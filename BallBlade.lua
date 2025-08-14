
-- Unified Auto Parry System
local Players = game:GetService('Players')
local Player = Players.LocalPlayer
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local VirtualInputService = game:GetService("VirtualInputManager")
local Camera = workspace.CurrentCamera
local Debris = game:GetService('Debris')

-- Configuration
local AutoParryConfig = {
    Enabled = false,
    LobbyEnabled = false,
    
    -- Parry Settings
    ParryAccuracy = 100,
    RandomAccuracy = false,
    
    -- Curve Settings
    CurveType = "Camera", -- "Camera", "Random", "Backwards", "Straight", "High", "Left", "Right", "RandomTarget"
    
    -- Detection Settings
    PhantomDetection = false,
    InfinityDetection = false,
    DeathSlashDetection = false,
    TimeHoleDetection = false,
    
    -- Input Settings
    UseKeypress = false,
    
    -- Safety Settings
    CooldownProtection = false,
    AutoAbility = false,
}

-- Variables
local Connections = {}
local Parried = false
local Last_Parry = 0
local Speed_Divisor_Multiplier = 1.1
local Infinity = false
local deathshit = false
local timehole = false
local Tornado_Time = tick()

-- Get Remote Events (from original script)
local PropertyChangeOrder = {}
local ShouldPlayerJump, MainRemote, GetOpponentPosition
local Parry_Key

-- Initialize remotes (simplified version)
local function initializeRemotes()
    -- This would contain the remote detection logic from original script
    -- For brevity, assuming remotes are already found
end

-- Parry function
local function Parry(...)
    if ShouldPlayerJump and MainRemote and GetOpponentPosition and Parry_Key then
        ShouldPlayerJump:FireServer("HashOne", Parry_Key, ...)
        MainRemote:FireServer("HashTwo", Parry_Key, ...)
        GetOpponentPosition:FireServer("HashThree", Parry_Key, ...)
    end
end

-- Get Ball Functions
local function GetMainBall()
    for _, Ball in pairs(workspace.Balls:GetChildren()) do
        if Ball:GetAttribute('realBall') then
            Ball.CanCollide = false
            return Ball
        end
    end
end

local function GetLobbyBall()
    for _, Ball in pairs(workspace.TrainingBalls:GetChildren()) do
        if Ball:GetAttribute("realBall") then
            return Ball
        end
    end
end

local function GetAllBalls()
    local Balls = {}
    for _, Ball in pairs(workspace.Balls:GetChildren()) do
        if Ball:GetAttribute('realBall') then
            Ball.CanCollide = false
            table.insert(Balls, Ball)
        end
    end
    return Balls
end

-- Closest Player Detection
local function GetClosestPlayer()
    local MaxDistance = math.huge
    local ClosestEntity = nil
    
    for _, Entity in pairs(workspace.Alive:GetChildren()) do
        if tostring(Entity) ~= tostring(Player) and Entity.PrimaryPart then
            local Distance = Player:DistanceFromCharacter(Entity.PrimaryPart.Position)
            if Distance < MaxDistance then
                MaxDistance = Distance
                ClosestEntity = Entity
            end
        end
    end
    
    return ClosestEntity
end

-- Mouse/Touch Position Detection
local function getMousePosition()
    local LastInput = UserInputService:GetLastInputType()
    local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
    
    if isMobile then
        return {Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2}
    elseif LastInput == Enum.UserInputType.MouseButton1 or LastInput == Enum.UserInputType.MouseButton2 or LastInput == Enum.UserInputType.Keyboard then
        local MouseLocation = UserInputService:GetMouseLocation()
        return {MouseLocation.X, MouseLocation.Y}
    else
        return {Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2}
    end
end

