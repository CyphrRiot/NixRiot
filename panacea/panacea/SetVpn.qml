import QtQuick
import QtQuick.Layouts
ColumnLayout {
    id: page
    property var sys
    Layout.fillWidth: true
    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: page.sys.colMuted; text: page.sys.tr("Choose a client or profile. Your selection is saved without connecting.") }
    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: page.sys.colMuted; text: page.sys.tr("The country chip in the island opens the selected client. The power button on the island VPN page connects and disconnects it.") }
    VpnView { sys: page.sys; settingsMode: true; Layout.fillWidth: true; Layout.preferredHeight: implicitHeight }
}
