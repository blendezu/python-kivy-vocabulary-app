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
        color: window.surfaceColor
        radius: 8
        border.color: window.accentColor
        border.width: 1
    }

    property string wordToEdit: ""
    property bool fromLearn: false
    property bool advancedViaNext: false
    property bool isTongueTwister: false
    property var posTags: ["n", "v", "adj", "adv", "prep", "conj"]

    // ── imperative data: each entry = { meaningInput, exInputs[], posButtons[], row }
    property var meaningRows: []

    // History Managment
    property var sessionHistory: []
    property int sessionIndex: -1

    // Notification
    Rectangle {
        id: notification
        width: 200; height: 40; radius: 6
        color: window.accentStrong
        anchors.top: parent.top; anchors.topMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        z: 100 // On top
        visible: false
        Text { anchors.centerIn: parent; text: "Saved!"; color: "white"; font.pixelSize: 16; font.bold: true }

        Timer {
            id: notifyTimer
            interval: 1500
            repeat: false
            onTriggered: notification.visible = false
        }
    }

    function showSavedNotification() {
        notification.visible = true
        notifyTimer.restart()
    }

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

    function loadWord(newWord) {
        if (!newWord) return
        console.log("loadWord called for: " + newWord)
        
        wordToEdit = newWord
        wordInput.text = newWord
        
        // Explicitly clear IPA first
        ipaField.text = ""
        var fetchedIpa = app.getWordIpa(newWord)
        if (fetchedIpa) ipaField.text = fetchedIpa

        isTongueTwister = app.isTongueTwister(newWord)
        
        var d = app.getWordDetails(newWord)
        // Debug what we found
        console.log("Details found for " + newWord + ": " + JSON.stringify(d))

        var dataList = []
        if (d && d.length > 0) {
            dataList = d
        } else {
            console.log("No details found, using empty template")
            dataList = [{ meaning: "", examples: [""], pos: [] }]
        }

        // 1. DESTROY ALL existing rows to ensure clean state
        console.log("Destroying " + meaningRows.length + " existing rows")
        while (meaningRows.length > 0) {
            var r = meaningRows.pop()
            r.row.visible = false // Hide immediately
            r.row.destroy()
        }

        // 2. Create new rows based on data
        console.log("Creating " + dataList.length + " new rows for: " + newWord)
        for (var i = 0; i < dataList.length; i++) {
            var dataItem = dataList[i]
            // We create a fresh row for every item
            var m_text = dataItem.meaning || ""
            var ex_list = dataItem.examples && dataItem.examples.length > 0 ? dataItem.examples : [""]
            var pos_list = dataItem.pos || []
            
            console.log(" - Adding row: meaning='" + m_text + "'")
            addMeaningRow(m_text, ex_list, pos_list)
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

    onOpened: {
        advancedViaNext = false
        sessionHistory = [wordToEdit]
        sessionIndex = 0
        loadWord(wordToEdit)
    }

    onClosed: {
        if (fromLearn && !advancedViaNext) {
            app.nextLearnWord()
        }
        advancedViaNext = false
        fromLearn = false
    }


    // ─── Component definitions ───────────────────────────────────────────────

    // ─── Timer for loading new word ─────────────────────────────────────────
    Timer {
        id: loadTimer
        property string nextWord: ""
        interval: 10
        repeat: false
        onTriggered: {
            if (nextWord && nextWord !== "") {
                loadWord(nextWord)
            } else {
                root.close()
            }
        }
    }

    Component {
        id: posButtonComp

    // ─── UI ─────────────────────────────────────────────────────────────────
        Rectangle {
            property string tagName: ""
            property bool active: false
            width: 38; height: 24; radius: 4
            color: active ? window.accentColor : window.surfaceAltColor
            border.color: window.borderColor; border.width: 1
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
                width: 110; height: 26; radius: 4; color: window.accentColor
                Text { anchors.centerIn: parent; text: "+ Example"; color: "white"; font.pixelSize: 13 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: addExampleClicked() }
            }

            // Divider
            Rectangle { width: parent.width; height: 1; color: window.borderColor }
        }
    }

    // ─── UI ─────────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        Text {
            text: wordToEdit + " – Meanings & Examples"
            color: window.textPrimary; font.pixelSize: 22; font.bold: true
            Layout.fillWidth: true
        }
        Rectangle { height: 2; Layout.fillWidth: true; color: window.accentColor }

        // Word row
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Text { text: "Word:"; color: window.textSecondary; font.pixelSize: 16; Layout.preferredWidth: 50 }
            TextField {
                id: wordInput; font.pixelSize: 16; Layout.fillWidth: true
                color: "black"; background: Rectangle { color: "white"; radius: 3 }
            }
            Rectangle {
                width: 140; height: 32; radius: 4; color: window.accentColor
                Text { anchors.centerIn: parent; text: "Rename word"; color: "white"; font.pixelSize: 14 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { app.correctWord(wordToEdit, wordInput.text); wordToEdit = wordInput.text }
                }
            }
        }

        // IPA row
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Text { text: "IPA:"; color: window.textSecondary; font.pixelSize: 16; Layout.preferredWidth: 50 }
            TextField {
                id: ipaField; font.pixelSize: 16; Layout.fillWidth: true
                color: "black"; background: Rectangle { color: "white"; radius: 3 }
            }
            Rectangle {
                width: 80; height: 32; radius: 4; color: window.accentColor
                Text { anchors.centerIn: parent; text: "Listen"; color: "white"; font.pixelSize: 14 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: app.tts.speak(wordToEdit) }
            }
        }

        // Tongue-twister
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Rectangle {
                width: 140; height: 28; radius: 4
                color: isTongueTwister ? window.accentStrong : window.surfaceAltColor
                border.color: isTongueTwister ? window.accentSoft : window.borderColor; border.width: 1
                Text { anchors.centerIn: parent; text: "Tongue-twister"; color: isTongueTwister ? window.textPrimary : window.textMuted; font.pixelSize: 13 }
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
                    {label: "+ Meaning", color: window.accentColor},
                    {label: "Save",      color: window.accentStrong},
                    {label: "Back",      color: "#6b5aa8"},
                    {label: "Next",      color: "#7a68c5"},
                    {label: "Close",     color: window.surfaceAltColor}
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
                                app.updateWordDetails(wordToEdit, collectData(), ipaField.text, isTongueTwister)
                                showSavedNotification()

                                if (fromLearn) {
                                    app.markWordKnown(wordToEdit)
                                    // User wants to stay on the page and press Next manually
                                } else {
                                    root.close()
                                }
                            } else if (lbl === "Back") {
                                if (fromLearn && sessionIndex > 0) {
                                    sessionIndex--
                                    loadWord(sessionHistory[sessionIndex])
                                } else {
                                    root.close()
                                }
                            } else if (lbl === "Next") {
                                // Save current changes before moving on
                                app.updateWordDetails(wordToEdit, collectData(), ipaField.text, isTongueTwister)

                                if (fromLearn) {
                                    app.markWordKnown(wordToEdit) // Mark as known when moving to next

                                    if (sessionIndex < sessionHistory.length - 1) {
                                        // Go forward in history
                                        sessionIndex++
                                        loadWord(sessionHistory[sessionIndex])
                                    } else {
                                        // Load new word
                                        var nw = app.nextLearnWord()
                                        advancedViaNext = true
                                        if (nw && nw !== "") {
                                            sessionHistory.push(nw)
                                            sessionIndex++
                                            loadWord(nw)
                                        } else {
                                            root.close()
                                        }
                                    }
                                } else {
                                    root.close()
                                }
                            } else if (lbl === "Close") {
                                root.close()
                            }
                        }
                    }
                }
            }
        }
    }
}