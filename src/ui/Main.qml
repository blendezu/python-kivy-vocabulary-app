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
    property string activePane: "home"
    property int knownCount: appState.knownSequence.length
    property int totalCount: Math.max(1, appState.vocabularyCount)
    property real knownProgress: Math.min(1.0, knownCount / totalCount)

    function closeAllPanes() {
        addNewWordsPopup.close()
        newTextPopup.close()
        expressionsPopup.close()
        learnPopup.close()
        learnedWordsPopup.close()
        reviewPopup.close()
        dashboardPopup.close()
        translatePopup.close()
        pdfModePopup.close()
    }

    function openPane(name) {
        activePane = name
        closeAllPanes()

        if (name === "add") {
            addNewWordsPopup.open()
        } else if (name === "fromText") {
            newTextPopup.open()
        } else if (name === "expressions") {
            expressionsPopup.open()
        } else if (name === "learn") {
            learnPopup.open()
        } else if (name === "learned") {
            learnedWordsPopup.open()
        } else if (name === "review") {
            reviewPopup.open()
        } else if (name === "dashboard") {
            dashboardPopup.open()
        } else if (name === "translate") {
            translatePopup.open()
        } else if (name === "pdfMode") {
            pdfModePopup.open()
        }
    }

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

    component NavTileButton: Button {
        id: navTile
        property string iconSymbol: ""
        property string labelText: ""
        property bool active: false
        property color tileColor: "#172b47"

        Layout.fillWidth: true
        Layout.preferredHeight: 54
        hoverEnabled: true
        scale: navTile.down ? 0.992 : 1.0

        Behavior on scale { NumberAnimation { duration: 110 } }

        background: Rectangle {
            id: navBg
            radius: 14
            color: navTile.active
                   ? Qt.rgba(window.accentColor.r, window.accentColor.g, window.accentColor.b, 0.2)
                   : (navTile.hovered
                      ? Qt.rgba(27 / 255, 47 / 255, 78 / 255, 0.95)
                      : navTile.tileColor)
            border.color: navTile.active
                          ? Qt.lighter(window.accentColor, 1.16)
                          : (navTile.hovered ? "#2d4f7d" : "#223a5e")
            border.width: navTile.active || navTile.hovered ? 1 : 0

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.color: Qt.rgba(1, 1, 1, navTile.active ? 0.08 : 0.03)
                border.width: 1
            }
        }

        contentItem: RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 11
            anchors.rightMargin: 12
            spacing: 10

            Rectangle {
                width: 28
                height: 28
                radius: 9
                color: navTile.active
                       ? Qt.rgba(window.accentColor.r, window.accentColor.g, window.accentColor.b, 0.22)
                       : Qt.rgba(1, 1, 1, 0.06)
                border.color: navTile.active
                              ? Qt.rgba(window.accentSoft.r, window.accentSoft.g, window.accentSoft.b, 0.85)
                              : Qt.rgba(1, 1, 1, 0.10)
                border.width: 1
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: navTile.iconSymbol
                    color: navTile.active ? "#dbeafe" : window.textSecondary
                    font.family: "Inter"
                    font.pixelSize: 14
                    font.bold: navTile.active
                }
            }

            Text {
                text: navTile.labelText
                color: navTile.active ? window.textPrimary : window.textSecondary
                font.family: "Inter"
                font.pixelSize: 16
                font.bold: navTile.active
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                elide: Text.ElideRight
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 18

        Rectangle {
            Layout.preferredWidth: 238
            Layout.fillHeight: true
            radius: 24
            color: Qt.rgba(19 / 255, 32 / 255, 54 / 255, 0.96)
            border.color: window.borderColor
            border.width: 1

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(96 / 255, 165 / 255, 250 / 255, 0.16)
            }

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height * 0.25
                radius: parent.radius
                color: Qt.rgba(59 / 255, 130 / 255, 246 / 255, 0.07)
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 11

                Text {
                    text: "VocaApp"
                    color: window.textPrimary
                    font.family: "Inter"
                    font.pixelSize: 25
                    font.bold: true
                }

                Text {
                    text: "Navigate"
                    color: window.textMuted
                    font.family: "Inter"
                    font.pixelSize: 13
                    font.letterSpacing: 0.6
                    Layout.bottomMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Qt.rgba(1, 1, 1, 0.07)
                    Layout.bottomMargin: 4
                }

                NavTileButton {
                    iconSymbol: "⌂"
                    labelText: "Home"
                    tileColor: "#172b47"
                    active: window.activePane === "home"
                    onClicked: window.openPane("home")
                }
                NavTileButton {
                    iconSymbol: "＋"
                    labelText: "Add new words"
                    tileColor: "#172b47"
                    active: window.activePane === "add"
                    onClicked: window.openPane("add")
                }
                NavTileButton {
                    iconSymbol: "⌁"
                    labelText: "From text"
                    tileColor: "#172b47"
                    active: window.activePane === "fromText"
                    onClicked: window.openPane("fromText")
                }
                NavTileButton {
                    iconSymbol: "✎"
                    labelText: "Expressions"
                    tileColor: "#172b47"
                    active: window.activePane === "expressions"
                    onClicked: window.openPane("expressions")
                }
                NavTileButton {
                    iconSymbol: "⚡"
                    labelText: "Learn"
                    tileColor: "#172b47"
                    active: window.activePane === "learn"
                    onClicked: window.openPane("learn")
                }
                NavTileButton {
                    iconSymbol: "✓"
                    labelText: "Learned words"
                    tileColor: "#172b47"
                    active: window.activePane === "learned"
                    onClicked: window.openPane("learned")
                }
                NavTileButton {
                    iconSymbol: "↻"
                    labelText: "Review"
                    tileColor: "#172b47"
                    active: window.activePane === "review"
                    onClicked: window.openPane("review")
                }
                NavTileButton {
                    iconSymbol: "◔"
                    labelText: "Dashboard"
                    tileColor: "#172b47"
                    active: window.activePane === "dashboard"
                    onClicked: window.openPane("dashboard")
                }
                NavTileButton {
                    iconSymbol: "🌐"
                    labelText: "Translate"
                    tileColor: "#172b47"
                    active: window.activePane === "translate"
                    onClicked: window.openPane("translate")
                }
                NavTileButton {
                    iconSymbol: "📄"
                    labelText: "PDF mode"
                    tileColor: "#172b47"
                    active: window.activePane === "pdfMode"
                    onClicked: window.openPane("pdfMode")
                }

                Item { Layout.fillHeight: true }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ColumnLayout {
                anchors.fill: parent
                visible: window.activePane === "home"
                spacing: 28

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
                    Layout.topMargin: 6
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
                                height: 46
                                radius: 14
                                property bool isSelected: window.selectedWord === modelData && window.selectedOrigin === "known"
                                color: isSelected ? Qt.rgba(window.accentColor.r, window.accentColor.g, window.accentColor.b, 0.22) : "#111b2e"
                                border.color: isSelected ? window.accentSoft : "#22314f"
                                border.width: 1

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 5
                                    width: 3
                                    radius: 2
                                    color: isSelected ? window.accentSoft : "#2d3f60"
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 14
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
                                height: 46
                                radius: 14
                                property bool isSelected: window.selectedWord === modelData && window.selectedOrigin === "new"
                                color: isSelected ? Qt.rgba(window.accentColor.r, window.accentColor.g, window.accentColor.b, 0.22) : "#111b2e"
                                border.color: isSelected ? window.accentSoft : "#22314f"
                                border.width: 1

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 5
                                    width: 3
                                    radius: 2
                                    color: isSelected ? window.accentSoft : "#2d3f60"
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 14
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
                                height: 46
                                radius: 14
                                property bool isSelected: window.selectedWord === modelData && window.selectedOrigin === "removed"
                                color: isSelected ? Qt.rgba(window.accentColor.r, window.accentColor.g, window.accentColor.b, 0.22) : "#111b2e"
                                border.color: isSelected ? window.accentSoft : "#22314f"
                                border.width: 1

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 5
                                    width: 3
                                    radius: 2
                                    color: isSelected ? window.accentSoft : "#2d3f60"
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 14
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

                        Text {
                            text: "Double-click removed words to restore"
                            color: window.textMuted
                            wrapMode: Text.WordWrap
                            font.family: "Inter"
                            font.pixelSize: 12
                            opacity: 0.92
                            Layout.fillWidth: true
                        }
                    }
                }
                }
            }

            Item {
                id: rightPaneHost
                anchors.fill: parent
                visible: window.activePane !== "home"
            }
        }
    }

    // --- Popups ---
    Dashboard {
        id: dashboardPopup
        embeddedMode: true
        parent: rightPaneHost
        modal: false
        focus: false
        closePolicy: Popup.NoAutoClose
        width: rightPaneHost.width * 0.98
        height: rightPaneHost.height * 0.98
        anchors.centerIn: parent
        onClosed: if (window.activePane === "dashboard") window.activePane = "home"
    }
    TranslatePopup {
        id: translatePopup
        embeddedMode: true
        parent: rightPaneHost
        modal: false
        focus: false
        closePolicy: Popup.NoAutoClose
        width: rightPaneHost.width * 0.98
        height: rightPaneHost.height * 0.98
        anchors.centerIn: parent
        onClosed: if (window.activePane === "translate") window.activePane = "home"
    }
    PdfModePopup {
        id: pdfModePopup
        embeddedMode: true
        parent: rightPaneHost
        modal: false
        focus: false
        closePolicy: Popup.NoAutoClose
        width: rightPaneHost.width * 0.98
        height: rightPaneHost.height * 0.98
        anchors.centerIn: parent
        onClosed: if (window.activePane === "pdfMode") window.activePane = "home"
    }
    
    LearnPopup {
        id: learnPopup
        embeddedMode: true
        parent: rightPaneHost
        modal: false
        focus: false
        closePolicy: Popup.NoAutoClose
        width: rightPaneHost.width * 0.98
        height: rightPaneHost.height * 0.98
        anchors.centerIn: parent
        learnedWordsPopup: learnedWordsPopup
        reviewPopup: reviewPopup
        editPopup: editPopup
        onClosed: if (window.activePane === "learn") window.activePane = "home"
    }
    ReviewPopup {
        id: reviewPopup
        embeddedMode: true
        parent: rightPaneHost
        modal: false
        focus: false
        closePolicy: Popup.NoAutoClose
        width: rightPaneHost.width * 0.98
        height: rightPaneHost.height * 0.98
        anchors.centerIn: parent
        onClosed: if (window.activePane === "review") window.activePane = "home"
    }
    WordEditPopup { id: editPopup }
    CorrectWordPopup { id: correctWordPopup }

    AddNewWordsPopup {
        id: addNewWordsPopup
        embeddedMode: true
        parent: rightPaneHost
        modal: false
        focus: false
        closePolicy: Popup.NoAutoClose
        width: rightPaneHost.width * 0.98
        height: rightPaneHost.height * 0.98
        anchors.centerIn: parent
        onClosed: if (window.activePane === "add") window.activePane = "home"
    }
    NewWordsFromTextPopup {
        id: newTextPopup
        embeddedMode: true
        parent: rightPaneHost
        modal: false
        focus: false
        closePolicy: Popup.NoAutoClose
        width: rightPaneHost.width * 0.98
        height: rightPaneHost.height * 0.98
        anchors.centerIn: parent
        wordListPopup: wordListPopup
        onClosed: if (window.activePane === "fromText") window.activePane = "home"
    }
    ExpressionsPopup {
        id: expressionsPopup
        embeddedMode: true
        parent: rightPaneHost
        modal: false
        focus: false
        closePolicy: Popup.NoAutoClose
        width: rightPaneHost.width * 0.98
        height: rightPaneHost.height * 0.98
        anchors.centerIn: parent
        editPopupRef: editPopup
        onClosed: if (window.activePane === "expressions") window.activePane = "home"
    }
    LearnedWordsPopup {
        id: learnedWordsPopup
        embeddedMode: true
        parent: rightPaneHost
        modal: false
        focus: false
        closePolicy: Popup.NoAutoClose
        width: rightPaneHost.width * 0.98
        height: rightPaneHost.height * 0.98
        anchors.centerIn: parent
        editPopupRef: editPopup
        onClosed: if (window.activePane === "learned") window.activePane = "home"
    }
    WordListPopup { id: wordListPopup }
}
