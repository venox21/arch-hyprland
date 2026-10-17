import QtQuick 2.15
import QtQuick.Controls 2.15

// ╔══════════════════════════════════════════════════════════════╗
// ║  Tokyo Night – Modern Neon Cyber Glass SDDM Login Screen     ║
// ║  Cyan-Magenta Gradient Glass Card • Pure QtQuick 2.15        ║
// ╚══════════════════════════════════════════════════════════════╝
Rectangle {
    id: root
    width: 1920
    height: 1080
    color: bgDark

    // ── Farbpalette ──────────────────────────────────────────
    readonly property color bgDark:       "#13141f"
    readonly property color cardBg:       Qt.rgba(18/255, 22/255, 34/255, 0.72)
    readonly property color fg:           "#ffffff"
    readonly property color fgMuted:      "#7982a9"
    readonly property color fgSubtle:     "#9aa5ce"
    readonly property color neonCyan:     "#00f0ff"
    readonly property color neonBlue:     "#38bdf8"
    readonly property color neonMagenta:  "#d946ef"
    readonly property color neonPurple:   "#c084fc"
    readonly property color red:          "#f7768e"
    readonly property color yellow:       "#e0af68"
    readonly property color green:        "#9ece6a"

    readonly property string uiFont: "JetBrainsMono Nerd Font, JetBrains Mono, Noto Sans, sans-serif"

    // ── Zustand ──────────────────────────────────────────────
    property bool   busy: false
    property bool   leaving: false
    property string errorText: ""
    property real   intro: 0.0
    property string currentUserName: (typeof userModel !== "undefined" && userModel.lastIndex >= 0 && userModel.lastIndex < userModel.count)
                                     ? userModel.lastUser : "fabian"

    NumberAnimation on intro {
        from: 0; to: 1; duration: 750
        easing.type: Easing.OutCubic
        running: true
    }

    // ── Hintergrundbild ──────────────────────────────────────
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

    // Dunkles Vignette- & Cyber-Overlay
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.00; color: Qt.rgba(10/255, 12/255, 20/255, 0.75) }
            GradientStop { position: 0.50; color: Qt.rgba(18/255, 20/255, 32/255, 0.55) }
            GradientStop { position: 1.00; color: Qt.rgba(10/255, 12/255, 20/255, 0.85) }
        }
    }

    // ══════════════════════════════════════════════════════════
    //  ZENTRALE GLAS-KARTE (NEON CYAN-MAGENTA GRADIENT BORDER)
    // ══════════════════════════════════════════════════════════
    Item {
        id: cardWrapper
        width: 400
        height: 560
        anchors.centerIn: parent
        anchors.verticalCenterOffset: (1 - root.intro) * 20
        opacity: root.intro

        property real shakeX: 0

        // Äußerer Neon-Schein (Soft Ambient Glow)
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 16
            height: parent.height + 16
            radius: 34
            color: "transparent"
            border.width: 8
            border.color: Qt.rgba(0/255, 240/255, 255/255, 0.08)
            z: -2
        }

        // Subtiler Tiefenschatten
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 6
            height: parent.height + 6
            radius: 30
            color: Qt.rgba(0, 0, 0, 0.45)
            z: -1
        }

        // Farbverlaufs-Rahmen (Cyan nach Magenta)
        Rectangle {
            id: gradientBorder
            width: parent.width
            height: parent.height
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: cardWrapper.shakeX
            anchors.verticalCenter: parent.verticalCenter
            radius: 28

            gradient: Gradient {
                GradientStop { position: 0.00; color: root.neonCyan }
                GradientStop { position: 0.45; color: root.neonBlue }
                GradientStop { position: 0.75; color: root.neonPurple }
                GradientStop { position: 1.00; color: root.neonMagenta }
            }

            // Innenkarte (Dunkles gefrostetes Glas)
            Rectangle {
                id: innerCard
                anchors.fill: parent
                anchors.margins: 1.6
                radius: 26
                color: root.cardBg
                clip: false

                // Subtile Lichtkante oben
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 1
                    height: 1
                    radius: 26
                    color: Qt.rgba(255, 255, 255, 0.20)
                }

                // ── 1. Leuchtendes Arch Linux Neon Logo ───────────────
                Item {
                    id: logoWrap
                    width: 86
                    height: 86
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 26

                    Image {
                        id: archLogoImg
                        anchors.fill: parent
                        source: "arch_logo.svg"
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                        visible: status === Image.Ready
                    }

                    // Fallback Nerd Font Glyph (falls SVG nicht geladen wird)
                    Text {
                        anchors.centerIn: parent
                        visible: !archLogoImg.visible
                        text: "\uf303"
                        font.family: root.uiFont
                        font.pixelSize: 68
                        color: root.neonCyan
                        style: Text.Outline
                        styleColor: Qt.rgba(0/255, 240/255, 255/255, 0.4)
                    }
                }

                // ── 2. "WELCOME BACK" Überschrift ────────────────────
                Text {
                    id: welcomeText
                    anchors.top: logoWrap.bottom
                    anchors.topMargin: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "WELCOME BACK"
                    font.family: root.uiFont
                    font.pixelSize: 20
                    font.bold: true
                    font.letterSpacing: 3.5
                    color: root.fg
                    renderType: Text.NativeRendering
                }

                // ── 3. Digitale Uhrzeit & Datum ──────────────────────
                Column {
                    id: clockCol
                    anchors.top: welcomeText.bottom
                    anchors.topMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 3

                    Text {
                        id: timeText
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.family: root.uiFont
                        font.pixelSize: 26
                        font.bold: true
                        font.letterSpacing: 1.5
                        color: root.neonBlue
                        renderType: Text.NativeRendering

                        function updateTime() {
                            text = Qt.formatTime(new Date(), "HH:mm")
                        }
                    }

                    Text {
                        id: dateText
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.family: root.uiFont
                        font.pixelSize: 13
                        color: root.fgSubtle
                        renderType: Text.NativeRendering

                        function updateDate() {
                            var d = new Date()
                            var days = ["Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"]
                            var months = ["Jan.", "Feb.", "März", "Apr.", "Mai", "Juni",
                                          "Juli", "Aug.", "Sept.", "Okt.", "Nov.", "Dez."]
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
                        timeText.updateTime()
                        dateText.updateDate()
                    }
                }

                // ── 4. Benutzername Eingabekapsel ──────────────────────
                Rectangle {
                    id: userCapsule
                    width: parent.width - 64
                    height: 42
                    radius: 21
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: clockCol.bottom
                    anchors.topMargin: 22
                    color: usernameField.activeFocus ? Qt.rgba(1, 1, 1, 0.11) : Qt.rgba(1, 1, 1, 0.07)
                    border.width: 1
                    border.color: usernameField.activeFocus ? root.neonCyan : Qt.rgba(1, 1, 1, 0.12)

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    // Benutzer-Icon
                    Text {
                        id: userIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uf007"
                        font.family: root.uiFont
                        font.pixelSize: 14
                        color: usernameField.activeFocus ? root.neonCyan : root.fgMuted
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    TextField {
                        id: usernameField
                        anchors.left: userIcon.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.currentUserName
                        placeholderText: "Username"
                        placeholderTextColor: root.fgMuted
                        font.family: root.uiFont
                        font.pixelSize: 13
                        color: root.fg
                        background: null
                        selectByMouse: true
                        selectionColor: root.neonCyan
                        selectedTextColor: root.bgDark
                        onTextChanged: root.currentUserName = text
                        Keys.onReturnPressed: passwordField.forceActiveFocus()
                    }
                }

                // ── 5. Passwort Eingabekapsel mit Neon-Glow ──────────
                Rectangle {
                    id: passwordCapsule
                    width: parent.width - 64
                    height: 42
                    radius: 21
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: userCapsule.bottom
                    anchors.topMargin: 12
                    color: passwordField.activeFocus ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.07)
                    border.width: passwordField.activeFocus ? 1.5 : 1.0
                    border.color: root.errorText !== "" ? root.red
                                : passwordField.activeFocus ? root.neonCyan
                                : Qt.rgba(125/255, 207/255, 255/255, 0.35)

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    // Schloss-Icon
                    Text {
                        id: lockIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uf023"
                        font.family: root.uiFont
                        font.pixelSize: 14
                        color: root.errorText !== "" ? root.red : root.neonCyan
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    TextField {
                        id: passwordField
                        anchors.left: lockIcon.right
                        anchors.leftMargin: 10
                        anchors.right: capsLockIcon.visible ? capsLockIcon.left : parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        placeholderText: "Password ••••••••"
                        placeholderTextColor: root.fgMuted
                        echoMode: TextInput.Password
                        passwordCharacter: "\u25CF"
                        font.family: root.uiFont
                        font.pixelSize: 13
                        color: root.fg
                        background: null
                        selectByMouse: true
                        selectionColor: root.neonCyan
                        selectedTextColor: root.bgDark

                        onTextChanged: if (text !== "") root.errorText = ""
                        Keys.onReturnPressed: root.doLogin()
                        Keys.onEnterPressed: root.doLogin()
                    }

                    // CapsLock Indikator
                    Text {
                        id: capsLockIcon
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        visible: (typeof keyboard !== "undefined" && keyboard && keyboard.capsLock) ? true : false
                        text: "\uf062"
                        font.family: root.uiFont
                        font.pixelSize: 12
                        color: root.yellow
                    }
                }

                // ── 6. Login Button (Kreis-Pfeil + LOGIN) ─────────────
                Rectangle {
                    id: loginButton
                    width: 140
                    height: 38
                    radius: 19
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: passwordCapsule.bottom
                    anchors.topMargin: 18
                    color: loginMouse.containsMouse ? Qt.rgba(0/255, 240/255, 255/255, 0.22)
                                                   : Qt.rgba(0/255, 240/255, 255/255, 0.10)
                    border.width: 1.2
                    border.color: loginMouse.containsMouse ? root.neonCyan : Qt.rgba(0/255, 240/255, 255/255, 0.45)
                    scale: loginMouse.pressed ? 0.96 : 1.0

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 10

                        // Cyan Kreis mit Pfeil
                        Rectangle {
                            width: 26
                            height: 26
                            radius: 13
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.neonCyan

                            Text {
                                anchors.centerIn: parent
                                text: root.busy ? "\uf110" : "\uf061"
                                font.family: root.uiFont
                                font.pixelSize: 12
                                font.bold: true
                                color: root.bgDark

                                RotationAnimator on rotation {
                                    from: 0; to: 360; duration: 900
                                    loops: Animation.Infinite
                                    running: root.busy
                                }
                            }
                        }

                        // "LOGIN" Text
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "LOGIN"
                            font.family: root.uiFont
                            font.pixelSize: 13
                            font.bold: true
                            font.letterSpacing: 2.0
                            color: root.fg
                            renderType: Text.NativeRendering
                        }
                    }

                    MouseArea {
                        id: loginMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.doLogin()
                    }
                }

                // ── Status-/Fehlertext ────────────────────────────────
                Text {
                    id: statusLabel
                    anchors.top: loginButton.bottom
                    anchors.topMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: root.uiFont
                    font.pixelSize: 11
                    color: root.errorText !== "" ? root.red : root.yellow
                    text: root.busy ? "Anmelden …"
                        : root.errorText !== "" ? root.errorText
                        : (typeof keyboard !== "undefined" && keyboard && keyboard.capsLock) ? "Feststelltaste aktiv"
                        : ""
                    opacity: text !== "" ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                }

                // ── 7. Hyprland Session Indikator & Wechselschalter ──
                Rectangle {
                    id: sessionBtn
                    width: parent.width - 80
                    height: 44
                    radius: 14
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 16
                    color: sessionMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.06) : "transparent"

                    Behavior on color { ColorAnimation { duration: 140 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 12

                        // Hyprland Wellen-Logo (SVG oder Sinuskurve Canvas)
                        Item {
                            width: 26
                            height: 26
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                id: hyprLogoImg
                                anchors.fill: parent
                                source: "hyprland_logo.svg"
                                fillMode: Image.PreserveAspectFit
                                visible: status === Image.Ready
                            }

                            // Fallback Sinus-Symbol
                            Text {
                                anchors.centerIn: parent
                                visible: !hyprLogoImg.visible
                                text: "∿"
                                font.pixelSize: 22
                                font.bold: true
                                color: root.neonCyan
                            }
                        }

                        // Session Beschriftung
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                id: sessionNameText
                                text: (sessionSelector.currentIndex >= 0 && sessionSelector.model && sessionSelector.model.length > 0)
                                      ? sessionSelector.displayText.toLowerCase() : "hyprland"
                                font.family: root.uiFont
                                font.pixelSize: 13
                                font.bold: true
                                color: root.fg
                                renderType: Text.NativeRendering
                            }

                            Text {
                                text: "hyprland session"
                                font.family: root.uiFont
                                font.pixelSize: 10
                                color: root.fgMuted
                                renderType: Text.NativeRendering
                            }
                        }
                    }

                    MouseArea {
                        id: sessionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (sessionSelector.count > 1) {
                                sessionSelector.currentIndex = (sessionSelector.currentIndex + 1) % sessionSelector.count
                            }
                        }
                    }
                }

                // Unsichtbare ComboBox für SDDM-Sitzungen
                ComboBox {
                    id: sessionSelector
                    visible: false
                    model: (typeof sessionModel !== "undefined") ? sessionModel : ["Hyprland"]
                    textRole: "name"
                    currentIndex: (typeof sessionModel !== "undefined" && typeof sessionModel.lastIndex !== "undefined" && sessionModel.lastIndex >= 0)
                                  ? sessionModel.lastIndex : 0
                }
            }
        }

        // Shake-Animation bei falschem Passwort
        SequentialAnimation {
            id: shakeAnimation
            NumberAnimation { target: cardWrapper; property: "shakeX"; to: -12; duration: 50 }
            NumberAnimation { target: cardWrapper; property: "shakeX"; to:  12; duration: 80 }
            NumberAnimation { target: cardWrapper; property: "shakeX"; to:  -8; duration: 70 }
            NumberAnimation { target: cardWrapper; property: "shakeX"; to:   8; duration: 70 }
            NumberAnimation { target: cardWrapper; property: "shakeX"; to:  -4; duration: 60 }
            NumberAnimation { target: cardWrapper; property: "shakeX"; to:   0; duration: 60 }
        }
    }

    // ══════════════════════════════════════════════════════════
    //  UNTEN RECHTS: MINIMALISTISCHE POWER-ICONS
    // ══════════════════════════════════════════════════════════
    Row {
        id: powerRow
        anchors.right: parent.right
        anchors.rightMargin: 36
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 32
        spacing: 20
        opacity: root.intro

        // 1. Neustart (⟳)
        Rectangle {
            width: 36
            height: 36
            radius: 18
            color: restartMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.14) : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "\uf021"
                font.family: root.uiFont
                font.pixelSize: 18
                color: restartMouse.containsMouse ? root.neonCyan : root.fgMuted
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: restartMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.runPower("reboot")
            }
        }

        // 2. Herunterfahren (⏻)
        Rectangle {
            width: 36
            height: 36
            radius: 18
            color: shutdownMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.14) : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "\uf011"
                font.family: root.uiFont
                font.pixelSize: 18
                color: shutdownMouse.containsMouse ? root.red : root.fgMuted
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: shutdownMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.runPower("powerOff")
            }
        }

        // 3. Abmelden / Standby (➜)
        Rectangle {
            width: 36
            height: 36
            radius: 18
            color: suspendMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.14) : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "\uf2f5"
                font.family: root.uiFont
                font.pixelSize: 17
                color: suspendMouse.containsMouse ? root.neonPurple : root.fgMuted
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: suspendMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.runPower("suspend")
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
    function runPower(action) {
        if (typeof sddm === "undefined") return
        if (action === "suspend")  sddm.suspend()
        if (action === "reboot")   sddm.reboot()
        if (action === "powerOff") sddm.powerOff()
    }

    function doLogin() {
        if (root.busy || passwordField.text === "" || root.currentUserName === "") return
        root.errorText = ""
        root.busy = true
        if (typeof sddm !== "undefined") {
            sddm.login(root.currentUserName, passwordField.text, sessionSelector.currentIndex)
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
