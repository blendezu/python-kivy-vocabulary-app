#include "STTService.h"
#include <QStandardPaths>
#include <QDir>
#include <QDebug>
#include <QtConcurrent/QtConcurrent>
#include <QCoreApplication>
#include <QAudioDevice>
#include <QMediaDevices>
#include <QMessageBox>

#include "whisper.h"

STTService::STTService(QObject *parent) : QObject(parent)
{
    // Recording timer
    m_stopTimer = new QTimer(this);
    m_stopTimer->setSingleShot(true);
    connect(m_stopTimer, &QTimer::timeout, this, &STTService::stopRecording);

    // Try to find the model in standard locations
    QStringList potentialPaths = {
        QCoreApplication::applicationDirPath() + "/../Resources/ggml-base.en.bin", // macOS bundle
        QCoreApplication::applicationDirPath() + "/ggml-base.en.bin",             // Linux/Windows
        "../3rdparty/whisper.cpp/models/ggml-base.en.bin",                        // Dev relative path
        "/Users/duongtran/Documents/Projects/Voca/VocaCpp/3rdparty/whisper.cpp/models/ggml-base.en.bin" // Absolute fallback
    };

    for (const auto &path : potentialPaths) {
        if (QFile::exists(path)) {
            loadModel(path);
            break;
        }
    }
}

STTService::~STTService()
{
    if (m_ctx) {
        whisper_free(m_ctx);
    }
}

bool STTService::isRecording() const
{
    return m_recording;
}

bool STTService::isTranscribing() const
{
    return m_transcribing;
}

bool STTService::isModelLoaded() const
{
    return m_ctx != nullptr;
}

void STTService::startRecording()
{
    startListening(0);
}

// New helper to ensure we have a valid audio device
bool STTService::initAudioDevice()
{
    // Clean up old source if exists
    if (m_audioSource) {
        m_audioSource->stop();
        delete m_audioSource;
        m_audioSource = nullptr;
    }

    // 1. Try Default Input
    QAudioDevice device = QMediaDevices::defaultAudioInput();
    if (device.isNull()) {
        qWarning() << "Default audio input is null. Searching all inputs...";
        const auto devices = QMediaDevices::audioInputs();
        if (!devices.isEmpty()) {
            device = devices.first(); // Fallback to first available
        } else {
            qWarning() << "No audio input devices found!";
            return false;
        }
    }

    qDebug() << "Selected Audio Device:" << device.description() << "ID:" << device.id();

    // 2. Select Preferred Format (Robustness)
    QAudioFormat format = device.preferredFormat();
    
    // We prefer 16kHz Mono, but if the device insists on something else (like 48k Float), accept it
    // Whisper needs 16kHz 1ch Float eventually.
    // Let's try to request Mono to simplify conversion if possible.
    if (format.channelCount() != 1) {
        QAudioFormat specific = format;
        specific.setChannelCount(1);
        if (device.isFormatSupported(specific)) {
            format = specific;
        }
    }

    qDebug() << "Final Audio Format -> Rate:" << format.sampleRate() 
             << "Ch:" << format.channelCount() 
             << "Fmt:" << format.sampleFormat();

    // 3. Create Source
    m_audioSource = new QAudioSource(device, format, this);
    if (!m_audioSource) {
        qCritical() << "Failed to create QAudioSource!";
        return false;
    }
    
    // 4. Connect Signals (crucial for error handling)
    connect(m_audioSource, &QAudioSource::stateChanged, this, &STTService::onAudioStateChanged);

    return true;
}

