#include "STTService.h"
#include <QStandardPaths>
#include <QDir>
#include <QDebug>
#include <QThread>

STTService::STTService(QObject *parent) : QObject(parent)
{
    m_audioInput = new QAudioInput(this);
    m_recorder = new QMediaRecorder(this);
    m_session.setAudioInput(m_audioInput);
    m_session.setRecorder(m_recorder);

    connect(m_recorder, &QMediaRecorder::recorderStateChanged, this, &STTService::onRecorderStateChanged);
}

bool STTService::isRecording() const
{
    return m_recording;
}

void STTService::startRecording()
{
    if (m_recording) return;

    QString path = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    QUrl url = QUrl::fromLocalFile(path + "/voca_voice_input.m4a");
    
    m_recorder->setOutputLocation(url);
    m_recorder->record();
}

void STTService::stopRecording()
{
    if (!m_recording) return;
    m_recorder->stop();
    // Logic continues in onRecorderStateChanged when state becomes Stopped
}

void STTService::onRecorderStateChanged(QMediaRecorder::RecorderState state)
{
    bool wasRecording = m_recording;
    m_recording = (state == QMediaRecorder::RecordingState);

    if (wasRecording != m_recording) {
        emit recordingChanged();
    }

    if (wasRecording && !m_recording) {
        // Just finished recording
        transcribeFile(m_recorder->outputLocation());
    }
}

void STTService::transcribeFile(const QUrl &url)
{
    qDebug() << "Transcribing file:" << url.toLocalFile();
    
    // Placeholder for Whisper.cpp integration
    // In a real implementation, we would pass the raw audio data (PCM) to whisper
    // Since QMediaRecorder usually saves encoded files (AAC/M4A), we might need to decode it first
    // or use QAudioSource to get raw PCM buffer directly.
    
    // For this migration skeleton, we maintain the "Structure".
    // TODO: Implement whisper.cpp inference here.
    
    emit transcriptionResult("Simulation: You said something hello", "");
}
