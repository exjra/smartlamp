import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Controls.Universal 2.12
import Qt.labs.settings 1.0
import QtQuick.Dialogs 1.1
import Qt.labs.platform 1.1

ApplicationWindow {
    id: window
    width: 360
    height: 520
    visible: true
    objectName: "window"

//    property var mSearching: true
//    property var mInstallMode: false
    property var mSearching: false
    property var mInstallMode: true

    MessageDialog {
        id: dlgInputProblems
        title: "Giriş verisi hatası"
        text: "Lütfen tüm alanları doldurun."
        buttons: MessageDialog.Ok
        onAccepted: {
            close();
        }
    }

    MessageDialog {
        id: dlgRestartApp
        title: "İşlem Sonucu"
        text: "Cihaz ayarlandı. Uygulamayı yeniden başlatın."
        buttons: MessageDialog.Ok
        onAccepted: {
            Qt.quit();
        }
    }

    Connections {
        target: controller

        onDeviceFound: {
            mSearching = false;

            if(!pAPMode)
                mInstallMode = false;
            else
                mInstallMode = true;
        }

        onRestartApp: {
            dlgRestartApp.open();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        Layout.fillWidth: true
        visible: mSearching

        BusyIndicator {
            Layout.fillWidth: true
            running: true
            visible: true
        }

        Label {
            Layout.fillWidth: true
            text: "Cihazlar aranıyor.\nLütfen Bekleyiniz..."
            font.bold: true
            horizontalAlignment: Qt.AlignHCenter
        }
    }

    ColumnLayout {
        anchors.fill: parent
        Layout.fillWidth: true
        visible: !mSearching & !mInstallMode

        Button {
            Layout.fillWidth: true

            text: "Aç!"

            onClicked: {
                controller.setOn()
            }
        }

        Button {
            Layout.fillWidth: true

            text: "Kapat!"

            onClicked: {
                controller.setOff()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        Layout.fillWidth: true
        visible: !mSearching & mInstallMode

        BusyIndicator {
            id: mIndicator
            Layout.fillWidth: true
            running: true
            visible: false
        }

        Label {
            Layout.fillWidth: true
            text: "Cihaz ayarları güncelleniyor.\nLütfen bekleyin."
            visible: mIndicator.visible
        }

        TextField {
            id: txtSSID
            Layout.fillWidth: true
            placeholderText: "Ağ adı"
            horizontalAlignment: Qt.AlignHCenter
        }

        TextField {
            id: txtPass
            Layout.fillWidth: true
            placeholderText: "Ağ şifresi"
            horizontalAlignment: Qt.AlignHCenter
        }

        Button {
            Layout.fillWidth: true

            text: "Kaydet"

            onClicked: {
                if(txtPass.text === "" || txtSSID.text === "")
                    dlgInputProblems.open()
                else
                {
                    visible = false;
                    txtPass.visible = false;
                    txtSSID.visible = false;
                    mIndicator.visible = true
                    controller.sendConfig(txtSSID.text, txtPass.text)
                }
            }
        }
    }
}
