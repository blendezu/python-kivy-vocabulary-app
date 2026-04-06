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

    property var summary: ({})
    property var dailyData: ({ "labels": [], "values": [], "isGood": [], "maxValue": 1 })
    property var monthlyData: ({ "labels": [], "values": [], "isGood": [], "maxValue": 1 })
    
    // State
    property int dayOffset: 0
    property int currentYear: new Date().getFullYear()
    property int maxYear: new Date().getFullYear()

    background: Rectangle {
        color: window.surfaceColor
        border.color: window.accentColor
        border.width: 1
        radius: 8
    }
    
    onOpened: {
        summary = app.getDashboardSummary()
        refreshDaily()
        refreshMonthly()
    }
    
    function refreshDaily() {
        dailyData = app.getDailyStats(dayOffset)
    }
    
    function refreshMonthly() {
        monthlyData = app.getMonthlyStats(currentYear)
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
                palette.buttonText: window.textPrimary
                palette.button: "transparent"
                onClicked: root.close()
                flat: true
            }
            Text {
                text: "Dashboard"
                color: window.textPrimary
                font.pixelSize: 24
                font.bold: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
            }
            Item { Layout.preferredWidth: 40 }
        }

        // Summary Stats Grid
        GridLayout {
            columns: 2
            Layout.fillWidth: true
            Layout.leftMargin: 40
            Layout.rightMargin: 40
            rowSpacing: 5
            columnSpacing: 20
            
            Text { text: "Today:"; color: window.textPrimary; font.pixelSize: 18 }
            Text { text: (summary.today || 0) + " words"; color: window.textPrimary; font.pixelSize: 18; font.bold: true }

            Text { text: "This week:"; color: window.textPrimary; font.pixelSize: 18 }
            Text { text: (summary.week || 0) + " words"; color: window.textPrimary; font.pixelSize: 18; font.bold: true }

            Text { text: "This month:"; color: window.textPrimary; font.pixelSize: 18 }
            Text { text: (summary.month || 0) + " words"; color: window.textPrimary; font.pixelSize: 18; font.bold: true }

            Text { text: "This year:"; color: window.textPrimary; font.pixelSize: 18 }
            Text { text: (summary.year || 0) + " words"; color: window.textPrimary; font.pixelSize: 18; font.bold: true }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: window.borderColor
            Layout.topMargin: 10
            Layout.bottomMargin: 10
        }

        // Charts Scroll Area
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: -1 

            ColumnLayout {
                width: parent.width
                spacing: 30
                
                // Chart 1: Last 10 Days
                ChartComponent {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 320
                    title: "Last 10 Days"
                    labels: dailyData.labels
                    values: dailyData.values
                    isGood: dailyData.isGood
                    maxValue: dailyData.maxValue
                    
                    canGoBack: true
                    canGoForward: dayOffset >= 10
                    
                    onBackClicked: {
                        dayOffset += 10;
                        refreshDaily();
                    }
                    onForwardClicked: {
                        dayOffset -= 10;
                        if(dayOffset < 0) dayOffset = 0;
                        refreshDaily();
                    }
                }

                // Chart 2: Months [Year]
                ChartComponent {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 320
                    title: "Months " + currentYear
                    labels: monthlyData.labels
                    values: monthlyData.values
                    isGood: monthlyData.isGood
                    maxValue: monthlyData.maxValue
                    
                    canGoBack: true
                    canGoForward: currentYear < maxYear
                    
                    onBackClicked: {
                        currentYear--;
                        refreshMonthly();
                    }
                    onForwardClicked: {
                        currentYear++;
                        refreshMonthly();
                    }
                }
                
                // Legend
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 20
                    
                    Rectangle { width: 15; height: 15; color: window.accentStrong }
                    Text { text: "same/more learned"; color: window.textPrimary; font.pixelSize: 14 }
                    
                    Rectangle { width: 15; height: 15; color: window.dangerColor }
                    Text { text: "less learned"; color: window.textPrimary; font.pixelSize: 14 }
                }
                
                Item { height: 20; Layout.fillWidth: true } // Bottom spacer
            }
        }
        
        Button {
            text: "Close"
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            palette.button: window.surfaceAltColor
            palette.buttonText: window.textPrimary
            onClicked: root.close()
        }
    }
    
    // Internal Chart Component
    component ChartComponent : Item {
        property string title
        property var labels: []
        property var values: []
        property var isGood: []
        property int maxValue: 1
        
        property bool canGoBack: true
        property bool canGoForward: false
        signal backClicked()
        signal forwardClicked()
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 5
            
            Text {
                text: title
                color: window.textPrimary
                font.pixelSize: 20
                Layout.alignment: Qt.AlignHCenter
            }
            
            // The Chart
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 10
                
                // Bars
                Row {
                    id: barsRow
                    anchors.fill: parent
                    anchors.bottomMargin: 30 // Space for labels
                    spacing: (width / Math.max(1, values.length)) * 0.2 // 20% spacing
                    
                    property real barWidth: (width - (spacing * (values.length - 1))) / Math.max(1, values.length)
                    
                    Repeater {
                        model: values.length
                        Item {
                            width: barsRow.barWidth
                            height: barsRow.height
                            
                            property int val: values[index] || 0
                            property bool good: isGood[index] !== undefined ? isGood[index] : true
                            property int max: maxValue > 0 ? maxValue : 1
                            
                            Rectangle {
                                width: parent.width
                                color: good ? window.accentStrong : window.dangerColor
                                radius: 2
                                anchors.bottom: parent.bottom
                                height: (parent.height * val) / max
                                
                                // Value Label above bar
                                Text {
                                    text: val > 0 ? val : ""
                                    color: window.textPrimary
                                    font.pixelSize: 12
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.top
                                    anchors.bottomMargin: 2
                                    visible: val > 0
                                }
                            }
                            
                            // X-Axis Label below bar
                            Text {
                                text: labels[index] || ""
                                color: window.textMuted
                                font.pixelSize: 11
                                anchors.top: parent.bottom
                                anchors.topMargin: 5
                                anchors.horizontalCenter: parent.horizontalCenter
                                // Rotate slightly if needed, but 10 days usually fit
                            }
                        }
                    }
                }
            }
            
            // Navigation
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20
                
                Button {
                    text: "<"
                    enabled: canGoBack
                    palette.button: window.surfaceAltColor
                    palette.buttonText: window.textPrimary
                    onClicked: backClicked()
                    Layout.preferredWidth: 60
                }
                
                Button {
                    text: ">"
                    enabled: canGoForward
                    palette.button: window.surfaceAltColor
                    palette.buttonText: window.textPrimary
                    onClicked: forwardClicked()
                    Layout.preferredWidth: 60
                }
            }
        }
    }
}
