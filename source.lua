--[[
	NEMESIS UI Library  (v1)
	A mobile-first Roblox/Luau UI library for script executors.

	Load:
		local NEMESIS = loadstring(game:HttpGet("https://raw.githubusercontent.com/DiabloPaidProjects/NEMESIS/main/source.lua"))()

	Features:
		- Rayfield-style single-window layout: tab sidebar + one scrolling column
		- Smooth TweenService transitions on every state change
		- Mobile / touch support (responsive scale, touch drag, floating reopen button)
		- Broad executor compatibility (gethui / protect_gui / CoreGui / PlayerGui fallback)
		- Components: Section, Button, Toggle, Slider, Dropdown, Input, Keybind, ColorPicker, Label, Paragraph
		- Tweened notifications

	API uses dot-style closures, e.g.
		local Win = NEMESIS.Window({ title = "NEMESIS" })
		local Tab = Win.Tab("Main")
		Tab.Toggle({ text = "Auto Farm", default = false, flag = "autofarm", callback = function(v) end })
]]

local NEMESIS = {}
NEMESIS.Flags = {}
NEMESIS.Version = "1.0.0"

----------------------------------------------------------------------
-- Services (cloneref-safe)
----------------------------------------------------------------------
local function getService(name)
	local ok, svc = pcall(function()
		return game:GetService(name)
	end)
	if ok and svc then
		if type(cloneref) == "function" then
			local ok2, c = pcall(cloneref, svc)
			if ok2 and c then
				return c
			end
		end
		return svc
	end
	return nil
end

local TweenService = getService("TweenService")
local UserInputService = getService("UserInputService")
local RunService = getService("RunService")
local Players = getService("Players")
local CoreGui = getService("CoreGui")

----------------------------------------------------------------------
-- Executor compatibility
----------------------------------------------------------------------
local function localPlayer()
	return Players and Players.LocalPlayer
end

local function getGuiParent()
	if type(gethui) == "function" then
		local ok, h = pcall(gethui)
		if ok and h then return h end
	end
	if type(get_hidden_gui) == "function" then
		local ok, h = pcall(get_hidden_gui)
		if ok and h then return h end
	end
	if CoreGui then
		return CoreGui
	end
	local lp = localPlayer()
	if lp then
		return lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui")
	end
	return nil
end

local function protectGui(gui)
	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(gui)
		elseif type(protectgui) == "function" then
			protectgui(gui)
		end
	end)
end

local function setClipboard(text)
	for _, fn in ipairs({ setclipboard, toclipboard, set_clipboard }) do
		if type(fn) == "function" then
			pcall(fn, text)
			return true
		end
	end
	return false
end

----------------------------------------------------------------------
-- Instance helper
----------------------------------------------------------------------
local function Create(class, props, children)
	local inst = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then
				inst[k] = v
			end
		end
	end
	if children then
		for _, c in ipairs(children) do
			c.Parent = inst
		end
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function corner(rad)
	return Create("UICorner", { CornerRadius = UDim.new(0, rad or 8) })
end

