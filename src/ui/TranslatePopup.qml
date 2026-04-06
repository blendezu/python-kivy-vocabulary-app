import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    property bool embeddedMode: false

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

        if (res.ok) {
            translatedOutput.text = res.translated
            let details = "Done"
            if (res.device) {
                details += " • device: " + res.device
            }
            if (res.warning) {
                details += " • " + res.warning
            }
            statusText.text = details
            statusText.color = "#93c5fd"
        } else {
            translatedOutput.text = ""
            statusText.text = res.error || "Translation failed"
            statusText.color = "#fca5a5"
        }
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

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ComboBox {
                id: sourceCombo
                Layout.fillWidth: true
                model: langModel
                textRole: "label"
                currentIndex: 0
            }

            Button {
                text: "⇄"
                Layout.preferredWidth: 56
                onClicked: swapLanguages()
            }

            ComboBox {
                id: targetCombo
                Layout.fillWidth: true
                model: langModel
                textRole: "label"
                currentIndex: 1
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

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
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
                    wrapMode: TextArea.Wrap
                    font.pixelSize: 16
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                Text {
                    text: "Translation"
                    color: window.textSecondary
                    font.pixelSize: 14
                }

                TextArea {
                    id: translatedOutput
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    readOnly: true
                    wrapMode: TextArea.Wrap
                    font.pixelSize: 16
                    placeholderText: "Translated text appears here..."
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
