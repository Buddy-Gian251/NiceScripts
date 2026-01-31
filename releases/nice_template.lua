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

local currently_dragged = {}
local drag_lock = {
	locked = false,
	reason = nil -- optional (slider, modal, etc.)
}

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

local function create_styles(item)
	local UI_Corner = Instance.new("UICorner")
	UI_Corner.CornerRadius = UDim.new(0, 10)
	UI_Corner.Parent = item
	local UI_Padding = Instance.new("UIPadding")
	UI_Padding.PaddingLeft = UDim.new(0, 10)
	UI_Padding.PaddingRight = UDim.new(0, 10)
	UI_Padding.PaddingTop = UDim.new(0, 10)
	UI_Padding.PaddingBottom = UDim.new(0, 10)
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

	-- EnumItems
	if typeof(list) == "Enum" then
		for _, item in ipairs(list:GetEnumItems()) do
			table.insert(out, item)
		end
		return out
	end

	-- EnumItem array
	if typeof(list[1]) == "EnumItem" then
		return list
	end

	-- Normal table
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

local themes = {
	["Default"] = {
		["PrimeColorLight"] = Color3.fromRGB(20, 110, 255),
		["PrimeColorDark"] = Color3.fromRGB(0, 67, 126),
		["AccentColor"] = Color3.fromRGB(0, 255, 255),
		["TextColor"] = Color3.fromRGB(0, 0, 0),
	},
}

function NiceUI.create_gui(name, gui_smoothness)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = UDim2.new(0, 500, 0, 320)
	frame.Position = UDim2.new(0.5, 0, 0.4, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(20, 110, 255)
	frame.BackgroundTransparency = 0.4
	frame.Parent = gui

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 20)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.Text = "niceGui: "..name
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	-- Tabs column
	local tabs_frame = Instance.new("ScrollingFrame")
	tabs_frame.Name = "Tabs"
	tabs_frame.Size = UDim2.new(0, 145, 1, -20)
	tabs_frame.Position = UDim2.new(0, 0, 0, 20)
	tabs_frame.BackgroundColor3 = Color3.fromRGB(20, 110, 255)
	tabs_frame.BackgroundTransparency = 0.4
	tabs_frame.ClipsDescendants = true
	tabs_frame.Parent = frame

	-- Content area for all tabs
	local content_frame = Instance.new("Frame")
	content_frame.Name = "Content"
	content_frame.Size = UDim2.new(1, -155, 1, -20)
	content_frame.Position = UDim2.new(0, 155, 0, 20)
	content_frame.BackgroundTransparency = 1
	content_frame.Parent = frame

	local toggle_button = Instance.new("TextButton")
	toggle_button.Name = "Toggle"
	toggle_button.Text = "niceGui"
	toggle_button.Size = UDim2.new(0, 80, 0, 40)
	toggle_button.Position = UDim2.new(0.5, 0, 0, 50)
	toggle_button.AnchorPoint = Vector2.new(0.5,0.5)
	toggle_button.BackgroundColor3 = Color3.fromRGB(20, 110, 255)
	toggle_button.BackgroundTransparency = 0.4
	toggle_button.TextColor3 = Color3.new(1,1,1)
	toggle_button.Parent = gui

	local tabs_layout = Instance.new("UIListLayout") 
	tabs_layout.SortOrder = Enum.SortOrder.LayoutOrder 
	tabs_layout.Padding = UDim.new(0,6) 
	tabs_layout.Parent = tabs_frame 
	tabs_layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() 
		tabs_frame.CanvasSize = UDim2.new(0,0,0,tabs_layout.AbsoluteContentSize.Y + 10) 
	end)

	create_styles(tabs_frame)
	create_styles(content_frame)
	make_draggable(frame)
	create_styles(frame)
	make_draggable(toggle_button)
	create_styles(toggle_button)

	toggle_button.Activated:Connect(function()
		if next(currently_dragged) then return end
		frame.Visible = not frame.Visible
	end)

	if gui_smoothness and typeof(gui_smoothness) == "number" then
		smoothSpeed = gui_smoothness
	end

	curr_mframe = frame
	currtabframe = tabs_frame
	currbuttonsframe = content_frame -- now default tab content lives here

	return gui
end

function NiceUI.create_tab(tab_name)
	assert(curr_mframe, "create_gui() must be called first")
	tab_name = tab_name or DEFAULT_TAB_NAME

	if tabs[tab_name] then
		return tabs[tab_name]
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
	if tab then
		return NiceUI.create_tab(tab)
	end
	-- default tab
	return NiceUI.create_tab(DEFAULT_TAB_NAME)
end

function NiceUI.create_click_button(name, tab, callback)
	local parent_frame = get_tab_frame(tab)
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

function NiceUI.create_slider(name, init_number, float_enabled, range, tab, callback)
	if not name then return end
	if not range or type(range) ~= "table" or range[1] == nil or range[2] == nil then
		notify("Slider requires a valid range with min and max values")
		return
	end

	local parent_frame = get_tab_frame(tab)

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
	local list = normalize_list(items)

	local selected = default or list[1]

	-- Root frame
	local picker_frame = Instance.new("Frame")
	picker_frame.Name = tostring(name)
	picker_frame.Size = UDim2.new(1, 0, 0, 80)
	picker_frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	picker_frame.BorderSizePixel = 1
	picker_frame.Parent = parent_frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -10, 0, 10)
	title.Position = UDim2.new(0, 5, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = name
	title.TextScaled = true
	title.TextColor3 = Color3.new(1,1,1)
	title.Parent = picker_frame

	-- Button
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -10, 0, 40)
	button.Position = UDim2.new(0, 5, 0, 15)
	button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	button.TextColor3 = Color3.new(1,1,1)
	button.TextScaled = true
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.Text = tostring(selected)
	button.Parent = picker_frame

	-- Dropdown
	local dropdown = Instance.new("ScrollingFrame")
	dropdown.Visible = false
	dropdown.Size = UDim2.new(1, -10, 0, 140)
	dropdown.Position = UDim2.new(0, 5, 0, 70)
	dropdown.CanvasSize = UDim2.new()
	dropdown.ScrollBarThickness = 6
	dropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	dropdown.BorderSizePixel = 1
	dropdown.ZIndex = picker_frame.ZIndex + 5
	dropdown.Parent = picker_frame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = dropdown

	create_styles(picker_frame)
	create_styles(button)
	create_styles(dropdown)

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		dropdown.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 6)
	end)

	local function close()
		dropdown.Visible = false
		picker_frame.Size = UDim2.new(1, -20, 0, 80)
		set_drag_lock(false)
	end

	-- Populate items
	for _, item in ipairs(list) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, -8, 0, 30)
		b.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
		b.TextColor3 = Color3.new(1,1,1)
		b.TextScaled = true
		b.Text = tostring(item)
		b.Parent = dropdown

		b.MouseButton1Click:Connect(function()
			selected = item
			button.Text = tostring(item)
			close()
			if callback then
				callback(item)
			end
		end)
	end

	button.MouseButton1Click:Connect(function()
		dropdown.Visible = not dropdown.Visible
		picker_frame.Size = UDim2.new(1, -20, 0, 240)
		set_drag_lock(dropdown.Visible, "picker")
	end)

	return {
		Frame = picker_frame,
		Get = function() return selected end,
		Set = function(v)
			selected = v
			button.Text = tostring(v)
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

return NiceUI
