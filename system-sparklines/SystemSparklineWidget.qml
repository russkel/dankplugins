import QtQuick
import qs.Common
import qs.Widgets
import qs.Services
import qs.Modules.Plugins
import "metrics.js" as Metrics

PluginComponent {
    id: root

    property string variantId: ""
    property var variantData: null

    readonly property string metricId: variantData?.metric || pluginData.metric || "cpu"
    readonly property var metricDef: Metrics.metric(metricId)

    // Per-metric appearance lives in pluginData under "<metric>_<key>" (written by settings).
    function cfg(key, def) {
        const k = root.metricId + "_" + key;
        return (pluginData[k] !== undefined) ? pluginData[k] : def;
    }
    readonly property bool showIcon: cfg("showIcon", true)
    readonly property bool showValue: cfg("showValue", true)
    readonly property bool gridOn: cfg("grid", false)
    readonly property string chartStyle: cfg("chartStyle", "line")
    readonly property string colormapName: cfg("colormap", "viridis")
    readonly property string barColor: cfg("barColor", "solid")
    readonly property int chartWidth: parseInt(cfg("width", "44"))
    readonly property int windowSec: parseInt(cfg("windowSec", "60"))
    // Samples are taken every 3s, so the buffer holds windowSec/3 points.
    readonly property int bufferCap: Math.max(2, Math.round(windowSec / 3))
    readonly property real vPad: pluginData.verticalPadding !== undefined ? parseInt(pluginData.verticalPadding) : 1

    readonly property bool degraded: !DgopService.dgopAvailable
    readonly property color accent: metricId === "cputemp" ? Theme.warning
                                    : metricId === "network" ? Theme.success
                                    : metricId === "disk" ? Theme.secondary
                                    : Theme.primary

    readonly property real currentValue: {
        switch (metricId) {
        case "memory": return DgopService.memoryUsage;
        case "cputemp": return DgopService.cpuTemperature;
        case "network": return DgopService.networkRxRate;
        case "disk": return DgopService.diskReadRate;
        default: return DgopService.cpuUsage;
        }
    }

    // Own reactive buffer (DgopService mutates its history arrays in place, so binding
    // them isn't reactive). Seed cpu/memory from the existing service history.
    property var localHistory: []
    readonly property var historyData: localHistory

    Component.onCompleted: {
        DgopService.addRef(root.metricDef.modules);
        if (root.metricDef.usesServiceHistory) {
            const seed = root.metricId === "memory" ? DgopService.memoryHistory : DgopService.cpuHistory;
            root.localHistory = (seed || []).slice(-root.bufferCap);
        }
    }
    Component.onDestruction: DgopService.removeRef(root.metricDef.modules)

    Timer {
        interval: 3000
        running: !root.degraded
        repeat: true
        triggeredOnStart: true
        onTriggered: root.localHistory = Metrics.pushSample(root.localHistory, root.currentValue, root.bufferCap)
    }

    pillClickAction: () => PopoutService.toggleProcessListModal()

    horizontalBarPill: Component {
        Row {
            id: hrow
            spacing: Theme.spacingXS
            readonly property real txt: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)

            DankIcon {
                visible: root.showIcon
                name: root.metricDef.icon
                size: root.iconSize
                color: Theme.surfaceText
                opacity: root.degraded ? 0.5 : 1.0
                anchors.verticalCenter: parent.verticalCenter
            }
            MetricChart {
                width: root.chartWidth
                height: root.widgetThickness
                history: root.historyData
                maxValue: root.metricDef.maxValue
                accentColor: root.accent
                mode: root.chartStyle
                colormap: root.colormapName
                barColor: root.barColor
                grid: root.gridOn
                verticalPadding: root.vPad
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                visible: root.showValue && !root.degraded
                text: Metrics.formatValue(root.metricDef.unit, root.currentValue)
                color: Theme.surfaceText
                font.pixelSize: hrow.txt
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: 1
            DankIcon {
                visible: root.showIcon
                name: root.metricDef.icon
                size: root.iconSize
                color: Theme.surfaceText
                opacity: root.degraded ? 0.5 : 1.0
                anchors.horizontalCenter: parent.horizontalCenter
            }
            MetricChart {
                width: root.widgetThickness
                height: root.chartWidth
                history: root.historyData
                maxValue: root.metricDef.maxValue
                accentColor: root.accent
                mode: root.chartStyle
                colormap: root.colormapName
                barColor: root.barColor
                grid: root.gridOn
                verticalPadding: root.vPad
                anchors.horizontalCenter: parent.horizontalCenter
            }
            StyledText {
                visible: root.showValue && !root.degraded
                text: Metrics.formatValue(root.metricDef.unit, root.currentValue)
                color: Theme.surfaceText
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
