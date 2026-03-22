#include "AppController.h"
#include <QStandardPaths>
#include <QDir>
#include <QDebug>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QFileInfo>
#include <QRegularExpression>
#include <algorithm>

AppController::AppController(QObject *parent) : QObject(parent)
{
    m_state = new AppState(this);
    
    QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir dir(dataPath);
    if (!dir.exists()) dir.mkpath(".");
    
    QString jsonPath = dir.filePath("progress.json");
    
    m_store = new ProgressStore(m_state, jsonPath, this);
    if (!m_store->load()) {
        qDebug() << "No progress found, starting fresh.";
    }

    // Always load vocabulary from the Cambridge B1 JSON first (like Python's load_vocabulary_from_json)
    {
        // Look for the JSON next to the project root (VocaCpp/b1_word_from_cambridge.json)
        // __FILE__ is VocaCpp/src/AppController.cpp, so go up one level to VocaCpp/
        QString vocabJsonPath = QFileInfo(QString(QStringLiteral(__FILE__))).absolutePath();
        vocabJsonPath += "/../b1_word_from_cambridge.json";
        QFile file(vocabJsonPath);
        if (file.open(QIODevice::ReadOnly)) {
            QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
            if (doc.isObject()) {
                QJsonArray wordsArray = doc.object().value("words").toArray();
                QSet<QString> seen;
                m_state->vocabulary.clear();
                for (const QJsonValue &val : wordsArray) {
                    QString w = val.toString().trimmed();
                    if (w.length() < 2) continue;
                    QString lw = w.toLower();
                    if (!seen.contains(lw)) {
                        seen.insert(lw);
                        m_state->vocabulary.append(w);
                    }
                }
                std::sort(m_state->vocabulary.begin(), m_state->vocabulary.end(), [](const QString &a, const QString &b){
                    return a.compare(b, Qt::CaseInsensitive) < 0;
                });
                qDebug() << "Loaded" << m_state->vocabulary.size() << "words from Cambridge list.";
            }
            file.close();
        } else {
            qWarning() << "Could not open Cambridge JSON at:" << vocabJsonPath;
        }
    }

    m_tts = new TTSService(this);
    m_stt = new STTService(this);
    
    // Initial Calc
    rebuildEligiblePool();
}

AppState* AppController::state() const
{
    return m_state;
}

TTSService* AppController::tts() const
{
    return m_tts;
}

STTService* AppController::stt() const
{
    return m_stt;
}

void AppController::rebuildEligiblePool()
{
    m_eligiblePool.clear();
    
    // Lowercase sets for fast lookup
    QSet<QString> shown, known, newW, removed;
    for(const auto &w : m_state->displayedWords) shown.insert(w.toLower());
    for(const auto &w : m_state->knownWords) known.insert(w.toLower());
    for(const auto &w : m_state->newWords) newW.insert(w.toLower());
    for(const auto &w : m_state->removedWords) removed.insert(w.toLower());
    
    for (const auto &w : m_state->vocabulary) {
        QString lw = w.toLower();
        if (!shown.contains(lw) && !known.contains(lw) && !newW.contains(lw) && !removed.contains(lw)) {
            m_eligiblePool.append(w);
        }
    }
    m_state->setRemainingCount(m_eligiblePool.size());
    m_eligibleDirty = false;
}

QString AppController::getRandomWord()
{
    if (m_eligibleDirty) rebuildEligiblePool();
    if (m_eligiblePool.isEmpty()) return "";
    
    int idx = QRandomGenerator::global()->bounded(m_eligiblePool.size());
    QString w = m_eligiblePool[idx];
    
    // Swap remove (fastest) - effectively "popping" from pool
    m_eligiblePool[idx] = m_eligiblePool.last();
    m_eligiblePool.removeLast();
    
    m_state->setRemainingCount(m_eligiblePool.size());
    
    return w;
}

