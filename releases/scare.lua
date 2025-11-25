if _G.NICE_SCARE and _G.NICE_SCARE == true then warn("niceScare is already loaded") return end
_G.NICE_SCARE = true

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

local myself = Players.LocalPlayer

local sound_files = { -- it's always Windows that has the best sounds
	startup = "rbxassetid://9085027122",
	err = "rbxassetid://8426701399",
	succ = "rbxassetid://7762841318",
	notif = "rbxassetid://8183296024",
	close = "rbxassetid://573639200",
	kicked = "rbxassetid://8499261098"
}

local PARENT 
do
	local success, result = pcall(function()
		if gethui and typeof(gethui) == "function" then -- gethui is not available in studio environments
			return gethui()
		elseif CoreGui:FindFirstChild("RobloxGui") then
			return CoreGui
		else
			return myself:WaitForChild("PlayerGui")
		end
	end)
	PARENT = (success and result) or myself:WaitForChild("PlayerGui")
end

local rand_string = function()
	local length = math.random(10,20)
	local array = {}
	for i = 1, length do
		array[i] = string.char(math.random(32, 126))
	end
	return table.concat(array)
end

print("PARENT: "..(PARENT and PARENT:GetFullName() or "UNKNOWN"))
local gui = Instance.new("ScreenGui")
gui.Name = rand_string()
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = math.pow(2, 32)
gui.Enabled = true
gui.Parent = PARENT

local currently_dragged = {}
local Config = {
	snap_char_choice = false,
	lerpSpeed = 16,
	prediction = true
}

local playsound = function(id, vol)
	if not id or id == "" then warn("no id") return end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = vol or 1
	sound.Parent = gui
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

local message = function(title, text, ptime, no_sound)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = ptime or 3
		})
		if no_sound == false then
			playsound(sound_files.notif, 2)
		end
	end)
end

local custom_warn = function(warn_message)
	local frmt = "niceFTF ERR: "..tostring(warn_message)
	warn(frmt)
	message("niceFTF ERR", warn_message, 3, true)
	playsound(sound_files.err, 0.5)
end

local adjust_layout = function(object, adjust_x, adjust_y)
	local layout = object:FindFirstChildWhichIsA("UIListLayout") or object:FindFirstChildWhichIsA("UIGridLayout")
	local padding = object:FindFirstChildWhichIsA("UIPadding")
	if not layout then
		warn("Layout adjusting error: No UIListLayout or UIGridLayout found inside " .. object.Name)
		return
	end
	local updateCanvasSize = function()
		task.wait()
		local absContentSize = layout.AbsoluteContentSize
		local padX, padY = 0, 0
		if padding then
			padX = (padding.PaddingLeft.Offset + padding.PaddingRight.Offset)
			padY = (padding.PaddingTop.Offset + padding.PaddingBottom.Offset)
		end
		local totalX = absContentSize.X + padX + 10
		local totalY = absContentSize.Y + padY + 10
		if adjust_x and adjust_y then
			object.CanvasSize = UDim2.new(0, totalX, 0, totalY)
		elseif adjust_x then
			object.CanvasSize = UDim2.new(0, totalX, object.CanvasSize.Y.Scale, object.CanvasSize.Y.Offset)
		elseif adjust_y then
			object.CanvasSize = UDim2.new(object.CanvasSize.X.Scale, object.CanvasSize.X.Offset, 0, totalY)
		end
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
	object.ChildAdded:Connect(updateCanvasSize)
	object.ChildRemoved:Connect(updateCanvasSize)
	updateCanvasSize()
end

local make_draggable = function(UIItem, y_draggable, x_draggable)
	local dragging = false
	local dragStart = nil
	local startPos = nil
	local holdStartTime = nil
	local holdConnection = nil
	UIItem.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			holdStartTime = tick()
			dragStart = input.Position
			startPos = UIItem.Position
			holdConnection = RunService.RenderStepped:Connect(function()
				if not dragging and (tick() - holdStartTime) >= 1 then
					message("Drag feature", "you can now drag "..(UIItem.Name or "this UI").." anywhere.", 1.5)
					dragging = true
					currently_dragged[UIItem] = true
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
						task.delay(0.5, function()
							currently_dragged[UIItem] = nil
						end)
					end
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			local newXOffset = x_draggable ~= false and (startPos.X.Offset + delta.X) or startPos.X.Offset
			local newYOffset = y_draggable ~= false and (startPos.Y.Offset + delta.Y) or startPos.Y.Offset
			UIItem.Position = UDim2.new(
				startPos.X.Scale, newXOffset,
				startPos.Y.Scale, newYOffset
			)
		end
	end)
end

while not game:IsLoaded() do 
	task.wait()
end

playsound(sound_files.startup, 1)

