#include "rcontroller.h"

#include <QDataStream>
#include <QNetworkDatagram>
#include <QTimer>

RController::RController(QObject *parent) :
    QObject(parent)
  , mBroadcastListener(nullptr)
  , mServerConfReceived(false)
  , mSocket(nullptr)
{

}

void RController::init()
{
    mDeviceInAPMode = false;

    if(mBroadcastListener != nullptr)
    {
        mBroadcastListener->close();

        disconnect(mBroadcastListener, nullptr, nullptr, nullptr);

        mBroadcastListener->deleteLater();
        mBroadcastListener = nullptr;
    }

    mServerConfReceived = false;
    mBroadcastData.clear();

    mBroadcastListener = new QUdpSocket();
    connect(mBroadcastListener, &QUdpSocket::readyRead, this, &RController::onBroadcastDataReceived);

    mBroadcastListener->bind(QHostAddress::Any, 1453);

}

void RController::onBroadcastDataReceived()
{
    while (mBroadcastListener->hasPendingDatagrams())
    {
        QNetworkDatagram tDatagram = mBroadcastListener->receiveDatagram();

        mServerAddr = tDatagram.senderAddress();

        mBroadcastData.append(tDatagram.data());
    }

    if(mBroadcastData.length() >= 5)
    {
        if(mServerConfReceived)
        {
            mBroadcastData.clear();
            return;
        }

        if(mBroadcastData.at(0) == 14 && mBroadcastData.at(4) == 53)
        {
            QDataStream tStream(&mBroadcastData, QIODevice::ReadOnly);

            unsigned char tBuff;

            tStream >> tBuff;
            tStream >> mServerPort;
            tStream >> tBuff;
            if(tBuff == 0)
                mDeviceInAPMode = false;
            else
                mDeviceInAPMode = true;
            tStream >> tBuff;

            mBroadcastData.clear();

            mServerConfReceived = true;

            qDebug() << "Server conf received:" << mServerAddr << mServerPort;

            onServerConfReceived();
        }
    }
}

void RController::onDataReady()
{
    qDebug() << "Data Received:" << mSocket->readAll();
}

void RController::onConnected()
{
    qDebug() << "the client connected to server";

    emit deviceFound(mDeviceInAPMode);
}

void RController::onDisconnected()
{
    qDebug() << "the client disconnected from server";
}

void RController::onError(QAbstractSocket::SocketError pError)
{
    qDebug() << "tcp socket error:" << pError;
}

void RController::onServerConfReceived()
{
    mSocket = new QTcpSocket();

    connect(mSocket, &QTcpSocket::readyRead, this, &RController::onDataReady);
    connect(mSocket, &QTcpSocket::connected, this, &RController::onConnected);
    connect(mSocket, &QTcpSocket::disconnected, this, &RController::onDisconnected);
    connect(mSocket, QOverload<QAbstractSocket::SocketError>::of(&QAbstractSocket::error), this, &RController::onError);

    qDebug() << "Connecting to:" << mServerAddr << mServerPort;

    mSocket->connectToHost(mServerAddr, mServerPort);
}

void RController::setOn()
{
    if(mSocket)
        mSocket->write("1");
}

void RController::setOff()
{
    if(mSocket)
        mSocket->write("0");
}

void RController::sendConfig(QString pSSID, QString pPass)
{
    if(mSocket)
    {
        QString tMsg = "2#" + pSSID + "#" + pPass;
        mSocket->write(tMsg.toUtf8());

        QTimer::singleShot(3000, [=]{
            emit restartApp();
        });
    }
}
