import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: correctPopup
    width: 600
    height: 300
    anchors.centerIn: parent
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    background: Rectangle {
        color: window.surfaceColor
        radius: 8
        border.color: window.borderColor
        border.width: 1
    }
    
    property string originalWord: ""
    
    function openForWord(word) {
        if (word === "") return;
        originalWord = word;
        inputField.text = word;
        open();
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15
        
        Text {
            text: "Correct word and save:"
            color: window.textPrimary
            font.pixelSize: 18
            Layout.fillWidth: true
        }
        
        TextField {
            id: inputField
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            font.pixelSize: 22
            color: "white"
            background: Rectangle {
                color: window.surfaceAltColor
                radius: 4
                border.color: inputField.activeFocus ? window.accentColor : window.borderColor
            }
        }
        
        Item { Layout.fillHeight: true }
        
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            
            Button {
                text: "Cancel"
                Layout.fillWidth: true
                height: 45
                font.pixelSize: 20
                background: Rectangle {
                    color: window.dangerColor
                    radius: 4
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font: parent.font
                }
                onClicked: correctPopup.close()
            }
            
            Button {
                text: "Save"
                Layout.fillWidth: true
                height: 45
                font.pixelSize: 20
                background: Rectangle {
                    color: window.accentStrong
                    radius: 4
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font: parent.font
                }
                onClicked: {
                    var newText = inputField.text.trim();
                    if (newText !== "" && newText !== originalWord) {
                        app.correctWord(originalWord, newText);
                        
                        // We also need to clear selection in Main.qml
                        window.selectedWord = newText; 
                    }
                    correctPopup.close()
                }
            }
        }
    }
}
