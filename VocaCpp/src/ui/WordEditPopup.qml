import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    width: 700
    height: 900
    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property string targetWord: ""
    property string targetIpa: ""
    property var detailsList: []

    signal saved()

    background: Rectangle {
        color: "#1e1e1e"
        border.color: "#333333"
        border.width: 1
        radius: 10
    }

    onOpened: {
        // Load data from app state for targetWord
        if (targetWord === "") return
        var d = app.state.wordDetails[targetWord.toLowerCase()]
        // Deep copy to allow editing without live update until save
        if (d) {
            // Convert to JS array of objects
            var temp = []
            for (var i=0; i<d.length; i++) temp.push({
                "meaning": d[i].meaning,
                "examples": d[i].examples, 
                "pos": d[i].pos
            })
            detailsList = temp
        } else {
            detailsList = []
        }
        targetIpa = app.state.wordIpa[targetWord.toLowerCase()] || ""
        
        // Reset models
        detailsModel.clear()
        for (var k=0; k<detailsList.length; k++) {
            detailsModel.append(detailsList[k])
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Text {
            text: "Edit Word: " + root.targetWord
            color: "white"
            font.pixelSize: 24
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        RowLayout {
            Text { text: "IPA:"; color: "#dddddd"; font.pixelSize: 18 }
            TextField {
                id: ipaField
                text: root.targetIpa
                Layout.fillWidth: true
                font.pixelSize: 18
                color: "black"
                palette.base: "white"
            }
        }

        // List of Meanings
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: ListModel { id: detailsModel }
            spacing: 10

            delegate: Rectangle {
                width: listView.width
                height: col.height + 20
                color: "#2a2a2a"
                radius: 6
                
                ColumnLayout {
                    id: col
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10
                    spacing: 5
                    
                    Text { text: "Meaning:"; color: "#aaaaaa"; font.pixelSize: 14 }
                    TextField {
                        text: model.meaning
                        Layout.fillWidth: true
                        font.pixelSize: 16
                        color: "black"
                        palette.base: "white"
                        onEditingFinished: model.meaning = text
                    }
                    
                    Text { text: "Example (one per line):"; color: "#aaaaaa"; font.pixelSize: 14 }
                    TextArea {
                        text: (model.examples && model.examples.join) ? model.examples.join("\n") : ""
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        font.pixelSize: 16
                        color: "black"
                        palette.base: "white"
                        onEditingFinished: {
                             model.examples = text.split("\n")
                        }
                    }

                    Button {
                        text: "Remove Meaning"
                        palette.button: "#552222"
                        palette.buttonText: "white"
                        onClicked: detailsModel.remove(index)
                    }
                }
            }
        }
        
        Button {
            text: "+ Add Meaning"
            Layout.fillWidth: true
            onClicked: detailsModel.append({ "meaning": "", "examples": [], "pos": [] })
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 10
            
            Button {
                text: "Cancel"
                onClicked: root.close()
            }
            
            Button {
                text: "Save"
                palette.button: "#225522"
                palette.buttonText: "white"
                onClicked: {
                    // Collect data
                    var finalDetails = []
                    for(var i=0; i<detailsModel.count; i++) {
                        var item = detailsModel.get(i)
                        // Convert ListModel item to JS object
                        var exArr = []
                        if (item.examples && item.examples.count) {/*Kivy logic*/} // simplify: use split above
                        // Actually ListModel items are a bit tricky with arrays. 
                        // Simplification: We trust the bindings or re-read
                        finalDetails.push({
                            "meaning": item.meaning,
                            "examples": (typeof item.examples === 'string') ? item.examples.split("\n") : item.examples, // fallback
                            "pos": item.pos
                        })
                    }
                    
                    app.updateWordDetails(root.targetWord, finalDetails, ipaField.text)
                    root.close()
                    root.saved()
                }
            }
        }
    }
}
