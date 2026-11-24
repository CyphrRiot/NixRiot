import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: page

    property var sys

    Layout.fillWidth: true
    spacing: 12

    readonly property string drive: page.sys.backupDrive
    readonly property string drivePath: page.sys.backupDrive.length ? page.sys.backupDrive : (page.sys.backupStatus.drive || "")

    property var drives: []

    function human(bytes) {
        var b = Number(bytes) || 0;
        var u = ["B", "kB", "MB", "GB", "TB", "PB"];
        var i = 0;
        while (b >= 1024 && i < u.length - 1) { b /= 1024; i++; }
        return (i === 0 ? b.toFixed(0) : b.toFixed(1)) + " " + u[i];
    }

    function clock(seconds) {
        var s = Math.max(0, Math.floor(seconds));
        var m = Math.floor(s / 60);
        return (m < 10 ? "0" : "") + m + ":" + (s % 60 < 10 ? "0" : "") + (s % 60);
    }

    function refreshDrives() {
        pDisks.running = false;
        pDisks.running = true;
    }

    Process {
        id: pDisks
        command: ["sh", "-c", page.sys.scriptDir + "/files.sh disks"]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = [];
                var lines = text.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var p = lines[i].split("|");
                    if (p.length < 6 || p[0] !== "removable" || !p[1]) continue;
                    if (p[1].indexOf("/run/media/") !== 0 && p[1].indexOf("/media/") !== 0) continue;
                    out.push({ id: p[1], text: p[2] && p[2].length ? p[2] : p[1] });
                }
                page.drives = out;
            }
        }
    }

    Timer {
        interval: 5000
        running: !page.sys.backupBusy
        repeat: true
        onTriggered: page.sys.backupRefresh()
    }

    Component.onCompleted: { page.sys.backupRefresh(); page.refreshDrives(); }

    SetCard {
        sys: page.sys
        visible: page.sys.backupBusy || page.sys.backupNote.length > 0 || page.sys.backupFailed.length > 0

        SetLabel {
            sys: page.sys
            text: page.sys.backupBusy ? page.sys.backupStep
                             : (page.sys.backupFailed.length > 0 ? page.sys.tr("Failed") : page.sys.backupNote)
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            radius: 3
            color: Qt.rgba(1, 1, 1, 0.08)

            Rectangle {
                width: page.sys.backupPct > 0 ? parent.width * Math.min(1, page.sys.backupPct / 100) : 0
                height: parent.height
                radius: 3
                color: page.sys.backupFailed.length > 0 ? page.sys.colCrit : page.sys.colOn
                Behavior on width { NumberAnimation { duration: 300 } }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                Layout.fillWidth: true
                text: page.sys.backupBusy && page.sys.backupFile.length ? page.sys.backupFile
                      : (page.sys.backupFailed.length ? page.sys.backupFailed : page.sys.backupNote)
                color: page.sys.backupFailed.length > 0 ? page.sys.colCrit : page.sys.colMuted
                elide: Text.ElideMiddle
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
            }
            Text {
                visible: page.sys.backupBusy
                text: page.sys.backupPct + "%" + (page.sys.backupTotal > 0 ? "  " + page.human(page.sys.backupDone) + " / " + page.human(page.sys.backupTotal) : "")
                      + "  " + page.clock(page.sys.backupElapsed)
                color: page.sys.colMuted
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
            }
            SetButton {
                sys: page.sys
                visible: page.sys.backupBusy
                text: page.sys.tr("Cancel")
                primary: true
                onClicked: page.sys.backupCancel()
            }
        }
    }

    SetCard {
        sys: page.sys

        SetLabel { sys: page.sys; text: page.sys.tr("Backup drive") }

        SetSelect {
            sys: page.sys
            label: page.sys.tr("Location")
            options: [{ id: "", text: page.sys.tr("Automatic") }].concat(page.drives)
            value: page.drive
            onPicked: id => { page.sys.backupSetDrive(id); }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                Layout.fillWidth: true
                text: page.sys.tr("Drive")
                color: page.sys.colFg
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 1 }
            }
            Text {
                text: page.drivePath
                color: page.sys.colMuted
                elide: Text.ElideMiddle
                Layout.maximumWidth: 260
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                Layout.fillWidth: true
                text: page.sys.tr("State")
                color: page.sys.colFg
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 1 }
            }
            Text {
                text: page.sys.backupMounted
                      ? (page.sys.backupCrypto ? page.sys.tr("Mounted, encrypted") : page.sys.tr("Mounted, not encrypted"))
                      : page.sys.tr("Not mounted")
                color: page.sys.backupMounted ? (page.sys.backupCrypto ? page.sys.colOk : page.sys.colCrit) : page.sys.colMuted
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
            }
            SetButton {
                sys: page.sys
                visible: !page.sys.backupMounted
                text: page.sys.tr("Mount")
                enabled: !page.sys.backupBusy
                onClicked: page.sys.backupStart("mount")
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                Layout.fillWidth: true
                text: page.sys.tr("Free space")
                color: page.sys.colFg
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 1 }
            }
            Text {
                text: page.sys.backupMounted ? page.human(page.sys.backupStatus.free) : "-"
                color: page.sys.colMuted
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                Layout.fillWidth: true
                text: page.sys.tr("Last backup")
                color: page.sys.colFg
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 1 }
            }
            Text {
                text: page.sys.backupStatus.last && page.sys.backupStatus.last.length ? page.sys.backupStatus.last : page.sys.tr("never")
                color: page.sys.colMuted
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                Layout.fillWidth: true
                text: page.sys.tr("Mirror size")
                color: page.sys.colFg
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 1 }
            }
            Text {
                text: page.human(page.sys.backupStatus.size)
                color: page.sys.colMuted
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
            }
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: page.sys.tr("The drive is a mirror of your home folder: files you delete here are deleted there on the next backup.")
            color: page.sys.colMuted
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            SetButton {
                sys: page.sys
                Layout.fillWidth: true
                text: page.sys.tr("Back up now")
                primary: true
                enabled: !page.sys.backupBusy && page.sys.backupMounted
                onClicked: page.sys.backupStart("backup")
            }
            SetButton {
                sys: page.sys
                Layout.fillWidth: true
                text: page.sys.tr("Verify")
                enabled: !page.sys.backupBusy && page.sys.backupMounted
                onClicked: page.sys.backupStart("verify")
            }
            SetButton {
                sys: page.sys
                Layout.fillWidth: true
                text: page.sys.tr("Restore…")
                enabled: !page.sys.backupBusy && page.sys.backupMounted
                onClicked: page.sys.backupStart("restore")
            }
        }
    }

    SetCard {
        sys: page.sys
        visible: page.sys.backupConfirm

        SetLabel { sys: page.sys; text: page.sys.tr("Restore") }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: page.sys.tr("You will overwrite") + " " + page.sys.backupHome + " "
                  + page.sys.tr("with the backup data. Are you absolutely certain this is what you want to do?")
            color: page.sys.colCrit
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 1; bold: true }
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: page.sys.tr("Files that exist on both sides are replaced by the backup copy. Files that exist only here are kept, and nothing is deleted.")
            color: page.sys.colMuted
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
        }

        Repeater {
            model: page.sys.backupDrift.slice(0, 12)
            Text {
                required property var modelData
                Layout.fillWidth: true
                text: modelData
                color: page.sys.colFg
                elide: Text.ElideRight
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: page.sys.backupDrift.length > 12
            text: "+ " + (page.sys.backupDrift.length - 12)
            color: page.sys.colMuted
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            SetButton {
                sys: page.sys
                Layout.fillWidth: true
                text: page.sys.tr("Yes, restore")
                primary: true
                enabled: !page.sys.backupBusy
                onClicked: page.sys.backupStart("restore", true)
            }
            SetButton {
                sys: page.sys
                Layout.fillWidth: true
                text: page.sys.tr("Cancel")
                onClicked: page.sys.backupConfirm = false
            }
        }
    }
}
