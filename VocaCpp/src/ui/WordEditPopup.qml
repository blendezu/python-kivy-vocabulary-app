import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    width: window.width * 0.95
    height: window.height * 0.92
    modal: true
    focus: true
    anchors.centerIn: parent

    background: Rectangle {
        color: "#1e232e"
        radius: 8
        border.color: "#3385e6"
        border.width: 1
    }

    property string wordToEdit: ""
    property var detailsList: []
    property bool isTongueTwister: false
    
    // POS Enum roughly
    property var posTags: ["n", "v", "adj", "adv", "prep", "conj"]

    onOpened: {
        if (wordToEdit === "") return
        var d = app.state.wordDetails[wordToEdit.toLowerCase()]
        if (d) {
            var temp = []
            for (var i = 0; i < d.length; i++) {
                temp.push({
                    "meaning": d[i].meaning,
                    "examples": d[i].examples.length > 0 ? d[i].examples : [""],
                    "pos": d[i].pos || []
                })
            }
            detailsList = temp
        } else {
            detailsList = [{"meaning": "", "examples": [""], "pos": []}]
        }
        ipaField.text = app.state.wordIpa[wordToEdit.toLowerCase()] || ""
        isTongueTwister = false // TODO: bind tongue_twisters set if available
        wordInput.text = wordToEdit
        
        // Refresh Repeater
        detailsRepeater.model = 0
        detailsRepeater.model = detailsList.length
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Text {
            text: wordToEdit + " - Meanings & Examples"
            color: "#f2faff"
            font.pixelSize: 24
            Layout.fillWidth: true
        }
        
        // --- Rename Row ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text { text: "Word:"; color: "#c7d1e0"; font.pixelSize: 18; Layout.preferredWidth: 70 }
            TextField {
                id: wordInput
                text: wordToEdit
                font.pixelSize: 18
                Layout.fillWidth: true
            }
            Button {
                text: "Rename word"
                font.pixelSize: 18
                palette.buttonText: "#f2faff"
                palette.button: "#3385e6"
                Layout.preferredWidth: 200
                onClicked: {
                    // C++ rename logic not yet implemented in AppController but user requested UI focus
                    // app.renameWord(wordToEdit, wordInput.text)
                    wordToEdit = wordInput.text
                }
            }
        }

        // --- IPA Row ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text { text: "IPA:"; color: "#c7d1e0"; font.pixelSize: 18; Layout.preferredWidth: 70 }
            TextField {
                id: ipaField
                font.pixelSize: 18
                Layout.fillWidth: true
            }
            Button {
                text: "Listen"
                font.pixelSize: 18
                palette.buttonText: "#f2faff"
                palette.button: "#3385e6"
                Layout.preferredWidth: 200
                onClicked: app.tts.speak(wordToEdit)
            }
        }

        // --- Flags Row ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Button {
                text: "Tongue-twister"
                font.pixelSize: 18
                checkable: true
                checked: isTongueTwister
                onClicked: isTongueTwister = checked
                Layout.preferredWidth: 220
            }
        }

        // --- Meanings List ---
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 16

                Repeater {
                    id: detailsRepeater
                    model: detailsList.length

                    Rectangle {
                        color: "transparent"
                        Layout.fillWidth: true
                        implicitHeight: colLayout.implicitHeight
                        
                        required property int index
                        property int extIndex: index

                        ColumnLayout {
                            id: colLayout
                            anchors.left: parent.left
                            anchors.right: parent.right
                            spacing: 8

                            // POS Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                Text { text: "POS:"; color: "#c7d1e0"; font.pixelSize: 18; Layout.preferredWidth: 50 }
                                
                                Repeater {
                                    model: posTags
                                    Button {
                                        text: modelData
                                        font.pixelSize: 18
                                        checkable: true
                                        checked: detailsList[extIndex].pos.indexOf(modelData) >= 0
                                        palette.button: checked ? "#8c52bf" : "#404040"
                                        palette.buttonText: "white"
                                        onClicked: {
                                            var p = detailsList[extIndex].pos
                                            var i = p.indexOf(modelData)
                                            if (i >= 0 && !checked) p.splice(i, 1)
                                            else if (i < 0 && checked) p.push(modelData)
                                        }
                                    }
                                }
                            }

                            // Meaning Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                TextField {
                                    text: detailsList[extIndex].meaning
                                    placeholderText: "Meaning"
                                    font.pixelSize: 18
                                    Layout.fillWidth: true
                                    onTextChanged: detailsList[extIndex].meaning = text
                                }
                                Button {
                                    text: "x"
                                    font.pixelSize: 18
                                    Layout.preferredWidth: 42
                                    palette.button: "#cc4c4c"
                                    palette.buttonText: "white"
                                    onClicked: {
                                        detailsList.splice(extIndex, 1)
                                        detailsRepeater.model = 0
                                        detailsRepeater.model = detailsList.length
                                    }
                                }
                            }

                            // Examples Box
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: 24
                                spacing: 6

                                Repeater {
                                    id: examplesRepeater
                                    model: detailsList[extIndex].examples.length

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6
                                        TextField {
                                            text: detailsList[extIndex].examples[model.index]
                                            placeholderText: "Example"
                                            font.pixelSize: 16
                                            Layout.fillWidth: true
                                            onTextChanged: detailsList[extIndex].examples[model.index] = text
                                        }
                                        Button {
                                            text: "x"
                                            font.pixelSize: 18
                                            Layout.preferredWidth: 42
                                            palette.button: "#cc4c4c"
                                            palette.buttonText: "white"
                                            onClicked: {
                                                detailsList[extIndex].examples.splice(model.index, 1)
                                                examplesRepeater.model = 0
                                                examplesRepeater.model = detailsList[extIndex].examples.length
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Button {
                                        text: "+ Example"
                                        font.pixelSize: 18
                                        palette.buttonText: "white"
                                        palette.button: "#3385e6"
                                        Layout.preferredWidth: 200
                                        onClicked: {
                                            detailsList[extIndex].examples.push("")
                                            examplesRepeater.model = 0
                                            examplesRepeater.model = detailsList[extIndex].examples.length
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- Footer Buttons ---
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            spacing: 8

            Button {
                text: "+ Meaning"
                font.pixelSize: 20
                palette.buttonText: "white"
                palette.button: "#3385e6"
                Layout.fillWidth: true; Layout.fillHeight: true
                onClicked: {
                    detailsList.push({"meaning": "", "examples": [""], "pos": []})
                    detailsRepeater.model = 0
                    detailsRepeater.model = detailsList.length
                }
            }
            Button {
                text: "Save"
                font.pixelSize: 20
                palette.buttonText: "white"
                palette.button: "#40a661"
                Layout.fillWidth: true; Layout.fillHeight: true
                onClicked: {
                    app.updateWordDetails(wordToEdit, detailsList, ipaField.text)
                    // TODO string-based tongue twister sets, but skipping for now
                    root.close()
                }
            }
            Button {
                text: "Back"
                font.pixelSize: 20
                palette.buttonText: "white"
                palette.button: "#808080"
                Layout.fillWidth: true; Layout.fillHeight: true
                // TODO: Learn mode Next/Back logic
            }
            Button {
                text: "Next"
                font.pixelSize: 20
                palette.buttonText: "white"
                palette.button: "#5cc27d"
                Layout.fillWidth: true; Layout.fillHeight: true
                onClicked: {
                    app.updateWordDetails(wordToEdit, detailsList, ipaField.text)
                    app.nextLearnWord()
                    wordToEdit = app.state.learnCurrentWord
                    if (!wordToEdit) root.close()
                    else {
                        // re-trigger onOpened manually
                        var d = app.state.wordDetails[wordToEdit.toLowerCase()]
                        if (d) {
                            var temp = []
                            for (var i = 0; i < d.length; i++) temp.push({"meaning": d[i].meaning, "examples": d[i].examples.length > 0 ? d[i].examples : [""], "pos": d[i].pos || []})
                            detailsList = temp
                        } else {
                            detailsList = [{"meaning": "", "examples": [""], "pos": []}]
                        }
                        ipaField.text = app.state.wordIpa[wordToEdit.toLowerCase()] || ""
                        wordInput.text = wordToEdit
                        detailsRepeater.model = 0
                        detailsRepeater.model = detailsList.length
                    }
                }
            }
            Button {
                text: "Close"
                font.pixelSize: 20
                palette.buttonText: "white"
                palette.button: "#808080"
                Layout.fillWidth: true; Layout.fillHeight: true
                onClicked: root.close()
            }
        }
    }
}
