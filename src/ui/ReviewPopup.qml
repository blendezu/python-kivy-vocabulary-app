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
        color: window.surfaceColor
        radius: 8
        border.color: window.accentColor
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
            color: window.textPrimary
            font.pixelSize: 24
            font.bold: true
            Layout.fillWidth: true
        }
        Rectangle { height: 2; Layout.fillWidth: true; color: window.accentColor }

        // ── Date filters ─────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text { text: "From:"; color: window.textSecondary; font.pixelSize: 17; Layout.preferredWidth: 48 }
            TextField {
                id: fromInput
                Layout.fillWidth: true
                font.pixelSize: 18
                placeholderText: "DD/MM or YYYY-MM-DD"
                background: Rectangle { color: "#e8eff5"; radius: 4 }
                onTextChanged: Qt.callLater(root.rebuildPool)
            }
            Text { text: "To:"; color: window.textSecondary; font.pixelSize: 17; Layout.preferredWidth: 30 }
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
                    color: twisterBtn.checked ? window.accentStrong : window.surfaceAltColor
                    radius: 4
                }
                contentItem: Text {
                    text: twisterBtn.text
                    color: window.textPrimary
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
            color: window.accentSoft
            font.pixelSize: 17
            Layout.fillWidth: true
        }

        // ── Spacer ───────────────────────────────────────────
        Item { Layout.preferredHeight: 24 }

        // ── Current word ─────────────────────────────────────
        Text {
            text: root.currentItem.word || (root.reviewPool.length === 0 ? "No words in pool" : "")
            color: root.reviewPool.length === 0 ? window.textMuted : window.textPrimary
            font.pixelSize: 64
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.currentItem.word && root.editPopupRef) {
                        root.editPopupRef.fromLearn = false
                        root.editPopupRef.wordToEdit = root.currentItem.word
                        root.editPopupRef.open()
                    }
                }
            }
        }

        // ── IPA ──────────────────────────────────────────────
        Text {
            text: root.currentItem.ipa ? "[" + root.currentItem.ipa + "]" : ""
            color: window.accentSoft
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
                background: Rectangle { color: window.accentColor; radius: 6 }
                contentItem: Text { text: parent.text; color: "#fff"; font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                onClicked: if (root.currentItem.word) app.tts.speak(root.currentItem.word)
                enabled: !!root.currentItem.word
            }

            Button {
                id: speakButton
                // Match Python: Fixed duration, show "Speak" normally, "Listening..." when active
                text: app.stt.isRecording ? "Listening..." : (app.stt.isTranscribing ? "Thinking..." : "Speak")
                font.pixelSize: 20
                width: 110; height: 54
                background: Rectangle { 
                    color: app.stt.isRecording || app.stt.isTranscribing ? "#e03333" : "#e05540"
                    radius: 6 
                }
                contentItem: Text { text: parent.text; color: "#fff"; font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                
                onClicked: {
                    if (app.stt.isRecording) {
                        // Allow user to stop early if they want, but usually it stops after 3s
                        app.stt.stopRecording()
                    } else if (!app.stt.isTranscribing) {
                        sttResultLabel.text = "Speak now..."
                        sttResultLabel.color = "white"
                        // Match Python: 3.0 seconds
                        app.stt.startListening(3000)
                    }
                }
                enabled: !!root.currentItem.word && !app.stt.isTranscribing
            }
        }
        
        Text {
            id: sttResultLabel
            text: ""
            color: "white"
            font.pixelSize: 16
            Layout.alignment: Qt.AlignHCenter
            visible: text !== ""
        }
        
        Connections {
            target: app.stt
            function onTranscriptionResult(text, error) {
                if (error) {
                    sttResultLabel.text = "Error: " + error
                    sttResultLabel.color = "#ff6666"
                } else {
                    console.log("Transcription: " + text)
                    var cleanText = text.replace(/[^a-zA-Z0-9]/g, "").toLowerCase()
                    if (!root.currentItem.word) return;
                    var target = root.currentItem.word.replace(/[^a-zA-Z0-9]/g, "").toLowerCase()
                    
                    if (cleanText === target) {
                        sttResultLabel.text = "Correct! (" + text + ")"
                        sttResultLabel.color = "#88ff88"
                    } else {
                        sttResultLabel.text = "Heard: " + text
                        sttResultLabel.color = "#ffaa88"
                    }
                }
                
                // Reset button state logic if needed (it resets automatically via isRecording binding)
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
                            color: window.textPrimary
                            font.pixelSize: 20
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            visible: modelData.meaning !== ""
                        }

                        Repeater {
                            model: modelData.examples || []
                            delegate: Text {
                                text: "- " + modelData
                                color: window.textSecondary
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
        Item { Layout.fillHeight: true } // Push buttons to bottom

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40 // Reduced height
            spacing: 12

            Button {
                text: "Close"
                font.pixelSize: 16
                Layout.fillWidth: true
                Layout.fillHeight: true
                background: Rectangle { 
                    color: window.surfaceAltColor
                    radius: 6 
                }
                contentItem: Text { 
                    text: parent.text
                    color: window.textPrimary
                    font: parent.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.close()
            }

            Button {
                text: root.revealed ? "Next" : "Show"
                font.pixelSize: 16
                Layout.fillWidth: true
                Layout.fillHeight: true
                background: Rectangle {
                    color: root.revealed ? window.accentStrong : window.accentColor
                    radius: 6
                }
                contentItem: Text { 
                    text: parent.text
                    color: "#fff"
                    font: parent.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                enabled: (root.reviewPool && root.reviewPool.length > 0)
                onClicked: {
                    if (root.revealed) {
                        // Mark as reviewed? Logic not implemented
                        root.pickRandom()
                    } else {
                        root.revealed = true
                        // Show all details is handled by visibility binding
                    }
                }
            }
        }
    }
}