local function stroke(color, thickness, transparency)
	return Create("UIStroke", {
		Color = color or Color3.fromRGB(45, 45, 58),
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function padding(all)
	return Create("UIPadding", {
		PaddingTop = UDim.new(0, all),
		PaddingBottom = UDim.new(0, all),
		PaddingLeft = UDim.new(0, all),
		PaddingRight = UDim.new(0, all),
	})
end

----------------------------------------------------------------------
-- Theme
----------------------------------------------------------------------
local THEME = {
	Background = Color3.fromRGB(18, 18, 24),
	Sidebar = Color3.fromRGB(23, 23, 31),
	Topbar = Color3.fromRGB(22, 22, 30),
	Element = Color3.fromRGB(30, 30, 40),
	ElementHover = Color3.fromRGB(38, 38, 50),
	Stroke = Color3.fromRGB(45, 45, 58),
	Text = Color3.fromRGB(235, 235, 240),
	SubText = Color3.fromRGB(150, 150, 165),
	Accent = Color3.fromRGB(140, 90, 255),
	Knob = Color3.fromRGB(240, 240, 245),
}

local FONT = Enum.Font.Gotham
local FONT_MED = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

----------------------------------------------------------------------
-- Tween helpers
----------------------------------------------------------------------
local TI = {
	OPEN = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	HOVER = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	SLIDE = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	NOTIFY = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
}

local function tween(inst, props, info)
	local t = TweenService:Create(inst, info or TI.SLIDE, props)
	t:Play()
	return t
end

----------------------------------------------------------------------
-- Mobile / scale
----------------------------------------------------------------------
local IS_MOBILE = false
pcall(function()
	IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end)

local function viewportSize()
	local ok, vp = pcall(function()
		return workspace.CurrentCamera.ViewportSize
	end)
	if ok and vp and vp.X and vp.X > 0 then
		return vp
	end
	return Vector2.new(1280, 720)
end

local function computeScale()
	local vp = viewportSize()
	local w = vp.X
	if IS_MOBILE then
		-- bump up touch targets on phones; clamp to a sane range
		local s = math.clamp(w / 900, 0.85, 1.25)
		return s
	end
	return math.clamp(w / 1280, 0.8, 1.1)
end

----------------------------------------------------------------------
-- Unified mouse + touch drag
----------------------------------------------------------------------
local function makeDraggable(frame, handle)
	handle = handle or frame
	local dragging = false
	local dragStart, startPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

----------------------------------------------------------------------
-- Hover helper
----------------------------------------------------------------------
local function bindHover(button, target, base, hover)
	button.MouseEnter:Connect(function()
		tween(target, { BackgroundColor3 = hover }, TI.HOVER)
	end)
	button.MouseLeave:Connect(function()
		tween(target, { BackgroundColor3 = base }, TI.HOVER)
	end)
end

----------------------------------------------------------------------
-- Root ScreenGui + notifications (created lazily, shared)
----------------------------------------------------------------------
local screenGui
local notifyHolder

local function ensureRoot()
	if screenGui and screenGui.Parent then
		return screenGui
	end
	screenGui = Create("ScreenGui", {
		Name = "NEMESIS_" .. tostring(math.random(1000, 9999)),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 9999,
		IgnoreGuiInset = true,
	})
	pcall(function()
		screenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	end)
	protectGui(screenGui)
	screenGui.Parent = getGuiParent()

	notifyHolder = Create("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 300, 1, -32),
		BackgroundTransparency = 1,
		Parent = screenGui,
	}, {
		Create("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 10),
		}),
	})
	return screenGui
end

----------------------------------------------------------------------
-- Notifications
----------------------------------------------------------------------
function NEMESIS.Notify(opts)
	opts = opts or {}
	ensureRoot()

	local card = Create("Frame", {
		BackgroundColor3 = THEME.Element,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = notifyHolder,
	}, {
		corner(10),
		stroke(THEME.Stroke, 1, 0.2),
		padding(12),
		Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}),
		Create("TextLabel", {
			Name = "Title",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			Font = FONT_BOLD,
			Text = tostring(opts.title or "Notification"),
			TextColor3 = THEME.Accent,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTransparency = 1,
		}),
		Create("TextLabel", {
			Name = "Content",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = FONT,
			Text = tostring(opts.content or ""),
			TextColor3 = THEME.Text,
			TextSize = 13,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTransparency = 1,
		}),
	})

	-- slide / fade in
	card.BackgroundTransparency = 1
	tween(card, { BackgroundTransparency = 0 }, TI.NOTIFY)
	for _, child in ipairs(card:GetChildren()) do
		if child:IsA("TextLabel") then
			tween(child, { TextTransparency = 0 }, TI.NOTIFY)
		end
	end

	local duration = tonumber(opts.duration) or 4
	task.delay(duration, function()
		if not card or not card.Parent then
			return
		end
		tween(card, { BackgroundTransparency = 1 }, TI.SLIDE)
		for _, child in ipairs(card:GetChildren()) do
			if child:IsA("TextLabel") then
				tween(child, { TextTransparency = 1 }, TI.SLIDE)
			end
		end
		task.delay(0.25, function()
			if card then
				card:Destroy()
			end
		end)
	end)
end

