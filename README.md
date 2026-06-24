# NEMESIS

A **desktop cheat-menu** Roblox/Luau UI library for script executors — horizontal top tabs, a grouped left sidebar of sub-tabs, collapsible content sections with inline rows, a breadcrumb + config bar, a full color picker, live FPS footer, smooth tweened transitions, and broad executor compatibility. Inspired by neverlose, gamesense, and onetap layouts.

```lua
local NEMESIS = loadstring(game:HttpGet("https://raw.githubusercontent.com/DiabloPaidProjects/NEMESIS/main/source.lua"))()
```

> **v2.0** is a layout redesign. The navigation is now two levels deep
> (**Tab → Group → Page → Section → controls**) and replaces the v1 single-level
> `Win.Tab` / `Tab.GroupBox` API. It is **desktop-first** but still responsive-scales
> down on touch.

## Features

- 🧭 **Two-level navigation** — a horizontal **top tab bar** (Combat / Visuals / …) plus a **grouped left sidebar** of sub-tabs (group headers + pages + standalone items, with an active highlight, accent bar, and optional dot).
- 🗂️ **Collapsible sections** — `Page.Section("GENERAL")` cards whose header chevron collapses the rows.
- ↔️ **Inline rows** — label on the left, control on the right, hairline separators between rows (the classic cheat-menu layout).
- 🧭 **Breadcrumb + config bar** — auto `Tab › Group › Page` breadcrumb, a config dropdown, a save button, and a 3-dot menu in the content header.
- 📊 **Status footer** — game name, connection state, live FPS, and folder/save config buttons.
- 🎨 **Full color picker** — pop-out panel: saturation/value square, hue slider, alpha slider, editable HEX + percentage.
- 🖼️ **Icons** — Lucide names (`icon = "crosshair"`) or raw asset IDs.
- 🔎 **Search** — top-bar search filters the active page (Ctrl+K to focus).
- 📱 **Touch support** — responsive scaling, touch-drag, a floating reopen button on phones.
- ⌨️ **Mouse-button keybinds** — keybinds accept `Enum.KeyCode` values or mouse strings like `"MOUSE5"`.
- 🔌 **Executor-friendly** — `gethui` → `protect_gui` → `CoreGui` → `PlayerGui` parenting fallback; every executor global is feature-detected and `pcall`-guarded.
- 🧩 **Components** — Button, Toggle, Slider, Dropdown (single + multi), Input, Keybind, ColorPicker, Label, Paragraph + notifications.

## Quick start

```lua
local NEMESIS = loadstring(game:HttpGet("https://raw.githubusercontent.com/DiabloPaidProjects/NEMESIS/main/source.lua"))()

local Win = NEMESIS.Window({ title = "NEMESIS", game = "CS2", configs = { "HvH", "Legit" } })

local Combat  = Win.Tab("Combat")                                  -- top tab
local Aimbot  = Combat.Group("AIMBOT")                             -- sidebar group
local General = Aimbot.Page("General", { icon = "crosshair", dot = true })  -- sub-tab

local gen = General.Section("GENERAL")                             -- collapsible section
gen.Toggle({ text = "Enable", default = true, flag = "aim_enable" })
gen.Dropdown({ text = "Weapon Group", options = { "Rifles", "Pistols" }, default = "Rifles" })
gen.Keybind({ text = "Keybind", default = "MOUSE5", mode = "Hold" })

NEMESIS.Notify({ title = "Loaded", content = "NEMESIS ready", duration = 4 })
```

See [`example.lua`](example.lua) for a full screen reproduction and [`test_all.lua`](test_all.lua) for every component.

## API

The API is **dot-style** — call methods with `.` (not `:`). Option tables use lowercase keys; the callback key is always `callback`.

### `NEMESIS.Window(options)` → `Win`

| Option | Type | Default | Description |
|---|---|---|---|
| `title` | string | `"NEMESIS"` | Wordmark next to the logo. |
| `logo` | number \| string? | — | Override the logo with your own Roblox image/decal ID. By default the real **NEMESIS** brand image auto-loads (downloaded + shown via `getcustomasset`, no upload); on executors without custom-asset support it falls back to a gradient "N" tile. |
| `accent` | Color3? | purple | Accent for highlights, toggles, sliders, underline. |
| `game` | string? | `"Game"` | Footer game name (next to the green status dot). |
| `status` | string? | `"Connected"` | Footer status line under the game name. |
| `configs` | string[]? | `{ "Default" }` | Options for the content-header config dropdown. |
| `toggleKey` | KeyCode? | `RightShift` | Key to hide/show the window. |
| `width` | number? | `960` (desktop) | Window width (px, before scaling). |
| `height` | number? | `640` (desktop) | Window height (px, before scaling). |
| `onSave` | function? | — | Fired by the save buttons (else a "Saved" toast). |
| `onConfig` | function(name)? | — | Fired when the config dropdown changes. |
| `onMenu` / `onFolder` | function? | — | Fired by the 3-dot / folder buttons. |

