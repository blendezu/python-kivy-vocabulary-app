#include "AppController.h"
#include <QStandardPaths>
#include <QDir>
#include <QDebug>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonParseError>
#include <QFileInfo>
#include <QRegularExpression>
#include <algorithm>
#include <iostream>

namespace {
inline QString toKey(const QString &value) { return value.toLower(); }

inline void insertLower(QSet<QString> &set, const QString &value) {
    set.insert(toKey(value));
}

inline void removeLower(QSet<QString> &set, const QString &value) {
    set.remove(toKey(value));
}

inline bool listContainsCI(const QStringList &list, const QString &value) {
    for (const QString &item : list) {
        if (item.compare(value, Qt::CaseInsensitive) == 0) {
            return true;
        }
    }
    return false;
}

inline bool removeFromListCI(QStringList &list, const QString &value) {
    bool removed = false;
    for (int i = list.size() - 1; i >= 0; --i) {
        if (list[i].compare(value, Qt::CaseInsensitive) == 0) {
            list.removeAt(i);
            removed = true;
        }
    }
    return removed;
}

inline void replaceInListCI(QStringList &list, const QString &oldValue, const QString &newValue) {
    for (QString &item : list) {
        if (item.compare(oldValue, Qt::CaseInsensitive) == 0) {
            item = newValue;
        }
    }
}
}

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

    auto parseVocabulary = [this](const QByteArray &raw, const QString &source) -> bool {
        QJsonParseError err;
        QJsonDocument doc = QJsonDocument::fromJson(raw, &err);
        if (err.error != QJsonParseError::NoError || !doc.isObject()) {
            qWarning() << "Failed to parse vocabulary JSON from" << source << ":" << err.errorString();
            return false;
        }

        QJsonArray wordsArray = doc.object().value("words").toArray();
        if (wordsArray.isEmpty()) {
            qWarning() << "Vocabulary JSON" << source << "does not contain a 'words' array";
            return false;
        }

        QSet<QString> seen;
        QStringList vocab;
        vocab.reserve(wordsArray.size());
        for (const QJsonValue &val : wordsArray) {
            QString w = val.toString().trimmed();
            if (w.length() < 2) continue;
            QString lw = w.toLower();
            if (seen.contains(lw)) continue;
            seen.insert(lw);
            vocab.append(w);
        }
        std::sort(vocab.begin(), vocab.end(), [](const QString &a, const QString &b) {
            return a.compare(b, Qt::CaseInsensitive) < 0;
        });
        m_state->vocabulary = vocab;
        qDebug() << "Loaded" << m_state->vocabulary.size() << "words from" << source;
        return true;
    };

    auto tryLoadFromPath = [&](const QString &path) -> bool {
        QFile file(path);
        if (!file.open(QIODevice::ReadOnly)) {
            return false;
        }
        QByteArray raw = file.readAll();
        file.close();
        return parseVocabulary(raw, path);
    };

    bool vocabLoaded = tryLoadFromPath(":/b1_word_from_cambridge.json");
    if (!vocabLoaded) {
        // Fallback: look for the JSON next to the project root (developer builds)
        QString vocabJsonPath = QFileInfo(QStringLiteral(__FILE__)).absolutePath() + "/../b1_word_from_cambridge.json";
        vocabLoaded = tryLoadFromPath(vocabJsonPath);
        if (!vocabLoaded) {
            qWarning() << "Could not load Cambridge vocabulary JSON from resources or" << vocabJsonPath;
        }
    }

    m_tts = new TTSService(this);
    qDebug() << "### Creating STTService ###";
    std::cout << "### Creating STTService std::cout ###" << std::endl;
    m_stt = new STTService(this);
    qDebug() << "### Created STTService ###";
    std::cout << "### Created STTService std::cout ###" << std::endl;
    
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
            m_state->knownWords.insert(lp);
            
            // Add to sequence if not there
            QStringList seq = m_state->knownSequence();
            if (!listContainsCI(seq, prev)) {
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
    
    insertLower(m_state->knownWords, word);
    removeLower(m_state->newWords, word);
    removeLower(m_state->removedWords, word);
    
    // Update sequences
    QStringList kSeq = m_state->knownSequence();
    if (!listContainsCI(kSeq, word)) {
        kSeq.append(word);
        m_state->setKnownSequence(kSeq);
    }
    
    QStringList nSeq = m_state->newSequence();
    if (removeFromListCI(nSeq, word)) {
        m_state->setNewSequence(nSeq);
    }
    
    // Track in learned session (so it appears in the "Learned words" list)
    m_state->learnedLog.insert(lw, QDate::currentDate().toString(Qt::ISODate));
    // Python preserves original casing in learned_session, but uses lowercase keys in learned_log.
    bool has = false;
    for (const QString &x : std::as_const(m_state->learnedSession)) {
        if (x.compare(word, Qt::CaseInsensitive) == 0) {
            has = true;
            break;
        }
    }
    if (!has) {
        m_state->learnedSession.append(word);
    }

    m_eligibleDirty = true;
    m_store->saveAsync();
}

