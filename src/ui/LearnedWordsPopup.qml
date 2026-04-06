import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    property var editPopupRef: null
    property var learnedItems: []

    width: window.width * 0.95
    height: window.height * 0.95
    modal: true
    focus: true
    anchors.centerIn: parent
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle { color: window.surfaceColor; radius: 8; border.color: window.borderColor; border.width: 1 }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Text { 
            id: headerLabel
            text: "Learned words & expressions"
            color: window.textPrimary
            font.pixelSize: 32
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            TextField {
                id: searchInput
                placeholderText: "Search..."
                Layout.fillWidth: true
                font.pixelSize: 18
                onTextChanged: rebuildList()
            }
            
            Button {
                id: twisterFilterBtn
                text: "Tongue-twister"
                checkable: true
                checked: false
                onCheckedChanged: rebuildList()
            }
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8
            model: root.learnedItems
            
            delegate: Rectangle {
                width: listView.width
                height: contentCol.height + 16
                color: window.surfaceAltColor
                radius: 6

                ColumnLayout {
                    id: contentCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 8
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        
                        Button {
                            text: "Listen"
                            font.pixelSize: 18
                            background: Rectangle { color: window.accentColor; radius: 4 }
                            contentItem: Text { text: parent.text; color: window.textPrimary; font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            onClicked: {
                                if (app.tts) app.tts.speak(modelData.word)
                            }
                        }
                        
                        Text {
                            text: modelData.word
                            color: window.textPrimary
                            font.pixelSize: 26
                            Layout.fillWidth: true
                            elide: Text.ElideRight
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
                    }

                    Text {
                        text: "[IPA] " + modelData.ipa
                        color: window.accentSoft
                        font.pixelSize: 18
                        visible: modelData.ipa !== ""
                        Layout.leftMargin: 8
                    }

                    Repeater {
                        model: modelData.details
                        delegate: ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            spacing: 4
                            
                            Text {
                                text: (index + 1) + ". " + (modelData.pos.length > 0 ? ("(" + modelData.pos.join(", ") + ") ") : "") + modelData.meaning
                                color: window.textPrimary
                                font.pixelSize: 22
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                            
                            Repeater {
                                model: modelData.examples
                                delegate: Text {
                                    text: "- " + modelData
                                    color: window.textSecondary
                                    font.pixelSize: 18
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 20
                                }
                            }
                        }
                    }
                    
                    Text {
                        text: "– No meanings available –"
                        color: window.textMuted
                        font.pixelSize: 16
                        visible: !modelData.details || modelData.details.length === 0
                        Layout.leftMargin: 8
                    }
                }
            }
            
            Text {
                text: "No results."
                color: window.textMuted
                font.pixelSize: 20
                visible: root.learnedItems.length === 0
                anchors.centerIn: parent
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Button { 
                text: "Close"
                font.pixelSize: 20
                onClicked: root.close() 
            }
        }
    }

    onOpened: {
        rebuildList()
    }

    function rebuildList() {
        var items = app.getLearnedWordsAndExpressions(searchInput.text, twisterFilterBtn.checked)
        headerLabel.text = items.length + " learned words & expressions" + (twisterFilterBtn.checked ? " • TT" : "")
        root.learnedItems = items.slice(0, 300) // cap at 300 to avoid giant arrays if needed, though lazy loading handles it
    }
}
