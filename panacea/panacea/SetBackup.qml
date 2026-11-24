import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: page

    property var sys

    Layout.fillWidth: true
    spacing: 12

    readonly property string drive: page.sys.cfg.backupDrive ? String(page.sys.cfg.backupDrive) : ""
    readonly property string drivePath: page.drive.length ? page.drive : (page.st.drive || "")
    readonly property string home: page.st.source && String(page.st.source).length
                                   ? String(page.st.source)
                                   : (Quickshell.env("HOME") || "")
    readonly property string script: page.sys.scriptDir + "/backup.sh"

    property var st: ({})
    property var drives: []
    property string job: ""
    property string step: ""
    property string file: ""
    property string note: ""
    property string failed: ""
    property int pct: 0
    property real done: 0
    property real total: 0
    property int elapsed: 0
    property var driftLines: []
    property bool confirmRestore: false

    readonly property bool busy: page.job.length > 0
    readonly property bool mounted: page.st.mounted === "yes"
    readonly property bool crypto: page.st.crypto === "yes"

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

    function reset() {
        page.step = "";
        page.file = "";
        page.note = "";
        page.failed = "";
        page.pct = 0;
        page.done = 0;
        page.total = 0;
        page.elapsed = 0;
        page.driftLines = [];
        page.confirmRestore = false;
    }

    function start(kind) {
        if (page.busy) return;
        page.reset();
        page.job = kind;
        pJob.command = ["sh", "-c", page.script + " " + (kind === "restore" ? "restore " : kind + " ") + "\"$1\"", "_", page.drive];
        pJob.running = false;
        pJob.running = true;
    }

    function restoreGo() {
        if (page.busy) return;
        page.confirmRestore = false;
        page.job = "restore";
        pJob.command = ["sh", "-c", page.script + " restore --go \"$1\"", "_", page.drive];
        pJob.running = false;
        pJob.running = true;
    }

    function refresh() {
        if (page.busy) return;
        pStatus.running = false;
        pStatus.running = true;
    }

    function refreshDrives() {
        pDisks.running = false;
        pDisks.running = true;
    }

    Process {
        id: pStatus
        command: ["sh", "-c", page.script + " status \"$1\"", "_", page.drive]
        stdout: StdioCollector {
            onStreamFinished: {
                var m = ({});
                var lines = text.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var k = lines[i].indexOf("=");
                    if (k < 1) continue;
                    m[lines[i].substring(0, k)] = lines[i].substring(k + 1);
                }
                page.st = m;
            }
        }
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

    Process {
        id: pJob
        stdout: SplitParser {
            onRead: line => {
                var t = line.trim().split(" ");
                if (t[0] === "STEP") {
                    var s = t.slice(1).join(" ");
                    page.step = s;
                    if (page.job === "restore" && s.indexOf("would change") === 0) {
                        page.driftLines = page.driftLines.concat([s.replace("would change ", "")]);
                    }
                } else if (t[0] === "FILE") {
                    page.file = t.slice(1).join(" ");
                } else if (t[0] === "PROGRESS") {
                    page.pct = parseInt(t[1]) || 0;
                    page.done = parseFloat(t[2]) || 0;
                    page.total = parseFloat(t[3]) || 0;
                } else if (t[0] === "DONE") {
                    page.finish(t[1] || "ok");
                } else if (t[0] === "ERROR") {
                    page.failed = t.slice(2).join(" ") || t[1] || "failed";
                    page.step = page.sys.tr("Failed");
                }
            }
        }
        onRunningChanged: {
            if (running) return;
            page.refreshDrives();
            if (page.job === "mount") { page.job = ""; page.refresh(); return; }
            if (page.busy) page.finish("cancelled");
            page.refresh();
        }
    }

    function finish(kind) {
        var wasRestore = page.job === "restore";
        page.job = "";
        if (kind === "ok") {
            if (wasRestore && page.driftLines.length > 0) {
                page.confirmRestore = true;
                page.note = page.sys.tr("Ready to restore") + ": " + page.driftLines.length;
            } else if (wasRestore) {
                page.note = page.sys.tr("Nothing to restore");
            } else {
                page.note = page.sys.tr("Done");
            }
        } else if (kind === "drift") {
            page.failed = page.sys.tr("The mirror differs from the source");
        } else if (kind === "cancelled") {
            page.note = page.sys.tr("Cancelled");
        } else {
            page.failed = kind;
        }
        page.pct = 100;
    }

    Timer {
        interval: 1000
        running: page.busy
        repeat: true
        onTriggered: page.elapsed++
    }

    Timer {
        interval: 5000
        running: !page.busy
        repeat: true
        onTriggered: page.refresh()
    }

    Component.onCompleted: { page.refresh(); page.refreshDrives(); }

    SetCard {
        sys: page.sys

        SetLabel { sys: page.sys; text: page.sys.tr("Backup drive") }

        SetSelect {
            sys: page.sys
            label: page.sys.tr("Location")
            options: [{ id: "", text: page.sys.tr("Automatic") }].concat(page.drives)
            value: page.drive
            onPicked: id => { page.sys.cfg.backupDrive = id; page.sys.saveCfg(); page.refresh(); }
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
                text: page.mounted
                      ? (page.crypto ? page.sys.tr("Mounted, encrypted") : page.sys.tr("Mounted, not encrypted"))
                      : page.sys.tr("Not mounted")
                color: page.mounted ? (page.crypto ? page.sys.colOk : page.sys.colCrit) : page.sys.colMuted
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
            }
            SetButton {
                sys: page.sys
                visible: !page.mounted
                text: page.sys.tr("Mount")
                enabled: !page.busy
                onClicked: { page.reset(); page.job = "mount"; pJob.command = ["sh", "-c", page.script + " mount \"$1\"", "_", page.drive]; pJob.running = false; pJob.running = true; }
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
                text: page.mounted ? page.human(page.st.free) : "-"
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
                text: page.st.last && page.st.last.length ? page.st.last : page.sys.tr("never")
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
                text: page.human(page.st.size)
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
                enabled: !page.busy && page.mounted
                onClicked: page.start("backup")
            }
            SetButton {
                sys: page.sys
                Layout.fillWidth: true
                text: page.sys.tr("Verify")
                enabled: !page.busy && page.mounted
                onClicked: page.start("verify")
            }
            SetButton {
                sys: page.sys
                Layout.fillWidth: true
                text: page.sys.tr("Restore…")
                enabled: !page.busy && page.mounted
                onClicked: page.start("restore")
            }
        }
    }

    SetCard {
        sys: page.sys
        visible: page.busy || page.note.length > 0 || page.failed.length > 0

        SetLabel {
            sys: page.sys
            text: page.title()
        }

        Text {
            Layout.fillWidth: true
            text: page.step
            color: page.sys.colMuted
            elide: Text.ElideRight
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            radius: 3
            color: Qt.rgba(1, 1, 1, 0.08)

            Rectangle {
                width: page.pct > 0 ? parent.width * Math.min(1, page.pct / 100) : 0
                height: parent.height
                radius: 3
                color: page.failed.length > 0 ? page.sys.colCrit : page.sys.colOn
                Behavior on width { NumberAnimation { duration: 300 } }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                Layout.fillWidth: true
                text: page.busy && page.file.length ? page.file : (page.failed.length ? page.failed : page.note)
                color: page.failed.length > 0 ? page.sys.colCrit : page.sys.colMuted
                elide: Text.ElideMiddle
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
            }
            Text {
                visible: page.busy
                text: page.pct + "%" + (page.total > 0 ? "  " + page.human(page.done) + " / " + page.human(page.total) : "")
                      + "  " + page.clock(page.elapsed)
                color: page.sys.colMuted
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
            }
            SetButton {
                sys: page.sys
                visible: page.busy
                text: page.sys.tr("Cancel")
                onClicked: pJob.running = false
            }
        }
    }

    SetCard {
        sys: page.sys
        visible: page.confirmRestore

        SetLabel { sys: page.sys; text: page.sys.tr("Restore") }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: page.sys.tr("You will overwrite") + " " + page.home + " "
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
            model: page.driftLines.slice(0, 12)
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
            visible: page.driftLines.length > 12
            text: "+ " + (page.driftLines.length - 12)
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
                enabled: !page.busy
                onClicked: page.restoreGo()
            }
            SetButton {
                sys: page.sys
                Layout.fillWidth: true
                text: page.sys.tr("Cancel")
                onClicked: page.reset()
            }
        }
    }
}
