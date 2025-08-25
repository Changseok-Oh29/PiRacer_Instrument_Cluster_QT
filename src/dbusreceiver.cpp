#include "dbusreceiver.h"
#include <QDebug>
#include <QDBusReply>
#include <QDateTime>
#include <QTimer>

DBusReceiver::DBusReceiver(QObject *parent)
    : QObject(parent),
      m_interface(nullptr),
      m_retryTimer(new QTimer(this)),
      m_battery(0.0),
      m_chargingCurrent(0.0),
      m_leftTurnSignal(false),
      m_rightTurnSignal(false),
      m_retryCount(0)
{
    qDebug() << "[DBusReceiver]" << QDateTime::currentDateTime().toString("hh:mm:ss.zzz")
             << "Initializing DBus connection with retry logic...";
    
    // Set up retry timer
    m_retryTimer->setSingleShot(true);
    connect(m_retryTimer, &QTimer::timeout, this, &DBusReceiver::tryConnectToDBus);
    
    // Start first connection attempt after a short delay to let Python service start
    QTimer::singleShot(1000, this, &DBusReceiver::tryConnectToDBus);
}

void DBusReceiver::tryConnectToDBus() {
    if (m_retryCount >= MAX_RETRIES) {
        qWarning() << "[DBusReceiver]" << QDateTime::currentDateTime().toString("hh:mm:ss.zzz")
                   << "❌ Maximum retry attempts reached. DBus connection failed.";
        return;
    }
    
    m_retryCount++;
    qDebug() << "[DBusReceiver]" << QDateTime::currentDateTime().toString("hh:mm:ss.zzz")
             << "🔄 Attempting DBus connection (attempt" << m_retryCount << "/" << MAX_RETRIES << ")";
    
    connectToDBus();
}

void DBusReceiver::connectToDBus() {
    // Clean up previous interface if exists
    if (m_interface) {
        delete m_interface;
        m_interface = nullptr;
    }
             
    m_interface = new QDBusInterface(
        "org.team7.IC", "/CarInformation", "org.team7.IC.Interface",
        QDBusConnection::sessionBus(), this
    );

    if (!m_interface->isValid()) {
        qWarning() << "[DBusReceiver]" << QDateTime::currentDateTime().toString("hh:mm:ss.zzz")
                   << "❌ Failed to connect to DBus interface! (attempt" << m_retryCount << ")";
        qWarning() << "[DBusReceiver] Error:" << m_interface->lastError().message();
        
        // Retry after 2 seconds
        m_retryTimer->start(2000);
        return;
    }

    qDebug() << "[DBusReceiver]" << QDateTime::currentDateTime().toString("hh:mm:ss.zzz")
             << "✅ Successfully connected to DBus service on attempt" << m_retryCount;

    // Connect to the DataReceived signal from Python service
    bool connected = QDBusConnection::sessionBus().connect(
        "org.team7.IC",
        "/CarInformation",
        "org.team7.IC.Interface",
        "DataReceived",
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

    // Update charging current if present
    if (data.contains("charging_current") && data["charging_current"].isDouble()) {
        double newValue = data["charging_current"].toDouble();
        double oldValue = m_chargingCurrent;

        if (!qFuzzyCompare(m_chargingCurrent, newValue)) {
            m_chargingCurrent = newValue;
            qDebug() << "[DBusReceiver]" << timestamp
                     << "⚡ Charging current updated - Old:" << oldValue
                     << "New:" << newValue << "mA"
                     << "Change:" << (newValue - oldValue) << "mA";
            emit chargingCurrentChanged();
        }
    }
    
    // Update left turn signal if present
    if (data.contains("left_turn_signal") && data["left_turn_signal"].isBool()) {
        bool newValue = data["left_turn_signal"].toBool();
        
        if (m_leftTurnSignal != newValue) {
            m_leftTurnSignal = newValue;
            qDebug() << "[DBusReceiver]" << timestamp
                     << "🔄 Left turn signal updated:" << (newValue ? "ON" : "OFF");
            emit leftTurnSignalChanged();
        }
    }
    
    // Update right turn signal if present
    if (data.contains("right_turn_signal") && data["right_turn_signal"].isBool()) {
        bool newValue = data["right_turn_signal"].toBool();
        
        if (m_rightTurnSignal != newValue) {
            m_rightTurnSignal = newValue;
            qDebug() << "[DBusReceiver]" << timestamp
                     << "🔄 Right turn signal updated:" << (newValue ? "ON" : "OFF");
            emit rightTurnSignalChanged();
        }
    }
}
