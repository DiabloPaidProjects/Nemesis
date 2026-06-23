--[[
	Smoke test for NEMESIS. Run from the repo root:
		lua  test/smoke.lua
		luau test/smoke.lua   (luau may lack dofile; lua is preferred)

	Loads source.lua under the Roblox stub and asserts the full API surface
	can be constructed and that controls' .Set/.Get behave.
]]

dofile("test/stub.lua")

local NEMESIS = dofile("source.lua")

local function check(cond, msg)
	if not cond then
		error("FAIL: " .. msg, 2)
	end
	print("  ok: " .. msg)
end

print("NEMESIS smoke test")
check(type(NEMESIS) == "table", "module returns a table")
check(type(NEMESIS.Window) == "function", "NEMESIS.Window exists")
check(type(NEMESIS.Notify) == "function", "NEMESIS.Notify exists")
check(type(NEMESIS.Flags) == "table", "NEMESIS.Flags table exists")

local Win = NEMESIS.Window({
	title = "Test",
	subtitle = "smoke",
	accent = Color3.fromRGB(140, 90, 255),
	toggleKey = Enum.KeyCode.RightShift,
})
check(type(Win) == "table", "Window returns a table")
check(type(Win.Tab) == "function", "Win.Tab exists")
check(type(Win.Toggle) == "function", "Win.Toggle exists")
check(type(Win.Destroy) == "function", "Win.Destroy exists")

local Tab = Win.Tab("Main")
local Tab2 = Win.Tab("Second")
check(type(Tab) == "table" and type(Tab2) == "table", "two tabs created")

Tab.Section("Combat")

local btn = Tab.Button({ text = "Execute", callback = function() end })
check(type(btn) == "table", "Button created")

local tog = Tab.Toggle({ text = "Auto Farm", default = true, flag = "autofarm", callback = function() end })
check(tog.Get() == true, "Toggle default true")
tog.Set(false)
check(tog.Get() == false, "Toggle Set(false)")
check(NEMESIS.Flags.autofarm == false, "Toggle flag synced to Flags")

local sld = Tab.Slider({ text = "Speed", min = 0, max = 100, default = 50, increment = 5, suffix = " s", flag = "speed" })
check(sld.Get() == 50, "Slider default 50")
sld.Set(75)
check(sld.Get() == 75, "Slider Set(75)")
check(NEMESIS.Flags.speed == 75, "Slider flag synced")

local dd = Tab.Dropdown({ text = "Mode", options = { "A", "B", "C" }, default = "A", flag = "mode" })
check(dd.Get() == "A", "Dropdown default A")
dd.Set("B")
check(dd.Get() == "B", "Dropdown Set(B)")
dd.SetOptions({ "X", "Y", "Z" })
check(type(dd.Get) == "function", "Dropdown SetOptions ok")

local mdd = Tab.Dropdown({ text = "Multi", options = { "x", "y", "z" }, multi = true, default = { "x" }, flag = "multi" })
local got = mdd.Get()
check(type(got) == "table" and got[1] == "x", "Multi dropdown default")

local inp = Tab.Input({ text = "Name", default = "hello", placeholder = "type", flag = "name" })
check(inp.Get() == "hello", "Input default")
inp.Set("world")
check(inp.Get() == "world", "Input Set")

local kb = Tab.Keybind({ text = "Bind", default = Enum.KeyCode.E, mode = "Toggle", flag = "bind", callback = function() end })
check(type(kb.Get) == "function", "Keybind created")

local cp = Tab.ColorPicker({ text = "Color", default = Color3.fromRGB(255, 0, 0), flag = "color", callback = function() end })
cp.Set(Color3.fromRGB(0, 255, 0))
check(type(cp.Get()) == "table", "ColorPicker Set/Get")

local lbl = Tab.Label("a label")
lbl.Set("updated")
check(lbl.Get() == "updated", "Label Set/Get")

local para = Tab.Paragraph({ title = "Notes", content = "some body text" })
check(type(para) == "table", "Paragraph created")

NEMESIS.Notify({ title = "Loaded", content = "NEMESIS ready", duration = 2 })
print("  ok: Notify ran without error")

print("\nALL CHECKS PASSED")
