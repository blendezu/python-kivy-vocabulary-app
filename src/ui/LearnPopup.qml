import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: learnPopup
    width: window.width * 0.95
    height: window.height * 0.92
    modal: true
    focus: true
    anchors.centerIn: parent

    property var learnedWordsPopup: null
    property var reviewPopup: null
    property var editPopup: null

    onOpened: {
        if (!app.state.learnCurrentWord) {
            app.nextLearnWord()
        }
    }

    background: Rectangle {
        color: window.surfaceColor
        radius: 8
        border.color: window.accentColor
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Text {
            text: "Learn (" + app.state.newSequence.length + " words)"
            color: window.textPrimary
            font.pixelSize: 24
            Layout.fillWidth: true
        }

        Rectangle {
            Layout.fillWidth: true
            height: 2
            color: window.accentColor
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text {
                text: "Order:"
                color: window.textSecondary
                font.pixelSize: 24
            }
            ComboBox {
                id: orderCombo
                model: ["Random", "Newest", "Oldest"]
                font.pixelSize: 24
                Layout.preferredWidth: 200
                currentIndex: Math.max(0, model.indexOf(app.state.learnOrderMode))
                onActivated: {
                    app.state.learnOrderMode = currentText
                    app.nextLearnWord()
                }
            }
            Item { Layout.fillWidth: true }
        }

        Item { Layout.fillHeight: true; Layout.preferredHeight: 40 }

        Text {
            text: app.state.learnCurrentWord ? app.state.learnCurrentWord : "No new words left!"
            color: app.state.learnCurrentWord ? window.textPrimary : window.textSecondary
            font.pixelSize: 64
            Layout.alignment: Qt.AlignHCenter
            // Underline hint on hover to signal clickability
            font.underline: wordHoverArea.containsMouse && app.state.learnCurrentWord

            MouseArea {
                id: wordHoverArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: app.state.learnCurrentWord ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (app.state.learnCurrentWord) {
                        editPopup.fromLearn = true
                        editPopup.wordToEdit = app.state.learnCurrentWord
                        editPopup.open()
                    }
                }
            }
        }

        Text {
            text: "<i>Click the word above to add meanings and examples.</i>"
            color: window.textMuted
            font.pixelSize: 16
            textFormat: Text.RichText
            Layout.alignment: Qt.AlignHCenter
        }

        Item { Layout.fillHeight: true; Layout.preferredHeight: 40 }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            spacing: 12

            Button {
                text: "Learned"
                Layout.fillWidth: true
                Layout.fillHeight: true
                font.pixelSize: 24
                palette.buttonText: window.textPrimary
                palette.button: window.accentStrong
                onClicked: app.markLearnWordKnown()
                enabled: app.state.learnCurrentWord !== ""
            }
            Button {
                text: "Next"
                Layout.fillWidth: true
                Layout.fillHeight: true
                font.pixelSize: 24
                palette.buttonText: window.textPrimary
                palette.button: window.accentStrong
                onClicked: app.nextLearnWord()
                enabled: app.state.learnCurrentWord !== ""
            }
            Button {
                text: "Remove"
                Layout.fillWidth: true
                Layout.fillHeight: true
                font.pixelSize: 24
                palette.buttonText: window.textPrimary
                palette.button: window.dangerColor
                onClicked: app.removeLearnWord()
                enabled: app.state.learnCurrentWord !== ""
            }
        }

        Button {
            text: "Review"
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            font.pixelSize: 24
            palette.buttonText: window.textPrimary
            palette.button: window.accentColor
            onClicked: {
                learnPopup.close()
                reviewPopup.open()
            }
        }

        Button {
            text: "Learned words"
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            font.pixelSize: 24
            palette.buttonText: window.textPrimary
            palette.button: window.surfaceAltColor
            onClicked: {
                if (learnedWordsPopup) {
                    learnedWordsPopup.open()
                } else {
                    console.warn("learnedWordsPopup not set")
                }
            }
        }

        Button {
            text: "Close"
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            font.pixelSize: 24
            palette.buttonText: window.textPrimary
            palette.button: window.surfaceAltColor
            onClicked: learnPopup.close()
        }
    }
}
