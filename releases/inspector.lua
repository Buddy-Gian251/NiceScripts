--[[
nicehouse10000e, I have finally used your NiceUI
it's good ngl
  -- some00004
]]
local open_source = loadstring(game:HttpGet("https://github.com/Buddy-Gian251/NiceScripts/raw/main/releases/nice_template.lua"))()
local gui = open_source.set_name('NiceInspector', 0.25)
open_source.lock("04292014", true, true)

local guiParent = open_source.get_gui()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local CONFIG = {
	Enabled = false,
	HighlightPart = false,
	HighlightOnTop = false,
	ShowFullName = false,
	ShowDistance = false,
}

local Mouse = LocalPlayer:GetMouse()

local lastClickTime = 0
local DOUBLE_CLICK_THRESHOLD = 0.3 -- seconds

local currentTarget = nil

local active_texts = {}

RunService.RenderStepped:Connect(function()
	currentTarget = Mouse.Target
end)

local function getDistance(part)
	if not part then return 0 end
	return (Camera.CFrame.Position - part.Position).Magnitude
end

function showPartDetails(part)
	if not part then return end

	local tab = "Inspector"

	-- 🔥 CLEAR OLD UI
	for i, textObj in ipairs(active_texts) do
		if textObj and textObj.Destroy then
			textObj:Destroy()
		end
	end
	table.clear(active_texts)

	-- helper to create + store
	local function addText(name, value)
		local t = open_source.create_text(name, value, tab)
		table.insert(active_texts, t)
	end

	-- Full Name
	if CONFIG.ShowFullName then
		addText("Full Name", part:GetFullName())
	end

	-- Distance
	if CONFIG.ShowDistance then
		addText("Distance", math.floor(getDistance(part)).." studs")
	end

	-- Class
	addText("Class", part.ClassName)

	-- Properties
	local props = {
		"Name",
		"Parent",
		"Anchored",
		"CanCollide",
		"Transparency",
		"Material"
	}

	for _, prop in ipairs(props) do
		local success, value = pcall(function()
			return part[prop]
		end)

		if success then
			addText(prop, tostring(value))
		end
	end
end

Mouse.Button1Down:Connect(function()
	local now = tick()

	if now - lastClickTime <= DOUBLE_CLICK_THRESHOLD then
		-- DOUBLE CLICK DETECTED
		if currentTarget then
			print("Double clicked:", currentTarget.Name)
			-- we'll handle UI here next
			showPartDetails(currentTarget)
		end
	end

	lastClickTime = now
end)
