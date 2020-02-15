#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QSettings>

#include "rcontroller.h"

int main(int argc, char *argv[])
{
    QCoreApplication::setOrganizationName("AydoLabs");
    QCoreApplication::setOrganizationDomain("aydolabs.com");
    QCoreApplication::setApplicationName("Akıllı Lamba");
    QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QSettings tSettings;

    QGuiApplication a(argc, argv);

    RController* tController = new RController();
    tController->init();

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("controller", tController);

    engine.load(QUrl("qrc:/main.qml"));
    if (engine.rootObjects().isEmpty())
        return -1;

    return a.exec();
}
