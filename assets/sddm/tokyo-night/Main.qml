import QtQuick 2.15
import QtQuick.Controls 2.15

// ╔══════════════════════════════════════════════════════════════╗
// ║  Tokyo Night – Modern & Clean SDDM Login Screen             ║
// ║  Glassmorphism Design • Pure QtQuick 2.15 • Qt5 & Qt6        ║
// ╚══════════════════════════════════════════════════════════════╝
Rectangle {
    id: root
    width: 1920
    height: 1080
    color: bgDark

    // ── Tokyo Night Farbpalette ──────────────────────────────
    readonly property color bgDark:       "#1a1b26"
    readonly property color surface:      "#24283b"
    readonly property color surfaceAlt:   "#1f2335"
    readonly property color fg:           "#c0caf5"
    readonly property color fgMuted:      "#7982a9"
    readonly property color blue:         "#7aa2f7"
    readonly property color cyan:         "#7dcfff"
    readonly property color magenta:      "#bb9af7"
    readonly property color purple:       "#9d7cd8"
    readonly property color red:          "#f7768e"
    readonly property color yellow:       "#e0af68"
    readonly property color green:        "#9ece6a"
    readonly property color teal:         "#73daca"

    readonly property string uiFont: "JetBrainsMono Nerd Font, JetBrains Mono, Noto Sans, sans-serif"

    // ── Zustand ──────────────────────────────────────────────
    property bool   busy: false
    property bool   leaving: false
    property string errorText: ""
    property real   intro: 0.0
    readonly property string currentUser: userList.currentItem ? userList.currentItem.userName : ""

    NumberAnimation on intro {
        from: 0; to: 1; duration: 800
        easing.type: Easing.OutCubic
        running: true
    }

    // ── Hintergrundbild mit sanftem Einblenden ────────────────
    Image {
        id: backgroundImage
        anchors.fill: parent
        source: "background.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        visible: status === Image.Ready
        opacity: root.intro * 0.95
    }

    // Modernes Vignette- & Tiefen-Overlay (Ambient Glow & Fokus auf die Mitte)
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.00; color: Qt.rgba(15/255, 16/255, 24/255, 0.72) }
            GradientStop { position: 0.45; color: Qt.rgba(26/255, 27/255, 38/255, 0.55) }
            GradientStop { position: 0.80; color: Qt.rgba(22/255, 24/255, 35/255, 0.70) }
            GradientStop { position: 1.00; color: Qt.rgba(15/255, 16/255, 24/255, 0.88) }
        }
    }

    // ── Obere Leiste / Minimalistische Uhr & Datum ───────────
    Column {
        id: clock
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height * 0.12 - (1 - root.intro) * 20
        opacity: root.intro
        spacing: 6

        Text {
            id: timeLabel
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: root.uiFont
            font.pixelSize: 84
            font.weight: Font.ExtraLight
            font.letterSpacing: 2
            color: root.fg
            renderType: Text.NativeRendering

            function updateTime() {
                text = Qt.formatTime(new Date(), "HH:mm")
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: root.cyan
                anchors.verticalCenter: parent.verticalCenter
                opacity: 0.8
            }

            Text {
                id: dateLabel
                font.family: root.uiFont
                font.pixelSize: 15
                font.letterSpacing: 1.2
                color: root.cyan
                renderType: Text.NativeRendering

                function updateDate() {
                    var d = new Date()
                    var days = ["Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"]
                    var months = ["Januar", "Februar", "März", "April", "Mai", "Juni",
                                  "Juli", "August", "September", "Oktober", "November", "Dezember"]
                    text = days[d.getDay()] + ", " + d.getDate() + ". " + months[d.getMonth()]
                }
            }

            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: root.cyan
                anchors.verticalCenter: parent.verticalCenter
                opacity: 0.8
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

    // ── Zentraler Glassmorphismus-Login-Kartenbereich ─────────
    Item {
        id: loginCardWrapper
        width: 380
        height: 340
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 50 + (1 - root.intro) * 25
        opacity: root.intro

        property real shakeX: 0

        // Subtiler äußerer Weichzeichner-/Schattierungseffekt
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 16
            height: parent.height + 16
            radius: 32
            color: Qt.rgba(10/255, 12/255, 20/255, 0.45)
            z: -1
        }

        // Die gefrostete Glaskarte (Glass Card)
        Rectangle {
            id: loginCard
            anchors.fill: parent
            x: loginCardWrapper.shakeX
            radius: 26
            clip: false

            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(36/255, 40/255, 59/255, 0.72) }
                GradientStop { position: 1.0; color: Qt.rgba(22/255, 24/255, 35/255, 0.82) }
            }

            border.width: 1
            border.color: passwordField.activeFocus
                          ? Qt.rgba(122/255, 162/255, 247/255, 0.45)
                          : Qt.rgba(255/255, 255/255, 255/255, 0.12)

            Behavior on border.color { ColorAnimation { duration: 220 } }

            // Subtile Lichtkante oben
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 1
                height: 1
                radius: 26
                color: Qt.rgba(255/255, 255/255, 255/255, 0.15)
            }

            // Fallback Benutzerliste
            ListModel {
                id: fallbackUsers
                ListElement { name: "user"; realName: "Benutzer"; icon: "" }
            }

            // Benutzer-Karussell (Avatar & Benutzername)
            ListView {
                id: userList
                anchors.top: parent.top
                anchors.topMargin: 28
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 40
                height: 140
                orientation: ListView.Horizontal
                interactive: false
                clip: true
                snapMode: ListView.SnapOneItem
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: 0
                preferredHighlightEnd: width
                highlightMoveDuration: 280
                model: (typeof userModel !== "undefined") ? userModel : fallbackUsers

                delegate: Item {
                    width: userList.width
                    height: userList.height

                    property string userName: model.name
                    property string displayName: (model.realName && model.realName !== "") ? model.realName : model.name
                    property string userIcon: (typeof model.icon !== "undefined" && model.icon) ? model.icon : ""

                    // Avatar Kreis mit leuchtendem Rahmen
                    Rectangle {
                        id: avatarRing
                        width: 86
                        height: 86
                        radius: 43
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Qt.rgba(26/255, 27/255, 38/255, 0.90)
                        border.width: 2
                        border.color: passwordField.activeFocus ? root.blue : Qt.rgba(122/255, 162/255, 247/255, 0.35)

                        Behavior on border.color { ColorAnimation { duration: 200 } }

                        // Avatar-Bild
                        Image {
                            id: avatarImage
                            anchors.fill: parent
                            anchors.margins: 2
                            source: userIcon
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            visible: status === Image.Ready
                            asynchronous: true
                        }

                        // Fallback: Eleganter Benutzer-Initialbuchstabe
                        Text {
                            anchors.centerIn: parent
                            visible: !avatarImage.visible
                            text: displayName.charAt(0).toUpperCase()
                            font.family: root.uiFont
                            font.pixelSize: 34
                            font.bold: true
                            color: root.blue
                        }
                    }

                    // Benutzer-Anzeigename
                    Text {
                        anchors.top: avatarRing.bottom
                        anchors.topMargin: 12
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: displayName
                        font.family: root.uiFont
                        font.pixelSize: 19
                        font.bold: true
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

            // Benutzer wechseln Buttons (nur sichtbar bei mehreren Benutzern)
            Rectangle {
                id: prevUserBtn
                anchors.left: parent.left
                anchors.leftMargin: 16
                y: 54
                width: 32
                height: 32
                radius: 16
                visible: userList.count > 1
                color: prevArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.06)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.10)
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "\uf053"
                    font.family: root.uiFont
                    font.pixelSize: 12
                    color: prevArea.containsMouse ? root.fg : root.fgMuted
                }

                MouseArea {
                    id: prevArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: userList.decrementCurrentIndex()
                }
            }

            Rectangle {
                id: nextUserBtn
                anchors.right: parent.right
                anchors.rightMargin: 16
                y: 54
                width: 32
                height: 32
                radius: 16
                visible: userList.count > 1
                color: nextArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.06)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.10)
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "\uf054"
                    font.family: root.uiFont
                    font.pixelSize: 12
                    color: nextArea.containsMouse ? root.fg : root.fgMuted
                }

                MouseArea {
                    id: nextArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: userList.incrementCurrentIndex()
                }
            }

            // ── Modernes Passwortfeld (Pille) ──────────────────────
            Item {
                id: passwordWrap
                width: parent.width - 56
                height: 48
                anchors.horizontalCenter: parent.horizontalCenter
                y: 195

                TextField {
                    id: passwordField
                    anchors.fill: parent
                    leftPadding: 44
                    rightPadding: (submitButton.visible || capsIndicator.visible) ? 48 : 20
                    enabled: !root.busy
                    placeholderText: "Passwort..."
                    placeholderTextColor: root.fgMuted
                    echoMode: TextInput.Password
                    passwordCharacter: "\u25CF"
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: root.uiFont
                    font.pixelSize: 14
                    color: root.fg
                    selectionColor: root.blue
                    selectedTextColor: root.bgDark

                    background: Rectangle {
                        radius: 24
                        color: passwordField.activeFocus ? Qt.rgba(1, 1, 1, 0.11) : Qt.rgba(1, 1, 1, 0.06)
                        border.width: 1.5
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

                // Schloss-Symbol links
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf023"
                    font.family: root.uiFont
                    font.pixelSize: 14
                    color: root.errorText !== "" ? root.red : passwordField.activeFocus ? root.blue : root.fgMuted
                    Behavior on color { ColorAnimation { duration: 180 } }
                }

                // CapsLock-Warnung Icon
                Text {
                    id: capsIndicator
                    anchors.right: submitButton.visible ? submitButton.left : parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    visible: (typeof keyboard !== "undefined") && keyboard.capsLock
                    text: "\uf023"
                    font.family: root.uiFont
                    font.pixelSize: 13
                    color: root.yellow
                    opacity: 0.9
                }

                // Absenden-Button (mit weichem Pop-in)
                Rectangle {
                    id: submitButton
                    width: 36
                    height: 36
                    radius: 18
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    color: submitArea.containsMouse ? Qt.lighter(root.blue, 1.15) : root.blue
                    opacity: (passwordField.text.length > 0 || root.busy) ? 1.0 : 0.0
                    scale: opacity > 0 ? 1.0 : 0.6
                    visible: opacity > 0.05

                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: root.busy ? "\uf110" : "\uf061"
                        font.family: root.uiFont
                        font.pixelSize: 14
                        color: root.bgDark

                        RotationAnimator on rotation {
                            from: 0; to: 360; duration: 900
                            loops: Animation.Infinite
                            running: root.busy
                        }
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

            // ── Statuszeile: Fehler / CapsLock / Anmelden ────────
            Text {
                id: statusText
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: passwordWrap.bottom
                anchors.topMargin: 12
                width: parent.width - 60
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                font.family: root.uiFont
                font.pixelSize: 12
                renderType: Text.NativeRendering

                readonly property bool capsOn: (typeof keyboard !== "undefined") && keyboard.capsLock

                text: root.busy ? "Anmelden …"
                    : root.errorText !== "" ? root.errorText
                    : capsOn ? "Feststelltaste (Caps Lock) aktiv"
                    : ""
                color: root.busy ? root.fgMuted
                     : root.errorText !== "" ? root.red
                     : root.yellow
                opacity: text !== "" ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }

        // Shake-Animation bei falschem Passwort
        SequentialAnimation {
            id: shakeAnimation
            NumberAnimation { target: loginCardWrapper; property: "shakeX"; to: -12; duration: 50 }
            NumberAnimation { target: loginCardWrapper; property: "shakeX"; to:  12; duration: 80 }
            NumberAnimation { target: loginCardWrapper; property: "shakeX"; to:  -8; duration: 70 }
            NumberAnimation { target: loginCardWrapper; property: "shakeX"; to:   8; duration: 70 }
            NumberAnimation { target: loginCardWrapper; property: "shakeX"; to:  -4; duration: 60 }
            NumberAnimation { target: loginCardWrapper; property: "shakeX"; to:   0; duration: 60 }
        }
    }

    // ── Untere Leiste: Schwebende Glas-Kapseln (Floating Dock) ──

    // 1. Unten links: Sitzungsauswahl (Hyprland Wayland)
    ComboBox {
        id: sessionSelector
        x: 32
        y: root.height - height - 32
        width: 220
        height: 40
        opacity: root.intro
        model: (typeof sessionModel !== "undefined") ? sessionModel : []
        textRole: "name"
        currentIndex: (typeof sessionModel !== "undefined" && typeof sessionModel.lastIndex !== "undefined" && sessionModel.lastIndex >= 0)
                      ? sessionModel.lastIndex : 0
        font.family: root.uiFont
        font.pixelSize: 12
        enabled: !root.busy

        background: Rectangle {
            radius: 20
            color: sessionSelector.hovered || sessionSelector.popup.visible ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.14)
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        contentItem: Row {
            leftPadding: 16
            spacing: 10
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "\uf108"
                font.family: root.uiFont
                font.pixelSize: 13
                color: root.blue
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: sessionSelector.displayText
                font: sessionSelector.font
                color: root.fg
                elide: Text.ElideRight
            }
        }

        indicator: Text {
            x: sessionSelector.width - width - 16
            anchors.verticalCenter: sessionSelector.verticalCenter
            text: "\uf077"
            font.family: root.uiFont
            font.pixelSize: 10
            color: root.fgMuted
        }

        delegate: ItemDelegate {
            width: sessionSelector.width - 12
            height: 36
            highlighted: sessionSelector.highlightedIndex === index

            contentItem: Text {
                text: model[sessionSelector.textRole]
                font: sessionSelector.font
                color: parent.highlighted ? root.bgDark : root.fg
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                leftPadding: 10
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
                border.color: Qt.rgba(1, 1, 1, 0.15)
            }
        }
    }

    // 2. Unten mitte: Tastaturlayout-Kapsel (Klick wechselt)
    Rectangle {
        id: layoutCapsule
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height - height - 32
        height: 40
        width: layoutRow.width + 32
        radius: 20
        opacity: root.intro
        visible: (typeof keyboard !== "undefined" && keyboard.layouts && keyboard.layouts.length > 0)
        color: layoutArea.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.14)
        Behavior on color { ColorAnimation { duration: 150 } }

        Row {
            id: layoutRow
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "\uf11c"
                font.family: root.uiFont
                font.pixelSize: 13
                color: root.teal
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                font.family: root.uiFont
                font.pixelSize: 12
                font.bold: true
                color: layoutArea.containsMouse ? root.fg : root.fgMuted
                text: (typeof keyboard !== "undefined" && keyboard.layouts && keyboard.layouts.length > keyboard.currentLayout)
                      ? keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase() : "DE"
            }
        }

        MouseArea {
            id: layoutArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (typeof keyboard !== "undefined" && keyboard.layouts && keyboard.layouts.length > 1) {
                    keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
                }
            }
        }
    }

    // 3. Unten rechts: Einheitliche Power-Kapsel (Standby, Reboot, Power Off)
    Row {
        id: powerArea
        anchors.right: parent.right
        anchors.rightMargin: 32
        y: root.height - 40 - 32
        spacing: 12
        opacity: root.intro

        Text {
            id: powerHint
            anchors.verticalCenter: parent.verticalCenter
            font.family: root.uiFont
            font.pixelSize: 12
            color: root.fgMuted
            text: ""
        }

        Rectangle {
            height: 40
            width: powerRow.width + 12
            radius: 20
            color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.14)

            Row {
                id: powerRow
                anchors.centerIn: parent
                spacing: 6

                Repeater {
                    model: [
                        { glyph: "\uf186", label: "Standby",        action: "suspend",  hoverColor: root.yellow },
                        { glyph: "\uf021", label: "Neustart",       action: "reboot",   hoverColor: root.cyan },
                        { glyph: "\uf011", label: "Ausschalten",    action: "powerOff", hoverColor: root.red }
                    ]

                    delegate: Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        visible: root.canPower(modelData.action)
                        color: btnMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.glyph
                            font.family: root.uiFont
                            font.pixelSize: 13
                            color: btnMouse.containsMouse ? modelData.hoverColor : root.fg
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: btnMouse
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
        }
    }

    // ── Eleganter Fade-to-Black Übergang bei erfolgreichem Login ──
    Rectangle {
        anchors.fill: parent
        color: root.bgDark
        opacity: root.leaving ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
    }

    // ── SDDM System-Funktionen ─────────────────────────────────
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
