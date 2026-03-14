local UserInput = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local NSK = {} -- NiceScreenKeyboard v1

NSK.text = ""
NSK.focus = nil
NSK.active = false
NSK._inputConnection = nil
NSK._keyboardGui = nil

function NSK.StartTypingFocus(focusElement)
	if not focusElement then
		warn("No focus element provided!")
		return
	end
	NSK.focus = focusElement
	NSK.text = focusElement.Text or ""
	NSK.active = true
	if NSK._inputConnection then
		NSK._inputConnection:Disconnect()
	end
	NSK._inputConnection = UserInput.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			local key = input.KeyCode.Name
			if key == "Backspace" then
				NSK.text = NSK.text:sub(1, #NSK.text - 1)
			elseif key == "Return" or key == "Enter" then
				NSK.StopTypingFocus()
			else
				if #key == 1 then
					NSK.text = NSK.text .. key
				end
			end
			if NSK.focus then
				NSK.focus.Text = NSK.text
			end
		end
	end)
end
function NSK.GetFocused()
	return NSK.focus
end
function NSK.SetFocus(focusElement)
	if focusElement then
		NSK.focus = focusElement
		NSK.text = focusElement.Text or ""
	end
end
function NSK.GetText()
	return NSK.text
end
function NSK.StopTypingFocus()
	if NSK.focus then
		NSK.focus.Text = NSK.text
	end
	NSK.focus = nil
	NSK.active = false
	if NSK._inputConnection then
		NSK._inputConnection:Disconnect()
		NSK._inputConnection = nil
	end
end
function NSK.CastKeyboardToScreen()
	if NSK._keyboardGui then return end
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "NSK_KeyboardGui"
	ScreenGui.Parent = PlayerGui
	NSK._keyboardGui = ScreenGui
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 400, 0, 200)
	frame.Position = UDim2.new(0.5, -200, 0.7, 0)
	frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	frame.Parent = ScreenGui
	frame.Active = true
	local keys = {
		"Q","W","E","R","T","Y","U","I","O","P",
		"A","S","D","F","G","H","J","K","L",
		"Z","X","C","V","B","N","M",
		"Space","Backspace","Enter"
	}
	local xOffset, yOffset = 10, 10
	local keyWidth, keyHeight = 35, 35
	local keysPerRow = {10, 9, 7}
	local rowIndex = 1
	local countInRow = 0
	for i, key in ipairs(keys) do
		local btn = Instance.new("TextButton")
		btn.Text = key
		btn.Size = UDim2.new(0, keyWidth, 0, keyHeight)
		btn.Position = UDim2.new(0, xOffset + (keyWidth + 5) * countInRow, 0, yOffset + (keyHeight + 5) * (rowIndex - 1))
		btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
		btn.TextColor3 = Color3.new(1,1,1)
		btn.Parent = frame
		btn.MouseButton1Click:Connect(function()
			if key == "Backspace" then
				NSK.text = NSK.text:sub(1, #NSK.text - 1)
			elseif key == "Enter" then
				NSK.StopTypingFocus()
			elseif key == "Space" then
				NSK.text = NSK.text .. " "
			else
				NSK.text = NSK.text .. key
			end
			if NSK.focus then
				NSK.focus.Text = NSK.text
			end
		end)
		countInRow = countInRow + 1
		if countInRow >= keysPerRow[rowIndex] then
			rowIndex = rowIndex + 1
			countInRow = 0
		end
	end
end

return NSK
