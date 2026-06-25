const test = require("node:test");
const assert = require("node:assert/strict");
const K = require("./kanban.js");

test("resolveToken prefers env, trims, falls back to settings", () => {
  assert.equal(K.resolveToken("env-tok", "set-tok"), "env-tok");
  assert.equal(K.resolveToken("   ", "set-tok"), "set-tok");
  assert.equal(K.resolveToken(null, "  s  "), "s");
  assert.equal(K.resolveToken("", ""), null);
});

test("initialsOf handles empty, single, multi-word names", () => {
  assert.equal(K.initialsOf(""), "?");
  assert.equal(K.initialsOf("Russ"), "RU");
  assert.equal(K.initialsOf("Russ Webber"), "RW");
  assert.equal(K.initialsOf("  Ada B. Lovelace "), "AL");
});

test("buildStateMap flattens workflow states by id", () => {
  const wf = [
    { states: [{ id: 1, type: "unstarted", name: "To Do" }, { id: 2, type: "started", name: "In Progress" }] },
    { states: [{ id: 3, type: "done", name: "Done" }] },
  ];
  const m = K.buildStateMap(wf);
  assert.equal(m[1].type, "unstarted");
  assert.equal(m[2].name, "In Progress");
  assert.equal(m[3].type, "done");
});

test("buildMemberMap maps id -> initials", () => {
  const members = [{ id: "a", profile: { name: "Russ Webber" } }, { id: "b", profile: { name: "Ada", mention_name: "ada" } }];
  const m = K.buildMemberMap(members);
  assert.equal(m["a"], "RW");
  assert.equal(m["b"], "AD");
});

test("startedIterationIds returns only started ids in order", () => {
  const its = [{ id: 10, status: "started" }, { id: 11, status: "done" }, { id: 12, status: "unstarted" }, { id: 13, status: "started" }];
  assert.deepEqual(K.startedIterationIds(its), [10, 13]);
});

test("defaultSearchBody builds the POST /stories/search body", () => {
  assert.deepEqual(K.defaultSearchBody("uuid-me", [10, 13]), { owner_ids: ["uuid-me"], iteration_ids: [10, 13] });
  assert.deepEqual(K.defaultSearchBody("", []), { owner_ids: [], iteration_ids: [] });
});

test("bucketStories groups by type; backlog folds into unstarted; unknown -> started", () => {
  const stateMap = { 1: { type: "unstarted" }, 2: { type: "started" }, 3: { type: "done" }, 4: { type: "backlog" } };
  const stories = [{ workflow_state_id: 1 }, { workflow_state_id: 4 }, { workflow_state_id: 2 }, { workflow_state_id: 2 }, { workflow_state_id: 3 }, { workflow_state_id: 999 }];
  const b = K.bucketStories(stories, stateMap);
  assert.equal(b.unstarted.length, 2); // unstarted + backlog
  assert.equal(b.started.length, 3);   // two started + unknown fallback
  assert.equal(b.done.length, 1);
});

test("counts reports bucket sizes", () => {
  assert.deepEqual(K.counts({ unstarted: [1], started: [1, 2], done: [] }), { unstarted: 1, started: 2, done: 0 });
});

test("cardModel builds the minimal view model", () => {
  const stateMap = { 2: { type: "started", name: "In Progress" } };
  const memberMap = { "uuid-a": "RW" };
  const vm = K.cardModel({ id: 42, name: "Fix bug", workflow_state_id: 2, owner_ids: ["uuid-a"], app_url: "https://app.shortcut.com/x/story/42" }, stateMap, memberMap);
  assert.deepEqual(vm, { id: 42, name: "Fix bug", stateName: "In Progress", ownerInitials: "RW", appUrl: "https://app.shortcut.com/x/story/42" });
});
