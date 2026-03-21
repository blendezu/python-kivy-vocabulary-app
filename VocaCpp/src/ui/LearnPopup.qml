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

    onOpened: {
        if (!app.state.learnCurrentWord) {
            app.nextLearnWord()
        }
    }

    background: Rectangle {
        color: "#1e232e" // surface
        radius: 8
        border.color: "#3385e6" // top thin line color approx
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Text {
            text: "Learn (" + app.state.newSequence.length + " words)"
            color: "#f2faff"
            font.pixelSize: 24
            Layout.fillWidth: true
        }

        Rectangle {
            Layout.fillWidth: true
            height: 2
            color: "#3385e6"
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text {
                text: "Order:"
                color: "#c7d1e0"
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
            color: "#f2faff"
            font.pixelSize: 64
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: "<i>Tap the word to add meanings and examples.</i>"
            color: "#c7d1e0"
            font.pixelSize: 20
            textFormat: Text.RichText
            Layout.alignment: Qt.AlignHCenter
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (app.state.learnCurrentWord) {
                        editPopup.wordToEdit = app.state.learnCurrentWord
                        editPopup.open()
                    }
                }
            }
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
                palette.buttonText: "#f2faff"
                palette.button: "#40a661" // success (green)
                onClicked: app.markLearnWordKnown()
                enabled: app.state.learnCurrentWord !== ""
            }
            Button {
                text: "Next"
                Layout.fillWidth: true
                Layout.fillHeight: true
                font.pixelSize: 24
                palette.buttonText: "#f2faff"
                palette.button: "#5cc27d" // lighter green
                onClicked: app.nextLearnWord()
                enabled: app.state.learnCurrentWord !== ""
            }
            Button {
                text: "Remove"
                Layout.fillWidth: true
                Layout.fillHeight: true
                font.pixelSize: 24
                palette.buttonText: "#f2faff"
                palette.button: "#cc4c4c" // red
                onClicked: app.removeLearnWord()
                enabled: app.state.learnCurrentWord !== ""
            }
        }

        Button {
            text: "Review"
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            font.pixelSize: 24
            palette.buttonText: "#f2faff"
            palette.button: "#8c8ce6" // light purple/blue
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
            palette.buttonText: "#f2faff"
            palette.button: "#468c99" // teal
        }

        Button {
            text: "Close"
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            font.pixelSize: 24
            palette.buttonText: "#f2faff"
            palette.button: "#808080" // gray
            onClicked: learnPopup.close()
        }
    }
}
