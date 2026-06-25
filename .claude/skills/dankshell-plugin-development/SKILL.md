---
name: dankshell-plugin-development
description: >-
  Hard-won gotchas for building DankMaterialShell (DMS) / Quickshell QML bar
  plugins. Use when: (1) developing a DMS/Quickshell plugin (PluginComponent,
  plugin.json, ~/.config/DankMaterialShell/plugins), (2) a plugin "loaded" but
  nothing shows on the bar, (3) QML logs show "Cannot read property X of
  undefined" or "depends on non-bindable properties: ...::data", (4) "Invalid
  property assignment: string expected" in a settings component, (5) pill
  content isn't sized/seated correctly, or (6) edited plugin QML doesn't take
  effect after toggling the plugin.
author: Claude Code
version: 1.0.0
date: 2026-06-24
---

# DankMaterialShell / Quickshell Plugin Development

## When to Use

- Writing or debugging a DMS plugin: `plugin.json` + a `PluginComponent` QML,
  installed under `~/.config/DankMaterialShell/plugins/<name>/`.
- A plugin shows as **loaded/enabled** in Settings → Plugins but **nothing
  appears on the bar**.
- QML/journal logs (`journalctl --user | grep -i <plugin>`, process is `dms`)
  show: `TypeError: Cannot read property '<x>' of undefined`, or
  `depends on non-bindable properties: …::data`, or
  `Invalid property assignment: string expected`.
- The bar pill renders but content overflows / isn't seated in the pill.
- You edited a plugin's QML, reloaded, and the change didn't take (or "reverted").

## When NOT to Use

- General QML/Qt questions unrelated to the DMS plugin framework.
- Non-DMS Quickshell configs that don't use `PluginComponent` / the plugin loader.
- Styling/theming questions answerable from `Common/Theme.qml` — just read it.

## Problem

DMS plugins are QML loaded into a running compositor. Several failure modes are
**runtime-only** — invisible to static review, `node`/unit tests, or reading the
code — and each produces a confusing symptom with a non-obvious cause. The
authoritative reference is the DMS source (typically
`/usr/share/quickshell/dms/quickshell/`): the plugin docs/examples in `PLUGINS/`,
the manifest schema in `PLUGINS/plugin-schema.json`, `Modules/Plugins/` (the
`PluginComponent`/`BasePill`/setting components), and `Services/PluginService.qml`.
The shipping `PLUGINS/ExampleEmojiPlugin/` is the best working reference — when in
doubt, diff your widget against it.

## Solution

Each gotcha below is **symptom → cause → fix → why**.

### Reloading: the enable/disable toggle does NOT reload edited QML

- **Symptom:** You edit plugin QML, toggle the plugin off/on, and the old
  behavior persists (or "reverts" after a toggle).
- **Cause:** `enablePlugin()` calls `loadPlugin(id)` with **no cache-buster**, so
  `Qt.createComponent("file://…")` returns the QQmlEngine's **in-memory cached
  Component** from this session's first compile. `reloadPlugin()` instead calls
  `loadPlugin(id, true)`, which appends `?t=Date.now()` → a unique URL → fresh
  compile.
