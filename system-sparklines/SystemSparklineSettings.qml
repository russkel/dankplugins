import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "metrics.js" as Metrics
import "colormap.js" as Colormap

PluginSettings {
    id: root
    pluginId: "systemSparklines"

    // Auto-seed one variant per metric so the per-metric widgets appear in the
    // DankBar add-widget picker. Idempotent; reads variants fresh to avoid staleness.
    property bool _seeded: false
    function ensureSeeded() {
        if (root._seeded || !pluginService)
            return;
        root._seeded = true;
        const current = pluginService.getPluginVariants(root.pluginId) || [];
        const have = {};
        for (let i = 0; i < current.length; i++)
            have[current[i].metric] = true;
        for (let j = 0; j < Metrics.METRIC_IDS.length; j++) {
            const m = Metrics.METRIC_IDS[j];
            if (!have[m])
                createVariant(Metrics.metric(m).label, { metric: m });
        }
    }
    Component.onCompleted: ensureSeeded()
    onPluginServiceChanged: ensureSeeded()

    StyledText {
        width: parent.width
        text: "System Sparklines"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }
    StyledText {
        width: parent.width
        text: "One chart widget per metric appears in Settings → DankBar. Configure each metric below."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    // --- Global appearance ---
    SelectionSetting {
        settingKey: "verticalPadding"
        label: "Vertical padding"
        description: "Empty space above/below the plot (px)."
        options: [{label: "0", value: "0"}, {label: "1", value: "1"}, {label: "3", value: "3"}, {label: "6", value: "6"}]
        defaultValue: "1"
    }

    StyledText {
        width: parent.width
        text: "Per-metric"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    Repeater {
        model: Metrics.METRIC_IDS

        delegate: StyledRect {
            id: card
            required property string modelData
            width: parent ? parent.width : 0
            height: col.implicitHeight + Theme.spacingM * 2
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            // Controlled-toggle backing state (DankToggle does not self-update `checked`).
            property bool vIcon: root.loadValue(card.modelData + "_showIcon", true)
            property bool vValue: root.loadValue(card.modelData + "_showValue", true)
            property bool vGrid: root.loadValue(card.modelData + "_grid", false)

            Column {
                id: col
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingS

                Row {
                    spacing: Theme.spacingS
                    DankIcon {
                        name: Metrics.metric(card.modelData).icon
                        size: Theme.iconSize
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    StyledText {
                        text: Metrics.metric(card.modelData).label
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                DankToggle {
                    width: parent.width
                    text: "Show icon"
                    checked: card.vIcon
                    onToggled: c => { card.vIcon = c; root.saveValue(card.modelData + "_showIcon", c); }
                }
                DankToggle {
                    width: parent.width
                    text: "Show value"
                    checked: card.vValue
                    onToggled: c => { card.vValue = c; root.saveValue(card.modelData + "_showValue", c); }
                }
                DankToggle {
                    width: parent.width
                    text: "Grid"
                    checked: card.vGrid
                    onToggled: c => { card.vGrid = c; root.saveValue(card.modelData + "_grid", c); }
                }
                DankDropdown {
                    id: styleDrop
                    width: parent.width
                    text: "Chart style"
                    options: ["line", "bars"]
                    currentValue: root.loadValue(card.modelData + "_chartStyle", "line")
                    onValueChanged: value => { styleDrop.currentValue = value; root.saveValue(card.modelData + "_chartStyle", value); }
                }
                DankDropdown {
                    id: cmapDrop
                    width: parent.width
                    text: "Colormap (bars)"
                    options: Colormap.COLORMAP_NAMES
                    currentValue: root.loadValue(card.modelData + "_colormap", "viridis")
                    onValueChanged: value => { cmapDrop.currentValue = value; root.saveValue(card.modelData + "_colormap", value); }
                }
                DankDropdown {
                    id: barColorDrop
                    width: parent.width
                    text: "Bar color (bars)"
                    options: ["solid", "gradient"]
                    currentValue: root.loadValue(card.modelData + "_barColor", "solid")
                    onValueChanged: value => { barColorDrop.currentValue = value; root.saveValue(card.modelData + "_barColor", value); }
                }
                DankDropdown {
                    id: widthDrop
                    width: parent.width
                    text: "Chart width (px)"
                    options: ["32", "44", "64", "96", "128"]
                    currentValue: root.loadValue(card.modelData + "_width", "44")
                    onValueChanged: value => { widthDrop.currentValue = value; root.saveValue(card.modelData + "_width", value); }
                }
                DankDropdown {
                    id: windowDrop
                    width: parent.width
                    text: "Window (seconds)"
                    options: ["30", "60", "120", "300"]
                    currentValue: root.loadValue(card.modelData + "_windowSec", "60")
                    onValueChanged: value => { windowDrop.currentValue = value; root.saveValue(card.modelData + "_windowSec", value); }
                }
            }
        }
    }
}
