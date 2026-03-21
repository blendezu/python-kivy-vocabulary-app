import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    width: window.width * 0.95
    height: window.height * 0.95
    modal: true
    focus: true
    anchors.centerIn: parent
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property var stats: ({})
    property var last7Dates: []
    property var last7Counts: []

    background: Rectangle {
        color: "#1e232e" // Main dark background
        border.color: "#3385e6" // Accent border
        border.width: 1
        radius: 8
    }
    
    onOpened: {
        stats = app.getDashboardStats()
        if (stats["last7Dates"]) {
            last7Dates = stats["last7Dates"]
            last7Counts = stats["last7Counts"]
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Top Header
        RowLayout {
            Layout.fillWidth: true
            Button {
                text: "<"
                font.pixelSize: 24
                palette.buttonText: "#f2faff"
                palette.button: "transparent"
                onClicked: root.close()
                flat: true
            }
            Text {
                text: "Dashboard"
                color: "#f2faff"
                font.pixelSize: 24
                font.bold: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
            }
            Item { Layout.preferredWidth: 40 } // Spacer for centering
        }

        // TabBar
        TabBar {
            id: tabBar
            Layout.fillWidth: true
            background: Rectangle { color: "transparent" }
            
            TabButton {
                text: "Daily Check"
                width: implicitWidth + 20
                contentItem: Text {
                    text: parent.text
                    color: parent.checked ? "#3385e6" : "#c7d1e0"
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: "transparent"
                    Rectangle {
                        width: parent.width
                        height: 2
                        anchors.bottom: parent.bottom
                        color: parent.parent.checked ? "#3385e6" : "transparent"
                    }
                }
            }
            TabButton { text: "New vs Old"; font.pixelSize: 16 }
            TabButton { text: "Retention"; font.pixelSize: 16 }
            TabButton { text: "Difficulty"; font.pixelSize: 16 }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            // View 0: Daily Check
            Item {
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    Text {
                        text: "Words Completed: " + (stats["today"] || 0) + " today"
                        color: "#f2faff"
                        font.pixelSize: 18
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 20
                    }

                    // Bar Chart Area
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: 20

                        // Y-axis
                        Column {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: bottomAxis.top
                            width: 30
                            spacing: 0
                            
                            function getMaxCount() {
                                let m = 5;
                                for (let i = 0; i < last7Counts.length; i++) {
                                    if (last7Counts[i] > m) m = last7Counts[i];
                                }
                                return m;
                            }
                            
                            Repeater {
                                model: 5
                                Item {
                                    width: 30
                                    height: parent.height / 4
                                    Text {
                                        anchors.verticalCenter: parent.top
                                        anchors.right: parent.right
                                        anchors.rightMargin: 5
                                        color: "#8c8ce6"
                                        font.pixelSize: 12
                                        text: {
                                            let max = parent.parent.getMaxCount()
                                            let val = max - (index * max / 4);
                                            return Math.round(val);
                                        }
                                    }
                                }
                            }
                        }

                        // Bars
                        Row {
                            id: chartArea
                            anchors.left: parent.left
                            anchors.leftMargin: 30
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: bottomAxis.top
                            spacing: (width - (last7Counts.length * 30)) / (last7Counts.length + 1)
                            
                            Repeater {
                                model: last7Counts
                                Item {
                                    width: 30
                                    height: chartArea.height
                                    
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        color: "#d97d7d" // chart color from screenshot
                                        radius: 4
                                        
                                        function getMax() {
                                            let m = 5;
                                            for (let i = 0; i < last7Counts.length; i++) {
                                                if (last7Counts[i] > m) m = last7Counts[i];
                                            }
                                            return m;
                                        }
                                        
                                        height: {
                                            let max = getMax();
                                            if (max === 0) return 0;
                                            return (modelData / max) * chartArea.height;
                                        }
                                    }
                                }
                            }
                        }

                        // X-axis (Dates)
                        Row {
                            id: bottomAxis
                            anchors.left: chartArea.left
                            anchors.right: chartArea.right
                            anchors.bottom: parent.bottom
                            height: 30
                            spacing: chartArea.spacing
                            
                            Repeater {
                                model: last7Dates
                                Item {
                                    width: 30
                                    height: 30
                                    Text {
                                        anchors.centerIn: parent
                                        color: "#8c8ce6"
                                        font.pixelSize: 12
                                        text: modelData
                                        rotation: -45
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // View 1: New vs Old
            Item {
                Text { anchors.centerIn: parent; text: "New vs Old - Coming Soon"; color: "#f2faff" }
            }
            // View 2: Retention
            Item {
                Text { anchors.centerIn: parent; text: "Retention - Coming Soon"; color: "#f2faff" }
            }
            // View 3: Difficulty
            Item {
                Text { anchors.centerIn: parent; text: "Difficulty - Coming Soon"; color: "#f2faff" }
            }
        }
    }
}
