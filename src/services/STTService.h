#ifndef STTSERVICE_H
#define STTSERVICE_H

#include <QObject>
#include <QAudioSource>
#include <QBuffer>
#include <QMediaDevices>
#include <QAudioDevice>
#include <QTimer>
#include <vector>

struct whisper_context;

class STTService : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isRecording READ isRecording NOTIFY recordingChanged)
    Q_PROPERTY(bool isTranscribing READ isTranscribing NOTIFY transcribingChanged)
    Q_PROPERTY(bool isModelLoaded READ isModelLoaded NOTIFY modelLoadedChanged)

public:
    explicit STTService(QObject *parent = nullptr);
    ~STTService();

    bool isRecording() const;
    bool isTranscribing() const;
    bool isModelLoaded() const;

    Q_INVOKABLE void startRecording();
    Q_INVOKABLE void startListening(int durationMs = 3000); // New: Match Python's fixed duration
    Q_INVOKABLE void stopRecording();
    Q_INVOKABLE void loadModel(const QString &modelPath);

signals:
    void recordingChanged();
    void transcribingChanged();
    void modelLoadedChanged();
    void transcriptionResult(const QString &text, const QString &error);

private:
    void onAudioStateChanged(QAudio::State state);
    void transcribe();
    bool initAudioDevice();

    QTimer *m_stopTimer = nullptr;
    QAudioSource *m_audioSource = nullptr;
    QBuffer m_audioBuffer;
    whisper_context *m_ctx = nullptr;
    bool m_recording = false;
    bool m_transcribing = false;
};

#endif // STTSERVICE_H
