const test = require("node:test");
const assert = require("node:assert/strict");
const C = require("./colormap.js");

test("COLORMAP_NAMES are the five perceptual maps", () => {
  assert.deepEqual(C.COLORMAP_NAMES, ["viridis", "plasma", "inferno", "magma", "cividis"]);
});

test("each map has stops and endpoints sample to first/last stop", () => {
  for (const n of C.COLORMAP_NAMES) {
    assert.ok(C.MAPS[n].length >= 2);
    assert.deepEqual(C.sample(n, 0), C.MAPS[n][0]);
    assert.deepEqual(C.sample(n, 1), C.MAPS[n][C.MAPS[n].length - 1]);
  }
});

test("sample clamps out-of-range t", () => {
  assert.deepEqual(C.sample("viridis", -5), C.MAPS.viridis[0]);
  assert.deepEqual(C.sample("viridis", 5), C.MAPS.viridis[C.MAPS.viridis.length - 1]);
});

test("sample hits an exact interior stop", () => {
  const v = C.sample("viridis", 1 / 7); // 8 stops -> index 1 exactly
  assert.deepEqual(v, C.MAPS.viridis[1]);
});

test("sample lerps halfway between two stops", () => {
  const a = C.MAPS.viridis[0], b = C.MAPS.viridis[1];
  const v = C.sample("viridis", 0.5 / 7);
  assert.ok(Math.abs(v[0] - (a[0] + b[0]) / 2) < 1e-9);
  assert.ok(Math.abs(v[1] - (a[1] + b[1]) / 2) < 1e-9);
});

test("unknown map falls back to viridis", () => {
  assert.deepEqual(C.sample("nope", 0), C.MAPS.viridis[0]);
});
