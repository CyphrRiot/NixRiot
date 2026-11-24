pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: page

    property var sys

    function checkedLabel() {
        if (!page.sys.updCheckedAt) return "";
        return page.sys.tr("checked ")
             + new Date(page.sys.updCheckedAt).toLocaleTimeString(Qt.locale(), "HH:mm");
    }

    function stepName(st) {
        return st === "download"      ? page.sys.tr("downloading")
             : st === "selfupdate"    ? page.sys.tr("updating the updater")
             : st === "backup"        ? page.sys.tr("saving settings")
             : st === "install"       ? page.sys.tr("installing")
             : st === "greeter"       ? page.sys.tr("login screen")
             : st === "restore"       ? page.sys.tr("restoring settings")
             : st === "voxtype_model" ? page.sys.tr("downloading voice model")
             : st === "restart"       ? page.sys.tr("restarting")
             : page.sys.tr("preparing");
    }

    Layout.fillWidth: true
    spacing: 12

    SetCard {
        sys: page.sys

        SetLabel { sys: page.sys; text: page.sys.tr("Version") }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: page.sys.updBusy
                          ? page.sys.tr("Updating…") + " " + page.stepName(page.sys.updStep)
                          : page.sys.updChecking ? page.sys.tr("Checking…")
                          : page.sys.updateAvailable ? page.sys.tr("A new version is available")
                          : page.sys.updStatus === "current" ? page.sys.tr("You are on the latest version")
                          : page.sys.updStatus === "offline" ? page.sys.tr("Cannot reach GitHub")
                          : page.sys.updStatus === "unknown" ? page.sys.tr("Version unknown: this was not installed by the installer")
                          : page.sys.tr("Checking…")
                    color: page.sys.updateAvailable ? page.sys.colOn : page.sys.colFg
                    wrapMode: Text.WordWrap
                    font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 1 }
                }
                Text {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: page.sys.updError.length ? page.sys.updErrorText
                        : page.sys.updateAvailable
                          ? "NixRiot " + (page.sys.updCurrent.length
                                          ? page.sys.updCurrent : page.sys.tr("version unknown"))
                            + " → " + (page.sys.updLatest.length
                                       ? page.sys.updLatest : page.sys.tr("version unknown"))
                            + (page.sys.updSubject.length ? " · " + page.sys.updSubject : "")
                        : "NixRiot " + (page.sys.updCurrent.length
                                        ? page.sys.updCurrent : page.sys.tr("version unknown"))
                          + (page.sys.updStatus === "current" && page.sys.updCheckedAt
                             ? " · " + page.checkedLabel() : "")
                    color: page.sys.updError.length ? page.sys.colCrit : page.sys.colMuted
                    wrapMode: Text.WordWrap
                    font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
                }
            }

            Rectangle {
                Layout.preferredWidth: Math.max(104, checkRow.implicitWidth + 24)
                Layout.preferredHeight: 32
                radius: 10
                visible: !page.sys.updBusy
                color: checkMa.containsMouse
                       ? Qt.rgba(page.sys.colFg.r, page.sys.colFg.g, page.sys.colFg.b, 0.14)
                       : Qt.rgba(page.sys.colFg.r, page.sys.colFg.g, page.sys.colFg.b, 0.06)
                Behavior on color { ColorAnimation { duration: page.sys.animFade } }

                RowLayout {
                    id: checkRow
                    anchors.centerIn: parent
                    spacing: 6

                    Glyph {
                        id: checkSpin
                        visible: page.sys.updChecking
                        glyph: String.fromCodePoint(0xF0450)   // md-refresh
                        color: page.sys.colOn
                        fontFam: page.sys.fontFam
                        size: 13

                        RotationAnimator {
                            target: checkSpin
                            running: page.sys.updChecking
                            from: 0; to: 360
                            duration: 900
                            loops: Animation.Infinite
                        }
                        onVisibleChanged: if (!visible) checkSpin.rotation = 0
                    }

                    Text {
                        text: page.sys.updChecking ? page.sys.tr("Checking…")
                                                   : page.sys.updCheckedAt
                                                     ? page.sys.tr("Check again")
                                                     : page.sys.tr("Check")
                        color: page.sys.updChecking ? page.sys.colFg : page.sys.colMuted
                        font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3 }
                    }
                }
                MouseArea {
                    id: checkMa
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !page.sys.updChecking
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.sys.checkUpdate()
                }
            }

            Rectangle {
                Layout.preferredWidth: Math.max(120, updRow.implicitWidth + 24)
                Layout.preferredHeight: 32
                radius: 10
                visible: page.sys.updateAvailable || page.sys.updBusy
                opacity: page.sys.updBusy ? 0.6 : 1
                color: updMa.containsMouse && !page.sys.updBusy
                       ? Qt.rgba(page.sys.colOn.r, page.sys.colOn.g, page.sys.colOn.b, 0.34)
                       : Qt.rgba(page.sys.colOn.r, page.sys.colOn.g, page.sys.colOn.b, 0.22)
                border.width: 1
                border.color: page.sys.colOn
                Behavior on color { ColorAnimation { duration: page.sys.animFade } }

                Text {
                    anchors.centerIn: parent
                    text: page.sys.updBusy ? page.sys.tr("Working…") : page.sys.tr("Update")
                    color: page.sys.colFg
                    font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 3; bold: true }
                }
                MouseArea {
                    id: updMa
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !page.sys.updBusy
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.sys.applyUpdate()
                }
            }
        }

        //
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            visible: page.sys.updBusy
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 6
                radius: 3
                color: Qt.rgba(page.sys.colFg.r, page.sys.colFg.g, page.sys.colFg.b, 0.10)

                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    width: parent.width * Math.max(0.04, page.sys.updProgress / 100)
                    color: page.sys.colOn
                    Behavior on width {
                        NumberAnimation { duration: page.sys.animMs; easing.type: Easing.OutQuint }
                    }
                }
            }

            RowLayout {
                    id: updRow
                Layout.fillWidth: true
                spacing: 6
                Text {
                    Layout.fillWidth: true
                    text: page.stepName(page.sys.updStep)
                    color: page.sys.colMuted
                    elide: Text.ElideRight
                    font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
                }
                Text {
                    text: Math.max(1, page.sys.updProgress) + "%"
                    color: page.sys.colMuted
                    font { family: page.sys.fontFam; pixelSize: page.sys.fontSize - 4 }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: page.sys.tr("Settings, key bindings and wallpapers stay put: they are moved aside before the install and put back after.")
            color: page.sys.colMuted
            wrapMode: Text.WordWrap
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
        }
    }
}