void AppController::requestNextWord()
{
    // Logic: If current word exists and is not new/known/removed, mark it known (Auto-Known)
    // This mirrors Python's behavior of "Clicking Next implies Known unless user clicked New"
    QString prev = m_state->currentWord();
    if (!prev.isEmpty()) {
        QString lp = prev.toLower();
        if (!m_state->knownWords.contains(lp) && 
            !m_state->newWords.contains(lp) && 
            !m_state->removedWords.contains(lp)) {
            
            // Auto mark known
            m_state->knownWords.insert(prev); // Store original case if possible, or lower
            
            // Add to sequence if not there
            QStringList seq = m_state->knownSequence();
            if (!seq.contains(prev)) {
                seq.append(prev);
                m_state->setKnownSequence(seq);
            }
            m_eligibleDirty = true;
        }
    }

    QString next = getRandomWord();
    if (next.isEmpty()) {
        m_state->setCurrentWord(""); // Finished
        return;
    }
    
    m_state->displayedWords.insert(next);
    m_state->wordHistory.append(next);
    m_state->historyIndex = m_state->wordHistory.size() - 1;
    
    m_state->setCurrentWord(next);
    m_store->saveAsync();
}

void AppController::markWordKnown(const QString &word)
{
    if (word.isEmpty()) return;
    QString lw = word.toLower();
    
    m_state->knownWords.insert(word); // Insert distinct casing
    m_state->newWords.remove(word);
    m_state->removedWords.remove(lw); // clean cleanup
    
    // Update sequences
    QStringList kSeq = m_state->knownSequence();
    if (!kSeq.contains(word)) {
        kSeq.append(word);
        m_state->setKnownSequence(kSeq);
    }
    
    QStringList nSeq = m_state->newSequence();
    if (nSeq.contains(word)) {
        nSeq.removeAll(word);
        m_state->setNewSequence(nSeq);
    }
    
    // Track in learned session (so it appears in the "Learned words" list)
    m_state->learnedLog.insert(lw, QDate::currentDate().toString(Qt::ISODate));
    if (!m_state->learnedSession.contains(lw)) {
        m_state->learnedSession.append(lw);
    }

    m_eligibleDirty = true;
    m_store->saveAsync();
}

void AppController::markWordNew(const QString &word)
{
    if (word.isEmpty()) return;
    QString lw = word.toLower();

    m_state->newWords.insert(word);
    m_state->knownWords.remove(word);
    m_state->removedWords.remove(lw);
    
    // Update sequences
    QStringList nSeq = m_state->newSequence();
    if (!nSeq.contains(word)) {
        nSeq.append(word);
        m_state->setNewSequence(nSeq);
    }
    
    QStringList kSeq = m_state->knownSequence();
    if (kSeq.contains(word)) {
        kSeq.removeAll(word);
        m_state->setKnownSequence(kSeq);
    }

    m_eligibleDirty = true;
    m_store->saveAsync();
    
    // Auto advance after marking new? Python says:
    // Clock.schedule_once(lambda *_: self._go_next(), 0)
    requestNextWord();
}

void AppController::removeCurrentWord()
{
    QString w = m_state->currentWord();
    if (w.isEmpty()) return;
    removeWord(w);
    requestNextWord();
}

void AppController::moveWordToKnown(const QString &word)
{
    if (word.isEmpty()) return;
    QString lw = word.toLower();

    m_state->newWords.remove(word);
    QStringList nSeq = m_state->newSequence();
    if (nSeq.removeAll(word)) m_state->setNewSequence(nSeq);

    m_state->knownWords.insert(word);
    QStringList kSeq = m_state->knownSequence();
    if (!kSeq.contains(word)) {
        kSeq.append(word);
        m_state->setKnownSequence(kSeq);
    }
    
    m_eligibleDirty = true;
    m_store->saveAsync();
}

void AppController::moveWordToNew(const QString &word)
{
    if (word.isEmpty()) return;
    QString lw = word.toLower();

    m_state->knownWords.remove(word);
    QStringList kSeq = m_state->knownSequence();
    if (kSeq.removeAll(word)) m_state->setKnownSequence(kSeq);

    m_state->newWords.insert(word);
    QStringList nSeq = m_state->newSequence();
    if (!nSeq.contains(word)) {
        nSeq.append(word);
        m_state->setNewSequence(nSeq);
    }

    m_eligibleDirty = true;
    m_store->saveAsync();
}

