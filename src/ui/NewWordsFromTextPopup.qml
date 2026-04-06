import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    property bool embeddedMode: false
    // injected from Main.qml
    property var wordListPopup: null
    width: window.width * 0.9
    height: window.height * 0.8
    modal: true
    focus: true
    anchors.centerIn: parent
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle { color: window.surfaceColor; radius: 8; border.color: window.borderColor; border.width: 1 }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

    Text { text: "Scan Text for New Words"; color: window.textPrimary; font.pixelSize: 20 }

        TextArea {
            id: inputArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            placeholderText: "Paste text here..."
            font.pixelSize: 16
            wrapMode: TextArea.Wrap
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Button {
                text: "Cancel"
                visible: !root.embeddedMode
                onClicked: root.close()
            }
            Button {
                text: "Scan"
                onClicked: {
                    var res = app.findWordsInText(inputArea.text)
                    if (wordListPopup) {
                        // Reset properties first
                        wordListPopup.allowAdd = false
                        try { wordListPopup.addClicked.disconnect(root.handleAddAll) } catch(e) {}

                        if (!res || res.length === 0) {
                            wordListPopup.wordList = []
                            wordListPopup.title = "No new words found"
                        } else {
                            wordListPopup.wordList = res
                            wordListPopup.title = "Words from text (Found: " + res.length + ")"
                            wordListPopup.allowAdd = true
                            
                            // Define handler to be connected
                            root.handleAddAll = function() {
                                var count = app.addWords(res)
                                wordListPopup.close()
                                console.log("Added " + count + " words.")
                            }
                            wordListPopup.addClicked.connect(root.handleAddAll)
                        }
                        wordListPopup.open()
                    }
                    root.close()
                }
            }
        }
    }
    // Helper property to store the handler reference so we can disconnect it
    property var handleAddAll: null
}
