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
    color: "#121419"

    // Shared theme colors (purple accent)
    property color accentColor: '#6f5da5'
    property color accentStrong: "#6f5da5"
    property color accentSoft: "#6f5da5"
    property color surfaceColor: "#1d1f26"
    property color surfaceAltColor: "#2a2d36"
    property color borderColor: "#6f5da5"
    property color textPrimary: "#edf0f7"
    property color textSecondary: "#c7ccda"
    property color textMuted: "#6f5da5"
    property color dangerColor: '#c87286'
    property string themeMode: "lila"

    function applyTheme(mode) {
        themeMode = mode
        if (mode === "turquesa") {
            accentColor = "#2f8f9d"
            accentStrong = "#2b7f8b"
            accentSoft = "#78aeb6"
            surfaceColor = "#1b2124"
            surfaceAltColor = "#263237"
            borderColor = "#2f8f9d"
            textPrimary = "#eaf2f3"
            textSecondary = "#c3d5d8"
            textMuted = "#7da1a6"
            dangerColor = "#b16c77"
        } else {
            accentColor = "#6f5da5"
            accentStrong = "#6f5da5"
            accentSoft = "#6f5da5"
            surfaceColor = "#1d1f26"
            surfaceAltColor = "#2a2d36"
            borderColor = "#6f5da5"
            textPrimary = "#edf0f7"
            textSecondary = "#c7ccda"
            textMuted = "#6f5da5"
            dangerColor = "#c87286"
        }
    }

    Component.onCompleted: applyTheme(themeMode)

    menuBar: MenuBar {
        Menu {
            title: "Theme"

            MenuItem {
                text: "Lila"
                checkable: true
                checked: window.themeMode === "lila"
                onTriggered: window.applyTheme("lila")
            }

            MenuItem {
                text: "Turquesa"
                checkable: true
                checked: window.themeMode === "turquesa"
                onTriggered: window.applyTheme("turquesa")
            }
        }
    }

    property var appState: app.state
    
    property string selectedWord: ""
    property string selectedOrigin: ""

    component ColorButton : Button {
        id: control
        property color bgColor: window.accentColor
        property color textColor: window.textPrimary
        
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
                bgColor: window.surfaceAltColor
                onClicked: addNewWordsPopup.open()
            }
            ColorButton {
                text: "Check for new\nwords from text"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                font.pixelSize: 18
                bgColor: window.accentColor
                onClicked: newTextPopup.open()
            }
            ColorButton {
                text: "Expressions"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                font.pixelSize: 18
                bgColor: window.accentStrong
                onClicked: expressionsPopup.open()
            }
            ColorButton {
                text: "Learn"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                font.pixelSize: 18
                bgColor: window.accentStrong
                onClicked: learnPopup.open()
            }
            ColorButton {
                text: "Learned words"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                font.pixelSize: 18
                bgColor: window.accentStrong
                onClicked: learnedWordsPopup.open()
            }
            ColorButton {
                text: "Review"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                font.pixelSize: 18
                bgColor: window.dangerColor
                onClicked: reviewPopup.open()
            }
            ColorButton {
                text: "Dashboard"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                font.pixelSize: 18
                bgColor: window.surfaceAltColor
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
                color: window.textPrimary
                font.pixelSize: 64
                font.bold: false
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                text: appState.remainingCount + " Words left"
                color: window.textSecondary
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
                    color: window.textMuted
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
                color: window.textSecondary
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
                bgColor: window.dangerColor
                onClicked: app.removeCurrentWord()
            }
            ColorButton {
                text: "Next word"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                font.pixelSize: 24
                bgColor: window.accentStrong
                onClicked: app.requestNextWord()
            }
            ColorButton {
                text: "Correct"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                font.pixelSize: 24
                bgColor: window.accentColor
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
                bgColor: window.accentColor
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
                    color: window.accentStrong
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
                    border.color: window.borderColor
                    clip: true
                    ListView {
                        anchors.fill: parent
                        model: appState.knownSequenceDisplay
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 35
                            property bool isSelected: window.selectedWord === modelData && window.selectedOrigin === "known"
                            color: isSelected ? window.accentStrong : (index % 2 === 0 ? window.surfaceColor : window.surfaceAltColor)
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: window.textPrimary
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
                    bgColor: window.selectedWord !== "" && window.selectedOrigin === "known" ? window.surfaceAltColor : window.surfaceColor
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
                    bgColor: window.selectedWord !== "" && window.selectedOrigin === "new" ? window.surfaceAltColor : window.surfaceColor
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
                    bgColor: window.selectedWord !== "" && (window.selectedOrigin === "known" || window.selectedOrigin === "new") ? window.dangerColor : "#3e3035"
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
                    color: window.accentColor
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
                    border.color: window.borderColor
                    clip: true
                    ListView {
                        anchors.fill: parent
                        model: appState.newSequenceDisplay
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 35
                            property bool isSelected: window.selectedWord === modelData && window.selectedOrigin === "new"
                            color: isSelected ? window.accentStrong : (index % 2 === 0 ? window.surfaceColor : window.surfaceAltColor)
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: window.textPrimary
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
                    color: window.dangerColor
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
                    border.color: window.borderColor
                    clip: true
                    ListView {
                        anchors.fill: parent
                        model: appState.removedSequence
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 35
                            property bool isSelected: window.selectedWord === modelData && window.selectedOrigin === "removed"
                            color: isSelected ? window.accentStrong : (index % 2 === 0 ? window.surfaceColor : window.surfaceAltColor)
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: window.textPrimary
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