void AppController::removeWord(const QString &word)
{
    if (word.isEmpty()) return;
    QString lw = word.toLower();

    m_state->removedWords.insert(lw);
    m_state->knownWords.remove(word);
    m_state->newWords.remove(word);

    // Update sequences
    QStringList rSeq = m_state->removedSequence();
    rSeq.removeAll(word);
    rSeq.prepend(word);
    m_state->setRemovedSequence(rSeq);
    
    QStringList kSeq = m_state->knownSequence();
    if (kSeq.removeAll(word)) m_state->setKnownSequence(kSeq);
    
    QStringList nSeq = m_state->newSequence();
    if (nSeq.removeAll(word)) m_state->setNewSequence(nSeq);
    
    m_eligibleDirty = true;
    m_store->saveAsync();
}

void AppController::restoreRemovedWord(const QString &word)
{
    if (word.isEmpty()) return;
    QString lw = word.toLower();

    // 1) Remove from removed list
    m_state->removedWords.remove(lw);
    QStringList rSeq = m_state->removedSequence();
    if (rSeq.removeAll(word)) m_state->setRemovedSequence(rSeq);

    // 2) Remove from new/known to be neutral
    m_state->knownWords.remove(word);
    m_state->newWords.remove(word);

    QStringList kSeq = m_state->knownSequence();
    if (kSeq.removeAll(word)) m_state->setKnownSequence(kSeq);
    QStringList nSeq = m_state->newSequence();
    if (nSeq.removeAll(word)) m_state->setNewSequence(nSeq);

    // 3) Display it in main screen (assuming it becomes current word)
    m_state->setCurrentWord(word);
    m_state->displayedWords.insert(word);

    m_eligibleDirty = true;
    m_store->saveAsync();
}

void AppController::correctWord(const QString &oldWord, const QString &newWord)
{
    if (oldWord.isEmpty() || newWord.isEmpty() || oldWord == newWord) return;
    
    QString oldLower = oldWord.toLower();
    QString newLower = newWord.toLower();

    if (m_state->removedWords.contains(newLower)) {
        return; // Target word is already removed
    }

    // Replace in vocabulary list
    int vIndex = m_state->vocabulary.indexOf(oldWord);
    if (vIndex != -1) {
        m_state->vocabulary.removeAt(vIndex);
    }
    if (!m_state->vocabulary.contains(newWord)) {
        m_state->vocabulary.append(newWord);
        m_state->vocabulary.sort(Qt::CaseInsensitive);
    }

    // Word Sets
    if (m_state->knownWords.remove(oldWord)) {
        m_state->knownWords.insert(newWord);
    }
    if (m_state->newWords.remove(oldWord)) {
        if (!m_state->knownWords.contains(newWord)) {
            m_state->newWords.insert(newWord);
        }
    }
    
    // Internal data maps
    if (m_state->wordDetails.contains(oldLower)) {
        auto details = m_state->wordDetails.take(oldLower);
        if (!m_state->wordDetails.contains(newLower)) {
            m_state->wordDetails.insert(newLower, details);
        } else {
            m_state->wordDetails[newLower].append(details);
        }
    }
    if (m_state->wordIpa.contains(oldLower)) {
        auto ipa = m_state->wordIpa.take(oldLower);
        if (!m_state->wordIpa.contains(newLower)) {
            m_state->wordIpa.insert(newLower, ipa);
        }
    }
    if (m_state->learnedLog.contains(oldLower)) {
        auto date = m_state->learnedLog.take(oldLower);
        if (!m_state->learnedLog.contains(newLower)) {
            m_state->learnedLog.insert(newLower, date);
        }
    }

    // Update the UI sequences
    QStringList kSeq = m_state->knownSequence();
    if (kSeq.contains(oldWord)) {
        kSeq.replace(kSeq.indexOf(oldWord), newWord);
        kSeq.sort(Qt::CaseInsensitive);
        m_state->setKnownSequence(kSeq);
    }

    QStringList nSeq = m_state->newSequence();
    if (nSeq.contains(oldWord)) {
        nSeq.replace(nSeq.indexOf(oldWord), newWord);
        nSeq.sort(Qt::CaseInsensitive);
        m_state->setNewSequence(nSeq);
    }

    QStringList rSeq = m_state->removedSequence();
    if (rSeq.contains(oldWord)) {
        rSeq.replace(rSeq.indexOf(oldWord), newWord);
        m_state->setRemovedSequence(rSeq);
    }

    if (m_state->currentWord() == oldWord) {
        m_state->setCurrentWord(newWord);
    }
    
    emit m_state->vocabularyCountChanged();
    m_eligibleDirty = true;
    m_store->saveAsync();
}

