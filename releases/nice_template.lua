local NiceUI = {} -- root of nicehouse10000e's modular UI
if not _G.nice_gui then _G.nice_gui = {} end 
_G.nice_gui.version = "153" 
_G.nice_gui.beta = false
_G.nice_gui.full_load = false
print("INITIALIZED: VERSION:".._G.nice_gui.version.."; BETA:"..tostring(_G.nice_gui.beta))
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")
local LocalPlayer = Players.LocalPlayer
local sound_files = {
	startup = "rbxassetid://587166970",
	err = "rbxassetid://5204290066",
	wrn = "rbxassetid://6838454574",
	notif = "rbxassetid://7229097896",
	close = "rbxassetid://99276942443345",
	open = "rbxassetid://987728667",
	kicked = "rbxassetid://5204290066",
	p_off = "rbxassetid://6858975342"
}
local libraries = {
	{ Name = "NSK", Source = 'https://raw.githubusercontent.com/Buddy-Gian251/NiceScripts/main/releases/NiceScreenKeyboard.lua' } --{ Name = "TweenLib", Source = script.TweenLib },{ Name = "MyURLLib", Source = "https://example.com/lib.lua" },{ Name = "FunctionLib", Source = function() print("Hello") return { Test = true } end }
}
local loaded_libraries = {}
local function xor_cipher(text, key, mode)
	local function xor_process(text, key)
		local result = {}
		for i = 1, #text do local textByte = string.byte(text, i) local keyByte = string.byte(key, ((i - 1) % #key) + 1) result[i] = string.char(bit32.bxor(textByte, keyByte)) end
		return table.concat(result)
	end
	local function string_to_hex(str) return (str:gsub(".", function(c) return string.format("%02X", string.byte(c)) end)) end
	if mode == "encode" then local raw = xor_process(text, key) return string_to_hex(raw)
	elseif mode == "decode" then local raw = text:gsub("..", function(hex) return string.char(tonumber(hex, 16)) end) return xor_process(raw, key)
	else error("Mode must be 'encode' or 'decode'") end
end
local function rand_string()
	local length = math.random(40,80)
	local s = {}
	for i = 1, length do s[i] = string.char(math.random(32, 126)) end
	return table.concat(s)
end
function IsToday(month, day)
	local now = os.date("*t")
	return (now.month == month and now.day == day)
end
local PARENT
do local success, result = pcall(function()
		if gethui then return gethui()
		elseif CoreGui:FindFirstChild("RobloxGui") then return CoreGui
		else return LocalPlayer:WaitForChild("PlayerGui")
		end end)
	PARENT = (success and result) or LocalPlayer:WaitForChild("PlayerGui")
end
local load_url = function(url)
	local success, result = pcall(function()
		local response = game:HttpGet(url)
		return response
	end)
	return success and result or nil
end
local gui = Instance.new("ScreenGui")
local sandboxgui = Instance.new("ScreenGui")
gui.Name = rand_string()
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = math.pow(2,16)
gui.Parent = PARENT
sandboxgui.Name = rand_string()
sandboxgui.ResetOnSpawn = false
sandboxgui.IgnoreGuiInset = true
sandboxgui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sandboxgui.DisplayOrder = math.pow(2,16) - 2
sandboxgui.Parent = PARENT
local gui_ready = false
local pending_tabs = {}
local theme_picker = nil
local currently_dragged = {}
local themes = {}
local drag_lock = { locked = false, reason = nil }
themes = {
	["LIFELESS GRAY"] = {
		P1  = Color3.fromRGB(180, 180, 180),-- Primary1
		P2  = Color3.fromRGB(139, 139, 139),-- Primary2
		S1  = Color3.fromRGB(197, 197, 197),-- Secondary1
		S2  = Color3.fromRGB(65, 65, 65),-- Secondary2
		S3  = Color3.fromRGB(20, 20, 20),-- Secondary3
		TB1 = Color3.fromRGB(99, 99, 99),-- TextBox1
		Name = "Lifeless Gray",-- Theme Name
	},
	["VIBRANT BLUE"] = {
		P1  = Color3.fromRGB(20, 110, 255),-- Primary1
		P2  = Color3.fromRGB(11, 60, 139),-- Primary2
		S1  = Color3.fromRGB(5, 188, 255),-- Secondary1
		S2  = Color3.fromRGB(136, 16, 255),-- Secondary2
		S3  = Color3.fromRGB(50, 50, 50),-- Secondary3
		TB1 = Color3.fromRGB(200, 200, 200),-- TextBox1
		Name = "Vibrant Blue",-- Theme Name
	}
}
local DEFAULT_THEME = "LIFELESS GRAY"
local data2 = {}
local mainframe_tweenlocked = false
local current_theme
local system_name = "NiceUI" -- APRIL FOOLS : Yeongsung UI
local frame_data = {}
local smoothSpeed = 0.3 
local main_container 
local stealth_container 
local notif_container
local curr_scale
local curr_mframe 
local currtabframe
local currbuttonsframe 
local stealthmode = false
local stealthmode_tweenlocked = false
local silent_mode = false
local stealthzonehovered = false
local univpadding = 2
local tabs = {}
local theme_changables = {}
local active_tab_window = nil
local DEFAULT_TAB_NAME = "No Category"
local THEME_FADE_TIME = 1
local master_volume = 100
local stealthtimer
local stealthconn
local defscale = 100
local scale_instance
local function player_send_message(text)
	if not text or type(text) ~= "string" then return end
	if game.TextChatService.TextChannels.RBXGeneral then
		pcall(function()
			game.TextChatService.TextChannels.RBXGeneral:SendAsync(text)
		end)
	end
end
local function format_name_for_system(name) local formatname = system_name.." Core: " return formatname..tostring(name) end -- [[NAIO means Native Application Input/Output]]
local function get_mastervolume() return master_volume / 100 end
local function playsound(id, volume)
	if stealthmode or silent_mode then return end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = (volume or 1) * get_mastervolume()
	s.Parent = gui
	s:Play()
	s.Ended:Connect(function() s:Destroy() end)
