// metrics.js — pure descriptors + math for System Sparklines.
// Dual-target: imported into QML (`import "metrics.js" as Metrics`) and require()d by node tests.
// No QML/Qt access; no `.pragma library`; module.exports guard at the bottom.

var METRICS = {
    cpu:     { id: "cpu",     label: "CPU",      icon: "memory",            unit: "%",   modules: ["cpu"],     maxValue: 100, usesServiceHistory: true },
    memory:  { id: "memory",  label: "RAM",      icon: "developer_board",   unit: "%",   modules: ["memory"],  maxValue: 100, usesServiceHistory: true },
    cputemp: { id: "cputemp", label: "CPU Temp", icon: "device_thermostat", unit: "°C",  modules: ["cpu"],     maxValue: 100, usesServiceHistory: false },
    network: { id: "network", label: "Network",  icon: "network_check",     unit: "B/s", modules: ["network"], maxValue: 0,   usesServiceHistory: false },
    disk:    { id: "disk",    label: "Disk",     icon: "storage",           unit: "B/s", modules: ["disk"],    maxValue: 0,   usesServiceHistory: false }
};

var METRIC_IDS = ["cpu", "memory", "cputemp", "network", "disk"];

function metric(id) {
    return METRICS[id] || METRICS.cpu;
}

function pushSample(buffer, value, cap) {
    var out = (buffer || []).slice();
    out.push(value);
    if (cap && out.length > cap)
        out = out.slice(out.length - cap);
    return out;
}

function normalize(history, maxValue) {
    var h = history || [];
    var n = h.length;
    if (n < 2)
        return [];
    var max = maxValue;
    if (maxValue <= 0) {
        max = 0;
        for (var i = 0; i < n; i++)
            max = Math.max(max, h[i]);
        if (max <= 0)
            max = 1;   // all-zero data: avoid divide-by-zero, render a flat baseline
    }
    var pts = [];
    for (var j = 0; j < n; j++) {
        var v = h[j] / max;
        if (v < 0) v = 0;
        if (v > 1) v = 1;
        pts.push({ x: j / (n - 1), v: v });
    }
    return pts;
}

function formatBytes(bytes) {
    var b = bytes || 0;
    if (b < 1024) return Math.round(b) + " B";
    if (b < 1024 * 1024) return (b / 1024).toFixed(1) + " KB";
    if (b < 1024 * 1024 * 1024) return (b / (1024 * 1024)).toFixed(1) + " MB";
    return (b / (1024 * 1024 * 1024)).toFixed(1) + " GB";
}

function formatValue(unit, value) {
    if (unit === "%") return Math.round(value) + "%";
    if (unit === "°C") return Math.round(value) + "°C";
    if (unit === "B/s") return formatBytes(value) + "/s";
    return String(value);
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = {
        METRICS: METRICS,
        METRIC_IDS: METRIC_IDS,
        metric: metric,
        pushSample: pushSample,
        normalize: normalize,
        formatValue: formatValue,
        formatBytes: formatBytes
    };
}
