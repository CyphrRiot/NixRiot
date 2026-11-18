import QtQuick
import QtQuick.Layouts
ColumnLayout {
    id: page
    property var sys
    Layout.fillWidth: true
    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: page.sys.colMuted; text: page.sys.tr("Choose a client or profile. Your selection is saved without connecting.") }
    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: page.sys.colMuted; text: page.sys.tr("Happ and NetworkManager profiles can be toggled in the island. Other clients open their own application.") }
    VpnView { sys: page.sys; settingsMode: true; Layout.fillWidth: true; Layout.preferredHeight: implicitHeight }
}
