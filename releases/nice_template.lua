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
	StarterGui:SetCore("SendNotification", {
		Title = title,
		Text = text,
		Duration = dur or 2
	})
	if not no_sound then
		playsound(sound_files.notif, 2)
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
	frame.Size = UDim2.new(0, 500, 0, 300)
	frame.Position = UDim2.new(0.5, 0, 0.4, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(20, 110, 255)
	frame.BackgroundTransparency = 0.4
	frame.Parent = gui

	-- Tabs column
	local tabs_frame = Instance.new("ScrollingFrame")
	tabs_frame.Name = "Tabs"
	tabs_frame.Size = UDim2.new(0, 145, 1, 0)
	tabs_frame.Position = UDim2.new(0, 0, 0, 0)
	tabs_frame.BackgroundColor3 = Color3.fromRGB(20, 110, 255)
	tabs_frame.BackgroundTransparency = 0.4
	tabs_frame.ScrollBarThickness = 6
	tabs_frame.Parent = frame

	local tabs_layout = Instance.new("UIListLayout")
	tabs_layout.SortOrder = Enum.SortOrder.LayoutOrder
	tabs_layout.Padding = UDim.new(0,6)
	tabs_layout.Parent = tabs_frame

	tabs_layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		tabs_frame.CanvasSize = UDim2.new(0,0,0,tabs_layout.AbsoluteContentSize.Y + 10)
	end)

	-- Content area for all tabs
	local content_frame = Instance.new("Frame")
	content_frame.Name = "Content"
	content_frame.Size = UDim2.new(1, -155, 1, 0)
	content_frame.Position = UDim2.new(0, 155, 0, 0)
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

	return {
		Root = frame,
		TabFrame = tabs_frame,
		ContentFrame = content_frame
	}
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
		tab_button.Size = UDim2.new(1, -10, 0, 40)
		tab_button.BackgroundTransparency = 0.4
		tab_button.TextColor3 = Color3.new(1,1,1)
		tab_button.Parent = currtabframe
	end

	local tab_window = Instance.new("Frame")
	tab_window.Name = tab_name .. "_Window"
	tab_window.Size = UDim2.new(1,0,1,0)
	tab_window.BackgroundTransparency = 1
	tab_window.Visible = false
	tab_window.Parent = currbuttonsframe

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
	b.Size = UDim2.new(1, -10, 0, 40)
	b.BackgroundColor3 = Color3.fromRGB(0,0,0)
	b.BackgroundTransparency = 0.4
	b.TextColor3 = Color3.new(1,1,1)
	b.Parent = parent_frame

	b.MouseButton1Click:Connect(function()
		if callback then callback() end
	end)
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
	local current_val = init_number or min_val :: number
	current_val = math.clamp(current_val, min_val, max_val)
	if not float_enabled then
		current_val = math.floor(current_val + 0.5)
	end
	local slide_frame = Instance.new("Frame")
	slide_frame.Name = tostring(name)
	slide_frame.Size = UDim2.new(1, -20, 0, 50)
	slide_frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	slide_frame.BorderSizePixel = 1
	slide_frame.Parent = parent_frame
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -10, 0, 10)
	title.Position = UDim2.new(0, 5, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = name
	title.TextScaled = true
	title.TextColor3 = Color3.new(1,1,1)
	title.Parent = slide_frame
	local slider_bar = Instance.new("Frame")
	slider_bar.Size = UDim2.new(1, -20, 0, 6)
	slider_bar.Position = UDim2.new(0, 10, 0, 24)
	slider_bar.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	slider_bar.Parent = slide_frame
	local slider_handle = Instance.new("Frame")
	slider_handle.Size = UDim2.new(0, 12, 0, 12)
	slider_handle.AnchorPoint = Vector2.new(0, 0.5)
	slider_handle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	slider_handle.Parent = slider_bar
	local dragging = false
	local function update_value(input_position)
		local relative_x = math.clamp(input_position.X - slider_bar.AbsolutePosition.X, 0, slider_bar.AbsoluteSize.X)
		local percent = relative_x / slider_bar.AbsoluteSize.X
		local raw_val = min_val + (max_val - min_val) * percent
		if not float_enabled then
			current_val = math.floor(raw_val + 0.5)
			local snapped_percent = (current_val - min_val) / (max_val - min_val)
			slider_handle.Position = UDim2.new(snapped_percent, 0, 0.5, -6)
		else
			current_val = raw_val
			slider_handle.Position = UDim2.new(percent, 0, 0.5, -6)
		end
		if callback then
			callback(current_val)
		end
	end
	task.defer(function()
		local percent = (current_val - min_val) / (max_val - min_val)
		slider_handle.Position = UDim2.new(percent, 0, 0.5, -6)

		if callback then
			callback(current_val)
		end
	end)
	slider_handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			set_drag_lock(true, "slider")
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			update_value(input.Position)
		end
	end)
	slider_handle.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
			set_drag_lock(false)
		end
	end)
	return slide_frame
end

function NiceUI.create_text_editor(name, text, tab, callback)
	if not name then return end
	local parent_frame = get_tab_frame(tab)
	local te_frame = Instance.new("Frame")
	te_frame.Name = tostring(name)
	te_frame.Size = UDim2.new(1, -20, 0, 50)
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
	text_editor.FocusLost:Connect(function()
		local new_text = text_editor.Text
		if callback then
			callback(new_text)
		end
	end)
	return te_frame
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
