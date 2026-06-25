const test = require("node:test");
const assert = require("node:assert/strict");
const M = require("./metrics.js");

test("metric() returns descriptors with the reused icons, falls back to cpu", () => {
  assert.equal(M.metric("cpu").icon, "memory");
  assert.equal(M.metric("memory").icon, "developer_board");
  assert.equal(M.metric("cputemp").icon, "device_thermostat");
  assert.equal(M.metric("network").icon, "network_check");
  assert.equal(M.metric("disk").icon, "storage");
  assert.equal(M.metric("bogus").id, "cpu");
  assert.equal(M.metric("cputemp").maxValue, 100); // CPU temp on a fixed 0-100°C scale
  assert.equal(M.metric("network").maxValue, 0);   // rates auto-scale
});

test("usesServiceHistory true only for cpu/memory", () => {
  assert.equal(M.metric("cpu").usesServiceHistory, true);
  assert.equal(M.metric("memory").usesServiceHistory, true);
  assert.equal(M.metric("cputemp").usesServiceHistory, false);
  assert.equal(M.metric("disk").usesServiceHistory, false);
});

test("METRIC_IDS lists the shipped metrics", () => {
  assert.deepEqual(M.METRIC_IDS, ["cpu", "memory", "cputemp", "network", "disk"]);
});

test("pushSample appends and trims to cap", () => {
  assert.deepEqual(M.pushSample([1, 2, 3], 4, 3), [2, 3, 4]);
  assert.deepEqual(M.pushSample([], 5, 60), [5]);
  assert.deepEqual(M.pushSample(null, 9, 2), [9]);
});

test("normalize: <2 points -> []; fixed max; auto-max; clamps", () => {
  assert.deepEqual(M.normalize([], 100), []);
  assert.deepEqual(M.normalize([50], 100), []);
  assert.deepEqual(M.normalize([0, 50, 100], 100), [{x:0,v:0},{x:0.5,v:0.5},{x:1,v:1}]);
  assert.deepEqual(M.normalize([1, 2, 4], 0), [{x:0,v:0.25},{x:0.5,v:0.5},{x:1,v:1}]); // auto-max=4
  // auto-max uses the data's maximum even when all values are < 1
  assert.deepEqual(M.normalize([0.25, 0.5], 0), [{x:0,v:0.5},{x:1,v:1}]);
  // all-zero data: divide-by-zero guard -> flat baseline at 0
  assert.deepEqual(M.normalize([0, 0], 0), [{x:0,v:0},{x:1,v:0}]);
});

test("formatValue per unit", () => {
  assert.equal(M.formatValue("%", 36.7), "37%");
  assert.equal(M.formatValue("°C", 54.2), "54°C");
  assert.equal(M.formatValue("B/s", 1536), "1.5 KB/s");
});

test("formatBytes scales units", () => {
  assert.equal(M.formatBytes(0), "0 B");
  assert.equal(M.formatBytes(1536), "1.5 KB");
  assert.equal(M.formatBytes(5 * 1024 * 1024), "5.0 MB");
});