void AppController::save()
{
    m_store->saveSync();
}

QVariantMap AppController::getDashboardStats() const
{
    QVariantMap stats;
    
    QDate today = QDate::currentDate();
    int dayCount = 0;
    int weekCount = 0;
    int monthCount = 0;
    int yearCount = 0;
    
    // QDate::weekNumber() helps but let's do simple day diffs for "This Week" (Mon-Sun)
    QDate weekStart = today.addDays(-(today.dayOfWeek() - 1));
    QDate monthStart(today.year(), today.month(), 1);
    QDate yearStart(today.year(), 1, 1);
    
    QVariantList last7Dates;
    QVariantList last7Counts;
    QMap<QDate, int> dailyCounts;
    for (int i = 6; i >= 0; --i) {
        dailyCounts[today.addDays(-i)] = 0;
    }
    
    auto it = m_state->learnedLog.constBegin();
    while (it != m_state->learnedLog.constEnd()) {
        // Format YYYY-MM-DD
        QDate d = QDate::fromString(it.value(), Qt::ISODate);
        if (d.isValid()) {
            if (d == today) dayCount++;
            if (d >= weekStart && d <= today) weekCount++;
            if (d >= monthStart && d <= today) monthCount++;
            if (d >= yearStart && d <= today) yearCount++;
            
            if (dailyCounts.contains(d)) {
                dailyCounts[d]++;
            }
        }
        ++it;
    }
    
    for (int i = 6; i >= 0; --i) {
        QDate d = today.addDays(-i);
        last7Dates.append(d.toString("dd/MM"));
        last7Counts.append(dailyCounts[d]);
    }
    
    stats["today"] = dayCount;
    stats["week"] = weekCount;
    stats["month"] = monthCount;
    stats["year"] = yearCount;
    stats["last7Dates"] = last7Dates;
    stats["last7Counts"] = last7Counts;
    
    return stats;
}

void AppController::updateWordDetails(const QString &word, const QVariantList &details, const QString &ipa)
{
    if (word.isEmpty()) return;
    QString key = word.toLower();
    
    QList<WordDetail> detailList;
    for (const auto &v : details) {
        // QML sends JS objects/maps
        QVariantMap map = v.toMap();
        WordDetail d;
        d.meaning = map["meaning"].toString();
        d.examples = map["examples"].toStringList();
        d.pos = map["pos"].toStringList();
        detailList.append(d);
    }
    
    m_state->wordDetails.insert(key, detailList);
    
    if (!ipa.isEmpty()) {
        m_state->wordIpa.insert(key, ipa);
    } else {
        m_state->wordIpa.remove(key);
    }
    
    // Trigger signal if it's the current word
    if (m_state->currentWord().toLower() == key) {
        emit m_state->currentWordChanged();
    }
    
    save();
}

void AppController::updateLearnWord()
{
    QStringList newSeq = m_state->newSequence();
    if (newSeq.isEmpty()) {
        m_state->setLearnCurrentWord("");
        return;
    }
    
    QString order = m_state->learnOrderMode();
    if (order == "Random") {
        m_state->setLearnCurrentWord(newSeq[QRandomGenerator::global()->bounded(newSeq.size())]);
    } else {
        if (m_learnIdx >= newSeq.size()) m_learnIdx = 0;
        if (m_learnIdx < 0) m_learnIdx = newSeq.size() - 1;
        
        if (order == "Newest") {
            // Assuming sequence appended at end -> newest is at the end.
            m_state->setLearnCurrentWord(newSeq[newSeq.size() - 1 - m_learnIdx]);
        } else {
            m_state->setLearnCurrentWord(newSeq[m_learnIdx]);
        }
    }
}

QStringList AppController::getNewWordsList() const
{
    return m_state->newSequence();
}

