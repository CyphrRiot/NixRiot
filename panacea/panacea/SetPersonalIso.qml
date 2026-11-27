import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: page

    property var sys

    Layout.fillWidth: true
    spacing: 12

    property string hostName: ""

    function clock(seconds) {
        var s = Math.max(0, Math.floor(seconds));
        var m = Math.floor(s / 60);
        return (m < 10 ? "0" : "") + m + ":" + (s % 60 < 10 ? "0" : "") + (s % 60);
    }

    Process {
        id: pHost
        command: ["sh", "-c", "hostname -s 2>/dev/null || hostname"]
        stdout: StdioCollector { onStreamFinished: page.hostName = String(text).trim() }
    }
    Process {
        id: pOpen
        command: ["xdg-open", Quickshell.env("HOME") + "/Downloads"]
    }
    Component.onCompleted: pHost.running = true

    SetCard {
        sys: page.sys

        SetLabel { sys: page.sys; text: page.sys.tr("An ISO with your settings") }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: page.sys.tr("Builds the NixRiot installer image from this machine's "
                              + "configuration, so a fresh install already has your account, "
                              + "your Installs selection and your Panacea settings.")
            color: page.sys.colMuted
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: page.sys.tr("Carried: the username and hostname, the Installs selection "
                              + "(Claude, LibreOffice, games and the rest), and the Panacea "
                              + "look, bindings and Installs state. Not carried: hardware, "
                              + "passwords, SSH keys, the vault, application data, or the "
                              + "weather and AI API keys, which are removed from the settings "
                              + "before the image is built.")
            color: page.sys.colMuted
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
        }
    }

    SetCard {
        sys: page.sys
        visible: page.sys.isoBusy || page.sys.isoError.length > 0 || page.sys.isoPath.length > 0

        SetLabel {
            sys: page.sys
            text: page.sys.isoBusy ? page.sys.tr("Building the image")
                 : page.sys.isoError.length > 0 ? page.sys.tr("Failed")
                 : page.sys.tr("Done")
        }

        Text {
            Layout.fillWidth: true
            visible: page.sys.isoBusy && page.sys.isoStep.length > 0
            text: page.sys.isoStep
            color: page.sys.colFg
            elide: Text.ElideRight
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 2 }
        }

        Rectangle {
            id: isoBar
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            radius: 3
            color: Qt.rgba(1, 1, 1, 0.08)
            clip: true
            visible: page.sys.isoBusy

            Rectangle {
                id: isoBarRunner
                width: parent.width * 0.3
                height: parent.height
                radius: 3
                color: page.sys.colOn
                x: -width
                NumberAnimation on x {
                    from: -isoBarRunner.width
                    to: isoBar.width
                    duration: 1500
                    loops: Animation.Infinite
                    running: page.sys.isoBusy
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: page.sys.isoBusy && page.sys.isoLog.length > 0
            text: page.sys.isoLog
            color: page.sys.colMuted
            elide: Text.ElideRight
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 5 }
        }

        Text {
            Layout.fillWidth: true
            visible: page.sys.isoPath.length > 0
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            text: page.sys.isoPath
            color: page.sys.colMuted
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
        }

        Text {
            Layout.fillWidth: true
            visible: page.sys.isoError.length > 0
            wrapMode: Text.WordWrap
            text: page.sys.isoError
            color: page.sys.colCrit
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                Layout.fillWidth: true
                visible: page.sys.isoBusy
                text: page.clock(page.sys.isoElapsed)
                color: page.sys.colMuted
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
            }
            SetButton {
                sys: page.sys
                visible: page.sys.isoBusy
                text: page.sys.tr("Cancel")
                primary: true
                onClicked: page.sys.isoCancel()
            }
            SetButton {
                sys: page.sys
                visible: !page.sys.isoBusy && page.sys.isoPath.length > 0
                text: page.sys.tr("Open folder")
                onClicked: pOpen.running = true
            }
        }
    }

    SetCard {
        sys: page.sys

        SetLabel { sys: page.sys; text: page.sys.tr("Image") }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                Layout.fillWidth: true
                text: page.sys.tr("File name")
                color: page.sys.colFg
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 1 }
            }
            Text {
                text: "NixRiot-" + (page.hostName.length ? page.hostName : "nixriot") + "-<date>.iso"
                color: page.sys.colMuted
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                Layout.fillWidth: true
                text: page.sys.tr("Saved to")
                color: page.sys.colFg
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 1 }
            }
            Text {
                text: "~/Downloads"
                color: page.sys.colMuted
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                Layout.fillWidth: true
                text: page.sys.tr("Space and time")
                color: page.sys.colFg
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 1 }
            }
            Text {
                text: page.sys.tr("8 GB free in /nix, 3 GB in ~/Downloads, 20 to 60 minutes")
                color: page.sys.colMuted
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
            }
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: page.sys.tr("The image is unsigned and is not the official release. "
                              + "It needs a network connection for anything this machine "
                              + "does not already have cached.")
            color: page.sys.colMuted
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
        }

        SetButton {
            sys: page.sys
            text: page.sys.isoBusy ? page.sys.tr("Building")
                                   : page.sys.tr("Build image")
            primary: true
            enabled: !page.sys.isoBusy
            onClicked: page.sys.isoStart()
        }
    }
}