end
local sfunction = function(func, ...)
	if not func or typeof(func) ~= "function" then
		return
	end
	local success, err = pcall(func, ...)
	if not success then
		local Text = "NiceUI SafeFunction error: " .. tostring(err)
		if game.TextChatService.TextChannels.RBXGeneral then
			pcall(function()
				game.TextChatService.TextChannels.RBXGeneral:DisplaySystemMessage(Text)
			end)
		end
		playsound(sound_files.err, 10)
		warn("Function error:", err)
	end
end
local function create_styles(item)
	local UI_Corner = Instance.new("UICorner")
	local UI_Padding = Instance.new("UIPadding")
	local UI_Stroke = Instance.new("UIStroke")
	local UI_Gradient = Instance.new("UIGradient")
	UI_Corner.CornerRadius = UDim.new(0, univpadding)
	UI_Corner.Parent = item
	UI_Padding.PaddingLeft = UDim.new(0, univpadding)
	UI_Padding.PaddingRight = UDim.new(0, univpadding)
	UI_Padding.PaddingTop = UDim.new(0, univpadding)
	UI_Padding.PaddingBottom = UDim.new(0, univpadding)
	UI_Padding.Parent = item
	UI_Stroke.Color = Color3.fromRGB(255,255,255)
	UI_Stroke.Thickness = 2
	UI_Stroke.Transparency = 0.5
	UI_Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UI_Stroke.Parent = item
	UI_Gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
	}
	UI_Gradient.Rotation = 90
	UI_Gradient.Parent = item
end
local function translate(text, target)
	local body
	local success, err = pcall(function()
		local encoded = HttpService:UrlEncode(text)
		local url =
			"https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl="
			.. target ..
			"&dt=t&q=" .. encoded
		local response = game:HttpGet(url)
		body = HttpService:JSONDecode(response)
	end)
	if not success then
		warn("Translate failed:", err)
		return nil
	end
	if body and body[1] and body[1][1] then
		return body[1][1][1]
	end
	return nil
end
local function tween_prop(obj, props) local t = TweenService:Create( obj, TweenInfo.new(THEME_FADE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), props )t:Play() end
local function univ_tween(object, tweendata, propertydata, callback) if type(tweendata) ~= "table" or #tweendata <= 0 or not tweendata then tweendata = {1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut} end if not propertydata then warn(format_name_for_system("Error casted: ").."Property data is invalid or empty.") return end local tween = TweenService:Create(object, TweenInfo.new(table.unpack(tweendata)), propertydata) tween:Play() tween.Completed:Connect(function() if callback then callback() end task.wait() tween:Destroy() end) end
local frame_data = {}
local function write_frame_data(frame, data)
	if not frame or not data then return end
	frame_data[frame] = data
end
local function get_frame_data(frame)
	return frame_data[frame]
end
local function get_property(object, property, propertytype)
	if not object or not property then return end
	local success, result = pcall(function()
		return object[property]
	end)
	if success then
		if propertytype and typeof(result) ~= propertytype then
			return nil
		end
		return result
	end
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
local function set_theme(argtheme)
	if not argtheme then return end
	if type(argtheme) == "string" then
		argtheme = themes[argtheme]
	end
	current_theme = argtheme
end
local function get_theme()
	local argtheme = current_theme or themes[DEFAULT_THEME]
	return argtheme
end
local function notify(title, text, dur, no_sound)
	local s, e = pcall(function() 
		if not notif_container then return end
		local notifbox = Instance.new("Frame")
		local titletxt = Instance.new("TextLabel")
		local texttxt = Instance.new("TextLabel")
		notifbox.Parent = notif_container
		notifbox.Size = UDim2.new(1, -20, 0, 0)
		notifbox.BackgroundTransparency = 0.5
		titletxt.Parent = notifbox
		titletxt.Size = UDim2.new(1, 0, 0, 60)
		titletxt.BackgroundTransparency = 1
		titletxt.Text = tostring(title) or "Untitled"
		titletxt.TextWrapped = true
		titletxt.TextXAlignment = Enum.TextXAlignment.Left
		texttxt.Parent = notifbox
		texttxt.Size = UDim2.new(1, 0, 1, -60)
		texttxt.BackgroundTransparency = 1
		texttxt.Position = UDim2.new(0, 0, 0, 60)
		texttxt.Text = tostring(text) or "No description provided."
		texttxt.TextWrapped = true
		texttxt.TextXAlignment = Enum.TextXAlignment.Left
		NiceUI.set_theme_changable(notifbox, "S1")
		create_styles(notifbox)
		univ_tween(notifbox, {1,Enum.EasingStyle.Circular, Enum.EasingDirection.Out},{Size=UDim2.new(1, -20, 0, 120)}, function()
			Debris:AddItem(notifbox, (dur+3 or 13))
			task.delay(dur or 10, function()
				univ_tween(notifbox, {1,Enum.EasingStyle.Circular, Enum.EasingDirection.Out},{Size=UDim2.new(1, -20, 0, 0)}, function()
					notifbox:Destroy()
				end)
			end)
		end)
	end)
	if not no_sound then playsound(sound_files.notif, 2) end 
	if not s then warn(format_name_for_system("Error casted: ")..tostring(e)) end
end
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
					notify(format_name_for_system("Drag feature"), "you can now drag "..(item.Name or "this UI").." anywhere.", 1.5)
					dragging = true
					currently_dragged[item] = true
					if holdConnection then holdConnection:Disconnect() holdConnection = nil end
				end
			end)
			input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then if holdConnection then holdConnection:Disconnect() holdConnection = nil	end if dragging then dragging = false task.delay(0.2, function() currently_dragged[item] = nil end) end end end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input) if dragging and not drag_lock.locked and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local delta = input.Position - dragStart targetPos = UDim2.new( startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y ) end end)
	RunService.RenderStepped:Connect(function() if dragging and targetPos and not drag_lock.locked then item.Position = item.Position:Lerp(targetPos, smoothSpeed) end end)
