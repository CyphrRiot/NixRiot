pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io

//
ColumnLayout {
    id: page

    property var sys

    property var bindDraft: ({})
    property int bindRev: 0
    readonly property bool dirty: {
        bindRev;
        for (var id in page.bindDraft) return true;
        return false;
    }

    function bindCombo(id) {
        bindRev;
        var raw = page.bindDraft[id] !== undefined
                  ? String(page.bindDraft[id]) : String(page.sys.cfg["bind_" + id] || "");
        return page.prettyCombo(raw);
    }
    function bindRaw(id) {
        bindRev;
        return page.bindDraft[id] !== undefined
               ? String(page.bindDraft[id]) : String(page.sys.cfg["bind_" + id] || "");
    }

    readonly property var keySigns: ({
        slash: "/", backslash: "\\", comma: ",", period: ".",
        semicolon: ";", apostrophe: "'", grave: "`", minus: "-", equal: "=",
        bracketleft: "[", bracketright: "]", space: "Space", delete: "Del"
    })
    function prettyCombo(raw) {
        var parts = String(raw).split("+");
        for (var i = 0; i < parts.length; i++) {
            var k = parts[i].trim();
            var sign = page.keySigns[k.toLowerCase()];
            parts[i] = sign !== undefined ? sign : k;
        }
        return parts.join(" + ");
    }
    function bindChanged(id) {
        bindRev;
        return page.bindDraft[id] !== undefined;
    }
    function setBind(id, combo) {
        page.bindDraft[id] = combo;
        page.bindRev++;
    }
    function clearBind(id) { page.setBind(id, ""); }
    function discardBinds() { page.bindDraft = ({}); page.bindRev++; }

    function applyBinds() {
        var touched = false;
        for (var id in page.bindDraft) {
            page.sys.cfg["bind_" + id] = page.bindDraft[id];
            touched = true;
        }
        page.discardBinds();
        if (touched) page.sys.applyBinds();
    }
    function resetBinds() {
        var o = {};
        var def = page.sys.defaultBinds;
        for (var id in def) {
            if (String(page.sys.cfg["bind_" + id] || "") !== def[id]) o[id] = def[id];
        }
        page.bindDraft = o;
        page.bindRev++;
    }

    property string capturingKey: ""

    property bool  mMeta:  false
    property bool  mCtrl:  false
    property bool  mAlt:   false
    property bool  mShift: false
    property string pendingName: ""

    readonly property string capturePreview: {
        var m = [];
        if (mMeta)  m.push("SUPER");
        if (mCtrl)  m.push("CTRL");
        if (mAlt)   m.push("ALT");
        if (mShift) m.push("SHIFT");
        if (pendingName.length) m.push(pendingName);
        return m.join(" + ");
    }

    Process { id: pCapture }
    function grabKeys(on) {
        pCapture.running = false;
        pCapture.command = ["sh", "-c",
            page.sys.scriptDir + "/capture.sh " + (on ? "on" : "off")];
        pCapture.running = true;
    }

    function clearHeld() {
        page.mMeta = false; page.mCtrl = false; page.mAlt = false; page.mShift = false;
        page.pendingName = "";
    }

    function startCapture(key) {
        page.capturingKey = key;
        page.clearHeld();
        page.forceActiveFocus();
        page.grabKeys(true);
        captureTimeout.restart();
    }
    function stopCapture() {
        if (page.capturingKey.length === 0) return;
        page.capturingKey = "";
        page.clearHeld();
        captureTimeout.stop();
        page.grabKeys(false);
    }

    Timer {
        id: captureTimeout
        interval: 8000
        onTriggered: page.stopCapture()
    }

    Connections {
        target: page.sys
        function onCancelCaptureRequested() {
            if (page.capturingKey.length) page.stopCapture();
        }
    }

    readonly property var modKeys: [
        Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_AltGr,
        Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_CapsLock
    ]

    function isMeta(k)  { return k === Qt.Key_Meta || k === Qt.Key_Super_L || k === Qt.Key_Super_R; }
    function isCtrl(k)  { return k === Qt.Key_Control; }
    function isAlt(k)   { return k === Qt.Key_Alt || k === Qt.Key_AltGr; }
    function isShift(k) { return k === Qt.Key_Shift; }

    function keyName(k) {
        if (k >= Qt.Key_A && k <= Qt.Key_Z) return String.fromCharCode(k);
        if (k >= Qt.Key_0 && k <= Qt.Key_9) return String.fromCharCode(k);
        if (k >= Qt.Key_F1 && k <= Qt.Key_F12) return "F" + (k - Qt.Key_F1 + 1);
        switch (k) {
            case Qt.Key_Space:  return "Space";
            case Qt.Key_Return:
            case Qt.Key_Enter:  return "Return";
            case Qt.Key_Tab:    return "Tab";
            case Qt.Key_Left:   return "left";
            case Qt.Key_Right:  return "right";
            case Qt.Key_Up:     return "up";
            case Qt.Key_Down:   return "down";
            case Qt.Key_Comma:  return "comma";
            case Qt.Key_Period: return "period";
            case Qt.Key_Slash:  return "slash";
            case Qt.Key_Minus:  return "minus";
            case Qt.Key_Equal:  return "equal";
            case Qt.Key_BracketLeft:  return "bracketleft";
            case Qt.Key_BracketRight: return "bracketright";
            case Qt.Key_Semicolon:    return "semicolon";
            case Qt.Key_Apostrophe:   return "apostrophe";
            case Qt.Key_Backslash:    return "backslash";
            case Qt.Key_Delete:       return "delete";
            case Qt.Key_Insert:       return "insert";
            case Qt.Key_Home:         return "home";
            case Qt.Key_End:          return "end";
            case Qt.Key_PageUp:       return "Page_Up";
            case Qt.Key_PageDown:     return "Page_Down";
            case Qt.Key_Backspace:    return "BackSpace";
            case Qt.Key_Print:        return "Print";
            case Qt.Key_Pause:        return "Pause";
            case Qt.Key_Menu:         return "Menu";
        }
        return "";
    }

    focus: true

    Keys.onPressed: event => {
        if (page.capturingKey.length === 0) {
            if (event.key === Qt.Key_Escape) {
                page.sys.keysWindowOpen = false;
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Slash && (event.modifiers & Qt.MetaModifier)) {
                page.sys.keysWindowOpen = false;
                event.accepted = true;
            }
            return;
        }
        event.accepted = true;
        captureTimeout.restart();

        if (event.key === Qt.Key_Escape) { page.stopCapture(); return; }

        page.mMeta  = page.mMeta  || page.isMeta(event.key)  || (event.modifiers & Qt.MetaModifier)    !== 0;
        page.mCtrl  = page.mCtrl  || page.isCtrl(event.key)  || (event.modifiers & Qt.ControlModifier) !== 0;
        page.mAlt   = page.mAlt   || page.isAlt(event.key)   || (event.modifiers & Qt.AltModifier)     !== 0;
        page.mShift = page.mShift || page.isShift(event.key) || (event.modifiers & Qt.ShiftModifier)   !== 0;

        if (page.modKeys.indexOf(event.key) >= 0) return;

        var n = page.keyName(event.key);
        if (n.length === 0) return;
        page.pendingName = n;

        var target = page.capturingKey;
        var combo = page.capturePreview;
        page.stopCapture();
        page.setBind(target, combo);
    }

    Keys.onReleased: event => {
        if (page.capturingKey.length === 0) return;
        event.accepted = true;
        if (page.isMeta(event.key))  page.mMeta = false;
        if (page.isCtrl(event.key))  page.mCtrl = false;
        if (page.isAlt(event.key))   page.mAlt = false;
        if (page.isShift(event.key)) page.mShift = false;
    }

    Component.onCompleted: page.forceActiveFocus()
    Component.onDestruction: {
        if (page.capturingKey.length) page.grabKeys(false);
    }

    component BindRow: RowLayout {
        id: brow
        property string bindId: ""
        property string label: ""
        property bool manual: false
        readonly property bool capturing: page.capturingKey === brow.bindId
        readonly property string combo: page.bindCombo(brow.bindId)
        readonly property bool edited: page.bindChanged(brow.bindId)

        // Keep each shortcut at a consistent height in the scrollable list.
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        spacing: 14

        Rectangle {
            id: box
            Layout.preferredWidth: brow.manual ? 220 : 176
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignVCenter
            radius: 9
            color: brow.capturing
                   ? Qt.rgba(page.sys.colOn.r, page.sys.colOn.g, page.sys.colOn.b, 0.20)
                   : (bMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.07))
            border.color: brow.capturing ? page.sys.colOn : page.sys.colLine
            border.width: 1
            Behavior on color { ColorAnimation { duration: 160 } }
            Behavior on border.color { ColorAnimation { duration: 160 } }

            SequentialAnimation {
                running: brow.capturing
                loops: Animation.Infinite
                alwaysRunToEnd: true
                NumberAnimation { target: box; property: "opacity"; to: 0.45; duration: 520 }
                NumberAnimation { target: box; property: "opacity"; to: 1.0;  duration: 520 }
            }

            Text {
                visible: !brow.manual
                anchors.centerIn: parent
                text: brow.capturing
                      ? (page.capturePreview.length ? page.capturePreview
                                                    : page.sys.tr("Press a shortcut…"))
                      : (brow.combo.length ? brow.combo : "—")
                color: brow.combo.length || brow.capturing ? page.sys.colFg : page.sys.colMuted
                font { family: page.sys.fontFam; pixelSize: page.sys.fontSize - 4; bold: true }
            }

            TextField {
                id: manualCombo
                visible: brow.manual
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                verticalAlignment: TextInput.AlignVCenter
                text: page.bindRaw(brow.bindId)
                color: page.sys.colFg
                selectByMouse: true
                background: null
                font { family: page.sys.fontFam; pixelSize: page.sys.fontSize - 4 }
                onEditingFinished: if (text.trim() !== page.bindRaw(brow.bindId)) page.setBind(brow.bindId, text.trim())
            }

            Connections {
                target: page
                function onBindRevChanged() { if (brow.manual) manualCombo.text = page.bindRaw(brow.bindId); }
            }

            Rectangle {
                width: 6; height: 6; radius: 3
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 5
                visible: brow.edited
                color: page.sys.colOk
            }

            MouseArea {
                id: bMa
                anchors.fill: parent
                enabled: !brow.manual
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: page.startCapture(brow.bindId)
            }
        }

        Text {
            Layout.fillWidth: true
            text: brow.label
            color: page.sys.colMuted
            elide: Text.ElideRight
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 2 }
        }

        Text {
            text: "×"
            visible: brow.combo.length > 0
            color: cMa.containsMouse ? page.sys.colCrit : page.sys.colMuted
            font { family: page.sys.fontFam; pixelSize: page.sys.fontSize + 2 }
            Behavior on color { ColorAnimation { duration: 150 } }
            MouseArea {
                id: cMa
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: page.clearBind(brow.bindId)
            }
        }
    }


    component Head: Text {
        Layout.fillWidth: true
        Layout.topMargin: 8
        color: page.sys.colMuted
        font {
            family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4
            bold: true; capitalization: Font.AllUppercase; letterSpacing: 1
        }
    }

    //
    Layout.fillWidth: true
    spacing: 10

    Text {
        Layout.fillWidth: true
        text: page.sys.tr("Click a binding to change it. × removes the key.")
        color: Qt.rgba(1, 1, 1, 0.32)
        font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
    }

    Flickable {
        id: bindScroll
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        contentWidth: width
        contentHeight: bindColumns.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: SetScroll { sys: page.sys }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                var max = Math.max(0, bindScroll.contentHeight - bindScroll.height);
                bindScroll.contentY = Math.max(0, Math.min(max, bindScroll.contentY - event.angleDelta.y));
            }
        }

    RowLayout {
        id: bindColumns
        width: bindScroll.width - 12
        spacing: 26

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            spacing: 9

            Head { text: page.sys.tr("Pill") }
            BindRow { bindId: "pillLauncher";  label: page.sys.tr("App launcher") }
            BindRow { bindId: "launchpad";     label: page.sys.tr("Launchpad (app grid)") }
            BindRow { bindId: "overview";      label: page.sys.tr("Workspace overview") }
            BindRow { bindId: "pillControls";  label: page.sys.tr("Quick Settings") }
            BindRow { bindId: "pillSettings";  label: page.sys.tr("These settings") }
            BindRow { bindId: "pillShortcuts"; label: page.sys.tr("Shortcuts cheat sheet") }
            BindRow { bindId: "pillWifi";      label: page.sys.tr("Network list") }
            BindRow { bindId: "pillBt";        label: page.sys.tr("Bluetooth") }
            BindRow { bindId: "pillClip";      label: page.sys.tr("Clipboard") }
            BindRow { bindId: "pillPower";     label: page.sys.tr("Power menu") }
            BindRow { bindId: "pillRecord";    label: page.sys.tr("Screen recording") }
            BindRow { bindId: "voxDictate";    label: page.sys.tr("Voice to text"); manual: true }
            BindRow { bindId: "pillNotif";     label: page.sys.tr("Notifications") }
            BindRow { bindId: "fileManager";   label: page.sys.tr("File manager") }
            BindRow { bindId: "pillVault";     label: page.sys.tr("Password manager") }
            BindRow { bindId: "backup";        label: page.sys.tr("Backup & Restore") }

            Head { text: page.sys.tr("System") }
            BindRow { bindId: "lockScreen"; label: page.sys.tr("Lock Screen") }
            BindRow { bindId: "screenOff";  label: page.sys.tr("Turn screen off") }
            BindRow { bindId: "runCommand"; label: page.sys.tr("Run a command") }
            BindRow { bindId: "pillAway";   label: page.sys.tr("Put the island away") }
            BindRow { bindId: "themeSwitch"; label: page.sys.tr("Switch theme") }
            BindRow { bindId: "themeSwitchAlt"; label: page.sys.tr("Wallpapers (alternate)") }

            Head { text: page.sys.tr("Workspaces") }
            Repeater {
                model: 10
                BindRow {
                    required property int index
                    bindId: "workspace" + (index + 1)
                    label: page.sys.tr("Switch to workspace") + " " + (index + 1)
                }
            }
            BindRow { bindId: "workspaceNext"; label: page.sys.tr("Next workspace"); manual: true }
            BindRow { bindId: "workspacePrevious"; label: page.sys.tr("Previous workspace"); manual: true }

            Head { text: page.sys.tr("Media keys") }
            BindRow { bindId: "volumeUp"; label: page.sys.tr("Volume up"); manual: true }
            BindRow { bindId: "volumeDown"; label: page.sys.tr("Volume down"); manual: true }
            BindRow { bindId: "volumeMute"; label: page.sys.tr("Mute audio"); manual: true }
            BindRow { bindId: "micMute"; label: page.sys.tr("Mute microphone"); manual: true }
            BindRow { bindId: "brightnessUp"; label: page.sys.tr("Brightness up"); manual: true }
            BindRow { bindId: "brightnessDown"; label: page.sys.tr("Brightness down"); manual: true }
            BindRow { bindId: "mediaNext"; label: page.sys.tr("Next track"); manual: true }
            BindRow { bindId: "mediaPrevious"; label: page.sys.tr("Previous track"); manual: true }
            BindRow { bindId: "mediaPlay"; label: page.sys.tr("Play"); manual: true }
            BindRow { bindId: "mediaPause"; label: page.sys.tr("Pause"); manual: true }
            BindRow { bindId: "mediaNextAlt"; label: page.sys.tr("Next track (alternate)"); manual: true }
            BindRow { bindId: "mediaPreviousAlt"; label: page.sys.tr("Previous track (alternate)"); manual: true }

            Head { text: page.sys.tr("Laptop lid") }
            BindRow { bindId: "lidOn"; label: page.sys.tr("Lid closed"); manual: true }
            BindRow { bindId: "lidOff"; label: page.sys.tr("Lid opened"); manual: true }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            spacing: 9

            Head { text: page.sys.tr("Applications") }
            BindRow { bindId: "terminal";       label: page.sys.tr("Terminal") }
            BindRow { bindId: "processViewer";  label: page.sys.tr("Process viewer") }
            BindRow { bindId: "browser";        label: page.sys.tr("Browser") }
            BindRow { bindId: "fileManagerTui"; label: page.sys.tr("Files (TUI)") }
            BindRow { bindId: "notes";          label: page.sys.tr("Text editor") }
            BindRow { bindId: "crush";          label: page.sys.tr("Crush") }
            BindRow { bindId: "music";          label: page.sys.tr("Music player") }
            BindRow { bindId: "mail";           label: page.sys.tr("Proton Mail") }
            BindRow { bindId: "mailKey";        label: page.sys.tr("Proton Mail (mail key)"); manual: true }
            BindRow { bindId: "x";              label: page.sys.tr("X") }
            BindRow { bindId: "xPost";          label: page.sys.tr("Compose post on X") }
            BindRow { bindId: "nightlight";     label: page.sys.tr("Night light") }
            BindRow { bindId: "screenshot";     label: page.sys.tr("Screenshot") }
            BindRow { bindId: "screenshotKey";  label: page.sys.tr("Screenshot (Print)"); manual: true }

            Head { text: page.sys.tr("Windows") }
            BindRow { bindId: "closeWindow"; label: page.sys.tr("Close window") }
            BindRow { bindId: "fullscreen";  label: page.sys.tr("Fullscreen") }
            BindRow { bindId: "floatToggle"; label: page.sys.tr("Floating window") }
            BindRow { bindId: "floatCenter"; label: page.sys.tr("Float & centre") }
            BindRow { bindId: "toggleSplit"; label: page.sys.tr("Toggle split") }
            BindRow { bindId: "closeMouse"; label: page.sys.tr("Close with middle click"); manual: true }
            BindRow { bindId: "dragWindow"; label: page.sys.tr("Drag window"); manual: true }
            BindRow { bindId: "resizeWindowMouse"; label: page.sys.tr("Resize window with mouse"); manual: true }

            Head { text: page.sys.tr("Window navigation") }
            BindRow { bindId: "focusLeft"; label: page.sys.tr("Focus left") }
            BindRow { bindId: "focusRight"; label: page.sys.tr("Focus right") }
            BindRow { bindId: "focusUp"; label: page.sys.tr("Focus up") }
            BindRow { bindId: "focusDown"; label: page.sys.tr("Focus down") }
            BindRow { bindId: "moveLeft"; label: page.sys.tr("Move window left") }
            BindRow { bindId: "moveRight"; label: page.sys.tr("Move window right") }
            BindRow { bindId: "moveUp"; label: page.sys.tr("Move window up") }
            BindRow { bindId: "moveDown"; label: page.sys.tr("Move window down") }
            BindRow { bindId: "resizeLeft"; label: page.sys.tr("Decrease width") }
            BindRow { bindId: "resizeRight"; label: page.sys.tr("Increase width") }
            BindRow { bindId: "resizeUp"; label: page.sys.tr("Decrease height") }
            BindRow { bindId: "resizeDown"; label: page.sys.tr("Increase height") }

            Head { text: page.sys.tr("Workspaces") }
            BindRow { bindId: "emptyWorkspace";   label: page.sys.tr("Empty workspace") }
            Repeater {
                model: 10
                BindRow {
                    required property int index
                    bindId: "moveWorkspace" + (index + 1)
                    label: page.sys.tr("Move to workspace") + " " + (index + 1)
                }
            }
            BindRow { bindId: "specialWorkspace"; label: page.sys.tr("Scratchpad") }
            BindRow { bindId: "packWorkspaces";   label: page.sys.tr("Pack workspaces") }
        }
    }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 2
        spacing: 12

        Item { Layout.fillWidth: true }

        SetButton {
            sys: page.sys
            text: page.sys.tr("Reset")
            onClicked: page.resetBinds()
        }

        SetButton {
            sys: page.sys
            text: page.sys.tr("Apply")
            primary: true
            enabled: page.dirty
            onClicked: page.applyBinds()
        }
    }
}
