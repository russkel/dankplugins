// kanban.js — pure, deterministic logic for the Shortcut Kanban plugin.
// Dual-target: imported into QML (`import "kanban.js" as Kanban`) and require()d by node tests.
// No QML object access; no `.pragma library` (that directive is not valid JS for node).

function resolveToken(envToken, settingsToken) {
    var e = (envToken || "").trim();
    if (e.length > 0) return e;
    var s = (settingsToken || "").trim();
    return s.length > 0 ? s : null;
}

function initialsOf(name) {
    var parts = (name || "").trim().split(/\s+/).filter(function (p) { return p.length > 0; });
    if (parts.length === 0) return "?";
    if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

function buildStateMap(workflows) {
    var map = {};
    (workflows || []).forEach(function (wf) {
        (wf.states || []).forEach(function (st) {
            map[st.id] = { type: st.type, name: st.name };
        });
    });
    return map;
}

function buildMemberMap(members) {
    var map = {};
    (members || []).forEach(function (m) {
        var p = m.profile || {};
        map[m.id] = initialsOf(p.name || p.mention_name || "");
    });
    return map;
}

function startedIterationIds(iterations) {
    return (iterations || [])
        .filter(function (it) { return it.status === "started"; })
        .map(function (it) { return it.id; });
}

// POST /stories/search body for the default "my stories in started iterations"
// mode. Server-side filtering by owner + iteration avoids the GET search
// endpoint's 10-per-page pagination and needs no client-side iteration filter.
function defaultSearchBody(myId, startedIds) {
    return { owner_ids: myId ? [myId] : [], iteration_ids: (startedIds || []).slice() };
}

function bucketStories(stories, stateMap) {
    var buckets = { unstarted: [], started: [], done: [] };
    (stories || []).forEach(function (s) {
        var st = stateMap[s.workflow_state_id];
        var type = st ? st.type : "started";
        if (type === "backlog") type = "unstarted";   // Shortcut has a 4th state type
        if (type !== "unstarted" && type !== "started" && type !== "done") type = "started";
        buckets[type].push(s);
    });
    return buckets;
}

function counts(buckets) {
    return {
        unstarted: ((buckets || {}).unstarted || []).length,
        started: ((buckets || {}).started || []).length,
        done: ((buckets || {}).done || []).length
    };
}

function cardModel(story, stateMap, memberMap) {
    var st = (stateMap || {})[story.workflow_state_id] || {};
    var owners = (story.owner_ids || [])
        .map(function (id) { return (memberMap || {})[id]; })
        .filter(function (x) { return !!x; });
    return {
        id: story.id,
        name: story.name || "(untitled)",
        stateName: st.name || "",
        ownerInitials: owners.length > 0 ? owners[0] : "",
        appUrl: story.app_url || ""
    };
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = {
        resolveToken: resolveToken,
        initialsOf: initialsOf,
        buildStateMap: buildStateMap,
        buildMemberMap: buildMemberMap,
        startedIterationIds: startedIterationIds,
        defaultSearchBody: defaultSearchBody,
        bucketStories: bucketStories,
        counts: counts,
        cardModel: cardModel
    };
}
