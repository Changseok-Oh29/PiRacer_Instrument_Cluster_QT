// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QDebug>
#include <QQmlContext>

#include "app_environment.h"
#include "import_qml_components_plugins.h"
#include "import_qml_plugins.h"
#include "canreceiver.h"

int main(int argc, char *argv[])
{
    set_qt_environment();

    QGuiApplication app(argc, argv);

    // Create CAN receiver instance
    CanReceiver canReceiver;
    
    QQmlApplicationEngine engine;
    
    // Register CAN receiver with QML context
    engine.rootContext()->setContextProperty("canReceiver", &canReceiver);
    
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
