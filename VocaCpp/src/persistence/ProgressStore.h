#ifndef PROGRESSSTORE_H
#define PROGRESSSTORE_H

#include <QObject>
#include <QString>
#include <QFileInfo>
#include <QJsonObject>

class AppState;

class ProgressStore : public QObject
{
    Q_OBJECT
public:
    explicit ProgressStore(AppState *state, const QString &filePath, QObject *parent = nullptr);

    bool load();
    void saveSync();
    void saveAsync();

private:
    QJsonObject buildSnapshot() const;
    void applySnapshot(const QJsonObject &root);
    void doSave(const QString &targetPath);

    AppState *m_state;
    QString m_filePath;
    bool m_saveScheduled = false;
};

#endif // PROGRESSSTORE_H
