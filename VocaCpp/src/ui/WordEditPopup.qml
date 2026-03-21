import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    width: window.width * 0.88
    height: window.height * 0.90
    modal: true
    focus: true
    anchors.centerIn: parent
    closePolicy: Popup.CloseOnEscape

    background: Rectangle {
        color: "#1a1e2a"
        radius: 8
        border.color: "#3385e6"
        border.width: 1
    }

    property string wordToEdit: ""
    property var detailsList: [{"meaning": "", "examples": [""], "pos": []}]
    property bool isTongueTwister: false
    property var posTags: ["n", "v", "adj", "adv", "prep", "conj"]

    function loadWord(word) {
        if (word === "") return
        wordToEdit = word
        var d = app.state.wordDetails[word.toLowerCase()]
        if (d && d.length > 0) {
            var temp = []
            for (var i = 0; i < d.length; i++) {
                temp.push({
                    "meaning": d[i].meaning,
                    "examples": d[i].examples.length > 0 ? d[i].examples.slice() : [""],
                    "pos": d[i].pos ? d[i].pos.slice() : []
                })
            }
            detailsList = temp
        } else {
            detailsList = [{"meaning": "", "examples": [""], "pos": []}]
        }
        // Always ensure at least one entry
        if (detailsList.length === 0) {
            detailsList = [{"meaning": "", "examples": [""], "pos": []}]
        }
        ipaField.text = app.state.wordIpa[word.toLowerCase()] || ""
        isTongueTwister = false
        wordInput.text = word
        detailsRepeater.model = 0
        detailsRepeater.model = detailsList.length
    }

    onOpened: loadWord(wordToEdit)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        // Title
        Text {
            text: wordToEdit + " – Meanings & Examples"
            color: "#f2faff"
            font.pixelSize: 22
            font.bold: true
            Layout.fillWidth: true
        }
        Rectangle { height: 2; Layout.fillWidth: true; color: "#3385e6" }

        // Word row
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Text { text: "Word:"; color: "#c7d1e0"; font.pixelSize: 16; Layout.preferredWidth: 50 }
            TextField {
                id: wordInput
                text: wordToEdit
                font.pixelSize: 16
                Layout.fillWidth: true
                color: "black"
                background: Rectangle { color: "white"; radius: 3 }
            }
            // Rename button
            Rectangle {
                width: 140; height: 32; radius: 4; color: "#3385e6"
                Text { anchors.centerIn: parent; text: "Rename word"; color: "white"; font.pixelSize: 14 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        app.correctWord(wordToEdit, wordInput.text)
                        wordToEdit = wordInput.text
                    }
                }
            }
        }

        // IPA row
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Text { text: "IPA:"; color: "#c7d1e0"; font.pixelSize: 16; Layout.preferredWidth: 50 }
            TextField {
                id: ipaField
                font.pixelSize: 16
                Layout.fillWidth: true
                color: "black"
                background: Rectangle { color: "white"; radius: 3 }
            }
            Rectangle {
                width: 80; height: 32; radius: 4; color: "#3385e6"
                Text { anchors.centerIn: parent; text: "Listen"; color: "white"; font.pixelSize: 14 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: app.tts.speak(wordToEdit) }
            }
        }

        // Tongue-twister toggle
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Rectangle {
                width: 140; height: 28; radius: 4
                color: isTongueTwister ? "#555577" : "#333344"
                border.color: isTongueTwister ? "#9988cc" : "#555566"; border.width: 1
                Text { anchors.centerIn: parent; text: "Tongue-twister"; color: isTongueTwister ? "#ccbbff" : "#8899aa"; font.pixelSize: 13 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: isTongueTwister = !isTongueTwister }
            }
            Item { Layout.fillWidth: true }
        }

        // Meanings scroll area
        ScrollView {
            id: scrollArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            Column {
                width: scrollArea.availableWidth
                spacing: 14

                Repeater {
                    id: detailsRepeater
                    model: detailsList.length

                    Column {
                        required property int index
                        property int extIndex: index
                        width: scrollArea.availableWidth
                        spacing: 4

                        // POS row
                        Row {
                            width: parent.width
                            spacing: 4
                            Text { text: "POS:"; color: "#c7d1e0"; font.pixelSize: 14; Layout.preferredWidth: 40 }
                            Repeater {
                                model: posTags
                                Rectangle {
                                    required property string modelData
                                    property bool active: detailsList[extIndex] && detailsList[extIndex].pos.indexOf(modelData) >= 0
                                    width: 38; height: 24; radius: 4
                                    color: active ? "#3385e6" : "#333344"
                                    border.color: "#555566"; border.width: 1
                                    Text { anchors.centerIn: parent; text: modelData; color: "white"; font.pixelSize: 13 }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (!detailsList[extIndex]) return
                                            var p = detailsList[extIndex].pos.slice()
                                            var i = p.indexOf(modelData)
                                            if (i >= 0) p.splice(i, 1)
                                            else p.push(modelData)
                                            detailsList[extIndex].pos = p
                                            detailsList = detailsList.slice() // force update
                                            detailsRepeater.model = 0
                                            detailsRepeater.model = detailsList.length
                                        }
                                    }
                                }
                            }
                            Item { width: parent.width - 40 * posTags.length - 4 * posTags.length; height: 1 }
                        }

                        // Meaning row
                        Row {
                            width: parent.width
                            spacing: 4
                            TextArea {
                                text: detailsList[extIndex] ? detailsList[extIndex].meaning : ""
                                placeholderText: "Meaning"
                                font.pixelSize: 18
                                width: parent.width - 36 - 4
                                wrapMode: TextArea.Wrap
                                color: "black"
                                background: Rectangle { color: "white"; radius: 3 }
                                implicitHeight: Math.max(36, contentHeight + topPadding + bottomPadding)
                                onTextEdited: { if (detailsList[extIndex]) detailsList[extIndex].meaning = text }
                            }
                            Rectangle {
                                width: 32; height: 32; radius: 4; color: "#aa3333"
                                Text { anchors.centerIn: parent; text: "x"; color: "white"; font.pixelSize: 14; font.bold: true }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var updated = JSON.parse(JSON.stringify(detailsList))
                                        updated.splice(extIndex, 1)
                                        if (updated.length === 0) updated.push({"meaning": "", "examples": [""], "pos": []})
                                        detailsList = updated
                                        detailsRepeater.model = 0
                                        detailsRepeater.model = detailsList.length
                                    }
                                }
                            }
                        }

                        // Examples
                        Column {
                            width: parent.width
                            leftPadding: 20
                            spacing: 4

                            Repeater {
                                model: detailsList[extIndex] ? detailsList[extIndex].examples.length : 0
                                Row {
                                    required property int index
                                    property int exIdx: index
                                    width: scrollArea.availableWidth - 20
                                    spacing: 4
                                    TextArea {
                                        text: detailsList[extIndex] ? (detailsList[extIndex].examples[exIdx] || "") : ""
                                        placeholderText: "Example"
                                        font.pixelSize: 17
                                        width: parent.width - 32 - 4
                                        wrapMode: TextArea.Wrap
                                        color: "black"
                                        background: Rectangle { color: "#f5f5f5"; radius: 3 }
                                        implicitHeight: Math.max(32, contentHeight + topPadding + bottomPadding)
                                        onTextEdited: { if (detailsList[extIndex] && detailsList[extIndex].examples) detailsList[extIndex].examples[exIdx] = text }
                                    }
                                    Rectangle {
                                        width: 28; height: 28; radius: 4; color: "#aa3333"
                                        Text { anchors.centerIn: parent; text: "x"; color: "white"; font.pixelSize: 12; font.bold: true }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                var updated = JSON.parse(JSON.stringify(detailsList))
                                                updated[extIndex].examples.splice(exIdx, 1)
                                                if (updated[extIndex].examples.length === 0) updated[extIndex].examples.push("")
                                                detailsList = updated
                                                detailsRepeater.model = 0
                                                detailsRepeater.model = detailsList.length
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: 110; height: 26; radius: 4; color: "#3385e6"
                                Text { anchors.centerIn: parent; text: "+ Example"; color: "white"; font.pixelSize: 13 }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var updated = JSON.parse(JSON.stringify(detailsList))
                                        updated[extIndex].examples.push("")
                                        detailsList = updated
                                        detailsRepeater.model = 0
                                        detailsRepeater.model = detailsList.length
                                    }
                                }
                            }
                        } // Column examples
                    } // Column meaning block
                } // Repeater
            } // Column (scroll content)
        } // ScrollView

        // Footer buttons
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            spacing: 8

            Repeater {
                model: [
                    {label: "+ Meaning", color: "#3385e6"},
                    {label: "Save",      color: "#40a661"},
                    {label: "Back",      color: "#7777aa"},
                    {label: "Next",      color: "#5cc27d"},
                    {label: "Close",     color: "#666677"}
                ]
                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true; height: 50; radius: 6
                    color: modelData.color
                    Text { anchors.centerIn: parent; text: modelData.label; color: "white"; font.pixelSize: 18 }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var lbl = modelData.label
                            if (lbl === "+ Meaning") {
                                detailsList.push({"meaning": "", "examples": [""], "pos": []})
                                detailsRepeater.model = 0
                                detailsRepeater.model = detailsList.length
                            } else if (lbl === "Save") {
                                app.updateWordDetails(wordToEdit, detailsList, ipaField.text)
                                root.close()
                            } else if (lbl === "Next") {
                                app.updateWordDetails(wordToEdit, detailsList, ipaField.text)
                                app.nextLearnWord()
                                var nw = app.state.learnCurrentWord
                                if (!nw) root.close()
                                else loadWord(nw)
                            } else if (lbl === "Close" || lbl === "Back") {
                                root.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
