import QtQuick
import qs.Common
import "metrics.js" as Metrics
import "colormap.js" as Colormap

Item {
    id: root
    property var history: []
    property real maxValue: 0          // 0 = auto-scale to the window's max
    property color accentColor: Theme.primary
    property bool fillArea: false
    property real verticalPadding: 1.5
    property string mode: "line"       // "line" | "bars"
    property string colormap: "viridis"
    property string barColor: "solid"  // "solid" (one color by value) | "gradient" (per-bar ramp)
    property bool grid: false

    Canvas {
        id: canvas
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        readonly property var pts: Metrics.normalize(root.history, root.maxValue)
        // Bundle all style inputs so any change triggers a repaint.
        readonly property string sig: [root.mode, root.colormap, root.barColor, root.grid, root.fillArea,
                                        root.verticalPadding, String(root.accentColor)].join("|")
        onPtsChanged: requestPaint()
        onSigChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const p = pts;
            if (!p || p.length < 2)
                return;
            const pad = Math.max(0, root.verticalPadding);
            const h = height - pad * 2;
            const top = pad;
            const bottom = height - pad;

            // Optional grid: faint quarter lines.
            if (root.grid) {
                ctx.strokeStyle = Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.25);
                ctx.lineWidth = 1;
                for (let g = 1; g <= 3; g++) {
                    const gy = top + (g / 4) * h;
                    ctx.beginPath();
                    ctx.moveTo(0, gy);
                    ctx.lineTo(width, gy);
                    ctx.stroke();
                }
            }

            if (root.mode === "bars") {
                // Show the full window (every point) across the width, same window as line mode.
                const n = p.length;
                const gap = 1;
                const step = width / n;
                const barW = Math.max(1, step - gap);
                // Gradient mode: ONE fixed gradient spanning the full plot height
                // (colormap 0 at the baseline -> 1 at the top). Every bar reuses it, and
                // each bar's rect clips it — so the gradient stays constant across bars
                // and only the bar HEIGHT encodes the value (a short bar shows just the
                // cool low end; a tall bar reaches the hot colors).
                let barGrad = null;
                if (root.barColor === "gradient") {
                    barGrad = ctx.createLinearGradient(0, bottom, 0, top);
                    const gstops = [0, 0.25, 0.5, 0.75, 1];
                    for (let s = 0; s < gstops.length; s++) {
                        const gc = Colormap.sample(root.colormap, gstops[s]);
                        barGrad.addColorStop(gstops[s], Qt.rgba(gc[0], gc[1], gc[2], 1));
                    }
                }
                for (let k = 0; k < n; k++) {
                    const v = p[k].v;
                    const bh = v * h;
                    if (bh <= 0)
                        continue;
                    if (root.barColor === "gradient") {
                        ctx.fillStyle = barGrad;
                    } else {
                        const c = Colormap.sample(root.colormap, v);
                        ctx.fillStyle = Qt.rgba(c[0], c[1], c[2], 1);
                    }
                    ctx.fillRect(k * step, bottom - bh, barW, bh);
                }
                return;
            }

            // line mode (+ optional area fill)
            if (root.fillArea) {
                ctx.beginPath();
                ctx.moveTo(p[0].x * width, bottom);
                for (let i = 0; i < p.length; i++)
                    ctx.lineTo(p[i].x * width, top + (1 - p[i].v) * h);
                ctx.lineTo(p[p.length - 1].x * width, bottom);
                ctx.closePath();
                ctx.fillStyle = Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.18);
                ctx.fill();
            }
            ctx.beginPath();
            for (let i = 0; i < p.length; i++) {
                const x = p[i].x * width;
                const y = top + (1 - p[i].v) * h;
                i ? ctx.lineTo(x, y) : ctx.moveTo(x, y);
            }
            ctx.lineWidth = 1.5;
            ctx.lineJoin = "round";
            ctx.strokeStyle = root.accentColor;
            ctx.stroke();
        }
    }
}
