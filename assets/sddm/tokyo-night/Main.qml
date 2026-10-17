import QtQuick 2.15
import QtQuick.Controls 2.15

// ╔══════════════════════════════════════════════════════════════╗
// ║  Tokyo Night – SDDM Login (clean & modern)                  ║
// ║  Keine Zusatzmodule nötig (Qt5 & Qt6 kompatibel)            ║
// ╚══════════════════════════════════════════════════════════════╝
Rectangle {
    id: root
    width: 1920
    height: 1080
    color: bgDark

    // ── Tokyo Night Farben ───────────────────────────────────
    readonly property color bgDark:  "#1a1b26"
    readonly property color surface: "#24283b"
    readonly property color fg:      "#c0caf5"
    readonly property color fgMuted: "#7982a9"
    readonly property color blue:    "#7aa2f7"
    readonly property color magenta: "#bb9af7"
    readonly property color red:     "#f7768e"
    readonly property color yellow:  "#e0af68"
    readonly property color teal:    "#73daca"

    readonly property string uiFont: "JetBrainsMono Nerd Font"

    // ── Zustand ──────────────────────────────────────────────
    property bool   busy: false
    property bool   leaving: false
    property string errorText: ""
    property real   intro: 0.0
    readonly property string currentUser: userList.currentItem ? userList.currentItem.userName : ""

    NumberAnimation on intro {
        from: 0; to: 1; duration: 700
        easing.type: Easing.OutCubic
        running: true
    }

    // ── Hintergrund ──────────────────────────────────────────
    Image {
        id: backgroundImage
        anchors.fill: parent
        source: "background.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        visible: status === Image.Ready
        opacity: root.intro
    }

    // Abdunklung: oben leicht, unten kräftig (Fokus auf die Mitte)
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(26/255, 27/255, 38/255, 0.45) }
            GradientStop { position: 0.5; color: Qt.rgba(26/255, 27/255, 38/255, 0.62) }
            GradientStop { position: 1.0; color: Qt.rgba(26/255, 27/255, 38/255, 0.88) }
        }
    }

    // ── Uhr & Datum ──────────────────────────────────────────
    Column {
        id: clock
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height * 0.10 - (1 - root.intro) * 16
        opacity: root.intro
        spacing: 4

        Text {
            id: timeLabel
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: root.uiFont
            font.pixelSize: 112
            font.weight: Font.Light
            color: root.fg
            renderType: Text.NativeRendering

            function updateTime() {
                text = Qt.formatTime(new Date(), "HH:mm")
            }
        }

        Text {
            id: dateLabel
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: root.uiFont
            font.pixelSize: 18
            font.letterSpacing: 1
            color: root.fgMuted
            renderType: Text.NativeRendering

            function updateDate() {
                var d = new Date()
                var days = ["Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"]
                var months = ["Januar", "Februar", "März", "April", "Mai", "Juni",
                              "Juli", "August", "September", "Oktober", "November", "Dezember"]
                text = days[d.getDay()] + ", " + d.getDate() + ". " + months[d.getMonth()]
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            timeLabel.updateTime()
            dateLabel.updateDate()
        }
    }

    // ── Login-Bereich ────────────────────────────────────────
    Item {
        id: loginArea
        width: 320
        height: 270
        x: (root.width - width) / 2
        y: root.height * 0.40 + (1 - root.intro) * 24
        opacity: root.intro

        property real shakeX: 0

        // Fallback-Modell (z. B. Vorschau ohne SDDM)
        ListModel {
            id: fallbackUsers
            ListElement { name: "user"; realName: "Benutzer" }
        }

        // Benutzer-Karussell (Avatar + Name)
        ListView {
            id: userList
            width: parent.width
            height: 140
            orientation: ListView.Horizontal
            interactive: false
            clip: true
            snapMode: ListView.SnapOneItem
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: 0
            preferredHighlightEnd: width
            highlightMoveDuration: 320
            model: (typeof userModel !== "undefined") ? userModel : fallbackUsers

            delegate: Item {
                width: userList.width
                height: userList.height

                property string userName: model.name
                property string displayName: (model.realName && model.realName !== "") ? model.realName : model.name

                Rectangle {
                    id: avatar
                    width: 92
                    height: 92
                    radius: 46
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: root.surface
                    border.width: 2
                    border.color: passwordField.activeFocus ? root.blue : Qt.rgba(1, 1, 1, 0.18)

                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    Text {
                        anchors.centerIn: parent
                        text: displayName.charAt(0).toUpperCase()
                        font.family: root.uiFont
                        font.pixelSize: 38
                        font.bold: true
                        color: root.blue
                    }
                }

                Text {
                    anchors.top: avatar.bottom
                    anchors.topMargin: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: displayName
                    font.family: root.uiFont
                    font.pixelSize: 20
                    color: root.fg
                    renderType: Text.NativeRendering
                }
            }

            Component.onCompleted: {
                if (typeof userModel !== "undefined" && userModel.lastIndex >= 0) {
                    currentIndex = userModel.lastIndex
                }
            }
        }

        // Benutzer wechseln (nur bei mehreren Benutzern)
        Text {
            x: -44
            y: 32
            visible: userList.count > 1
            text: "\uf053"
            font.family: root.uiFont
            font.pixelSize: 18
            color: leftArea.containsMouse ? root.fg : root.fgMuted
            Behavior on color { ColorAnimation { duration: 150 } }
            MouseArea {
                id: leftArea
                anchors.fill: parent
                anchors.margins: -12
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: userList.decrementCurrentIndex()
            }
        }
        Text {
            x: parent.width + 28
            y: 32
            visible: userList.count > 1
            text: "\uf054"
            font.family: root.uiFont
            font.pixelSize: 18
            color: rightArea.containsMouse ? root.fg : root.fgMuted
            Behavior on color { ColorAnimation { duration: 150 } }
            MouseArea {
                id: rightArea
                anchors.fill: parent
                anchors.margins: -12
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: userList.incrementCurrentIndex()
            }
        }

        // Passwortfeld (Pille)
        Item {
            id: passwordWrap
            width: parent.width
            height: 52
            x: loginArea.shakeX
            y: 176

            TextField {
                id: passwordField
                anchors.fill: parent
                leftPadding: 48
                rightPadding: 56
                enabled: !root.busy
                placeholderText: "Passwort"
                placeholderTextColor: root.fgMuted
                echoMode: TextInput.Password
                passwordCharacter: "\u25CF"
                verticalAlignment: TextInput.AlignVCenter
                font.family: root.uiFont
                font.pixelSize: 15
                color: root.fg
                selectionColor: root.blue
                selectedTextColor: root.bgDark

                background: Rectangle {
                    radius: height / 2
                    color: passwordField.activeFocus ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.07)
                    border.width: 1
                    border.color: root.errorText !== "" ? root.red
                                : passwordField.activeFocus ? root.blue
                                : Qt.rgba(1, 1, 1, 0.14)

                    Behavior on color { ColorAnimation { duration: 180 } }
                    Behavior on border.color { ColorAnimation { duration: 180 } }
                }

                onTextChanged: if (text !== "") root.errorText = ""

                Keys.onReturnPressed: root.doLogin()
                Keys.onEnterPressed: root.doLogin()
                Keys.onEscapePressed: text = ""
            }

            // Schloss-Symbol
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: "\uf023"
                font.family: root.uiFont
                font.pixelSize: 15
                color: root.errorText !== "" ? root.red : root.fgMuted
                Behavior on color { ColorAnimation { duration: 180 } }
            }

            // Absenden-Button
            Rectangle {
                id: submitButton
                width: 38
                height: 38
                radius: 19
                anchors.right: parent.right
                anchors.rightMargin: 7
                anchors.verticalCenter: parent.verticalCenter
                color: submitArea.containsMouse ? Qt.lighter(root.blue, 1.15) : root.blue
                opacity: (passwordField.text.length > 0 || root.busy) ? 1.0 : 0.0
                scale: opacity > 0 ? 1.0 : 0.6

                Behavior on opacity { NumberAnimation { duration: 180 } }
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    id: submitGlyph
                    anchors.centerIn: parent
                    text: root.busy ? "\uf110" : "\uf061"
                    font.family: root.uiFont
                    font.pixelSize: 15
                    color: root.bgDark

                    RotationAnimator on rotation {
                        from: 0; to: 360; duration: 900
                        loops: Animation.Infinite
                        running: root.busy
                    }
                    onTextChanged: if (!root.busy) rotation = 0
                }

                MouseArea {
                    id: submitArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.doLogin()
                }
            }
        }

        // Status: Fehler / Caps Lock
        Text {
            id: statusText
            anchors.horizontalCenter: parent.horizontalCenter
            y: 176 + 52 + 16
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.family: root.uiFont
            font.pixelSize: 12
            renderType: Text.NativeRendering

            readonly property bool capsOn: (typeof keyboard !== "undefined") && keyboard.capsLock

            text: root.busy ? "Anmelden …"
                : root.errorText !== "" ? root.errorText
                : capsOn ? "\uf023  Feststelltaste ist aktiv"
                : ""
            color: root.busy ? root.fgMuted
                 : root.errorText !== "" ? root.red
                 : root.yellow
            opacity: text !== "" ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        // Shake bei falschem Passwort
        SequentialAnimation {
            id: shakeAnimation
            NumberAnimation { target: loginArea; property: "shakeX"; to: -14; duration: 50 }
            NumberAnimation { target: loginArea; property: "shakeX"; to:  14; duration: 80 }
            NumberAnimation { target: loginArea; property: "shakeX"; to: -10; duration: 70 }
            NumberAnimation { target: loginArea; property: "shakeX"; to:  10; duration: 70 }
            NumberAnimation { target: loginArea; property: "shakeX"; to:  -5; duration: 60 }
            NumberAnimation { target: loginArea; property: "shakeX"; to:   0; duration: 60 }
        }
    }

    // ── Unten links: Sitzungsauswahl ─────────────────────────
    ComboBox {
        id: sessionSelector
        x: 32
        y: root.height - height - 32
        width: 230
        height: 38
        opacity: root.intro
        model: (typeof sessionModel !== "undefined") ? sessionModel : []
        textRole: "name"
        currentIndex: (typeof sessionModel !== "undefined" && typeof sessionModel.lastIndex !== "undefined" && sessionModel.lastIndex >= 0)
                      ? sessionModel.lastIndex : 0
        font.family: root.uiFont
        font.pixelSize: 12
        enabled: !root.busy

        background: Rectangle {
            radius: height / 2
            color: sessionSelector.hovered || sessionSelector.popup.visible ? Qt.rgba(1, 1, 1, 0.13) : Qt.rgba(1, 1, 1, 0.07)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.12)
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        contentItem: Text {
            leftPadding: 18
            rightPadding: 34
            text: sessionSelector.displayText
            font: sessionSelector.font
            color: root.fg
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        indicator: Text {
            x: sessionSelector.width - width - 16
            y: (sessionSelector.height - height) / 2
            text: "\uf077"
            font.family: root.uiFont
            font.pixelSize: 10
            color: root.fgMuted
        }

        delegate: ItemDelegate {
            width: sessionSelector.width - 12
            height: 34
            highlighted: sessionSelector.highlightedIndex === index

            contentItem: Text {
                text: model[sessionSelector.textRole]
                font: sessionSelector.font
                color: parent.highlighted ? root.bgDark : root.fg
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                leftPadding: 6
            }
            background: Rectangle {
                radius: 12
                color: parent.highlighted ? root.blue : "transparent"
            }
        }

        popup: Popup {
            y: -height - 8
            width: sessionSelector.width
            implicitHeight: contentItem.implicitHeight + 12
            padding: 6

            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: sessionSelector.popup.visible ? sessionSelector.delegateModel : null
                currentIndex: sessionSelector.highlightedIndex
            }

            background: Rectangle {
                radius: 18
                color: Qt.rgba(26/255, 27/255, 38/255, 0.96)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.14)
            }
        }
    }

    // ── Unten mitte: Tastaturlayout (Klick wechselt) ─────────
    Text {
        id: layoutLabel
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height - height - 40
        opacity: root.intro
        visible: text !== ""
        font.family: root.uiFont
        font.pixelSize: 12
        color: layoutArea.containsMouse ? root.fg : root.fgMuted
        text: (typeof keyboard !== "undefined" && keyboard.layouts && keyboard.layouts.length > keyboard.currentLayout)
              ? "\uf11c  " + keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase() : ""
        Behavior on color { ColorAnimation { duration: 150 } }

        MouseArea {
            id: layoutArea
            anchors.fill: parent
            anchors.margins: -10
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (typeof keyboard !== "undefined" && keyboard.layouts && keyboard.layouts.length > 1) {
                    keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
                }
            }
        }
    }

    // ── Unten rechts: Power-Buttons ──────────────────────────
    Row {
        id: powerRow
        anchors.right: parent.right
        anchors.rightMargin: 32
        y: root.height - 38 - 32
        spacing: 10
        opacity: root.intro

        Text {
            id: powerHint
            anchors.verticalCenter: parent.verticalCenter
            font.family: root.uiFont
            font.pixelSize: 12
            color: root.fgMuted
            rightPadding: 6
            text: ""
        }

        Repeater {
            model: [
                { glyph: "\uf186", label: "Standby",         action: "suspend"  },
                { glyph: "\uf021", label: "Neustart",        action: "reboot"   },
                { glyph: "\uf011", label: "Herunterfahren",  action: "powerOff" }
            ]

            delegate: Rectangle {
                width: 38
                height: 38
                radius: 19
                visible: root.canPower(modelData.action)
                color: powerArea.containsMouse
                       ? (modelData.action === "powerOff" ? root.red : Qt.rgba(1, 1, 1, 0.16))
                       : Qt.rgba(1, 1, 1, 0.07)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.12)
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: modelData.glyph
                    font.family: root.uiFont
                    font.pixelSize: 14
                    color: (powerArea.containsMouse && modelData.action === "powerOff") ? root.bgDark : root.fg
                }

                MouseArea {
                    id: powerArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: powerHint.text = modelData.label
                    onExited: powerHint.text = ""
                    onClicked: root.runPower(modelData.action)
                }
            }
        }
    }

    // ── Übergang nach erfolgreichem Login ────────────────────
    Rectangle {
        anchors.fill: parent
        color: root.bgDark
        opacity: root.leaving ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
    }

    // ── Logik ────────────────────────────────────────────────
    function canPower(action) {
        if (typeof sddm === "undefined") return true
        if (action === "suspend")  return sddm.canSuspend
        if (action === "reboot")   return sddm.canReboot
        if (action === "powerOff") return sddm.canPowerOff
        return false
    }

    function runPower(action) {
        if (typeof sddm === "undefined") return
        if (action === "suspend")  sddm.suspend()
        if (action === "reboot")   sddm.reboot()
        if (action === "powerOff") sddm.powerOff()
    }

    function doLogin() {
        if (root.busy || passwordField.text === "" || root.currentUser === "") return
        root.errorText = ""
        root.busy = true
        if (typeof sddm !== "undefined") {
            sddm.login(root.currentUser, passwordField.text, sessionSelector.currentIndex)
        } else {
            root.busy = false
        }
    }

    Connections {
        target: (typeof sddm !== "undefined") ? sddm : null

        function onLoginSucceeded() {
            root.errorText = ""
            root.leaving = true
        }

        function onLoginFailed() {
            root.busy = false
            root.errorText = "Falsches Passwort – bitte erneut versuchen"
            passwordField.text = ""
            passwordField.forceActiveFocus()
            shakeAnimation.restart()
        }
    }

    Component.onCompleted: passwordField.forceActiveFocus()
}
