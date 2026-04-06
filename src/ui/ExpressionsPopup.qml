import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    property var editPopupRef: null
    property var exprItems: []

    width: window.width * 0.95
    height: window.height * 0.95
    modal: true
    focus: true
    anchors.centerIn: parent
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle { color: window.surfaceColor; radius: 8; border.color: window.borderColor; border.width: 1 }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Text { 
            text: "Expressions & Phrases"
            color: window.textPrimary
            font.pixelSize: 22
            font.bold: true
            Layout.fillWidth: true
        }

        TextField {
            id: searchInput
            placeholderText: "Search..."
            Layout.fillWidth: true
            font.pixelSize: 18
            background: Rectangle { color: "#e8eff5"; radius: 4 }
            onTextChanged: rebuildList()
        }

        Rectangle {
            Layout.fillWidth: true
            height: 2
            color: window.accentColor
            Layout.topMargin: -8
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 16
            model: root.exprItems
            
            delegate: Rectangle {
                width: listView.width
                height: contentCol.height + 16
                color: "transparent"

                ColumnLayout {
                    id: contentCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 4
                    spacing: 6

                    Text {
                        text: modelData.word
                        color: window.textPrimary
                        font.pixelSize: 22
                        font.bold: true
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (editPopupRef) {
                                    editPopupRef.fromLearn = false
                                    editPopupRef.wordToEdit = modelData.word
                                    editPopupRef.open()
                                }
                            }
                        }
                    }

                    Repeater {
                        model: modelData.details
                        delegate: ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 4
                            spacing: 4
                            
                            Text {
                                text: (index + 1) + ". " + modelData.meaning
                                color: window.textPrimary
                                font.pixelSize: 20
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                visible: modelData.meaning !== ""
                            }
                            
                            Repeater {
                                model: modelData.examples
                                delegate: Text {
                                    text: "- " + modelData
                                    color: window.textSecondary
                                    font.pixelSize: 18
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 12
                                }
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Button {
                text: "Add"
                font.pixelSize: 20
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                background: Rectangle { color: window.accentColor; radius: 6 }
                contentItem: Text { text: parent.text; color: "#ffffff"; font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                onClicked: addExprPopup.open()
            }
            
            Button { 
                text: "Close"
                font.pixelSize: 20
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                background: Rectangle { color: window.surfaceAltColor; radius: 6 }
                contentItem: Text { text: parent.text; color: window.textPrimary; font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                onClicked: root.close() 
            }
        }
    }

    onOpened: {
        searchInput.text = ""
        rebuildList()
    }

    function rebuildList() {
        root.exprItems = app.getExpressionsWithDetails(searchInput.text)
    }

    // Inline Add popup
    Popup {
        id: addExprPopup
        width: root.width * 0.8
        height: root.height * 0.6
        modal: true; focus: true; anchors.centerIn: parent
    background: Rectangle { color: window.surfaceAltColor; radius: 8; border.color: window.borderColor; border.width: 1 }
        
        ColumnLayout { 
            anchors.fill: parent; anchors.margins: 16; spacing: 12
            Text { text: "New expression"; color: window.textPrimary; font.pixelSize: 22; font.bold: true }
            TextField { id: phraseField; placeholderText: "Expression / phrase"; Layout.fillWidth: true; font.pixelSize: 18 }
            TextArea { id: meaningArea; placeholderText: "Meaning (optional)"; Layout.fillWidth: true; Layout.fillHeight: true; font.pixelSize: 18; wrapMode: TextArea.Wrap }
            TextField { id: exampleField; placeholderText: "Example (optional)"; Layout.fillWidth: true; font.pixelSize: 18 }
            
            RowLayout { 
                Layout.fillWidth: true; spacing: 12
                Button { 
                    text: "Cancel"
                    Layout.fillWidth: true
                    onClicked: addExprPopup.close() 
                }
                Button {
                    text: "Add"
                    Layout.fillWidth: true
                    background: Rectangle { color: window.accentColor; radius: 4 }
                    contentItem: Text { text: parent.text; color: "#ffffff"; font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    onClicked: {
                        var phrase = phraseField.text.trim()
                        if (!phrase) return
                        var details = []
                        var entry = {"meaning": meaningArea.text.trim(), "examples": [] , "pos": []}
                        if (exampleField.text.trim()) entry.examples.push(exampleField.text.trim())
                        details.push(entry)
                        app.addExpression(phrase, details)
                        
                        phraseField.text = ""
                        meaningArea.text = ""
                        exampleField.text = ""
                        
                        addExprPopup.close()
                        rebuildList()
                    }
                }
            }
        }
    }
}
