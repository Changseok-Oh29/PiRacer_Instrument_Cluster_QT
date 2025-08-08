#include "dbusservice.h"
#include <QDebug>
#include <QDateTime>

DBusService::DBusService(QObject *parent)
    : QDBusAbstractAdaptor(parent), m_battery(0.0)
{
    qDebug() << "[DBusService]" << QDateTime::currentDateTime().toString("hh:mm:ss.zzz") 
             << "Service initialized with battery:" << m_battery;
}

void DBusService::setBattery(double battery)
{
    QString timestamp = QDateTime::currentDateTime().toString("hh:mm:ss.zzz");
    double oldValue = m_battery;
    m_battery = battery;
    
    qDebug() << "[DBusService]" << timestamp 
             << "setBattery called - Old:" << oldValue 
             << "New:" << battery
             << "Change:" << (battery - oldValue);
}

double DBusService::getBattery()
{
    QString timestamp = QDateTime::currentDateTime().toString("hh:mm:ss.zzz");
    qDebug() << "[DBusService]" << timestamp 
             << "getBattery called, returning:" << m_battery;
    return m_battery;
}
