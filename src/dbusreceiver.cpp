#include "dbusreceiver.h"
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>

const QString DBusReceiver::SERVICE_NAME = "com.piracer.DataSender";
const QString DBusReceiver::OBJECT_PATH = "/com/piracer/DataSender";
const QString DBusReceiver::INTERFACE_NAME = "com.piracer.DataSender.Interface";

DBusReceiver::DBusReceiver(QObject *parent)
    : QObject(parent)
    , m_connection(QDBusConnection::sessionBus())
    , m_batteryCapacity(0.0)
    , m_connected(false)
{
    connectToService();
}

DBusReceiver::~DBusReceiver()
{
    disconnectFromService();
}

void DBusReceiver::connectToService()
{
    if (!m_connection.isConnected()) {
        qWarning() << "D-Bus session bus is not connected";
        setConnected(false);
        return;
    }

    // Connect to the DataReceived signal
    bool success = m_connection.connect(
        SERVICE_NAME,
        OBJECT_PATH,
        INTERFACE_NAME,
        "DataReceived",
        this,
        SLOT(onDataReceived(QString))
    );

    if (success) {
        qDebug() << "Successfully connected to D-Bus service";
        setConnected(true);
    } else {
        qWarning() << "Failed to connect to D-Bus service";
        setConnected(false);
    }
}

void DBusReceiver::disconnectFromService()
{
    if (m_connection.isConnected()) {
        m_connection.disconnect(
            SERVICE_NAME,
            OBJECT_PATH,
            INTERFACE_NAME,
            "DataReceived",
            this,
            SLOT(onDataReceived(QString))
        );
    }
    setConnected(false);
}

void DBusReceiver::onDataReceived(const QString &dataJson)
{
    qDebug() << "Received D-Bus data:" << dataJson;
    
    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(dataJson.toUtf8(), &error);
    
    if (error.error != QJsonParseError::NoError) {
        qWarning() << "Failed to parse JSON data:" << error.errorString();
        return;
    }
    
    QJsonObject data = doc.object();
    updateProperties(data);
    emit dataReceived(data);
}

void DBusReceiver::updateProperties(const QJsonObject &data)
{
    if (data.contains("battery_capacity") && data["battery_capacity"].isDouble()) {
        double newBatteryCapacity = data["battery_capacity"].toDouble();
        if (newBatteryCapacity != m_batteryCapacity) {
            m_batteryCapacity = newBatteryCapacity;
            emit batteryCapacityChanged();
        }
    }
}

void DBusReceiver::setConnected(bool connected)
{
    if (m_connected != connected) {
        m_connected = connected;
        emit connectedChanged();
    }
}

void DBusReceiver::setError(const QString &error)
{
    if (m_lastError != error) {
        m_lastError = error;
        emit errorChanged();
    }
}
