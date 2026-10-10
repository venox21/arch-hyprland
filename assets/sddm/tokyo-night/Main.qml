import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080

    // ── Tokyo Night Farben ───────────────────────────────────
    readonly property color bgDark:      "#1a1b26"
    readonly property color bg:          "#24283b"
    readonly property color bgLight:     "#292e42"
    readonly property color bgHl:        "#33467c"
    readonly property color fg:          "#c0caf5"
    readonly property color fgDark:      "#a9b1d6"
    readonly property color blue:        "#7aa2f7"
    readonly property color magenta:     "#bb9af7"
    readonly property color red:         "#f7768e"
    readonly property color green:       "#9ece6a"
    readonly property color teal:        "#73daca"

    // ── Hintergrund ──────────────────────────────────────────
    Image {
        id: backgroundImage
        anchors.fill: parent
        source: "background.jpg"
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
    }

    // Fallback-Hintergrund
    Rectangle {
        anchors.fill: parent
        color: bgDark
        visible: backgroundImage.status !== Image.Ready
    }

    // Dunkler Overlay
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.4
    }

    // ── Uhrzeit ──────────────────────────────────────────────
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.15
        spacing: 8

        Text {
            id: timeLabel
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 72
            font.bold: true
            color: fg
            renderType: Text.NativeRendering

            function updateTime() {
                text = Qt.formatTime(new Date(), "HH:mm")
            }
        }

        Text {
            id: dateLabel
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18
            color: fgDark
            renderType: Text.NativeRendering

            function updateDate() {
                var d = new Date()
                var days = ["Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"]
                var months = ["Januar", "Februar", "März", "April", "Mai", "Juni",
                              "Juli", "August", "September", "Oktober", "November", "Dezember"]
                text = days[d.getDay()] + ", " + d.getDate() + ". " + months[d.getMonth()] + " " + d.getFullYear()
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            timeLabel.updateTime()
            dateLabel.updateDate()
        }
        Component.onCompleted: {
            timeLabel.updateTime()
            dateLabel.updateDate()
        }
    }

    // ── Login-Box ────────────────────────────────────────────
    Rectangle {
        id: loginBox
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 60
        width: 340
        height: loginColumn.height + 60
        color: Qt.rgba(36/255, 40/255, 59/255, 0.85)
        radius: 12
        border.color: bgHl
        border.width: 1

        Column {
            id: loginColumn
            anchors.centerIn: parent
            spacing: 16
            width: parent.width - 60

            // Benutzername
            TextField {
                id: usernameField
                width: parent.width
                height: 44
                placeholderText: "Benutzername"
                text: userModel.lastUser
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                color: fg
                selectionColor: blue
                selectedTextColor: bgDark

                background: Rectangle {
                    color: bgDark
                    radius: 8
                    border.color: usernameField.activeFocus ? blue : bgHl
                    border.width: usernameField.activeFocus ? 2 : 1
                }

                Keys.onReturnPressed: passwordField.forceActiveFocus()
                Keys.onTabPressed: passwordField.forceActiveFocus()
            }

            // Passwort
            TextField {
                id: passwordField
                width: parent.width
                height: 44
                placeholderText: "Passwort"
                echoMode: TextInput.Password
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                color: fg
                selectionColor: blue
                selectedTextColor: bgDark

                background: Rectangle {
                    color: bgDark
                    radius: 8
                    border.color: passwordField.activeFocus ? blue : bgHl
                    border.width: passwordField.activeFocus ? 2 : 1
                }

                Keys.onReturnPressed: doLogin()
            }

            // Sitzungsauswahl
            ComboBox {
                id: sessionSelector
                width: parent.width
                height: 38
                model: sessionModel
                currentIndex: sessionModel.lastIndex
                textRole: "name"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12

                background: Rectangle {
                    color: bgDark
                    radius: 8
                    border.color: bgHl
                    border.width: 1
                }

                contentItem: Text {
                    text: sessionSelector.displayText
                    color: fgDark
                    font: sessionSelector.font
                    leftPadding: 12
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // Login-Button
            Button {
                id: loginButton
                width: parent.width
                height: 44
                text: "Anmelden"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                font.bold: true

                background: Rectangle {
                    color: loginButton.pressed ? Qt.darker(blue, 1.2) :
                           loginButton.hovered ? Qt.lighter(blue, 1.1) : blue
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                contentItem: Text {
                    text: loginButton.text
                    color: bgDark
                    font: loginButton.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: doLogin()
            }

            // Fehlermeldung
            Text {
                id: errorMessage
                width: parent.width
                visible: text !== ""
                color: red
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }
    }

    // ── Tastaturlayout-Anzeige ───────────────────────────────
    Text {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        text: keyboard.layouts[keyboard.currentLayout].longName
        color: fgDark
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
    }

    // ── Login-Funktion ───────────────────────────────────────
    function doLogin() {
        errorMessage.text = ""
        sddm.login(usernameField.text, passwordField.text, sessionSelector.currentIndex)
    }

    Connections {
        target: sddm
        function onLoginSucceeded() {
            errorMessage.text = ""
        }
        function onLoginFailed() {
            errorMessage.text = "Anmeldung fehlgeschlagen. Bitte prüfe Benutzername und Passwort."
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
    }

    Component.onCompleted: {
        if (usernameField.text === "") {
            usernameField.forceActiveFocus()
        } else {
            passwordField.forceActiveFocus()
        }
    }
}
