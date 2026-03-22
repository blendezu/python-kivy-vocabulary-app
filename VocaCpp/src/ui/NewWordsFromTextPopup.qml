import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    // injected from Main.qml
    property var wordListPopup: null
    width: window.width * 0.9
    height: window.height * 0.8
    modal: true
    focus: true
    anchors.centerIn: parent
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle { color: "#1e232e"; radius: 8; border.color: "#333"; border.width: 1 }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Text { text: "Scan Text for New Words"; color: "#f2faff"; font.pixelSize: 20 }

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
            Button { text: "Cancel"; onClicked: root.close() }
            Button {
                text: "Scan"
                onClicked: {
                    var res = app.findWordsInText(inputArea.text)
                    if (wordListPopup) {
                        if (!res || res.length === 0) {
                            wordListPopup.wordList = []
                            wordListPopup.title = "No new words found"
                        } else {
                            wordListPopup.wordList = res
                            wordListPopup.title = "Words from text"
                        }
                        wordListPopup.open()
                    }
                    root.close()
                }
            }
        }
    }
}