end
local function is_drag_locked() return drag_lock.locked, drag_lock.reason end
local function set_drag_lock(state, reason) drag_lock.locked = state and true or false drag_lock.reason = state and (reason or "unknown") or nil end
function NiceUI.make_resizable(frame, minSize, maxSize)
	minSize = minSize or Vector2.new(100, 100)
	maxSize = maxSize or Vector2.new(1920, 1080)
	local handle = Instance.new("Frame")
	handle.Size = UDim2.new(0,16,0,16)
	handle.BackgroundColor3 = Color3.fromRGB(0, 60, 200)
	handle.BorderSizePixel = 0
	handle.ZIndex = frame.ZIndex + 10
	handle.Parent = frame.Parent
	local dragging = false
	local startMouse
	local startSize
	local function update_position()
		local absPos = frame.AbsolutePosition
		local absSize = frame.AbsoluteSize
		handle.Position = UDim2.fromOffset(
			absPos.X + absSize.X - 8,
			absPos.Y + absSize.Y + 48
		)
	end
	RunService.RenderStepped:Connect(function()
		sfunction(function()
			update_position()
			if frame.Visible then
				handle.Visible = true
			else
				handle.Visible = false
			end
		end)
	end)
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			set_drag_lock(true, "resize")
			dragging = true
			startMouse = input.Position
			startSize = frame.Size
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					set_drag_lock(false)
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - startMouse
			local newWidth = math.clamp(startSize.X.Offset + delta.X, minSize.X, maxSize.X)
			local newHeight = math.clamp(startSize.Y.Offset + delta.Y, minSize.Y, maxSize.Y)
			frame.Size = UDim2.new(0, newWidth, 0, newHeight)
		end
	end)
	update_position()
end
local function store_original(v)
	if data2[v] then return end
	local corner = v:FindFirstChildOfClass("UICorner")
	local padding = v:FindFirstChildOfClass("UIPadding")
	local stroke = v:FindFirstChildOfClass("UIStroke")
	local bg = get_property(v, "BackgroundTransparency")
	local txt = get_property(v, "TextTransparency")
	data2[v] = {
		BTransparency = bg,
		TTransparency = txt,
		Corner = corner and corner.CornerRadius,
		Padding = padding and {
			L = padding.PaddingLeft,
			R = padding.PaddingRight,
			T = padding.PaddingTop,
			B = padding.PaddingBottom
		},
		StrokeThickness = stroke and stroke.Thickness,
		StrokeTransparency = stroke and stroke.Transparency,
		CornerObj = corner,
		PaddingObj = padding,
		StrokeObj = stroke
	}
end
local function tween_descendant(v, open, __tweentime)
	local d = data2[v]
	if not d then return end
	if d.CornerObj then
		univ_tween(d.CornerObj, {__tweentime, Enum.EasingStyle.Circular, Enum.EasingDirection.Out}, {
			CornerRadius = open and d.Corner or UDim.new(0,0)
		})
	end
	if d.PaddingObj and d.Padding then
		univ_tween(d.PaddingObj, {__tweentime, Enum.EasingStyle.Circular, Enum.EasingDirection.Out}, {
			PaddingLeft = open and d.Padding.L or UDim.new(0,0),
			PaddingRight = open and d.Padding.R or UDim.new(0,0),
			PaddingTop = open and d.Padding.T or UDim.new(0,0),
			PaddingBottom = open and d.Padding.B or UDim.new(0,0)
		})
	end
	if d.StrokeObj then
		univ_tween(d.StrokeObj, {__tweentime, Enum.EasingStyle.Circular, Enum.EasingDirection.Out}, {
			Thickness = open and d.StrokeThickness or 0,
			Transparency = open and d.StrokeTransparency or 1
		})
	end
	if v:IsA("GuiObject") then
		local tween_props = {BackgroundTransparency = open and d.BTransparency or 1}
		if d.TTransparency ~= nil then
			tween_props.TextTransparency = open and d.TTransparency or 1
		end
		univ_tween(v, {__tweentime, Enum.EasingStyle.Circular, Enum.EasingDirection.Out}, tween_props)
	end
end
local function element_api(frame) return { Frame = frame, Destroy = function() if frame then frame:Destroy() end end, SetVisible = function(v) if frame then frame.Visible = v end end } end
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
	for i = 1, #list do
		table.insert(out, list[i])
	end
	return out
end
local function set_stealth(state)
	if stealthmode_tweenlocked then return end
	stealthmode = state and true or false
	if stealthmode then
		main_container.Visible = false
		stealth_container.Visible = true
		sandboxgui.Enabled = false
		main_container.Position = UDim2.new(0, 0, 1, 0)
	else
		stealthmode_tweenlocked = true
		main_container.Position = UDim2.new(0, 0, 1, 0)
		main_container.Visible = true
		stealth_container.Visible = false
		sandboxgui.Enabled = true
		univ_tween(main_container, {1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out}, { Position = UDim2.new(0, 0, 0, 0) })
	end
end
local function apply_text_contrast(ui)
	if not (ui:IsA("TextLabel") or ui:IsA("TextButton") or ui:IsA("TextBox")) then return end
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
			task.delay(0.4, function() if stroke then stroke:Destroy() end end)
		else
			ui.TextColor3 = Color3.new(0,0,0)
		end
	end
end
local function update_theme_picker()
	if not theme_picker then return end
	local items = {}
	for name, _ in pairs(themes) do 
		table.insert(items, name)  -- <-- make sure this is the string key
	end
	theme_picker:SetItems(items) -- <-- use SetItems instead of Set if using your item picker
end
function NiceUI.apply_theme()
	for i, entry in ipairs(theme_changables) do
		local obj = entry.Object
		local ch = entry.Channel
		if obj and obj.Parent then
			local theme = get_theme()
			local clr = theme[ch]
			if clr then
				if obj:IsA("UIStroke") then
					tween_prop(obj, {Color = clr})
				else
					tween_prop(obj, {BackgroundColor3 = clr})
				end
			end
		end
	end