----------------------------------------------------------------------
-- Element factory builder (shared row scaffold)
----------------------------------------------------------------------
local function newRow(parent, height)
	return Create("Frame", {
		BackgroundColor3 = THEME.Element,
		Size = UDim2.new(1, 0, 0, height or 38),
		Parent = parent,
	}, {
		corner(8),
		stroke(THEME.Stroke, 1, 0.4),
		padding(10),
	})
end

local function rowLabel(parent, text)
	return Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -40, 1, 0),
		Font = FONT_MED,
		Text = tostring(text or ""),
		TextColor3 = THEME.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = parent,
	})
end

----------------------------------------------------------------------
-- Element factories. Each takes (page, accent) and returns a creator.
-- The creators register values into NEMESIS.Flags and return a control
-- table with .Set / .Get (dot-style, matching the creation API).
----------------------------------------------------------------------
local Elements = {}

function Elements.Section(page, accent, title)
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		Font = FONT_BOLD,
		Text = string.upper(tostring(title or "Section")),
		TextColor3 = THEME.SubText,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = page,
	}, {
		padding(4),
	})
end

function Elements.Label(page, accent, text)
	local lbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = FONT,
		Text = tostring(text or ""),
		TextColor3 = THEME.SubText,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = page,
	})
	return {
		Set = function(v)
			lbl.Text = tostring(v)
		end,
		Get = function()
			return lbl.Text
		end,
	}
end

function Elements.Paragraph(page, accent, opts)
	opts = opts or {}
	local holder = Create("Frame", {
		BackgroundColor3 = THEME.Element,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = page,
	}, {
		corner(8),
		stroke(THEME.Stroke, 1, 0.4),
		padding(10),
		Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
		Create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			Font = FONT_BOLD,
			Text = tostring(opts.title or "Title"),
			TextColor3 = THEME.Text,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Create("TextLabel", {
			Name = "Body",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = FONT,
			Text = tostring(opts.content or ""),
			TextColor3 = THEME.SubText,
			TextSize = 13,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})
	return {
		Set = function(v)
			holder:FindFirstChild("Body").Text = tostring(v)
		end,
	}
end

function Elements.Button(page, accent, opts)
	opts = opts or {}
	local row = newRow(page)
	local btn = Create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, -10, 0, 0),
		Text = "",
		Parent = row,
	})
	rowLabel(row, opts.text)
	Create("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 20, 1, 0),
		Font = FONT_BOLD,
		Text = "\u{203A}",
		TextColor3 = accent,
		TextSize = 18,
		Parent = row,
	})
	bindHover(btn, row, THEME.Element, THEME.ElementHover)
	btn.MouseButton1Click:Connect(function()
		tween(row, { BackgroundColor3 = accent }, TI.HOVER)
		task.delay(0.12, function()
			tween(row, { BackgroundColor3 = THEME.Element }, TI.HOVER)
		end)
		if type(opts.callback) == "function" then
			pcall(opts.callback)
		end
	end)
	return { Instance = row }
end

function Elements.Toggle(page, accent, opts)
	opts = opts or {}
	local state = opts.default and true or false
	local row = newRow(page)
	rowLabel(row, opts.text)

	local track = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 40, 0, 20),
		BackgroundColor3 = THEME.Stroke,
		Parent = row,
	}, {
		corner(10),
	})
	local knob = Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.new(0, 16, 0, 16),
		BackgroundColor3 = THEME.Knob,
		Parent = track,
	}, {
		corner(8),
	})
	local click = Create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, -10, 0, 0),
		Text = "",
		Parent = row,
	})

	local control = {}
	local function render(animate)
		local info = animate and TI.SLIDE or TweenInfo.new(0)
		tween(track, { BackgroundColor3 = state and accent or THEME.Stroke }, info)
		tween(knob, { Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) }, info)
	end

	function control.Set(v, silent)
		state = v and true or false
		if opts.flag then
			NEMESIS.Flags[opts.flag] = state
		end
		render(true)
		if not silent and type(opts.callback) == "function" then
			pcall(opts.callback, state)
		end
	end
	function control.Get()
		return state
	end

	bindHover(click, row, THEME.Element, THEME.ElementHover)
	click.MouseButton1Click:Connect(function()
		control.Set(not state)
	end)

	if opts.flag then
		NEMESIS.Flags[opts.flag] = state
	end
	render(false)
	return control