- **Fix:** After editing a **widget**, click the per-row **↻ refresh icon** in
  Settings → Plugins (that's `reloadPlugin`), not the on/off toggle.
- **Settings components are worse — not hot-reloadable at all.** They're loaded
  by the Plugins-tab's own `Loader` with a **plain `file://` URL (no `?t=`)**, so
  an edited settings QML stays cached for the engine's entire lifetime. A
  **full DMS shell restart** is the only way to pick up settings changes.
- **Why it matters:** Without this you'll "fix" a bug, see no change, and chase
  ghosts. Rule: edit widget → ↻ reload; edit settings → restart the shell.

### Never name a QML `id: data`

- **Symptom:** `TypeError: Cannot read property '<field>' of undefined` and
  `depends on non-bindable properties: SomeType::data` in child bindings, even
  though the object clearly exists and has that property.
- **Cause:** `data` is a **built-in property on every QML `Item`** (the default
  children list). Inside any child item, an unqualified `data.foo` resolves to
  *that item's* `data` list, **shadowing** your `id: data` object.
- **Fix:** Rename the id (e.g. `id: scData`) and update references.
- **Why:** id-vs-property resolution favors the current object's own property.
  This also applies to other Item property names — avoid `state`, `children`,
  `parent`, `width`, etc. as ids.

### Bar pill content must be BARE items, not a self-backed rectangle

- **Symptom:** The pill content overflows, isn't seated, or a piece "spills" to
  the side; sizing looks broken.
- **Cause:** `PluginComponent` wraps your `horizontalBarPill`/`verticalBarPill`
  in a **`BasePill`** that draws the rounded background and sizes itself to the
  content's **`implicitWidth`**. If your content is a `StyledRect` that sets
  `width`/`height` (often via `parent.widgetThickness`), its `implicitWidth` is 0
  → BasePill collapses to padding, and `parent.widgetThickness` is **undefined in
  the content scope** (it lives on the PluginComponent, not the content's parent).
- **Fix:** Return a plain `Row`/`Column` of the inner items (logo, text, etc.) —
  exactly like `ExampleEmojiPlugin`. Let `BasePill` provide chrome and sizing.
- **Why:** The README "Hello World" snippet shows a self-backed `StyledRect`,
  which is misleading; the real working pattern is bare content.

### Setting components are string-typed

- **Symptom:** `Invalid property assignment: string expected` at the settings
  file; the Plugins-tab row's expand chevron is present but **expanding shows
  nothing** (zero-height, clipped).
- **Cause:** `StringSetting`/`SelectionSetting` declare `defaultValue` and `value`
  as **`string`**. Passing an integer (`defaultValue: 5`, or numeric `options`
  values) is a fatal instantiation error → `Loader.Error` → the accordion expands
  to zero height (and the "Failed to load settings" text is clipped, so it looks
  like nothing happens).
- **Fix:** Use string values (`defaultValue: "5"`, `value: "5"`) and convert in
  the consumer (e.g. `parseInt(pluginData.key)`).
- **Why:** The settings panel's height is `loader.item ? implicitHeight : 0`, so a
  failed component is indistinguishable from "no settings" unless you read the log.

### Enabling a plugin ≠ placing it on the bar

- **Symptom:** Plugin shows "loaded" in the Plugins tab, but the bar is unchanged.
- **Cause:** Enabling only loads the plugin. Every widget (built-in or plugin)
  must be **explicitly added to a DankBar section**.
- **Fix:** Settings → DankBar → add the widget (by its `plugin.json` `id`) to a
  section, or edit `barConfigs[].leftWidgets/centerWidgets/rightWidgets` in
  `~/.config/DankMaterialShell/settings.json`.
- **Why:** There is no auto-placement; the bar layout is fully explicit.

## Verification

1. Reload correctly: ↻ for widget edits, full restart for settings edits.
2. `journalctl --user -n 200 | grep -i <plugin>` is free of the TypeErrors,
   `…::data` warnings, and `string expected` errors above.
3. The pill is sized/seated correctly; the popout/counts bind to live data.
4. Settings → Plugins → expand the plugin row → the fields render (not zero-height).

## References

- DMS plugin docs & examples: `PLUGINS/README.md`, `PLUGINS/ExampleEmojiPlugin/`,
  and `PLUGINS/plugin-schema.json` in the DMS source tree (commonly
  `/usr/share/quickshell/dms/quickshell/`).
- Framework internals worth reading when stuck: `Modules/Plugins/PluginComponent.qml`,
  `Modules/Plugins/BasePill.qml`, `Modules/Plugins/{StringSetting,SelectionSetting}.qml`,
  `Modules/Settings/PluginListItem.qml`, `Services/PluginService.qml`.
- Plugin registry: https://plugins.danklinux.com/
