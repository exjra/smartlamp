#ifndef RCONTROLLER_H
#define RCONTROLLER_H

#include <QObject>
#include <QTcpSocket>
#include <QUdpSocket>
#include <QAbstractSocket>

class RController : public QObject
{
    Q_OBJECT
public:
    explicit RController(QObject *parent = nullptr);

    void init();

private slots:
    void onBroadcastDataReceived();

    void onDataReady();
    void onConnected();
    void onDisconnected();
    void onError(QAbstractSocket::SocketError pError);

private:
    QUdpSocket* mBroadcastListener;

    bool mServerConfReceived;
    QByteArray mBroadcastData;

    QHostAddress mServerAddr;
    quint16 mServerPort;
    bool mDeviceInAPMode;

    void onServerConfReceived();

    QTcpSocket* mSocket;

public slots:
    void setOn();
    void setOff();
    void sendConfig(QString pSSID, QString pPass);

signals:
    void deviceFound(bool pAPMode);
    void restartApp();
};

#endif // RCONTROLLER_H
