--[[
	Minimal Roblox-environment stub for offline smoke-testing NEMESIS with
	plain `lua` / `luau`. It installs just enough globals for source.lua to
	LOAD and CONSTRUCT its UI table without a real Roblox runtime.

	It does NOT emulate rendering, input, or tweening — event callbacks and
	tweens are no-ops. It verifies the library parses, builds every element,
	and that .Set/.Get behave. Visual behaviour is validated in-executor.

	dofile this before dofile("source.lua").
]]

----------------------------------------------------------------------
-- math.clamp (Luau/Roblox extension, absent in standard Lua)
----------------------------------------------------------------------
if not math.clamp then
	function math.clamp(x, a, b)
		if x < a then return a elseif x > b then return b else return x end
	end
end

----------------------------------------------------------------------
-- Instance mock
----------------------------------------------------------------------
local EVENT_KEYS = {
	InputBegan = true, InputChanged = true, InputEnded = true,
	MouseButton1Click = true, MouseButton2Click = true, MouseButton1Down = true,
	MouseButton1Up = true, MouseEnter = true, MouseLeave = true, MouseMoved = true,
	FocusLost = true, Focused = true, Changed = true, Activated = true,
}

local METHODS
local instMeta = {}

local function newInstance(className)
	local self = setmetatable({}, instMeta)
	rawset(self, "_props", { ClassName = className, Name = className })
	rawset(self, "_children", {})
	rawset(self, "_signals", {})
	return self
end

local function signal()
	return {
		Connect = function() return { Disconnect = function() end, Connected = true } end,
		Once = function() return { Disconnect = function() end } end,
		Wait = function() end,
	}
end

METHODS = {
	Destroy = function(self) self._props.Parent = nil end,
	GetChildren = function(self)
		local t = {}
		for i, c in ipairs(self._children) do t[i] = c end
		return t
	end,
	GetDescendants = function() return {} end,
	IsA = function(self, cn) return self._props.ClassName == cn end,
	FindFirstChild = function(self, name)
		for _, c in ipairs(self._children) do
			if c._props.Name == name then return c end
		end
		return nil
	end,
	FindFirstChildOfClass = function(self, cn)
		for _, c in ipairs(self._children) do
			if c._props.ClassName == cn then return c end
		end
		return nil
	end,
	WaitForChild = function(self, name)
		return METHODS.FindFirstChild(self, name) or newInstance(name)
	end,
	GetPropertyChangedSignal = function() return signal() end,
	Clone = function(self) return newInstance(self._props.ClassName) end,
	TweenSize = function() end,
}

instMeta.__index = function(self, k)
	if EVENT_KEYS[k] then
		local s = self._signals[k]
		if not s then
			s = signal()
			self._signals[k] = s
		end
		return s
	end
	if METHODS[k] then return METHODS[k] end
	return self._props[k]
end

instMeta.__newindex = function(self, k, v)
	if k == "Parent" then
		self._props.Parent = v
		if type(v) == "table" and rawget(v, "_children") then
			table.insert(v._children, self)
		end
	else
		self._props[k] = v
	end
end

Instance = { new = function(cn) return newInstance(cn) end }

----------------------------------------------------------------------
-- Datatypes
----------------------------------------------------------------------
local function color3(r, g, b)
	return {
		R = r, G = g, B = b,
		ToHSV = function() return 0, 0, 0 end,
		Lerp = function(self) return self end,
	}
end
Color3 = {
	new = function(r, g, b) return color3(r or 0, g or 0, b or 0) end,
	fromRGB = function(r, g, b) return color3((r or 0) / 255, (g or 0) / 255, (b or 0) / 255) end,
	fromHSV = function(h, s, v) return color3(h or 0, s or 0, v or 0) end,
}

Vector2 = {
	new = function(x, y) return { X = x or 0, Y = y or 0 } end,
}

UDim = {
	new = function(s, o) return { Scale = s or 0, Offset = o or 0 } end,
}
UDim2 = {
	new = function(xs, xo, ys, yo)
		return { X = { Scale = xs or 0, Offset = xo or 0 }, Y = { Scale = ys or 0, Offset = yo or 0 } }
	end,
	fromOffset = function(xo, yo)
		return { X = { Scale = 0, Offset = xo or 0 }, Y = { Scale = 0, Offset = yo or 0 } }
	end,
}

TweenInfo = { new = function() return {} end }

----------------------------------------------------------------------
-- Enum (permissive — any chain returns a harmless sentinel)
----------------------------------------------------------------------
local enumMeta
enumMeta = {
	__index = function() return setmetatable({ Name = "EnumItem", Value = 0 }, enumMeta) end,
}
Enum = setmetatable({}, enumMeta)

----------------------------------------------------------------------
-- Services + game
----------------------------------------------------------------------
local function makeServiceInstance(name, props)
	local inst = newInstance(name)
	if props then
		for k, v in pairs(props) do inst[k] = v end
	end
	return inst
end

local TweenServiceStub = {
	Create = function(_, _, _, _)
		return { Play = function() end, Cancel = function() end, Completed = signal() }
	end,
}

local services = {
	TweenService = TweenServiceStub,
	UserInputService = makeServiceInstance("UserInputService", {
		TouchEnabled = false, KeyboardEnabled = true, MouseEnabled = true, GamepadEnabled = false,
	}),
	RunService = makeServiceInstance("RunService"),
	CoreGui = makeServiceInstance("CoreGui"),
	HttpService = makeServiceInstance("HttpService"),
	GuiService = makeServiceInstance("GuiService"),
}
local playerGui = newInstance("PlayerGui")
local localPlayer = makeServiceInstance("Player", { Name = "TestPlayer" })
localPlayer.PlayerGui = playerGui
table.insert(localPlayer._children, playerGui)
services.Players = makeServiceInstance("Players", { LocalPlayer = localPlayer })

game = {
	GetService = function(_, name)
		if not services[name] then
			services[name] = makeServiceInstance(name)
		end
		return services[name]
	end,
	HttpGet = function() return "" end,
}
setmetatable(game, { __index = function(_, k) return services[k] end })

----------------------------------------------------------------------
-- workspace (CurrentCamera.ViewportSize)
----------------------------------------------------------------------
workspace = newInstance("Workspace")
local camera = newInstance("Camera")
camera.ViewportSize = Vector2.new(1280, 720)
workspace.CurrentCamera = camera

----------------------------------------------------------------------
-- task scheduler (no-op: do not run deferred callbacks during smoke test)
----------------------------------------------------------------------
task = {
	spawn = function() end,
	delay = function() end,
	wait = function() return 0 end,
	defer = function() end,
}
if not wait then wait = function() return 0 end end
