pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

Item {
    id: view

    property var sys
    property var lines: []
    readonly property string version: view.lines.length ? String(view.lines[0]).substring(0, 7) : ""
    readonly property var changes: view.lines.slice(1)

    readonly property int maxListH: Math.max(120, view.height - 380)
    readonly property int fontPx: view.changes.length > 9 ? view.sys.fontSize - 3
                                                          : view.sys.fontSize - 2

    //
    //

    component DepsNotice: Rectangle {
        id: notice
        property string text: ""
        property string cmd: ""
        property bool shown: false
        property color tone: view.sys.colMuted

        Layout.fillWidth: true
        visible: notice.shown
        implicitHeight: noticeCol.implicitHeight + 24
        radius: 14
        color: Qt.rgba(notice.tone.r, notice.tone.g, notice.tone.b, 0.10)
        border.width: 1
        border.color: Qt.rgba(notice.tone.r, notice.tone.g, notice.tone.b, 0.35)

        ColumnLayout {
            id: noticeCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 5

            Text {
                Layout.fillWidth: true
                text: notice.text
                color: view.sys.colFg
                wrapMode: Text.WordWrap
                font { family: view.sys.fontBody; pixelSize: view.fontPx; bold: true }
            }

            Text {
                Layout.fillWidth: true
                text: notice.cmd
                color: view.sys.colMuted
                wrapMode: Text.WrapAnywhere
                font { family: view.sys.fontFam; pixelSize: view.fontPx - 1 }
            }

            Text {
                Layout.fillWidth: true
                text: noticeMa.containsMouse ? view.sys.tr("Click to copy")
                                             : view.sys.tr("Copy the command")
                color: view.sys.colOn
                font { family: view.sys.fontBody; pixelSize: view.fontPx - 2 }
            }
        }

        MouseArea {
            id: noticeMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: view.sys.copyText(notice.cmd)
        }
    }

    function changeText(subject) {
        if (view.sys.isEn) return subject;
        var t = subject;
        return t !== undefined ? t : subject;
    }

    anchors.fill: parent

    MouseArea { anchors.fill: parent }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(620, parent.width - 80)
        height: Math.min(body.implicitHeight + 56, parent.height - 60)
        radius: 26
        color: view.sys.colBg
        border.width: 1
        border.color: Qt.rgba(view.sys.colFg.r, view.sys.colFg.g, view.sys.colFg.b, 0.12)

        opacity: 0
        transform: Translate { id: rise; y: 24 }
        Component.onCompleted: { card.opacity = 1; rise.y = 0; }
        Behavior on opacity { NumberAnimation { duration: view.sys.animMs } }

        ColumnLayout {
            id: body
            anchors.fill: parent
            anchors.margins: 28
            spacing: 16

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Image {
                    Layout.alignment: Qt.AlignHCenter
                    source: Quickshell.env("HOME") + "/.config/panacea/assets/logo-128.png"
                    sourceSize.width: 72
                    sourceSize.height: 72
                    fillMode: Image.PreserveAspectFit
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: view.sys.tr("NixRiot has been updated")
                    color: view.sys.colFg
                    font { family: view.sys.fontDisplay; pixelSize: view.sys.fontSize + 8 }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    visible: view.version.length > 0
                    text: view.sys.tr("Build") + " " + view.version
                    color: view.sys.colMuted
                    font { family: view.sys.fontBody; pixelSize: view.sys.fontSize - 3 }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Math.min(changeCol.implicitHeight + 28, view.maxListH + 28)
                radius: 18
                color: Qt.rgba(view.sys.colFg.r, view.sys.colFg.g, view.sys.colFg.b, 0.045)

                Flickable {
                    id: changesFlick
                    anchors.fill: parent
                    anchors.margins: 14
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    contentHeight: changeCol.implicitHeight
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        contentItem: Rectangle { radius: 2; color: Qt.rgba(1, 1, 1, 0.22) }
                    }

                    WheelHandler {
                        onWheel: event => {
                            var most = Math.max(0, changesFlick.contentHeight - changesFlick.height);
                            changesFlick.contentY = Math.max(0,
                                Math.min(most, changesFlick.contentY - event.angleDelta.y));
                        }
                    }

                    ColumnLayout {
                        id: changeCol
                        width: changesFlick.width
                        spacing: 7

                        Repeater {
                            model: view.changes

                            RowLayout {
                                id: rowlayo
                                required property string modelData
                                Layout.fillWidth: true
                                spacing: 10

                                Rectangle {
                                    Layout.alignment: Qt.AlignTop
                                    Layout.topMargin: 6
                                    Layout.preferredWidth: 5; Layout.preferredHeight: 5; radius: 3
                                    color: view.sys.colOn
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: view.changeText(rowlayo.modelData)
                                    color: view.sys.colFg
                                    wrapMode: Text.WordWrap
                                    font { family: view.sys.fontBody; pixelSize: view.fontPx }
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: view.changes.length === 0
                            horizontalAlignment: Text.AlignHCenter
                            text: view.sys.tr("The change list is unavailable")
                            color: view.sys.colMuted
                            font { family: view.sys.fontBody; pixelSize: view.fontPx }
                        }
                    }
                }
            }

            DepsNotice {
                text: view.sys.tr("Some packages are missing")
                cmd: "sudo pacman -S --needed " + view.sys.missingDeps
                shown: view.sys.missingDeps.length > 0
                tone: view.sys.colCrit
            }

            DepsNotice {
                text: view.sys.tr("No longer needed")
                cmd: "sudo pacman -Rns " + view.sys.obsoleteDeps
                shown: view.sys.obsoleteDeps.length > 0
                tone: view.sys.colMuted
            }

            DepsNotice {
                text: view.sys.tr("Your edits were kept (new versions next to them — *.panacea-new)")
                cmd: view.sys.keptEdits.split("\n").join("  ")
                shown: view.sys.keptEdits.length > 0
                tone: view.sys.colOn
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: 14
                color: okMa.containsMouse
                       ? Qt.rgba(view.sys.colOn.r, view.sys.colOn.g, view.sys.colOn.b, 0.36)
                       : Qt.rgba(view.sys.colOn.r, view.sys.colOn.g, view.sys.colOn.b, 0.24)
                border.width: 1
                border.color: view.sys.colOn
                Behavior on color { ColorAnimation { duration: view.sys.animFade } }

                Text {
                    anchors.centerIn: parent
                    text: view.sys.tr("OK")
                    color: view.sys.colFg
                    font { family: view.sys.fontBody; pixelSize: view.sys.fontSize; bold: true }
                }
                MouseArea {
                    id: okMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: view.sys.dismissWhatsNew()
                }
            }
        }
    }

    focus: true
    Keys.onEscapePressed: view.sys.dismissWhatsNew()
    Keys.onReturnPressed: view.sys.dismissWhatsNew()
    Component.onCompleted: forceActiveFocus()
}