void AppController::nextLearnWord()
{
    QStringList newSeq = m_state->newSequence();
    if (newSeq.isEmpty()) {
        m_state->setLearnCurrentWord("");
        return;
    }
    
    QString order = m_state->learnOrderMode();
    if (order != "Random") {
        m_learnIdx++;
        if (m_learnIdx >= newSeq.size()) m_learnIdx = 0;
    }
    updateLearnWord();
}

void AppController::markLearnWordKnown()
{
    QString w = m_state->learnCurrentWord();
    if (w.isEmpty()) return;
    
    markWordKnown(w);
    nextLearnWord();
}

void AppController::removeLearnWord()
{
    QString w = m_state->learnCurrentWord();
    if (w.isEmpty()) return;
    
    m_state->removedWords.insert(w.toLower());
    m_state->newWords.remove(w);
    
    QStringList rSeq = m_state->removedSequence();
    if (!rSeq.contains(w.toLower())) { // Wait, Python removed list is mixed casing, but usually word is kept. 
        rSeq.append(w);
        m_state->setRemovedSequence(rSeq);
    }
    
    QStringList nSeq = m_state->newSequence();
    nSeq.removeAll(w);
    m_state->setNewSequence(nSeq);
    
    m_eligibleDirty = true;
    save();
    nextLearnWord();
}

// Helper to parse "DD/MM" or "YYYY-MM-DD" "Today" "-1" etc.
static QDate parseReviewDate(const QString &str) {
    if (str.isEmpty()) return QDate();
    if (str.toLower() == "today" || str == "0") return QDate::currentDate();
    
    bool isNum = false;
    int offset = str.toInt(&isNum);
    if (isNum && offset <= 0) {
        return QDate::currentDate().addDays(offset);
    }
    
    // Try YYYY-MM-DD
    QDate d = QDate::fromString(str, Qt::ISODate);
    if (d.isValid()) return d;
    
    // Try DD/MM
    QStringList parts = str.split("/");
    if (parts.size() == 2) {
        int day = parts[0].toInt();
        int month = parts[1].toInt();
        return QDate(QDate::currentDate().year(), month, day);
    }
    return QDate();
}

int AppController::getReviewMatchingCount(const QString &startStr, const QString &endStr, bool twisterOnly)
{
    QDate st = parseReviewDate(startStr);
    QDate en = parseReviewDate(endStr);
    
    if (!st.isValid() && !en.isValid()) return 0;
    if (!en.isValid()) en = st;
    if (!st.isValid()) st = en;
    if (st > en) std::swap(st, en);

    int count = 0;
    auto it = m_state->learnedLog.constBegin();
    while (it != m_state->learnedLog.constEnd()) {
        QDate d = QDate::fromString(it.value(), Qt::ISODate);
        if (d.isValid() && d >= st && d <= en) {
            // Check tongue twister ?
            // In AppState we don't track twister explicitly yet, assuming all match if twisterOnly = false
            bool matchTwister = true; // TODO
            if (!twisterOnly || matchTwister) {
                count++;
            }
        }
        ++it;
    }
    return count;
}