end
function NiceUI.create_theme(name, data)
	assert(type(name) == "string", "Theme name must be a string")
	assert(type(data) == "table", "Theme data must be a table")
	themes[name] = {
		P1  = data.P1  or Color3.new(1,1,1),
		P2  = data.P2  or Color3.new(1,1,1),
		S1  = data.S1  or Color3.new(1,1,1),
		S2  = data.S2  or Color3.new(1,1,1),
		S3  = data.S3  or Color3.new(1,1,1),
		TB1 = data.TB1 or Color3.new(1,1,1),
		Name = data.Name or "Untitled"..math.round(tick()),
	}
	update_theme_picker()
end
function NiceUI.set_theme_changable(object, clrchannel)
	if not object or not object:IsA("GuiObject") then
		warn("set_theme_changable: object must be a UI object")
		return
	end
	local valid = {
		P1 = true,
		P2 = true,
		S1 = true,
		S2 = true,
		S3 = true,
		TB1 = true
	}
	if not valid[clrchannel] then
		warn("set_theme_changable: invalid color channel:", clrchannel)
		return
	end
	table.insert(theme_changables, {
		Object = object,
		Channel = clrchannel
	})
	local theme = get_theme()
	if theme and theme[clrchannel] then
		if object:IsA("UIStroke") then
			tween_prop(object, {Color = theme[clrchannel]})
		else
			tween_prop(object, {BackgroundColor3 = theme[clrchannel]})
		end
	end
end
local function init_gui()
	if gui_ready then return end
	local curtheme = get_theme()
	print(curtheme)
	main_container = Instance.new("Frame")
	main_container.Name = "MainContainer"
	main_container.Size = UDim2.fromScale(1,1)
	main_container.BackgroundTransparency = 1
	main_container.Parent = gui
	main_container.Visible = false
	stealth_container = Instance.new("Frame")
	stealth_container.Name = "StealthContainer"
	stealth_container.Size = UDim2.fromScale(1,1)
	stealth_container.BackgroundTransparency = 1
	stealth_container.Visible = false
	stealth_container.Parent = gui
	notif_container = Instance.new("ScrollingFrame")
	notif_container.Name = "NotificationContainer"
	notif_container.Parent = gui
	notif_container.Visible = false
	notif_container.Size = UDim2.new(0, 320, 1, 0)
	notif_container.AnchorPoint = Vector2.new(1,0)
	notif_container.Position = UDim2.new(1,0,0,0)
	notif_container.Transparency = 1
	notif_container.ScrollBarThickness = 2
	local notif_layout = Instance.new("UIListLayout")
	notif_layout.Parent = notif_container
	notif_layout.Padding = UDim.new(0, 10)
	notif_layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	notif_layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	notif_layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		notif_container.CanvasSize = UDim2.new(0,0,0,notif_layout.AbsoluteContentSize.Y)
	end)
	local startup_frame = Instance.new("Frame")
	startup_frame.Name = "StartupFrame"
	startup_frame.Size = UDim2.fromScale(1,1)
	startup_frame.BackgroundColor3 = Color3.new(0,0,0)
	startup_frame.BackgroundTransparency = 0.5
	startup_frame.Parent = gui
	local startup_text = Instance.new("TextLabel")
	startup_text.Size = UDim2.new(0,200,0,50)
	startup_text.Position = UDim2.new(0.5,0,0.5,0)
	startup_text.AnchorPoint = Vector2.new(0.5,0.5)
	startup_text.BackgroundTransparency = 1
	startup_text.Text = "Loading NiceUI..."
	startup_text.TextScaled = true
	startup_text.TextColor3 = Color3.new(1,1,1)
	startup_text.Font = Enum.Font.GothamBold
	startup_text.Parent = startup_frame
	local frame = Instance.new("Frame")
	local toggle = Instance.new("TextButton")
	local title = Instance.new("TextLabel")
	local tabs_frame = Instance.new("ScrollingFrame")
	local content_frame = Instance.new("Frame")
	local tabs_layout = Instance.new("UIListLayout")
	frame.Name = "NiceUI_Main"
	frame.Size = UDim2.new(0, 600, 0, 300)
	frame.Position = UDim2.new(0, 20, 0, 20)
	frame.BackgroundTransparency = 0.4
	frame.Parent = main_container
	toggle.Name = "Toggle"
	toggle.Size = UDim2.new(0, 64, 0, 32)
	toggle.Position = UDim2.new(0.5, 0, 0, 0)
	toggle.AnchorPoint = Vector2.new(0.5, 0)
	toggle.BackgroundTransparency = 0.4
	toggle.Text = system_name
	toggle.TextScaled = true
	toggle.TextColor3 = Color3.new(1,1,1)
	toggle.Font = Enum.Font.GothamBold
	toggle.Parent = main_container
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = system_name.." [v".._G.nice_gui.version.."]"
	title.TextScaled = true
	title.TextColor3 = Color3.new(1,1,1)
	title.Font = Enum.Font.GothamBold
	title.Parent = frame
	tabs_frame.Name = "Tabs"
	tabs_frame.Size = UDim2.new(0, 145, 1, -20)
	tabs_frame.Position = UDim2.new(0, 0, 0, 20)
	tabs_frame.BackgroundTransparency = 0.5
	tabs_frame.Parent = frame
	content_frame.Name = "Content"
	content_frame.Size = UDim2.new(1, -155, 1, -20)
	content_frame.Position = UDim2.new(0, 155, 0, 20)
	content_frame.BackgroundTransparency = 0.5
	content_frame.Parent = frame
	tabs_layout.Padding = UDim.new(0, 6)
	tabs_layout.Parent = tabs_frame
	tabs_layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		tabs_frame.CanvasSize = UDim2.new(0,0,0,tabs_layout.AbsoluteContentSize.Y + 10)
	end)
	local zone = Instance.new("Frame")
	zone.Name = "StealthZone"
	zone.Size = UDim2.new(0,10,0,10)
	zone.BackgroundTransparency = 0.8
	zone.ZIndex = 1
	zone.Parent = stealth_container
	scale_instance = Instance.new("UIScale")
	scale_instance.Scale = defscale / 100
	scale_instance.Parent = frame
	toggle.Activated:Connect(function()
		if next(currently_dragged) then return end
		if mainframe_tweenlocked then return end
		mainframe_tweenlocked = true
		local __tweentime = 0.3
		local data = get_frame_data(frame)
		if not data then
			data = {
				default_size = frame.Size,
				default_pos = frame.Position,
				default_transparency = frame.BackgroundTransparency,
				visible = frame.Visible,
			}
			write_frame_data(frame, data)
		end
		local is_open = not data.visible
		frame.Visible = true
		playsound(is_open and sound_files.open or sound_files.close, 3)
		if is_open then
			frame.Position = toggle.Position
			frame.Size = UDim2.new(0,0,0,0)
		end
		for _, v in ipairs(frame:GetDescendants()) do
			sfunction(function() store_original(v) end)
			sfunction(function() tween_descendant(v, is_open, __tweentime) end)
		end
		univ_tween(frame, {__tweentime, Enum.EasingStyle.Circular, Enum.EasingDirection.Out}, {
			Size = is_open and data.default_size or UDim2.new(0,0,0,0),
			Position = is_open and data.default_pos or toggle.Position,
			BackgroundTransparency = is_open and data.default_transparency or 1
		}, function()
			if not is_open then
				frame.Visible = false
			end
			mainframe_tweenlocked = false
		end)
		data.visible = is_open
		if not is_open then
			data.default_size = frame.Size
			data.default_pos = frame.Position
		end
	end)
	zone.MouseEnter:Connect(function() stealthzonehovered = true end)
	zone.MouseLeave:Connect(function() stealthzonehovered = false stealthmode_tweenlocked = false end)
	zone.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then set_stealth(not stealthmode) end end)
	create_styles(frame)
	create_styles(toggle)
	create_styles(tabs_frame)
	create_styles(content_frame)
	make_draggable(toggle)
	make_draggable(frame)
	NiceUI.set_theme_changable(frame, "P1")
	NiceUI.set_theme_changable(toggle, "P2")
	NiceUI.set_theme_changable(tabs_frame, "S1")
	NiceUI.set_theme_changable(content_frame, "S2")
	curr_mframe = frame
	currtabframe = tabs_frame
	currbuttonsframe = content_frame
	local libloaded = false
	local function load_libraries()
		if #libraries <= 0 then 
			libloaded = true 
			return 
		end
		for _, lib in ipairs(libraries) do
			sfunction(function()
				local result
				local src = lib.Source
				if typeof(src) == "Instance" and src:IsA("ModuleScript") then
					result = require(src)
				elseif type(src) == "string" then
					if src:match("^https?://") then
						src = load_url(src)
					end
					if src then
						local func = loadstring(src)
						if func then
							result = func()
						end
					end
				elseif type(src) == "function" then
					result = src()
				end
				if lib.Name then
					loaded_libraries[lib.Name] = result
				else
					table.insert(loaded_libraries, result)
				end
			end)
		end
		libloaded = true
	end
	load_libraries()
	playsound(sound_files.startup, 5)
	task.wait(2)
	while not libloaded do
		task.wait()
	end
	task.wait(2)
	gui_ready = true
	for tabName in pairs(pending_tabs) do NiceUI.create_tab(tabName) end
	NiceUI.make_resizable(curr_mframe, Vector2.new(200, 150), Vector2.new(800, 600))
	startup_frame.Visible = false
	main_container.Visible = true
	notif_container.Visible = true
	_G.nice_gui.full_load = true
	table.clear(pending_tabs)
