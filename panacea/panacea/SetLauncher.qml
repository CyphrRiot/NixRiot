pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    id: page

    property var sys

    Layout.fillWidth: true
    spacing: 12

    SetCard {
        sys: page.sys

        SetToggle {
            sys: page.sys
            label: page.sys.tr("Search apps")
            sub: page.sys.tr("The list of installed apps on Super+A.")
            on: page.sys.cfg.featLauncher
            onToggled: v => { page.sys.cfg.featLauncher = v; page.sys.saveCfg(); }
        }

        SetToggle {
            sys: page.sys
            label: page.sys.tr("Launchpad")
            sub: page.sys.tr("Every app as a full-screen grid, with folders. Drop an app on another to make a folder.")
            on: page.sys.cfg.featLaunchpad
            onToggled: v => { page.sys.cfg.featLaunchpad = v; page.sys.saveCfg(); }
        }
    }

    SetCard {
        sys: page.sys

        SetLabel { sys: page.sys; text: page.sys.tr("Neighbouring pages") }

        SetToggle {
            sys: page.sys
            label: page.sys.tr("Clipboard")
            on: page.sys.cfg.featClipboard
            onToggled: v => { page.sys.cfg.featClipboard = v; page.sys.saveCfg(); }
        }

        SetToggle {
            sys: page.sys
            label: page.sys.tr("Password manager")
            on: page.sys.cfg.featVault
            onToggled: v => { page.sys.cfg.featVault = v; page.sys.saveCfg(); }
        }

        SetToggle {
            sys: page.sys
            label: page.sys.tr("Offer to save passwords from the clipboard")
            sub: page.sys.tr("A copied password can be tucked into the vault with one button.")
            on: page.sys.cfg.vaultCapture
            onToggled: v => { page.sys.cfg.vaultCapture = v; page.sys.saveCfg(); }
        }

        SetToggle {
            sys: page.sys
            label: page.sys.tr("File manager")
            on: page.sys.cfg.featFiles
            onToggled: v => { page.sys.cfg.featFiles = v; page.sys.saveCfg(); }
        }

        SetToggle {
            sys: page.sys
            label: page.sys.tr("File manager as a window")
            sub: page.sys.tr("Opens as a Hyprland window instead of an island page.")
            on: page.sys.cfg.filesWindow
            onToggled: v => { page.sys.cfg.filesWindow = v; page.sys.saveCfg(); }
        }

        SetToggle {
            sys: page.sys
            label: page.sys.tr("Calendar")
            on: page.sys.cfg.featCalendar
            onToggled: v => { page.sys.cfg.featCalendar = v; page.sys.saveCfg(); }
        }

        SetToggle {
            sys: page.sys
            label: page.sys.tr("Wallpapers")
            on: page.sys.cfg.featThemes
            onToggled: v => { page.sys.cfg.featThemes = v; page.sys.saveCfg(); }
        }
    }

    SetCard {
        sys: page.sys

        SetLabel { sys: page.sys; text: page.sys.tr("Web search and AI") }
        Text {
            Layout.fillWidth: true
            text: page.sys.tr("Any query can go to a search engine via the last row of the list. If you connect an AI, a query starting with “?” goes to it and a short answer appears right in the launcher.")
            color: page.sys.colMuted
            wrapMode: Text.WordWrap
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
        }
        SetPick {
            sys: page.sys
            label: page.sys.tr("Search engine")
            options: [
                { id: "duckduckgo", text: "DuckDuckGo" },
                { id: "google", text: "Google" },
                { id: "bing", text: "Bing" },
                { id: "brave", text: "Brave" },
                { id: "yandex", text: "Yandex" }
            ]
            value: page.sys.cfg.searchEngine
            onPicked: id => { page.sys.cfg.searchEngine = id; page.sys.saveCfg(); }
        }

        component Field: TextField {
            Layout.fillWidth: true
            color: page.sys.colFg
            placeholderTextColor: page.sys.colMuted
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 2 }
            leftPadding: 12; rightPadding: 12; topPadding: 9; bottomPadding: 9
            selectByMouse: true
            background: Rectangle {
                radius: 10
                color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1
                border.color: parent.activeFocus ? page.sys.colOn : page.sys.colLine
            }
        }
        Text {
            Layout.fillWidth: true
            text: page.sys.tr("API settings for the Chat tab in the island: an OpenAI-compatible service, model and key.")
            color: page.sys.colMuted
            wrapMode: Text.WordWrap
            font { family: page.sys.fontBody; pixelSize: page.sys.fontSize - 4 }
        }
        Field {
            placeholderText: page.sys.tr("API URL, e.g. https://api.openai.com/v1")
            text: page.sys.cfg.aiUrl
            onEditingFinished: { page.sys.cfg.aiUrl = text.trim(); page.sys.saveCfg(); }
        }
        Field {
            placeholderText: page.sys.tr("Model")
            text: page.sys.cfg.aiModel
            onEditingFinished: { page.sys.cfg.aiModel = text.trim(); page.sys.saveCfg(); }
        }
        Field {
            placeholderText: page.sys.tr("API key (not needed for local models)")
            echoMode: TextInput.Password
            text: page.sys.cfg.aiKey
            onEditingFinished: { page.sys.cfg.aiKey = text.trim(); page.sys.saveCfg(); }
        }
    }
    SetCard {
        sys: page.sys
        SetSelect {
            sys: page.sys
            label: page.sys.tr("Agent events in chat")
            value: page.sys.cfg.agentEventFilter
            options: [{id:"all", text:page.sys.tr("All")}, {id:"claude", text:"Claude"}, {id:"codex", text:"Codex"}, {id:"antigravity", text:"Antigravity"}]
            onPicked: id => { page.sys.cfg.agentEventFilter = id; page.sys.saveCfg(); }
        }
    }

}
