if type(_G.NICE_ARRESTAURA) ~= "table" then
	_G.NICE_ARRESTAURA = {}
end

if _G.NICE_ARRESTAURA.loaded then
	warn("niceScare is already loaded")
	return
end

while not game:IsLoaded() do 
	task.wait()
end

local NiceGui = require(game:GetService("ReplicatedStorage"):WaitForChild("nicegui")) --loadstring(game:HttpGet('https://raw.githubusercontent.com/Buddy-Gian251/NiceScripts/main/releases/nice_template.lua'))()
local gui = NiceGui.create_gui("niceScare")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SELF = Players.LocalPlayer
local ARREST_REMOTE = ReplicatedStorage.Remotes.ArrestPlayer

_G.NICE_ARRESTAURA.enabled = _G.NICE_ARRESTAURA.enabled or false
_G.NICE_ARRESTAURA.range = _G.NICE_ARRESTAURA.range or 10

local enabled = _G.NICE_ARRESTAURA.enabled
local aura_range = _G.NICE_ARRESTAURA.range
local conn = nil

local aura_button = NiceGui.create_click_button("Toggle Aura", function() 
	enabled = not enabled
	_G.NICE_ARRESTAURA.enabled = enabled
	if not enabled then
		NiceGui.display_message("Arrest Aura", "Arrest Aura Disabled", "rbxassetid://118011393482317")
		if conn then
			conn:Disconnect()
			conn = nil
		end
	else
		NiceGui.display_message("Arrest Aura", "Arrest Aura Enabled", "rbxassetid://987728667")
		conn = RunService.Heartbeat:Connect(function() --ref: https://rawscripts.net/raw/Prison-Life-Arrest-Aura-OPEN-SOURCE-61190
			local root = SELF.Character and SELF.Character:FindFirstChild("HumanoidRootPart")
			if not root then return end
			for _, plr in Players:GetPlayers() do
				if plr == SELF then continue end
				local char = plr.Character
				if not char then continue end
				local hrp = char:FindFirstChild("HumanoidRootPart")
				local hum = char:FindFirstChild("Humanoid")
				if not hrp or not hum or hum.Health <= 0 then continue end
				if (root.Position - hrp.Position).Magnitude <= aura_range then
					task.spawn(function()
						pcall(ARREST_REMOTE.InvokeServer, ARREST_REMOTE, plr)
					end)
				end
			end
		end)
	end
end)

local range_editor = NiceGui.create_slider("RANGE", aura_range or 10, false, {5, 500}, function(val)
	aura_range = tonumber(val)
end)
