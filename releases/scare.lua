if type(_G.NICE_SCARE) ~= "table" then
	_G.NICE_SCARE = {}
end

if _G.NICE_SCARE.loaded then
	warn("niceScare is already loaded")
	return
end

_G.NICE_SCARE.loaded = true
_G.NICE_SCARE.scaring = _G.NICE_SCARE.scaring or false

while not game:IsLoaded() do 
	task.wait()
end

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

local rand_string = function()
	local length = math.random(10,20)
	local array = {}
	for i = 1, length do
		array[i] = string.char(math.random(32, 126))
	end
	return table.concat(array)
end

local NiceGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/Buddy-Gian251/NiceScripts/main/releases/nice_template.lua'))()
local gui = NiceGui.create_gui("niceScare")

local currently_dragged = {}
local scaring = _G.NICE_SCARE.scaring or false

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

local targetPLR = ""
local wait_ms = 200
local front_distance = 0

local scare_function = function(playername) 
	if scaring then return end 
	local target = Players:FindFirstChild(playername) 
	if target then 
		scaring = true
		local s_char = myself.Character 
		local s_hrp = s_char:FindFirstChild("HumanoidRootPart") 
		local t_char = target.Character 
		local t_hrp = t_char:FindFirstChild("HumanoidRootPart") 
		if (t_char and t_hrp) and (s_char and s_hrp) then 
			message("niceScare", "Scaring "..playername) 
			local prev_loc = s_char:GetPivot() 
			local frontCF = t_hrp.CFrame * CFrame.new(0, 0, -front_distance) 
			s_char:PivotTo(frontCF) 
			task.wait(wait_ms/1000) 
			s_char:PivotTo(prev_loc) 
			scaring = false
		end 
	end 
end

local b_targetPLR = NiceGui.create_text_editor("Target Player", "username", "Targets", function(a)
	local a_lower = string.lower(a)
	for _, player in ipairs(Players:GetPlayers()) do
		if string.find(string.lower(player.Name), a_lower) then
			targetPLR = player.Name
			break
		end
	end
end)

local b_waitms = NiceGui.create_slider("Wait (ms)", 200, false, {10, 2500}, "Config", function(v)
	if v and typeof(v) == "number" then
		wait_ms = v
	end
end)

local b_front_dist = NiceGui.create_slider("Distance (front)", 4, false, {-32, 32}, "Config", function(v)
	if v and typeof(v) == "number" then
		front_distance = v
	end
end)

local b_scare = NiceGui.create_click_button("Scare target", "Targets", function() 
	scare_function(targetPLR) 
end)

local b_scare_random = NiceGui.create_click_button("Scare a random player", "Targets", function() 
	local random_player = Players:GetPlayers()[math.random(1, #Players:GetPlayers())] 
	if random_player then 
		scare_function(random_player.Name) 
	end 
end)
