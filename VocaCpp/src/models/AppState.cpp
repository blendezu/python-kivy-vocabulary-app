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

int AppState::remainingCount() const
{
    return m_remainingCount;
}

void AppState::setRemainingCount(int count)
{
    if (m_remainingCount == count)
        return;
    m_remainingCount = count;
    emit remainingCountChanged();
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
