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
    property bool isTongueTwister: false
    property var posTags: ["n", "v", "adj", "adv", "prep", "conj"]

    // ── imperative data: each entry = { meaningInput, exInputs[], posButtons[], row }
    property var meaningRows: []

    // ── helpers ──────────────────────────────────────────────────────────────
    function addExampleToRow(rowObj, initialText) {
        var comp = Qt.createComponent("_ExampleRow.qml")
        // Inline since we can't easily create sub-files
        var exRow = exampleRowComp.createObject(rowObj.exBox, { "initialText": initialText })
        exRow.deleteRequested.connect(function() { _removeExampleFromRow(rowObj, exRow) })
        rowObj.exInputs.push(exRow)
    }

    function _removeExampleFromRow(rowObj, exRow) {
        var idx = rowObj.exInputs.indexOf(exRow)
        if (idx >= 0) rowObj.exInputs.splice(idx, 1)
        exRow.destroy()
    }

    function addMeaningRow(meaning, examples, pos) {
        var rowObj = { meaningInput: null, exInputs: [], posButtons: [], exBox: null }
        var row = meaningRowComp.createObject(meaningsColumn, {})
        rowObj.row = row
        rowObj.exBox = row.exBoxItem
        rowObj.meaningInput = row.meaningInput
        rowObj.posButtonsContainer = row.posRowItem

        // Initialize meaning text
        row.meaningInput.text = meaning || ""

        // POS buttons
        for (var i = 0; i < posTags.length; i++) {
            var tag = posTags[i]
            var isActive = pos && pos.indexOf(tag) >= 0
            var pbtn = posButtonComp.createObject(row.posRowItem, { "tagName": tag, "active": isActive })
            rowObj.posButtons.push(pbtn)
        }

        // Delete meaning callback
        row.deleteClicked.connect(function() { _removeMeaningRow(rowObj) })
        row.addExampleClicked.connect(function() { addExampleToRow(rowObj, "") })

        rowObj.exInputs = []
        rowObj.exBox = row.exBoxItem

        // Add examples
        if (examples && examples.length > 0) {
            for (var j = 0; j < examples.length; j++) {
                var exRow = exampleRowComp.createObject(row.exBoxItem, { "initialText": examples[j] || "" })
                var _exRow = exRow; var _rowObj = rowObj
                exRow.deleteRequested.connect((function(er, ro) { return function() { _removeExampleFromRow(ro, er) } })(exRow, rowObj))
                rowObj.exInputs.push(exRow)
            }
        } else {
            var exRow0 = exampleRowComp.createObject(row.exBoxItem, { "initialText": "" })
            var _rowObj0 = rowObj
            exRow0.deleteRequested.connect((function(er, ro) { return function() { _removeExampleFromRow(ro, er) } })(exRow0, rowObj))
            rowObj.exInputs.push(exRow0)
        }

        meaningRows.push(rowObj)
    }

    function _removeMeaningRow(rowObj) {
        var idx = meaningRows.indexOf(rowObj)
        if (idx < 0) return
        if (meaningRows.length <= 1) {
            // Only one left: clear instead of delete (like Python)
            rowObj.meaningInput.text = ""
            for (var i = rowObj.exInputs.length - 1; i >= 0; i--) {
                rowObj.exInputs[i].destroy()
            }
            rowObj.exInputs = []
            var exRow = exampleRowComp.createObject(rowObj.exBox, { "initialText": "" })
            exRow.deleteRequested.connect((function(er, ro) { return function() { _removeExampleFromRow(ro, er) } })(exRow, rowObj))
            rowObj.exInputs.push(exRow)
            return
        }
        meaningRows.splice(idx, 1)
        rowObj.row.destroy()
    }

    function clearAll() {
        for (var i = 0; i < meaningRows.length; i++) {
            meaningRows[i].row.destroy()
        }
        meaningRows = []
    }

    function loadWord(word) {
        if (!word) return
        wordToEdit = word
        wordInput.text = word
        ipaField.text = app.state.wordIpa[word.toLowerCase()] || ""
        clearAll()
        var d = app.state.wordDetails[word.toLowerCase()]
        if (d && d.length > 0) {
            for (var i = 0; i < d.length; i++) {
                var exs = d[i].examples && d[i].examples.length > 0 ? d[i].examples : [""]
                addMeaningRow(d[i].meaning || "", exs, d[i].pos || [])
            }
        } else {
            addMeaningRow("", [""], [])
        }
        // Sicherheitsnetz: mindestens ein Feld immer
        if (meaningRows.length === 0) {
            addMeaningRow("", [""], [])
        }
    }

    function collectData() {
        var result = []
        for (var i = 0; i < meaningRows.length; i++) {
            var ro = meaningRows[i]
            var m = ro.meaningInput.text
            var exs = []
            for (var j = 0; j < ro.exInputs.length; j++) {
                var t = ro.exInputs[j].exText
                if (t) exs.push(t)
            }
            var pos = []
            for (var k = 0; k < ro.posButtons.length; k++) {
                if (ro.posButtons[k].active) pos.push(ro.posButtons[k].tagName)
            }
            result.push({ "meaning": m, "examples": exs, "pos": pos })
        }
        return result
    }

    onOpened: loadWord(wordToEdit)

    // ─── Component definitions ───────────────────────────────────────────────
    Component {
        id: posButtonComp
        Rectangle {
            property string tagName: ""
            property bool active: false
            width: 38; height: 24; radius: 4
            color: active ? "#3385e6" : "#333344"
            border.color: "#555566"; border.width: 1
            Text { anchors.centerIn: parent; text: tagName; color: "white"; font.pixelSize: 13 }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: active = !active
            }
        }
    }

    Component {
        id: exampleRowComp
        Item {
            property string initialText: ""
            property alias exText: exInput.text
            signal deleteRequested
            width: parent ? parent.width : 0
            height: exInput.implicitHeight + 4
            Row {
                width: parent.width
                spacing: 4
                TextArea {
                    id: exInput
                    text: initialText
                    placeholderText: "Example"
                    font.pixelSize: 17
                    width: parent.width - 52 - 8
                    wrapMode: TextArea.Wrap
                    color: "black"
                    background: Rectangle { color: "#f5f5f5"; radius: 3 }
                    implicitHeight: Math.max(32, contentHeight + topPadding + bottomPadding)
                }
                Rectangle {
                    width: 28; height: 28; radius: 4; color: "#aa3333"
                    anchors.verticalCenter: parent.verticalCenter
                    Text { anchors.centerIn: parent; text: "x"; color: "white"; font.pixelSize: 12; font.bold: true }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: deleteRequested()
                    }
                }
            }
        }
    }

    Component {
        id: meaningRowComp
        Column {
            signal deleteClicked
            signal addExampleClicked
            property alias meaningInput: meaningTextArea
            property alias exBoxItem: exBox
            property alias posRowItem: posTagsRow
            width: parent ? parent.width : 0
            spacing: 4
            Item { width: 1; height: 4 }

            // POS row
            Row {
                id: posTagsRow
                width: parent.width
                spacing: 4
                Text { text: "POS:"; color: "#c7d1e0"; font.pixelSize: 14; width: 40 }
            }

            // Meaning + x button
            Row {
                width: parent.width
                spacing: 4
                TextArea {
                    id: meaningTextArea
                    placeholderText: "Meaning"
                    font.pixelSize: 18
                    width: parent.width - 36 - 4
                    wrapMode: TextArea.Wrap
                    color: "black"
                    background: Rectangle { color: "white"; radius: 3 }
                    implicitHeight: Math.max(36, contentHeight + topPadding + bottomPadding)
                }
                Rectangle {
                    width: 32; height: 32; radius: 4; color: "#aa3333"
                    anchors.verticalCenter: parent.verticalCenter
                    Text { anchors.centerIn: parent; text: "x"; color: "white"; font.pixelSize: 14; font.bold: true }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: deleteClicked() }
                }
            }

            // Example rows container
            Column {
                id: exBox
                width: parent.width
                leftPadding: 20
                spacing: 4
            }

            // + Example button
            Rectangle {
                width: 110; height: 26; radius: 4; color: "#3385e6"
                Text { anchors.centerIn: parent; text: "+ Example"; color: "white"; font.pixelSize: 13 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: addExampleClicked() }
            }

            // Divider
            Rectangle { width: parent.width; height: 1; color: "#2a3040" }
        }
    }

    // ─── UI ─────────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        Text {
            text: wordToEdit + " – Meanings & Examples"
            color: "#f2faff"; font.pixelSize: 22; font.bold: true
            Layout.fillWidth: true
        }
        Rectangle { height: 2; Layout.fillWidth: true; color: "#3385e6" }

        // Word row
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Text { text: "Word:"; color: "#c7d1e0"; font.pixelSize: 16; Layout.preferredWidth: 50 }
            TextField {
                id: wordInput; font.pixelSize: 16; Layout.fillWidth: true
                color: "black"; background: Rectangle { color: "white"; radius: 3 }
            }
            Rectangle {
                width: 140; height: 32; radius: 4; color: "#3385e6"
                Text { anchors.centerIn: parent; text: "Rename word"; color: "white"; font.pixelSize: 14 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { app.correctWord(wordToEdit, wordInput.text); wordToEdit = wordInput.text }
                }
            }
        }

        // IPA row
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Text { text: "IPA:"; color: "#c7d1e0"; font.pixelSize: 16; Layout.preferredWidth: 50 }
            TextField {
                id: ipaField; font.pixelSize: 16; Layout.fillWidth: true
                color: "black"; background: Rectangle { color: "white"; radius: 3 }
            }
            Rectangle {
                width: 80; height: 32; radius: 4; color: "#3385e6"
                Text { anchors.centerIn: parent; text: "Listen"; color: "white"; font.pixelSize: 14 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: app.tts.speak(wordToEdit) }
            }
        }

        // Tongue-twister
        RowLayout {
            Layout.fillWidth: true; spacing: 8
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
                id: meaningsColumn
                width: scrollArea.availableWidth
                spacing: 4
            }
        }

        // Footer
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
                                addMeaningRow("", [""], [])
                            } else if (lbl === "Save") {
                                app.updateWordDetails(wordToEdit, collectData(), ipaField.text)
                                root.close()
                            } else if (lbl === "Next") {
                                app.updateWordDetails(wordToEdit, collectData(), ipaField.text)
                                app.nextLearnWord()
                                var nw = app.state.learnCurrentWord
                                if (!nw) root.close()
                                else loadWord(nw)
                            } else {
                                root.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
