import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    property bool embeddedMode: false
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

        Text { 
            text: "Paste new words, one per line (with or without prefix). They will be saved as 'New'."
            color: window.textPrimary
            font.pixelSize: 18
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        TextArea {
            id: inputArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            placeholderText: "apple\nbanana\ncherry..."
            font.pixelSize: 18
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
                text: "Add (New)"
                onClicked: {
                    var addedCount = app.addNewWordsFromText(inputArea.text)
                    inputArea.text = ""
                    root.close()
                    // Optional: show a small toast/alert about addedCount
                    console.log("Added " + addedCount + " new words.")
                }
            }
        }
    }
}