end

function Elements.Slider(page, accent, opts)
	opts = opts or {}
	local min = tonumber(opts.min) or 0
	local max = tonumber(opts.max) or 100
	local increment = tonumber(opts.increment) or 1
	local value = math.clamp(tonumber(opts.default) or min, min, max)
	local suffix = opts.suffix or ""

	local row = newRow(page, 50)
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -60, 0, 18),
		Font = FONT_MED,
		Text = tostring(opts.text or "Slider"),
		TextColor3 = THEME.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	local valueLabel = Create("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 60, 0, 18),
		Font = FONT_BOLD,
		Text = tostring(value) .. suffix,
		TextColor3 = accent,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = row,
	})
	local bar = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -2),
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = THEME.Stroke,
		Parent = row,
	}, {
		corner(3),
	})
	local fill = Create("Frame", {
		Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
		BackgroundColor3 = accent,
		Parent = bar,
	}, {
		corner(3),
	})

	local control = {}
	local function setFromAlpha(alpha)
		alpha = math.clamp(alpha, 0, 1)
		local raw = min + (max - min) * alpha
		local stepped = min + math.floor((raw - min) / increment + 0.5) * increment
		value = math.clamp(stepped, min, max)
		valueLabel.Text = tostring(value) .. suffix
		tween(fill, { Size = UDim2.new((value - min) / (max - min), 0, 1, 0) }, TI.HOVER)
		if opts.flag then
			NEMESIS.Flags[opts.flag] = value
		end
		if type(opts.callback) == "function" then
			pcall(opts.callback, value)
		end
	end

	function control.Set(v)
		setFromAlpha(((tonumber(v) or min) - min) / (max - min))
	end
	function control.Get()
		return value
	end

	local dragging = false
	local function update(input)
		local rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
		setFromAlpha(rel)
	end
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			update(input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			update(input)
		end
	end)

	if opts.flag then
		NEMESIS.Flags[opts.flag] = value
	end
	return control
end

