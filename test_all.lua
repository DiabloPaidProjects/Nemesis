--[[
	NEMESIS v2.0 — full test bench
	Loadstring this in your executor. It exercises every component across the new
	Window -> Tab -> Group -> Page -> Section -> controls hierarchy.
	RightShift hides/shows, Ctrl+K focuses search, drag the grip to resize.
]]

-- ?_=os.time() busts GitHub's CDN / executor HTTP cache so you always get the latest
local NEMESIS = loadstring(game:HttpGet("https://raw.githubusercontent.com/DiabloPaidProjects/NEMESIS/main/source.lua?_=" .. tostring(os.time())))()

local function notify(t, c, d)
	NEMESIS.Notify({ title = t, content = c, duration = d or 3 })
end

local Win = NEMESIS.Window({
	title = "NEMESIS",
	accent = Color3.fromRGB(140, 90, 255),
	-- logoColor omitted -> uses the new purple default (override with any Color3)
	toggleKey = Enum.KeyCode.RightShift,
})

--====================================================================
-- TAB 1 — Elements (one Group, several Pages, every control)
--====================================================================
local Elements = Win.Tab("Elements", "layout-grid")
local Basic = Elements.Group("BASICS")

-- Page: Buttons & Toggles
local BT = Basic.Page("Buttons", { icon = "mouse-pointer-click" })
local s1 = BT.Section("BUTTONS & TOGGLES")
s1.Button({ text = "Plain Button", button = "Run", callback = function() notify("Button", "Clicked!", 2) end })
s1.Toggle({ text = "Toggle (off)", default = false, flag = "t_off",
	callback = function(v) notify("Toggle", "off-default is now " .. tostring(v), 2) end })
s1.Toggle({ text = "Toggle (on)", default = true, flag = "t_on" })
s1.Label("This is a plain Label — small muted text inside a section.")

-- Page: Sliders
local SL = Basic.Page("Sliders", { icon = "sliders-horizontal" })
local s2 = SL.Section("SLIDERS")
s2.Slider({ text = "Integer 0–250", min = 0, max = 250, default = 100, increment = 1, flag = "s_int" })
s2.Slider({ text = "Percent", min = 0, max = 100, default = 50, increment = 5, suffix = "%", flag = "s_pct" })
s2.Slider({ text = "Degrees", min = 0, max = 360, default = 90, increment = 15, suffix = "°", flag = "s_deg" })
s2.Slider({ text = "Decimal", min = 0, max = 1, default = 0.65, increment = 0.01, flag = "s_dec" })

-- Page: Inputs (dropdowns, input, keybinds)
local IN = Basic.Page("Inputs", { icon = "keyboard" })
local s3 = IN.Section("DROPDOWNS")
s3.Dropdown({ text = "Single select", options = { "Low", "Medium", "High", "Ultra" }, default = "Medium", flag = "dd_single",
	callback = function(v) notify("Dropdown", "chose " .. tostring(v), 1.5) end })
s3.Dropdown({ text = "Multi select", options = { "Players", "NPCs", "Items", "Chests", "Vehicles" },
	multi = true, default = { "Players", "Items" }, flag = "dd_multi",
	callback = function(list) notify("Multi", table.concat(list, ", "), 2) end })

local s4 = IN.Section("TEXT & KEYS")
s4.Input({ text = "Name", placeholder = "type here...", default = "", clearOnFocus = false, flag = "in_name",
	callback = function(s) notify("Input", "You typed: " .. s, 2) end })
s4.Input({ text = "Clears on focus", placeholder = "click me", clearOnFocus = true, flag = "in_clear" })
s4.Keybind({ text = "Toggle mode (E)", default = Enum.KeyCode.E, mode = "Toggle", flag = "kb_toggle",
	callback = function(state) notify("Keybind/Toggle", "state = " .. tostring(state), 1.5) end })
s4.Keybind({ text = "Hold mode (F)", default = Enum.KeyCode.F, mode = "Hold", flag = "kb_hold",
	callback = function(down) notify("Keybind/Hold", down and "DOWN" or "up", 1) end })
s4.Keybind({ text = "Always mode (G)", default = Enum.KeyCode.G, mode = "Always", flag = "kb_always",
	callback = function() notify("Keybind/Always", "fired", 1) end })
s4.Keybind({ text = "Mouse button", default = "MOUSE5", mode = "Hold", flag = "kb_mouse" })

