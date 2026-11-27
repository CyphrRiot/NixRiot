import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: page

    property var sys

    // Desired state, as recorded by the feature service, and the step it is on.
    property var installed: ({})
    property var status: ({})

    // Live state of the unit, which can lag the setting until the rebuild lands.
    property bool sshRunning: false

    readonly property bool busy: status && status.busy === true
    readonly property bool statusFresh: status && status.ts !== undefined
        && (Date.now() / 1000 - status.ts) < 30
    readonly property bool failed: status && status.step === "failed"

    Layout.fillWidth: true
    spacing: 12

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
    Process {
        id: pSsh
        command: ["sh", "-c", "systemctl is-active sshd 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: page.sshRunning = (String(text).trim() === "active")
        }
    }
    Process { id: pStart }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            pState.running = false; pState.running = true;
            pStatus.running = false; pStatus.running = true;
            pSsh.running = false; pSsh.running = true;
        }
    }
    Component.onCompleted: {
        pState.running = true;
        pStatus.running = true;
        pSsh.running = true;
    }

    function setSsh(on) {
        pStart.command = ["systemctl", "start",
                          "nixriot-features@ssh-" + (on ? "on" : "off") + ".service"];
        pStart.running = false;
        pStart.running = true;
    }

    SetCard {
        sys: page.sys

        SetToggle {
            sys: page.sys
            label: page.sys.tr("SSH Server")
            sub: page.sys.tr("Off by default. Turning it on rebuilds the system.")
            on: page.installed.ssh === true
            onToggled: v => { if (!page.busy) page.setSsh(v); }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: page.sys.tr("Service")
                color: page.sys.colFg
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 1 }
            }
            Text {
                text: page.sshRunning ? page.sys.tr("Running") : page.sys.tr("Not Running")
                color: page.sshRunning ? page.sys.colOk : page.sys.colMuted
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
            }
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: page.sys.tr("When it is on, passwords and root logins are refused, so only a "
                              + "public key listed in ~/.ssh/authorized_keys gets in.")
            color: page.sys.colMuted
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
        }
    }

    SetCard {
        sys: page.sys
        visible: page.busy || page.failed || (page.status.step === "done" && page.statusFresh)

        SetLabel {
            sys: page.sys
            text: page.busy ? page.sys.tr("Rebuilding") + " " + page.status.feature
                 : page.failed ? page.sys.tr("Failed")
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
                color: page.failed ? page.sys.colCrit : page.sys.colOn
                Behavior on width { NumberAnimation { duration: 400 } }
            }
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: page.status.step || ""
            color: page.sys.colMuted
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
        }
    }

    SetCard {
        sys: page.sys

        SetLabel { sys: page.sys; text: page.sys.tr("Keys") }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: page.sys.tr("Put a public key in ~/.ssh/authorized_keys for every account that "
                              + "should be reachable. The same setting can be written by hand as "
                              + "nixriot.ssh = true; in /etc/nixriot/hosts/installed/local.nix.")
            color: page.sys.colMuted
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
        }
    }
}
