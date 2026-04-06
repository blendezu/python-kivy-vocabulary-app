import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    width: 600
    height: 800
    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property string title: "Word List"
    property var wordList: [] // string list
    property bool allowEdit: true
    property bool allowAdd: false
    
    signal wordSelected(string word)
    signal addClicked()

    background: Rectangle {
        color: window.surfaceColor
        border.color: window.borderColor
        border.width: 1
        radius: 10
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Text {
            text: root.title
            color: "white"
            font.pixelSize: 28
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }
        
        TextField {
            id: searchField
            placeholderText: "Search..."
            Layout.fillWidth: true
            font.pixelSize: 18
            color: "black"
            palette.base: "white"
            onTextChanged: listModel.updateFilter()
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 5
            
            model: ListModel {
                id: listModel
                function updateFilter() {
                    clear()
                    var term = searchField.text.toLowerCase()
                    for (var i = 0; i < root.wordList.length; i++) {
                        var w = root.wordList[i]
                        if (w.toLowerCase().indexOf(term) >= 0) {
                            append({ "word": w })
                        }
                    }
                }
            }

            delegate: ItemDelegate {
                width: listView.width
                height: 50
                
                background: Rectangle {
                    color: hovered ? window.surfaceAltColor : "transparent"
                    radius: 4
                }

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 10
                    text: model.word
                    color: "white"
                    font.pixelSize: 18
                }
                
                onClicked: {
                    root.wordSelected(model.word)
                }
            }
        }
        
        RowLayout {
            Layout.alignment: Qt.AlignHCenter

            Button {
                text: "Close"
                onClicked: root.close()
                palette.button: "#555555"
                palette.buttonText: "white"
            }

            Button {
                text: "Add"
                visible: root.allowAdd
                onClicked: root.addClicked()
                palette.button: window.accentColor
                palette.buttonText: "white"
            }
        }
    }
    
    onOpened: {
        searchField.text = ""
        listModel.updateFilter()
    }
    
    // Refresh list when the source array changes (if bound)
    onWordListChanged: {
        if (opened) listModel.updateFilter()
    }
}