function Elements.Dropdown(page, accent, opts)
	opts = opts or {}
	local options = opts.options or {}
	local multi = opts.multi and true or false
	local selected = {}
	if multi then
		if type(opts.default) == "table" then
			for _, v in ipairs(opts.default) do
				selected[v] = true
			end
		end
	end
	local single = (not multi) and opts.default or nil

	local row = newRow(page)
	rowLabel(row, opts.text)
	local current = Create("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -20, 0.5, 0),
		Size = UDim2.new(0, 120, 1, 0),
		Font = FONT,
		Text = "...",
		TextColor3 = THEME.SubText,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})
	local arrow = Create("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 16, 1, 0),
		Font = FONT_BOLD,
		Text = "\u{25BE}",
		TextColor3 = accent,
		TextSize = 14,
		Parent = row,
	})

	local listHolder = Create("Frame", {
		BackgroundColor3 = THEME.Background,
		Size = UDim2.new(1, 0, 0, 0),
		ClipsDescendants = true,
		Parent = page,
	}, {
		corner(8),
		stroke(THEME.Stroke, 1, 0.4),
		Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }),
		padding(4),
	})

	local open = false
	local function refreshLabel()
		if multi then
			local parts = {}
			for _, v in ipairs(options) do
				if selected[v] then
					table.insert(parts, tostring(v))
				end
			end
			current.Text = #parts > 0 and table.concat(parts, ", ") or "None"
		else
			current.Text = single ~= nil and tostring(single) or "None"
		end
	end

	local control = {}
	local function fire()
		if opts.flag then
			if multi then
				local list = {}
				for _, v in ipairs(options) do
					if selected[v] then
						table.insert(list, v)
					end
				end
				NEMESIS.Flags[opts.flag] = list
			else
				NEMESIS.Flags[opts.flag] = single
			end
		end
		if type(opts.callback) == "function" then
			if multi then
				local list = {}
				for _, v in ipairs(options) do
					if selected[v] then
						table.insert(list, v)
					end
				end
				pcall(opts.callback, list)
			else
				pcall(opts.callback, single)
			end
		end
	end

	local optionButtons = {}
	local function rebuildOptions()
		for _, b in ipairs(optionButtons) do
			b:Destroy()
		end
		optionButtons = {}
		for _, v in ipairs(options) do
			local ob = Create("TextButton", {
				BackgroundColor3 = THEME.Element,
				Size = UDim2.new(1, 0, 0, 28),
				Font = FONT,
				Text = tostring(v),
				TextColor3 = THEME.Text,
				TextSize = 13,
				AutoButtonColor = false,
				Parent = listHolder,
			}, {
				corner(6),
			})
			local function paint()
				local on = multi and selected[v] or (single == v)
				ob.TextColor3 = on and accent or THEME.Text
			end
			paint()
			ob.MouseButton1Click:Connect(function()
				if multi then
					selected[v] = not selected[v]
				else
					single = v
				end
				for _, b in ipairs(optionButtons) do
					b.TextColor3 = THEME.Text
				end
				paint()
				refreshLabel()
				fire()
				if not multi then
					control.Toggle(false)
				end
			end)
			table.insert(optionButtons, ob)
		end
	end

	function control.Toggle(force)
		open = (force == nil) and (not open) or force
		local count = #options
		local target = open and math.min(count, 6) * 30 + 8 or 0
		tween(listHolder, { Size = UDim2.new(1, 0, 0, target) }, TI.SLIDE)
		tween(arrow, { Rotation = open and 180 or 0 }, TI.SLIDE)
	end
	function control.Set(v)
		if multi then
			selected = {}
			if type(v) == "table" then
				for _, x in ipairs(v) do
					selected[x] = true
				end
			end
		else
			single = v
		end
		rebuildOptions()
		refreshLabel()
		fire()
	end
	function control.Get()
		if multi then
			local list = {}
			for _, v in ipairs(options) do
				if selected[v] then
					table.insert(list, v)
				end
			end
			return list
		end
		return single
	end
	function control.SetOptions(newOptions)
		options = newOptions or {}
		rebuildOptions()
		refreshLabel()
	end

	local click = Create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, -10, 0, 0),
		Text = "",
		Parent = row,
	})
	bindHover(click, row, THEME.Element, THEME.ElementHover)
	click.MouseButton1Click:Connect(function()
		control.Toggle()
	end)

	rebuildOptions()
	refreshLabel()
	if opts.flag then
		NEMESIS.Flags[opts.flag] = control.Get()
	end
	return control
end

function Elements.Input(page, accent, opts)
	opts = opts or {}
	local row = newRow(page)
	rowLabel(row, opts.text)
	local box = Create("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 130, 0, 24),
		BackgroundColor3 = THEME.Background,
		Font = FONT,
		PlaceholderText = tostring(opts.placeholder or "..."),
		Text = tostring(opts.default or ""),
		TextColor3 = THEME.Text,
		PlaceholderColor3 = THEME.SubText,
		TextSize = 13,
		ClearTextOnFocus = opts.clearOnFocus and true or false,
		Parent = row,
	}, {
		corner(6),
		stroke(THEME.Stroke, 1, 0.3),
		padding(6),
	})

	local control = {}
	function control.Set(v)
		box.Text = tostring(v)
	end
	function control.Get()
		return box.Text
	end

	box.FocusLost:Connect(function()
		if opts.flag then
			NEMESIS.Flags[opts.flag] = box.Text
		end
		if type(opts.callback) == "function" then
			pcall(opts.callback, box.Text)
		end
	end)
	if opts.flag then
		NEMESIS.Flags[opts.flag] = box.Text
	end
	return control
end

