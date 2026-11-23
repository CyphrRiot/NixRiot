pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: view

    property var sys
    property bool open: false

    property var history: []
    property int histIndex: -1

    // Output of the last command, and whether it is still running. A command
    // that is still going after two seconds closes the prompt and keeps
    // running in its own scope, so launching an application feels the same as
    // running something that prints and exits.
    property string output: ""
    property int exitCode: 0
    property bool ran: false
    property bool running: false

    readonly property string historyPath:
        Quickshell.env("HOME") + "/.config/panacea/.run_history"

    function stepHistory(delta) {
        if (!view.history.length) return;
        if (view.histIndex === -1) view.histIndex = view.history.length;
        view.histIndex = Math.max(0, Math.min(view.history.length,
                                             view.histIndex + delta));
        input.text = view.histIndex >= view.history.length ? ""
                                                           : view.history[view.histIndex];
        input.cursorPosition = input.text.length;
    }

    function remember(cmd) {
        pHistWrite.command = ["sh", "-c",
            "printf '%s\\n' \"$1\" >> \"$2\"; tail -n 20 \"$2\" > \"$2.tmp\" && mv \"$2.tmp\" \"$2\"",
            "_", cmd, view.historyPath];
        pHistWrite.running = false;
        pHistWrite.running = true;
    }

    // A command is started in its own systemd scope, so it survives the shell
    // restarting under it instead of dying with the shell's cgroup.
    function runCommand(cmd) {
        view.output = "";
        view.exitCode = 0;
        view.ran = false;
        view.running = true;
        pRun.command = ["systemd-run", "--user", "--scope", "--collect", "--quiet",
                        "sh", "-c", cmd];
        pRun.running = false;
        pRun.running = true;
        runTimer.restart();
        view.remember(cmd);
    }

    function accept() {
        var cmd = input.text.trim();
        if (!cmd.length) { view.sys.closeRun(); return; }
        // The prompt stays open so the output is readable; the two second
        // timer closes it if the command turns out to be an application.
        view.runCommand(cmd);
    }

    onOpenChanged: {
        if (!open) return;
        input.text = "";
        view.histIndex = -1;
        view.output = "";
        view.exitCode = 0;
        view.ran = false;
        view.running = false;
        pHistRead.running = false;
        pHistRead.running = true;
        input.forceActiveFocus();
    }

    Process {
        id: pRun

        stdout: StdioCollector { id: runOut }
        stderr: StdioCollector { id: runErr }

        onExited: code => {
            runTimer.stop();
            view.running = false;
            view.exitCode = code;
            view.ran = true;
            view.output = (String(runOut.text || "")
                           + String(runErr.text || "")).trim();
        }
    }

    // A command still going after two seconds is an application or a daemon:
    // close the prompt and let it keep running in its scope.
    Timer {
        id: runTimer
        interval: 2000
        onTriggered: if (pRun.running) view.sys.closeRun()
    }

    Process { id: pHistWrite }

    Process {
        id: pHistRead
        command: ["sh", "-c", "cat \"$1\" 2>/dev/null", "_", view.historyPath]
        stdout: StdioCollector {
            onStreamFinished: view.history =
                String(text).split("\n").filter(l => l.trim().length)
        }
    }

    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)

        MouseArea {
            anchors.fill: parent
            onClicked: view.sys.closeRun()
        }
    }

    Rectangle {
        id: card

        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.22)
        width: Math.min(760, parent.width - 120)
        height: col.implicitHeight + 32
        radius: 20
        color: view.sys.colBg
        border.width: 1
        border.color: Qt.rgba(view.sys.colFg.r, view.sys.colFg.g, view.sys.colFg.b, 0.14)

        opacity: view.open ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: view.sys.noMotion ? 0 : view.sys.animMs }
        }

        ColumnLayout {
            id: col

            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: "❯"
                    color: view.sys.colOn
                    font { family: view.sys.fontFam; pixelSize: view.sys.fontSize + 2 }
                }

                TextInput {
                    id: input

                    Layout.fillWidth: true
                    clip: true
                    color: view.sys.colFg
                    selectionColor: Qt.rgba(view.sys.colOn.r, view.sys.colOn.g,
                                            view.sys.colOn.b, 0.35)
                    selectedTextColor: view.sys.colFg
                    font { family: view.sys.fontFam; pixelSize: view.sys.fontSize }

                    onAccepted: view.accept()
                    Keys.onEscapePressed: view.sys.closeRun()
                    Keys.onUpPressed: view.stepHistory(-1)
                    Keys.onDownPressed: view.stepHistory(1)
                }
            }

            Text {
                Layout.fillWidth: true
                text: input.text.length ? "" : view.sys.tr("Type a command, Enter to run")
                color: view.sys.colMuted
                elide: Text.ElideRight
                font { family: view.sys.fontBody; pixelSize: view.sys.fontSize - 3 }
            }

            Text {
                Layout.fillWidth: true
                visible: view.ran && view.output.length > 0
                text: view.output
                color: view.sys.colMuted
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 14
                elide: Text.ElideRight
                font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 4 }
            }

            Text {
                Layout.fillWidth: true
                visible: view.ran && view.exitCode !== 0
                text: view.sys.tr("exit") + " " + view.exitCode
                color: view.sys.colCrit
                font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 4 }
            }
        }
    }
}
