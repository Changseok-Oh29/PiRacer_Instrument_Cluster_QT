#ifndef DBUSRECEIVER_H
#define DBUSRECEIVER_H

#include <QObject>
#include <QDBusInterface>
#include <QTimer>

class DBusReceiver : public QObject
{
    Q_OBJECT
    Q_PROPERTY(double battery READ battery NOTIFY batteryChanged)
    

public:
    explicit DBusReceiver(QObject *parent = nullptr);

    // Property getters
    double battery() const { return m_battery; }

signals:
    void batteryChanged();

public slots:
    void updateBattery();

private:
    QDBusInterface *m_interface;
    double m_battery;
    QTimer *pollTimer;
};

#endif // DBUSRECEIVER_H
