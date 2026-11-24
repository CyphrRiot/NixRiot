pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: page

    property var sys

    // [{ name, desc, w, h, rr, scale, transform, vrr, x, y, modes: [] }]
    property var mons: []

    // One "HH:MM" field for the schedule. Two of these side by side beat six
    // spinners, and the format is easy to validate.
    component NightTimeField: ColumnLayout {
        id: tf

        property var sys
        property string label: ""
        property string value: "22:00"
        signal committed(string value)

        spacing: 4

        function textValue() { return input.text; }
        function setTime(v) { input.text = String(v); }

        Text {
            text: tf.label
            color: tf.sys.colMuted
            font { family: tf.sys.fontBody; pixelSize: tf.sys.fontSize - 4 }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 10
            color: Qt.rgba(tf.sys.colFg.r, tf.sys.colFg.g, tf.sys.colFg.b, 0.07)

            TextInput {
                id: input
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                color: tf.sys.colFg
                clip: true
                selectByMouse: true
                text: tf.value
                font { family: tf.sys.fontBody; pixelSize: tf.sys.fontSize - 2 }
                onEditingFinished: tf.committed(text)
                Keys.onEscapePressed: { input.text = tf.value; input.focus = false; }
            }
        }
    }

    Layout.fillWidth: true
    spacing: 12

    Component.onCompleted: { pMons.running = true; page.sys.brightRefresh(false); }

    function brightOf(name) {
        var l = page.sys.brightList || [];
        for (var i = 0; i < l.length; i++)
            if (l[i].name === name) return l[i];
        if (l.length === 1 && page.sys.brightBackend === "backlight") return l[0];
        return null;
    }

    // Commit both fields together: otherwise one can be saved while the other is
    // still half-typed. An invalid time snaps the fields back to what is saved.
    function commitNightTimes() {
        page.sys.setNightTimes(startField.textValue(), endField.textValue());
        startField.setTime(page.sys.cfg.nightStart);
        endField.setTime(page.sys.cfg.nightEnd);
    }

    Process {
        id: pMons
        command: ["sh", "-c", "hyprctl -j monitors all"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var raw = JSON.parse(text.slice(text.lastIndexOf("[{")));
                    page.mons = raw.map(m => ({
                        name: m.name,
                        desc: m.description || "",
                        w: m.width, h: m.height,
                        rr: m.refreshRate,
                        scale: m.scale,
                        transform: m.transform,
                        vrr: !!m.vrr,
                        x: m.x, y: m.y,
                        modes: m.availableModes || []
                    }));
                } catch (e) {
                    page.mons = [];
                }
            }
        }
    }

    function apply(m, over) {
        page.sys.monApply(m.name, {
            w:  over.w  !== undefined ? over.w  : m.w,
            h:  over.h  !== undefined ? over.h  : m.h,
            rr: over.rr !== undefined ? over.rr : m.rr,
            scale: over.scale !== undefined ? over.scale : m.scale,
            transform: over.transform !== undefined ? over.transform : m.transform,
            vrr: m.vrr,
            pos: over.pos !== undefined ? over.pos : page.placeOf(m)
        });
        reload.restart();
    }

    Timer {
        id: reload
        interval: 700
        onTriggered: { pMons.running = false; pMons.running = true; }
    }

    function placeOf(m) {
        var base = page.mons.length ? page.mons[0] : null;
        if (!base || base.name === m.name) return "auto";
        if (m.x >= base.x + base.w) return "auto-right";
        if (m.x + m.w <= base.x)    return "auto-left";
        if (m.y >= base.y + base.h) return "auto-down";
        if (m.y + m.h <= base.y)    return "auto-up";
        return "auto";
    }

    function modeText(s) {
        var p = String(s).split("@");
        var wh = p[0].split("x");
        return wh[0] + " × " + wh[1]
            + (p.length > 1 ? " · " + Number(parseFloat(p[1])).toFixed(0) + " Hz" : "");
    }
    function modeList(m) {
        var seen = {}, out = [];
        (m.modes || []).forEach(s => {
            if (seen[s]) return;
            seen[s] = true;
            out.push({ id: s, text: page.modeText(s) });
        });
        if (!out.length) {
            var cur = m.w + "x" + m.h + "@" + m.rr;
            out.push({ id: cur, text: page.modeText(cur) });
        }
        return out;
    }
    function modeValue(m) {
        var best = "", dist = 1e9;
        (m.modes || []).forEach(s => {
            var p = s.split("@");
            if (p[0] !== m.w + "x" + m.h) return;
            var d = Math.abs(parseFloat(p[1]) - m.rr);
            if (d < dist) { dist = d; best = s; }
        });
        return best || (m.w + "x" + m.h + "@" + m.rr);
    }
    function applyMode(m, id) {
        var p = String(id).split("@");
        var wh = p[0].split("x");
        page.apply(m, { w: +wh[0], h: +wh[1], rr: parseFloat(p[1]) });
    }

    SetCard {
        sys: page.sys
        visible: page.mons.length > 1

        SetLabel {
            sys: page.sys
            text: page.sys.tr("Dynamic island")
        }

        SetPick {
            sys: page.sys
            label: page.sys.tr("Show on screen")
            options: [{ id: "auto", text: page.sys.tr("Follow focus") }].concat(
                page.mons.map(m => ({
                    id: m.name,
                    text: m.name + (m.desc.length ? " · " + m.desc : "")
                })))
            value: page.sys.cfg.pillScreen
            onPicked: id => { page.sys.cfg.pillScreen = id; page.sys.saveCfg(); }
        }

        Text {
            Layout.fillWidth: true
            text: page.sys.tr("“Follow focus” moves the island to whichever screen you are working on.")
            color: page.sys.colMuted
            wrapMode: Text.WordWrap
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: page.mons.length === 0
        text: page.sys.tr("Screens cannot be read: hyprctl did not answer.")
        color: page.sys.colMuted
        font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
    }

    Repeater {
        model: page.mons

        SetCard {
            id: card
            required property var modelData
            required property int index
            readonly property string res: card.modelData.w + "x" + card.modelData.h

            sys: page.sys

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: card.modelData.name
                        color: page.sys.colFg
                        font { family: page.sys.fontDisplay; pixelSize: page.sys.fontSize }
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: card.modelData.desc.length > 0
                        text: card.modelData.desc
                        color: page.sys.colMuted
                        elide: Text.ElideRight
                        font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
                    }
                }

                Text {
                    text: card.res + " · " + Number(card.modelData.rr).toFixed(0) + " Hz"
                    color: page.sys.colMuted
                    font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
                }
            }

            SetPick {
                sys: page.sys
                label: page.sys.tr("Mode")
                options: page.modeList(card.modelData)
                value: page.modeValue(card.modelData)
                onPicked: id => page.applyMode(card.modelData, id)
            }

            Text {
                Layout.fillWidth: true
                visible: (card.modelData.modes || []).length === 0
                text: page.sys.tr("The monitor did not report any modes; usually that means "
                                  + "the graphics driver is not installed.")
                color: page.sys.colCrit
                wrapMode: Text.WordWrap
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
            }

            SetSelect {
                sys: page.sys
                visible: page.mons.length > 1 && card.index > 0
                label: page.sys.tr("Placement") + (page.mons.length > 1
                       ? " — " + page.sys.tr("relative to") + " " + page.mons[0].name : "")
                options: [
                    { id: "auto-right", text: page.sys.tr("Right of") },
                    { id: "auto-left",  text: page.sys.tr("Left of") },
                    { id: "auto-up",    text: page.sys.tr("Above") },
                    { id: "auto-down",  text: page.sys.tr("Below") }
                ]
                value: page.placeOf(card.modelData)
                onPicked: id => page.apply(card.modelData, { pos: id })
            }

            SetSlider {
                id: brightSl
                readonly property var b: page.brightOf(card.modelData.name)
                sys: page.sys
                visible: brightSl.b !== null
                label: page.sys.tr("Brightness")
                from: 1; to: 100; step: 1
                value: brightSl.b ? brightSl.b.pct : 0
                suffix: "%"
                onMoved: v => { if (brightSl.b) page.sys.brightSet(brightSl.b.id, v); }
            }

            Text {
                Layout.fillWidth: true
                visible: page.brightOf(card.modelData.name) === null
                         && !page.sys.batteryPresent
                text: !page.sys.ddcutilPresent
                      ? page.sys.tr("Monitor brightness is handled by ddcutil, which is not installed. "
                                    + "Install the ddcutil package and the slider will appear here.")
                      : page.sys.tr("The monitor does not answer DDC/CI brightness requests. "
                                    + "This is usually enabled in its menu under DDC/CI.")
                color: page.sys.colMuted
                wrapMode: Text.WordWrap
                font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
            }

            SetSlider {
                sys: page.sys
                visible: card.index === 0
                label: page.sys.tr("Digital vibrance")
                from: 0; to: 100; step: 5
                value: page.sys.cfg.vibrance
                suffix: "%"
                onMoved: v => page.sys.applyVibrance(v)
            }

            SetSlider {
                sys: page.sys
                label: page.sys.tr("Scale")
                from: 1; to: 3; step: 0.01
                decimals: 2
                value: card.modelData.scale
                suffix: "×"
                onMoved: v => page.apply(card.modelData, { scale: v })
            }

            SetSelect {
                sys: page.sys
                label: page.sys.tr("Rotation")
                options: [
                    { id: "0", text: "0°" },
                    { id: "1", text: "90°" },
                    { id: "2", text: "180°" },
                    { id: "3", text: "270°" }
                ]
                value: String(card.modelData.transform)
                onPicked: id => page.apply(card.modelData, { transform: +id })
            }

        }
    }

    SetCard {
        sys: page.sys

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    text: page.sys.tr("Detect displays")
                    color: page.sys.colFg
                    font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 1 }
                }
                Text {
                    Layout.fillWidth: true
                    text: page.sys.tr("Re-read the list of connected monitors.")
                    color: page.sys.colMuted
                    wrapMode: Text.WordWrap
                    font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
                }
            }

            Rectangle {
                Layout.preferredWidth: 118
                Layout.preferredHeight: 32
                radius: 10
                color: detectMa.containsMouse
                       ? Qt.rgba(page.sys.colOn.r, page.sys.colOn.g, page.sys.colOn.b, 0.28)
                       : Qt.rgba(page.sys.colFg.r, page.sys.colFg.g, page.sys.colFg.b, 0.07)
                Behavior on color { ColorAnimation { duration: page.sys.animFade } }

                Text {
                    anchors.centerIn: parent
                    text: page.sys.tr("Refresh")
                    color: page.sys.colFg
                    font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
                }
                MouseArea {
                    id: detectMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { pMons.running = false; pMons.running = true; }
                }
            }
        }
    }

    // ------------------------------------------------------------ night light
    // Its own card in Display: it is about how the picture looks, so it is
    // looked for next to brightness.
    SetCard {
        sys: page.sys

        SetLabel { sys: page.sys; text: page.sys.tr("Night light") }

        Text {
            Layout.fillWidth: true
            text: page.sys.tr("A warm filter that takes the blue out of the screen in the evening. "
                              + "A lower temperature is warmer and yellower.")
            color: page.sys.colMuted
            wrapMode: Text.WordWrap
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
        }

        SetToggle {
            sys: page.sys
            label: page.sys.tr("Turn on night light")
            sub: page.sys.tr("Stays on until the next schedule boundary, if automatic switching is on.")
            on: page.sys.cfg.nightLight
            onToggled: v => page.sys.setNightLight(v, true)
        }

        SetSlider {
            sys: page.sys
            label: page.sys.tr("Night light temperature")
            from: 2500; to: 6500; step: 100
            value: page.sys.cfg.nightTemp
            suffix: "K"
            onMoved: v => page.sys.setNightTemp(v)
        }

        SetToggle {
            sys: page.sys
            label: page.sys.tr("Turn on automatically")
            sub: page.sys.tr("On the schedule below: on in the evening, off in the morning.")
            on: page.sys.cfg.nightAuto
            onToggled: v => page.sys.setNightAuto(v)
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            NightTimeField {
                id: startField
                Layout.fillWidth: true
                sys: page.sys
                label: page.sys.tr("Turn on at")
                value: page.sys.cfg.nightStart
                onCommitted: v => page.commitNightTimes()
            }
            NightTimeField {
                id: endField
                Layout.fillWidth: true
                sys: page.sys
                label: page.sys.tr("Turn off at")
                value: page.sys.cfg.nightEnd
                onCommitted: v => page.commitNightTimes()
            }
        }
    }
}
