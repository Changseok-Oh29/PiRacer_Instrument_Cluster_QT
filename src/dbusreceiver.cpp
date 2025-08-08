#include "dbusreceiver.h"
#include <QDebug>
#include <QDBusReply>
#include <QDateTime>

DBusReceiver::DBusReceiver(QObject *parent)
    : QObject(parent),
      m_battery(0.0)
{
    qDebug() << "[DBusReceiver]" << QDateTime::currentDateTime().toString("hh:mm:ss.zzz")
             << "Initializing DBus connection...";
             
    m_interface = new QDBusInterface(
        "org.team7.IC", "/CarInformation", "org.team7.IC.Interface",
        QDBusConnection::sessionBus(), this
    );

    if (!m_interface->isValid()) {
        qWarning() << "[DBusReceiver]" << QDateTime::currentDateTime().toString("hh:mm:ss.zzz")
                   << "❌ Failed to connect to DBus interface!";
        qWarning() << "[DBusReceiver] Error:" << m_interface->lastError().message();
        return;
    }

    qDebug() << "[DBusReceiver]" << QDateTime::currentDateTime().toString("hh:mm:ss.zzz")
             << "✅ Successfully connected to DBus service";

    // Connect to the DataReceived signal from Python service
    bool connected = QDBusConnection::sessionBus().connect(
        "org.team7.IC",
        "/CarInformation", 
        "org.team7.IC.Interface",
        "DataReceived",
        "s",  // Add explicit signature
        this,
        SLOT(onDataReceived(QString))
    );
    
    if (connected) {
        qDebug() << "[DBusReceiver]" << QDateTime::currentDateTime().toString("hh:mm:ss.zzz")
                 << "✅ Connected to DataReceived signal";
    } else {
        qWarning() << "[DBusReceiver]" << QDateTime::currentDateTime().toString("hh:mm:ss.zzz")
                   << "❌ Failed to connect to DataReceived signal";
    }
}

void DBusReceiver::onDataReceived(const QString &dataJson) {
    QString timestamp = QDateTime::currentDateTime().toString("hh:mm:ss.zzz");
    
    qDebug() << "[DBusReceiver]" << timestamp 
             << "📨 Received D-Bus data:" << dataJson;
    
    // Parse JSON data
    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(dataJson.toUtf8(), &error);
    
    if (error.error != QJsonParseError::NoError) {
        qWarning() << "[DBusReceiver]" << timestamp 
                   << "❌ Failed to parse JSON:" << error.errorString();
        return;
    }
    
    QJsonObject data = doc.object();
    
    // Update battery capacity if present
    if (data.contains("battery_capacity") && data["battery_capacity"].isDouble()) {
        double newValue = data["battery_capacity"].toDouble();
        double oldValue = m_battery;
        
        if (!qFuzzyCompare(m_battery, newValue)) {
            m_battery = newValue;
            qDebug() << "[DBusReceiver]" << timestamp 
                     << "🔋 Battery updated - Old:" << oldValue 
                     << "New:" << newValue 
                     << "Change:" << (newValue - oldValue);
            emit batteryChanged();
        }
    }
}
