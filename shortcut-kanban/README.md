# Shortcut Kanban (DankMaterialShell plugin)

A bar pill showing the Shortcut logo and three counts — unstarted / in
progress / done — for a configurable Shortcut search query. Click it for a
read-only 3-column kanban; click a card to open the story in your browser.

## Install

1. Symlink or copy this directory into `~/.config/DankMaterialShell/plugins/`:
   `ln -sfn "$PWD" ~/.config/DankMaterialShell/plugins/shortcut-kanban`
2. DMS Settings → Plugins → "Scan for Plugins" → enable **Shortcut Kanban**.
3. Settings → Appearance → DankBar → add the `shortcutKanban` widget.

## Auth

Set `SHORTCUT_API_TOKEN` in the environment the DMS shell runs in, **or** paste
a token in Settings → Plugins → Shortcut Kanban. The env var takes precedence.
A token in settings is stored in `settings.json` in plaintext.

## Settings

- **API Token** — optional; overrides nothing if blank (env var is used).
- **Search Query** — optional Shortcut search string. Blank = your stories in
  currently-started iterations.
- **Background Refresh** — 1 / 5 / 15 minutes (counts refresh while closed; the
  open popout refreshes every 30 s).

## Develop / test

- Pure logic: `node --test` (in this directory).
- Validate manifest: see the project plan.
- Logs: `journalctl --user -n 200 | grep -i shortcut` (the shell process is
  `dms`), or run a foreground `qs -v -p /usr/share/quickshell/dms/quickshell/shell.qml`.

### Reloading after edits (important)

- The plugin enable/disable **toggle does NOT reload edited QML** — it reuses
  the engine's first-compiled component. After editing the **widget**, click
  the per-row **↻ refresh icon** in Settings → Plugins (that runs
  `reloadPlugin`, which cache-busts).
- The **settings component is not hot-reloadable at all** (its loader uses a
  plain `file://` URL with no cache-buster). After editing
  `ShortcutKanbanSettings.qml`, **fully restart the DMS shell** to pick it up.