void STTService::startListening(int durationMs)
{
    if (m_recording) return;
    if (m_transcribing) return; 

    if (!m_ctx) {
        emit transcriptionResult("", "Model not loaded. Please ensure ggml-base.en.bin is available.");
        return;
    }
    
    // Always re-init device before recording to handle standard mic changes or permissions
    if (!initAudioDevice()) {
        emit transcriptionResult("", "Failed to initialize microphone.");
        return;
    }
    
    // Reset buffer (Close, Clear, Open)
    if (m_audioBuffer.isOpen()) m_audioBuffer.close();
    m_audioBuffer.setData(QByteArray()); 
    if (!m_audioBuffer.open(QIODevice::ReadWrite | QIODevice::Truncate)) {
         emit transcriptionResult("", "Failed to open audio buffer.");
         return;
    }

    // Start Recording
    m_audioSource->start(&m_audioBuffer);
    
    if (m_audioSource->error() != QAudio::NoError) {
        qWarning() << "Immediate Audio Error:" << m_audioSource->error();
        m_audioBuffer.close();
        emit transcriptionResult("", "Failed to start recording. Check permissions.");
        return;
    }
    
    qDebug() << "Recording started...";
    m_recording = true;
    emit recordingChanged();

    if (durationMs > 0) {
        m_stopTimer->start(durationMs);
    }
}

void STTService::stopRecording()
{
    if (!m_recording) return;

    if (m_stopTimer->isActive()) m_stopTimer->stop();
    
    // Stop writing to buffer
    m_audioSource->stop();
    m_audioBuffer.close();
    
    m_recording = false;
    emit recordingChanged();
    
    // Check raw data immediately
    QByteArray raw = m_audioBuffer.data();
    qDebug() << "Recorded" << raw.size() << "bytes of audio.";
    
    if (raw.isEmpty()) {
        emit transcriptionResult("", "No audio recorded (0 bytes), check microphone permissions.");
        return;
    }

    // Start transcription
    transcribe();
}

void STTService::loadModel(const QString &modelPath)
{
    if (m_ctx) {
        whisper_free(m_ctx);
        m_ctx = nullptr;
    }

    struct whisper_context_params cparams = whisper_context_default_params();
    m_ctx = whisper_init_from_file_with_params(modelPath.toStdString().c_str(), cparams);

    if (m_ctx) {
        qDebug() << "Loaded Whisper model from:" << modelPath;
    } else {
        qWarning() << "Failed to load Whisper model from:" << modelPath;
    }
    emit modelLoadedChanged();
}

void STTService::onAudioStateChanged(QAudio::State state)
{
    if (state == QAudio::StoppedState) {
        if (m_audioSource->error() != QAudio::NoError) {
            qWarning() << "Audio Source Error:" << m_audioSource->error();
            emit transcriptionResult("", "Audio recording error.");
        }
    }
}

