if getgenv and tonumber(getgenv().LoadTime) then
	task.wait(tonumber(getgenv().LoadTime))
else
	repeat task.wait() until game:IsLoaded()
end

local VIMVIM = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DCWebhook = (getgenv and getgenv().DiscordWebhook) or false
local GenTime = tonumber(getgenv and getgenv().GeneratorTime) or 2.5

local NotificationUI
local ActiveNotifications = {}
local ProfilePicture = ""

if DCWebhook == "" then
	DCWebhook = false
end

local function CreateNotificationUI()
	if NotificationUI then return NotificationUI end
	NotificationUI = Instance.new("ScreenGui")
	NotificationUI.Name = "NotificationUI"
	NotificationUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	NotificationUI.Parent = game:GetService("CoreGui")
	return NotificationUI
end

local function MakeNotif(title, message, duration, color)
	local ui = CreateNotificationUI()
	title = title or "Notification"
	message = message or ""
	duration = duration or 5
	color = color or Color3.fromRGB(255, 200, 0)

	local notification = Instance.new("Frame")
	notification.Name = "Notification"
	notification.Size = UDim2.new(0, 250, 0, 80)
	notification.Position = UDim2.new(1, 50, 1, 10)
	notification.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	notification.BorderSizePixel = 0
	notification.Parent = ui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = notification

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -25, 0, 25)
	titleLabel.Position = UDim2.new(0, 15, 0, 5)
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.Text = title
	titleLabel.TextSize = 18
	titleLabel.TextColor3 = color
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = notification

	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "Message"
	messageLabel.Size = UDim2.new(1, -25, 0, 50)
	messageLabel.Position = UDim2.new(0, 15, 0, 30)
	messageLabel.Font = Enum.Font.SourceSans
	messageLabel.Text = message
	messageLabel.TextSize = 16
	messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	messageLabel.BackgroundTransparency = 1
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextWrapped = true
	messageLabel.Parent = notification

	local colorBar = Instance.new("Frame")
	colorBar.Name = "ColorBar"
	colorBar.Size = UDim2.new(0, 5, 1, 0)
	colorBar.Position = UDim2.new(0, 0, 0, 0)
	colorBar.BackgroundColor3 = color
	colorBar.BorderSizePixel = 0
	colorBar.Parent = notification

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 8)
	barCorner.Parent = colorBar

	local offset = 0
	for _, notif in pairs(ActiveNotifications) do
		if notif.Instance and notif.Instance.Parent then
			offset = offset + notif.Instance.Size.Y.Offset + 10
		end
	end

	local targetPos = UDim2.new(1, -270, 1, -90 - offset)
	table.insert(ActiveNotifications, {Instance = notification, ExpireTime = os.time() + duration})

	local tween = game:GetService("TweenService"):Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = targetPos})
	tween:Play()

	task.spawn(function()
		task.wait(duration)
		local tweenOut = game:GetService("TweenService"):Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1, 50, notification.Position.Y.Scale, notification.Position.Y.Offset)})
		tweenOut:Play()
		tweenOut.Completed:Wait()

		for i, notif in pairs(ActiveNotifications) do
			if notif.Instance == notification then
				table.remove(ActiveNotifications, i)
				break
			end
		end

		notification:Destroy()
		local currentOffset = 0
		for _, notif in pairs(ActiveNotifications) do
			if notif.Instance and notif.Instance.Parent then
				game:GetService("TweenService"):Create(notif.Instance, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(1, -270, 1, -90 - currentOffset)}):Play()
				currentOffset = currentOffset + notif.Instance.Size.Y.Offset + 10
			end
		end
	end)

	return notification
end

task.spawn(function()
	while task.wait(1) do
		local currentTime = os.time()
		local reposition = false
		for i = #ActiveNotifications, 1, -1 do
			local notif = ActiveNotifications[i]
			if currentTime > notif.ExpireTime and notif.Instance and notif.Instance.Parent then
				notif.Instance:Destroy()
				table.remove(ActiveNotifications, i)
				reposition = true
			end
		end

		if reposition then
			local currentOffset = 0
			for _, notif in pairs(ActiveNotifications) do
				if notif.Instance and notif.Instance.Parent then
					notif.Instance.Position = UDim2.new(1, -270, 1, -90 - currentOffset)
					currentOffset = currentOffset + notif.Instance.Size.Y.Offset + 10
				end
			end
		end
	end
end)

MakeNotif("Shity generator is on!", "Its Loaded!!!", 5, Color3.fromRGB(115, 194, 89))

local function GetProfilePicture()
	local PlayerID = Players.LocalPlayer.UserId
	local request = request or http_request or syn.request
	local response = request({
		Url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="..PlayerID.."&size=180x180&format=png",
		Method = "GET",
		Headers = {["User-Agent"] = "Mozilla/5.0"}
	})
	local urlStart, urlEnd = string.find(response.Body, "https://[%w-_%.%?%.:/%+=&]+")
	if urlStart and urlEnd then
		ProfilePicture = string.sub(response.Body, urlStart, urlEnd)
	else
		ProfilePicture = "https://cdn.sussy.dev/bleh.jpg"
	end
end

if DCWebhook then GetProfilePicture() end

