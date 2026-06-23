--[[
	NEMESIS — example / demo script
	Run this in your executor to see every component in action.
]]

local NEMESIS = loadstring(game:HttpGet("https://raw.githubusercontent.com/DiabloPaidProjects/NEMESIS/main/source.lua"))()

local Win = NEMESIS.Window({
	title = "NEMESIS",
	subtitle = "demo hub",
	accent = Color3.fromRGB(140, 90, 255),
	toggleKey = Enum.KeyCode.RightShift, -- press to hide/show (also a floating button on mobile)
})

----------------------------------------------------------------------
-- Tab 1: Main
----------------------------------------------------------------------
local Main = Win.Tab("Main")

Main.Section("Combat")

Main.Toggle({
	text = "Auto Farm",
	default = false,
	flag = "autofarm",
	callback = function(on)
		NEMESIS.Notify({ title = "Auto Farm", content = on and "Enabled" or "Disabled", duration = 2 })
	end,
})

Main.Slider({
	text = "Walk Speed",
	min = 16,
	max = 250,
	default = 16,
	increment = 1,
	suffix = "",
	flag = "walkspeed",
	callback = function(v)
		local char = game.Players.LocalPlayer.Character
		if char and char:FindFirstChild("Humanoid") then
			char.Humanoid.WalkSpeed = v
		end
	end,
})

Main.Dropdown({
	text = "Teleport",
	options = { "Spawn", "Shop", "Boss Arena" },
	default = "Spawn",
	flag = "tp_target",
	callback = function(choice)
		print("Teleport to", choice)
	end,
})

Main.Button({
	text = "Execute",
	callback = function()
		NEMESIS.Notify({ title = "Executed", content = "Ran the thing.", duration = 3 })
	end,
})

----------------------------------------------------------------------
-- Tab 2: Visuals
----------------------------------------------------------------------
local Visuals = Win.Tab("Visuals")

Visuals.Section("ESP")

Visuals.Toggle({ text = "Box ESP", default = false, flag = "esp_box" })
Visuals.Toggle({ text = "Name ESP", default = true, flag = "esp_name" })

Visuals.ColorPicker({
	text = "ESP Color",
	default = Color3.fromRGB(255, 0, 80),
	flag = "esp_color",
	callback = function(c)
		print("ESP color:", c)
	end,
})

Visuals.Dropdown({
	text = "Render (multi)",
	options = { "Players", "NPCs", "Items", "Chests" },
	multi = true,
	default = { "Players" },
	flag = "esp_targets",
})

----------------------------------------------------------------------
-- Tab 3: Misc
----------------------------------------------------------------------
local Misc = Win.Tab("Misc")

Misc.Section("Settings")

Misc.Input({
	text = "Webhook URL",
	placeholder = "https://...",
	clearOnFocus = false,
	flag = "webhook",
	callback = function(text)
		print("Webhook set:", text)
	end,
})

Misc.Keybind({
	text = "Panic Key",
	default = Enum.KeyCode.P,
	mode = "Toggle",
	flag = "panic",
	callback = function(state)
		print("Panic:", state)
	end,
})

Misc.Paragraph({
	title = "About",
	content = "NEMESIS UI — mobile-first, tweened, executor-friendly. Right-click a color swatch to copy its hex.",
})

Misc.Label("Tip: press RightShift to toggle the menu.")

----------------------------------------------------------------------
NEMESIS.Notify({ title = "NEMESIS", content = "Loaded successfully.", duration = 4 })
