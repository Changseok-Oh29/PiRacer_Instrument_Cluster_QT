#include "canreceiver.h"
#include <QDebug>
#include <QSocketNotifier>
#include <cstring>
#include <fcntl.h>

CanReceiver::CanReceiver(QObject *parent)
    : QObject(parent)
    , m_socket(-1)
    , m_speed(0.0f)
    , m_rpm(0.0f)
    , m_connected(false)
    , m_readTimer(new QTimer(this))
    , m_interface("can10")
{
    // Set up timer for periodic reading
    m_readTimer->setInterval(50); // Read every 50ms
    connect(m_readTimer, &QTimer::timeout, this, &CanReceiver::readCanData);
}

CanReceiver::~CanReceiver()
{
    disconnectFromCan();
}

void CanReceiver::connectToCan(const QString &interface)
{
    if (m_connected) {
        disconnectFromCan();
    }

    m_interface = interface;
    setupSocket(interface);
}

void CanReceiver::disconnectFromCan()
{
    stopListening();
    closeSocket();
}

void CanReceiver::startListening()
{
    if (m_connected && !m_readTimer->isActive()) {
        m_readTimer->start();
        qDebug() << "Started CAN listening on" << m_interface;
    }
}

void CanReceiver::stopListening()
{
    if (m_readTimer->isActive()) {
        m_readTimer->stop();
        qDebug() << "Stopped CAN listening";
    }
}

void CanReceiver::setupSocket(const QString &interface)
{
    struct sockaddr_can addr;
    struct ifreq ifr;

    // Create socket
    m_socket = socket(PF_CAN, SOCK_RAW, CAN_RAW);
    if (m_socket < 0) {
        emit errorOccurred("Failed to create CAN socket");
        return;
    }

    // Set socket to non-blocking mode
    int flags = fcntl(m_socket, F_GETFL, 0);
    fcntl(m_socket, F_SETFL, flags | O_NONBLOCK);

    // Get interface index
    strcpy(ifr.ifr_name, interface.toLocal8Bit().data());
    if (ioctl(m_socket, SIOCGIFINDEX, &ifr) < 0) {
        emit errorOccurred(QString("Failed to get interface index for %1").arg(interface));
        closeSocket();
        return;
    }

    // Bind socket
    addr.can_family = AF_CAN;
    addr.can_ifindex = ifr.ifr_ifindex;

    if (bind(m_socket, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        emit errorOccurred(QString("Failed to bind to CAN interface %1").arg(interface));
        closeSocket();
        return;
    }

    m_connected = true;
    emit connectedChanged();
    qDebug() << "Connected to CAN interface:" << interface;
}

void CanReceiver::closeSocket()
{
    if (m_socket >= 0) {
        close(m_socket);
        m_socket = -1;
    }
    
    if (m_connected) {
        m_connected = false;
        emit connectedChanged();
    }
}

void CanReceiver::readCanData()
{
    if (!m_connected || m_socket < 0) {
        return;
    }

    struct can_frame frame;
    ssize_t nbytes;

    // Read all available frames
    while ((nbytes = read(m_socket, &frame, sizeof(struct can_frame))) > 0) {
        if (nbytes == sizeof(struct can_frame)) {
            processCanFrame(frame);
        }
    }
}

void CanReceiver::processCanFrame(const struct can_frame &frame)
{
    qDebug() << "Received CAN frame - ID:" << QString::number(frame.can_id, 16) 
             << "DLC:" << frame.can_dlc;
    
    // Process frame with ID 0x123 and at least 6 bytes of data
    if (frame.can_id == 0x123 && frame.can_dlc >= 6) {
        // Extract speed (bytes 0-2)
        int speed_int = (frame.data[0] << 8) | frame.data[1];
        int speed_frac = frame.data[2];
        float newSpeed = speed_int + (speed_frac / 100.0f);

        // Extract RPM (bytes 3-5)
        int rpm_int = (frame.data[3] << 8) | frame.data[4];
        int rpm_frac = frame.data[5];
        float newRpm = rpm_int + (rpm_frac / 100.0f);

        qDebug() << "CAN Data - Speed:" << newSpeed << "cm/s, RPM:" << newRpm;

        // Update values and emit signals if changed
        bool speedHasChanged = (m_speed != newSpeed);
        bool rpmHasChanged = (m_rpm != newRpm);

        m_speed = newSpeed;
        m_rpm = newRpm;

        if (speedHasChanged) {
            emit speedChanged();
        }
        if (rpmHasChanged) {
            emit rpmChanged();
        }

        emit dataReceived(m_speed, m_rpm);
    }
}
