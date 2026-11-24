import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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
        { key: "glyphriot",    name: "GlyphRiot",   sub: "Seed-phrase glyph tool." },
        { key: "claude",       name: "Claude Code", sub: "Anthropic's command-line agent." }
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

    // ---------------------------------------------------------------- search
    // Every attribute name in the pinned nixpkgs, written by the features module.
    // Names only, so the whole search is a string scan and nothing here has to
    // know what a flake or a nixpkgs evaluation is.
    property string indexText: ""
    readonly property var indexNames: indexText.length ? indexText.split("\n") : []
    property string query: ""
    // What the list is showing: the ranked matches. Capped, because the panel is
    // small and a long list of near misses is not an answer.
    readonly property var results: page.rankMatches(query, page.indexNames)

    FileView {
        path: "/etc/nixriot-packages.txt"
        watchChanges: false
        printErrors: false
        onLoaded: page.indexText = String(text())
    }

    function rankMatches(q, names) {
        var needle = String(q || "").trim().toLowerCase();
        if (needle.length < 2) return [];
        var exact = [], prefix = [], sub = [], fuzz = [];
        var subseq = function (n) {
            var i = 0;
            for (var k = 0; k < n.length && i < needle.length; k++)
                if (n[k] === needle[i]) i++;
            return i === needle.length;
        };
        for (var j = 0; j < names.length; j++) {
            var n = names[j];
            if (!n.length) continue;
            var low = n.toLowerCase();
            if (low === needle) { exact.push(n); continue; }
            if (low.startsWith(needle)) { prefix.push(n); continue; }
            if (low.indexOf(needle) >= 0) { sub.push(n); continue; }
            if (needle.length >= 3 && subseq(low)) fuzz.push(n);
        }
        // nixpkgs keeps the same package under more than one spelling: the
        // canonical attribute, and an alias that holds the upstream name, so
        // "supertux" matched superTux, superTuxKart, supertux and
        // supertuxkart. One row per package, and the lowercase attribute is
        // the spelling that installs.
        var dedupe = function (names) {
            var best = new Map();
            var order = [];
            for (var i = 0; i < names.length; i++) {
                var name = names[i];
                var key = name.toLowerCase();
                if (!best.has(key)) {
                    best.set(key, name);
                    order.push(key);
                } else if (name === key) {
                    best.set(key, name);
                }
            }
            var out = [];
            for (var j = 0; j < order.length; j++)
                out.push(best.get(order[j]));
            return out;
        };
        // If the whole name was typed, that is the answer. Variants such as
        // chromium-bsu and chromium-hsts are prefix matches of "chromium" and
        // only add noise when the user already typed the exact name.
        if (exact.length > 0) return dedupe(exact).slice(0, 5);
        return dedupe(exact.concat(prefix, sub, fuzz)).slice(0, 5);
    }

    function displayName(name) {
        var parts = name.split(/[-_.]/).filter(function (p) { return p.length; });
        return parts.map(function (p) { return p.charAt(0).toUpperCase() + p.slice(1); }).join(" ");
    }

    function installedPackages() {
        var list = page.installed && page.installed.packages;
        return Array.isArray(list) ? list : [];
    }

    function setPackage(name, add) {
        pStart.command = ["systemctl", "start",
                          "nixriot-features@" + name + "-" + (add ? "add" : "remove") + ".service"];
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

    SetCard {
        sys: page.sys
        visible: page.indexNames.length > 0

        SetLabel { sys: page.sys; text: page.sys.tr("Install anything else") }

        Text {
            Layout.fillWidth: true
            text: page.sys.tr("Search packages by name and install them. Two letters is enough to start.")
            color: page.sys.colMuted
            wrapMode: Text.WordWrap
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            radius: 19
            color: Qt.rgba(1, 1, 1, 0.06)
            border.color: searchField.activeFocus ? page.sys.colOn : page.sys.colLine
            border.width: 1

            TextField {
                id: searchField
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                background: null
                color: page.sys.colFg
                placeholderText: page.sys.tr("Search packages")
                placeholderTextColor: page.sys.colMuted
                onTextChanged: page.query = text
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 2 }
                Keys.onEscapePressed: text = ""
            }
        }

        Text {
            Layout.fillWidth: true
            visible: page.query.length === 1
            text: page.sys.tr("Keep typing")
            color: page.sys.colMuted
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
        }

        Text {
            Layout.fillWidth: true
            visible: page.query.length >= 2 && page.results.length === 0
            text: page.sys.tr("Nothing matches that")
            color: page.sys.colMuted
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
        }

        Repeater {
            model: page.results

            RowLayout {
                required property var modelData

                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: page.displayName(modelData)
                        color: page.sys.colFg
                        font {
                            family: page.sys.fontBody
                            pixelSize: page.sys.fontSize - 1
                            bold: true
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData
                        color: page.sys.colMuted
                        elide: Text.ElideMiddle
                        font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
                    }
                }

                SetButton {
                    sys: page.sys

                    readonly property bool have: page.installedPackages().some(
                        function (p) { return p.toLowerCase() === modelData.toLowerCase(); })

                    text: page.busy && page.status.feature === modelData
                          ? (page.status.action === "add"
                             ? page.sys.tr("Installing…")
                             : page.sys.tr("Removing…"))
                          : have ? page.sys.tr("Remove") : page.sys.tr("Install")
                    primary: !have
                    enabled: !page.busy
                    onClicked: page.setPackage(modelData, !have)
                }
            }
        }
    }
}