QVariantList AppController::getReviewPool(const QString &startStr, const QString &endStr, bool twisterOnly) const
{
    QDate st = parseReviewDate(startStr);
    QDate en = parseReviewDate(endStr);
    
    // Build pool: all learned session words + expressions
    QStringList candidates;
    candidates += m_state->learnedSession;
    for (const QString &expr : m_state->expressions) {
        if (!candidates.contains(expr.toLower())) candidates.append(expr.toLower());
    }
    
    QVariantList result;
    for (const QString &w : candidates) {
        QString lw = w.toLower();
        
        // Date filter
        if (st.isValid() || en.isValid()) {
            QString ds = m_state->learnedLog.value(lw, "").trimmed();
            QDate d = ds.isEmpty() ? QDate() : QDate::fromString(ds, Qt::ISODate);
            if (st.isValid() && (!d.isValid() || d < st)) continue;
            if (en.isValid() && (!d.isValid() || d > en)) continue;
        }
        
        // Tongue-twister filter
        if (twisterOnly && !m_state->tongueTwisters.contains(lw)) continue;
        
        // Build rich item
        QVariantMap item;
        item["word"] = w;
        item["ipa"] = m_state->wordIpa.value(lw, "");
        
        QVariantList detailsList;
        if (m_state->wordDetails.contains(lw)) {
            for (const WordDetail &d : m_state->wordDetails[lw]) {
                QVariantMap dMap;
                dMap["meaning"] = d.meaning;
                dMap["examples"] = d.examples;
                dMap["pos"] = d.pos;
                detailsList.append(dMap);
            }
        }
        item["details"] = detailsList;
        result.append(item);
    }
    
    return result;
}
void AppController::startReview(const QString &startStr, const QString &endStr, bool twisterOnly)
{
    m_reviewPool.clear();
    m_reviewIdx = 0;
    
    QDate st = parseReviewDate(startStr);
    QDate en = parseReviewDate(endStr);
    
    if (!st.isValid() && !en.isValid()) {
        m_state->setReviewCurrentWord("");
        return;
    }
    if (!en.isValid()) en = st;
    if (!st.isValid()) st = en;
    if (st > en) std::swap(st, en);

    auto it = m_state->learnedLog.constBegin();
    while (it != m_state->learnedLog.constEnd()) {
        QDate d = QDate::fromString(it.value(), Qt::ISODate);
        if (d.isValid() && d >= st && d <= en) {
            bool matchTwister = true; // TODO
            if (!twisterOnly || matchTwister) {
                m_reviewPool.append(it.key()); // already lowercase
            }
        }
        ++it;
    }
    
    m_state->setReviewRemainingCount(m_reviewPool.size());
    
    if (m_reviewPool.isEmpty()) {
        m_state->setReviewCurrentWord("");
    } else {
        // Find original casing if possible, or just use lower
        m_state->setReviewCurrentWord(m_reviewPool[0]);
    }
}

void AppController::nextReviewWord()
{
    if (m_reviewPool.isEmpty()) {
        m_state->setReviewCurrentWord("");
        return;
    }
    m_reviewIdx++;
    if (m_reviewIdx >= m_reviewPool.size()) {
        m_state->setReviewCurrentWord("");
    } else {
        m_state->setReviewCurrentWord(m_reviewPool[m_reviewIdx]);
    }
    m_state->setReviewRemainingCount(m_reviewPool.size() - m_reviewIdx);
}

void AppController::markReviewWordKnown()
{
    if (m_reviewPool.isEmpty() || m_reviewIdx >= m_reviewPool.size()) return;
    
    // In Review Mode, "Correct" just confirms they know it.
    // In Python app it might extend the interval in DB.
    // For Voca basic: it's just marking as learned again today? Or no-op.
    // We'll just update history or next.
    QString w = m_reviewPool[m_reviewIdx];
    m_state->learnedSession.append(w); // ensure it's in session
    
    nextReviewWord();
}

int AppController::addNewWordsFromText(const QString &text)
{
    QStringList lines = text.split(QRegularExpression("[\r\n]+"), Qt::SkipEmptyParts);
    QSet<QString> existingLower;
    for (const QString &w : m_state->vocabulary) existingLower.insert(w.toLower());
    for (const QString &w : m_state->removedWords) existingLower.insert(w.toLower());

    QStringList toAdd;
    for (QString line : lines) {
        line = line.trimmed();
        if (line.isEmpty()) continue;
        
        // Clean leading bullets, hyphens
        line.replace(QRegularExpression("^[-*\\x{2022}]+\\s*"), "");
        line.replace("’", "'").replace("‘", "'");
        line.replace(QRegularExpression("[^A-Za-z'\\-\\s]"), "");
        line.replace(QRegularExpression("\\s*-\\s*"), "-");
        line.replace(QRegularExpression("-{2,}"), "-");
        line.replace(QRegularExpression("^-+|-+$"), "");
        line = line.simplified();
        
        if (line.length() < 2) continue;
        
        QString w = line.toLower();
        if (!existingLower.contains(w)) {
            toAdd.append(w);
            existingLower.insert(w);
        }
    }

    if (toAdd.isEmpty()) return 0;

    for (const QString &w : toAdd) {
        m_state->userWords.insert(w);
        m_state->vocabulary.append(w);
        m_state->knownWords.remove(w);
        if (!m_state->newWords.contains(w)) {
            m_state->newWords.insert(w);
        }
        QStringList nSeq = m_state->newSequence();
        if (!nSeq.contains(w)) {
            nSeq.append(w);
            m_state->setNewSequence(nSeq);
        }
    }
    
    m_state->vocabulary.sort(Qt::CaseInsensitive);

    m_eligibleDirty = true;
    save();
    emit m_state->vocabularyCountChanged();

    return toAdd.size();
}

