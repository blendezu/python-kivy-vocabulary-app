import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Voca

ApplicationWindow {
    id: window
    width: 1280
    height: 900
    visible: true
    title: qsTr("VocaApp")
    color: "#0b1220"

    // Modern clean dark theme
    property color accentColor: "#3b82f6"      // Electric blue
    property color accentStrong: "#2563eb"
    property color accentSoft: "#60a5fa"
    property color surfaceColor: "#1b263b"
    property color surfaceAltColor: "#172235"
    property color borderColor: "#2a3b5e"
    property color textPrimary: "#e5ecff"
    property color textSecondary: "#9fb2d7"
    property color textMuted: "#7b8db1"
    property color successColor: "#22c55e"
    property color dangerColor: "#ef4444"

    property var appState: app.state

    property string selectedWord: ""
    property string selectedOrigin: ""
    property bool hintVisible: true
    property int knownCount: appState.knownSequence.length
    property int totalCount: Math.max(1, appState.vocabularyCount)
    property real knownProgress: Math.min(1.0, knownCount / totalCount)

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

    RowLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 18

        Rectangle {
            Layout.preferredWidth: 238
            Layout.fillHeight: true
            radius: 20
            color: Qt.rgba(23 / 255, 34 / 255, 53 / 255, 0.94)
            border.color: window.borderColor
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Text {
                    text: "VocaApp"
                    color: window.textPrimary
                    font.family: "Inter"
                    font.pixelSize: 24
                    font.bold: true
                }

                Text {
                    text: "Navigate"
                    color: window.textMuted
                    font.family: "Inter"
                    font.pixelSize: 13
                    Layout.bottomMargin: 8
                }

                ColorButton {
                    text: "＋ Add new words"
                    bgColor: window.surfaceAltColor
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    font.family: "Inter"
                    font.pixelSize: 15
                    onClicked: addNewWordsPopup.open()
                }
                ColorButton {
                    text: "⌁ From text"
                    bgColor: "#1d2b43"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    font.family: "Inter"
                    font.pixelSize: 15
                    onClicked: newTextPopup.open()
                }
                ColorButton {
                    text: "✎ Expressions"
                    bgColor: window.surfaceAltColor
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    font.family: "Inter"
                    font.pixelSize: 15
                    onClicked: expressionsPopup.open()
                }
                ColorButton {
                    text: "⚡ Learn"
                    bgColor: "#1d2f50"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    font.family: "Inter"
                    font.pixelSize: 15
                    onClicked: learnPopup.open()
                }
                ColorButton {
                    text: "✓ Learned words"
                    bgColor: window.surfaceAltColor
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    font.family: "Inter"
                    font.pixelSize: 15
                    onClicked: learnedWordsPopup.open()
                }
                ColorButton {
                    text: "↻ Review"
                    bgColor: "#3a2130"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    font.family: "Inter"
                    font.pixelSize: 15
                    onClicked: reviewPopup.open()
                }
                ColorButton {
                    text: "◔ Dashboard"
                    bgColor: window.surfaceAltColor
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    font.family: "Inter"
                    font.pixelSize: 15
                    onClicked: dashboardPopup.open()
                }

                Item { Layout.fillHeight: true }

                Text {
                    text: "Double-click removed words to restore"
                    color: window.textMuted
                    wrapMode: Text.WordWrap
                    font.family: "Inter"
                    font.pixelSize: 12
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 18

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 400
                radius: 24
                color: Qt.rgba(27 / 255, 38 / 255, 59 / 255, 0.96)
                border.color: window.borderColor
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 30
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 20

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                text: "Current word"
                                color: window.textMuted
                                font.family: "Inter"
                                font.pixelSize: 14
                            }

                            Text {
                                text: appState.currentWord !== "" ? appState.currentWord : "Done"
                                color: window.textPrimary
                                font.family: "Inter"
                                font.pixelSize: appState.currentWord !== "" ? 62 : 52
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                text: appState.remainingCount + " words left"
                                color: window.textSecondary
                                font.family: "Inter"
                                font.pixelSize: 20
                            }
                        }

                        Item {
                            width: 170
                            height: 170

                            Canvas {
                                id: progressRing
                                anchors.fill: parent

                                Component.onCompleted: requestPaint()

                                onPaint: {
                                    const ctx = getContext("2d")
                                    const centerX = width / 2
                                    const centerY = height / 2
                                    const radius = Math.min(width, height) / 2 - 11
                                    const start = -Math.PI / 2
                                    const end = start + (Math.PI * 2 * window.knownProgress)

                                    ctx.reset()
                                    ctx.lineWidth = 14
                                    ctx.lineCap = "round"

                                    ctx.strokeStyle = "#2b3958"
                                    ctx.beginPath()
                                    ctx.arc(centerX, centerY, radius, 0, Math.PI * 2)
                                    ctx.stroke()

                                    const gradient = ctx.createLinearGradient(0, 0, width, height)
                                    gradient.addColorStop(0, "#60a5fa")
                                    gradient.addColorStop(1, "#2563eb")

                                    ctx.strokeStyle = gradient
                                    ctx.beginPath()
                                    ctx.arc(centerX, centerY, radius, start, end)
                                    ctx.stroke()
                                }
                            }

                            Connections {
                                target: window
                                function onKnownProgressChanged() { progressRing.requestPaint() }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: Math.round(window.knownProgress * 100) + "%"
                                    color: window.textPrimary
                                    font.family: "Inter"
                                    font.pixelSize: 28
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Text {
                                    text: "known"
                                    color: window.textMuted
                                    font.family: "Inter"
                                    font.pixelSize: 13
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: window.borderColor
                    }

                    Text {
                        text: window.hintVisible ? "Tip: Next marks this word as known, New word keeps it in learning, Remove moves it to removed list." : ""
                        visible: window.hintVisible
                        color: window.textMuted
                        font.family: "Inter"
                        font.pixelSize: 14
                        wrapMode: Text.WordWrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ColorButton {
                            text: "Remove"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            font.family: "Inter"
                            font.pixelSize: 18
                            bgColor: window.dangerColor
                            onClicked: app.removeCurrentWord()
                        }
                        ColorButton {
                            text: "Next word"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            font.family: "Inter"
                            font.pixelSize: 18
                            bgColor: window.accentStrong
                            onClicked: app.requestNextWord()
                        }
                        ColorButton {
                            text: "Correct"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            font.family: "Inter"
                            font.pixelSize: 18
                            bgColor: window.accentColor
                            onClicked: {
                                if (appState.currentWord !== "") {
                                    correctWordPopup.openForWord(appState.currentWord)
                                }
                            }
                        }
                        ColorButton {
                            text: "New word"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            font.family: "Inter"
                            font.pixelSize: 18
                            bgColor: "#1d4ed8"
                            onClicked: {
                                if (appState.currentWord !== "") {
                                    app.markWordNew(appState.currentWord)
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 14

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 18
                    color: window.surfaceAltColor
                    border.color: window.borderColor
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        Text {
                            text: "✓ Known words (" + appState.knownSequence.length + "/" + appState.vocabularyCount + ")"
                            color: window.successColor
                            font.family: "Inter"
                            font.pixelSize: 16
                            font.bold: true
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 8
                            model: appState.knownSequenceDisplay
                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 40
                                radius: 12
                                property bool isSelected: window.selectedWord === modelData && window.selectedOrigin === "known"
                                color: isSelected ? Qt.rgba(window.accentColor.r, window.accentColor.g, window.accentColor.b, 0.22) : "#111b2e"
                                border.color: isSelected ? window.accentSoft : "#22314f"
                                border.width: 1
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.right: parent.right
                                    anchors.rightMargin: 12
                                    text: modelData
                                    color: window.textSecondary
                                    font.family: "Inter"
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        window.selectedWord = modelData
                                        window.selectedOrigin = "known"
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 190
                    Layout.fillHeight: true
                    radius: 18
                    color: window.surfaceAltColor
                    border.color: window.borderColor
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Text {
                            text: "Actions"
                            color: window.textPrimary
                            font.family: "Inter"
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Text {
                            text: window.selectedWord === "" ? "Select a word card" : "Selected: " + window.selectedWord
                            color: window.textMuted
                            font.family: "Inter"
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }

                        ColorButton {
                            text: "→ Move to New"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            font.family: "Inter"
                            font.pixelSize: 14
                            bgColor: "#1d4ed8"
                            enabled: window.selectedWord !== "" && window.selectedOrigin === "known"
                            onClicked: {
                                app.moveWordToNew(window.selectedWord)
                                window.selectedWord = ""
                                window.selectedOrigin = ""
                            }
                        }

                        ColorButton {
                            text: "← Move to Known"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            font.family: "Inter"
                            font.pixelSize: 14
                            bgColor: window.accentStrong
                            enabled: window.selectedWord !== "" && window.selectedOrigin === "new"
                            onClicked: {
                                app.moveWordToKnown(window.selectedWord)
                                window.selectedWord = ""
                                window.selectedOrigin = ""
                            }
                        }

                        ColorButton {
                            text: "✕ Remove"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            font.family: "Inter"
                            font.pixelSize: 14
                            bgColor: window.dangerColor
                            enabled: window.selectedWord !== "" && (window.selectedOrigin === "known" || window.selectedOrigin === "new")
                            onClicked: {
                                app.removeWord(window.selectedWord)
                                window.selectedWord = ""
                                window.selectedOrigin = ""
                            }
                        }

                        ColorButton {
                            text: window.hintVisible ? "Hide tip" : "Show tip"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            font.family: "Inter"
                            font.pixelSize: 14
                            bgColor: "#13203a"
                            onClicked: window.hintVisible = !window.hintVisible
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 18
                    color: window.surfaceAltColor
                    border.color: window.borderColor
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        Text {
                            text: "• New words (" + appState.newSequence.length + "/" + appState.vocabularyCount + ")"
                            color: window.accentColor
                            font.family: "Inter"
                            font.pixelSize: 16
                            font.bold: true
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 8
                            model: appState.newSequenceDisplay
                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 40
                                radius: 12
                                property bool isSelected: window.selectedWord === modelData && window.selectedOrigin === "new"
                                color: isSelected ? Qt.rgba(window.accentColor.r, window.accentColor.g, window.accentColor.b, 0.22) : "#111b2e"
                                border.color: isSelected ? window.accentSoft : "#22314f"
                                border.width: 1
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.right: parent.right
                                    anchors.rightMargin: 12
                                    text: modelData
                                    color: window.textSecondary
                                    font.family: "Inter"
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        window.selectedWord = modelData
                                        window.selectedOrigin = "new"
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 18
                    color: window.surfaceAltColor
                    border.color: window.borderColor
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        Text {
                            text: "− Removed words (" + appState.removedSequence.length + ")"
                            color: window.dangerColor
                            font.family: "Inter"
                            font.pixelSize: 16
                            font.bold: true
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 8
                            model: appState.removedSequence
                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 40
                                radius: 12
                                property bool isSelected: window.selectedWord === modelData && window.selectedOrigin === "removed"
                                color: isSelected ? Qt.rgba(window.accentColor.r, window.accentColor.g, window.accentColor.b, 0.22) : "#111b2e"
                                border.color: isSelected ? window.accentSoft : "#22314f"
                                border.width: 1
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.right: parent.right
                                    anchors.rightMargin: 12
                                    text: modelData
                                    color: window.textSecondary
                                    font.family: "Inter"
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        window.selectedWord = modelData
                                        window.selectedOrigin = "removed"
                                    }
                                    onDoubleClicked: {
                                        app.restoreRemovedWord(modelData)
                                        window.selectedWord = ""
                                        window.selectedOrigin = ""
                                    }
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
