#include "dbusreceiver.h"
#include <QDebug>
#include <QDBusReply>


DBusReceiver::DBusReceiver(QObject *parent)
    : QObject(parent),
      m_battery(0.0)
{
    m_interface = new QDBusInterface(
        "org.team7.IC", "/CarInformation", "org.team7.IC.CarInformation",
        QDBusConnection::systemBus(), this
    );

    if (!m_interface->isValid()) {
        qWarning() << "Failed to connect to DBus interface.";
        return;
    }

    pollTimer = new QTimer(this);
    connect(pollTimer, &QTimer::timeout, this, &DBusReceiver::updateBattery);
    pollTimer->start(100);
}

void DBusReceiver::updateBattery() {
    QDBusReply<double> reply = m_interface->call("getBattery");
    if (reply.isValid()) {
        double newValue = reply.value();
        if (!qFuzzyCompare(m_battery, newValue)) {
            m_battery = newValue;
            emit batteryChanged();
        }
    }
    else {
        qWarning() << "Failed to getBattery:" << reply.error().message();
    }
}