QStringList AppController::findWordsInText(const QString &text)
{
    QString t = text;
    t.replace("’", "'").replace("‘", "'");
    t.replace(QRegularExpression("[^a-zA-Z'\\-]"), " ");
    
    QStringList words = t.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
    QStringList res;
    QSet<QString> seen;
    
    QSet<QString> existingLower;
    for (const QString &w : m_state->vocabulary) existingLower.insert(w.toLower());
    
    for (QString w : words) {
        // Strip leading/trailing hyphen or quote
        while(w.startsWith('-') || w.startsWith('\'')) w.remove(0, 1);
        while(w.endsWith('-') || w.endsWith('\'')) w.chop(1);
        
        if (w.length() > 2) {
            QString lw = w.toLower();
            if (!seen.contains(lw)) {
                seen.insert(lw);
                if (!existingLower.contains(lw) && !m_state->removedWords.contains(lw)) {
                    res.append(lw);
                }
            }
        }
    }
    
    return res;
}

QStringList AppController::getExpressions() const
{
    // The Python app reads `self.expressions` which is a `list`. 
    // In our `AppState`, `m_state->expressions` holds this list.
    return m_state->expressions;
}

void AppController::addExpression(const QString &phrase, const QVariantList &details)
{
    if (phrase.trimmed().isEmpty()) return;
    
    QString cleanPhrase = phrase.trimmed();
    
    if (!m_state->expressions.contains(cleanPhrase, Qt::CaseInsensitive)) {
        m_state->expressions.append(cleanPhrase);
    }
    
    // Add to wordDetails
    updateWordDetails(cleanPhrase, details, "");
}

QVariantList AppController::getLearnedWordsAndExpressions(const QString &query, bool onlyTwister) const
{
    QString q = query.trimmed().toLower();
    
    QStringList combined;
    // learnedSession reversed
    for (int i = m_state->learnedSession.size() - 1; i >= 0; --i) {
        combined.append(m_state->learnedSession[i]);
    }
    for (const QString &expr : m_state->expressions) {
        if (!combined.contains(expr, Qt::CaseInsensitive)) {
            combined.append(expr);
        }
    }
    
    QVariantList result;
    for (const QString &w : combined) {
        QString lw = w.toLower();
        if (!q.isEmpty() && !lw.contains(q)) continue;
        
        if (onlyTwister && !m_state->tongueTwisters.contains(lw)) continue;
        
        QVariantMap item;
        item["word"] = w;
        item["ipa"] = m_state->wordIpa.value(lw, "");
        
        QVariantList detailsList;
        if (m_state->wordDetails.contains(lw)) {
            const auto &details = m_state->wordDetails[lw];
            for (const WordDetail &d : details) {
                QVariantMap dMap;
                dMap["meaning"] = d.meaning;
                dMap["examples"] = d.examples;
                dMap["pos"] = d.pos;
                detailsList.append(dMap);
            }
        }
        item["details"] = detailsList;
        
        result.append(item);
    }
    
    return result;
}

QVariantList AppController::getExpressionsWithDetails(const QString &query) const
{
    QString q = query.trimmed().toLower();
    
    QVariantList result;
    for (const QString &w : m_state->expressions) {
        QString lw = w.toLower();
        if (!q.isEmpty() && !lw.contains(q)) continue;
        
        QVariantMap item;
        item["word"] = w;
        item["ipa"] = m_state->wordIpa.value(lw, "");
        
        QVariantList detailsList;
        if (m_state->wordDetails.contains(lw)) {
            const auto &details = m_state->wordDetails[lw];
            for (const WordDetail &d : details) {
                QVariantMap dMap;
                dMap["meaning"] = d.meaning;
                dMap["examples"] = d.examples;
                dMap["pos"] = d.pos;
                detailsList.append(dMap);
            }
        }
        item["details"] = detailsList;
        
        result.append(item);
    }
    
    return result;
}

