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
        "org.team7.IC", "/CarInformation", "org.team7.IC.CarInformation",
        QDBusConnection::systemBus(), this
    );

    if (!m_interface->isValid()) {
        qWarning() << "[DBusReceiver]" << QDateTime::currentDateTime().toString("hh:mm:ss.zzz")
                   << "❌ Failed to connect to DBus interface!";
        qWarning() << "[DBusReceiver] Error:" << m_interface->lastError().message();
        return;
    }

    qDebug() << "[DBusReceiver]" << QDateTime::currentDateTime().toString("hh:mm:ss.zzz")
             << "✅ Successfully connected to DBus service";

    pollTimer = new QTimer(this);
    connect(pollTimer, &QTimer::timeout, this, &DBusReceiver::updateBattery);
    pollTimer->start(100);
    
    qDebug() << "[DBusReceiver]" << QDateTime::currentDateTime().toString("hh:mm:ss.zzz")
             << "⏰ Started polling timer (100ms interval)";
}

void DBusReceiver::updateBattery() {
    QString timestamp = QDateTime::currentDateTime().toString("hh:mm:ss.zzz");
    
    QDBusReply<double> reply = m_interface->call("getBattery");
    if (reply.isValid()) {
        double newValue = reply.value();
        double oldValue = m_battery;
        
        if (!qFuzzyCompare(m_battery, newValue)) {
            m_battery = newValue;
            qDebug() << "[DBusReceiver]" << timestamp 
                     << "🔋 Battery updated - Old:" << oldValue 
                     << "New:" << newValue 
                     << "Change:" << (newValue - oldValue);
            emit batteryChanged();
        } else {
            // Uncomment below line if you want to see every poll attempt
            // qDebug() << "[DBusReceiver]" << timestamp << "🔋 Battery unchanged:" << m_battery;
        }
    }
    else {
        qWarning() << "[DBusReceiver]" << timestamp 
                   << "❌ Failed to getBattery:" << reply.error().message();
    }
}
