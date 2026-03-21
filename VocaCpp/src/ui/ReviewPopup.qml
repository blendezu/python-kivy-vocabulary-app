import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: reviewPopup
    width: window.width * 0.95
    height: window.height * 0.95
    modal: true
    focus: true
    anchors.centerIn: parent
    closePolicy: Popup.NoAutoClose // user must click Close to prevent accidental exits

    background: Rectangle {
        color: "#1e232e" 
        radius: 8
        border.color: "#3385e6" 
        border.width: 1
    }
    
    property bool showingMeaning: false

    function updateMatchCount() {
        if (!app) return;
        let count = app.getReviewMatchingCount(startDateInput.text, endDateInput.text, twisterCheck.checked);
        matchingCountText.text = "Matching words: " + count;
    }


    StackLayout {
        id: stackLayout
        anchors.fill: parent
        anchors.margins: 16
        currentIndex: 0 // 0 = Setup, 1 = Review

        // --- View 0: Setup ---
        ColumnLayout {
            spacing: 12

            Text {
                text: "Review Setup"
                color: "#f2faff"
                font.pixelSize: 28
                font.bold: true
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                height: 2
                color: "#3385e6"
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text { text: "Start:"; color: "#c7d1e0"; font.pixelSize: 18; Layout.preferredWidth: 60 }
                TextField {
                    id: startDateInput
                    Layout.fillWidth: true
                    font.pixelSize: 18
                    placeholderText: "DD/MM or YYYY-MM-DD"
                    onTextChanged: reviewPopup.updateMatchCount()
                }

                Text { text: "End:"; color: "#c7d1e0"; font.pixelSize: 18; Layout.preferredWidth: 40 }
                TextField {
                    id: endDateInput
                    Layout.fillWidth: true
                    font.pixelSize: 18
                    placeholderText: "DD/MM or YYYY-MM-DD"
                    onTextChanged: reviewPopup.updateMatchCount()
                }
            }

            // Quick dates row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Repeater {
                    model: ["Today", "-1", "-2", "-3", "-4", "-5", "-6", "-7", "-8"]
                    Button {
                        text: modelData
                        font.pixelSize: 16
                        Layout.fillWidth: true
                        palette.button: "#468c99"
                        palette.buttonText: "#f2faff"
                        onClicked: {
                            startDateInput.text = modelData
                            endDateInput.text = modelData
                        }
                    }
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                Button {
                    id: twisterCheck
                    text: "Tongue-twister exclusively"
                    font.pixelSize: 18
                    checkable: true
                    Layout.preferredWidth: 250
                    onCheckedChanged: reviewPopup.updateMatchCount()
                }

            }

            Text {
                id: matchingCountText
                text: "Matching words: -"
                color: "#8c8ce6"
                font.pixelSize: 20
                Layout.fillWidth: true
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                spacing: 12

                Button {
                    text: "Close"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    font.pixelSize: 24
                    palette.buttonText: "#f2faff"
                    palette.button: "#808080"
                    onClicked: reviewPopup.close()
                }
                Button {
                    text: "Start Review"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    font.pixelSize: 24
                    palette.buttonText: "#f2faff"
                    palette.button: "#3385e6"
                    onClicked: {
                        app.startReview(startDateInput.text, endDateInput.text, twisterCheck.checked)
                        showingMeaning = false
                        stackLayout.currentIndex = 1
                    }
                }
            }
        }

        // --- View 1: Active Review ---
        ColumnLayout {
            spacing: 12

            Text {
                text: "Reviewing... " + app.state.reviewRemainingCount + " remaining"
                color: "#f2faff"
                font.pixelSize: 20
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                height: 2
                color: "#3385e6"
            }

            Item { Layout.fillHeight: true }

            Text {
                text: app.state.reviewCurrentWord ? app.state.reviewCurrentWord : "Finished!"
                color: "#f2faff"
                font.pixelSize: 64
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
            
            Text {
                text: app.state.reviewCurrentWord && app.state.vocabulary[app.state.reviewCurrentWord] ? 
                      "[" + app.state.vocabulary[app.state.reviewCurrentWord]["ipa"] + "]" : ""
                color: "#c7d1e0"
                font.pixelSize: 24
                Layout.alignment: Qt.AlignHCenter
            }


            Item { Layout.fillHeight: true }
            
            // Revealed meaning area
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 150
                color: showingMeaning ? "#2a2a2a" : "transparent"
                border.color: showingMeaning ? "#444444" : "transparent"
                radius: 8
                
                Text {
                    id: meaningText
                    anchors.fill: parent
                    anchors.margins: 10
                    color: "#f2faff"
                    font.pixelSize: 18
                    wrapMode: Text.WordWrap
                    
                    function getMeaningText() {
                        if (!showingMeaning || !app.state.reviewCurrentWord) return "";
                        let wordData = app.state.vocabulary[app.state.reviewCurrentWord];
                        if (!wordData || !wordData.meanings) return "";
                        let result = "";
                        for (let i = 0; i < wordData.meanings.length; i++) {
                            let m = wordData.meanings[i];
                            result += (i+1) + ". " + m.pos + " " + m.expl + "\n";
                        }
                        return result;
                    }
                    
                    text: getMeaningText()
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                spacing: 12
                
                Button {
                    text: "Speak"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    font.pixelSize: 24
                    palette.buttonText: "#f2faff"
                    palette.button: "#3385e6"
                    onClicked: app.tts.speak(app.state.reviewCurrentWord)
                    enabled: app.state.reviewCurrentWord !== ""
                }
                
                Button {
                    text: showingMeaning ? "Correct" : "Show"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    font.pixelSize: 24
                    palette.buttonText: "#f2faff"
                    palette.button: showingMeaning ? "#40a661" : "#8c8ce6"
                    enabled: app.state.reviewCurrentWord !== ""
                    onClicked: {
                        if (showingMeaning) {
                            app.markReviewWordKnown()
                            showingMeaning = false
                        } else {
                            showingMeaning = true
                        }
                    }
                }
            }


            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                spacing: 12
                
                Button {
                    text: "Stop Review"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    font.pixelSize: 24
                    palette.buttonText: "#f2faff"
                    palette.button: "#808080"
                    onClicked: {
                        stackLayout.currentIndex = 0
                    }
                }
                
                Button {
                    text: "Next"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    font.pixelSize: 24
                    palette.buttonText: "#f2faff"
                    palette.button: "#5cc27d"
                    onClicked: {
                        app.nextReviewWord()
                        showingMeaning = false
                    }
                    enabled: app.state.reviewCurrentWord !== ""
                }
                
                Button {
                    text: "Edit"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    font.pixelSize: 24
                    palette.buttonText: "#f2faff"
                    palette.button: "#468c99"
                    onClicked: {
                        editPopup.wordToEdit = app.state.reviewCurrentWord
                        editPopup.open()
                    }
                    enabled: app.state.reviewCurrentWord !== ""
                }

            }
        }
    }
}
