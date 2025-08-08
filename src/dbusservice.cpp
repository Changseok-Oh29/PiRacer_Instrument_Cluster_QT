#include "dbusservice.h"
#include <QDebug>

DBusService::DBusService(QObject *parent)
    : QDBusAbstractAdaptor(parent), m_battery(0.0)
{
}

void DBusService::setBattery(double battery)
{
    qDebug() << "[DBusService] setBattery called with value:" << battery;
    m_battery = battery;
}

double DBusService::getBattery()
{
    qDebug() << "[DBusService] getBattery called, returning:" << m_battery;
    return m_battery;
}
