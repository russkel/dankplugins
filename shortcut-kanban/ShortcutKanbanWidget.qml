import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "kanban.js" as Kanban

PluginComponent {
    id: root
    layerNamespacePlugin: "shortcut-kanban"

    property string resolvedToken: Kanban.resolveToken(Quickshell.env("SHORTCUT_API_TOKEN"), pluginData.apiToken || "") || ""

    ShortcutData {
        id: scData
        token: root.resolvedToken
        query: root.pluginData.query || ""
    }

    Timer {
        interval: Math.max(1, parseInt(root.pluginData.backgroundIntervalMin) || 5) * 60000
        running: root.resolvedToken.length > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: scData.tick()
    }

    onResolvedTokenChanged: scData.tick()

    // The pill content is bare inner items: PluginComponent wraps this in a
    // BasePill that draws the rounded background and sizes itself to the
    // content's implicitWidth. (Do NOT add a StyledRect background or use
    // parent.widgetThickness here — that double-draws and breaks sizing.)
    horizontalBarPill: Component {
        Row {
            id: row
            spacing: Theme.spacingS

            readonly property bool degraded: root.resolvedToken.length === 0 || scData.errorState
            // Scale text with the bar like built-in widgets (thickness + the bar's font-scale/maximize settings).
            readonly property real txt: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)

            ShortcutLogo {
                size: root.iconSize
                anchors.verticalCenter: parent.verticalCenter
                opacity: row.degraded ? 0.4 : 1.0
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingXS
                visible: !row.degraded

                StyledText { text: scData.countsObj.unstarted; color: Theme.surfaceVariantText; font.pixelSize: row.txt }
                StyledText { text: "·"; color: Theme.surfaceVariantText; font.pixelSize: row.txt }
                StyledText { text: scData.countsObj.started; color: Theme.primary; font.pixelSize: row.txt; font.weight: Font.Medium }
                StyledText { text: "·"; color: Theme.surfaceVariantText; font.pixelSize: row.txt }
                StyledText { text: scData.countsObj.done; color: Theme.success; font.pixelSize: row.txt }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: row.degraded
                width: 6; height: 6; radius: 3
                color: Theme.error
            }
        }
    }

    verticalBarPill: Component {
        Column {
            id: col
            spacing: Theme.spacingXS

            readonly property bool degraded: root.resolvedToken.length === 0 || scData.errorState
            readonly property real txt: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)

            ShortcutLogo {
                size: root.iconSize
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: col.degraded ? 0.4 : 1.0
            }
            StyledText { visible: !col.degraded; text: scData.countsObj.unstarted; color: Theme.surfaceVariantText; font.pixelSize: col.txt; anchors.horizontalCenter: parent.horizontalCenter }
            StyledText { visible: !col.degraded; text: scData.countsObj.started; color: Theme.primary; font.pixelSize: col.txt; font.weight: Font.Medium; anchors.horizontalCenter: parent.horizontalCenter }
            StyledText { visible: !col.degraded; text: scData.countsObj.done; color: Theme.success; font.pixelSize: col.txt; anchors.horizontalCenter: parent.horizontalCenter }
            Rectangle { visible: col.degraded; width: 6; height: 6; radius: 3; color: Theme.error; anchors.horizontalCenter: parent.horizontalCenter }
        }
    }

    popoutWidth: 520
    popoutHeight: 420

    popoutContent: Component {
        PopoutComponent {
            id: pop
            headerText: "Shortcut"
            detailsText: (root.pluginData.query || "").trim().length > 0
                ? ("Query: " + root.pluginData.query)
                : "My stories · started iterations"
            showCloseButton: true

            // Active refresh: this Component exists only while the popout is open.
            Component.onCompleted: scData.refresh()
            Timer { interval: 30000; running: true; repeat: true; onTriggered: scData.refresh() }

            Row {
                width: parent.width
                height: root.popoutHeight - pop.headerHeight - pop.detailsHeight - Theme.spacingXL
                spacing: Theme.spacingM

                Repeater {
                    model: [
                        { key: "unstarted", title: "Unstarted", accent: Theme.surfaceVariantText },
                        { key: "started",   title: "In Progress", accent: Theme.primary },
                        { key: "done",      title: "Done", accent: Theme.success }
                    ]

                    delegate: Column {
                        width: (parent.width - Theme.spacingM * 2) / 3
                        height: parent.height
                        spacing: Theme.spacingS

                        property var colStories: scData.buckets[modelData.key] || []

                        Row {
                            width: parent.width
                            spacing: Theme.spacingXS
                            StyledText { text: modelData.title; color: modelData.accent; font.pixelSize: Theme.fontSizeMedium; font.weight: Font.Bold }
                            StyledText { text: "(" + parent.parent.colStories.length + ")"; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall }
                        }

                        StyledText {
                            visible: parent.colStories.length === 0
                            text: scData.loading ? "Loading…" : "No stories."
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        DankListView {
                            width: parent.width
                            height: parent.height - Theme.spacingXL
                            clip: true
                            spacing: Theme.spacingXS
                            model: parent.colStories

                            delegate: StyledRect {
                                width: ListView.view.width
                                implicitHeight: cardCol.implicitHeight + Theme.spacingS * 2
                                radius: Theme.cornerRadius
                                color: cardMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh

                                property var vm: Kanban.cardModel(modelData, scData.stateMap, scData.memberMap)

                                Column {
                                    id: cardCol
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingS
                                    spacing: 2
                                    StyledText {
                                        width: parent.width
                                        text: parent.parent.vm.name
                                        color: Theme.surfaceText
                                        font.pixelSize: Theme.fontSizeSmall
                                        elide: Text.ElideRight
                                        maximumLineCount: 2
                                        wrapMode: Text.WordWrap
                                    }
                                    Row {
                                        spacing: Theme.spacingXS
                                        StyledText { text: "#" + parent.parent.parent.vm.id; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall }
                                        StyledText { visible: parent.parent.parent.vm.ownerInitials.length > 0; text: parent.parent.parent.vm.ownerInitials; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall }
                                    }
                                }

                                MouseArea {
                                    id: cardMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const url = parent.vm.appUrl
                                        if (url.length > 0) Quickshell.execDetached(["xdg-open", url])
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
