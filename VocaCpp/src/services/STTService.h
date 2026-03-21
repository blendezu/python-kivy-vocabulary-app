#ifndef STTSERVICE_H
#define STTSERVICE_H

#include <QObject>
#include <QMediaCaptureSession>
#include <QAudioInput>
#include <QMediaRecorder>
#include <QUrl>

class STTService : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isRecording READ isRecording NOTIFY recordingChanged)

public:
    explicit STTService(QObject *parent = nullptr);

    bool isRecording() const;
    
    Q_INVOKABLE void startRecording();
    Q_INVOKABLE void stopRecording();

signals:
    void recordingChanged();
    void transcriptionResult(const QString &text, const QString &error);

private slots:
    void onRecorderStateChanged(QMediaRecorder::RecorderState state);

private:
    void transcribeFile(const QUrl &url);

    QMediaCaptureSession m_session;
    QAudioInput *m_audioInput;
    QMediaRecorder *m_recorder;
    bool m_recording = false;
};

#endif // STTSERVICE_H
