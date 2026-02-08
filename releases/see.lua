local open_source = loadstring(game:HttpGet("https://github.com/Buddy-Gian251/NiceScripts/raw/main/releases/nice_template.lua"))()
local gui = open_source.set_name('"SEE" cheats', 0.25)

if type(_G.see) ~= "table" then _G.see = {} end
if _G.see.loaded then
	warn("SEE already loaded")
	return
end
_G.see.loaded = true

while not game:IsLoaded() do task.wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local CONFIG = {
	Enabled = false,

	ShowFrames = true,
	ShowLines = true,
	ShowNames = true,
	ShowHealth = true,
	ShowDistance = false,

	MaxDistance = 16384,
	LineOrigin = Vector2.new(0.5, 1),
}

local ESP_STORE = {} -- [player] = {folder, conn}

local function removeESP(player)
	local data = ESP_STORE[player]
	if not data then return end

	if data.conn then
		data.conn:Disconnect()
	end

	if data.folder then
		data.folder:Destroy()
	end

	ESP_STORE[player] = nil
end

local function createESP(player, hrp)
	removeESP(player)

	local guiParent = open_source.get_gui()

	local folder = Instance.new("Folder")
	folder.Name = "SEE_ESP_" .. player.UserId
	folder.Parent = guiParent

	local label = Instance.new("TextLabel")
	label.Name = "NameLabel"
	label.Size = UDim2.fromOffset(200, 18)
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1,1,1)
	label.Visible = false
	label.Parent = folder

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.new(0,0,0)
	stroke.Parent = label

	local box = Instance.new("Frame")
	box.Name = "Box"
	box.BackgroundTransparency = 0.5
	box.BorderSizePixel = 2
	box.BorderColor3 = Color3.fromRGB(255,0,0)
	box.Visible = false
	box.Parent = folder

	local line = Instance.new("Frame")
	line.Name = "SnapLine"
	line.AnchorPoint = Vector2.new(0, 0.5)
	line.BackgroundColor3 = Color3.fromRGB(255,255,255)
	line.BorderSizePixel = 0
	line.Size = UDim2.fromOffset(0, 2)
	line.Visible = false
	line.Parent = folder

	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not CONFIG.Enabled or not hrp.Parent then
			label.Visible = false
			box.Visible = false
			line.Visible = false
			return
		end

		local char = hrp.Parent
		local hum = char:FindFirstChildOfClass("Humanoid")
		local head = char:FindFirstChild("Head")
		if not hum or not head then return end

		local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
		if dist > CONFIG.MaxDistance then
			label.Visible = false
			box.Visible = false
			line.Visible = false
			return
		end

		local rootPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
		if not onScreen or rootPos.Z < 0 then
			label.Visible = false
			box.Visible = false
			line.Visible = false
			return
		end

		local text = ""
		if CONFIG.ShowNames then text = player.Name end
		if CONFIG.ShowHealth then text ..= " [" .. math.floor(hum.Health) .. "]" end
		if CONFIG.ShowDistance then text ..= " (" .. math.floor(dist) .. "m)" end

		if text ~= "" then
			label.Text = text
		
			-- Team color (fallback to white)
			if player.Team then
				label.TextColor3 = player.TeamColor.Color
			else
				label.TextColor3 = Color3.new(1, 1, 1)
			end
		
			label.Position = UDim2.fromOffset(rootPos.X, rootPos.Y - 20)
			label.Visible = true
		else
			label.Visible = false
		end

		-- BOX
		if CONFIG.ShowFrames then
			local top = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.3,0))
			local bottom = Camera:WorldToViewportPoint(
				hrp.Position - Vector3.new(0, hum.HipHeight, 0)
			)

			local h = math.abs(bottom.Y - top.Y)
			local w = h / 2

			box.Size = UDim2.fromOffset(w, h)
			box.Position = UDim2.fromOffset(top.X - w/2, top.Y)
			box.Visible = true
		else
			box.Visible = false
		end

		if CONFIG.ShowLines then
			local from = Vector2.new(
				Camera.ViewportSize.X * CONFIG.LineOrigin.X,
				Camera.ViewportSize.Y * CONFIG.LineOrigin.Y
			)
			local to = Vector2.new(rootPos.X, rootPos.Y)

			local d = to - from
			local len = d.Magnitude
			local ang = math.deg(math.atan2(d.Y, d.X))

			line.Position = UDim2.fromOffset(from.X, from.Y)
			line.Size = UDim2.fromOffset(len, 2)
			line.Rotation = ang
			line.Visible = true
		else
			line.Visible = false
		end
	end)

	ESP_STORE[player] = { folder = folder, conn = conn }
end

local function hookPlayer(player)
	if player == LocalPlayer then return end

	player.CharacterAdded:Connect(function(char)
		local hrp = char:WaitForChild("HumanoidRootPart", 5)
		if hrp then createESP(player, hrp) end
	end)

	player.CharacterRemoving:Connect(function()
		removeESP(player)
	end)

	if player.Character then
		local hrp = player.Character:FindFirstChild("HumanoidRootPart")
		if hrp then createESP(player, hrp) end
	end
end

for _, p in ipairs(Players:GetPlayers()) do
	hookPlayer(p)
end

Players.PlayerAdded:Connect(hookPlayer)
Players.PlayerRemoving:Connect(removeESP)

open_source.create_click_button("Toggle SEE", "ESP", function()
	CONFIG.Enabled = not CONFIG.Enabled
end)

open_source.create_click_button("Toggle Frames", "ESP", function()
	CONFIG.ShowFrames = not CONFIG.ShowFrames
end)

open_source.create_click_button("Toggle Lines", "ESP", function()
	CONFIG.ShowLines = not CONFIG.ShowLines
end)

open_source.create_click_button("Toggle Names", "ESP", function()
	CONFIG.ShowNames = not CONFIG.ShowNames
end)

open_source.create_click_button("Toggle Health", "ESP", function()
	CONFIG.ShowHealth = not CONFIG.ShowHealth
end)

open_source.create_click_button("Toggle Distance", "ESP", function()
	CONFIG.ShowDistance = not CONFIG.ShowDistance
end)
