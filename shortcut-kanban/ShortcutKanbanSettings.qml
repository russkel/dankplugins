import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "shortcutKanban"

    StyledText {
        width: parent.width
        text: "Shortcut Kanban Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StringSetting {
        settingKey: "apiToken"
        label: "API Token"
        description: "Leave blank to use the SHORTCUT_API_TOKEN environment variable. If set here, it is stored in settings.json in plaintext."
        placeholder: "(using SHORTCUT_API_TOKEN)"
        defaultValue: ""
    }

    StringSetting {
        settingKey: "query"
        label: "Search Query (override)"
        description: "A Shortcut search query. Leave blank for the default: your stories in currently-started iterations."
        placeholder: "owner:you !is:done"
        defaultValue: ""
    }

    SelectionSetting {
        settingKey: "backgroundIntervalMin"
        label: "Background Refresh"
        description: "How often the pill counts refresh while the popout is closed."
        options: [
            {label: "1 minute", value: "1"},
            {label: "5 minutes", value: "5"},
            {label: "15 minutes", value: "15"}
        ]
        defaultValue: "5"
    }
}
