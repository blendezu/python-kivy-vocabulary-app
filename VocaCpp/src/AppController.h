#ifndef APPCONTROLLER_H
#define APPCONTROLLER_H

#include <QObject>
#include <QRandomGenerator>
#include "models/AppState.h"
#include "persistence/ProgressStore.h"
#include "services/TTSService.h"
#include "services/STTService.h"

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

    // Learn Mode
    Q_INVOKABLE void nextLearnWord();
    Q_INVOKABLE void markLearnWordKnown();
    Q_INVOKABLE void removeLearnWord();

    // Review Mode
    Q_INVOKABLE int getReviewMatchingCount(const QString &startStr, const QString &endStr, bool twisterOnly);
    Q_INVOKABLE void startReview(const QString &startStr, const QString &endStr, bool twisterOnly);
    Q_INVOKABLE void nextReviewWord();
    Q_INVOKABLE void markReviewWordKnown();



    // Stats
    Q_INVOKABLE QVariantMap getDashboardStats() const;
    
    // Editor
    Q_INVOKABLE void updateWordDetails(const QString &word, const QVariantList &details, const QString &ipa);

private:
    void rebuildEligiblePool();
    QString getRandomWord();

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
};


#endif // APPCONTROLLER_H
