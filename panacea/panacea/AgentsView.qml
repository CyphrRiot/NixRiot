pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

//
//
Item {
    id: view
    property var sys

    implicitHeight: col.implicitHeight

    property var  agents: []
    property real serverNow: 0
    property bool loaded: false

    property real clockNow: Date.now()
    Timer {
        interval: 30000; repeat: true; running: true
        onTriggered: view.clockNow = Date.now()
    }

    Process {
        id: pAgents
        command: ["sh", view.sys.scriptDir + "/agents.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let d = JSON.parse(text);
                    view.agents = d.agents || [];
                    view.serverNow = d.now || Date.now();
                } catch (e) {
                    view.agents = [];
                }
                view.loaded = true;
                view.clockNow = Date.now();
            }
        }
    }

    function refresh() { pAgents.running = false; pAgents.running = true; }

    Timer {
        interval: 20000; repeat: true; running: true
        onTriggered: view.refresh()
    }

    Connections {
        target: view.sys
        function onAgentsEpochChanged() { view.refresh(); }
    }

    FileView {
        path: Quickshell.env("HOME") + "/.claude.json"
        watchChanges: true
        printErrors: false
        onFileChanged: view.refresh()
    }

    function limitLabel(kind) {
        switch (String(kind)) {
        case "session":       return view.sys.tr("5 hours");
        case "weekly_all":    return view.sys.tr("Week");
        case "weekly_opus":   return view.sys.tr("Opus, week");
        case "weekly_sonnet": return view.sys.tr("Sonnet, week");
        }
        return String(kind).replace(/_/g, " ");
    }

    function untilText(ms) {
        if (!ms || ms <= 0) return "";
        var left = ms - view.clockNow;
        if (left <= 0) return view.sys.tr("window has already reset");
        var mins = Math.floor(left / 60000);
        var h = Math.floor(mins / 60), m = mins % 60;
        var pre = view.sys.tr("resets in") + " ";
        if (h >= 24) return pre + Math.floor(h / 24) + " " + view.sys.tr("d") + " " + (h % 24) + " " + view.sys.tr("h");
        if (h > 0)   return pre + h + " " + view.sys.tr("h") + " " + m + " " + view.sys.tr("min");
        return pre + Math.max(1, m) + " " + view.sys.tr("min");
    }

    function agoText(ms) {
        if (!ms || ms <= 0) return "";
        var mins = Math.floor((view.clockNow - ms) / 60000);
        if (mins < 1)  return view.sys.tr("just now");
        if (mins < 60) return mins + " " + view.sys.tr("min ago");
        var h = Math.floor(mins / 60);
        if (h < 24) return h + " " + view.sys.tr("h ago");
        return Math.floor(h / 24) + " " + view.sys.tr("d ago");
    }

    function barColor(pct, severity) {
        if (String(severity) === "critical" || pct >= 90) return view.sys.colCrit;
        if (pct >= 70) return view.sys.colWarn;
        return view.sys.colOn;
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Glyph {
                glyph: String.fromCodePoint(0xF1719)   // md-robot_outline
                color: view.sys.colFg
                fontFam: view.sys.fontFam
                size: 19
            }
            Text {
                text: view.sys.tr("Agents")
                color: view.sys.colFg
                font { family: view.sys.fontDisplay; pixelSize: view.sys.fontSize + 1; bold: true }
            }
            Item { Layout.fillWidth: true }
            Text {
                visible: view.loaded && view.agents.length > 0
                text: view.agents.length
                color: view.sys.colMuted
                font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 4 }
            }
        }

        Repeater {
            model: view.agents

            Rectangle {
                id: card
                required property var modelData

                Layout.fillWidth: true
                implicitHeight: body.implicitHeight + 26
                radius: 14
                color: Qt.rgba(view.sys.colFg.r, view.sys.colFg.g, view.sys.colFg.b, 0.05)
                border.width: 1
                border.color: view.sys.colLine

                ColumnLayout {
                    id: body
                    anchors {
                        left: parent.left; right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 14; rightMargin: 14
                    }
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: card.modelData.name || ""
                            color: view.sys.colFg
                            font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 2; bold: true }
                        }
                        Text {
                            visible: String(card.modelData.version || "").length > 0
                            text: card.modelData.version || ""
                            color: view.sys.colMuted
                            font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 5 }
                        }
                        Item { Layout.fillWidth: true }

                        Rectangle {
                            visible: String(card.modelData.plan || "").length > 0
                            implicitWidth: planText.implicitWidth + 18
                            implicitHeight: 22
                            radius: 11
                            color: Qt.rgba(view.sys.colOn.r, view.sys.colOn.g, view.sys.colOn.b, 0.18)
                            Text {
                                id: planText
                                anchors.centerIn: parent
                                text: card.modelData.plan || ""
                                color: view.sys.colOn
                                font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 5; bold: true }
                            }
                        }
                    }

                    Repeater {
                        model: card.modelData.limits || []

                        ColumnLayout {
                            id: lim
                            required property var modelData

                            Layout.fillWidth: true
                            spacing: 5

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                Text {
                                    text: view.limitLabel(lim.modelData.kind)
                                    color: view.sys.colFg
                                    font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 4 }
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: Math.round(lim.modelData.percent) + "%"
                                    color: view.barColor(lim.modelData.percent, lim.modelData.severity)
                                    font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 4; bold: true }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 7
                                radius: 4
                                color: Qt.rgba(view.sys.colFg.r, view.sys.colFg.g, view.sys.colFg.b, 0.10)

                                Rectangle {
                                    height: parent.height
                                    radius: parent.radius
                                    width: parent.width * Math.max(0, Math.min(100, lim.modelData.percent)) / 100
                                    color: view.barColor(lim.modelData.percent, lim.modelData.severity)
                                    Behavior on width  { NumberAnimation { duration: view.sys.animMs; easing.type: Easing.OutQuint } }
                                    Behavior on color  { ColorAnimation  { duration: view.sys.animFade } }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: text.length > 0
                                text: view.untilText(lim.modelData.resetsAt)
                                color: view.sys.colMuted
                                font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 6 }
                            }
                        }
                    }

                    //
                    Text {
                        Layout.fillWidth: true
                        visible: (card.modelData.limits || []).length === 0
                        text: String(card.modelData.note) !== "nodata"
                              ? view.sys.tr("This agent does not expose its limits")
                              : String(card.modelData.id) === "claude"
                              ? view.sys.tr("No data yet — run /usage in Claude Code")
                              : view.sys.tr("No data yet — it will appear once the agent has run")
                        color: view.sys.colMuted
                        wrapMode: Text.WordWrap
                        font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 5 }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: (card.modelData.limits || []).length > 0
                                 && String(view.agoText(card.modelData.fetchedAt)).length > 0
                        text: view.sys.tr("agent data from") + " " + view.agoText(card.modelData.fetchedAt)
                        color: view.sys.colMuted
                        font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 6 }
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: view.loaded && view.agents.length === 0
            text: view.sys.tr("No agents found")
            color: view.sys.colMuted
            horizontalAlignment: Text.AlignHCenter
            font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 4 }
        }
    }
}
