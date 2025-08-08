#ifndef DBUSSERVICE_H
#define DBUSSERVICE_H

#include <QObject>
#include <QDBusAbstractAdaptor>

class DBusService : public QDBusAbstractAdaptor
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.team7.IC.CarInformation")

public:
    explicit DBusService(QObject *parent = nullptr);

public slots:
    void setBattery(double battery);
    double getBattery();

private:
    double m_battery;
};

#endif // DBUSSERVICE_H
