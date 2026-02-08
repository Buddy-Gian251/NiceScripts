local NiceUI = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

local sound_files = {
	startup = "rbxassetid://9085027122",
	err = "rbxassetid://8426701399",
	succ = "rbxassetid://7762841318",
	notif = "rbxassetid://8183296024",
	close = "rbxassetid://573639200",
	kicked = "rbxassetid://8499261098"
}

local function rand_string()
	local length = math.random(10,20)
	local s = {}
	for i = 1, length do
		s[i] = string.char(math.random(32, 126))
	end
	return table.concat(s)
end

local PARENT
do
	local success, result = pcall(function()
		if gethui then
			return gethui()
		elseif CoreGui:FindFirstChild("RobloxGui") then
			return CoreGui
		else
			return LocalPlayer:WaitForChild("PlayerGui")
		end
	end)
	PARENT = (success and result) or LocalPlayer:WaitForChild("PlayerGui")
end

local gui = Instance.new("ScreenGui")
gui.Name = rand_string()
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = math.pow(2,16)
gui.Parent = PARENT

local gui_ready = false
local pending_tabs = {}
local theme_picker = nil
local currently_dragged = {}
local themes = {}
local drag_lock = {
	locked = false,
	reason = nil -- optional (slider, modal, etc.)
}

-- ===== THEME SYSTEM =====

themes = {
	["VIBRANT BLUE"] = {
		P1  = Color3.fromRGB(20, 110, 255), -- Primary1
		P2  = Color3.fromRGB(11, 60, 139),  -- Primary2
		S1  = Color3.fromRGB(5, 188, 255),  -- Secondary1
		S2  = Color3.fromRGB(136, 16, 255), -- Secondary2
		S3  = Color3.fromRGB(50, 50, 50),   -- Secondary3
		TB1 = Color3.fromRGB(200, 200, 200) -- TextBox1
	}
}

local DEFAULT_THEME = "VIBRANT BLUE"

local function playsound(id, volume)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 1
	s.Parent = gui
	s:Play()
	s.Ended:Connect(function() s:Destroy() end)
end

local function notify(title, text, dur, no_sound)
	local s, e = pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = dur or 2
		})
	end)
	if not no_sound then
		playsound(sound_files.notif, 2)
	end
	if not s then
		warn("NiceGUI: "..tostring(e))
	end
end

local smoothSpeed = 0.3 -- lower = smoother, higher = snappier

local function make_draggable(item)
	local targetPos
	local dragging = false
	local dragStart = nil
	local startPos = nil
	local holdStartTime = nil
	local holdConnection = nil
	item.InputBegan:Connect(function(input)
		if drag_lock.locked then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			holdStartTime = tick()
			dragStart = input.Position
			startPos = item.Position
			holdConnection = RunService.RenderStepped:Connect(function()
				if not dragging and (tick() - holdStartTime) >= 0.2 then
					notify("Drag feature", "you can now drag "..(item.Name or "this UI").." anywhere.", 1.5)
					dragging = true
					currently_dragged[item] = true
					if holdConnection then
						holdConnection:Disconnect()
						holdConnection = nil
					end
				end
			end)
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					if holdConnection then
						holdConnection:Disconnect()
						holdConnection = nil
					end
					if dragging then
						dragging = false
						task.delay(0.2, function()
							currently_dragged[item] = nil
						end)
					end
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and not drag_lock.locked and 
			(input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			targetPos = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
	RunService.RenderStepped:Connect(function()
		if dragging and targetPos and not drag_lock.locked then
			item.Position = item.Position:Lerp(targetPos, smoothSpeed)
		end
	end)
end

local function is_drag_locked()
	return drag_lock.locked, drag_lock.reason
end

local function set_drag_lock(state, reason)
	drag_lock.locked = state and true or false
	drag_lock.reason = state and (reason or "unknown") or nil
end

local univpadding = 8

local function create_styles(item)
	local UI_Corner = Instance.new("UICorner")
	UI_Corner.CornerRadius = UDim.new(0, univpadding)
	UI_Corner.Parent = item
	local UI_Padding = Instance.new("UIPadding")
	UI_Padding.PaddingLeft = UDim.new(0, univpadding)
	UI_Padding.PaddingRight = UDim.new(0, univpadding)
	UI_Padding.PaddingTop = UDim.new(0, univpadding)
	UI_Padding.PaddingBottom = UDim.new(0, univpadding)
	UI_Padding.Parent = item
	local UI_Stroke = Instance.new("UIStroke")
	UI_Stroke.Color = Color3.fromRGB(255,255,255)
	UI_Stroke.Thickness = 2
	UI_Stroke.Transparency = 0.5
	UI_Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UI_Stroke.Parent = item
	local UI_Gradient = Instance.new("UIGradient")
	UI_Gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(161, 161, 161))
	}
	UI_Gradient.Rotation = 90
	UI_Gradient.Parent = item
