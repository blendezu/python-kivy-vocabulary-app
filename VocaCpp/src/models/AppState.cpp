#include "AppState.h"

AppState::AppState(QObject *parent) : QObject(parent)
{
}

QString AppState::currentWord() const
{
    return m_currentWord;
}

void AppState::setCurrentWord(const QString &word)
{
    if (m_currentWord == word)
        return;
    m_currentWord = word;
    emit currentWordChanged();
}

QString AppState::learnCurrentWord() const
{
    return m_learnCurrentWord;
}

void AppState::setLearnCurrentWord(const QString &word)
{
    if (m_learnCurrentWord == word)
        return;
    m_learnCurrentWord = word;
    emit learnCurrentWordChanged();
}

QString AppState::reviewCurrentWord() const
{
    return m_reviewCurrentWord;
}

void AppState::setReviewCurrentWord(const QString &word)
{
    if (m_reviewCurrentWord == word)
        return;
    m_reviewCurrentWord = word;
    emit reviewCurrentWordChanged();
}

int AppState::remainingCount() const

{
    return m_remainingCount;
}

int AppState::reviewRemainingCount() const
{
    return m_reviewRemainingCount;
}

int AppState::vocabularyCount() const
{
    return vocabulary.size();
}

void AppState::setRemainingCount(int count)
{
    if (m_remainingCount == count)
        return;
    m_remainingCount = count;
    emit remainingCountChanged();
}

void AppState::setReviewRemainingCount(int count)
{
    if (m_reviewRemainingCount == count)
        return;
    m_reviewRemainingCount = count;
    emit reviewRemainingCountChanged();
}


QString AppState::learnOrderMode() const
{
    return m_learnOrderMode;
}

void AppState::setLearnOrderMode(const QString &mode)
{
    if (m_learnOrderMode == mode)
        return;
    m_learnOrderMode = mode;
    emit learnOrderModeChanged();
}

QStringList AppState::knownSequence() const
{
    return m_knownSequence;
}

void AppState::setKnownSequence(const QStringList &seq)
{
    if (m_knownSequence == seq)
        return;
    m_knownSequence = seq;
    emit knownSequenceChanged();
}

QStringList AppState::newSequence() const
{
    return m_newSequence;
}

void AppState::setNewSequence(const QStringList &seq)
{
    if (m_newSequence == seq)
        return;
    m_newSequence = seq;
    emit newSequenceChanged();
}

QStringList AppState::removedSequence() const
{
    return m_removedSequence;
}

void AppState::setRemovedSequence(const QStringList &seq)
{
    if (m_removedSequence == seq)
        return;
    m_removedSequence = seq;
    emit removedSequenceChanged();
}


QVariantList AppState::currentWordDetails() const
{
    QVariantList list;
    if (m_currentWord.isEmpty()) return list;

    QString key = m_currentWord.toLower();
    if (wordDetails.contains(key)) {
        const auto &details = wordDetails[key];
        for (const auto &d : details) {
            list.append(QVariant::fromValue(d));
        }
    }
    return list;
}

QString AppState::currentWordIpa() const
{
    if (m_currentWord.isEmpty()) return "";
    return wordIpa.value(m_currentWord.toLower(), "");
}