void STTService::transcribe()
{
    if (!m_ctx) {
        emit transcriptionResult("", "Model not loaded");
        return;
    }

    // Get data
    QByteArray data = m_audioBuffer.data();
    if (data.isEmpty()) {
        emit transcriptionResult("", "No audio recorded");
        return;
    }

    m_transcribing = true;
    emit transcribingChanged();
    
    // Capture format to use in lambda
    QAudioFormat fmt = m_audioSource->format();

    // Process in background thread
    QtConcurrent::run([this, data, fmt]() {
        // Convert to Float Vector for Whisper
        std::vector<float> pcmf;
        
        if (fmt.sampleFormat() == QAudioFormat::Int16) {
            const int16_t* pcm16 = reinterpret_cast<const int16_t*>(data.constData());
            int n_samples = data.size() / sizeof(int16_t);
            int channels = fmt.channelCount();
            
            // If Stereo, mix to Mono; if Mono, just copy
            int frames = n_samples / channels;
            pcmf.resize(frames);
            
            for (int i = 0; i < frames; i++) {
                float sum = 0.0f;
                for (int c = 0; c < channels; c++) {
                    sum += static_cast<float>(pcm16[i * channels + c]) / 32768.0f;
                }
                pcmf[i] = sum / static_cast<float>(channels);
            }
        } else if (fmt.sampleFormat() == QAudioFormat::Float) {
            const float* pcmFloat = reinterpret_cast<const float*>(data.constData());
            int n_samples = data.size() / sizeof(float);
            int channels = fmt.channelCount();
            
            int frames = n_samples / channels;
            pcmf.resize(frames);
            
            for (int i = 0; i < frames; i++) {
                float sum = 0.0f;
                for (int c = 0; c < channels; c++) {
                    sum += pcmFloat[i * channels + c];
                }
                pcmf[i] = sum / static_cast<float>(channels);
            }
        } else {
             // Fallback for UInt8 or other formats if ever encountered (rare on defaults)
             // For now assume Int16 or Float are the main ones.
             // If UnsignedInt8: (val - 128) / 128.0
             const uint8_t* pcm8 = reinterpret_cast<const uint8_t*>(data.constData());
             int n_samples = data.size(); 
             int channels = fmt.channelCount();
             int frames = n_samples / channels;
             pcmf.resize(frames);
             for(int i=0; i<frames; i++) {
                 float sum = 0.0f;
                 for(int c=0; c<channels; ++c) {
                     sum += (static_cast<float>(pcm8[i*channels + c]) - 128.0f) / 128.0f;
                 }
                 pcmf[i] = sum / static_cast<float>(channels);
             }
        }
        
        // Resample if necessary (Simple linear validation)
        std::vector<float> pcmf_resampled;
        if (fmt.sampleRate() != 16000 && fmt.sampleRate() > 0) {
            // Target 16k
            double ratio = static_cast<double>(fmt.sampleRate()) / 16000.0;
            int new_samples = static_cast<int>(pcmf.size() / ratio);
            pcmf_resampled.resize(new_samples);
            
            for (int i = 0; i < new_samples; i++) {
                double srcIdx = i * ratio;
                int idx0 = static_cast<int>(srcIdx);
                int idx1 = idx0 + 1;
                if (idx1 >= pcmf.size()) idx1 = pcmf.size() - 1;
                double frac = srcIdx - idx0;
                pcmf_resampled[i] = pcmf[idx0] * (1.0 - frac) + pcmf[idx1] * frac;
            }
            // Use resampled data
            pcmf = std::move(pcmf_resampled);
        }

        // Normalize audio (like Python version: audio = audio / max(abs(audio)))
        float max_amp = 0.0f;
        for (float s : pcmf) {
            float abs_s = std::abs(s);
            if (abs_s > max_amp) max_amp = abs_s;
        }
        if (max_amp > 1e-9f) {
            float scale = 1.0f / max_amp;
            for (float &s : pcmf) {
                s *= scale;
            }
        }

        // Run Whisper
        whisper_full_params wparams = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
        wparams.print_progress = false;
        wparams.print_special = false;
        wparams.print_realtime = false;
        wparams.print_timestamps = false;
        wparams.translate = false;
        wparams.language = "en";
        wparams.n_threads = 4; // Use 4 threads
        
        if (whisper_full(m_ctx, wparams, pcmf.data(), pcmf.size()) != 0) {
            QMetaObject::invokeMethod(this, [this]() {
                m_transcribing = false;
                emit transcribingChanged();
                emit transcriptionResult("", "Transcription failed");
            });
            return;
        }

        // Get result
        int n_segments = whisper_full_n_segments(m_ctx);
        QString resultText;
        for (int i = 0; i < n_segments; ++i) {
            const char* text = whisper_full_get_segment_text(m_ctx, i);
            resultText += QString::fromUtf8(text);
        }

        // Cleanup text (remove leading spaces often present in whisper output)
        resultText = resultText.trimmed();
        
        // Remove punctuation for comparison
        // resultText = resultText.remove(QRegularExpression("[^a-zA-Z0-9 ]"));

        QMetaObject::invokeMethod(this, [this, resultText]() {
            m_transcribing = false;
            emit transcribingChanged();
            emit transcriptionResult(resultText, "");
        });
    });
}