end

local function normalize_list(list)
	local out = {}
	if typeof(list) == "Enum" then
		for _, item in ipairs(list:GetEnumItems()) do
			table.insert(out, item)
		end
		return out
	end
	if typeof(list[1]) == "EnumItem" then
		return list
	end
	for _, v in pairs(list) do
		table.insert(out, v)
	end
	return out
end

playsound(sound_files.startup, 1)

local curr_mframe
local currtabframe
local currbuttonsframe
local tabs = {}
local active_tab_window = nil
local DEFAULT_TAB_NAME = "Uncategorized"

local THEME_FADE_TIME = 2

local function tween_prop(obj, props)
	local t = TweenService:Create(
		obj,
		TweenInfo.new(THEME_FADE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		props
	)
	t:Play()
end

local function apply_text_contrast(ui)
	if not (ui:IsA("TextLabel") or ui:IsA("TextButton") or ui:IsA("TextBox")) then
		return
	end
	local bg = ui.BackgroundColor3
	local transparency = ui.BackgroundTransparency or 0
	local brightness = (bg.R + bg.G + bg.B) / 3 * 255
	local old = ui:FindFirstChild("tempstroke")
	if old then old:Destroy() end
	if transparency < 0.5 then
		if brightness <= 99 then
			ui.TextColor3 = Color3.new(1,1,1)
		elseif brightness <= 149 then
			ui.TextColor3 = Color3.new(1,1,1)
			local stroke = Instance.new("UIStroke")
			stroke.Name = "tempstroke"
			stroke.Color = Color3.new(0,0,0)
			stroke.Thickness = 2
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
			stroke.Parent = ui

			task.delay(0.4, function()
				if stroke then stroke:Destroy() end
			end)
		else
			ui.TextColor3 = Color3.new(0,0,0)
		end
	end
end

local function update_theme_picker()
	if not theme_picker then return end
	local items = {}
	for name in pairs(themes) do
		table.insert(items, name)
	end
	theme_picker:Set(items)
end

function NiceUI.apply_theme(instance, theme_name)
	notify("Themes are out of order for a moment...", "Please wait 'til the developer fixes this.", 0, nil)
	--if not instance or not themes[theme_name] then return end
	--local theme = themes[theme_name]
	--if instance:IsA("Frame") or instance:IsA("TextButton") or instance:IsA("TextBox") then
	--	tween_prop(instance, {
	--		BackgroundColor3 = theme.P1
	--	})
	--end
	--if instance:IsA("TextBox") then
	--	tween_prop(instance, {
	--		BackgroundColor3 = theme.TB1
	--	})
	--end
	--local stroke = instance:FindFirstChildOfClass("UIStroke")
	--if stroke then
	--	tween_prop(stroke, {
	--		Color = theme.S2
	--	})
	--end
	--local grad = instance:FindFirstChildOfClass("UIGradient")
	--if grad then
	--	grad.Color = ColorSequence.new{
	--		ColorSequenceKeypoint.new(0, theme.P1),
	--		ColorSequenceKeypoint.new(1, theme.P2)
	--	}
	--end
	--apply_text_contrast(instance)
	--instance:SetAttribute("NiceUI_Theme", theme_name)
end

function NiceUI.create_theme(name, data)
	notify("Themes are out of order for a moment...", "Please wait 'til the developer fixes this.", 0, nil)
	--assert(type(name) == "string", "Theme name must be a string")
	--assert(type(data) == "table", "Theme data must be a table")
	--themes[name] = {
	--	P1  = data.P1  or Color3.new(1,1,1),
	--	P2  = data.P2  or Color3.new(1,1,1),
	--	S1  = data.S1  or Color3.new(1,1,1),
	--	S2  = data.S2  or Color3.new(1,1,1),
	--	S3  = data.S3  or Color3.new(1,1,1),
	--	TB1 = data.TB1 or Color3.new(1,1,1)
	--}
	--if theme_picker then
	--	theme_picker:SetItems((function()
	--		local t = {}
	--		for k in pairs(themes) do table.insert(t,k) end
	--		return t
	--	end)())
	--end
end

local function init_gui()
	if gui_ready then return end

	-- main frame
	local frame = Instance.new("Frame")
	frame.Name = "NiceUI_Main"
	frame.Size = UDim2.new(0, 600, 0, 320)
	frame.Position = UDim2.new(0.5, 0, 0.4, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(20, 110, 255)
	frame.BackgroundTransparency = 0.4
	frame.Parent = gui

	local toggle = Instance.new("TextButton")
	toggle.Name = "Toggle"
	toggle.Size = UDim2.new(0, 64, 0, 32)
	toggle.Position = UDim2.new(0.5, 0, 0, 0)
	toggle.AnchorPoint = Vector2.new(0.5, 0)
	toggle.BackgroundColor3 = Color3.fromRGB(20, 110, 255)
	toggle.BackgroundTransparency = 0.4
	toggle.Text = "NiceUI"
	toggle.TextScaled = true
	toggle.TextColor3 = Color3.new(1,1,1)
	toggle.Font = Enum.Font.GothamBold
	toggle.Parent = gui

	-- title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = "niceGui"
	title.TextScaled = true
	title.TextColor3 = Color3.new(1,1,1)
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	-- tabs column
	local tabs_frame = Instance.new("ScrollingFrame")
	tabs_frame.Name = "Tabs"
	tabs_frame.Size = UDim2.new(0, 145, 1, -20)
	tabs_frame.Position = UDim2.new(0, 0, 0, 20)
	tabs_frame.BackgroundTransparency = 0.4
	tabs_frame.Parent = frame

	-- content area
	local content_frame = Instance.new("Frame")
	content_frame.Name = "Content"
	content_frame.Size = UDim2.new(1, -155, 1, -20)
	content_frame.Position = UDim2.new(0, 155, 0, 20)
	content_frame.BackgroundTransparency = 1
	content_frame.Parent = frame

	-- layouts / styles
	local tabs_layout = Instance.new("UIListLayout")
	tabs_layout.Padding = UDim.new(0, 6)
	tabs_layout.Parent = tabs_frame
	tabs_layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		tabs_frame.CanvasSize = UDim2.new(0,0,0,tabs_layout.AbsoluteContentSize.Y + 10)
	end)

	toggle.Activated:Connect(function()
		if next(currently_dragged) then return end
		frame.Visible = not frame.Visible
	end)

	create_styles(frame)
	create_styles(toggle)
	create_styles(tabs_frame)
	create_styles(content_frame)
	make_draggable(toggle)
	make_draggable(frame)

	-- expose internals
	curr_mframe = frame
	currtabframe = tabs_frame
	currbuttonsframe = content_frame

	gui_ready = true

	-- flush queued tabs
	for tabName in pairs(pending_tabs) do
		NiceUI.create_tab(tabName)
	end
	table.clear(pending_tabs)
end

function NiceUI.create_gui(name, gui_smoothness)
	NiceUI.display_message("Oh No! Deprecated?", "Sorry, this function is deprecated and will be removed completely. Please use NiceUI.set_name(name) instead!")
end

function NiceUI.get_gui()
	return gui
end

function NiceUI.set_name(name)
	assert(type(name) == "string", "GUI name must be a string")

	gui.Name = name

	if curr_mframe then
		local title = curr_mframe:FindFirstChild("Title")
		if title then
			title.Text = "niceGui: " .. name
		end
	end
end

function NiceUI.create_tab(tab_name)
	tab_name = tab_name or DEFAULT_TAB_NAME

	if not gui_ready then
		pending_tabs[tab_name] = true
		return nil
	end

	local tab_button
	if tab_name ~= DEFAULT_TAB_NAME then
		tab_button = Instance.new("TextButton")
		tab_button.Text = tab_name
		tab_button.Size = UDim2.new(1, 0, 0, 40)
		tab_button.BackgroundTransparency = 0.4
		tab_button.TextColor3 = Color3.new(1,1,1)
		tab_button.TextScaled = true
		tab_button.Font = Enum.Font.SourceSans
		tab_button.Parent = currtabframe
	end

	local tab_window = Instance.new("ScrollingFrame")
	tab_window.Name = tab_name .. "_Window"
	tab_window.Size = UDim2.new(1, 0, 1, 0)
	tab_window.CanvasSize = UDim2.new(0, 0, 0, 0)
	tab_window.ScrollBarThickness = 6
	tab_window.ScrollingDirection = Enum.ScrollingDirection.Y
	tab_window.AutomaticCanvasSize = Enum.AutomaticSize.None
	tab_window.BackgroundTransparency = 1
	tab_window.Visible = false
	tab_window.ClipsDescendants = true
	tab_window.VerticalScrollBarInset = Enum.ScrollBarInset.Always
	tab_window.HorizontalScrollBarInset = Enum.ScrollBarInset.Always
	tab_window.Parent = currbuttonsframe
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0,8)
	padding.PaddingRight = UDim.new(0,8)
	padding.PaddingTop = UDim.new(0,8)
	padding.PaddingBottom = UDim.new(0,8)
	padding.Parent = tab_window
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0,10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = tab_window
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		tab_window.CanvasSize = UDim2.new(
			0,
			0,
			0,
			layout.AbsoluteContentSize.Y + 10
		)
	end)

	create_styles(tab_button)

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0,6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = tab_window

	if tab_button then
		tab_button.Activated:Connect(function()
			if active_tab_window then active_tab_window.Visible = false end
			active_tab_window = tab_window
			tab_window.Visible = true
		end)
	end

	-- auto-select first tab
	if not active_tab_window then
		active_tab_window = tab_window
		tab_window.Visible = true
	end

	tabs[tab_name] = tab_window
	return tab_window
