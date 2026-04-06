import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Pdf

Popup {
    id: root
    property bool embeddedMode: false
    property bool isBusy: false

    width: window.width * 0.95
    height: window.height * 0.95
    modal: !embeddedMode
    focus: !embeddedMode
    anchors.centerIn: parent
    closePolicy: embeddedMode ? Popup.NoAutoClose : (Popup.CloseOnEscape | Popup.CloseOnPressOutside)

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

    function selectedLangCode(cb, fallbackCode) {
        if (!cb || cb.currentIndex < 0 || cb.currentIndex >= langModel.count) {
            return fallbackCode
        }
        return langModel.get(cb.currentIndex).code
    }

    function cleanSelection(rawSelected) {
        return String(rawSelected || "")
            .replace(/\s+/g, " ")
            .trim()
    }

    PdfDocument {
        id: pdfDocument
    }

    function selectedLangLabel(cb, fallbackLabel) {
        if (!cb || cb.currentIndex < 0 || cb.currentIndex >= langModel.count) {
            return fallbackLabel
        }
        return langModel.get(cb.currentIndex).label
    }

    function translateSelection(rawSelected) {
        if (isBusy) {
            return
        }

        if (pdfDocument.status !== PdfDocument.Ready) {
            statusText.text = "Open a PDF first, then select a word."
            statusText.color = window.textMuted
            return
        }

        if (pdfView.currentPage < 0) {
            statusText.text = "No active page selected yet."
            statusText.color = "#fca5a5"
            return
        }

        const selectedText = cleanSelection(rawSelected)
        if (!selectedText) {
            statusText.text = "Select or double-click text in the PDF to translate."
            statusText.color = window.textMuted
            return
        }

        selectedTextValue.text = selectedText
        topTranslationValue.text = ""
        bottomTranslationValue.text = ""

        isBusy = true
        statusText.text = "Translating selection into 2 target languages..."
        statusText.color = window.textMuted

        const src = selectedLangCode(sourceCombo, "eng_Latn")
        const topTgt = selectedLangCode(topTargetCombo, "deu_Latn")
        const bottomTgt = selectedLangCode(bottomTargetCombo, "fra_Latn")

        const topRes = app.translateText(selectedText, src, topTgt)
        const bottomRes = app.translateText(selectedText, src, bottomTgt)

        if (topRes.ok) {
            topTranslationValue.text = topRes.translated
        } else {
            topTranslationValue.text = ""
        }

        if (bottomRes.ok) {
            bottomTranslationValue.text = bottomRes.translated
        } else {
            bottomTranslationValue.text = ""
        }

        let finalWarning = ""
        if (topRes.warning) {
            finalWarning = String(topRes.warning)
        }
        if (bottomRes.warning) {
            finalWarning = finalWarning ? (finalWarning + " | " + bottomRes.warning) : String(bottomRes.warning)
        }

        if (topRes.ok || bottomRes.ok) {
            let details = "Done"
            if (topRes.device || bottomRes.device) {
                details += " • device: " + (topRes.device || bottomRes.device)
            }
            if (!topRes.ok) {
                details += " • " + selectedLangLabel(topTargetCombo, "Top") + " failed"
            }
            if (!bottomRes.ok) {
                details += " • " + selectedLangLabel(bottomTargetCombo, "Bottom") + " failed"
            }
            if (finalWarning) {
                details += " • " + finalWarning
            }
            statusText.text = details
            statusText.color = "#93c5fd"
        } else {
            const err = topRes.error || bottomRes.error || "Translation failed"
            statusText.text = err
            statusText.color = "#fca5a5"
        }

        isBusy = false
    }

    function loadPdf(fileUrl) {
        if (!fileUrl) {
            return
        }

    selectedTextValue.text = ""
    topTranslationValue.text = ""
    bottomTranslationValue.text = ""

        pdfDocument.source = fileUrl
        pdfPathValue.text = fileUrl.toString()
        pagesValue.text = "0"
        statusText.text = "Loading PDF..."
        statusText.color = window.textMuted
    }

    Connections {
        target: pdfDocument
        function onStatusChanged() {
            if (pdfDocument.status === PdfDocument.Ready) {
                pagesValue.text = String(pdfDocument.pageCount)
                statusText.text = "PDF loaded • select or double-click text to translate"
                statusText.color = "#93c5fd"
            } else if (pdfDocument.status === PdfDocument.Loading) {
                statusText.text = "Loading PDF..."
                statusText.color = window.textMuted
            } else if (pdfDocument.status === PdfDocument.Error) {
                statusText.text = "PDF could not be opened"
                statusText.color = "#fca5a5"
            }
        }
    }

    FileDialog {
        id: pdfFileDialog
        title: "Open PDF file"
        nameFilters: ["PDF files (*.pdf)"]
        onAccepted: {
            if (selectedFile.toString()) {
                root.loadPdf(selectedFile)
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Text {
            text: "PDF Mode"
            color: window.textPrimary
            font.pixelSize: 24
            font.bold: true
            Layout.fillWidth: true
        }

        Text {
            text: "Native PDF reader: scroll, zoom, and select/double-click text for 2-language translation."
            color: window.textMuted
            font.pixelSize: 13
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                text: "Open PDF"
                Layout.preferredWidth: 120
                onClicked: pdfFileDialog.open()
            }

            Button {
                text: "-"
                Layout.preferredWidth: 36
                onClicked: pdfView.renderScale = Math.max(0.4, pdfView.renderScale - 0.1)
            }

            Slider {
                id: zoomSlider
                from: 0.4
                to: 4.0
                value: pdfView.renderScale
                Layout.preferredWidth: 180
                onMoved: pdfView.renderScale = value
            }

            Button {
                text: "+"
                Layout.preferredWidth: 36
                onClicked: pdfView.renderScale = Math.min(4.0, pdfView.renderScale + 0.1)
            }

            Text {
                text: Math.round(pdfView.renderScale * 100) + "%"
                color: window.textSecondary
                font.pixelSize: 12
                Layout.preferredWidth: 52
            }

            Item { Layout.fillWidth: true }

            ComboBox {
                id: sourceCombo
                Layout.preferredWidth: 180
                model: langModel
                textRole: "label"
                currentIndex: 0
                onActivated: {
                    if (selectedTextValue.text) {
                        root.translateSelection(selectedTextValue.text)
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
            spacing: 10

            Text {
                text: "File:"
                color: window.textSecondary
                font.pixelSize: 12
            }
            Text {
                id: pdfPathValue
                text: "(none)"
                color: window.textMuted
                font.pixelSize: 12
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }
            Text {
                text: "Page:"
                color: window.textSecondary
                font.pixelSize: 12
            }
            Text {
                text: pdfView.currentPage >= 0 ? (pdfView.currentPage + 1) : 0
                color: window.textMuted
                font.pixelSize: 12
            }
            Text {
                text: "/"
                color: window.textMuted
                font.pixelSize: 12
            }
            Text {
                id: pagesValue
                text: "0"
                color: window.textMuted
                font.pixelSize: 12
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 2
                radius: 12
                color: "#15233b"
                border.color: "#27436b"
                border.width: 1
                clip: true

                PdfMultiPageView {
                    id: pdfView
                    anchors.fill: parent
                    anchors.margins: 8
                    document: pdfDocument
                    renderScale: 1.0

                    onSelectedTextChanged: {
                        root.translateSelection(selectedText)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                radius: 12
                color: "#15233b"
                border.color: "#27436b"
                border.width: 1

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 10
                    clip: true

                    Column {
                        width: parent.width
                        spacing: 10

                        Text {
                            text: "Selected text"
                            color: window.textSecondary
                            font.pixelSize: 13
                            font.bold: true
                        }
                        Text {
                            id: selectedTextValue
                            text: ""
                            color: window.textPrimary
                            font.pixelSize: 16
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }

                        Rectangle { width: parent.width; height: 1; color: window.borderColor }

                        RowLayout {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: "Top language"
                                color: window.textSecondary
                                font.pixelSize: 12
                                Layout.alignment: Qt.AlignVCenter
                            }

                            ComboBox {
                                id: topTargetCombo
                                Layout.fillWidth: true
                                model: langModel
                                textRole: "label"
                                currentIndex: 1
                                onActivated: {
                                    if (selectedTextValue.text) {
                                        root.translateSelection(selectedTextValue.text)
                                    }
                                }
                            }
                        }

                        Text {
                            id: topTranslationValue
                            text: ""
                            color: window.accentSoft
                            font.pixelSize: 16
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }

                        Rectangle { width: parent.width; height: 1; color: window.borderColor }

                        RowLayout {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: "Bottom language"
                                color: window.textSecondary
                                font.pixelSize: 12
                                Layout.alignment: Qt.AlignVCenter
                            }

                            ComboBox {
                                id: bottomTargetCombo
                                Layout.fillWidth: true
                                model: langModel
                                textRole: "label"
                                currentIndex: 2
                                onActivated: {
                                    if (selectedTextValue.text) {
                                        root.translateSelection(selectedTextValue.text)
                                    }
                                }
                            }
                        }

                        Text {
                            id: bottomTranslationValue
                            text: ""
                            color: window.successColor
                            font.pixelSize: 16
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            BusyIndicator {
                running: root.isBusy
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
                text: "Close"
                visible: !root.embeddedMode
                Layout.preferredWidth: 100
                onClicked: root.close()
            }
        }
    }
}
