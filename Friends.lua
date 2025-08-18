wait(2)
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local cam = workspace.CurrentCamera
local runService = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local rs = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")

-- ui lib
local Obsidian = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/obsidian.lua"))()

-- settings
local settings = {
    autoHunger = false,
    autoFarm = false,
    autoBreak = false,
    noclipActive = false,
    playerEsp = false,
    itemEsp = false,
    hitboxes = {
        wolves = false,
        rabbits = false,
        cultists = false,
        size = 15,
        visible = false
    }
}

-- some helper functions
local function notify(title, msg)
    game.StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = msg,
        Duration = 3
    })
end

local function getPlayer()
    return plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
end

local function bringItems(itemName)
    local root = getPlayer()
    if not root then return end
    
    for i,v in pairs(workspace.Items:GetChildren()) do
        if string.find(string.lower(v.Name), string.lower(itemName)) then
            local part = v:FindFirstChildOfClass("BasePart")
            if part then
                part.CFrame = root.CFrame * CFrame.new(math.random(-3,3), 2, math.random(-3,3))
            end
        end
    end
end

-- esp stuff
local function makeEsp(obj, color, text)
    if not obj then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Parent = obj
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = color
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    local gui = Instance.new("BillboardGui")
    gui.Parent = obj
    gui.Size = UDim2.new(0, 100, 0, 50)
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.AlwaysOnTop = true
    
    local label = Instance.new("TextLabel")
    label.Parent = gui
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.TextScaled = true
    label.Text = text
    label.Font = Enum.Font.SourceSans
end

local function removeEsp(obj)
    if obj then
        local highlight = obj:FindFirstChild("Highlight")
        if highlight then highlight:Destroy() end
        local gui = obj:FindFirstChild("BillboardGui")
        if gui then gui:Destroy() end
    end
end

-- hitbox stuff
local function updateHitboxes()
    for i,v in pairs(workspace.Characters:GetChildren()) do
        local hrp = v:FindFirstChild("HumanoidRootPart")
        if hrp then
            local name = string.lower(v.Name)
            local shouldExpand = false
            
            if settings.hitboxes.wolves and (name:find("wolf") or name:find("alpha")) then
                shouldExpand = true
            elseif settings.hitboxes.rabbits and name:find("bunny") then
                shouldExpand = true  
            elseif settings.hitboxes.cultists and name:find("cultist") then
                shouldExpand = true
            end
            
            if shouldExpand then
                hrp.Size = Vector3.new(settings.hitboxes.size, settings.hitboxes.size, settings.hitboxes.size)
                hrp.Transparency = settings.hitboxes.visible and 0.7 or 1
                hrp.CanCollide = false
                hrp.Color = Color3.new(1, 0, 0)
                hrp.Material = Enum.Material.ForceField
            end
        end
    end
end

-- create the gui
local Window = Obsidian:CreateWindow({
    Name = "99 Nights Helper",
    Size = UDim2.fromOffset(550, 400),
    Anchor = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 0.2,
    Theme = "Dark"
})

-- create tabs
local MainTab = Window:CreateTab("Main")
local PlayerTab = Window:CreateTab("Player")  
local FarmTab = Window:CreateTab("Farm")
local ItemTab = Window:CreateTab("Items")
local EspTab = Window:CreateTab("ESP")
local HitboxTab = Window:CreateTab("Hitbox")
local MiscTab = Window:CreateTab("Misc")

-- main tab
MainTab:CreateToggle({
    Name = "Auto Feed",
    CurrentValue = false,
    Flag = "AutoFeed",
    Callback = function(Value)
        settings.autoHunger = Value
        if Value then
            spawn(function()
                local remote = rs.RemoteEvents:FindFirstChild("RequestConsumeItem")
                while settings.autoHunger and remote do
                    pcall(function()
                        remote:InvokeServer(Instance.new("Model"))
                    end)
                    wait(1.5)
                end
            end)
        end
    end,
})

MainTab:CreateButton({
    Name = "Cook All Meat",
    Callback = function()
        local campfire = Vector3.new(1.87, 4.33, -3.67)
        for i,v in pairs(workspace.Items:GetChildren()) do
            if string.find(string.lower(v.Name), "meat") then
                local part = v:FindFirstChildOfClass("BasePart")
                if part then
                    part.CFrame = CFrame.new(campfire + Vector3.new(math.random(-1,1), 1, math.random(-1,1)))
                end
            end
        end
        notify("Cooking", "moved meat to campfire")
    end,
})

-- player tab  
PlayerTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(Value)
        if plr.Character and plr.Character:FindFirstChild("Humanoid") then
            plr.Character.Humanoid.WalkSpeed = Value
        end
    end,
})

PlayerTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 300},
    Increment = 1,
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(Value)
        if plr.Character and plr.Character:FindFirstChild("Humanoid") then
            plr.Character.Humanoid.JumpPower = Value
        end
    end,
})

PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(Value)
        settings.noclipActive = Value
        if Value then
            spawn(function()
                while settings.noclipActive do
                    if plr.Character then
                        for i,v in pairs(plr.Character:GetDescendants()) do
                            if v:IsA("BasePart") then
                                v.CanCollide = false
                            end
                        end
                    end
                    runService.Heartbeat:Wait()
                end
            end)
        end
    end,
})

PlayerTab:CreateToggle({
    Name = "God Mode",
    CurrentValue = false,
    Flag = "GodMode",
    Callback = function(Value)
        if plr.Character and plr.Character:FindFirstChild("Humanoid") then
            if Value then
                plr.Character.Humanoid.MaxHealth = math.huge
                plr.Character.Humanoid.Health = math.huge
            else
                plr.Character.Humanoid.MaxHealth = 100
                plr.Character.Humanoid.Health = 100
            end
        end
    end,
})

-- farm tab
FarmTab:CreateToggle({
    Name = "Auto Tree Farm",
    CurrentValue = false,
    Flag = "AutoTreeFarm",
    Callback = function(Value)
        settings.autoFarm = Value
        if Value then
            spawn(function()
                local toolDamage = rs.RemoteEvents:FindFirstChild("ToolDamageObject")
                while settings.autoFarm do
                    local trees = {}
                    
                    -- find trees
                    if workspace:FindFirstChild("Map") then
                        local landmarks = workspace.Map:FindFirstChild("Landmarks") or workspace.Map:FindFirstChild("Foliage")
                        if landmarks then
                            for i,v in pairs(landmarks:GetChildren()) do
                                if v.Name == "Small Tree" and v:FindFirstChild("Trunk") then
                                    table.insert(trees, v)
                                end
                            end
                        end
                    end
                    
                    -- farm trees
                    for i,tree in pairs(trees) do
                        if not settings.autoFarm then break end
                        if tree and tree.Parent then
                            local myChar = plr.Character
                            local root = myChar and myChar:FindFirstChild("HumanoidRootPart")
                            if root and tree:FindFirstChild("Trunk") then
                                root.CFrame = tree.Trunk.CFrame * CFrame.new(3, 0, 0)
                                wait(0.3)
                                
                                -- get axe
                                local axe = nil
                                if plr:FindFirstChild("Inventory") then
                                    axe = plr.Inventory:FindFirstChild("Old Axe") or plr.Inventory:FindFirstChild("Good Axe")
                                end
                                
                                if axe then
                                    if axe.Parent == plr.Backpack then
                                        axe.Parent = myChar
                                        wait(0.2)
                                    end
                                    
                                    while tree.Parent and settings.autoFarm do
                                        pcall(function()
                                            axe:Activate()
                                            if toolDamage then
                                                toolDamage:InvokeServer(tree, axe, "1_8264699301", tree.Trunk.CFrame)
                                            end
                                        end)
                                        wait(0.8)
                                    end
                                end
                            end
                        end
                        wait(0.5)
                    end
                    wait(2)
                end
            end)
        end
    end,
})

FarmTab:CreateToggle({
    Name = "Auto Break (look at tree)",
    CurrentValue = false,
    Flag = "AutoBreak",
    Callback = function(Value)
        settings.autoBreak = Value
        if Value then
            spawn(function()
                while settings.autoBreak do
                    local weapon = nil
                    if plr:FindFirstChild("Inventory") then
                        weapon = plr.Inventory:FindFirstChild("Old Axe") or 
                                plr.Inventory:FindFirstChild("Good Axe") or
                                plr.Inventory:FindFirstChild("Strong Axe")
                    end
                    
                    if weapon then
                        local ray = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 20)
                        if ray and ray.Instance and ray.Instance.Name == "Trunk" then
                            pcall(function()
                                rs.RemoteEvents.ToolDamageObject:InvokeServer(
                                    ray.Instance.Parent, weapon, "4_7591937906", CFrame.new(ray.Position)
                                )
                            end)
                        end
                    end
                    wait(0.5)
                end
            end)
        end
    end,
})

-- item tab
local itemList = {
    "Log", "Stone", "Rope", "Nails", "Scrap", "Wood", "Cloth", "Bandage", "Meat",
    "Spear", "Knife", "Revolver", "Rifle", "Ammo", "Coal", "Oil", "Radio"
}