end

local function get_tab_frame(tab)
	if not gui_ready then
		return nil
	end

	tab = tab or DEFAULT_TAB_NAME
	if tabs[tab] then
		return tabs[tab]
	else
		return NiceUI.create_tab(tab)
	end
end

function NiceUI.create_click_button(name, tab, callback)
	local parent_frame = get_tab_frame(tab)
	if not parent_frame then
		warn("NiceUI: GUI not ready, cannot create item picker:", name)
		return
	end

	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = name
	b.TextScaled = true
	b.Size = UDim2.new(1, 0, 0, 40)
	b.BackgroundColor3 = Color3.fromRGB(0,0,0)
	b.BackgroundTransparency = 0.4
	b.TextColor3 = Color3.new(1,1,1)
	b.Parent = parent_frame

	b.MouseButton1Click:Connect(function()
		if callback then callback() end
	end)
	create_styles(b)
	return b
end

local function clamp255(n)
	return math.clamp(math.floor(n + 0.5), 0, 255)
end

local function color3_to_hex(c)
	return string.format("%02X%02X%02X",
		clamp255(c.R * 255),
		clamp255(c.G * 255),
		clamp255(c.B * 255)
	)
end

local function hex_to_color3(hex)
	hex = hex:gsub("#", "")
	local r
	local g
	local b
	pcall(function()
		if #hex ~= 6 then return nil end

		r = tonumber(hex:sub(1,2), 16)
		g = tonumber(hex:sub(3,4), 16)
		b = tonumber(hex:sub(5,6), 16)
		if not r or not g or not b then return nil end
	end)

	return Color3.fromRGB(r, g, b)
