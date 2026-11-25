pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io

ColumnLayout {
    id: page

    property var sys
    property bool detailsOpen: false
    property var localeOptions: [{ id: "en", text: "English" }, { id: "tr", text: "Türkçe" }]

    Process {
        command: [page.sys.scriptDir + "/locale.sh", "list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var options = [];
                var lines = String(text).trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split("|");
                    if (parts.length !== 2 || !parts[0].length) continue;
                    var locale = Qt.locale(parts[0]);
                    var nativeName = locale && locale.name !== "C" ? locale.nativeLanguageName : "";
                    options.push({ id: parts[0], text: nativeName ? nativeName + " · " + parts[0] : parts[1] });
                }
                if (options.length) page.localeOptions = options;
            }
        }
    }
    Layout.fillWidth: true
    spacing: 12

    SetCard {
        sys: page.sys

        SetLabel { sys: page.sys; text: page.sys.tr("Language") }

        SetPick {
            sys: page.sys
            label: page.sys.tr("System language")
            options: page.localeOptions
            searchable: true
            value: page.sys.cfg.lang
            onPicked: id => page.sys.setLang(id)
        }

        Text {
            Layout.fillWidth: true
            text: page.sys.sysLangPending
                  ? page.sys.tr("Changing the system language…")
                  : (!page.sys.systemLocaleMatches
                     ? page.sys.tr("The shell is already on the new language. Apps and menus read the language at login; they switch after you log back in.")
                     : page.sys.tr("The shell switches right away. Apps and menus after you log back in: they read the language at login."))
            color: page.sys.colMuted
            wrapMode: Text.WordWrap
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
        }
        Text {
            Layout.fillWidth: true
            visible: ["en", "tr"].indexOf(page.sys.languageCode) < 0
            text: page.sys.tr("There is no Panacea interface translation for this language. English is used for now; request a translation in a GitHub issue.")
            color: page.sys.colMuted
            wrapMode: Text.WordWrap
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
        }
    }

    SetCard {
        sys: page.sys

        SetLabel { sys: page.sys; text: page.sys.tr("Desktop widgets") }

        SetToggle {
            sys: page.sys
            label: page.sys.tr("Desktop widgets")
            sub: page.sys.tr("Cards on the wallpaper: date, clock, weather, system monitor, and a progress bar. Click the cards to switch modes.")
            on: page.sys.cfg.featWidgets
            onToggled: v => { page.sys.cfg.featWidgets = v; page.sys.saveCfg(); }
        }

        SetSelect {
            visible: page.sys.cfg.featWidgets && page.detailsOpen
            sys: page.sys
            label: page.sys.tr("Clock style")
            options: [
                { id: "analog", text: page.sys.tr("Analog") },
                { id: "digital", text: page.sys.tr("Digital Dot") }
            ]
            value: page.sys.cfg.widgetClockMode || "analog"
            onPicked: id => { page.sys.cfg.widgetClockMode = id; page.sys.saveCfg(); }
        }

        SetSelect {
            visible: page.sys.cfg.featWidgets && page.detailsOpen
            sys: page.sys
            label: page.sys.tr("Info card")
            options: [
                { id: "weather", text: page.sys.tr("Weather (wind & humidity)") },
                { id: "system", text: page.sys.tr("System (RAM & SSD)") }
            ]
            value: page.sys.cfg.widgetRightMode || "weather"
            onPicked: id => { page.sys.cfg.widgetRightMode = id; page.sys.saveCfg(); }
        }

        SetToggle {
            visible: page.sys.cfg.featWidgets && page.detailsOpen
            sys: page.sys
            label: page.sys.tr("Pomodoro timer")
            sub: page.sys.tr("A 25 minute focus timer with a 5 minute break, in place of the day progress bar.")
            on: page.sys.cfg.featPomodoro !== false
            onToggled: v => { page.sys.cfg.featPomodoro = v; page.sys.saveCfg(); }
        }

        SetToggle {
            visible: page.sys.cfg.featWidgets && page.detailsOpen
            sys: page.sys
            label: page.sys.tr("Music widget")
            sub: page.sys.tr("A player with a spinning vinyl and playback controls right on the desktop.")
            on: page.sys.cfg.widgetMusic !== false
            onToggled: v => { page.sys.cfg.widgetMusic = v; page.sys.saveCfg(); }
        }

        SetToggle {
            visible: page.sys.cfg.featWidgets && page.detailsOpen
            sys: page.sys
            label: page.sys.tr("ScratchPad widget")
            sub: page.sys.tr("Quick notes right on the desktop with automatic saving.")
            on: page.sys.cfg.widgetScratchpad !== false
            onToggled: v => { page.sys.cfg.widgetScratchpad = v; page.sys.saveCfg(); }
        }

        Text {
            Layout.fillWidth: true
            visible: page.sys.cfg.featWidgets
                     && page.sys.cfg.weatherKey.length === 0
            text: page.sys.tr("Enter a key and city in the Weather tab, or the weather card stays empty.")
            color: page.sys.colMuted
            wrapMode: Text.WordWrap
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
        }
    }

    SetButton {
        sys: page.sys
        text: page.detailsOpen ? page.sys.tr("Hide details") : page.sys.tr("Detailed settings")
        onClicked: page.detailsOpen = !page.detailsOpen
    }

    SetButton {
        sys: page.sys
        text: page.sys.tr("Wallpapers")
        onClicked: page.sys.openWalls()
    }

    SetCard {
        sys: page.sys
        visible: page.detailsOpen

        SetLabel { sys: page.sys; text: page.sys.tr("Appearance") }

        SetSlider {
            sys: page.sys
            label: page.sys.tr("Muted text")
            from: 0.2; to: 1.0; step: 0.05
            decimals: 2
            value: page.sys.cfg.mutedAlpha
            onMoved: v => { page.sys.cfg.mutedAlpha = v; page.sys.saveCfg(); }
        }

        SetSlider {
            sys: page.sys
            label: page.sys.tr("Terminal transparency")
            from: 0.5; to: 1.0; step: 0.01
            decimals: 2
            value: page.sys.cfg.termAlpha
            onMoved: v => {
                page.sys.cfg.termAlpha = v;
                page.sys.saveCfg();
                page.sys.applyTermAlpha();
            }
        }

        Text {
            Layout.fillWidth: true
            text: page.sys.tr("1.00 is a solid background. It applies right away; if not, the terminal is holding settings from a previous login and its server needs a restart.")
            color: page.sys.colMuted
            wrapMode: Text.WordWrap
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item { Layout.fillWidth: true }

            SetButton {
                sys: page.sys
                text: page.sys.tr("Restart the terminal")
                onClicked: page.sys.restartTerminalServer()
            }
        }

        Text {
            Layout.fillWidth: true
            text: page.sys.tr("Open terminal windows will close: they run from the same server.")
            color: page.sys.colMuted
            wrapMode: Text.WordWrap
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
        }
    }

    SetCard {
        sys: page.sys

        SetLabel { sys: page.sys; text: page.sys.tr("Fonts") }

        SetSlider {
            sys: page.sys
            label: page.sys.tr("Text size")
            from: 10; to: 24; step: 1
            value: page.sys.cfg.fontSize
            suffix: "px"
            onMoved: v => { page.sys.cfg.fontSize = v; page.sys.saveCfg(); }
        }

        SetSlider {
            sys: page.sys
            label: page.sys.tr("Icon size")
            visible: page.detailsOpen
            from: 12; to: 28; step: 1
            value: page.sys.cfg.iconSize
            suffix: "px"
            onMoved: v => { page.sys.cfg.iconSize = v; page.sys.saveCfg(); }
        }

        SetPick {
            sys: page.sys
            label: page.sys.tr("Body font")
            visible: page.detailsOpen
            options: page.sys.fontList
            value: page.sys.cfg.fontBody || page.sys.cfg.fontFam
            onPicked: id => { page.sys.cfg.fontBody = id; page.sys.saveCfg(); }
        }

        SetPick {
            sys: page.sys
            label: page.sys.tr("Display font")
            visible: page.detailsOpen
            options: page.sys.fontList
            value: page.sys.cfg.fontDisplay || page.sys.cfg.fontFam
            onPicked: id => { page.sys.cfg.fontDisplay = id; page.sys.saveCfg(); }
        }

        SetPick {
            sys: page.sys
            label: page.sys.tr("Icon font")
            visible: page.detailsOpen
            options: page.sys.fontList
            value: page.sys.cfg.fontFam
            onPicked: id => { page.sys.cfg.fontFam = id; page.sys.saveCfg(); }
        }
    }

    SetCard {
        sys: page.sys

        SetLabel { sys: page.sys; text: page.sys.tr("Sounds") }

        SetToggle {
            sys: page.sys
            label: page.sys.tr("System sound effects")
            sub: page.sys.tr("Charging, Bluetooth, screenshots, voice input")
            on: page.sys.cfg.uiSounds !== false
            onToggled: value => {
                page.sys.cfg.uiSounds = value;
                page.sys.saveCfg();
                if (value) page.sys.playSound("connect");
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 8
            visible: page.sys.cfg.uiSounds !== false && page.detailsOpen

            Repeater {
                model: [
                    { id: "charge",      label: page.sys.tr("Charging"),     icon: "󰂄" },
                    { id: "connect",     label: "Bluetooth",               icon: "󰂯" },
                    { id: "disconnect",  label: page.sys.tr("Disconnect"),  icon: "󰂲" },
                    { id: "screenshot",  label: page.sys.tr("Screenshot"),    icon: "󰄀" },
                    { id: "voice_start", label: page.sys.tr("Voice"),       icon: "󰍬" }
                ]

                Rectangle {
                    id: sndBtn

                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 8
                    color: sndMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05)
                    border.color: sndMa.containsMouse ? page.sys.colOn : page.sys.colLine
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: sndBtn.modelData.icon
                            color: sndMa.containsMouse ? page.sys.colOn : page.sys.colMuted
                            font { family: page.sys.fontFam; pixelSize: 13 }
                        }
                        Text {
                            text: sndBtn.modelData.label
                            color: sndMa.containsMouse ? page.sys.colFg : page.sys.colMuted
                            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: sndMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.sys.playSound(sndBtn.modelData.id)
                    }
                }
            }
        }
    }
}
