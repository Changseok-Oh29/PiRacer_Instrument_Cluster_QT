#ifndef DBUSRECEIVER_H
#define DBUSRECEIVER_H

#include <QObject>
#include <QDBusConnection>
#include <QJsonObject>

class DBusReceiver : public QObject
{
    Q_OBJECT
    Q_PROPERTY(double batteryCapacity READ batteryCapacity NOTIFY batteryCapacityChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY errorChanged)

public:
    explicit DBusReceiver(QObject *parent = nullptr);
    ~DBusReceiver();

    // Property getters
    double batteryCapacity() const { return m_batteryCapacity; }
    bool connected() const { return m_connected; }
    QString lastError() const { return m_lastError; }

public slots:
    void connectToService();
    void disconnectFromService();

signals:
    void batteryCapacityChanged();
    void connectedChanged();
    void errorChanged();
    void dataReceived(const QJsonObject &data);

private slots:
    void onDataReceived(const QString &dataJson);

private:
    void setConnected(bool connected);
    void setError(const QString &error);
    void updateProperties(const QJsonObject &data);

    QDBusConnection m_connection;
    
    // Data properties
    double m_batteryCapacity;
    bool m_connected;
    QString m_lastError;
    
    // D-Bus service details
    static const QString SERVICE_NAME;
    static const QString OBJECT_PATH;
    static const QString INTERFACE_NAME;
};

#endif // DBUSRECEIVER_H
