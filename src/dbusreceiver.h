#ifndef DBUSRECEIVER_H
#define DBUSRECEIVER_H

#include <QObject>
#include <QDBusInterface>
#include <QJsonDocument>
#include <QJsonObject>

class DBusReceiver : public QObject
{
    Q_OBJECT
    Q_PROPERTY(double battery READ battery NOTIFY batteryChanged)
    Q_PROPERTY(double chargingCurrent READ chargingCurrent NOTIFY chargingCurrentChanged)


public:
    explicit DBusReceiver(QObject *parent = nullptr);

    // Property getters
    double battery() const { return m_battery; }
    double chargingCurrent() const { return m_chargingCurrent; }

signals:
    void batteryChanged();
    void chargingCurrentChanged();

public slots:
    void onDataReceived(const QString &dataJson);

private:
    QDBusInterface *m_interface;
    double m_battery;
    double m_chargingCurrent;
};

#endif // DBUSRECEIVER_H
