#include "ProgressStore.h"
#include "../models/AppState.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QTimer>
#include <QStandardPaths>
#include <QDir>
#include <QDebug>

ProgressStore::ProgressStore(AppState *state, const QString &filePath, QObject *parent)
    : QObject(parent), m_state(state), m_filePath(filePath)
{
}

bool ProgressStore::load()
{
    QFile file(m_filePath);
    if (!file.exists()) {
        return false;
    }
    if (!file.open(QIODevice::ReadOnly)) {
        return false;
    }
    
    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &err);
    if (err.error != QJsonParseError::NoError) {
        return false;
    }
    
    applySnapshot(doc.object());
    return true;
}

void ProgressStore::saveSync()
{
    doSave(m_filePath);
    m_saveScheduled = false;
}

void ProgressStore::saveAsync()
{
    if (m_saveScheduled) return;
    m_saveScheduled = true;
    
    QTimer::singleShot(200, this, [this]() {
        doSave(m_filePath);
        m_saveScheduled = false;
    });
}

void ProgressStore::doSave(const QString &targetPath)
{
    QJsonDocument doc(buildSnapshot());
    // Use AppDataLocation for atomic write if possible, or direct write
    QString tmpPath = targetPath + ".tmp";
    
    QFile file(tmpPath);
    if (file.open(QIODevice::WriteOnly)) {
        file.write(doc.toJson());
        file.close();
        
        QFile finalFile(targetPath);
        if (finalFile.exists()) {
            finalFile.remove();
        }
        file.rename(targetPath);
    }
}

QJsonObject ProgressStore::buildSnapshot() const
{
    QJsonObject root;
    
    auto toJsonArray = [](const auto &container) {
        QJsonArray arr;
        for (const auto &item : container) arr.append(item);
        return arr;
    };
    
    root["known_words"] = toJsonArray(m_state->knownWords);
    root["new_words"] = toJsonArray(m_state->newWords);
    root["user_words"] = toJsonArray(m_state->userWords);
    root["removed_words"] = toJsonArray(m_state->removedWords);
    
    root["known_sequence"] = toJsonArray(m_state->knownSequence());
    root["new_sequence"] = toJsonArray(m_state->newSequence());
    root["expressions"] = toJsonArray(m_state->expressions);
    root["tongue_twisters"] = toJsonArray(m_state->tongueTwisters);
    root["learned_words"] = toJsonArray(m_state->learnedSession);
    
    root["current_word"] = m_state->currentWord();
    root["learn_order_mode"] = m_state->learnOrderMode();
    
    // Maps
    QJsonObject logObj;
    QMapIterator<QString, QString> i(m_state->learnedLog);
    while (i.hasNext()) {
        i.next();
        logObj[i.key()] = i.value();
    }
    root["learned_log"] = logObj;

    QJsonObject ipaObj;
    QMapIterator<QString, QString> ipaIt(m_state->wordIpa);
    while (ipaIt.hasNext()) {
        ipaIt.next();
        ipaObj[ipaIt.key()] = ipaIt.value();
    }
    root["word_ipa"] = ipaObj;

    QJsonObject detailsObj;
    QMapIterator<QString, QList<WordDetail>> dIt(m_state->wordDetails);
    while (dIt.hasNext()) {
        dIt.next();
        QJsonArray listArr;
        for (const auto &wd : dIt.value()) {
            QJsonObject wdObj;
            wdObj["meaning"] = wd.meaning;
            wdObj["examples"] = toJsonArray(wd.examples);
            wdObj["pos"] = toJsonArray(wd.pos);
            listArr.append(wdObj);
        }
        detailsObj[dIt.key()] = listArr;
    }
    root["word_details"] = detailsObj;
    
    return root;
}

void ProgressStore::applySnapshot(const QJsonObject &root)
{
    auto toStringList = [](const QJsonArray &arr) {
        QStringList list;
        for (const auto &val : arr) list.append(val.toString());
        return list;
    };
    
    auto toStringSet = [](const QJsonArray &arr) {
        QSet<QString> s;
        for (const auto &val : arr) s.insert(val.toString().toLower()); 
        return s;
    };
    
    m_state->userWords = toStringSet(root["user_words"].toArray());
    m_state->removedWords = toStringSet(root["removed_words"].toArray());
    m_state->knownWords = toStringSet(root["known_words"].toArray());
    m_state->newWords = toStringSet(root["new_words"].toArray());
    m_state->tongueTwisters = toStringSet(root["tongue_twisters"].toArray());
    
    m_state->setKnownSequence(toStringList(root["known_sequence"].toArray()));
    m_state->setNewSequence(toStringList(root["new_sequence"].toArray()));
    m_state->expressions = toStringList(root["expressions"].toArray());
    m_state->learnedSession = toStringList(root["learned_words"].toArray());
    
    if (root.contains("current_word")) {
        m_state->setCurrentWord(root["current_word"].toString());
    }
    
    if (root.contains("learn_order_mode")) {
        m_state->setLearnOrderMode(root["learn_order_mode"].toString());
    }

    // Maps
    QJsonObject logObj = root["learned_log"].toObject();
    m_state->learnedLog.clear();
    for(auto it = logObj.begin(); it != logObj.end(); ++it) {
        m_state->learnedLog.insert(it.key(), it.value().toString());
    }

    QJsonObject ipaObj = root["word_ipa"].toObject();
    m_state->wordIpa.clear();
    for(auto it = ipaObj.begin(); it != ipaObj.end(); ++it) {
        m_state->wordIpa.insert(it.key(), it.value().toString());
    }

    QJsonObject detailsObj = root["word_details"].toObject();
    m_state->wordDetails.clear();
    for(auto it = detailsObj.begin(); it != detailsObj.end(); ++it) {
        QList<WordDetail> list;
        QJsonArray arr = it.value().toArray();
        for(const auto &v : arr) {
            QJsonObject o = v.toObject();
            WordDetail wd;
            wd.meaning = o["meaning"].toString();
            wd.examples = toStringList(o["examples"].toArray());
            wd.pos = toStringList(o["pos"].toArray());
            list.append(wd);
        }
        m_state->wordDetails.insert(it.key(), list);
    }
}
