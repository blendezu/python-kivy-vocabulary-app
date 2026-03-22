#include "TTSService.h"
#include <QDebug>

TTSService::TTSService(QObject *parent) : QObject(parent)
{
    m_speech = new QTextToSpeech(this);
    
    // Enforce English locale to avoid using system default (e.g. German) for English words
    m_speech->setLocale(QLocale(QLocale::English));
    
    // Try to find a high quality English voice
    // Auto-selects default engine and voice, but let's debug available voices
    const auto voices = m_speech->availableVoices();
    QVoice preferredVoice;
    bool found = false;
    
    for (const auto &voice : voices) {
        // Prefer "Samantha" on macOS or any English voice
        if (voice.name().contains("Samantha") || voice.name().contains("Stephanie") || voice.name().contains("Google US English")) {
             preferredVoice = voice;
             found = true;
             break;
        }
    }
    
    if (found) {
        m_speech->setVoice(preferredVoice);
    } else {
        // Fallback: pick any English voice
        for (const auto &voice : voices) {
            if (voice.locale().language() == QLocale::English) {
                m_speech->setVoice(voice);
                break;
            }
        }
    }
}

bool TTSService::isReady() const
{
    return m_speech && m_speech->state() == QTextToSpeech::Ready;
}

void TTSService::speak(const QString &text)
{
    if (!m_speech) return;
    
    qDebug() << "TTS Speaking:" << text;
    m_speech->say(text);
}

void TTSService::stop()
{
    if (m_speech) m_speech->stop();
}
