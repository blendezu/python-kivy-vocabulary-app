#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "AppController.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    AppController controller;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("app", &controller);

    const QUrl url(u"qrc:/Voca/src/ui/Main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