-- Curve Calculation
local function calculateCurveData(curveType)
    local mousePos = getMousePosition()
    local events = {}
    
    -- Get screen positions of all players
    for _, v in pairs(workspace.Alive:GetChildren()) do
        if v ~= Player.Character and v.PrimaryPart then
            local worldPos = v.PrimaryPart.Position
            local screenPos = Camera:WorldToScreenPoint(worldPos)
            events[tostring(v)] = screenPos
        end
    end
    
    local cframe
    local targetScreenPos = mousePos
    
    if curveType == 'Camera' then
        cframe = Camera.CFrame
        
    elseif curveType == 'Backwards' then
        local backDir = Camera.CFrame.LookVector * -10000
        backDir = Vector3.new(backDir.X, 0, backDir.Z)
        cframe = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + backDir)
        
    elseif curveType == 'Straight' then
        local aimedPlayer = nil
        local closestDist = math.huge
        local mouseVector = Vector2.new(mousePos[1], mousePos[2])
        
        for _, v in pairs(workspace.Alive:GetChildren()) do
            if v ~= Player.Character and v.PrimaryPart then
                local worldPos = v.PrimaryPart.Position
                local screenPos, isOnScreen = Camera:WorldToScreenPoint(worldPos)
                
                if isOnScreen then
                    local playerScreenPos = Vector2.new(screenPos.X, screenPos.Y)
                    local distance = (mouseVector - playerScreenPos).Magnitude
                    
                    if distance < closestDist then
                        closestDist = distance
                        aimedPlayer = v
                    end
                end
            end
        end
        
        if aimedPlayer then
            cframe = CFrame.new(Player.Character.PrimaryPart.Position, aimedPlayer.PrimaryPart.Position)
            local screenPos = Camera:WorldToScreenPoint(aimedPlayer.PrimaryPart.Position)
            targetScreenPos = {screenPos.X, screenPos.Y}
        else
            local closestEntity = GetClosestPlayer()
            if closestEntity then
                cframe = CFrame.new(Player.Character.PrimaryPart.Position, closestEntity.PrimaryPart.Position)
            else
                cframe = Camera.CFrame
            end
        end
        
    elseif curveType == 'Random' then
        local randomPos = Vector3.new(math.random(-4000, 4000), math.random(-4000, 4000), math.random(-4000, 4000))
        cframe = CFrame.new(Camera.CFrame.Position, randomPos)
        
    elseif curveType == 'High' then
        local highDir = Camera.CFrame.UpVector * 10000
        cframe = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + highDir)
        
    elseif curveType == 'Left' then
        local leftDir = Camera.CFrame.RightVector * 10000
        cframe = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position - leftDir)
        
    elseif curveType == 'Right' then
        local rightDir = Camera.CFrame.RightVector * 10000
        cframe = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + rightDir)
        
    elseif curveType == 'RandomTarget' then
        local candidates = {}
        for _, v in pairs(workspace.Alive:GetChildren()) do
            if v ~= Player.Character and v.PrimaryPart then
                local screenPos, isOnScreen = Camera:WorldToScreenPoint(v.PrimaryPart.Position)
                if isOnScreen then
                    table.insert(candidates, {
                        character = v,
                        screenPos = {screenPos.X, screenPos.Y}
                    })
                end
            end
        end
        
        if #candidates > 0 then
            local randomPick = candidates[math.random(1, #candidates)]
            cframe = CFrame.new(Player.Character.PrimaryPart.Position, randomPick.character.PrimaryPart.Position)
            targetScreenPos = randomPick.screenPos
        else
            cframe = Camera.CFrame
        end
    else
        cframe = Camera.CFrame
    end
    
    return {0, cframe, events, targetScreenPos}
end

-- Curve Detection
local Lerp_Radians = 0
local Last_Warping = tick()
local Curving = tick()

local function linearInterpolation(a, b, time_volume)
    return a + (b - a) * time_volume
end

local function isCurved(ball)
    if not ball then return false end
    
    local Zoomies = ball:FindFirstChild('zoomies')
    if not Zoomies then return false end
    
    local Velocity = Zoomies.VectorVelocity
    local Ball_Direction = Velocity.Unit
    local Direction = (Player.Character.PrimaryPart.Position - ball.Position).Unit
    local Dot = Direction:Dot(Ball_Direction)
    local Speed = Velocity.Magnitude
    local Speed_Threshold = math.min(Speed / 100, 40)
    local Direction_Difference = (Ball_Direction - Velocity).Unit
    local Direction_Similarity = Direction:Dot(Direction_Difference)
    local Dot_Difference = Dot - Direction_Similarity
    local Distance = (Player.Character.PrimaryPart.Position - ball.Position).Magnitude
    local Pings = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()
    local Dot_Threshold = 0.5 - (Pings / 1000)
    local Reach_Time = Distance / Speed - (Pings / 1000)
    local Ball_Distance_Threshold = 15 - math.min(Distance / 1000, 15) + Speed_Threshold
    local Clamped_Dot = math.clamp(Dot, -1, 1)
    local Radians = math.rad(math.asin(Clamped_Dot))
    
    Lerp_Radians = linearInterpolation(Lerp_Radians, Radians, 0.8)
    
    if Speed > 100 and Reach_Time > Pings / 10 then
        Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 15, 15)
    end
    
    if Distance < Ball_Distance_Threshold then
        return false
    end
    
    if Dot_Difference < Dot_Threshold then
        return true
    end
    
    if Lerp_Radians < 0.018 then
        Last_Warping = tick()
    end
    
    if (tick() - Last_Warping) < (Reach_Time / 1.5) then
        return true
    end
    
    if (tick() - Curving) < (Reach_Time / 1.5) then
        return true
    end
    
    return Dot < Dot_Threshold
end

-- Safety Checks
local function isSafeToParry(ball)
    -- Check for tornado
    local Runtime = workspace:FindFirstChild("Runtime")
    if Runtime and Runtime:FindFirstChild('Tornado') then
        if (tick() - Tornado_Time) < (Runtime.Tornado:GetAttribute("TornadoTime") or 1) + 0.314159 then
            return false
        end
    end
    
    -- Check for combo counter (Slash of Fury)
    if ball:FindFirstChild("ComboCounter") then
        return false
    end
    
    -- Check for singularity cape
    if Player.Character.PrimaryPart:FindFirstChild('SingularityCape') then
        return false
    end
    
    -- Check detection settings
    if AutoParryConfig.InfinityDetection and Infinity then
        return false
    end
    
    if AutoParryConfig.DeathSlashDetection and deathshit then
        return false
    end
    
    if AutoParryConfig.TimeHoleDetection and timehole then
        return false
    end
    
    return true
end

-- Parry Animation
local function playParryAnimation()
    local ParryAnimation = game:GetService("ReplicatedStorage").Shared.SwordAPI.Collection.Default:FindFirstChild('GrabParry')
    local CurrentSword = Player.Character:GetAttribute('CurrentlyEquippedSword')
    
    if not CurrentSword or not ParryAnimation then
        return
    end
    
    local SwordData = game:GetService("ReplicatedStorage").Shared.ReplicatedInstances.Swords.GetSword:Invoke(CurrentSword)
    if not SwordData or not SwordData['AnimationType'] then
        return
    end
    
    for _, object in pairs(game:GetService('ReplicatedStorage').Shared.SwordAPI.Collection:GetChildren()) do
        if object.Name == SwordData['AnimationType'] then
            if object:FindFirstChild('GrabParry') or object:FindFirstChild('Grab') then
                local swordAnimationType = object:FindFirstChild('GrabParry') and 'GrabParry' or 'Grab'
                ParryAnimation = object[swordAnimationType]
            end
        end
    end
    
    local GrabParry = Player.Character.Humanoid.Animator:LoadAnimation(ParryAnimation)
    GrabParry:Play()
end

-- Execute Parry
local function executeParry()
    local parryData = calculateCurveData(AutoParryConfig.CurveType)
    
    if AutoParryConfig.UseKeypress then
        VirtualInputService:SendKeyEvent(true, Enum.KeyCode.F, false, nil)
    else
        Parry(parryData[1], parryData[2], parryData[3], parryData[4])
    end
end false, nil)
    else
        Parry(parryData[1], parryData[2], parryData[3], parryData[4])
    end
    
    -- Update parry count for spam protection
    if Parries > 7 then
        return
    end
    
    Parries = Parries + 1
    task.delay(0.5, function()
        if Parries > 0 then
            Parries = Parries - 1
        end
    end)
