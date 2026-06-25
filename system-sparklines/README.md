# System Sparklines (DankMaterialShell plugin)

Per-metric system charts for the bar: CPU, RAM, CPU temp, network, disk. Each
metric is its own widget (auto-provided — no variant management). A widget draws
a full-pill-height chart as a line or colormap-colored bars, on a fixed scale
(CPU/RAM 0–100%, CPU temp 0–100 °C; network/disk auto-scale). Click a widget to
open the System Monitor.

## Install & first run

1. Symlink this dir into the plugins dir:
   `ln -sfn "$PWD" ~/.config/DankMaterialShell/plugins/system-sparklines`
2. DMS Settings → Plugins → Scan → enable **System Sparklines**.
3. **Open its settings once** — this seeds one widget per metric.
4. Settings → DankBar → add the CPU / RAM / … widgets you want.

## Configuration

- **Per metric:** show icon, show value, chart style (line / bars), colormap
  (viridis / plasma / inferno / magma / cividis, used in bars), grid on/off.
- **Global:** chart width, vertical padding.

## Reloading after edits

- Widget QML: per-row **↻ reload** (the enable/disable toggle does NOT reload).
- Settings QML: a **full DMS shell restart** is required.

## Test

- Pure logic: `node --test` (in this directory).
- Logs: `journalctl --user -n 200 | grep -i sparkline` (process is `dms`).
