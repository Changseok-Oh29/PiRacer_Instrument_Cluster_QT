// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QDebug>
#include <QQmlContext>
#include <QProcess>
#include <QDBusConnection>
#include <QDateTime>

#include "app_environment.h"
#include "import_qml_components_plugins.h"
#include "import_qml_plugins.h"
#include "canreceiver.h"
#include "dbusreceiver.h"

int main(int argc, char *argv[])
{
    set_qt_environment();

    QGuiApplication app(argc, argv);

    qDebug() << "[MAIN]" << QDateTime::currentDateTime().toString("hh:mm:ss.zzz")
             << "🚀 Starting PiRacer Instrument Cluster Application";

    // Setup DBus service
    qDebug() << "[MAIN]" << QDateTime::currentDateTime().toString("hh:mm:ss.zzz")
             << "🔧 Starting application...";

    // run python
    QString pythonPath = "python3"; // Adjust for Windows: \venv\Scripts\python.exe
    QString scriptPath = QCoreApplication::applicationDirPath() + "/rc_example.py";
    QProcess *pythonProcess = new QProcess(&app);
    pythonProcess->start(pythonPath, QStringList() << scriptPath);

    if (!pythonProcess->waitForStarted(3000)) {
        qWarning("Failed to start Python joystick process");
    }

    // Create CAN receiver instance
    CanReceiver canReceiver;
    
    // Create DBus receiver instance
    DBusReceiver dbusReceiver;
    
    QQmlApplicationEngine engine;
    
    // Register CAN receiver with QML context
    engine.rootContext()->setContextProperty("canReceiver", &canReceiver);
    
    // Register DBus receiver with QML context
    engine.rootContext()->setContextProperty("dbusReceiver", &dbusReceiver);
    
    // For static builds, just add the basic resource paths
    engine.addImportPath("qrc:/");
    engine.addImportPath(":/");
    
    // Add debugging for QML import paths
    qDebug() << "QML Import Paths:";
    for (const QString &path : engine.importPathList()) {
        qDebug() << "  " << path;
    }
    
    const QUrl url(u"qrc:Main/main.qml"_qs);
    QObject::connect(
                &engine, &QQmlApplicationEngine::objectCreated, &app,
                [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            qDebug() << "Failed to load main QML file:" << url;
            QCoreApplication::exit(-1);
        } else if (obj) {
            qDebug() << "Successfully loaded QML file:" << url;
        }
    },
    Qt::QueuedConnection);

    qDebug() << "Loading QML file:" << url;
    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
