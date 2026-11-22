import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: page

    property var sys
    property var installed: ({})
    property var status: ({})

    Layout.fillWidth: true
    spacing: 12

    readonly property bool busy: status && status.busy === true
    readonly property var features: [
        { key: "office",       name: "LibreOffice", sub: "Writer, Calc, Impress. About 1 GB." },
        { key: "games",        name: "Games",       sub: "SuperTux, OpenTTD, Cataclysm-DDA, Endless Sky, Angband, Brogue." },
        { key: "transmission", name: "Transmission", sub: "BitTorrent client." },
        { key: "monero",       name: "Monero",      sub: "Monero GUI wallet." },
        { key: "bitcoin",      name: "Bitcoin",     sub: "Bitcoin Core and Bitcoin Qt." },
        { key: "glyphriot",    name: "GlyphRiot",   sub: "Seed-phrase glyph tool." }
    ]

    function parseInstalled(text) {
        try { page.installed = JSON.parse(text); } catch (e) { page.installed = ({}); }
    }
    function parseStatus(text) {
        try { page.status = JSON.parse(text); } catch (e) { page.status = ({}); }
    }

    Process {
        id: pState
        command: ["sh", "-c", "cat /var/lib/nixriot/features.json 2>/dev/null || echo {}"]
        stdout: StdioCollector { onStreamFinished: page.parseInstalled(text) }
    }
    Process {
        id: pStatus
        command: ["sh", "-c", "cat /run/nixriot-features/status.json 2>/dev/null || echo {}"]
        stdout: StdioCollector { onStreamFinished: page.parseStatus(text) }
    }
    Process { id: pStart }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            pState.running = false;
            pState.running = true;
            pStatus.running = false;
            pStatus.running = true;
        }
    }
    Component.onCompleted: {
        pState.running = true;
        pStatus.running = true;
    }

    function setFeature(key, on) {
        pStart.command = ["systemctl", "start",
                          "nixriot-features@" + key + "-" + (on ? "on" : "off") + ".service"];
        pStart.running = false;
        pStart.running = true;
    }

    SetCard {
        sys: page.sys

        SetLabel { sys: page.sys; text: page.sys.tr("Optional applications") }

        Repeater {
            model: page.features

            RowLayout {
                required property var modelData

                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: modelData.name
                        color: page.sys.colFg
                        font {
                            family: page.sys.fontBody
                            pixelSize: page.sys.fontSize - 1
                            bold: true
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.sub
                        color: page.sys.colMuted
                        wrapMode: Text.WordWrap
                        font {
                            family: page.sys.fontBody
                            pixelSize: page.sys.fontSize - 3
                        }
                    }
                }

                SetButton {
                    sys: page.sys
                    text: page.busy && page.status.feature === modelData.key
                          ? (page.status.action === "on"
                             ? page.sys.tr("Installing…")
                             : page.sys.tr("Removing…"))
                          : page.installed[modelData.key] ? page.sys.tr("Remove") : page.sys.tr("Install")
                    primary: !page.installed[modelData.key]
                    enabled: !page.busy
                    onClicked: page.setFeature(modelData.key, !page.installed[modelData.key])
                }
            }
        }
    }

    SetCard {
        sys: page.sys
        visible: page.busy || page.status.step === "done" || page.status.step === "failed"

        SetLabel {
            sys: page.sys
            text: page.busy
                  ? page.sys.tr("Installing") + " " + page.status.feature
                  : page.status.step === "failed"
                    ? page.sys.tr("Failed")
                    : page.sys.tr("Done")
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            radius: 3
            color: Qt.rgba(1, 1, 1, 0.08)

            Rectangle {
                width: page.busy ? parent.width * 0.6 : parent.width
                height: parent.height
                radius: 3
                color: page.sys.colOn
                Behavior on width { NumberAnimation { duration: 400 } }
            }
        }

        Text {
            Layout.fillWidth: true
            text: page.status.step || ""
            color: page.sys.colMuted
            font {
                family: page.sys.fontBody
                pixelSize: page.sys.fontSize - 3
            }
        }
    }
}
