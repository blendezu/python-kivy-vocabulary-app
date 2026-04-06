#ifndef APPCONTROLLER_H
#define APPCONTROLLER_H

#include <QObject>
#include <QRandomGenerator>
#include <QByteArray>
#include <QJsonObject>
#include "models/AppState.h"
#include "persistence/ProgressStore.h"
#include "services/TTSService.h"
#include "services/STTService.h"

class QProcess;

class AppController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(AppState* state READ state CONSTANT)
    Q_PROPERTY(TTSService* tts READ tts CONSTANT)
    Q_PROPERTY(STTService* stt READ stt CONSTANT)

public:
    explicit AppController(QObject *parent = nullptr);

    AppState* state() const;
    TTSService* tts() const;
    STTService* stt() const;

    Q_INVOKABLE void requestNextWord();
    Q_INVOKABLE void markWordKnown(const QString &word);
    Q_INVOKABLE void markWordNew(const QString &word);
    Q_INVOKABLE void removeCurrentWord();
    Q_INVOKABLE void save();

    // List Transfer Methods
    Q_INVOKABLE void moveWordToKnown(const QString &word);
    Q_INVOKABLE void moveWordToNew(const QString &word);
    Q_INVOKABLE void removeWord(const QString &word);
    Q_INVOKABLE void restoreRemovedWord(const QString &word);
    Q_INVOKABLE void correctWord(const QString &oldWord, const QString &newWord);

    // Learn
    Q_INVOKABLE QStringList getNewWordsList() const;
    Q_INVOKABLE QString nextLearnWord();
    Q_INVOKABLE void markLearnWordKnown();
    Q_INVOKABLE void removeLearnWord();

    // Review Mode
    Q_INVOKABLE int getReviewMatchingCount(const QString &startStr, const QString &endStr, bool twisterOnly);
    Q_INVOKABLE QVariantList getReviewPool(const QString &startStr, const QString &endStr, bool twisterOnly) const;
    Q_INVOKABLE void startReview(const QString &startStr, const QString &endStr, bool twisterOnly);
    Q_INVOKABLE void nextReviewWord();
    Q_INVOKABLE void markReviewWordKnown();



    // Stats
    Q_INVOKABLE QVariantMap getDashboardSummary() const;
    Q_INVOKABLE QVariantMap getDailyStats(int offsetDay) const;
    Q_INVOKABLE QVariantMap getMonthlyStats(int year) const;

    // Editor
    Q_INVOKABLE void updateWordDetails(const QString &word, const QVariantList &details, const QString &ipa, bool isTongueTwister);
    Q_INVOKABLE QVariantList getWordDetails(const QString &word) const;
    Q_INVOKABLE QString getWordIpa(const QString &word) const;
    Q_INVOKABLE bool isTongueTwister(const QString &word) const;

    // Text Analysis & Adding Words
    Q_INVOKABLE int addNewWordsFromText(const QString &text);
    Q_INVOKABLE QStringList findWordsInText(const QString &text);

    // Learned Words & Expressions List
    Q_INVOKABLE QVariantList getLearnedWordsAndExpressions(const QString &query, bool onlyTwister) const;

    // Expressions
    Q_INVOKABLE QStringList getExpressions() const;
    Q_INVOKABLE QVariantList getExpressionsWithDetails(const QString &query) const;
    Q_INVOKABLE void addExpression(const QString &phrase, const QVariantList &details);
    Q_INVOKABLE int addWords(const QStringList &words);
    Q_INVOKABLE QVariantMap warmupTranslator();
    Q_INVOKABLE QVariantMap translateText(const QString &text, const QString &sourceLangCode, const QString &targetLangCode);

private:
    void rebuildEligiblePool();
    QString getRandomWord();
    QString resolveNllbScriptPath() const;
    bool ensureTranslateWorker(QString &errorMessage);
    QVariantMap translateTextOneShot(const QString &text, const QString &sourceLangCode, const QString &targetLangCode) const;
    bool readWorkerJsonLine(QJsonObject &obj, QString &errorMessage, int timeoutMs);

    AppState *m_state;
    ProgressStore *m_store;
    TTSService *m_tts;
    STTService *m_stt;
    
    QStringList m_eligiblePool;
    bool m_eligibleDirty = true;
    
    int m_learnIdx = 0;
    void updateLearnWord();

    QStringList m_reviewPool;
    int m_reviewIdx = 0;

    QProcess *m_translateWorker = nullptr;
    QByteArray m_translateStdoutBuffer;
    QString m_translateWorkerDevice;
    QString m_translateWorkerModel;
    QString m_translateWorkerWarning;
};


#endif // APPCONTROLLER_H
