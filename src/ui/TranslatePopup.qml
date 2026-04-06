import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    property bool embeddedMode: false
    property bool secondTargetEnabled: false

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

    function selectedLangCode(cb) {
        if (cb.currentIndex < 0 || cb.currentIndex >= langModel.count) {
            return "eng_Latn"
        }
        return langModel.get(cb.currentIndex).code
    }

    function swapLanguages() {
        const from = sourceCombo.currentIndex
        sourceCombo.currentIndex = targetCombo.currentIndex
        targetCombo.currentIndex = from
    }

    function runTranslate() {
        statusText.text = "Translating..."
        statusText.color = window.textMuted

        const res = app.translateText(
            sourceInput.text,
            selectedLangCode(sourceCombo),
            selectedLangCode(targetCombo)
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
                selectedLangCode(sourceCombo),
                selectedLangCode(targetCombo2)
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
            columns: 3
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
                        model: langModel
                        textRole: "label"
                        currentIndex: 2
                        enabled: root.secondTargetEnabled
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                text: "⇄"
                Layout.preferredWidth: 56
                onClicked: swapLanguages()
            }

            Item {
                Layout.fillWidth: true
            }

            Button {
                id: toggleSecondLanguageButton
                text: root.secondTargetEnabled ? "− Sprache" : "+ Sprache"
                Layout.preferredWidth: 110
                onClicked: {
                    root.secondTargetEnabled = !root.secondTargetEnabled
                    if (!root.secondTargetEnabled) {
                        translatedOutput2.text = ""
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
                        text: "Translation 1"
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
                        enabled: root.secondTargetEnabled
                        wrapMode: TextEdit.WrapAnywhere
                        color: root.secondTargetEnabled ? window.textPrimary : window.textMuted
                        selectionColor: window.accentColor
                        selectedTextColor: "#ffffff"
                        font.pixelSize: 16
                        placeholderText: root.secondTargetEnabled
                            ? "Second translation appears here..."
                            : "Enable '+ Sprache' to add a second target language"
                        clip: true
                        background: Rectangle {
                            radius: 10
                            color: root.secondTargetEnabled ? "#0f1d34" : "#12233f"
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
