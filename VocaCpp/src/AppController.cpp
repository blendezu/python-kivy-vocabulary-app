#include "AppController.h"
#include <QStandardPaths>
#include <QDir>
#include <QDebug>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

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

    // Load Vocabulary (Mocking loading from resource or bundled file)
    // In real app, we'd read b1_word_from_cambridge.json
    // For now, let's inject some dummy data if empty or try to load from a relative path
    // TODO: Copy b1_word_from_cambridge.json to build dir or resources
    if (m_state->vocabulary.isEmpty()) {
         m_state->vocabulary << "apple" << "banana" << "conversation" << "determine" << "example" << "function" << "grateful" << "harmony";
         // Add some details for testing
         WordDetail d; d.meaning = "A sweet fruit"; d.examples << "I ate an apple."; d.pos << "n";
         m_state->wordDetails.insert("apple", {d});
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

    m_eligibleDirty = true;
    m_store->saveAsync();
    // In Python, clicking "Correct" didn't auto-advance. It just marked it.
    // But "Next Word" will advance.
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
    
    m_state->removedWords.insert(w.toLower());
    m_state->knownWords.remove(w);
    m_state->newWords.remove(w);
    
    // Clean sequences
    QStringList kSeq = m_state->knownSequence();
    if (kSeq.removeAll(w)) m_state->setKnownSequence(kSeq);
    
    QStringList nSeq = m_state->newSequence();
    if (nSeq.removeAll(w)) m_state->setNewSequence(nSeq);
    
    m_eligibleDirty = true;
    m_store->saveAsync();
    requestNextWord();
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
    // Python code: week_start = today - timedelta(days=today.weekday()) -> Monday
    QDate weekStart = today.addDays(-(today.dayOfWeek() - 1));
    QDate monthStart(today.year(), today.month(), 1);
    QDate yearStart(today.year(), 1, 1);
    
    auto it = m_state->learnedLog.constBegin();
    while (it != m_state->learnedLog.constEnd()) {
        // Format YYYY-MM-DD
        QDate d = QDate::fromString(it.value(), Qt::ISODate);
        if (d.isValid()) {
            if (d == today) dayCount++;
            if (d >= weekStart && d <= today) weekCount++;
            if (d >= monthStart && d <= today) monthCount++;
            if (d >= yearStart && d <= today) yearCount++;
        }
        ++it;
    }
    
    stats["today"] = dayCount;
    stats["week"] = weekCount;
    stats["month"] = monthCount;
    stats["year"] = yearCount;
    
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