void AppController::markWordNew(const QString &word)
{
    if (word.isEmpty()) return;
    QString lw = word.toLower();

    insertLower(m_state->newWords, word);
    removeLower(m_state->knownWords, word);
    removeLower(m_state->removedWords, word);
    
    // Update sequences
    QStringList nSeq = m_state->newSequence();
    if (!listContainsCI(nSeq, word)) {
        nSeq.append(word);
        m_state->setNewSequence(nSeq);
    }
    
    QStringList kSeq = m_state->knownSequence();
    if (removeFromListCI(kSeq, word)) {
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

    removeLower(m_state->newWords, word);
    QStringList nSeq = m_state->newSequence();
    if (removeFromListCI(nSeq, word)) m_state->setNewSequence(nSeq);

    insertLower(m_state->knownWords, word);
    QStringList kSeq = m_state->knownSequence();
    if (!listContainsCI(kSeq, word)) {
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

    removeLower(m_state->knownWords, word);
    QStringList kSeq = m_state->knownSequence();
    if (removeFromListCI(kSeq, word)) m_state->setKnownSequence(kSeq);

    insertLower(m_state->newWords, word);
    QStringList nSeq = m_state->newSequence();
    if (!listContainsCI(nSeq, word)) {
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
    removeLower(m_state->knownWords, word);
    removeLower(m_state->newWords, word);

    // Update sequences
    QStringList rSeq = m_state->removedSequence();
    removeFromListCI(rSeq, word);
    rSeq.prepend(word);
    m_state->setRemovedSequence(rSeq);
    
    QStringList kSeq = m_state->knownSequence();
    if (removeFromListCI(kSeq, word)) m_state->setKnownSequence(kSeq);
    
    QStringList nSeq = m_state->newSequence();
    if (removeFromListCI(nSeq, word)) m_state->setNewSequence(nSeq);
    
    m_eligibleDirty = true;
    m_store->saveAsync();
}

void AppController::restoreRemovedWord(const QString &word)
{
    if (word.isEmpty()) return;
    QString lw = word.toLower();

    // 1) Remove from removed list
    removeLower(m_state->removedWords, word);
    QStringList rSeq = m_state->removedSequence();
    if (removeFromListCI(rSeq, word)) m_state->setRemovedSequence(rSeq);

    // 2) Remove from new/known to be neutral
    removeLower(m_state->knownWords, word);
    removeLower(m_state->newWords, word);

    QStringList kSeq = m_state->knownSequence();
    if (removeFromListCI(kSeq, word)) m_state->setKnownSequence(kSeq);
    QStringList nSeq = m_state->newSequence();
    if (removeFromListCI(nSeq, word)) m_state->setNewSequence(nSeq);

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
    if (m_state->knownWords.remove(oldLower)) {
        insertLower(m_state->knownWords, newWord);
    }
    if (m_state->newWords.remove(oldLower)) {
        if (!m_state->knownWords.contains(newLower)) {
            insertLower(m_state->newWords, newWord);
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
    if (listContainsCI(kSeq, oldWord)) {
        replaceInListCI(kSeq, oldWord, newWord);
        kSeq.sort(Qt::CaseInsensitive);
        m_state->setKnownSequence(kSeq);
    }

    QStringList nSeq = m_state->newSequence();
    if (listContainsCI(nSeq, oldWord)) {
        replaceInListCI(nSeq, oldWord, newWord);
        nSeq.sort(Qt::CaseInsensitive);
        m_state->setNewSequence(nSeq);
    }

    QStringList rSeq = m_state->removedSequence();
    if (listContainsCI(rSeq, oldWord)) {
        replaceInListCI(rSeq, oldWord, newWord);
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

QVariantMap AppController::getDashboardSummary() const
{
    QVariantMap stats;
    QDate today = QDate::currentDate();
    
    // Python week start: monday (0)
    int dayOfWeek = today.dayOfWeek(); // 1=Mon, 7=Sun
    QDate weekStart = today.addDays(-(dayOfWeek - 1));
    QDate monthStart(today.year(), today.month(), 1);
    QDate yearStart(today.year(), 1, 1);
    
    int cToday = 0;
    int cWeek = 0;
    int cMonth = 0;
    int cYear = 0;

    auto i = m_state->learnedLog.constBegin();
    while (i != m_state->learnedLog.constEnd()) {
        QDate d = QDate::fromString(i.value(), Qt::ISODate);
        if (d.isValid()) {
            if (d == today) cToday++;
            if (d >= weekStart && d <= today) cWeek++;
            if (d >= monthStart && d <= today) cMonth++;
            if (d >= yearStart && d <= today) cYear++;
        }
        ++i;
    }
    
    stats["today"] = cToday;
    stats["week"] = cWeek;
    stats["month"] = cMonth;
    stats["year"] = cYear;
    return stats;
}

QVariantMap AppController::getDailyStats(int offsetDay) const
{
    QVariantMap result;
    QDate today = QDate::currentDate();
    QDate end = today.addDays(-offsetDay);
    QDate start = end.addDays(-9); // 10 days total
    
    // Initialize map
    QMap<QDate, int> counts;
    for (QDate d = start; d <= end; d = d.addDays(1)) {
        counts[d] = 0;
    }

    // Fill counts
    auto i = m_state->learnedLog.constBegin();
    while (i != m_state->learnedLog.constEnd()) {
        QDate d = QDate::fromString(i.value(), Qt::ISODate);
        if (d.isValid() && d >= start && d <= end) {
            counts[d]++;
        }
        ++i;
    }

    QVariantList labels;
    QVariantList values;
    int maxVal = 0;

    for (QDate d = start; d <= end; d = d.addDays(1)) {
        labels.append(d.toString("dd.MM"));
        int v = counts[d];
        values.append(v);
        if (v > maxVal) maxVal = v;
    }
    
    result["labels"] = labels;
    result["values"] = values;
    result["maxValue"] = maxVal;
    
    // We also need colors: if (val >= prev_val) -> good, else -> bad
    // But color logic is better handled in QML or passed as array of bool "isGood"
    // Python: good if (prev is None or v >= prev) else bad
    
    QVariantList isGood;
    int prev = -1;
    for (const QVariant &val : values) {
        int v = val.toInt();
        if (prev == -1 || v >= prev) {
            isGood.append(true);
        } else {
            isGood.append(false);
        }
        prev = v;
    }
    result["isGood"] = isGood;

    return result;
}

QVariantMap AppController::getMonthlyStats(int year) const
{
    QVariantMap result;
    QMap<int, int> counts; // month 1-12
    for (int m = 1; m <= 12; ++m) counts[m] = 0;
    
    auto i = m_state->learnedLog.constBegin();
    while (i != m_state->learnedLog.constEnd()) {
        QDate d = QDate::fromString(i.value(), Qt::ISODate);
        if (d.isValid() && d.year() == year) {
            counts[d.month()]++;
        }
        ++i;
    }

    QVariantList labels;
    QVariantList values;
    int maxVal = 0;
    
    QStringList monthNames = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", 
                              "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};
                              
    for (int m = 1; m <= 12; ++m) {
        labels.append(monthNames[m-1]);
        int v = counts[m];
        values.append(v);
        if (v > maxVal) maxVal = v;
    }
    
    result["labels"] = labels;
    result["values"] = values;
    result["maxValue"] = maxVal;

    QVariantList isGood;
    int prev = -1;
    for (const QVariant &val : values) {
        int v = val.toInt();
        if (prev == -1 || v >= prev) {
            isGood.append(true);
        } else {
            isGood.append(false);
        }
        prev = v;
    }
    result["isGood"] = isGood;
    
    return result;
}

void AppController::updateWordDetails(const QString &word, const QVariantList &details, const QString &ipa)
{
    if (word.isEmpty()) return;
    QString key = word.toLower();

    // Convert QVariantList (from JS) back to QList<WordDetail>
    QList<WordDetail> detailList;
    for (const QVariant &v : details) {
        QVariantMap map = v.toMap();
        WordDetail wd;
        wd.meaning = map.value("meaning").toString();
        wd.examples = map.value("examples").toStringList();
        
        // Clean up empty examples
        QStringList cleanEx;
        for (const QString &ex : std::as_const(wd.examples)) {
            if (!ex.trimmed().isEmpty()) cleanEx.append(ex);
        }
        wd.examples = cleanEx;

        // pos is list of strings
        QVariantList posList = map.value("pos").toList();
        QStringList pList;
        for (const QVariant &p : posList) pList.append(p.toString());
        wd.pos = pList;

        detailList.append(wd);
    }
    
    // Update State
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

QVariantList AppController::getWordDetails(const QString &word) const
{
    if (word.isEmpty()) return {};
    QString key = word.toLower();
    
    if (!m_state->wordDetails.contains(key)) return {};

    QList<WordDetail> list = m_state->wordDetails.value(key);
    QVariantList res;
    for (const WordDetail &wd : list) {
        QVariantMap m;
        m["meaning"] = wd.meaning;
        m["examples"] = wd.examples;
        m["pos"] = wd.pos;
        res.append(m);
    }
    return res;
}

QString AppController::getWordIpa(const QString &word) const
{
    if (word.isEmpty()) return "";
    return m_state->wordIpa.value(word.toLower());
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
        int idx = QRandomGenerator::global()->bounded(newSeq.size());
        QString candidate = newSeq[idx];
        // If we picked same word and have alternatives, pick next one
        if (newSeq.size() > 1 && candidate == m_state->learnCurrentWord()) {
            idx = (idx + 1) % newSeq.size();
            candidate = newSeq[idx];
        }
        m_state->setLearnCurrentWord(candidate);
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

QString AppController::nextLearnWord()
{
    QStringList newSeq = m_state->newSequence();
    if (newSeq.isEmpty()) {
        m_state->setLearnCurrentWord("");
        return "";
    }
    
    QString order = m_state->learnOrderMode();
    if (order != "Random") {
        m_learnIdx++;
        if (m_learnIdx >= newSeq.size()) m_learnIdx = 0;
    }
    updateLearnWord();
    return m_state->learnCurrentWord();
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

    // Match Python _learn_remove_current:
    // - add lowercase to removed_words
    // - remove from known/new sets
    // - remove from known/new sequences
    // - remove from learnedSession (case-insensitive) and learnedLog
    const QString lw = w.toLower();
    m_state->removedWords.insert(lw);

    removeLower(m_state->knownWords, w);
    removeLower(m_state->newWords, w);

    QStringList kSeq = m_state->knownSequence();
    if (removeFromListCI(kSeq, w)) m_state->setKnownSequence(kSeq);

    QStringList nSeq = m_state->newSequence();
    if (removeFromListCI(nSeq, w)) m_state->setNewSequence(nSeq);

    // Keep removedSequence as a MRU list with original casing (prepend like removeWord())
    QStringList rSeq = m_state->removedSequence();
    removeFromListCI(rSeq, w);
    rSeq.prepend(w);
    m_state->setRemovedSequence(rSeq);

    // learnedSession stores casing; learnedLog uses lowercase key
    removeFromListCI(m_state->learnedSession, w);
    m_state->learnedLog.remove(lw);

    m_eligibleDirty = true;
    m_store->saveAsync();
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

int AppController::addWords(const QStringList &words)
{
    QSet<QString> existingLower;
    // We must rebuild existing set because m_state->vocabulary may change
    for (const QString &w : m_state->vocabulary) existingLower.insert(w.toLower());
    for (const QString &w : m_state->removedWords) existingLower.insert(w.toLower());

    QStringList toAdd;
    // Use QSet for quicker uniqueness check within the batch
    QSet<QString> batchUnique;

    for (const QString &raw : words) {
        QString w = raw.trimmed().toLower();
        if (w.isEmpty()) continue;
        if (w.length() < 2) continue; // Minimum length check

        if (!existingLower.contains(w) && !batchUnique.contains(w)) {
            toAdd.append(w);
            batchUnique.insert(w);
        }
    }

    if (toAdd.isEmpty()) return 0;
    
    // Process new words
    QStringList nSeq = m_state->newSequence();

    for (const QString &w : toAdd) {
        m_state->userWords.insert(w);
        m_state->vocabulary.append(w);
        
        // Ensure not in knownWords
        m_state->knownWords.remove(w);

        if (!m_state->newWords.contains(w)) {
            m_state->newWords.insert(w);
        }
        
        // Add to newSequence if not present
        if (!listContainsCI(nSeq, w)) {
            nSeq.append(w);
        }
    }
    
    m_state->setNewSequence(nSeq);
    
    // Sort vocabulary
    m_state->vocabulary.sort(Qt::CaseInsensitive);

    m_eligibleDirty = true;
    save();
    emit m_state->vocabularyCountChanged();

    return toAdd.size();
}

QStringList AppController::findWordsInText(const QString &text)
{
    // Match Python logic: re.findall(r"[A-Za-z]+(?:[-'][A-Za-z]+)*", text)
    // allowing words like "far-out", "it's" but avoiding garbage
    QRegularExpression re("[A-Za-z]+(?:[-'][A-Za-z]+)*");
    QRegularExpressionMatchIterator i = re.globalMatch(text);
    
    QStringList res;
    QSet<QString> seen;
    
    QSet<QString> existingLower;
    for (const QString &w : m_state->vocabulary) existingLower.insert(w.toLower());
    
    while (i.hasNext()) {
        QRegularExpressionMatch match = i.next();
        QString w = match.captured(0);
        
        // Remove length checks if you want short words, but Python had > 2
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

