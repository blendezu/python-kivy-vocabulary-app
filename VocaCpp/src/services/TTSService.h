#ifndef TTSSERVICE_H
#define TTSSERVICE_H

#include <QObject>
#include <QTextToSpeech>

class TTSService : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isReady READ isReady NOTIFY readyChanged)

public:
    explicit TTSService(QObject *parent = nullptr);

    bool isReady() const;
    Q_INVOKABLE void speak(const QString &text);
    Q_INVOKABLE void stop();

signals:
    void readyChanged();

private:
    QTextToSpeech *m_speech = nullptr;
};

#endif // TTSSERVICE_H