end

function NiceUI.create_slider(name, init_number, float_enabled, range, tab, callback)
	if not name then return end
	if not range or type(range) ~= "table" or range[1] == nil or range[2] == nil then
		notify("Slider requires a valid range with min and max values")
		return
	end

	local parent_frame = get_tab_frame(tab)
	if not parent_frame then
		warn("NiceUI: GUI not ready, cannot create item picker:", name)
		return
	end

	local min_val = range[1] :: number
	local max_val = range[2] :: number

	if not min_val or not max_val then notify("Error", "Expected 2 arguments but nothing was filled in.", 5) return end
	if type(min_val) ~= "number" or type(max_val) ~= "number" then notify("Error", "Expected 2 arguments but left with incorrect type/s.", 5) return end

	local current_val = init_number or min_val
	local last_snapped_val = current_val
	current_val = math.clamp(current_val, min_val, max_val)
	if not float_enabled then
		current_val = math.floor(current_val + 0.5)
	end

	-- ===== UI =====
	local slide_frame = Instance.new("Frame")
	slide_frame.Name = tostring(name)
	slide_frame.Size = UDim2.new(1, 0, 0, 50)
	slide_frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	slide_frame.BorderSizePixel = 1
	slide_frame.Parent = parent_frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.5, -10, 0, 10)
	title.Position = UDim2.new(0, 5, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = name
	title.TextScaled = true
	title.TextColor3 = Color3.new(1,1,1)
	title.Parent = slide_frame

	local input_box = Instance.new("TextBox")
	input_box.Size = UDim2.new(0.5, -10, 0, 10)
	input_box.Position = UDim2.new(0.5, 5, 0, 0)
	input_box.BackgroundTransparency = 1
	input_box.TextScaled = true
	input_box.TextColor3 = Color3.new(1,1,1)
	input_box.ClearTextOnFocus = false
	input_box.Parent = slide_frame

	local slider_bar = Instance.new("Frame")
	slider_bar.Size = UDim2.new(1, -20, 0, 6)
	slider_bar.Position = UDim2.new(0, 10, 0, 24)
	slider_bar.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	slider_bar.Parent = slide_frame

	local slider_handle = Instance.new("Frame")
	slider_handle.Size = UDim2.new(0, 12, 0, 12)
	slider_handle.AnchorPoint = Vector2.new(0.5, 0.5)
	slider_handle.Position = UDim2.new(0, 0, 0.5, -6)
	slider_handle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	slider_handle.BackgroundTransparency = 0.5
	slider_handle.Parent = slider_bar

	create_styles(slide_frame)

	-- ===== Logic =====
	local dragging = false
	local syncing = false

	local function format_value(v)
		if float_enabled then
			return string.format("%.2f", v)
		else
			return tostring(v)
		end
	end

	local function set_value(new_val)
		if syncing then return end
		syncing = true

		new_val = math.clamp(new_val, min_val, max_val)

		-- snap logic
		if not float_enabled then
			new_val = math.floor(new_val + 0.5)
		end

		-- 🔊 play sound ONLY if snapped value changed
		if new_val ~= last_snapped_val then
			playsound("rbxassetid://14133663945", 5)
			last_snapped_val = new_val
		end

		current_val = new_val

		local percent = (current_val - min_val) / (max_val - min_val)
		slider_handle.Position = UDim2.new(percent, 0, 0.5, -6)
		input_box.Text = format_value(current_val)

		if callback then
			callback(current_val)
		end

		syncing = false
	end

	-- ===== Slider drag =====
	slider_handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			set_drag_lock(true, "slider")
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local relative_x = math.clamp(
				input.Position.X - slider_bar.AbsolutePosition.X,
				0,
				slider_bar.AbsoluteSize.X
			)

			local percent = relative_x / slider_bar.AbsoluteSize.X
			local raw_val = min_val + (max_val - min_val) * percent
			set_value(raw_val)
		end
	end)

	slider_handle.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
			set_drag_lock(false)
		end
	end)

	-- ===== TextBox → slider =====
	input_box.FocusLost:Connect(function()
		local num = tonumber(input_box.Text)
		if num then
			set_value(num)
		else
			input_box.Text = format_value(current_val)
		end
	end)

	-- ===== Initial sync =====
	task.defer(function()
		set_value(current_val)
	end)

	return slide_frame
