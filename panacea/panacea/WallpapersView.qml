pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io

//
Item {
    id: view
    property var sys

    property real pos: 0
    property int  target: 0
    Behavior on pos {
        NumberAnimation { duration: 420; easing.type: Easing.OutQuint }
    }
    onTargetChanged: view.pos = view.target

    property string applying: ""
    property string flying: ""
    property string flyingThumb: ""
    property bool userScrolled: false

    property string mode: "still"
    property real wheelAcc: 0
    readonly property bool live: view.mode === "live"
    readonly property bool open: view.sys.wallsOpen && view.applying.length === 0

    readonly property int cardW: Math.round(Math.min(width * 0.44, 760))
    readonly property int cardH: Math.round(cardW * 9 / 16)
    readonly property real step: cardW * 0.62

    ListModel { id: walls }

    focus: true
    Component.onCompleted: {
        reload(); view.target = 0; forceActiveFocus(); warmDelay.restart();
    }

    Keys.onEscapePressed: view.sys.closeWalls()
    Keys.onLeftPressed:   view.move(-1)
    Keys.onRightPressed:  view.move(1)
    Keys.onUpPressed:     view.move(-1)
    Keys.onDownPressed:   view.move(1)
    Keys.onReturnPressed: view.activate()
    Keys.onEnterPressed:  view.activate()
    Keys.onSpacePressed:  view.activate()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Home) { view.target = 0; event.accepted = true; }
        else if (event.key === Qt.Key_End) {
            view.target = Math.max(0, walls.count - 1); event.accepted = true;
        }
    }

    function move(d) {
        if (walls.count === 0) return;
        view.userScrolled = true;
        view.target = Math.max(0, Math.min(walls.count - 1, view.target + d));
    }
    function activate() {
        if (view.target < 0 || view.target >= walls.count) return;
        var w = walls.get(view.target);
        if (w.wActive) { view.sys.closeWalls(); return; }
        view.flyingThumb = w.wThumb;
        view.apply(w.wPath);
    }

    function applyRows(rows, act) {
        var first = walls.count === 0;
        for (var i = 0; i < rows.length; i++) {
            if (i < walls.count) walls.set(i, rows[i]);
            else                 walls.append(rows[i]);
        }
        while (walls.count > rows.length) walls.remove(walls.count - 1);
        if (view.target >= walls.count) {
            view.target = Math.max(0, walls.count - 1);
        }
    }

    //
    function reload(liveOverride) {
        var isLive = liveOverride === undefined ? view.live : liveOverride;
        var rows = ((isLive ? view.sys.liveList : view.sys.wallList) || []).slice();
        if (!isLive) rows.sort(function(a, b) {
            function priority(w) { return /^nothing/i.test(w.wName) ? 0 : 1; }
            return priority(a) - priority(b);
        });
        var act = -1;
        for (var i = 0; i < rows.length; i++) if (rows[i].wActive) act = i;
        view.applyRows(rows, act);
    }
    Connections {
        target: view.sys
        function onWallListChanged() { if (!view.live) view.reload(); }
        function onLiveListChanged() { if (view.live)  view.reload(); }
    }
    onModeChanged: {
        var isLive = view.mode === "live";
        view.userScrolled = false;
        view.reload(isLive);
        view.target = 0;
        if (isLive) liveWarmDelay.restart();
    }

    Process {
        id: pWarm
        command: ["sh", "-c", view.sys.scriptDir + "/themes.sh warm"]
        onRunningChanged: {
            if (running) warmPoll.restart();
            else { warmPoll.stop(); view.sys.refreshWalls(); }
        }
    }
    Timer {
        id: warmPoll
        interval: 2500
        repeat: true
        onTriggered: if (view.sys.wallsOpen) view.sys.refreshWalls();
                     else pWarm.running = false;
    }
    Timer {
        id: warmDelay
        interval: 900
        onTriggered: pWarm.running = true
    }

    Process {
        id: pLiveWarm
        command: ["bash", Quickshell.env("HOME")
                          + "/.config/hypr/scripts/live_wallpaper.sh", "warm"]
        onRunningChanged: if (!running) view.sys.refreshLiveWalls()
    }
    Timer {
        id: liveWarmDelay
        interval: 700
        onTriggered: pLiveWarm.running = true
    }

    Process {
        id: pSet
        onRunningChanged: {
            if (running) return;
            view.sys.endThemeFade();
            closeAfter.restart();
        }
    }
    Timer {
        id: closeAfter
        interval: 560
        onTriggered: view.sys.closeWalls()
    }
    Connections {
        target: view.sys
        function onWallsOpenChanged() {
            if (view.sys.wallsOpen) { view.userScrolled = false; view.target = 0; }
            else                    resetAfterClose.restart();
        }
    }
    function jumpToActive() {
        for (var i = 0; i < walls.count; i++) {
            if (walls.get(i).wActive) { view.target = i; view.pos = i; return; }
        }
    }
    Timer {
        id: resetAfterClose
        interval: 400
        onTriggered: { view.applying = ""; view.flying = ""; view.flyingThumb = ""; }
    }

    function apply(path) {
        view.applying = path;
        view.flying = path;
        view.sys.startThemeFade();
        pSet.command = view.live
            ? ["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/live_wallpaper.sh",
               "set", path]
            : ["sh", "-c", view.sys.scriptDir + "/themes.sh set \"$1\"", "_", path];
        pSet.running = true;
    }

    function pretty(n) {
        var s = String(n).replace(/_/g, " ");
        return s.charAt(0).toUpperCase() + s.slice(1);
    }

    Rectangle {
        id: morph
        color: "#111112"
        z: -1
        x:      view.open ? 0 : view.sys.pillRectX
        y:      view.open ? 0 : view.sys.pillRectY
        width:  view.open ? view.width  : Math.max(8, view.sys.pillRectW)
        height: view.open ? view.height : Math.max(8, view.sys.pillRectH)
        radius: view.open ? 0 : Math.min(width, height) / 2
        opacity: view.open ? 0.97 : 0.96
        visible: view.sys.wallsOpen

        Behavior on x      { NumberAnimation { duration: view.sys.animMs; easing.type: Easing.OutQuint } }
        Behavior on y      { NumberAnimation { duration: view.sys.animMs; easing.type: Easing.OutQuint } }
        Behavior on width  { NumberAnimation { duration: view.sys.animMs; easing.type: Easing.OutQuint } }
        Behavior on height { NumberAnimation { duration: view.sys.animMs; easing.type: Easing.OutQuint } }
        Behavior on radius { NumberAnimation { duration: view.sys.animMs; easing.type: Easing.OutQuint } }
        Behavior on opacity { NumberAnimation { duration: view.sys.animMs } }
    }

    Grid {
        anchors.right: parent.right
        anchors.rightMargin: Math.round(view.width * 0.07)
        anchors.top: parent.top
        anchors.topMargin: Math.round(view.height * 0.075)
        columns: 12; spacing: 5
        opacity: view.open ? 0.38 : 0
        Repeater {
            model: 36
            Rectangle {
                required property int index
                width: 3; height: 3; radius: 1.5
                color: index === 35 ? "#e23b3b" : "#77777a"
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: view.sys.closeWalls()
        onWheel: wheel => {
            var d = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : -wheel.angleDelta.x;
            if (d === 0) return;
            if ((d > 0) !== (view.wheelAcc > 0)) view.wheelAcc = 0;
            view.wheelAcc = Math.max(-240, Math.min(240, view.wheelAcc + d));
            if (wheelCool.running || Math.abs(view.wheelAcc) < 120) return;
            view.wheelAcc += view.wheelAcc > 0 ? -120 : 120;
            view.move(view.wheelAcc > 0 ? -1 : (view.wheelAcc < 0 ? 1 : (d > 0 ? -1 : 1)));
            wheelCool.restart();
        }
    }

    Timer { id: wheelCool; interval: 130 }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.round(view.height * 0.075)
        spacing: 5
        opacity: view.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: view.sys.animMs } }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: view.live ? view.sys.tr("Live wallpapers") : view.sys.tr("Wallpapers")
            color: "#f2f2f2"
            font {
                family: view.sys.fontFam
                pixelSize: view.sys.fontSize + 12; bold: true
            }
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 12
            spacing: 8

            Repeater {
                model: [
                    { m: "still", t: view.sys.tr("Wallpapers") },
                    { m: "live",  t: view.sys.tr("Live wallpapers") }
                ]
                Rectangle {
                    id: tabBtn
                    required property var modelData
                    readonly property bool picked: view.mode === tabBtn.modelData.m

                    Layout.preferredWidth: tabTxt.implicitWidth + 34
                    Layout.preferredHeight: 38
                    radius: 12
                    color: tabBtn.picked ? "#e8e8e8" : (tabMa.containsMouse ? "#353538" : "#222224")
                    border.color: tabBtn.picked ? "#e8e8e8" : "#39393c"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 160 } }
                    Behavior on border.color { ColorAnimation { duration: 160 } }

                    Text {
                        id: tabTxt
                        anchors.centerIn: parent
                        text: tabBtn.modelData.t
                        color: tabBtn.picked ? "#171719" : "#b8b8bb"
                        font {
                            family: view.sys.fontFam
                            pixelSize: view.sys.fontSize - 2
                            bold: tabBtn.picked
                        }
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }
                    MouseArea {
                        id: tabMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: view.mode = tabBtn.modelData.m
                    }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            text: walls.count
                  ? (view.target + 1) + " / " + walls.count
                  : (view.live ? view.sys.liveListReady : view.sys.wallListReady)
                    ? (view.live ? view.sys.tr("The live wallpaper folder is empty")
                                 : view.sys.tr("No wallpapers found"))
                    : view.sys.tr("Reading…")
            color: view.sys.colMuted
            font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 2 }
        }
    }

    Item {
        id: reel
        anchors.fill: parent
        opacity: view.open ? 1 : 0
        scale: view.open ? 1 : 0.94
        Behavior on opacity { NumberAnimation { duration: view.sys.animMs } }
        Behavior on scale {
            NumberAnimation { duration: view.sys.animMs; easing.type: Easing.OutQuint }
        }

        Repeater {
            model: walls

            Item {
                id: card
                required property int    index
                required property string wName
                required property string wThumb
                required property bool   wActive
                required property bool   wOwn
                required property string wPath

                readonly property real d: card.index - view.pos
                readonly property real ad: Math.abs(card.d)
                readonly property bool centered: card.ad < 0.5

                width: view.cardW
                height: view.cardH
                x: reel.width / 2 - width / 2 + card.d * view.step
                y: reel.height / 2 - height / 2 + 22
                scale: Math.max(0.5, 1 - card.ad * 0.16)
                opacity: Math.max(0, 1 - card.ad * 0.34)
                visible: card.ad < 4.2
                z: Math.round(100 - card.ad * 10)

                Item {
                    id: frame
                    anchors.fill: parent
                    readonly property int r: 16
                    z: 1

                    Item {
                        id: shot
                        anchors.fill: parent
                        visible: false
                        layer.enabled: true

                        Rectangle { anchors.fill: parent; color: "#000000" }

                    Image {
                        id: img
                        width: frame.width * 1.28
                        height: frame.height
                        x: -(frame.width * 0.14) + card.d * (view.step * 0.22)
                        source: (card.ad < 5 && card.wThumb.indexOf("/") === 0)
                                ? "file://" + card.wThumb : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: Math.round(view.cardW * 1.4)
                        asynchronous: true
                        cache: true
                        smooth: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
                        }
                    }

                    Rectangle {
                        id: pulse
                        anchors.fill: parent
                        visible: img.status === Image.Loading
                        color: Qt.rgba(1, 1, 1, 0.06)
                        SequentialAnimation on opacity {
                            running: pulse.visible
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.35; duration: 620 }
                            NumberAnimation { to: 1.0;  duration: 620 }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "#000000"
                        opacity: Math.min(0.55, card.ad * 0.3)
                    }
                    }

                    Item {
                        id: cardMask
                        anchors.fill: parent
                        visible: false
                        layer.enabled: true
                        Rectangle {
                            anchors.fill: parent
                            radius: frame.r
                            color: "#ffffff"
                        }
                    }

                    MultiEffect {
                        anchors.fill: parent
                        source: shot
                        maskEnabled: true
                        maskSource: cardMask
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: frame.r
                        color: "transparent"
                        border.color: card.wActive ? "#e23b3b"
                                    : card.centered ? Qt.rgba(1, 1, 1, 0.55)
                                                    : Qt.rgba(1, 1, 1, 0.10)
                        border.width: card.centered || card.wActive ? 2 : 1
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 62
                        radius: frame.r
                        opacity: card.centered ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0) }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.72) }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 18
                            anchors.rightMargin: 14
                            anchors.bottomMargin: 4
                            spacing: 10

                            Text {
                                Layout.fillWidth: true
                                text: view.pretty(card.wName)
                                color: view.sys.colFg
                                elide: Text.ElideRight
                                font {
                                    family: view.sys.fontFam
                                    pixelSize: view.sys.fontSize + 1; bold: true
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 26
                                radius: 13
                                visible: card.wActive && view.applying.length === 0
                                color: "#e23b3b"
                                Text {
                                    anchors.centerIn: parent
                                    text: String.fromCodePoint(0xF012C)
                                    color: "#ffffff"
                                    font { family: view.sys.fontFam; pixelSize: 13 }
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 26
                                radius: 13
                                visible: card.wOwn && !card.wActive
                                color: delMa.containsMouse ? view.sys.colCrit
                                                           : Qt.rgba(1, 1, 1, 0.12)
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: String.fromCodePoint(0xF01B4)
                                    color: delMa.containsMouse ? "#ffffff" : view.sys.colMuted
                                    font { family: view.sys.fontFam; pixelSize: 13 }
                                }
                                MouseArea {
                                    id: delMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: view.removeWall(card.wName)
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (card.centered) view.activate();
                        else { view.userScrolled = true; view.target = card.index; }
                    }
                }
            }
        }
    }

    Rectangle {
        id: burst
        visible: view.flying.length > 0
        anchors.centerIn: parent
        width: view.flying.length ? view.width : view.cardW
        height: view.flying.length ? view.height : view.cardH
        radius: view.flying.length ? 0 : 22
        clip: true
        color: "transparent"
        opacity: view.applying.length ? 1 : 0
        z: 200
        Behavior on width   { NumberAnimation { duration: 520; easing.type: Easing.OutQuint } }
        Behavior on height  { NumberAnimation { duration: 520; easing.type: Easing.OutQuint } }
        Behavior on radius  { NumberAnimation { duration: 520; easing.type: Easing.OutQuint } }
        Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }

        Image {
            id: burstThumb
            anchors.fill: parent
            source: view.flyingThumb.length ? "file://" + view.flyingThumb : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: false
            cache: true
        }
        Image {
            anchors.fill: parent
            source: view.flying.length ? "file://" + view.flying : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: view.width
            asynchronous: true
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 220 } }
        }
    }

    RowLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(view.height * 0.08)
        spacing: 22
        opacity: view.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: view.sys.animMs } }

        Repeater {
            model: [
                { k: "← →",   t: view.sys.tr("choose") },
                { k: "Enter", t: view.sys.tr("apply") },
                { k: "Esc",   t: view.sys.tr("close") }
            ]
            RowLayout {
                id: rowlayout
                required property var modelData
                spacing: 7
                Rectangle {
                    Layout.preferredWidth: hintKey.implicitWidth + 16
                    Layout.preferredHeight: 26
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.10)
                    Text {
                        id: hintKey
                        anchors.centerIn: parent
                        text: rowlayout.modelData.k
                        color: view.sys.colFg
                        font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 3 }
                    }
                }
                Text {
                    text: rowlayout.modelData.t
                    color: view.sys.colMuted
                    font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 3 }
                }
            }
        }

        Rectangle {
            visible: view.live
            Layout.preferredWidth: Math.max(196, liveRow.implicitWidth + 24)
            Layout.preferredHeight: 38
            radius: 13
            color: folderMa.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.06)
            border.color: folderMa.containsMouse ? view.sys.colOn : view.sys.colLine
            border.width: 1
            Behavior on color { ColorAnimation { duration: 160 } }
            Behavior on border.color { ColorAnimation { duration: 160 } }

            RowLayout {
                id: liveRow
                anchors.centerIn: parent
                spacing: 8
                Text {
                    text: String.fromCodePoint(0xF024B)
                    color: folderMa.containsMouse ? view.sys.colOn : view.sys.colMuted
                    font { family: view.sys.fontFam; pixelSize: 16 }
                }
                Text {
                    text: view.sys.tr("Live wallpaper folder")
                    color: folderMa.containsMouse ? view.sys.colFg : view.sys.colMuted
                    font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 3 }
                }
            }
            MouseArea {
                id: folderMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: view.sys.openLiveFolder()
            }
        }

        Rectangle {
            visible: !view.live
            Layout.preferredWidth: Math.max(156, ownRow.implicitWidth + 24)
            Layout.preferredHeight: 38
            radius: 13
            color: addMa.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.06)
            border.color: addMa.containsMouse ? view.sys.colOn : view.sys.colLine
            border.width: 1
            Behavior on color { ColorAnimation { duration: 160 } }
            Behavior on border.color { ColorAnimation { duration: 160 } }

            RowLayout {
                id: ownRow
                anchors.centerIn: parent
                spacing: 8
                Text {
                    text: String.fromCodePoint(0xF0415)
                    color: addMa.containsMouse ? view.sys.colOn : view.sys.colMuted
                    font { family: view.sys.fontFam; pixelSize: 16 }
                }
                Text {
                    text: view.sys.tr("Your wallpaper")
                    color: addMa.containsMouse ? view.sys.colFg : view.sys.colMuted
                    font { family: view.sys.fontFam; pixelSize: view.sys.fontSize - 3 }
                }
            }
            MouseArea {
                id: addMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: view.sys.startWallpaperPick()
            }
        }
    }

    Process { id: pDel }
    function removeWall(name) {
        pDel.command = ["sh", "-c",
            view.sys.scriptDir + "/themes.sh del \"$1\"", "_", name];
        pDel.running = true;
        delTimer.restart();
    }
    Timer {
        id: delTimer
        interval: 250
        onTriggered: view.sys.refreshWalls()
    }

    Process {
        id: pAdd
        onRunningChanged: if (!running) { view.sys.wallpaperPick = ""; view.sys.refreshWalls(); }
    }
    onVisibleChanged: if (visible) view.takePick()
    function takePick() {
        if (view.sys.wallpaperPick.length === 0) return;
        pAdd.command = ["sh", "-c",
            view.sys.scriptDir + "/themes.sh add \"$1\"", "_", view.sys.wallpaperPick];
        pAdd.running = true;
    }
    Connections {
        target: view.sys
        function onWallpaperPickChanged() { view.takePick(); }
    }
}