Returns `Win` with: `Win.Tab(name)`, `Win.Toggle(force?)` (minimize/restore), `Win.Destroy()`, `Win.Notify(...)`, `Win.Instance`. The top bar has search + minimize + close; the menu drags by its top bar and resizes from the dotted bottom-right grip.

### `Win.Tab(name)` → `Tab`

Adds a **top-bar tab** (and its own sidebar) and returns a `Tab`. The first tab created is shown by default.

```lua
local Combat = Win.Tab("Combat")

Combat.Group("AIMBOT")              -- sidebar group header → has .Page(...)
Combat.Page("Misc", { icon = "x" }) -- standalone sidebar item (no group header)
```

| `Tab` method | Returns | Description |
|---|---|---|
| `Tab.Group(name)` | `Group` | A sidebar section header (purple uppercase). Subsequent groups get a divider above them. |
| `Tab.Page(name, opts?)` | `Page` | A **standalone** sidebar sub-tab (rendered below the groups). |

### `Group.Page(name, opts?)` → `Page`

A sidebar sub-tab under a group. `opts`:

| Page option | Type | Description |
|---|---|---|
| `icon` | string \| number | Lucide name, `"rbxassetid://N"`, or numeric asset ID. |

The first page created in a tab is its default-active page. Clicking a page swaps the content area; the breadcrumb updates to `Tab › Group › Page`.

### `Page.Section(title?)` → `Section`

A collapsible card in the content area. Click the header chevron to collapse it. Returns a host with the element creators below. (`Page` also exposes those creators directly — they go into a lazily-created untitled section.)

```lua
local s = General.Section("GENERAL")
s.Toggle({ text = "Enable", default = true })
```

### Components

Created on a `Section` (or directly on a `Page`). Value components accept an optional `flag` (mirrored into `NEMESIS.Flags[flag]`) and return a **control** with `.Set(value)` / `.Get()`.

```lua
s.Button({ text = "Execute", button = "Run", callback = function() end })

local t = s.Toggle({ text = "Toggle", default = false, flag = "f1", callback = function(v) end })
t.Set(true); print(t.Get())

s.Slider({ text = "Point Scale", min = 0, max = 1, default = 0.65, increment = 0.01, suffix = "", flag = "f2", callback = function(v) end })
-- decimals auto from increment (<1 → 2dp); override with `decimals = N`.

s.Dropdown({ text = "Mode", options = {"A","B","C"}, default = "A", flag = "f3", callback = function(v) end })
s.Dropdown({ text = "Targets", options = {"x","y","z"}, multi = true, default = {"x"}, flag = "f4", callback = function(list) end })

s.Input({ text = "Name", placeholder = "type…", default = "", clearOnFocus = false, flag = "f5", callback = function(text) end })

s.Keybind({ text = "Keybind", default = "MOUSE5", mode = "Hold", flag = "f6", callback = function(state) end })
-- default: Enum.KeyCode value OR a mouse string ("MOUSE1"/"MOUSE2"/"MOUSE3"; "MOUSE4"/"MOUSE5" display only)
-- mode: "Toggle" | "Hold" | "Always". Click the field then press a key/right-or-middle mouse to rebind (Esc clears).

s.ColorPicker({ text = "Color", default = Color3.fromRGB(255,0,80), transparency = 0, flag = "f7", callback = function(color, alpha) end })
-- click the swatch → full panel (SV square, hue, alpha, editable HEX + %). right-click to copy hex.
-- control extras: cp.Set(color, alpha?), cp.GetAlpha()

local lbl = s.Label("plain text"); lbl.Set("new text")
s.Paragraph({ title = "Title", content = "longer body text" })
```

**Control methods** (Toggle / Slider / Dropdown / Input / Keybind / ColorPicker / Label):
- `control.Set(value)` — set the value programmatically (fires the callback).
- `control.Get()` — read the current value.
- Dropdown also has `control.SetOptions({...})` and `control.Toggle(force?)`.

### `NEMESIS.Notify(options)`

```lua
NEMESIS.Notify({ title = "Title", content = "Body", duration = 4 })
```

### `NEMESIS.Flags`

Every component with a `flag` writes its current value to `NEMESIS.Flags[flag]`:

```lua
if NEMESIS.Flags.aim_enable then ... end
```

> Flags are kept **in memory** for the session. Disk-based config saving is planned for a later version (the save / folder buttons currently fire `onSave` / `onFolder`).

## Mobile

- The window auto-scales to the device viewport and uses larger touch targets on phones.
- The top bar is drag-movable with both mouse and touch.
- On touch devices a draggable floating **N** button appears to hide/show the menu (the keyboard `toggleKey` still works on desktop).

## Testing

There is no Roblox runtime offline, so a stub mock is used to verify the library **parses, constructs every element, and that `.Set`/`.Get` behave**:

```sh
lua test/smoke.lua          # builds the full API under test/stub.lua
luau-analyze source.lua     # syntax / type check
```

Visual and touch behaviour is validated in-executor.

## License

[MIT](LICENSE)
