#ifndef APPSTATE_H
#define APPSTATE_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <QSet>
#include <QVariantMap>
#include <QVector>
#include <QMap>

struct WordDetail {
    Q_GADGET
    Q_PROPERTY(QString meaning MEMBER meaning)
    Q_PROPERTY(QStringList examples MEMBER examples)
    Q_PROPERTY(QStringList pos MEMBER pos)
public:
    QString meaning;
    QStringList examples;
    QStringList pos;
    // Operator for equality check
    bool operator==(const WordDetail &other) const {
        return meaning == other.meaning && examples == other.examples && pos == other.pos;
    }
};
Q_DECLARE_METATYPE(WordDetail)

class AppState : public QObject
{
    Q_OBJECT

    // Exposed Properties for QML
    Q_PROPERTY(QString currentWord READ currentWord WRITE setCurrentWord NOTIFY currentWordChanged)
    Q_PROPERTY(int remainingCount READ remainingCount WRITE setRemainingCount NOTIFY remainingCountChanged)
    Q_PROPERTY(QString learnOrderMode READ learnOrderMode WRITE setLearnOrderMode NOTIFY learnOrderModeChanged)
    
    // Sequences
    Q_PROPERTY(QStringList knownSequence READ knownSequence WRITE setKnownSequence NOTIFY knownSequenceChanged)
    Q_PROPERTY(QStringList newSequence READ newSequence WRITE setNewSequence NOTIFY newSequenceChanged)
    
    // Details for current word (Convenience for QML)
    Q_PROPERTY(QVariantList currentWordDetails READ currentWordDetails NOTIFY currentWordChanged)
    Q_PROPERTY(QString currentWordIpa READ currentWordIpa NOTIFY currentWordChanged)

public:
    explicit AppState(QObject *parent = nullptr);

    // Getters
    QString currentWord() const;
    int remainingCount() const;
    QString learnOrderMode() const;
    QStringList knownSequence() const;
    QStringList newSequence() const;
    
    QVariantList currentWordDetails() const;
    QString currentWordIpa() const;

    // Setters
    void setCurrentWord(const QString &word);
    void setRemainingCount(int count);
    void setLearnOrderMode(const QString &mode);
    void setKnownSequence(const QStringList &seq);
    void setNewSequence(const QStringList &seq);

    // Internal Data Structures (Direct Access for C++ Logic)
    QStringList vocabulary; 
    
    QSet<QString> displayedWords;
    QSet<QString> knownWords;
    QSet<QString> newWords;
    QSet<QString> userWords;
    QSet<QString> removedWords;

    QStringList learnedSession;
    
    // Maps
    QMap<QString, QString> learnedLog;
    QMap<QString, QList<WordDetail>> wordDetails; // word (lower) -> list of details
    QMap<QString, QString> wordIpa;               // word (lower) -> ipa string

    QSet<QString> tongueTwisters;
    QStringList expressions;

    QStringList wordHistory;
    int historyIndex = -1;

signals:
    void currentWordChanged();
    void remainingCountChanged();
    void learnOrderModeChanged();
    void knownSequenceChanged();
    void newSequenceChanged();

private:
    QString m_currentWord;
    int m_remainingCount = 0;
    QString m_learnOrderMode = "Random";
    QStringList m_knownSequence;
    QStringList m_newSequence;
};

#endif // APPSTATE_H
