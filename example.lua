--[[
	NEMESIS v2.0 — example / demo
	Desktop CS2 cheat-menu layout. Panels are laid out as a one-pager 2-column grid
	(set per-page with { columns = N }, or Window-wide with columns = N).
	Run in your executor. RightShift hides/shows, Ctrl+K focuses search,
	drag the dotted bottom-right grip to resize.
]]

local NEMESIS = loadstring(game:HttpGet("https://raw.githubusercontent.com/DiabloPaidProjects/NEMESIS/main/source.lua"))()

local Win = NEMESIS.Window({
	title = "NEMESIS",
	accent = Color3.fromRGB(140, 90, 255),
	game = "NEMESIS",
	logoColor = Color3.fromRGB(255, 45, 45), -- recolor the N logo to any hue (default red)
	columns = 2,                              -- panels per page (default 2 desktop / 1 mobile)
	-- logo = 0,  -- ← optional: your own uploaded Roblox image/decal ID overrides the built-in N
	configs = { "HvH", "Legit", "Rage", "Default" },
	toggleKey = Enum.KeyCode.RightShift,
	onSave = function() NEMESIS.Notify({ title = "Config", content = "Saved current config", duration = 2 }) end,
	onConfig = function(name) NEMESIS.Notify({ title = "Config", content = "Loaded: " .. name, duration = 2 }) end,
})

--====================================================================
-- COMBAT
--====================================================================
local Combat = Win.Tab("Combat")

-- AIMBOT group ------------------------------------------------------
local Aimbot = Combat.Group("AIMBOT")
local General = Aimbot.Page("General", { icon = "crosshair" })
local Targeting = Aimbot.Page("Targeting", { icon = "target" })
local Accuracy = Aimbot.Page("Accuracy", { icon = "crosshair" })
local AimAdvanced = Aimbot.Page("Advanced", { icon = "sliders-horizontal" })
local AimFilters = Aimbot.Page("Filters", { icon = "filter" })

-- General page: GENERAL + SMOOTH (left) | HITBOX (right) ------------
local gen = General.Section("GENERAL")
gen.Toggle({ text = "Enable", default = true, flag = "aim_enable" })
gen.Dropdown({ text = "Weapon Group", options = { "Rifles", "Pistols", "SMGs", "Snipers", "Heavy" }, default = "Rifles", flag = "aim_wg" })
gen.Dropdown({ text = "Fire Mode", options = { "On Key", "Always" }, default = "On Key", flag = "aim_fire" })
gen.Keybind({ text = "Keybind", default = "MOUSE5", mode = "Hold", flag = "aim_key" })
gen.Toggle({ text = "Enable in Air", default = false, flag = "aim_air" })

local hitbox = General.Section("HITBOX")
hitbox.Dropdown({ text = "Hitbox", options = { "Head", "Neck", "Chest", "Stomach", "Pelvis" }, default = "Head", flag = "hb_box" })
hitbox.Toggle({ text = "Multi-Point", default = true, flag = "hb_multi" })
hitbox.Slider({ text = "Point Scale", min = 0, max = 1, default = 0.65, increment = 0.01, flag = "hb_scale" })
hitbox.Dropdown({ text = "Priority", options = { "Head > Chest", "Chest > Head", "Head Only", "Closest" }, default = "Head > Chest", flag = "hb_prio" })
hitbox.Dropdown({ text = "Auto Fire", options = { "On Key", "Always", "Off" }, default = "On Key", flag = "hb_autofire" })
hitbox.Toggle({ text = "Silent Aim", default = true, flag = "hb_silent" })

local smooth = General.Section("SMOOTH")
smooth.Slider({ text = "Smooth", min = 0, max = 10, default = 3.5, increment = 0.1, flag = "sm_amount" })
smooth.Dropdown({ text = "Smooth Type", options = { "Linear", "Exponential", "Adaptive" }, default = "Exponential", flag = "sm_type" })
smooth.Slider({ text = "FOV", min = 0, max = 20, default = 2.5, increment = 0.1, flag = "sm_fov" })

-- Other AIMBOT sub-tabs (two panels each → balanced 2-column page)
local tgtA = Targeting.Section("SELECTION")
tgtA.Dropdown({ text = "Selection", options = { "FOV", "Distance", "Health", "Damage" }, default = "FOV", flag = "tgt_sel" })
tgtA.Slider({ text = "Max FOV", min = 0, max = 360, default = 180, increment = 1, suffix = "°", flag = "tgt_fov" })
local tgtB = Targeting.Section("FILTERS")
tgtB.Toggle({ text = "Visible Only", default = true, flag = "tgt_vis" })
tgtB.Toggle({ text = "Auto Wall", default = false, flag = "tgt_wall" })

