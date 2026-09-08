# CONTEXT

Why two session prefs are pinned in `modules.programs.zen-browser`.

## `zen.window-sync.enabled = false`

Zen's window sync makes closed tabs come back. On save,
`ZenSessionManager#collectUsedTabsFromWindows` unions the tab lists of every
open window keyed by `zenSyncId` with no removal step; on restore
`#restoreWindowData` assigns that union to *every* window (`aWindowData.tabs =
sidebar.tabs`). So a tab closed in one window is resurrected by any other window
that still lists it, and new windows are cloned with the whole set. Off, restore
comes from Firefox's per-window sessionstore.

## `browser.startup.page = 3`

Required alongside the above: `#shouldRestoreOnlyPinned` drops unpinned tabs
unless this is 3. Zen's built-in default is already 3, pinned here so it can't
drift.
