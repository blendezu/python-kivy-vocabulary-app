import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Voca

ApplicationWindow {
    id: window
    width: 800
    height: 1000
    visible: true
    title: qsTr("VocaApp C++")
    color: "#1e1e1e"

    property var appState: app.state

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // --- Header / Status ---
        RowLayout {
            Layout.fillWidth: true
            Label {
                text: "Remaining: " + appState.remainingCount
                color: "#cccccc"
                font.pixelSize: 16
            }
            Item { Layout.fillWidth: true }
            Label {
                text: "Mode: " + appState.learnOrderMode
                color: "#cccccc"
                font.pixelSize: 16
            }
        }

        Item { Layout.fillHeight: true }

        // --- Main Word Display ---
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            Text {
                text: appState.currentWord ? appState.currentWord : "Done!"
                color: "white"
                font.pixelSize: 64
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: appState.currentWordIpa ? "/" + appState.currentWordIpa + "/" : ""
                color: "#aaaaaa"
                font.pixelSize: 24
                visible: text !== ""
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // --- Details Section (Meaning, Examples) ---
        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: 300
            visible: appState.currentWordDetails && appState.currentWordDetails.length > 0
            
            ColumnLayout {
                width: parent.width
                spacing: 15

                Repeater {
                    model: appState.currentWordDetails
                    delegate: ColumnLayout {
                        width: parent.width
                        spacing: 5
                        
                        RowLayout {
                            spacing: 10
                            Repeater {
                                model: modelData.pos
                                delegate: Rectangle {
                                    width: posLabel.width + 10; height: 24
                                    color: "#336699"
                                    radius: 4
                                    Text {
                                        id: posLabel
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: "white"
                                        font.bold: true
                                        font.pixelSize: 14
                                    }
                                }
                            }
                        }

                        Text {
                            text: modelData.meaning
                            color: "#dddddd"
                            font.pixelSize: 18
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Repeater {
                            model: modelData.examples
                            delegate: Text {
                                text: "• " + modelData
                                color: "#999999"
                                font.italic: true
                                font.pixelSize: 16
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                Layout.leftMargin: 20
                            }
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: "#333333"
                            visible: index < appState.currentWordDetails.length - 1
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // --- Transcription / Feedback ---
        Text {
            id: transcriptionLabel
            text: "..."
            color: "#888888"
            font.pixelSize: 14
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
        }

        // --- Controls ---
        RowLayout {
            // ... (Previous audio controls)
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            
            RoundButton {
                text: "🔊 Listen"
                onClicked: app.tts.speak(appState.currentWord)
                font.pixelSize: 16
                implicitWidth: 120
                implicitHeight: 50
            }
            
            RoundButton {
                text: "🎙️ Speak"
                onPressed: app.stt.startRecording()
                onReleased: app.stt.stopRecording()
                font.pixelSize: 16
                implicitWidth: 120
                implicitHeight: 50
                palette.button: "#cc4444"
            }
        }
        
        // ... (Transcription Connections)

         // --- Top Menu Buttons (Lists & Dashboard) ---
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10
            spacing: 10
            
            Button {
                text: "Dashboard"
                onClicked: dashboardPopup.open()
                palette.button: "#2d5e2e"
                palette.buttonText: "white"
            }
            
            Button {
                text: "Known (" + appState.knownSequence.length + ")"
                onClicked: knownPopup.open()
                palette.button: "#224422"
                palette.buttonText: "white"
            }
            
            Button {
                text: "New (" + appState.newSequence.length + ")"
                onClicked: newPopup.open()
                palette.button: "#664400"
                palette.buttonText: "white"
            }
        }

        // --- Bottom Controls ---
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 15
            Layout.topMargin: 20

            Button {
                text: "Remove"
                onClicked: app.removeCurrentWord()
                palette.button: "#552222"
                palette.buttonText: "white"
            }
            
            Item { width: 20 } // Spacer

            Button {
                text: "New Word"
                onClicked: {
                    if (appState.currentWord) app.markWordNew(appState.currentWord)
                }
                palette.button: "#cc8800"
                palette.buttonText: "black"
                font.bold: true
            }

            Button {
                text: "Next Word"
                onClicked: app.requestNextWord()
                palette.button: "#448844"
                palette.buttonText: "white"
                font.bold: true
                font.pixelSize: 18
                implicitWidth: 150
                implicitHeight: 50
            }
        }
    }
    
    // --- Popups ---
    Dashboard {
        id: dashboardPopup
    }
    
    WordListPopup {
        id: knownPopup
        title: "Known Words"
        wordList: appState.knownSequence
        onWordSelected: (w) => {
            appState.currentWord = w
            knownPopup.close()
        }
    }
    
    WordListPopup {
        id: newPopup
        title: "New Words"
        wordList: appState.newSequence
        onWordSelected: (w) => {
            appState.currentWord = w
            newPopup.close()
        }
    }
    
    WordEditPopup {
        id: editPopup
        onSaved: {
            // Force refresh of details if needed, though property binding should handle it
            appState.currentWordChanged() 
        }
    }
    
    // Initial Load
    Component.onCompleted: {
    }
}