end

function NiceUI.create_text_editor(name, text, tab, callback)
	if not name then return end
	local parent_frame = get_tab_frame(tab)
	if not parent_frame then
		warn("NiceUI: GUI not ready, cannot create item picker:", name)
		return
	end
	local te_frame = Instance.new("Frame")
	te_frame.Name = tostring(name)
	te_frame.Size = UDim2.new(1, 0, 0, 70)
	te_frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	te_frame.BorderSizePixel = 1
	te_frame.Parent = parent_frame
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -10, 0, 10)
	title.Position = UDim2.new(0, 5, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = name
	title.TextScaled = true
	title.TextColor3 = Color3.new(1,1,1)
	title.Parent = te_frame
	local text_editor = Instance.new("TextBox")
	text_editor.Name = "TextEditor"
	text_editor.Size = UDim2.new(1, -10, 0, 30)
	text_editor.Position = UDim2.new(0, 5, 0, 15)
	text_editor.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	text_editor.Text = tostring(text or "")
	text_editor.TextColor3 = Color3.fromRGB(0, 0, 0)
	text_editor.TextScaled = true
	text_editor.ClearTextOnFocus = false
	text_editor.Parent = te_frame
	create_styles(te_frame)
	create_styles(text_editor)
	text_editor.FocusLost:Connect(function()
		local new_text = text_editor.Text
		if callback then
			callback(new_text)
		end
	end)
	return te_frame
end

function NiceUI.create_item_picker(name, items, default, tab, callback)
	if not name or not items then return end
	local parent_frame = get_tab_frame(tab)
	if not parent_frame then return end

	local list = normalize_list(items)
	local selected = default or list[1]

	local picker_frame = Instance.new("Frame")
	picker_frame.Name = name
	picker_frame.Size = UDim2.new(1,0,0,80)
	picker_frame.BackgroundColor3 = Color3.fromRGB(50,50,50)
	picker_frame.Parent = parent_frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1,-10,0,10)
	title.Position = UDim2.new(0,5,0,0)
	title.BackgroundTransparency = 1
	title.Text = name
	title.TextScaled = true
	title.TextColor3 = Color3.new(1,1,1)
	title.Parent = picker_frame

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1,-10,0,40)
	button.Position = UDim2.new(0,5,0,15)
	button.BackgroundColor3 = Color3.fromRGB(80,80,80)
	button.TextColor3 = Color3.new(1,1,1)
	button.TextScaled = true
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.Text = tostring(selected)
	button.Parent = picker_frame

	local dropdown = Instance.new("ScrollingFrame")
	dropdown.Visible = false
	dropdown.Size = UDim2.new(1,-10,0,140)
	dropdown.Position = UDim2.new(0,5,0,70)
	dropdown.BackgroundColor3 = Color3.fromRGB(40,40,40)
	dropdown.BorderSizePixel = 1
	dropdown.ZIndex = picker_frame.ZIndex + 5
	dropdown.Parent = picker_frame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0,4)
	layout.Parent = dropdown
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		dropdown.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 6)
	end)

	create_styles(picker_frame)
	create_styles(button)
	create_styles(dropdown)

	local function close_dropdown()
		dropdown.Visible = false
		picker_frame.Size = UDim2.new(1,0,0,80)
	end

	local function rebuild_dropdown()
		-- destroy old buttons
		for _, child in ipairs(dropdown:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		-- create new ones
		for _, item in ipairs(list) do
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1,-8,0,30)
			b.BackgroundColor3 = Color3.fromRGB(70,70,70)
			b.TextColor3 = Color3.new(1,1,1)
			b.TextScaled = true
			b.Text = tostring(item)
			b.Parent = dropdown
			b.MouseButton1Click:Connect(function()
				selected = item
				button.Text = tostring(item)
				close_dropdown()
				if callback then callback(item) end
			end)
		end
	end

	button.MouseButton1Click:Connect(function()
		dropdown.Visible = not dropdown.Visible
		picker_frame.Size = UDim2.new(1,0,0, dropdown.Visible and 240 or 80)
		if dropdown.Visible then rebuild_dropdown() end
	end)

	return {
		Frame = picker_frame,
		Get = function() return selected end,
		Set = function(v)
			if table.find(list,v) then
				selected = v
				button.Text = tostring(v)
			end
		end,
		SetItems = function(newList)
			list = normalize_list(newList)
			selected = list[1] or nil
			button.Text = tostring(selected)
			rebuild_dropdown()
		end
	}
