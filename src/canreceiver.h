#ifndef CANRECEIVER_H
#define CANRECEIVER_H

#include <QObject>
#include <QTimer>
#include <QThread>
#include <linux/can.h>
#include <linux/can/raw.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <unistd.h>

class CanReceiver : public QObject
{
    Q_OBJECT
    Q_PROPERTY(float speed READ speed NOTIFY speedChanged)
    Q_PROPERTY(float rpm READ rpm NOTIFY rpmChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)

public:
    explicit CanReceiver(QObject *parent = nullptr);
    ~CanReceiver();

    float speed() const { return m_speed; }
    float rpm() const { return m_rpm; }
    bool connected() const { return m_connected; }

public slots:
    void connectToCan(const QString &interface = "can10");
    void disconnectFromCan();
    void startListening();
    void stopListening();

signals:
    void speedChanged();
    void rpmChanged();
    void connectedChanged();
    void dataReceived(float speed, float rpm);
    void errorOccurred(const QString &error);

private slots:
    void readCanData();

private:
    void setupSocket(const QString &interface);
    void closeSocket();
    void processCanFrame(const struct can_frame &frame);

    int m_socket;
    float m_speed;
    float m_rpm;
    bool m_connected;
    QTimer *m_readTimer;
    QString m_interface;
};

#endif // CANRECEIVER_H
