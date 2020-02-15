import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Controls.Universal 2.12
import Qt.labs.settings 1.0
import QtQuick.Dialogs 1.1

ApplicationWindow {
    id: window
    width: 360
    height: 520
    visible: true
    objectName: "window"

    property var mSearching: true

    Connections {
        target: controller

        onDeviceFound: {
            mSearching = false;
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
        visible: !mSearching

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
}