for i,item in pairs(itemList) do
    ItemTab:CreateButton({
        Name = "Get " .. item,
        Callback = function()
            bringItems(item)
            notify("Items", "brought " .. item)
        end,
    })
end

ItemTab:CreateButton({
    Name = "Bring Everything", 
    Callback = function()
        local root = getPlayer()
        if root then
            for i,v in pairs(workspace.Items:GetChildren()) do
                local part = v:FindFirstChildOfClass("BasePart")
                if part then
                    part.CFrame = root.CFrame * CFrame.new(math.random(-8,8), 0, math.random(-8,8))
                end
            end
            notify("Items", "brought all items")
        end
    end,
})

-- esp tab
EspTab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Flag = "PlayerESP",
    Callback = function(Value)
        settings.playerEsp = Value
        if Value then
            spawn(function()
                while settings.playerEsp do
                    for i,player in pairs(game.Players:GetPlayers()) do
                        if player ~= plr and player.Character then
                            if not player.Character:FindFirstChild("Highlight") then
                                makeEsp(player.Character, Color3.new(0, 1, 0), player.Name)
                            end
                        end
                    end
                    wait(1)
                end
                
                -- cleanup
                for i,player in pairs(game.Players:GetPlayers()) do
                    if player.Character then
                        removeEsp(player.Character)
                    end
                end
            end)
        end
    end,
})

EspTab:CreateToggle({
    Name = "Item ESP",
    CurrentValue = false,
    Flag = "ItemESP",
    Callback = function(Value)
        settings.itemEsp = Value
        if Value then
            spawn(function()
                while settings.itemEsp do
                    for i,item in pairs(workspace.Items:GetChildren()) do
                        if item:IsA("Model") and not item:FindFirstChild("Highlight") then
                            makeEsp(item, Color3.new(1, 1, 0), item.Name)
                        end
                    end
                    wait(2)
                end
                
                -- cleanup
                for i,item in pairs(workspace.Items:GetChildren()) do
                    removeEsp(item)
                end
            end)
        end
    end,
})

-- hitbox tab
HitboxTab:CreateToggle({
    Name = "Wolf Hitbox",
    CurrentValue = false,
    Flag = "WolfHitbox",
    Callback = function(Value)
        settings.hitboxes.wolves = Value
    end,
})

HitboxTab:CreateToggle({
    Name = "Rabbit Hitbox", 
    CurrentValue = false,
    Flag = "RabbitHitbox",
    Callback = function(Value)
        settings.hitboxes.rabbits = Value
    end,
})

HitboxTab:CreateToggle({
    Name = "Cultist Hitbox",
    CurrentValue = false,
    Flag = "CultistHitbox",
    Callback = function(Value)
        settings.hitboxes.cultists = Value
    end,
})

HitboxTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {5, 50},
    Increment = 1,
    CurrentValue = 15,
    Flag = "HitboxSize",
    Callback = function(Value)
        settings.hitboxes.size = Value
    end,
})

HitboxTab:CreateToggle({
    Name = "Show Hitboxes",
    CurrentValue = false,
    Flag = "ShowHitboxes",
    Callback = function(Value)
        settings.hitboxes.visible = Value
    end,
})

-- misc tab
MiscTab:CreateToggle({
    Name = "Fast Interact",
    CurrentValue = false,
    Flag = "FastInteract",
    Callback = function(Value)
        for i,v in pairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                v.HoldDuration = Value and 0 or 0.5
            end
        end
    end,
})

MiscTab:CreateButton({
    Name = "Kill Rabbits",
    Callback = function()
        for i,v in pairs(workspace.Characters:GetChildren()) do
            if v.Name == "Bunny" and v:FindFirstChild("Humanoid") then
                v.Humanoid.Health = 0
            end
        end
        notify("Combat", "killed all rabbits")
    end,
})

MiscTab:CreateButton({
    Name = "Kill Wolves", 
    Callback = function()
        for i,v in pairs(workspace.Characters:GetChildren()) do
            if v.Name == "Wolf" and v:FindFirstChild("Humanoid") then
                v.Humanoid.Health = 0
            end
        end
        notify("Combat", "killed all wolves")
    end,
})

MiscTab:CreateButton({
    Name = "Teleport to Camp",
    Callback = function()
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            plr.Character.HumanoidRootPart.CFrame = CFrame.new(13.287, 3.999, 0.362)
        end
    end,
})

-- background stuff
spawn(function()
    while true do
        updateHitboxes()
        wait(1)
    end
end)

-- done
notify("Script", "loaded successfully")
print("script loaded - have fun!")