end

function NiceUI.create_color_editor(name, value, tab, callback)
	local parent_frame = get_tab_frame(tab)
	if not parent_frame then
		warn("NiceUI: GUI not ready, cannot create item picker:", name)
		return
	end
	local currentColor = value or Color3.new(0,0,0)
	local syncing = false
	local col_edit = Instance.new("Frame")
	col_edit.Name = "col_edit"
	col_edit.Size = UDim2.new(1, 0, 0, 190)
	col_edit.BackgroundColor3 = Color3.fromRGB(50,50,50)
	col_edit.Parent = parent_frame
	create_styles(col_edit)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 20)
	title.BackgroundTransparency = 1
	title.TextScaled = true
	title.Text = name
	title.TextColor3 = Color3.new(1,1,1)
	title.Parent = col_edit
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 1, -20)
	container.Position = UDim2.new(0, 0, 0, 20)
	container.BackgroundTransparency = 1
	container.Parent = col_edit
	create_styles(container)
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.48, 0, 0, 30)
	grid.CellPadding = UDim2.new(0.04, 0, 0, 8)
	grid.FillDirection = Enum.FillDirection.Vertical
	grid.Parent = container
	local function make_field(labelText)
		local f = Instance.new("Frame")
		f.BackgroundTransparency = 1
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.4, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = labelText
		label.TextScaled = true
		label.TextColor3 = Color3.new(1,1,1)
		label.Parent = f
		local box = Instance.new("TextBox")
		box.Size = UDim2.new(0.6, -4, 1, 0)
		box.Position = UDim2.new(0.4, 4, 0, 0)
		box.BackgroundColor3 = Color3.fromRGB(200,200,200)
		box.TextColor3 = Color3.fromRGB(0,0,0)
		box.TextScaled = true
		box.ClearTextOnFocus = false
		box.Parent = f
		create_styles(box)
		return f, box
	end
	local rF, rBox = make_field("Red")
	local gF, gBox = make_field("Green")
	local bF, bBox = make_field("Blue")
	local hexF, hexBox = make_field("Hex")
	local hF, hBox = make_field("Hue")
	local sF, sBox = make_field("Sat")
	local vF, vBox = make_field("Val")
	rF.Parent = container
	gF.Parent = container
	bF.Parent = container
	hexF.Parent = container
	hF.Parent = container
	sF.Parent = container
	vF.Parent = container
	local preview = Instance.new("Frame")
	preview.Size = UDim2.new(1, -10, 0, 30)
	preview.BackgroundColor3 = currentColor
	preview.Parent = container
	create_styles(preview)
	local function sync_from_color()
		if syncing then return end
		syncing = true
		local r,g,b = clamp255(currentColor.R*255), clamp255(currentColor.G*255), clamp255(currentColor.B*255)
		local h,s,v = currentColor:ToHSV()
		rBox.Text = r
		gBox.Text = g
		bBox.Text = b
		hBox.Text = math.floor(h * 360 + 0.5)
		sBox.Text = math.floor(s * 100 + 0.5)
		vBox.Text = math.floor(v * 100 + 0.5)
		hexBox.Text = color3_to_hex(currentColor)
		preview.BackgroundColor3 = currentColor
		if callback then
			callback(currentColor)
		end
		syncing = false
	end
	local function set_rgb()
		local r = tonumber(rBox.Text)
		local g = tonumber(gBox.Text)
		local b = tonumber(bBox.Text)
		if r and g and b then
			currentColor = Color3.fromRGB(clamp255(r), clamp255(g), clamp255(b))
			sync_from_color()
		end
	end
	local function set_hsv()
		local h = tonumber(hBox.Text)
		local s = tonumber(sBox.Text)
		local v = tonumber(vBox.Text)
		if h and s and v then
			currentColor = Color3.fromHSV(
				math.clamp(h / 360, 0, 1),
				math.clamp(s / 100, 0, 1),
				math.clamp(v / 100, 0, 1)
			)
			sync_from_color()
		end
	end
	for _, box in ipairs({rBox,gBox,bBox}) do
		box.FocusLost:Connect(set_rgb)
	end
	for _, box in ipairs({hBox,sBox,vBox}) do
		box.FocusLost:Connect(set_hsv)
	end
	hexBox.FocusLost:Connect(function()
		local c = hex_to_color3(hexBox.Text)
		if c then
			currentColor = c
			sync_from_color()
		end
	end)
	task.defer(sync_from_color)
	return {
		Frame = col_edit,
		Get = function() return currentColor end,
		Set = function(c)
			if typeof(c) == "Color3" then
				currentColor = c
				sync_from_color()
			end
		end
	}
end

function NiceUI.display_message(customtitle, customtext, customsound)
	local nosound = (not customsound) or tostring(customsound) == ""
	notify(
		"NiceGui: "..tostring(customtitle),
		"NiceGui: "..tostring(customtext),
		2,
		customsound,
		nosound
	)
end

init_gui()

-- HEY!
-- Themes is undergoing color errors at this moment, come back if you need to!
-- [February 3, 2026]

---- === THEMES TAB ===
--NiceUI.create_tab("Themes")

---- collect theme names as strings
--local theme_names = {}
--for name in pairs(themes) do
--	table.insert(theme_names, name)
--end

--theme_picker = NiceUI.create_item_picker(
--	"Select Theme",
--	theme_names,
--	DEFAULT_THEME,
--	"Themes",
--	function(selected)
--		NiceUI.apply_theme(curr_mframe, selected)
--	end
--)

--theme_picker.Set(DEFAULT_THEME)

return NiceUI