end
function NiceUI.set_scale(scale)
	scale = math.clamp(scale, 50, 300)
	defscale = scale
	if scale_instance then
		univ_tween(scale_instance, {1}, {Scale = scale / 100}, function()
			scale_instance.Scale = scale / 100
		end)
	end
end
function NiceUI.create_gui(name, gui_smoothness)
	NiceUI.display_message("Oh No! Deprecated?", "Sorry, this function is deprecated and will be removed completely in version 154. Please use NiceUI.set_name(name) instead!")
end
function NiceUI.get_gui() return sandboxgui end
function NiceUI.set_name(name)
	assert(type(name) == "string", "GUI name must be a string")
	gui.Name = rand_string()..name
	if curr_mframe then
		local title = curr_mframe:FindFirstChild("Title")
		if title then title.Text = system_name.." [v".._G.nice_gui.version.."]: " .. name end
	end
end
function NiceUI.create_tab(tab_name)
	tab_name = tab_name or DEFAULT_TAB_NAME
	if not gui_ready then pending_tabs[tab_name] = true return nil end
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
	local padding = Instance.new("UIPadding")
	local layout = Instance.new("UIListLayout")
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
	padding.PaddingLeft = UDim.new(0,8)
	padding.PaddingRight = UDim.new(0,8)
	padding.PaddingTop = UDim.new(0,8)
	padding.PaddingBottom = UDim.new(0,8)
	padding.Parent = tab_window
	layout.Padding = UDim.new(0,10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = tab_window
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		tab_window.CanvasSize = UDim2.new(0, 0,
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
		sfunction(function()
			tab_button.Activated:Connect(function()
				if active_tab_window then 
					active_tab_window.Size = UDim2.new(1, 0, 1, 0)
					active_tab_window.Visible = true
					univ_tween(active_tab_window, {1, Enum.EasingStyle.Circular, Enum.EasingDirection.In}, {Size = UDim2.new(0, 0, 1, 0) } )
					active_tab_window.Visible = false 
				end
				active_tab_window = tab_window
				tab_window.Size = UDim2.new(0, 0, 1, 0)
				tab_window.Visible = true
				univ_tween(tab_window, {1, Enum.EasingStyle.Circular, Enum.EasingDirection.Out}, {Size = UDim2.new(1, 0, 1, 0) } )
			end)
		end)
	end
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
		warn(format_name_for_system("Error casted: GUI not ready, cannot create item picker:"), name)
		return
	end
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = name
	b.TextScaled = true
	b.Size = UDim2.new(1, 0, 0, 40)
	b.BackgroundTransparency = 0.4
	b.TextColor3 = Color3.new(1,1,1)
	b.Parent = parent_frame
	b.MouseButton1Click:Connect(function()
		if callback then sfunction(callback) end
	end)
	create_styles(b)
	NiceUI.set_theme_changable(b, "S3")
	local api = element_api(b)
	api.OnClick = function(fn)
		callback = fn
	end
	return api
end
function NiceUI.create_slider(name, init_number, float_enabled, range, tab, callback)
	if not name then return end
	if not range or type(range) ~= "table" or range[1] == nil or range[2] == nil then
		notify("Slider requires a valid range with min and max values")
		return
	end
	local parent_frame = get_tab_frame(tab)
	if not parent_frame then
		warn(format_name_for_system("Error casted: GUI not ready, cannot create item picker:"), name)
		return
	end
	local min_val = range[1] 
	local max_val = range[2] 
	if not min_val or not max_val then notify("Error", "Expected 2 arguments but nothing was filled in.", 5) return end
	if type(min_val) ~= "number" or type(max_val) ~= "number" then notify("Error", "Expected 2 arguments but left with incorrect type/s.", 5) return end
	local current_val = init_number or min_val
	local last_snapped_val = current_val
	current_val = math.clamp(current_val, min_val, max_val)
	if not float_enabled then current_val = math.floor(current_val + 0.5) end
	local slide_frame = Instance.new("Frame")
	slide_frame.Name = tostring(name)
	slide_frame.Size = UDim2.new(1, 0, 0, 50)
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
	slider_bar.Parent = slide_frame
	local slider_handle = Instance.new("Frame")
	slider_handle.Size = UDim2.new(0, 12, 0, 12)
	slider_handle.AnchorPoint = Vector2.new(0.5, 0.5)
	slider_handle.Position = UDim2.new(0, 0, 0.5, -6)
	slider_handle.BackgroundTransparency = 0.5
	slider_handle.Parent = slider_bar
	create_styles(slide_frame)
	NiceUI.set_theme_changable(slide_frame, "S3")
	NiceUI.set_theme_changable(slider_bar, "S2")
	NiceUI.set_theme_changable(slider_handle, "S1")
	local dragging = false
	local syncing = false
	local function format_value(v)
		if float_enabled then return string.format("%.2f", v)
		else return tostring(v)
		end
	end
	local function set_value(new_val)
		if syncing then return end
		syncing = true
		new_val = math.clamp(new_val, min_val, max_val)
		if not float_enabled then
			new_val = math.floor(new_val + 0.5)
		end
		if new_val ~= last_snapped_val then
			playsound("rbxassetid://14133663945", 5)
			last_snapped_val = new_val
		end
		current_val = new_val
		local percent = (current_val - min_val) / (max_val - min_val)
		slider_handle.Position = UDim2.new(percent, 0, 0.5, -6)
		input_box.Text = format_value(current_val)
		if callback then
			sfunction(callback, current_val)
		end
		syncing = false
	end
	sfunction(function()
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
		input_box.FocusLost:Connect(function()
			local num = tonumber(input_box.Text)
			if num then
				set_value(num)
			else
				input_box.Text = format_value(current_val)
			end
		end)
		task.defer(function()
			set_value(current_val)
		end)
	end)
	local api = element_api(slide_frame)
	api.OnClick = function(fn)
		callback = fn
	end
	return api
end
function NiceUI.create_text_editor(name, text, tab, callback)
	if not name then return end
	local parent_frame = get_tab_frame(tab)
	if not parent_frame then
		warn(format_name_for_system("Error casted: GUI not ready, cannot create item picker:"), name)
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
	text_editor.Text = tostring(text or "")
	text_editor.TextColor3 = Color3.fromRGB(0, 0, 0)
	text_editor.TextScaled = true
	text_editor.ClearTextOnFocus = false
	text_editor.Parent = te_frame
	create_styles(te_frame)
	create_styles(text_editor)
	NiceUI.set_theme_changable(te_frame, "S3")
	NiceUI.set_theme_changable(text_editor, "S2")
	sfunction(function()
		text_editor.FocusLost:Connect(function()
			local new_text = text_editor.Text
			if callback then
				sfunction(callback, new_text)
			end
		end)
	end)
	local api = element_api(te_frame)
	api.OnClick = function(fn)
		callback = fn
	end
	return api
end
function NiceUI.create_item_picker(name, items, default, tab, callback)
	if not name or not items then return end
	local parent_frame = get_tab_frame(tab)
	if not parent_frame then
		warn(format_name_for_system("Error casted: GUI not ready, cannot create item picker:"), name)
		return
	end
	local list = normalize_list(items)
	local selected = default or list[1]
	local picker_frame = Instance.new("Frame")
	picker_frame.Name = name
	picker_frame.Size = UDim2.new(1,0,0,80)
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
	button.TextColor3 = Color3.new(1,1,1)
	button.TextScaled = true
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.Text = tostring(selected or "Err: NoName")
	button.Parent = picker_frame
	local dropdown = Instance.new("ScrollingFrame")
	dropdown.Visible = false
	dropdown.Size = UDim2.new(1,-10,0,140)
	dropdown.Position = UDim2.new(0,5,0,70)
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
	NiceUI.set_theme_changable(picker_frame, "S3")
	NiceUI.set_theme_changable(button, "S2")
	NiceUI.set_theme_changable(dropdown, "S2")
	local function close_dropdown()
		dropdown.Visible = false
		picker_frame.Size = UDim2.new(1,0,0,80)
	end
	local function rebuild_dropdown()
		for _, child in ipairs(dropdown:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		for _, item in ipairs(list) do
			sfunction(function()
				local b = Instance.new("TextButton")
				b.Size = UDim2.new(1,-8,0,30)
				b.TextColor3 = Color3.new(1,1,1)
				b.TextScaled = true
				b.Text = tostring((item.Name or item) or "Err: NoName")
				b.Parent = dropdown
				b.MouseButton1Click:Connect(function()
					selected = item
					button.Text = tostring(selected.Name or selected)
					close_dropdown()
					if callback then sfunction(callback(item)) end
				end)
			end)
		end
	end
	sfunction(function()
		button.MouseButton1Click:Connect(function()
			dropdown.Visible = not dropdown.Visible
			picker_frame.Size = UDim2.new(1,0,0, dropdown.Visible and 240 or 80)
			if dropdown.Visible then rebuild_dropdown() end
		end)
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
		warn(format_name_for_system("Error casted: GUI not ready, cannot create item picker:"), name)
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
			sfunction(callback(currentColor))
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
	sfunction(function()
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
	end)
	task.defer(sync_from_color)
	return {
		Frame = col_edit,
		Get = function() return currentColor end,
		Set = function(c) if typeof(c) == "Color3" then currentColor = c sync_from_color() end end
	}
end
function NiceUI.create_boolean(name, default, tab, callback)
	local parent = get_tab_frame(tab)
	if not parent then warn(format_name_for_system("Error casted: GUI not ready, cannot create item picker:"), name) return end
	local state = default == true
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1,0,0,40)
	frame.BackgroundColor3 = Color3.fromRGB(50,50,50)
	frame.Parent = parent
	create_styles(frame)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.7, -10, 1, 0)
	label.Position = UDim2.new(0,5,0,0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextScaled = true
	label.TextColor3 = Color3.new(1,1,1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame
	local toggle = Instance.new("TextButton")
	toggle.Size = UDim2.new(0,36,0,18)
	toggle.Position = UDim2.new(1,-46,0.5,-9)
	toggle.BackgroundColor3 = Color3.fromRGB(80,80,80)
	toggle.Text = ""
	toggle.Parent = frame
	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0,14,0,14)
	knob.Position = UDim2.new(state and 1 or 0, state and -16 or 2, 0.5, -7)
	knob.BackgroundColor3 = Color3.fromRGB(220,220,220)
	knob.Parent = toggle
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
	local function redraw()
		local color = state
			and Color3.fromRGB(0, 200, 0)   -- green (true)
			or  Color3.fromRGB(200, 0, 0)   -- red (false)
		TweenService:Create(
			knob,
			TweenInfo.new(0.15, Enum.EasingStyle.Sine),
			{
				Position = UDim2.new(
					state and 1 or 0,
					state and -16 or 2,
					0.5, -7
				),
				BackgroundColor3 = color
			}
		):Play()
		if callback then sfunction(callback, state) end
	end
	sfunction(function()
		toggle.MouseButton1Click:Connect(function() state = not state redraw() end) redraw()
	end)
	return {
		Frame = frame,
		Get = function() return state end,
		Set = function(v) state = v == true redraw() end,
		Destroy = function() frame:Destroy() end
	}
end
function NiceUI.create_text(name, value, tab)
	local parent = get_tab_frame(tab)
	if not parent then warn(format_name_for_system("Error casted: GUI not ready, cannot create item picker:"), name) return end
	local current = tostring(value or "")
	local frame = Instance.new("Frame")
	local label = Instance.new("TextLabel")
	local valueLabel = Instance.new("TextLabel")
	frame.Size = UDim2.new(1,0,0,40)
	frame.BackgroundColor3 = Color3.fromRGB(50,50,50)
	frame.Parent = parent
	create_styles(frame)
	label.Size = UDim2.new(0.4,-10,1,0)
	label.Position = UDim2.new(0,5,0,0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextScaled = true
	label.TextColor3 = Color3.new(1,1,1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame
	valueLabel.Size = UDim2.new(0.6,-10,1,0)
	valueLabel.Position = UDim2.new(0.4,5,0,0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = current
	valueLabel.TextScaled = true
	valueLabel.TextColor3 = Color3.fromRGB(200,200,200)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = frame
	return {
		Frame = frame,
		Get = function() return current end,
		Set = function(v) current = tostring(v) valueLabel.Text = current end,
		Destroy = function() frame:Destroy() end
	}
end
function NiceUI.make_stealth_mode()
	if stealth_container.Visible then return end if stealthconn then stealthconn:Disconnect() stealthconn = nil end
	stealthtimer = 1
	set_stealth(true)
	if stealth_container.Visible then
		stealthconn = RunService.RenderStepped:Connect(function(dt)
			if not stealthzonehovered then stealthtimer = 1 return end
			stealthtimer = math.max(0, stealthtimer - dt)
			if stealthtimer <= 0 then set_stealth(false) end
		end)
	end
end
function NiceUI.create_popup(name, description, choices, callback)
	if not name then return end if not callback or type(callback) ~= "function" then return end if not choices or type(choices) ~= "table" then choices = {"Okay"} end
	local frame = Instance.new("Frame")
	local stroke = Instance.new("UIStroke")
	local shadow = Instance.new("Frame")
	local titlebar = Instance.new("Frame")
	local titleStroke = Instance.new("UIStroke")
	local title = Instance.new("TextLabel")
	local content = Instance.new("TextLabel")
	local buttons = Instance.new("Frame")
	local layout = Instance.new("UIListLayout")
	frame.Name = "popup_" .. name
	frame.Size = UDim2.fromOffset(320, 150)
	frame.Position = UDim2.new(0.5, -160, 0.5, -75)
	frame.BackgroundColor3 = Color3.fromRGB(240,240,240)
	frame.BorderSizePixel = 0
	frame.Parent = gui
	stroke.Color = Color3.fromRGB(160,160,160)
	stroke.Thickness = 1
	stroke.Parent = frame
	shadow.Size = UDim2.new(1,8,1,8)
	shadow.Position = UDim2.fromOffset(-4,-4)
	shadow.BackgroundColor3 = Color3.new(0,0,0)
	shadow.BackgroundTransparency = 0.85
	shadow.ZIndex = frame.ZIndex - 1
	shadow.Parent = frame
	titlebar.Size = UDim2.new(1,0,0,30)
	titlebar.BackgroundColor3 = Color3.fromRGB(250,250,250)
	titlebar.BorderSizePixel = 0
	titlebar.Parent = frame
	titleStroke.Color = Color3.fromRGB(210,210,210)
	titleStroke.Parent = titlebar
	title.Size = UDim2.new(1,-10,1,0)
	title.Position = UDim2.fromOffset(10,0)
	title.BackgroundTransparency = 1
	title.Text = tostring(name)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Font = Enum.Font.SourceSansSemibold
	title.TextSize = 16
	title.TextColor3 = Color3.fromRGB(20,20,20)
	title.Parent = titlebar
	content.Size = UDim2.new(1,-20,0,60)
	content.Position = UDim2.fromOffset(10,40)
	content.BackgroundTransparency = 1
	content.Text = tostring(description)
	content.TextWrapped = true
	content.TextXAlignment = Enum.TextXAlignment.Left
	content.TextYAlignment = Enum.TextYAlignment.Top
	content.Font = Enum.Font.SourceSans
	content.TextSize = 15
	content.TextColor3 = Color3.fromRGB(30,30,30)
	content.Parent = frame
	buttons.Size = UDim2.new(1,-20,0,30)
	buttons.Position = UDim2.new(0,10,1,-40)
	buttons.BackgroundTransparency = 1
	buttons.Parent = frame
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.Padding = UDim.new(0,6)
	layout.Parent = buttons
	local function createButton(text)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromOffset(80,26)
		btn.BackgroundColor3 = Color3.fromRGB(255,255,255)
		btn.BorderColor3 = Color3.fromRGB(180,180,180)
		btn.Text = text
		btn.Font = Enum.Font.SourceSans
		btn.TextSize = 15
		btn.TextColor3 = Color3.fromRGB(0,0,0)
		btn.Parent = buttons
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0,4)
		corner.Parent = btn
		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(245,245,245)
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(255,255,255)
		end)
		btn.Activated:Connect(function()
			frame:Destroy()
			sfunction(callback(text))
		end)
	end
	for _,choice in ipairs(choices) do
		createButton(tostring(choice))
	end
	createButton("Cancel")
	make_draggable(frame)
	return frame
end
function NiceUI.display_message(customtitle, customtext, customsound)
	notify(
		"NiceGui: "..tostring(customtitle),
		"NiceGui: "..tostring(customtext),
		1,
		customsound
	)
end
set_theme(DEFAULT_THEME)
init_gui()
while _G.nice_gui.full_load == false do
	task.wait()
end
local sent_tag___ = false
sfunction(function()
	if sent_tag___ then return end
	if IsToday(4, 1) then
		sent_tag___ = true
		local url
		local data
		sfunction(function()
			url = load_url("https://raw.githubusercontent.com/Buddy-Gian251/NiceScripts/main/misc/niceui_lines.json")
			data = HttpService:JSONDecode(url)
		end)
		if url then
			local randomIndex = math.random(1, #data.lines)
			player_send_message(data.lines[randomIndex])
		end
	else
		--player_send_message("i love you")
	end
end)
NiceUI.create_click_button(format_name_for_system("Activate Stealth Mode"), system_name, function() local a = {"Yes", "No"} NiceUI.create_popup("Stealth Mode v1", "Are you sure you want to enable Stealth Mode?\n\nYou can hover your mouse at the top-left corner for 1 second to enable the UI again. ", a, function(i) if i == a[1] then NiceUI.make_stealth_mode() end end) end)
NiceUI.create_slider(format_name_for_system("Master Volume"), 100, false, {0,100}, system_name, function(a) master_volume = a end)
NiceUI.create_slider(format_name_for_system("UI Scale"), 100, false, {50,300}, system_name, function(a) NiceUI.set_scale(a) end)
NiceUI.create_slider(format_name_for_system("Drag Smoothnes"), 30, false, {0, 200}, system_name, function(a) local a100 = a/100 smoothSpeed = tonumber(a100) or (30/100) end)
NiceUI.create_boolean(format_name_for_system("Silent Mode"), false, system_name, function(b) silent_mode = b end)
local theme_names = {}
for name in pairs(themes) do
	table.insert(theme_names, name)
end
theme_picker = NiceUI.create_item_picker(
	format_name_for_system("Themes"),
	theme_names,
	DEFAULT_THEME,
	system_name,
	function(selectedTheme)
		if themes[selectedTheme] then
			set_theme(selectedTheme)
			NiceUI.apply_theme()
		end
	end
)
-- LocalPlayer.Destroying:Connect(function() playsound(sound_files.kicked, 10) end) -- ts doesnt even work twin [some00004]
-- ====================
-- DEBUG: YOU MUST TURN THIS OFF IN PUBLIC RELEASES
-- ====================
if RunService:IsStudio() then
	sfunction(function()
		player_send_message("NiceUI is best! [Studio Test]")
		local __translatortxt = "hello"
		local __translatorlangtarget = "en"
		local debugname = system_name..":debug"
		NiceUI.create_click_button("safe_function_err_test1", debugname, function() sfunction(nil) end)
		NiceUI.create_click_button("safe_function_err_test2", debugname, function() for i = 1, 100 do sfunction(function() local house = nil house:Destroy() end) end end)
		NiceUI.create_text_editor("translator_text_target", __translatortxt, debugname, function(txt)
			__translatortxt = tostring(txt) and txt
		end)
		NiceUI.create_text_editor("translator_lang_target", __translatorlangtarget, debugname, function(txt)
			__translatorlangtarget = tostring(txt) and txt
		end)
		NiceUI.create_click_button("translator_translate_process", debugname, function()
			if not __translatortxt or __translatortxt == "" then return end
			if not __translatorlangtarget or __translatorlangtarget == "" then return end
			sfunction(function()
				local __translator_translated = translate(__translatortxt, __translatorlangtarget)
				if __translator_translated then	
					NiceUI.display_message("debug.translator.result", tostring("D:translator.result="..__translator_translated))
				else
					NiceUI.display_message("debug:translator.result", "err:nil")
				end
			end)
		end)
	end)
end
return NiceUI
-- EDITOR NOTE:
--[[
	i fixed it now twin, dw about a macOS user fixing shi
					-some00004
]]
