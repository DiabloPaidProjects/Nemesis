# NEMESIS

A **mobile-first** Roblox/Luau UI library for script executors — clean single-window layout, smooth tweened transitions, and broad executor compatibility. Inspired by Rayfield, Obsidian, neverlose-ui, and syde.

```lua
local NEMESIS = loadstring(game:HttpGet("https://raw.githubusercontent.com/DiabloPaidProjects/NEMESIS/main/source.lua"))()
```

## Features

- 🎯 **Rayfield-style layout** — one window, tab sidebar, single scrolling column.
- 📱 **Mobile / touch support** — responsive scaling, touch-drag, and a floating reopen button on phones.
- ✨ **Smooth transitions** — every state change (open/close, toggle, tab switch, dropdown, notify) is `TweenService`-animated.
- 🔌 **Executor-friendly** — `gethui` → `protect_gui` → `CoreGui` → `PlayerGui` parenting fallback; every executor global is feature-detected and `pcall`-guarded, so it degrades instead of erroring.
- 🧩 **Full component set** — Section, Button, Toggle, Slider, Dropdown (single + multi), Input, Keybind, ColorPicker, Label, Paragraph.
- 🔔 **Notifications** — tweened toast stack.

## Quick start

```lua
local NEMESIS = loadstring(game:HttpGet("https://raw.githubusercontent.com/DiabloPaidProjects/NEMESIS/main/source.lua"))()

local Win = NEMESIS.Window({ title = "NEMESIS", subtitle = "by you" })
local Tab = Win.Tab("Main")

Tab.Section("Combat")
Tab.Toggle({ text = "Auto Farm", default = false, flag = "autofarm", callback = function(on)
    print("Auto farm:", on)
end })

NEMESIS.Notify({ title = "Loaded", content = "NEMESIS ready", duration = 4 })
```

See [`example.lua`](example.lua) for a full demo of every component.

## API

The API is **dot-style** — call methods with `.` (not `:`). Option tables use lowercase keys; the callback key is always `callback`.

### `NEMESIS.Window(options)` → `Win`

| Option | Type | Default | Description |
|---|---|---|---|
| `title` | string | `"NEMESIS"` | Window title. |
| `subtitle` | string? | — | Small text under the title. |
| `accent` | Color3? | purple | Accent color for highlights, toggles, sliders. |
| `toggleKey` | KeyCode? | `RightShift` | Key to hide/show the window. |

Returns `Win` with: `Win.Tab(name)`, `Win.Toggle(force?)` (hide/show), `Win.Destroy()`, `Win.Notify(...)`, `Win.Instance`.

### `Win.Tab(name, icon?)` → `Tab`

Adds a sidebar tab and returns a `Tab` with all the element creators below plus `Tab.Section(title)`. The first tab created is shown by default.

### Components

Every component is created on a `Tab`. Components that hold a value accept an optional `flag` (mirrored into `NEMESIS.Flags[flag]`) and return a **control** with `.Set(value)` and `.Get()`.

```lua
Tab.Section("Combat")                  -- header / divider

Tab.Button({ text = "Execute", callback = function() end })

local t = Tab.Toggle({ text = "Toggle", default = false, flag = "f1", callback = function(v) end })
t.Set(true); print(t.Get())

Tab.Slider({ text = "Speed", min = 0, max = 100, default = 50, increment = 1, suffix = " st", flag = "f2", callback = function(v) end })

Tab.Dropdown({ text = "Mode", options = {"A","B","C"}, default = "A", flag = "f3", callback = function(v) end })
Tab.Dropdown({ text = "Multi", options = {"x","y","z"}, multi = true, default = {"x"}, flag = "f4", callback = function(list) end })

Tab.Input({ text = "Name", placeholder = "type…", default = "", clearOnFocus = false, flag = "f5", callback = function(text) end })

Tab.Keybind({ text = "Bind", default = Enum.KeyCode.E, mode = "Toggle", flag = "f6", callback = function(state) end })
-- mode: "Toggle" | "Hold" | "Always"

Tab.ColorPicker({ text = "Color", default = Color3.fromRGB(255,0,80), flag = "f7", callback = function(c) end })
-- right-click the swatch to copy hex (if the executor supports setclipboard)

local lbl = Tab.Label("plain text"); lbl.Set("new text")
Tab.Paragraph({ title = "Title", content = "longer body text" })
```

**Control methods** (returned by Toggle / Slider / Dropdown / Input / Keybind / ColorPicker / Label):
- `control.Set(value)` — set the value programmatically (fires the callback).
- `control.Get()` — read the current value.
- Dropdown also has `control.SetOptions({...})` and `control.Toggle(force?)`.

### `NEMESIS.Notify(options)`

```lua
NEMESIS.Notify({ title = "Title", content = "Body", duration = 4 })
```

### `NEMESIS.Flags`

Every component with a `flag` writes its current value to `NEMESIS.Flags[flag]`, so you can read all state at once:

```lua
if NEMESIS.Flags.autofarm then ... end
```

> Note: v1 keeps flags **in memory** for the session. Disk-based config saving is planned for a later version.

## Mobile

- The window auto-scales to the device viewport and uses larger touch targets on phones.
- The title bar is drag-movable with both mouse and touch.
- On touch devices a draggable floating **N** button appears to hide/show the menu (the keyboard `toggleKey` still works on desktop).
- Honors device safe-area insets (notches) where supported.

## Executor compatibility

NEMESIS targets the common executor surface and never hard-errors on a missing API:
- **GUI parent:** `gethui()` → `get_hidden_gui()` → `syn.protect_gui` + `CoreGui` → `PlayerGui`.
- **Clipboard:** `setclipboard` / `toclipboard` (color hex copy) — optional.
- No file or HTTP dependency at runtime, so it loads even on minimal executors.

## License

[MIT](LICENSE)
