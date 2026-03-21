import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Voca

ApplicationWindow {
    id: window
    width: 1000
    height: 900
    visible: true
    title: qsTr("VocaApp C++")
    color: "#121419" // bg

    property var appState: app.state

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // --- Top Bar (7 Buttons) ---
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            spacing: 8

            Button {
                text: "Add new words"
                Layout.fillWidth: true
                Layout.fillHeight: true
                font.pixelSize: 18
                palette.buttonText: "#f2faff"
                palette.button: "#1e232e" // surface
                onClicked: {} // TODO: Add words popup
            }
            Button {
                text: "Check for new\nwords from text"
                Layout.fillWidth: true
                Layout.fillHeight: true
                font.pixelSize: 18
                palette.buttonText: "#f2faff"
                palette.button: "#3385e6" // primary
                onClicked: {} // TODO
            }
            Button {
                text: "Expressions"
                Layout.fillWidth: true
                Layout.fillHeight: true
                font.pixelSize: 18
                palette.buttonText: "#f2faff"
                palette.button: "#8c52bf" // accent
                onClicked: {} // TODO
            }
            Button {
                text: "Learn"
                Layout.fillWidth: true
                Layout.fillHeight: true
                font.pixelSize: 18
                palette.buttonText: "#f2faff"
                palette.button: "#eda640" // warning (yellow/orange)
                onClicked: learnPopup.open()
            }
            Button {
                text: "Learned words"
                Layout.fillWidth: true
                Layout.fillHeight: true
                font.pixelSize: 18
                palette.buttonText: "#f2faff"
                palette.button: "#1a5900" // darkGreen
                onClicked: {} // TODO
            }
            Button {
                text: "Review"
                Layout.fillWidth: true
                Layout.fillHeight: true
                font.pixelSize: 18
                palette.buttonText: "#f2faff"
                palette.button: "#cc4c4c" // red
                onClicked: reviewPopup.open()
            }
            Button {
                text: "Dashboard"
                Layout.fillWidth: true
                Layout.fillHeight: true
                font.pixelSize: 18
                palette.buttonText: "#f2faff"
                palette.button: "#40a661" // success (green)
                onClicked: dashboardPopup.open()
            }
        }

        // --- Central Word Display ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            Item { Layout.fillHeight: true }

            Text {
                text: appState.currentWord ? appState.currentWord : "Done!"
                color: "#f2faff"
                font.pixelSize: 64
                font.bold: false
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: appState.remainingCount + " Words left"
                color: "#c7d1e0"
                font.pixelSize: 24
                visible: true
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 20
            }

            Text {
                text: "Note: The current word is automatically marked as 'Known' when you click 'Next word'. Tap 'New word' to move it to 'New words'. Double-tap a removed word to restore it."
                color: "#c7d1e0"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 800
                Layout.topMargin: 20
            }

            Item { Layout.fillHeight: true }
        }

        // --- Middle 2x2 Buttons ---
        GridLayout {
            columns: 2
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            rowSpacing: 12
            columnSpacing: 12

            Button {
                text: "Remove this word"
                Layout.fillWidth: true
                Layout.fillHeight: true
                font.pixelSize: 24
                palette.buttonText: "#f2faff"
                palette.button: "#cc4c4c"
                onClicked: app.removeCurrentWord()
            }
            Button {
                text: "Next word"
                Layout.fillWidth: true
                Layout.fillHeight: true
                font.pixelSize: 24
                palette.buttonText: "#f2faff"
                palette.button: "#40a661"
                onClicked: app.requestNextWord()
            }
            Button {
                text: "Correct"
                Layout.fillWidth: true
                Layout.fillHeight: true
                font.pixelSize: 24
                palette.buttonText: "#f2faff"
                palette.button: "#3385e6"
                onClicked: {
                    // Logic for Correct
                }
            }
            Button {
                text: "New word"
                Layout.fillWidth: true
                Layout.fillHeight: true
                font.pixelSize: 24
                palette.buttonText: "#f2faff"
                palette.button: "#eda640"
                onClicked: {
                    if (appState.currentWord) app.markWordNew(appState.currentWord)
                }
            }
        }

        // --- Bottom 3 list columns ---
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 300
            spacing: 12

            // Known Words
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: "#005900" // darker green
                    Text {
                        anchors.centerIn: parent
                        text: "Known words (" + appState.knownSequence.length + ")"
                        color: "white"
                        font.pixelSize: 16
                    }
                }
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ListView {
                        model: appState.knownSequence
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 40
                            color: "#2e2e2e"
                            border.color: "#1e1e1e"
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: "#f2faff"
                                font.pixelSize: 16
                            }
                        }
                    }
                }
            }

            // Transfer Buttons Middle Column
            ColumnLayout {
                Layout.preferredWidth: 40
                spacing: 8
                Item { Layout.fillHeight: true }
                Button {
                    text: ">>"
                    Layout.fillWidth: true
                    height: 40
                    palette.button: "#2e2e2e"
                }
                Button {
                    text: "<<"
                    Layout.fillWidth: true
                    height: 40
                    palette.button: "#2e2e2e"
                }
                Button {
                    text: "X"
                    Layout.fillWidth: true
                    height: 40
                    palette.buttonText: "white"
                    palette.button: "#cc4c4c"
                }
                Item { Layout.fillHeight: true }
            }

            // New Words
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: "#734700" // dark orange
                    Text {
                        anchors.centerIn: parent
                        text: "New words (" + appState.newSequence.length + ")"
                        color: "white"
                        font.pixelSize: 16
                    }
                }
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ListView {
                        model: appState.newSequence
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 40
                            color: "#332e1f"
                            border.color: "#1e1e1e"
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: "#f2faff"
                                font.pixelSize: 16
                            }
                        }
                    }
                }
            }

            // Removed Words
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: "#400000" // very dark red
                    Text {
                        anchors.centerIn: parent
                        text: "Removed words (" + appState.removedSequence.length + ")"
                        color: "white"
                        font.pixelSize: 16
                    }
                }
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ListView {
                        model: appState.removedSequence
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 40
                            color: "#290d12"
                            border.color: "#1e1e1e"
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: "#f2faff"
                                font.pixelSize: 16
                            }
                        }
                    }
                }
            }
        }
    }

    // --- Popups ---
    Dashboard {
        id: dashboardPopup
    }
    
    LearnPopup { id: learnPopup }
    ReviewPopup { id: reviewPopup }
    WordEditPopup { id: editPopup }
}
