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

    // Start Python processes
    
    // 1. Start RC example (joystick control)
    QString pythonPath = "python3";
    QString rcScriptPath = QCoreApplication::applicationDirPath() + "/rc_example.py";
    QProcess *pythonRcProcess = new QProcess(&app);
    pythonRcProcess->start(pythonPath, QStringList() << rcScriptPath);

    if (!pythonRcProcess->waitForStarted(3000)) {
        qWarning() << "[MAIN]" << QDateTime::currentDateTime().toString("hh:mm:ss.zzz")
                   << "❌ Failed to start Python RC process:" << rcScriptPath;
    } else {
        qDebug() << "[MAIN]" << QDateTime::currentDateTime().toString("hh:mm:ss.zzz")
                 << "✅ Python RC process started:" << rcScriptPath;
    }

    // 2. Start DBus sender (battery data provider)
    QString dbusScriptPath = QCoreApplication::applicationDirPath() + "/dbussender.py";
    QProcess *pythonDbusProcess = new QProcess(&app);
    pythonDbusProcess->start(pythonPath, QStringList() << dbusScriptPath);

    if (!pythonDbusProcess->waitForStarted(3000)) {
        qWarning() << "[MAIN]" << QDateTime::currentDateTime().toString("hh:mm:ss.zzz")
                   << "❌ Failed to start Python DBus process:" << dbusScriptPath;
    } else {
        qDebug() << "[MAIN]" << QDateTime::currentDateTime().toString("hh:mm:ss.zzz")
                 << "✅ Python DBus process started:" << dbusScriptPath;
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
