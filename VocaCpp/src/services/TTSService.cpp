#include "TTSService.h"
#include <QDebug>

TTSService::TTSService(QObject *parent) : QObject(parent)
{
    m_speech = new QTextToSpeech(this);
    // Auto-selects default engine and voice
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