local function SendWebhook(Title, Description, Color, ProfilePicture, Footer)
	if not DCWebhook then return end
	local request = request or http_request or syn.request
	if not request then return end

	local success, errorMessage = pcall(function()
		request({
			Url = DCWebhook,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode({
				username = Players.LocalPlayer.DisplayName,
				avatar_url = ProfilePicture,
				embeds = {{title = Title, description = Description, color = Color, footer = {text = Footer}}},
			}),
		})
	end)

	if not success then
		warn("Webhook Error: "..errorMessage)
	end
end

-- ====== Generator Finder ======
local function findGenerators()
	local folder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Ingame")
	local map = folder and folder:FindFirstChild("Map")
	local generators = {}
	if map then
		for _, g in ipairs(map:GetChildren()) do
			if g.Name == "Generator" and g.Progress.Value < 100 then
				local playersNearby = false
				for _, player in ipairs(Players:GetPlayers()) do
					if player ~= Players.LocalPlayer and player:DistanceFromCharacter(g:GetPivot().Position) <= 25 then
						playersNearby = true
					end
				end
				if not playersNearby then
					table.insert(generators, g)
				end
			end
		end
	end
	table.sort(generators, function(a,b)
		local character = Players.LocalPlayer.Character
		if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
		local rootPos = character.HumanoidRootPart.Position
		return (a:GetPivot().Position - rootPos).Magnitude < (b:GetPivot().Position - rootPos).Magnitude
	end)
	return generators
end

-- ====== Visualize Generator Pivot ======
local function VisualizePivot(model)
	local pivot = model:GetPivot()
	for i, dir in ipairs({{pivot.LookVector, Color3.fromRGB(0,255,0)}, {-pivot.LookVector, Color3.fromRGB(255,0,0)}, {pivot.RightVector, Color3.fromRGB(255,255,0)}, {-pivot.RightVector, Color3.fromRGB(0,0,255)}}) do
		local part = Instance.new("Part")
		part.Size = Vector3.new(1,1,1)
		part.Anchored = true
		part.CanCollide = false
		part.Color = dir[2]
		part.Position = pivot.Position + dir[1]*5
		part.Parent = workspace
	end
end

-- ====== Pathfinding to Generator ======
local function PathFinding(generator)
	local success, _ = pcall(function()
		local sprintModule = require(game.ReplicatedStorage.Systems.Character.Game.Sprinting)
		sprintModule.StaminaLossDisabled = true
	end)

	local activeNodes = {}

	local function createNode(position)
		local part = Instance.new("Part")
		part.Size = Vector3.new(0.6,0.6,0.6)
		part.Shape = Enum.PartType.Ball
		part.Material = Enum.Material.Neon
		part.Color = Color3.fromRGB(248,255,150)
		part.Transparency = 0.5
		part.Anchored = true
		part.CanCollide = false
		part.Position = position + Vector3.new(0,1.5,0)
		part.Parent = workspace
		table.insert(activeNodes, part)
		game:GetService("Debris"):AddItem(part, 15)
	end

	if not generator or not generator.Parent then return false end
	local character = Players.LocalPlayer.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end
	local rootPart = character.HumanoidRootPart
	local targetPosition = generator:GetPivot().Position + generator:GetPivot().LookVector*3
	VisualizePivot(generator)

	local path = PathfindingService:CreatePath({AgentRadius = 2.5, AgentHeight = 1, AgentCanJump = false})
	local success, err = pcall(function() path:ComputeAsync(rootPart.Position, targetPosition) end)
	if not success or path.Status ~= Enum.PathStatus.Success then return false end
	local waypoints = path:GetWaypoints()
	if #waypoints <= 1 then return false end

	for _, waypoint in ipairs(waypoints) do
		createNode(waypoint.Position)
		humanoid:MoveTo(waypoint.Position)
		local reached = false
		local startTime = tick()
		while not reached and tick()-startTime < 5 do
			if (rootPart.Position - waypoint.Position).Magnitude < 5 then
				reached = true
			end
			RunService.Heartbeat:Wait()
		end
		if not reached then return false end
	end

	for _, node in ipairs(activeNodes) do node:Destroy() end
	return true
end

local function DoAllGenerators()
	for _, g in ipairs(findGenerators()) do
		local pathStarted = false
		for attempt = 1, 3 do
			pathStarted = PathFinding(g)
			if pathStarted then break end
			task.wait(1)
		end

		if pathStarted then
			task.wait(0.5)
			local prompt = g:FindFirstChild("Main") and g.Main:FindFirstChild("Prompt")
			if prompt then
				fireproximityprompt(prompt)
				task.wait(0.5)
			end
			for i = 1, 6 do
				if g.Progress.Value < 100 and g:FindFirstChild("Remotes") and g.Remotes:FindFirstChild("RE") then
					g.Remotes.RE:FireServer()
				end
				if i < 6 and g.Progress.Value < 100 then task.wait(GenTime) end
			end
		end
	end

	SendWebhook(
		"Generator Autofarm",
		"generators DONE! Current Balance: "..Players.LocalPlayer.PlayerData.Stats.Currency.Money.Value,
		0x00FF00,
		ProfilePicture,
		".gg/tuffguys <3"
	)
end

task.spawn(function()
	repeat task.wait(1) until Players.LocalPlayer.Character
	task.wait(2)
	DoAllGenerators()
end)