local accA = Accuracy.Section("ACCURACY")
accA.Slider({ text = "Hit Chance", min = 0, max = 100, default = 70, increment = 1, suffix = "%", flag = "acc_hc" })
accA.Slider({ text = "Min Damage", min = 0, max = 100, default = 1, increment = 1, flag = "acc_dmg" })
local accB = Accuracy.Section("AUTOMATION")
accB.Toggle({ text = "Auto Scope", default = true, flag = "acc_scope" })
accB.Toggle({ text = "Auto Stop", default = false, flag = "acc_stop" })

local aadvA = AimAdvanced.Section("ADVANCED")
aadvA.Slider({ text = "Ping Compensation", min = 0, max = 400, default = 120, increment = 5, suffix = " ms", flag = "adv_ping" })
local aadvB = AimAdvanced.Section("SAFETY")
aadvB.Toggle({ text = "Prefer Body Aim", default = false, flag = "adv_body" })
aadvB.Toggle({ text = "Force Safe Point", default = false, flag = "adv_safe" })

local afilA = AimFilters.Section("TEAMS")
afilA.Dropdown({ text = "Target Teams", options = { "Enemies", "All", "Allies" }, default = "Enemies", flag = "fil_team" })
local afilB = AimFilters.Section("IGNORE")
afilB.Toggle({ text = "Ignore Knife", default = true, flag = "fil_knife" })
afilB.Toggle({ text = "Ignore Downed", default = false, flag = "fil_downed" })

-- TRIGGERBOT group --------------------------------------------------
local Trigger = Combat.Group("TRIGGERBOT")
local TrigGeneral = Trigger.Page("General", { icon = "grid-2x2" })
local TrigFilters = Trigger.Page("Filters", { icon = "sliders-horizontal" })
local TrigAdvanced = Trigger.Page("Advanced", { icon = "settings" })

local tgA = TrigGeneral.Section("GENERAL")
tgA.Toggle({ text = "Enable", default = false, flag = "tb_enable" })
tgA.Dropdown({ text = "Mode", options = { "On Key", "Always" }, default = "On Key", flag = "tb_mode" })
local tgB = TrigGeneral.Section("TIMING")
tgB.Keybind({ text = "Keybind", default = "MOUSE4", mode = "Hold", flag = "tb_key" })
tgB.Slider({ text = "Delay", min = 0, max = 300, default = 30, increment = 5, suffix = " ms", flag = "tb_delay" })

local tfA = TrigFilters.Section("FILTERS")
tfA.Dropdown({ text = "Hitboxes", options = { "Head", "Body", "Head + Body" }, default = "Head", flag = "tbf_hb" })
local tfB = TrigFilters.Section("OPTIONS")
tfB.Toggle({ text = "Visible Only", default = true, flag = "tbf_vis" })

local taA = TrigAdvanced.Section("ACCURACY")
taA.Slider({ text = "Hit Chance", min = 0, max = 100, default = 60, increment = 1, suffix = "%", flag = "tba_hc" })
local taB = TrigAdvanced.Section("MODE")
taB.Toggle({ text = "Burst Mode", default = false, flag = "tba_burst" })

-- Standalone sidebar items -----------------------------------------
local Backtrack = Combat.Page("Backtrack", { icon = "zap" })
local btA = Backtrack.Section("BACKTRACK")
btA.Toggle({ text = "Enable", default = true, flag = "bt_enable" })
btA.Slider({ text = "Max Time", min = 0, max = 400, default = 200, increment = 10, suffix = " ms", flag = "bt_time" })
local btB = Backtrack.Section("APPEARANCE")
btB.ColorPicker({ text = "Tick Color", default = Color3.fromRGB(140, 90, 255), transparency = 0, flag = "bt_col" })

local AntiAim = Combat.Page("Anti-Aim", { icon = "eye" })
local aaA = AntiAim.Section("ANGLES")
aaA.Toggle({ text = "Enable", default = false, flag = "aa_enable" })
aaA.Dropdown({ text = "Yaw", options = { "Backwards", "Spin", "Jitter", "Sideways" }, default = "Backwards", flag = "aa_yaw" })
local aaB = AntiAim.Section("PITCH")
aaB.Dropdown({ text = "Pitch", options = { "Down", "Up", "Zero" }, default = "Down", flag = "aa_pitch" })

local Misc = Combat.Page("Misc", { icon = "sliders-horizontal" })
local mcA = Misc.Section("MOVEMENT")
mcA.Toggle({ text = "Bunny Hop", default = false, flag = "mc_bhop" })
mcA.Toggle({ text = "Auto Strafe", default = false, flag = "mc_strafe" })
local mcB = Misc.Section("SPEED")
mcB.Slider({ text = "Walk Speed", min = 100, max = 400, default = 250, increment = 5, suffix = "%", flag = "mc_speed" })

