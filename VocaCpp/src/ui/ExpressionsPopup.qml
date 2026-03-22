import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    // injected from Main.qml
    property var editPopupRef: null
    width: window.width * 0.8
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

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Expressions & Phrases"; color: "#f2faff"; font.pixelSize: 20 }
            Item { Layout.fillWidth: true }
            Button {
                text: "Add"
                onClicked: addExprPopup.open()
            }
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: ListModel { id: exprModel }
            delegate: ItemDelegate {
                width: listView.width; height: 44
                text: model.word
                onClicked: {
                    if (editPopupRef) {
                        editPopupRef.wordToEdit = model.word
                        editPopupRef.open()
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Button { text: "Close"; onClicked: root.close() }
        }
    }

    onOpened: {
        exprModel.clear()
        var arr = app.getExpressions()
        for (var i = 0; i < arr.length; i++) exprModel.append({"word": arr[i]})
    }

    // Inline small Add popup
    Popup {
        id: addExprPopup
        width: root.width * 0.6; height: root.height * 0.5
        modal: true; focus: true; anchors.centerIn: parent
        background: Rectangle { color: "#222"; radius: 8 }
        ColumnLayout { anchors.fill: parent; anchors.margins: 12; spacing: 8
            Text { text: "New expression"; color: "#f2faff" }
            TextField { id: phraseField; placeholderText: "Expression / phrase" }
            TextArea { id: meaningArea; placeholderText: "Meaning (optional)"; Layout.fillHeight: true }
            TextField { id: exampleField; placeholderText: "Example (optional)" }
            RowLayout { Layout.fillWidth: true; spacing: 8
                Button { text: "Cancel"; onClicked: addExprPopup.close() }
                Button {
                    text: "Add"
                    onClicked: {
                        var phrase = phraseField.text.trim()
                        if (!phrase) return
                        var details = []
                        var entry = {"meaning": meaningArea.text.trim(), "examples": [] , "pos": []}
                        if (exampleField.text.trim()) entry.examples.push(exampleField.text.trim())
                        details.push(entry)
                        app.addExpression(phrase, details)
                        addExprPopup.close()
                        // refresh
                        exprModel.clear()
                        var arr = app.getExpressions()
                        for (var i = 0; i < arr.length; i++) exprModel.append({"word": arr[i]})
                    }
                }
            }
        }
    }
}
