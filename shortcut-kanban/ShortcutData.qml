pragma ComponentBehavior: Bound
import QtQuick
import qs.Services
import "kanban.js" as Kanban

Item {
    id: root

    property string token: ""
    property string query: ""        // override; empty => built-in my-active-work mode

    property var stateMap: ({})
    property var memberMap: ({})
    property var startedIds: []
    property string mentionName: ""
    property string myId: ""

    property var buckets: ({ unstarted: [], started: [], done: [] })
    property var countsObj: ({ unstarted: 0, started: 0, done: 0 })

    property bool loading: false
    property bool errorState: false
    property bool ready: false       // catalog loaded at least once

    readonly property string pluginId: "shortcutKanban"
    property int _backoffMs: 0

    Component.onCompleted: {
        try {
            const cached = PluginService.loadPluginData(root.pluginId, "cacheCounts", null)
            if (cached) root.countsObj = cached
        } catch (e) {}
    }

    function _persist() {
        try { PluginService.savePluginData(root.pluginId, "cacheCounts", root.countsObj) } catch (e) {}
    }

    Timer {
        id: retryTimer
        repeat: false
        onTriggered: root.refresh()
    }

    function _scheduleRetry() {
        root._backoffMs = root._backoffMs === 0 ? 5000 : Math.min(root._backoffMs * 2, 120000)
        retryTimer.interval = root._backoffMs
        retryTimer.restart()
    }

    // catalog readiness tracking
    property bool _gotMember: false
    property bool _gotWorkflows: false
    property bool _gotMembers: false
    property bool _gotIterations: false

    function tick() {
        if (root.token.length === 0) { root.errorState = true; return }
        if (!root.ready) loadCatalog()
        else refresh()
    }

    function loadCatalog() {
        if (root.token.length === 0) { root.errorState = true; return }
        root._gotMember = root._gotWorkflows = root._gotMembers = root._gotIterations = false
        memberGet.run()
        workflowsGet.run()
        membersGet.run()
        iterationsGet.run()
    }

    function _maybeReady() {
        if (root._gotMember && root._gotWorkflows && root._gotMembers && root._gotIterations) {
            root.ready = true
            refresh()
        }
    }

    function refresh() {
        if (root.token.length === 0) return
        if (!root.ready) { loadCatalog(); return }
        const override = (root.query || "").trim()
        root.loading = true
        if (override.length > 0) {
            // Override mode: free-text Shortcut query via GET search (first page).
            storiesGet.method = "GET"
            storiesGet.body = ""
            storiesGet.path = "/search/stories?query=" + encodeURIComponent(override)
        } else {
            // Default mode: my stories in started iterations via POST search.
            if (root.startedIds.length === 0 || root.myId.length === 0) {
                root.buckets = ({ unstarted: [], started: [], done: [] })
                root.countsObj = Kanban.counts(root.buckets)
                root.loading = false
                return
            }
            storiesGet.method = "POST"
            storiesGet.body = JSON.stringify(Kanban.defaultSearchBody(root.myId, root.startedIds))
            storiesGet.path = "/stories/search"
        }
        storiesGet.run()
    }

    // /member is a FLAT object (no .profile sub-object): read mention_name and id directly.
    ShortcutGet { id: memberGet; token: root.token; path: "/member"
        onLoaded: jsonText => { try { const m = JSON.parse(jsonText); root.mentionName = m.mention_name || ""; root.myId = m.id || "" } catch (e) { root.errorState = true } root._gotMember = true; root._maybeReady() }
        onFailed: () => { root.errorState = true; root._scheduleRetry() } }

    ShortcutGet { id: workflowsGet; token: root.token; path: "/workflows"
        onLoaded: jsonText => { try { root.stateMap = Kanban.buildStateMap(JSON.parse(jsonText)) } catch (e) { root.errorState = true } root._gotWorkflows = true; root._maybeReady() }
        onFailed: () => { root.errorState = true; root._scheduleRetry() } }

    ShortcutGet { id: membersGet; token: root.token; path: "/members"
        onLoaded: jsonText => { try { root.memberMap = Kanban.buildMemberMap(JSON.parse(jsonText)) } catch (e) { root.errorState = true } root._gotMembers = true; root._maybeReady() }
        onFailed: () => { root.errorState = true; root._scheduleRetry() } }

    ShortcutGet { id: iterationsGet; token: root.token; path: "/iterations"
        onLoaded: jsonText => { try { root.startedIds = Kanban.startedIterationIds(JSON.parse(jsonText)) } catch (e) { root.errorState = true } root._gotIterations = true; root._maybeReady() }
        onFailed: () => { root.errorState = true; root._scheduleRetry() } }

    ShortcutGet { id: storiesGet; token: root.token
        onLoaded: jsonText => {
            try {
                const parsed = JSON.parse(jsonText)
                const data = parsed.data || parsed   // POST /stories/search → bare array; GET override → {data, ...}
                root.buckets = Kanban.bucketStories(data, root.stateMap)
                root.countsObj = Kanban.counts(root.buckets)
                root.errorState = false
                root._backoffMs = 0
                retryTimer.stop()
                root._persist()
                console.info("ShortcutKanban: counts", JSON.stringify(root.countsObj))
            } catch (e) {
                console.warn("ShortcutKanban: parse error", e)
                root.errorState = true
            }
            root.loading = false
        }
        onFailed: code => {
            console.warn("ShortcutKanban: stories fetch failed", code)
            root.errorState = true
            root.loading = false
            root._scheduleRetry()
        } }
}
