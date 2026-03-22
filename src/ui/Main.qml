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
    
    property string selectedWord: ""
    property string selectedOrigin: ""

    component ColorButton : Button {
        id: control
        property color bgColor: "#3385e6"
        property color textColor: "#f2faff"
        
        contentItem: Text {
            text: control.text
            font: control.font
            color: control.textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            fontSizeMode: Text.Fit
            minimumPixelSize: 10
            rightPadding: 4
            leftPadding: 4
        }
        background: Rectangle {
            color: control.down ? Qt.darker(control.bgColor, 1.2) : (control.hovered ? Qt.lighter(control.bgColor, 1.1) : control.bgColor)
            radius: 8
            border.color: Qt.lighter(control.bgColor, 1.2)
            border.width: control.hovered ? 1 : 0
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // --- Top Bar (7 Buttons) ---
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            spacing: 8

            ColorButton {
                text: "Add new words"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                font.pixelSize: 18
                bgColor: "#242a36" 
                onClicked: addNewWordsPopup.open()
            }
            ColorButton {
                text: "Check for new\nwords from text"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                font.pixelSize: 18
                bgColor: "#3385e6" 
                onClicked: newTextPopup.open()
            }
            ColorButton {
                text: "Expressions"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                font.pixelSize: 18
                bgColor: "#8c52bf" 
                onClicked: expressionsPopup.open()
            }
            ColorButton {
                text: "Learn"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                font.pixelSize: 18
                bgColor: "#e6ad3e" 
                onClicked: learnPopup.open()
            }
            ColorButton {
                text: "Learned words"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                font.pixelSize: 18
                bgColor: "#1a5900" 
                onClicked: learnedWordsPopup.open()
            }
            ColorButton {
                text: "Review"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                font.pixelSize: 18
                bgColor: "#cc4c4c" 
                onClicked: reviewPopup.open()
            }
            ColorButton {
                text: "Dashboard"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                font.pixelSize: 18
                bgColor: "#40a661" 
                onClicked: dashboardPopup.open()
            }
        }

        // --- Central Word Display ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            Item { Layout.fillHeight: true; Layout.minimumHeight: 20 }

            Text {
                text: appState.currentWord !== "" ? appState.currentWord : "Done!"
                color: "#f2faff"
                font.pixelSize: 64
                font.bold: false
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                text: appState.remainingCount + " Words left"
                color: "#c7d1e0"
                font.pixelSize: 24
                visible: true
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                Layout.topMargin: 20
            }

            // Hint toggle row
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 10
                Item { Layout.fillWidth: true }
                Text {
                    property bool hintVisible: true
                    id: hintToggle
                    text: hintVisible ? "▾ Note" : "▸ Note"
                    color: "#8899aa"
                    font.pixelSize: 13
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: hintToggle.hintVisible = !hintToggle.hintVisible
                    }
                }
                Item { Layout.fillWidth: true }
            }

            Text {
                text: "Note: The current word is automatically marked as 'Known' when you click 'Next word'. Tap 'New word' to move it to 'New words'. Double-tap a removed word to restore it."
                color: "#c7d1e0"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                leftPadding: width * 0.1
                rightPadding: width * 0.1
                visible: hintToggle.hintVisible
                opacity: hintToggle.hintVisible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            Item { Layout.fillHeight: true; Layout.minimumHeight: 20 }
        }

        // --- Middle 2x2 Buttons ---
        GridLayout {
            columns: 2
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            rowSpacing: 12
            columnSpacing: 12

            ColorButton {
                text: "Remove this word"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                font.pixelSize: 24
                bgColor: "#cc4c4c"
                onClicked: app.removeCurrentWord()
            }
            ColorButton {
                text: "Next word"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                font.pixelSize: 24
                bgColor: "#5cc27d"
                onClicked: app.requestNextWord()
            }
            ColorButton {
                text: "Correct"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                font.pixelSize: 24
                bgColor: "#3399e6"
                onClicked: {
                    if (appState.currentWord !== "") {
                        correctWordPopup.openForWord(appState.currentWord);
                    }
                }
            }
            ColorButton {
                text: "New word"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                font.pixelSize: 24
                bgColor: "#eda640"
                onClicked: {
                    if (appState.currentWord !== "") app.markWordNew(appState.currentWord)
                }
            }
        }

        // --- Bottom 3 list columns ---
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 250 // Give it explicit height so it doesn't squash to 0
            spacing: 12

            // Known Words
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 100
                spacing: 4
                Rectangle {
                    Layout.fillWidth: true
                    height: 35
                    color: "#006600" // darker green
                    radius: 4
                    Text {
                        anchors.fill: parent
                        anchors.margins: 4
                        text: "Known words (" + appState.knownSequence.length + "/" + appState.vocabularyCount + ")"
                        color: "white"
                        font.pixelSize: 16
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                        elide: Text.ElideRight
                        fontSizeMode: Text.Fit
                        minimumPixelSize: 10
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                    border.color: "#333333"
                    clip: true
                    ListView {
                        anchors.fill: parent
                        model: appState.knownSequenceDisplay
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 35
                            property bool isSelected: window.selectedWord === modelData && window.selectedOrigin === "known"
                            color: isSelected ? "#1966b3" : (index % 2 === 0 ? "#1a1a1a" : "#222222")
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: "#f2faff"
                                font.pixelSize: 14
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    window.selectedWord = modelData;
                                    window.selectedOrigin = "known";
                                }
                            }
                        }
                    }
                }
            }

            // Transfer Buttons Middle Column
            ColumnLayout {
                Layout.preferredWidth: 35
                Layout.maximumWidth: 35
                Layout.fillHeight: true
                spacing: 8
                Item { Layout.fillHeight: true }
                ColorButton {
                    text: ">>"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 35
                    bgColor: window.selectedWord !== "" && window.selectedOrigin === "known" ? "#333333" : "#1a1a1a"
                    enabled: window.selectedWord !== "" && window.selectedOrigin === "known"
                    onClicked: {
                        app.moveWordToNew(window.selectedWord);
                        window.selectedWord = "";
                        window.selectedOrigin = "";
                    }
                }
                ColorButton {
                    text: "<<"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 35
                    bgColor: window.selectedWord !== "" && window.selectedOrigin === "new" ? "#333333" : "#1a1a1a"
                    enabled: window.selectedWord !== "" && window.selectedOrigin === "new"
                    onClicked: {
                        app.moveWordToKnown(window.selectedWord);
                        window.selectedWord = "";
                        window.selectedOrigin = "";
                    }
                }
                ColorButton {
                    text: "X"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 35
                    bgColor: window.selectedWord !== "" && (window.selectedOrigin === "known" || window.selectedOrigin === "new") ? "#aa3333" : "#4a1919"
                    enabled: window.selectedWord !== "" && (window.selectedOrigin === "known" || window.selectedOrigin === "new")
                    onClicked: {
                        app.removeWord(window.selectedWord);
                        window.selectedWord = "";
                        window.selectedOrigin = "";
                    }
                }
                Item { Layout.fillHeight: true }
            }

            // New Words
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 100
                spacing: 4
                Rectangle {
                    Layout.fillWidth: true
                    height: 35
                    color: "#b37700" // dirty yellow/brown
                    radius: 4
                    Text {
                        anchors.fill: parent
                        anchors.margins: 4
                        text: "New words (" + appState.newSequence.length + "/" + appState.vocabularyCount + ")"
                        color: "white"
                        font.pixelSize: 16
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                        elide: Text.ElideRight
                        fontSizeMode: Text.Fit
                        minimumPixelSize: 10
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                    border.color: "#333333"
                    clip: true
                    ListView {
                        anchors.fill: parent
                        model: appState.newSequenceDisplay
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 35
                            property bool isSelected: window.selectedWord === modelData && window.selectedOrigin === "new"
                            color: isSelected ? "#1966b3" : (index % 2 === 0 ? "#26221a" : "#2e2a22")
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: "#f2faff"
                                font.pixelSize: 14
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    window.selectedWord = modelData;
                                    window.selectedOrigin = "new";
                                }
                            }
                        }
                    }
                }
            }

            // Removed Words
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 100
                spacing: 4
                Rectangle {
                    Layout.fillWidth: true
                    height: 35
                    color: "#660000" // dark red
                    radius: 4
                    Text {
                        anchors.fill: parent
                        anchors.margins: 4
                        text: "Removed words (" + appState.removedSequence.length + ")"
                        color: "white"
                        font.pixelSize: 16
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                        elide: Text.ElideRight
                        fontSizeMode: Text.Fit
                        minimumPixelSize: 10
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                    border.color: "#333333"
                    clip: true
                    ListView {
                        anchors.fill: parent
                        model: appState.removedSequence
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 35
                            property bool isSelected: window.selectedWord === modelData && window.selectedOrigin === "removed"
                            color: isSelected ? "#1966b3" : (index % 2 === 0 ? "#261a1a" : "#2e2222")
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: "#f2faff"
                                font.pixelSize: 14
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    window.selectedWord = modelData;
                                    window.selectedOrigin = "removed";
                                }
                                onDoubleClicked: {
                                    app.restoreRemovedWord(modelData);
                                    window.selectedWord = "";
                                    window.selectedOrigin = "";
                                }
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
    
    LearnPopup {
        id: learnPopup
        learnedWordsPopup: learnedWordsPopup
        reviewPopup: reviewPopup
        editPopup: editPopup
    }
    ReviewPopup { id: reviewPopup }
    WordEditPopup { id: editPopup }
    CorrectWordPopup { id: correctWordPopup }

    AddNewWordsPopup { id: addNewWordsPopup }
    NewWordsFromTextPopup { id: newTextPopup; wordListPopup: wordListPopup }
    ExpressionsPopup { id: expressionsPopup; editPopupRef: editPopup }
    LearnedWordsPopup { id: learnedWordsPopup; editPopupRef: editPopup }
    WordListPopup { id: wordListPopup }
}