local menu_toggle = Instance.new("TextButton")
local main_frame = Instance.new("Frame")
local buttons_frame = Instance.new("ScrollingFrame")
local buttons_frame_layout = Instance.new("UIListLayout")
menu_toggle.Position = UDim2.new(0, 60, 0, 60)
menu_toggle.Size = UDim2.new(0, 80, 0, 40)
menu_toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
menu_toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
menu_toggle.BackgroundTransparency = 0.5
menu_toggle.Text = "niceScare"
menu_toggle.TextScaled = true
menu_toggle.ZIndex = 0
menu_toggle.Parent = gui
main_frame.Position = UDim2.new(0.5, 0, 0, 100)
main_frame.Size = UDim2.new(0, 200, 0, 340)
main_frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
main_frame.BackgroundTransparency = 0.5
main_frame.AnchorPoint = Vector2.new(0.5,0)
main_frame.Visible = false
main_frame.Parent = gui
buttons_frame.Position = UDim2.new(0, 0, 0, 40)
buttons_frame.Size = UDim2.new(1, 0, 1, -40)
buttons_frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
buttons_frame.BackgroundTransparency = 0.5
buttons_frame.Parent = main_frame
buttons_frame_layout.SortOrder = Enum.SortOrder.LayoutOrder
buttons_frame_layout.Padding = UDim.new(0, 10)
buttons_frame_layout.Parent = buttons_frame

make_draggable(menu_toggle,true,true)
make_draggable(main_frame,true,true)
adjust_layout(buttons_frame,false,true)

local create_button = function(name, callback)
	if not name then return end
	local button = Instance.new("TextButton")
	button.Name = tostring(name)
	button.Size = UDim2.new(1, 0, 0, 50)
	button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	button.BackgroundTransparency = 0.5
	button.Text = tostring(name)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 14
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.TextYAlignment = Enum.TextYAlignment.Center
	button.Parent = buttons_frame
	button.MouseButton1Click:Connect(function()
		if callback then
			callback()
		end
	end)
	return button
end

local create_slider = function(name, range, float_enabled, callback)
	if not name then return end
	if not range or type(range) ~= "table" or range[1] == nil or range[2] == nil then
		warn("Slider requires a valid range with min and max values")
		return
	end
	local min_val = range[1]
	local max_val = range[2]
	local current_val = min_val
	local slide_frame = Instance.new("Frame")
	slide_frame.Name = tostring(name)
	slide_frame.Size = UDim2.new(0, 200, 0, 50)
	slide_frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	slide_frame.BorderSizePixel = 1
	slide_frame.Parent = buttons_frame
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
	slider_handle.Position = UDim2.new(0, 0, 0.5, 4)
	slider_handle.AnchorPoint = Vector2.new(0, 0.5)
	slider_handle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	slider_handle.Parent = slider_bar
	local dragging = false
	local function update_value(input_position)
		local relative_x = math.clamp(input_position.X - slider_bar.AbsolutePosition.X, 0, slider_bar.AbsoluteSize.X)
		local percent = relative_x / slider_bar.AbsoluteSize.X
		current_val = min_val + (max_val - min_val) * percent
		if not float_enabled then
			current_val = math.floor(current_val + 0.5)
		end
		slider_handle.Position = UDim2.new(percent, 0, 0.5, -6)
		if callback then
			callback(current_val)
		end
	end
	slider_handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			currently_dragged[main_frame] = true
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
			currently_dragged[main_frame] = nil
		end
	end)
	return slide_frame
end

local create_text_edit = function(name, pltext, callback)
	if not name then return end
	local te_frame = Instance.new("Frame")
	te_frame.Name = tostring(name)
	te_frame.Size = UDim2.new(0, 200, 0, 50)
	te_frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	te_frame.BorderSizePixel = 1
	te_frame.Parent = buttons_frame
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
	text_editor.Text = tostring(pltext or "")
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

local targetPLR = ""
local wait_ms = 200
local front_distance = 0

local b_targetPLR = create_text_edit("Target Player", "username", function(a)
	local a_lower = string.lower(a)
	for _, player in ipairs(Players:GetPlayers()) do
		if string.find(string.lower(player.Name), a_lower) then
			targetPLR = player.Name
			break
		end
	end
end)

local b_waitms = create_slider("Wait (ms)", {10, 1000}, false, function(v)
	if v and typeof(v) == "number" then
		wait_ms = v
	end
end)

local b_front_dist = create_slider("Distance (front)", {0, 16}, false, function(v)
    if v and typeof(v) == "number" then
        front_distance = v
    end
end)

local b_scare = create_button("Scare target", function()
	local target = Players:FindFirstChild(targetPLR)
	if target then
		local s_char = myself.Character
		local s_hrp = s_char:FindFirstChild("HumanoidRootPart")
		local t_char = target.Character
		local t_hrp = t_char:FindFirstChild("HumanoidRootPart")
		if (t_char and t_hrp) and (s_char and s_hrp) then
			message("niceScare", "Scaring "..targetPLR)
			local prev_loc = s_char:GetPivot()
			local frontCF = t_hrp.CFrame * CFrame.new(0, 0, -front_distance)
			s_char:PivotTo(frontCF)
			task.wait(wait_ms/1000)
			s_char:PivotTo(prev_loc)
		end
	end
end)

menu_toggle.Activated:Connect(function()
	if next(currently_dragged) then
		return
	end
	main_frame.Visible = not main_frame.Visible
end)