function Elements.Keybind(page, accent, opts)
	opts = opts or {}
	local mode = opts.mode or "Toggle"
	local key = opts.default
	local row = newRow(page)
	rowLabel(row, opts.text)

	local btn = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 80, 0, 24),
		BackgroundColor3 = THEME.Background,
		Font = FONT_MED,
		Text = key and tostring(key.Name or key) or "None",
		TextColor3 = accent,
		TextSize = 13,
		AutoButtonColor = false,
		Parent = row,
	}, {
		corner(6),
		stroke(THEME.Stroke, 1, 0.3),
	})

	local listening = false
	local toggled = false
	local control = {}
	function control.Set(v)
		key = v
		btn.Text = v and tostring(v.Name or v) or "None"
		if opts.flag then
			NEMESIS.Flags[opts.flag] = key
		end
	end
	function control.Get()
		return key
	end

	btn.MouseButton1Click:Connect(function()
		listening = true
		btn.Text = "..."
	end)

	UserInputService.InputBegan:Connect(function(input, gpe)
		if listening and input.UserInputType == Enum.UserInputType.Keyboard then
			listening = false
			control.Set(input.KeyCode)
			return
		end
		if gpe or listening then
			return
		end
		if key and input.KeyCode == key then
			if mode == "Toggle" then
				toggled = not toggled
				if type(opts.callback) == "function" then
					pcall(opts.callback, toggled)
				end
			elseif mode == "Hold" then
				if type(opts.callback) == "function" then
					pcall(opts.callback, true)
				end
			else -- Always / Press
				if type(opts.callback) == "function" then
					pcall(opts.callback)
				end
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if mode == "Hold" and key and input.KeyCode == key then
			if type(opts.callback) == "function" then
				pcall(opts.callback, false)
			end
		end
	end)

	if opts.flag then
		NEMESIS.Flags[opts.flag] = key
	end
	return control
end

