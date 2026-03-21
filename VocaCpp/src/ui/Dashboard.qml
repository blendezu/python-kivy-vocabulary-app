import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    width: 600
    height: 500
    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property var stats: ({})

    background: Rectangle {
        color: "#1e1e1e"
        border.color: "#333333"
        border.width: 1
        radius: 10
    }
    
    onOpened: {
        stats = app.getDashboardStats()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        Text {
            text: "Dashboard"
            color: "white"
            font.pixelSize: 32
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }
        
        GridLayout {
            columns: 2
            rowSpacing: 15
            columnSpacing: 30
            Layout.alignment: Qt.AlignHCenter

            Text { text: "Today:"; color: "#dddddd"; font.pixelSize: 24 }
            Text { text: stats["today"] + " words"; color: "#44cc88"; font.pixelSize: 24; font.bold: true }

            Text { text: "This Week:"; color: "#dddddd"; font.pixelSize: 24 }
            Text { text: stats["week"] + " words"; color: "#44cc88"; font.pixelSize: 24; font.bold: true }

            Text { text: "This Month:"; color: "#dddddd"; font.pixelSize: 24 }
            Text { text: stats["month"] + " words"; color: "#44cc88"; font.pixelSize: 24; font.bold: true }

            Text { text: "This Year:"; color: "#dddddd"; font.pixelSize: 24 }
            Text { text: stats["year"] + " words"; color: "#44cc88"; font.pixelSize: 24; font.bold: true }
        }

        Item { Layout.fillHeight: true } // Spacer

        Button {
            text: "Close"
            Layout.alignment: Qt.AlignHCenter
            onClicked: root.close()
            palette.button: "#555555"
            palette.buttonText: "white"
        }
    }
}
