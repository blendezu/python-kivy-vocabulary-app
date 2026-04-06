import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    property bool embeddedMode: false
    readonly property bool secondTargetEnabled: selectedLangCode(targetCombo2, "") !== ""
    property int autoTranslateDelayMs: 700
    property bool isWarmingUp: false
    property bool autoTranslatePendingAfterWarmup: false

    width: window.width * 0.95
    height: window.height * 0.95
    modal: true
    focus: true
    anchors.centerIn: parent
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        color: window.surfaceColor
        radius: 8
        border.color: window.borderColor
        border.width: 1
    }

    ListModel {
        id: langModel
        ListElement { label: "English"; code: "eng_Latn" }
        ListElement { label: "Deutsch"; code: "deu_Latn" }
        ListElement { label: "Français"; code: "fra_Latn" }
        ListElement { label: "Español"; code: "spa_Latn" }
        ListElement { label: "Italiano"; code: "ita_Latn" }
        ListElement { label: "Português"; code: "por_Latn" }
        ListElement { label: "Nederlands"; code: "nld_Latn" }
        ListElement { label: "Tiếng Việt"; code: "vie_Latn" }
        ListElement { label: "日本語"; code: "jpn_Jpan" }
        ListElement { label: "한국어"; code: "kor_Hang" }
        ListElement { label: "中文（简体）"; code: "zho_Hans" }
    }

    ListModel {
        id: target2LangModel
        ListElement { label: "None"; code: "" }
        ListElement { label: "English"; code: "eng_Latn" }
        ListElement { label: "Deutsch"; code: "deu_Latn" }
        ListElement { label: "Français"; code: "fra_Latn" }
        ListElement { label: "Español"; code: "spa_Latn" }
        ListElement { label: "Italiano"; code: "ita_Latn" }
        ListElement { label: "Português"; code: "por_Latn" }
        ListElement { label: "Nederlands"; code: "nld_Latn" }
        ListElement { label: "Tiếng Việt"; code: "vie_Latn" }
        ListElement { label: "日本語"; code: "jpn_Jpan" }
        ListElement { label: "한국어"; code: "kor_Hang" }
        ListElement { label: "中文（简体）"; code: "zho_Hans" }
    }

    function selectedLangCode(cb, fallbackCode) {
        if (!cb || !cb.model || cb.currentIndex < 0 || cb.currentIndex >= cb.model.count) {
            return fallbackCode === undefined ? "eng_Latn" : fallbackCode
        }
        return cb.model.get(cb.currentIndex).code
    }

    function swapLanguages() {
        const from = sourceCombo.currentIndex
        sourceCombo.currentIndex = targetCombo.currentIndex
        targetCombo.currentIndex = from
    }

    function runTranslate() {
        if (!sourceInput.text.trim()) {
            translatedOutput.text = ""
            translatedOutput2.text = ""
            statusText.text = ""
            statusText.color = window.textMuted
            return
        }

        statusText.text = "Translating..."
        statusText.color = window.textMuted

        const res = app.translateText(
            sourceInput.text,
            selectedLangCode(sourceCombo, "eng_Latn"),
            selectedLangCode(targetCombo, "deu_Latn")
        )

        if (!res.ok) {
            translatedOutput.text = ""
            translatedOutput2.text = ""
            statusText.text = res.error || "Translation failed"
            statusText.color = "#fca5a5"
            return
        }

        translatedOutput.text = res.translated

        let warningText = res.warning ? String(res.warning) : ""
        let details = "Done"
        if (res.device) {
            details += " • device: " + res.device
        }

        if (secondTargetEnabled) {
            const res2 = app.translateText(
                sourceInput.text,
                selectedLangCode(sourceCombo, "eng_Latn"),
                selectedLangCode(targetCombo2, "")
            )

            if (res2.ok) {
                translatedOutput2.text = res2.translated
                if (res2.warning) {
                    warningText = warningText
                        ? (warningText + " | " + res2.warning)
                        : String(res2.warning)
                }
            } else {
                translatedOutput2.text = ""
                details += " • 2nd language failed"
                warningText = warningText
                    ? (warningText + " | " + (res2.error || "Second translation failed"))
                    : (res2.error || "Second translation failed")
            }
        } else {
            translatedOutput2.text = ""
        }

        if (warningText) {
            details += " • " + warningText
        }
        statusText.text = details
        statusText.color = "#93c5fd"
    }

    function requestAutoTranslate() {
        if (isWarmingUp) {
            autoTranslatePendingAfterWarmup = true
            return
        }

        if (!sourceInput.text.trim()) {
            translatedOutput.text = ""
            translatedOutput2.text = ""
            if (statusText.text !== "Loading model...") {
                statusText.text = ""
                statusText.color = window.textMuted
            }
            autoTranslateTimer.stop()
            return
        }
        autoTranslateTimer.restart()
    }

    function warmupIfNeeded() {
        if (isWarmingUp) {
            return
        }

        isWarmingUp = true
        statusText.text = "Loading model..."
        statusText.color = window.textMuted
        autoTranslateTimer.stop()
        warmupStartTimer.restart()
    }

    function finishWarmup() {
        const warmup = app.warmupTranslator()
        isWarmingUp = false

        if (warmup.ok) {
            let details = "Model ready"
            if (warmup.device) {
                details += " • device: " + warmup.device
            }
            if (warmup.warning) {
                details += " • " + warmup.warning
            }
            statusText.text = details
            statusText.color = "#93c5fd"
            if (autoTranslatePendingAfterWarmup || sourceInput.text.trim()) {
                autoTranslatePendingAfterWarmup = false
                requestAutoTranslate()
            }
        } else {
            statusText.text = warmup.error || "Translator warmup failed"
            statusText.color = "#fca5a5"
            autoTranslatePendingAfterWarmup = false
        }
    }

    onVisibleChanged: {
        if (visible) {
            warmupIfNeeded()
        }
    }

    Timer {
        id: autoTranslateTimer
        interval: root.autoTranslateDelayMs
        repeat: false
        onTriggered: runTranslate()
    }

    Timer {
        id: warmupStartTimer
        interval: 1
        repeat: false
        onTriggered: finishWarmup()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Text {
            text: "Translate"
            color: window.textPrimary
            font.pixelSize: 24
            font.bold: true
            Layout.fillWidth: true
        }

        Text {
            text: "Local model: facebook/nllb-200-distilled-600M"
            color: window.textMuted
            font.pixelSize: 13
            Layout.fillWidth: true
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: 12
            rowSpacing: 12

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 84
                Layout.minimumWidth: 240
                radius: 10
                color: "#15233b"
                border.color: "#27436b"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    Text {
                        text: "Source"
                        color: window.textMuted
                        font.pixelSize: 13
                    }

                    ComboBox {
                        id: sourceCombo
                        Layout.fillWidth: true
                        model: langModel
                        textRole: "label"
                        currentIndex: 0
                        onCurrentIndexChanged: requestAutoTranslate()
                    }
                }
            }

            Button {
                text: "⇄"
                Layout.preferredWidth: 56
                Layout.preferredHeight: 56
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                onClicked: swapLanguages()
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 84
                Layout.minimumWidth: 240
                radius: 10
                color: "#15233b"
                border.color: "#27436b"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    Text {
                        text: "Target 1"
                        color: window.textMuted
                        font.pixelSize: 13
                    }

                    ComboBox {
                        id: targetCombo
                        Layout.fillWidth: true
                        model: langModel
                        textRole: "label"
                        currentIndex: 1
                        onCurrentIndexChanged: requestAutoTranslate()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 84
                Layout.minimumWidth: 240
                radius: 10
                color: "#15233b"
                border.color: "#27436b"
                border.width: 1
                opacity: root.secondTargetEnabled ? 1.0 : 0.7

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    Text {
                        text: "Target 2"
                        color: window.textMuted
                        font.pixelSize: 13
                    }

                    ComboBox {
                        id: targetCombo2
                        Layout.fillWidth: true
                        model: target2LangModel
                        textRole: "label"
                        currentIndex: 0
                        onCurrentIndexChanged: requestAutoTranslate()
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: window.borderColor
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                Layout.minimumWidth: 240
                radius: 12
                color: "#15233b"
                border.color: "#27436b"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Text {
                        text: "Source"
                        color: window.textSecondary
                        font.pixelSize: 14
                    }

                    TextArea {
                        id: sourceInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        placeholderText: "Type text to translate..."
                        wrapMode: TextEdit.WrapAnywhere
                        onTextChanged: requestAutoTranslate()
                        color: window.textPrimary
                        selectionColor: window.accentColor
                        selectedTextColor: "#ffffff"
                        font.pixelSize: 16
                        clip: true
                        background: Rectangle {
                            radius: 10
                            color: "#0f1d34"
                            border.color: "#213a5d"
                            border.width: 1
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                Layout.minimumWidth: 240
                radius: 12
                color: "#15233b"
                border.color: "#27436b"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Text {
                        text: root.secondTargetEnabled ? "Translation 1" : "Translation"
                        color: window.textSecondary
                        font.pixelSize: 14
                    }

                    TextArea {
                        id: translatedOutput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        readOnly: true
                        wrapMode: TextEdit.WrapAnywhere
                        color: window.textPrimary
                        selectionColor: window.accentColor
                        selectedTextColor: "#ffffff"
                        font.pixelSize: 16
                        placeholderText: "Translated text appears here..."
                        clip: true
                        background: Rectangle {
                            radius: 10
                            color: "#0f1d34"
                            border.color: "#213a5d"
                            border.width: 1
                        }
                    }
                }
            }

            Rectangle {
                visible: root.secondTargetEnabled
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                Layout.minimumWidth: 240
                radius: 12
                color: "#15233b"
                border.color: "#27436b"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Text {
                        text: "Translation 2"
                        color: window.textSecondary
                        font.pixelSize: 14
                    }

                    TextArea {
                        id: translatedOutput2
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        readOnly: true
                        wrapMode: TextEdit.WrapAnywhere
                        color: window.textPrimary
                        selectionColor: window.accentColor
                        selectedTextColor: "#ffffff"
                        font.pixelSize: 16
                        placeholderText: "Second translation appears here..."
                        clip: true
                        background: Rectangle {
                            radius: 10
                            color: "#0f1d34"
                            border.color: "#213a5d"
                            border.width: 1
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            BusyIndicator {
                running: root.isWarmingUp
                visible: running
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
            }

            Text {
                id: statusText
                text: ""
                color: window.textMuted
                Layout.fillWidth: true
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            Button {
                text: "Translate"
                Layout.preferredWidth: 140
                onClicked: runTranslate()
            }

            Button {
                text: "Clear"
                Layout.preferredWidth: 100
                onClicked: {
                    sourceInput.text = ""
                    translatedOutput.text = ""
                    translatedOutput2.text = ""
                    statusText.text = ""
                }
            }

            Button {
                text: "Close"
                visible: !root.embeddedMode
                Layout.preferredWidth: 100
                onClicked: root.close()
            }
        }
    }
}