function Elements.ColorPicker(page, accent, opts)
	opts = opts or {}
	local value = opts.default or Color3.fromRGB(255, 255, 255)
	local row = newRow(page)
	rowLabel(row, opts.text)

	local preview = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 36, 0, 22),
		BackgroundColor3 = value,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	}, {
		corner(6),
		stroke(THEME.Stroke, 1, 0.2),
	})

	-- compact popout: hue + saturation/value sliders
	local h, s, v = value:ToHSV()
	local pop = Create("Frame", {
		BackgroundColor3 = THEME.Background,
		Size = UDim2.new(1, 0, 0, 0),
		ClipsDescendants = true,
		Parent = page,
	}, {
		corner(8),
		stroke(THEME.Stroke, 1, 0.4),
		padding(8),
		Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	local control = {}
	local function apply()
		value = Color3.fromHSV(h, s, v)
		preview.BackgroundColor3 = value
		if opts.flag then
			NEMESIS.Flags[opts.flag] = value
		end
		if type(opts.callback) == "function" then
			pcall(opts.callback, value)
		end
	end

	local function makeChannel(name, getter, setter)
		local holder = Create("Frame", {
			BackgroundColor3 = THEME.Stroke,
			Size = UDim2.new(1, 0, 0, 14),
			Parent = pop,
		}, {
			corner(4),
		})
		local f = Create("Frame", {
			Size = UDim2.new(getter(), 0, 1, 0),
			BackgroundColor3 = accent,
			Parent = holder,
		}, {
			corner(4),
		})
		local dragging = false
		local function upd(input)
			local rel = math.clamp((input.Position.X - holder.AbsolutePosition.X) / holder.AbsoluteSize.X, 0, 1)
			f.Size = UDim2.new(rel, 0, 1, 0)
			setter(rel)
			apply()
		end
		holder.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				upd(input)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
				upd(input)
			end
		end)
	end

	makeChannel("H", function() return h end, function(x) h = x end)
	makeChannel("S", function() return s end, function(x) s = x end)
	makeChannel("V", function() return v end, function(x) v = x end)

	local open = false
	preview.MouseButton1Click:Connect(function()
		open = not open
		tween(pop, { Size = UDim2.new(1, 0, 0, open and 70 or 0) }, TI.SLIDE)
	end)
	preview.MouseButton2Click:Connect(function()
		local hex = string.format("#%02X%02X%02X",
			math.floor(value.R * 255 + 0.5),
			math.floor(value.G * 255 + 0.5),
			math.floor(value.B * 255 + 0.5))
		if setClipboard(hex) then
			NEMESIS.Notify({ title = "Copied", content = hex, duration = 2 })
		end
	end)

	function control.Set(c)
		value = c
		h, s, v = c:ToHSV()
		preview.BackgroundColor3 = c
		apply()
	end
	function control.Get()
		return value
	end

	if opts.flag then
		NEMESIS.Flags[opts.flag] = value
	end
	return control
end

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------
function NEMESIS.Window(opts)
	opts = opts or {}
	local accent = opts.accent or THEME.Accent
	ensureRoot()

	local scale = computeScale()
	local baseW, baseH = 560, 380
	if IS_MOBILE then
		baseW, baseH = 470, 320
	end

	local root = Create("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, baseW, 0, baseH),
		BackgroundColor3 = THEME.Background,
		ClipsDescendants = true,
		Parent = screenGui,
	}, {
		Create("UIScale", { Scale = scale }),
		corner(12),
		stroke(THEME.Stroke, 1.5, 0),
	})

	-- topbar
	local topbar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = THEME.Topbar,
		Parent = root,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 12) }),
	})
	Create("Frame", { -- square off the bottom corners of the topbar
		Position = UDim2.new(0, 0, 1, -12),
		Size = UDim2.new(1, 0, 0, 12),
		BackgroundColor3 = THEME.Topbar,
		BorderSizePixel = 0,
		Parent = topbar,
	})
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 0),
		Size = UDim2.new(1, -120, 1, 0),
		Font = FONT_BOLD,
		Text = tostring(opts.title or "NEMESIS"),
		TextColor3 = THEME.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = topbar,
	})
	if opts.subtitle then
		Create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 16, 0, 0),
			Size = UDim2.new(1, -120, 1, 0),
			Font = FONT,
			Text = "        " .. tostring(opts.subtitle),
			TextColor3 = THEME.SubText,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Bottom,
			Parent = topbar,
		})
	end
	makeDraggable(root, topbar)

	local Win = {}
	local minimized = false
	local lastSize = root.Size

	local function makeTopButton(symbol, offset)
		local b = Create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, offset, 0.5, 0),
			Size = UDim2.new(0, 28, 0, 28),
			BackgroundTransparency = 1,
			Font = FONT_BOLD,
			Text = symbol,
			TextColor3 = THEME.SubText,
			TextSize = 18,
			Parent = topbar,
		})
		b.MouseEnter:Connect(function()
			tween(b, { TextColor3 = accent }, TI.HOVER)
		end)
		b.MouseLeave:Connect(function()
			tween(b, { TextColor3 = THEME.SubText }, TI.HOVER)
		end)
		return b
	end

	local closeBtn = makeTopButton("\u{2715}", -10)
	local minBtn = makeTopButton("\u{2013}", -42)

	-- body: sidebar + content
	local body = Create("Frame", {
		Position = UDim2.new(0, 0, 0, 44),
		Size = UDim2.new(1, 0, 1, -44),
		BackgroundTransparency = 1,
		Parent = root,
	})
	local sidebar = Create("ScrollingFrame", {
		Size = UDim2.new(0, 140, 1, 0),
		BackgroundColor3 = THEME.Sidebar,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = body,
	}, {
		padding(8),
		Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local content = Create("Frame", {
		Position = UDim2.new(0, 140, 0, 0),
		Size = UDim2.new(1, -140, 1, 0),
		BackgroundTransparency = 1,
		Parent = body,
	})

	-- open animation
	root.Size = UDim2.new(0, baseW, 0, 0)
	tween(root, { Size = UDim2.new(0, baseW, 0, baseH) }, TI.OPEN)
	lastSize = UDim2.new(0, baseW, 0, baseH)

	local tabs = {}
	local activePage

	local function showPage(page, tabBtn)
		if activePage == page then
			return
		end
		for _, t in ipairs(tabs) do
			tween(t.button, { BackgroundColor3 = THEME.Sidebar, TextColor3 = THEME.SubText }, TI.HOVER)
			t.page.Visible = false
		end
		page.Visible = true
		page.Position = UDim2.new(0, 12, 0, -6)
		tween(page, { Position = UDim2.new(0, 0, 0, 0) }, TI.SLIDE)
		tween(tabBtn, { BackgroundColor3 = THEME.Element, TextColor3 = accent }, TI.HOVER)
		activePage = page
	end

	function Win.Tab(name, icon)
		local tabBtn = Create("TextButton", {
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = THEME.Sidebar,
			Font = FONT_MED,
			Text = tostring(name or "Tab"),
			TextColor3 = THEME.SubText,
			TextSize = 14,
			AutoButtonColor = false,
			Parent = sidebar,
		}, {
			corner(8),
		})

		local page = Create("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = THEME.Stroke,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
			Parent = content,
		}, {
			padding(12),
			Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
		})

		tabBtn.MouseButton1Click:Connect(function()
			showPage(page, tabBtn)
		end)

		table.insert(tabs, { button = tabBtn, page = page })

		local Tab = {}
		local function bind(name)
			return function(arg)
				return Elements[name](page, accent, arg)
			end
		end
		Tab.Section = function(title)
			Elements.Section(page, accent, title)
			-- return a proxy so elements can be chained off a section too
			return Tab
		end
		Tab.Button = bind("Button")
		Tab.Toggle = bind("Toggle")
		Tab.Slider = bind("Slider")
		Tab.Dropdown = bind("Dropdown")
		Tab.Input = bind("Input")
		Tab.Keybind = bind("Keybind")
		Tab.ColorPicker = bind("ColorPicker")
		Tab.Label = function(text)
			return Elements.Label(page, accent, text)
		end
		Tab.Paragraph = bind("Paragraph")

		-- first tab becomes active
		if #tabs == 1 then
			showPage(page, tabBtn)
		end
		return Tab
	end

	function Win.Toggle(force)
		minimized = (force == nil) and (not minimized) or (not force)
		if minimized then
			lastSize = root.Size
			tween(root, { Size = UDim2.new(lastSize.X.Scale, lastSize.X.Offset, 0, 44) }, TI.SLIDE)
			body.Visible = false
		else
			body.Visible = true
			tween(root, { Size = lastSize }, TI.SLIDE)
		end
	end

	function Win.Destroy()
		tween(root, { Size = UDim2.new(0, root.Size.X.Offset, 0, 0) }, TI.SLIDE)
		task.delay(0.25, function()
			root:Destroy()
		end)
	end

	minBtn.MouseButton1Click:Connect(function()
		body.Visible = not body.Visible
		minimized = not body.Visible
		if minimized then
			lastSize = UDim2.new(0, baseW, 0, baseH)
			tween(root, { Size = UDim2.new(0, baseW, 0, 44) }, TI.SLIDE)
		else
			tween(root, { Size = lastSize }, TI.SLIDE)
		end
	end)
	closeBtn.MouseButton1Click:Connect(function()
		Win.Destroy()
	end)

	-- toggle key (desktop) + floating reopen button (mobile)
	local hidden = false
	local function setHidden(h)
		hidden = h
		if h then
			tween(root, { Size = UDim2.new(0, baseW, 0, 0) }, TI.SLIDE)
			task.delay(0.2, function()
				if hidden then root.Visible = false end
			end)
		else
			root.Visible = true
			tween(root, { Size = UDim2.new(0, baseW, 0, baseH) }, TI.OPEN)
		end
	end

	local toggleKey = opts.toggleKey or Enum.KeyCode.RightShift
	UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and input.KeyCode == toggleKey then
			setHidden(not hidden)
		end
	end)

	if IS_MOBILE then
		local fab = Create("TextButton", {
			Name = "Reopen",
			AnchorPoint = Vector2.new(0, 0),
			Position = UDim2.new(0, 12, 0, 12),
			Size = UDim2.new(0, 44, 0, 44),
			BackgroundColor3 = accent,
			Font = FONT_BOLD,
			Text = "N",
			TextColor3 = THEME.Text,
			TextSize = 20,
			Parent = screenGui,
		}, {
			corner(22),
			stroke(THEME.Stroke, 1, 0.4),
		})
		makeDraggable(fab, fab)
		fab.MouseButton1Click:Connect(function()
			setHidden(not hidden)
		end)
	end

	Win.Instance = root
	Win.Notify = NEMESIS.Notify
	return Win
end

----------------------------------------------------------------------
return NEMESIS
