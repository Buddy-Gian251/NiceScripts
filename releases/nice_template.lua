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
gui.DisplayOrder = 4096
gui.Parent = PARENT

local currently_dragged = {}

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

local function make_draggable(item)
	local dragging = false
	local dragStart = nil
	local startPos = nil
	local holdStartTime = nil
	local holdConnection = nil
	item.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			holdStartTime = tick()
			dragStart = input.Position
			startPos = item.Position
			holdConnection = RunService.RenderStepped:Connect(function()
				if not dragging and (tick() - holdStartTime) >= 1 then
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
						task.delay(0.5, function()
							currently_dragged[item] = nil
						end)
					end
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			local newXOffset = (startPos.X.Offset + delta.X) or startPos.X.Offset
			local newYOffset = (startPos.Y.Offset + delta.Y) or startPos.Y.Offset
			item.Position = UDim2.new(
				startPos.X.Scale, newXOffset,
				startPos.Y.Scale, newYOffset
			)
		end
	end)
end

playsound(sound_files.startup, 1)

function NiceUI.create_gui(name)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = UDim2.new(0, 200, 0, 300)
	frame.Position = UDim2.new(0.5, 0, 0.4, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
	frame.BackgroundTransparency = 0.4
	frame.Parent = gui

	make_draggable(frame)

	local listframe = Instance.new("ScrollingFrame")
	listframe.Size = UDim2.new(1, 0, 1, 0)
	listframe.CanvasSize = UDim2.new(0,0,0,0)
	listframe.BackgroundTransparency = 1
	listframe.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = listframe

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		listframe.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 20)
	end)

	return {
		Root = frame,
		ButtonsFrame = listframe
	}
end

function NiceUI.create_click_button(parent, name, callback)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = name
	b.Size = UDim2.new(1, -10, 0, 40)
	b.BackgroundColor3 = Color3.fromRGB(0,0,0)
	b.BackgroundTransparency = 0.4
	b.TextColor3 = Color3.new(1,1,1)
	b.Parent = parent

	b.MouseButton1Click:Connect(function()
		if callback then callback() end
	end)
	return b
end

function NiceUI.create_slider(parent, name, value, float_enabled, range, callback)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = UDim2.new(1, -10, 0, 50)
	frame.BackgroundColor3 = Color3.fromRGB(40,40,40)
	frame.Parent = parent

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -20, 0, 6)
	bar.Position = UDim2.new(0, 10, 0, 30)
	bar.BackgroundColor3 = Color3.fromRGB(100,100,100)
	bar.Parent = frame

	local handle = Instance.new("Frame")
	handle.Size = UDim2.new(0, 12, 0, 12)
	handle.AnchorPoint = Vector2.new(0.5, 0.5)
	handle.BackgroundColor3 = Color3.fromRGB(200,200,200)
	handle.Parent = bar

	local minv, maxv = range[1], range[2]
	local current = value

	local function update(x)
		local rel = math.clamp(x - bar.AbsolutePosition.X, 0, bar.AbsoluteSize.X)
		local pct = rel / bar.AbsoluteSize.X
		local val = minv + pct * (maxv - minv)

		if not float_enabled then
			val = math.floor(val + 0.5)
			pct = (val - minv) / (maxv - minv)
		end

		handle.Position = UDim2.new(pct, 0, 0.5, 0)
		current = val
		if callback then callback(val) end
	end

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			currently_dragged[parent] = true
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and currently_dragged[parent] then
			update(input.Position.X)
		end
	end)

	handle.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			currently_dragged[parent] = nil
		end
	end)

	task.defer(function()
		local pct = (value - minv) / (maxv - minv)
		handle.Position = UDim2.new(pct,0,0.5,0)
	end)

	return frame
end

function NiceUI.create_text_editor(parent, name, text, callback)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -10, 0, 50)
	frame.BackgroundColor3 = Color3.fromRGB(40,40,40)
	frame.Parent = parent

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -10, 0, 35)
	box.Position = UDim2.new(0,5,0,10)
	box.BackgroundColor3 = Color3.fromRGB(200,200,200)
	box.Text = text
	box.ClearTextOnFocus = false
	box.Parent = frame

	box.FocusLost:Connect(function()
		if callback then callback(box.Text) end
	end)

	return frame
end

return NiceUI
