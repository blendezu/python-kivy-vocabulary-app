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
    closePolicy: Popup.CloseOnEscape

    property var editPopupRef: null

    background: Rectangle {
        color: "#22252a"
        radius: 8
        border.color: "#3385e6"
        border.width: 1
    }

    // Internal state
    property var reviewPool: []
    property int currentIdx: -1
    property bool revealed: false
    property var currentItem: ({})

    function rebuildPool() {
        reviewPool = app.getReviewPool(fromInput.text, toInput.text, twisterBtn.checked)
        currentIdx = -1
        revealed = false
        currentItem = {}
        if (reviewPool.length > 0) {
            pickRandom()
        }
    }

    function pickRandom() {
        if (reviewPool.length === 0) {
            currentItem = {}
            currentIdx = -1
            return
        }
        currentIdx = Math.floor(Math.random() * reviewPool.length)
        currentItem = reviewPool[currentIdx]
        revealed = false
    }

    onOpened: {
        fromInput.text = ""
        toInput.text = ""
        twisterBtn.checked = false
        rebuildPool()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        // ── Header ──────────────────────────────────────────
        Text {
            text: "Review"
            color: "#f2faff"
            font.pixelSize: 24
            font.bold: true
            Layout.fillWidth: true
        }
        Rectangle { height: 2; Layout.fillWidth: true; color: "#3385e6" }

        // ── Date filters ─────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text { text: "From:"; color: "#9bb0c8"; font.pixelSize: 17; Layout.preferredWidth: 48 }
            TextField {
                id: fromInput
                Layout.fillWidth: true
                font.pixelSize: 18
                placeholderText: "DD/MM or YYYY-MM-DD"
                background: Rectangle { color: "#e8eff5"; radius: 4 }
                onTextChanged: Qt.callLater(root.rebuildPool)
            }
            Text { text: "To:"; color: "#9bb0c8"; font.pixelSize: 17; Layout.preferredWidth: 30 }
            TextField {
                id: toInput
                Layout.fillWidth: true
                font.pixelSize: 18
                placeholderText: "DD/MM or YYYY-MM-DD"
                background: Rectangle { color: "#e8eff5"; radius: 4 }
                onTextChanged: Qt.callLater(root.rebuildPool)
            }
            Button {
                id: twisterBtn
                text: "Tongue-twister"
                font.pixelSize: 16
                checkable: true
                Layout.preferredWidth: 160
                background: Rectangle {
                    color: twisterBtn.checked ? "#6655aa" : "#3d4355"
                    radius: 4
                }
                contentItem: Text {
                    text: twisterBtn.text
                    color: "#f2faff"
                    font: twisterBtn.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onCheckedChanged: root.rebuildPool()
            }
        }

        // ── Word count label ─────────────────────────────────
        Text {
            text: root.reviewPool.length + " words in pool"
            color: "#6888cc"
            font.pixelSize: 17
            Layout.fillWidth: true
        }

        // ── Spacer ───────────────────────────────────────────
        Item { Layout.preferredHeight: 24 }

        // ── Current word ─────────────────────────────────────
        Text {
            text: root.currentItem.word || (root.reviewPool.length === 0 ? "No words in pool" : "")
            color: root.reviewPool.length === 0 ? "#666" : "#f2faff"
            font.pixelSize: 64
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.currentItem.word && root.editPopupRef) {
                        root.editPopupRef.wordToEdit = root.currentItem.word
                        root.editPopupRef.open()
                    }
                }
            }
        }

        // ── IPA ──────────────────────────────────────────────
        Text {
            text: root.currentItem.ipa ? "[" + root.currentItem.ipa + "]" : ""
            color: "#a0ccbf"
            font.pixelSize: 22
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }

        // ── Listen + Speak buttons ────────────────────────────
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            Button {
                text: "Listen"
                font.pixelSize: 20
                width: 110; height: 54
                background: Rectangle { color: "#3b82f6"; radius: 6 }
                contentItem: Text { text: parent.text; color: "#fff"; font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                onClicked: if (root.currentItem.word) app.tts.speak(root.currentItem.word)
                enabled: !!root.currentItem.word
            }

            Button {
                text: "Speak"
                font.pixelSize: 20
                width: 110; height: 54
                background: Rectangle { color: "#e05540"; radius: 6 }
                contentItem: Text { text: parent.text; color: "#fff"; font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                onClicked: if (root.currentItem.word) app.stt.startListening()
                enabled: !!root.currentItem.word
            }
        }

        // ── Revealed meanings area ───────────────────────────
        ScrollView {
            id: meaningsScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            visible: root.revealed && !!root.currentItem.word

            ColumnLayout {
                width: meaningsScroll.availableWidth
                spacing: 6

                Repeater {
                    model: root.currentItem.details || []
                    delegate: ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Layout.leftMargin: 4

                        Text {
                            text: (index + 1) + ". " + (modelData.meaning || "")
                            color: "#f0f4ff"
                            font.pixelSize: 20
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            visible: modelData.meaning !== ""
                        }

                        Repeater {
                            model: modelData.examples || []
                            delegate: Text {
                                text: "- " + modelData
                                color: "#b0c8e8"
                                font.pixelSize: 18
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                Layout.leftMargin: 16
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // ── Bottom bar ───────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            spacing: 8

            Button {
                text: "Close"
                font.pixelSize: 18
                Layout.fillWidth: true
                Layout.fillHeight: true
                background: Rectangle { color: "#5a5a6a"; radius: 6 }
                contentItem: Text { text: parent.text; color: "#e2e8f0"; font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                onClicked: root.close()
            }

            Button {
                text: root.revealed ? "Next" : "Show"
                font.pixelSize: 18
                Layout.fillWidth: true
                Layout.fillHeight: true
                background: Rectangle {
                    color: root.revealed ? "#22bb66" : "#3b82f6"
                    radius: 6
                }
                contentItem: Text { text: parent.text; color: "#fff"; font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                enabled: !!root.currentItem.word
                onClicked: {
                    if (root.revealed) {
                        root.pickRandom()
                    } else {
                        root.revealed = true
                    }
                }
            }
        }
    }
}