end

-- Spam Parry Logic (removed)

-- Main Auto Parry Logic
local function mainAutoParryLogic()
    local balls = GetAllBalls()
    local lobbyBall = GetLobbyBall()
    
    -- Handle lobby parry
    if AutoParryConfig.LobbyEnabled and lobbyBall then
        local zoomies = lobbyBall:FindFirstChild('zoomies')
        if zoomies then
            local ballTarget = lobbyBall:GetAttribute('target')
            local velocity = zoomies.VectorVelocity
            local distance = Player:DistanceFromCharacter(lobbyBall.Position)
            local speed = velocity.Magnitude
            
            local ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue() / 10
            local cappedSpeedDiff = math.min(math.max(speed - 9.5, 0), 650)
            local speedDivisorBase = 2.4 + cappedSpeedDiff * 0.002
            
            local effectiveMultiplier = Speed_Divisor_Multiplier
            if AutoParryConfig.RandomAccuracy then
                effectiveMultiplier = 0.7 + (math.random(1, 100) - 1) * (0.35 / 99)
            end
            
            local speedDivisor = speedDivisorBase * effectiveMultiplier
            local parryAccuracy = ping + math.max(speed / speedDivisor, 9.5)
            
            if ballTarget == tostring(Player) and distance <= parryAccuracy then
                executeParry()
                Parried = true
                return
            end
        end
    end
    
    -- Handle main game parry
    if not AutoParryConfig.Enabled then return end
    
    for _, ball in pairs(balls) do
        if not ball then continue end
        
        local zoomies = ball:FindFirstChild('zoomies')
        if not zoomies then continue end
        
        -- Reset parry state when target changes
        ball:GetAttributeChangedSignal('target'):Once(function()
            Parried = false
        end)
        
        if Parried then continue end
        
        local ballTarget = ball:GetAttribute('target')
        local velocity = zoomies.VectorVelocity
        local distance = (Player.Character.PrimaryPart.Position - ball.Position).Magnitude
        local speed = velocity.Magnitude
        
        -- Safety checks
        if not isSafeToParry(ball) then continue end
        
        -- Curve detection
        local curved = isCurved(ball)
        if ballTarget == tostring(Player) and curved then continue end
        
        -- Calculate timing
        local ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue() / 10
        local pingThreshold = math.clamp(ping / 10, 5, 17)
        
        local cappedSpeedDiff = math.min(math.max(speed - 9.5, 0), 650)
        local speedDivisorBase = 2.4 + cappedSpeedDiff * 0.002
        
        local effectiveMultiplier = Speed_Divisor_Multiplier
        if AutoParryConfig.RandomAccuracy then
            if speed < 200 then
                effectiveMultiplier = 0.7 + (math.random(40, 100) - 1) * (0.35 / 99)
            else
                effectiveMultiplier = 0.7 + (math.random(1, 100) - 1) * (0.35 / 99)
            end
        end
        
        local speedDivisor = speedDivisorBase * effectiveMultiplier
        local parryAccuracy = pingThreshold + math.max(speed / speedDivisor, 9.5)
        
        -- Main parry logic
        if ballTarget == tostring(Player) and distance <= parryAccuracy then
            local parryTime = os.clock()
            local timeView = parryTime - Last_Parry
            
            if timeView > 0.5 then
                playParryAnimation()
            end
            
            executeParry()
            Last_Parry = parryTime
            Parried = true
        end
        
        -- Prevent multiple parries
        local lastParryTime = tick()
        repeat
            RunService.PreSimulation:Wait()
        until (tick() - lastParryTime) >= 1 or not Parried
        Parried = false
    end
