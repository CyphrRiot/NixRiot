import QtQuick 2.15

//
Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#050506"

    readonly property string fontFam: "JetBrainsMono Nerd Font"
    //
    Loader {
        id: accentLoader
        source: "file:///var/lib/panacea/accent.qml"
        asynchronous: false
    }
    readonly property color accent:
        accentLoader.item ? accentLoader.item.value : "#c65a47"

    Loader {
        id: localeLoader
        source: "file:///var/lib/panacea/locale.qml"
        asynchronous: false
    }
    readonly property var dictTr: ({
        "Password": "Parola",
        "Wrong password": "Yanlış parola",
        "Sleep": "Uyku",
        "Restart": "Yeniden başlat",
        "Shut down": "Kapat",
    })
    function tr(k) {
        var language = localeLoader.item ? String(localeLoader.item.lang).split("_")[0] : "en";
        if (language === "tr" && dictTr[k] !== undefined) return dictTr[k];
        return k;
    }
    readonly property color fg:
        (accentLoader.item && accentLoader.item.fg !== undefined)
            ? accentLoader.item.fg : "#f2f2f2"
    readonly property color muted:
        (accentLoader.item && accentLoader.item.muted !== undefined)
            ? accentLoader.item.muted : "#8a8a8a"
    readonly property color line: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12)
    readonly property color crit: "#ef4444"

    function fgOn(c) {
        return (0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b) > 0.6
               ? root.bg : "#ffffff";
    }
    readonly property color bg:
        (accentLoader.item && accentLoader.item.bg !== undefined)
            ? accentLoader.item.bg : "#050506"

    readonly property string loginName: userModel.lastUser || "ensi"
    readonly property string nick:
        loginName.charAt(0).toUpperCase() + loginName.slice(1)

    property var sessionNames: []

    Repeater {
        model: sessionModel
        Item {
            Component.onCompleted: {
                var a = root.sessionNames.slice();
                a[index] = name;
                root.sessionNames = a;
            }
        }
    }

    property string errorText: ""
    property bool busy: false

    Image {
        id: wallpaper
        anchors.fill: parent
        source: "file:///var/lib/panacea/sddm-bg.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        visible: status === Image.Ready
        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 320 } }
    }

    Rectangle {
        anchors.fill: parent
        visible: wallpaper.visible
        color: Qt.rgba(0, 0, 0, 0.28)
    }

    Rectangle {
        anchors.fill: parent
        visible: !wallpaper.visible
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.10) }
            GradientStop { position: 0.55; color: "#050506" }
            GradientStop { position: 1.0; color: "#000000" }
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.round(root.height * 0.14)
        spacing: 6

        Text {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.fg
            font { family: root.fontFam; pixelSize: 76; bold: true }
            text: Qt.formatDateTime(new Date(), "HH:mm")
        }
        Text {
            id: dateLabel
            anchors.horizontalCenter: parent.horizontalCenter
            color: Qt.rgba(1, 1, 1, 0.45)
            font { family: root.fontFam; pixelSize: 16 }
            text: Qt.formatDateTime(new Date(), "dddd, d MMMM")
        }
    }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            var d = new Date();
            clock.text = Qt.formatDateTime(d, "HH:mm");
            dateLabel.text = Qt.formatDateTime(d, "dddd, d MMMM");
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 18

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 84; height: 84; radius: 42
            color: Qt.rgba(1, 1, 1, 0.06)
            border.color: root.line
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: root.nick.charAt(0)
                color: root.accent
                font { family: root.fontFam; pixelSize: 34; bold: true }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.nick
            color: root.fg
            font { family: root.fontFam; pixelSize: 20; bold: true }
        }

        Rectangle {
            id: capsule
            anchors.horizontalCenter: parent.horizontalCenter
            width: 420
            height: 60
            radius: 30
            color: Qt.rgba(0.04, 0.04, 0.05, 0.95)
            border.width: 1
            border.color: root.errorText.length
                          ? Qt.rgba(0.94, 0.27, 0.27, 0.75)
                          : (password.activeFocus ? Qt.rgba(root.accent.r, root.accent.g,
                                                            root.accent.b, 0.65)
                                                  : root.line)
            Behavior on border.color { ColorAnimation { duration: 200 } }

            transform: Translate { id: shakeT }
            SequentialAnimation {
                id: shake
                loops: 2
                NumberAnimation { target: shakeT; property: "x"; to: -9; duration: 55 }
                NumberAnimation { target: shakeT; property: "x"; to:  9; duration: 55 }
                NumberAnimation { target: shakeT; property: "x"; to:  0; duration: 55 }
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 22
                anchors.rightMargin: 16
                spacing: 12

                Item {
                    width: 26; height: 26
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: capsuleIcon
                        anchors.centerIn: parent
                        visible: !root.busy
                        text: String.fromCodePoint(0xF033E)
                        color: root.errorText.length ? root.crit : root.accent
                        font { family: root.fontFam; pixelSize: 20 }
                    }

                    //
                    Canvas {
                        id: spinner
                        anchors.centerIn: parent
                        width: 20; height: 20
                        visible: root.busy
                        antialiasing: true

                        property real angle: 0
                        property color tint: root.errorText.length ? root.crit : root.accent
                        onAngleChanged: requestPaint()
                        onTintChanged: requestPaint()

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            var r = width / 2 - 2;
                            ctx.beginPath();
                            ctx.arc(width / 2, height / 2, r, 0, Math.PI * 2);
                            ctx.lineWidth = 2;
                            ctx.strokeStyle = Qt.rgba(spinner.tint.r, spinner.tint.g,
                                                      spinner.tint.b, 0.22);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.arc(width / 2, height / 2, r,
                                    spinner.angle, spinner.angle + Math.PI * 1.5);
                            ctx.lineWidth = 2;
                            ctx.lineCap = "round";
                            ctx.strokeStyle = spinner.tint;
                            ctx.stroke();
                        }

                        NumberAnimation on angle {
                            running: root.busy && spinner.visible
                            loops: Animation.Infinite
                            from: 0; to: Math.PI * 2; duration: 900
                        }
                    }
                }

                TextInput {
                    id: password
                    width: parent.width - 90
                    anchors.verticalCenter: parent.verticalCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    passwordMaskDelay: 0
                    color: root.fg
                    selectionColor: root.accent
                    clip: true
                    font { family: root.fontFam; pixelSize: 16 }
                    focus: true
                    enabled: !root.busy

                    onTextChanged: root.errorText = ""
                    onAccepted: root.doLogin()
                    Keys.onEnterPressed: root.doLogin()

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: password.text.length === 0
                        text: root.errorText.length ? root.errorText : root.tr("Password")
                        color: root.errorText.length ? root.crit : Qt.rgba(1, 1, 1, 0.32)
                        font { family: root.fontFam; pixelSize: 15 }
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40; height: 40; radius: 20
                    color: password.text.length ? root.accent : Qt.rgba(1, 1, 1, 0.08)
                    Behavior on color { ColorAnimation { duration: 160 } }

                    Text {
                        anchors.centerIn: parent
                        text: String.fromCodePoint(0xF0142)
                        color: password.text.length ? root.fgOn(root.accent) : root.muted
                        font { family: root.fontFam; pixelSize: 16 }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.doLogin()
                    }
                }
            }
        }

        Rectangle {
            id: sessionBtn
            anchors.horizontalCenter: parent.horizontalCenter
            width: sessionRow.implicitWidth + 34
            height: 34
            radius: 17
            color: sessionMa.containsMouse || sessionList.visible
                   ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.05)
            border.color: root.line
            border.width: 1
            Behavior on color { ColorAnimation { duration: 150 } }

            property int index: sessionModel.lastIndex

            Row {
                id: sessionRow
                anchors.centerIn: parent
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: String.fromCodePoint(0xF0379)
                    color: root.muted
                    font { family: root.fontFam; pixelSize: 13 }
                }
                Text {
                    id: sessionLabel
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.sessionNames[sessionBtn.index] || "Hyprland"
                    color: root.fg
                    font { family: root.fontFam; pixelSize: 12 }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: String.fromCodePoint(0xF0140)
                    color: root.muted
                    font { family: root.fontFam; pixelSize: 11 }
                }
            }

            MouseArea {
                id: sessionMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sessionList.visible = !sessionList.visible
            }

            Rectangle {
                id: sessionList
                visible: false
                width: 260
                height: Math.min(sessionView.count, 6) * 34 + 12
                radius: 16
                color: Qt.rgba(0.04, 0.04, 0.05, 0.97)
                border.color: root.line
                border.width: 1
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 8

                ListView {
                    id: sessionView
                    anchors.fill: parent
                    anchors.margins: 6
                    clip: true
                    model: sessionModel
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 34
                        radius: 10
                        color: rowMa.containsMouse ? Qt.rgba(1, 1, 1, 0.10)
                             : (index === sessionBtn.index ? Qt.rgba(1, 1, 1, 0.06)
                                                           : "transparent")

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            text: model.name
                            color: index === sessionBtn.index ? root.fg : root.muted
                            font {
                                family: root.fontFam; pixelSize: 12
                                bold: index === sessionBtn.index
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            visible: index === sessionBtn.index
                            text: String.fromCodePoint(0xF012C)
                            color: root.accent
                            font { family: root.fontFam; pixelSize: 12 }
                        }

                        MouseArea {
                            id: rowMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                sessionBtn.index = index;
                                sessionLabel.text = model.name;
                                sessionList.visible = false;
                                password.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 48
        spacing: 14

        Repeater {
            model: [
                { glyph: "", sleep: true, tip: root.tr("Sleep"),          act: "suspend" },
                { glyph: String.fromCodePoint(0xF0709), tip: root.tr("Restart"), act: "reboot"  },
                { glyph: String.fromCodePoint(0xF0425), tip: root.tr("Shut down"),    act: "power"   }
            ]

            Rectangle {
                width: 46; height: 46; radius: 23
                color: pwrMa.containsMouse ? Qt.rgba(1, 1, 1, 0.18)
                                           : Qt.rgba(1, 1, 1, 0.09)
                border.color: pwrMa.containsMouse
                              ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.45)
                              : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.22)
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                scale: pwrMa.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 130 } }

                Item {
                    anchors.centerIn: parent
                    width: 26; height: 26
                    visible: modelData.sleep === true
                    opacity: pwrMa.containsMouse ? 1 : 0.75
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Text {
                        x: 0; y: 9
                        text: "Z"
                        color: root.fg
                        font { family: root.fontFam; pixelSize: 15; bold: true }
                    }
                    Text {
                        x: 11; y: 0
                        text: "z"
                        color: root.fg
                        font { family: root.fontFam; pixelSize: 8; bold: true }
                    }
                    Text {
                        x: 16; y: 5
                        text: "z"
                        color: root.fg
                        font { family: root.fontFam; pixelSize: 11; bold: true }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: modelData.sleep !== true
                    text: modelData.glyph
                    color: root.fg
                    opacity: pwrMa.containsMouse ? 1 : 0.75
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    font { family: root.fontFam; pixelSize: 18 }
                }

                MouseArea {
                    id: pwrMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var a = modelData.act;
                        if (a === "suspend") sddm.suspend();
                        else if (a === "reboot") sddm.reboot();
                        else sddm.powerOff();
                    }
                }
            }
        }
    }

    //
    Item {
        id: kbBox
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 22
        width: kbText.implicitWidth
        height: kbText.implicitHeight
        clip: true

        readonly property string value: {
            var l = keyboard.layouts;
            if (!l || l.length === 0) return "";
            var i = keyboard.currentLayout;
            if (i < 0 || i >= l.length || !l[i] || !l[i].shortName) return "";
            return String(l[i].shortName).toUpperCase();
        }
        property string shown: kbBox.value

        onValueChanged: if (kbBox.value !== kbBox.shown) kbFlip.restart()

        Text {
            id: kbText
            text: kbBox.shown
            color: root.fg
            opacity: 0.75
            font { family: root.fontFam; pixelSize: 12; bold: true; letterSpacing: 1 }
        }

        SequentialAnimation {
            id: kbFlip
            NumberAnimation { target: kbText; property: "opacity"; to: 0; duration: 90 }
            NumberAnimation { target: kbText; property: "y"
                              to: -kbBox.height; duration: 0 }
            ScriptAction { script: kbBox.shown = kbBox.value }
            NumberAnimation { target: kbText; property: "y"; to: 0
                              duration: 150; easing.type: Easing.OutCubic }
            NumberAnimation { target: kbText; property: "opacity"; to: 0.75
                              duration: 150 }
        }
    }

    function doLogin() {
        if (root.busy || password.text.length === 0) return;
        root.errorText = "";
        root.busy = true;
        sddm.login(root.loginName, password.text, sessionBtn.index);
    }

    Connections {
        target: sddm

        function onLoginSucceeded() {
            root.busy = false;
            root.errorText = "";
        }
        function onLoginFailed() {
            root.busy = false;
            root.errorText = root.tr("Wrong password");
            password.text = "";
            shake.restart();
            password.forceActiveFocus();
        }
        function onInformationMessage(message) {
            root.busy = false;
            root.errorText = message;
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}