--====================================================================
-- VISUALS
--====================================================================
local Visuals = Win.Tab("Visuals")
local Esp = Visuals.Group("PLAYER ESP")
local EspGeneral = Esp.Page("General", { icon = "eye" })
local EspColors = Esp.Page("Colors", { icon = "palette" })

local egA = EspGeneral.Section("BOXES")
egA.Toggle({ text = "Enabled", default = true, flag = "esp_box" })
egA.Dropdown({ text = "Box Type", options = { "2D", "Corner", "Filled" }, default = "Corner", flag = "esp_boxtype" })
local egB = EspGeneral.Section("INFO")
egB.Toggle({ text = "Health Bar", default = true, flag = "esp_hp" })
egB.Toggle({ text = "Name", default = true, flag = "esp_name" })

local ecA = EspColors.Section("VISIBLE")
ecA.ColorPicker({ text = "Color", default = Color3.fromRGB(120, 255, 120), transparency = 0, flag = "esp_cvis" })
local ecB = EspColors.Section("OCCLUDED")
ecB.ColorPicker({ text = "Color", default = Color3.fromRGB(255, 80, 80), transparency = 0.2, flag = "esp_cocc" })

local Other = Visuals.Group("WORLD")
local WorldGen = Other.Page("General", { icon = "globe" })
local wvA = WorldGen.Section("LIGHTING")
wvA.Toggle({ text = "Full Bright", default = false, flag = "w_bright" })
local wvB = WorldGen.Section("NIGHT")
wvB.Slider({ text = "Night Mode", min = 0, max = 100, default = 0, increment = 1, suffix = "%", flag = "w_night" })

--====================================================================
-- PLAYER / WORLD / CONFIG (stubbed so every top tab navigates)
--====================================================================
local Player = Win.Tab("Player")
local PlayerMain = Player.Group("PLAYER").Page("Movement", { icon = "person-standing" })
local pmA = PlayerMain.Section("MOVEMENT")
pmA.Slider({ text = "Walk Speed", min = 16, max = 500, default = 16, increment = 1, flag = "p_speed" })
pmA.Slider({ text = "Jump Power", min = 50, max = 500, default = 50, increment = 5, flag = "p_jump" })
local pmB = PlayerMain.Section("CLIP")
pmB.Toggle({ text = "No Clip", default = false, flag = "p_noclip" })

local World = Win.Tab("World")
local WorldMain = World.Group("WORLD").Page("Environment", { icon = "globe" })
local wmA = WorldMain.Section("TIME")
wmA.Slider({ text = "Time of Day", min = 0, max = 24, default = 14, increment = 1, suffix = "h", flag = "wo_time" })
local wmB = WorldMain.Section("WEATHER")
wmB.Toggle({ text = "Remove Fog", default = false, flag = "wo_fog" })

local Config = Win.Tab("Config")
local ConfigMain = Config.Page("Settings", { icon = "settings" })
local cs = ConfigMain.Section("INTERFACE")
cs.Keybind({ text = "Menu Key", default = Enum.KeyCode.RightShift, mode = "Toggle", flag = "cfg_menukey" })
cs.ColorPicker({ text = "Accent", default = Color3.fromRGB(140, 90, 255), transparency = 0, flag = "cfg_accent" })
cs.ColorPicker({ text = "Logo Color", default = Color3.fromRGB(255, 45, 45), transparency = 0, flag = "cfg_logo",
	callback = function(color) Win.SetLogoColor(color) end })
cs.Dropdown({ text = "Logo Preset", options = { "Red", "Purple", "Pink", "Green", "Yellow", "Cyan", "White" }, default = "Red", flag = "cfg_logo_preset",
	callback = function(v)
		local map = {
			Red = Color3.fromRGB(255, 45, 45), Purple = Color3.fromRGB(180, 90, 255),
			Pink = Color3.fromRGB(255, 90, 200), Green = Color3.fromRGB(90, 255, 120),
			Yellow = Color3.fromRGB(255, 210, 40), Cyan = Color3.fromRGB(60, 220, 255),
			White = Color3.fromRGB(245, 245, 250),
		}
		Win.SetLogoColor(map[v])
	end })
cs.Input({ text = "Config Name", placeholder = "my-config", flag = "cfg_name" })
cs.Button({ text = "Save Config", button = "Save", callback = function()
	NEMESIS.Notify({ title = "Config", content = "Saved", duration = 2 })
end })

local about = ConfigMain.Section("ABOUT")
about.Paragraph({ title = "NEMESIS v2.0", content = "Desktop cheat-menu layout with a one-pager 2-column panel grid, collapsible sections, smooth fade scroll, recolorable logo, and live FPS. Right-click a color swatch to copy its hex." })

NEMESIS.Notify({ title = "NEMESIS", content = "Loaded — Combat ▸ Aimbot ▸ General", duration = 5 })