-- Page: Colors
local CO = Basic.Page("Colors", { icon = "palette" })
local s5 = CO.Section("COLOR PICKERS")
s5.ColorPicker({ text = "Solid color", default = Color3.fromRGB(255, 0, 80), transparency = 0, flag = "c_solid",
	callback = function(color, alpha) notify("Color", "rgb set (a=" .. tostring(alpha) .. ")", 1.5) end })
s5.ColorPicker({ text = "With transparency", default = Color3.fromRGB(0, 200, 255), transparency = 0.3, flag = "c_alpha",
	callback = function(color, alpha) print("color", color, "transparency", alpha) end })

-- Standalone page (no group header)
local Info = Elements.Page("Info", { icon = "info" })
local s6 = Info.Section("ABOUT")
s6.Paragraph({ title = "Paragraph", content = "A title plus a longer wrapping body of text that demonstrates the Paragraph element inside a section." })
s6.Label("Standalone pages render below the groups, just like the mockup's Backtrack / Anti-Aim / Misc.")

--====================================================================
-- TAB 2 — Control (programmatic Set/Get)
--====================================================================
local ControlTab = Win.Tab("Control", "sliders-horizontal")
local Live = ControlTab.Page("Live", { icon = "settings-2" })
local s7 = Live.Section("DRIVEN BY BUTTONS")
local liveToggle = s7.Toggle({ text = "Controlled toggle", default = false, flag = "ctl_toggle" })
local liveSlider = s7.Slider({ text = "Controlled slider", min = 0, max = 100, default = 0, flag = "ctl_slider" })
local liveDrop = s7.Dropdown({ text = "Controlled dropdown", options = { "A", "B", "C" }, default = "A", flag = "ctl_drop" })

local s8 = Live.Section("ACTIONS")
s8.Button({ text = "Set toggle ON", button = "On", callback = function() liveToggle.Set(true) end })
s8.Button({ text = "Set toggle OFF", button = "Off", callback = function() liveToggle.Set(false) end })
s8.Button({ text = "Set slider = 75", button = "75", callback = function() liveSlider.Set(75) end })
s8.Button({ text = "Set dropdown = C", button = "C", callback = function() liveDrop.Set("C") end })
s8.Button({ text = "Read all values", button = "Read", callback = function()
	notify("Get()", "toggle=" .. tostring(liveToggle.Get())
		.. " slider=" .. tostring(liveSlider.Get())
		.. " drop=" .. tostring(liveDrop.Get()), 4)
end })

--====================================================================
-- TAB 3 — Layout (two groups so sidebar grouping + dividers show)
--====================================================================
local Layout = Win.Tab("Layout", "columns-2")
local Combat = Layout.Group("COMBAT")
local CombatMain = Combat.Page("Aimbot", { icon = "crosshair" })
local cm = CombatMain.Section("AIMBOT")
cm.Toggle({ text = "Enable", default = true, flag = "g_aim" })
cm.Slider({ text = "FOV", min = 0, max = 180, default = 120, suffix = "°", flag = "g_fov" })
cm.Dropdown({ text = "Target", options = { "Closest", "Health", "Random" }, default = "Closest", flag = "g_target" })

local VisualsG = Layout.Group("VISUALS")
local VisMain = VisualsG.Page("ESP", { icon = "eye" })
local vm = VisMain.Section("ESP")
vm.Toggle({ text = "Enabled", default = true, flag = "g_esp" })
vm.ColorPicker({ text = "Color", default = Color3.fromRGB(120, 255, 120), flag = "g_color" })
vm.Keybind({ text = "Toggle ESP", default = Enum.KeyCode.V, mode = "Toggle", flag = "g_espkey" })

-- standalone item under the Layout tab
local Extra = Layout.Page("Extra", { icon = "more-horizontal" })
Extra.Toggle({ text = "Page-level toggle (lazy section)", default = false, flag = "x_lazy" })

-- columns: explicit per-page column count + manual section placement
local Grid = Layout.Page("Grid", { icon = "grid-2x2", columns = 2 })
local gridL = Grid.Section("LEFT")                 -- auto-placed (column 1)
gridL.Toggle({ text = "Auto column 1", default = true, flag = "grid_a" })
gridL.Slider({ text = "Value", min = 0, max = 100, default = 40, flag = "grid_v" })
local gridR = Grid.Section("RIGHT", { column = 2 }) -- forced into column 2
gridR.Toggle({ text = "Manual column 2", default = false, flag = "grid_b" })
gridR.Dropdown({ text = "Mode", options = { "A", "B", "C" }, default = "A", flag = "grid_m" })

NEMESIS.Notify({ title = "NEMESIS", content = "Test bench loaded — explore every tab.", duration = 5 })