end

-- Public API
local UnifiedAutoParry = {}

function UnifiedAutoParry.SetConfig(config)
    for key, value in pairs(config) do
        if AutoParryConfig[key] ~= nil then
            AutoParryConfig[key] = value
        end
    end
end

function UnifiedAutoParry.GetConfig()
    return AutoParryConfig
end

function UnifiedAutoParry.Start()
    if Connections.MainLoop then return end
    
    initializeRemotes()
    
    Connections.MainLoop = RunService.PreSimulation:Connect(mainAutoParryLogic)
    
    -- Listen for infinity detection
    game.ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(a, b)
        Infinity = b or false
    end)
end

function UnifiedAutoParry.Stop()
    if Connections.MainLoop then
        Connections.MainLoop:Disconnect()
        Connections.MainLoop = nil
    end
end

function UnifiedAutoParry.Toggle()
    if Connections.MainLoop then
        UnifiedAutoParry.Stop()
    else
        UnifiedAutoParry.Start()
    end
end

-- Usage Example:
--[[
UnifiedAutoParry.SetConfig({
    Enabled = true,
    LobbyEnabled = true,
    SpamEnabled = true,
    CurveType = "Straight",
    ParryAccuracy = 85,
    RandomAccuracy = true,
    PhantomDetection = true,
    InfinityDetection = true
})

UnifiedAutoParry.Start()
]]

return UnifiedAutoParry
