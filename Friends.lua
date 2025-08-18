--[[
claude generated script cuz why not
--]]

wait(2)
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()

local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()

local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options

local Toggles = Library.Toggles

Library.ForceCheckbox = false

Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({

    Title = "mspaint",

    Footer = "version: 1.0",

    Icon = 95816097006870,

    NotifySide = "Right",

    ShowCustomCursor = true,

})
local plr = game.Players.LocalPlayer

local char = plr.Character or plr.CharacterAdded:Wait()

local cam = workspace.CurrentCamera

local runService = game:GetService("RunService")

local uis = game:GetService("UserInputService")

local rs = game:GetService("ReplicatedStorage")

local tweenService = game:GetService("TweenService")
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

-- Helper functions

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

    label.Size = UDim2.new(1,0,1,0)

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

                hrp.Color = Color3.new(1,0,0)

                hrp.Material = Enum.Material.ForceField

            end

        end

    end

end

-- Tabs

local mainTab = Window:AddTab("Main")

local playerTab = Window:AddTab("Player")

local farmTab = Window:AddTab("Farm")

local itemTab = Window:AddTab("Items")

local espTab = Window:AddTab("ESP")

local hitboxTab = Window:AddTab("Hitbox")

local miscTab = Window:AddTab("Misc")

-- Main tab

mainTab:AddToggle({

    Title = "Auto Feed",

    Default = false,

    Callback = function(state)

        settings.autoHunger = state

        if state then

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

    end

})

mainTab:AddButton({

    Title = "Cook All Meat",

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

        notify("Cooking", "Moved meat to campfire")

    end

})
playerTab:AddSlider({

    Title = "Speed",

    Min = 16,

    Max = 200,

    Default = 16,

    Callback = function(val)

        if plr.Character and plr.Character:FindFirstChild("Humanoid") then

            plr.Character.Humanoid.WalkSpeed = val

        end

    end

})

playerTab:AddSlider({

    Title = "Jump",

    Min = 50,

    Max = 300,

    Default = 50,

    Callback = function(val)

        if plr.Character and plr.Character:FindFirstChild("Humanoid") then

            plr.Character.Humanoid.JumpPower = val

        end

    end

})

playerTab:AddToggle({

    Title = "Noclip",

    Default = false,

    Callback = function(state)

        settings.noclipActive = state

        if state then

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

    end

})

playerTab:AddToggle({

    Title = "God Mode",

    Default = false,

    Callback = function(state)

        if plr.Character and plr.Character:FindFirstChild("Humanoid") then

            if state then

                plr.Character.Humanoid.MaxHealth = math.huge

                plr.Character.Humanoid.Health = math.huge

            else

                plr.Character.Humanoid.MaxHealth = 100

                plr.Character.Humanoid.Health = 100

            end

        end

    end

})

-- Farm tab

farmTab:AddToggle({

    Title = "Auto Tree Farm",

    Default = false,

    Callback = function(state)

        settings.autoFarm = state

        if state then

            spawn(function()

                local toolDamage = rs.RemoteEvents:FindFirstChild("ToolDamageObject")

                while settings.autoFarm do

                    local trees = {}

                    if workspace:FindFirstChild("Map") then

                        local landmarks = workspace.Map:FindFirstChild("Landmarks") or workspace.Map:FindFirstChild("Foliage")

                        if landmarks then

                            for i,v in pairs(landmarks:GetChildren()) do

                                if v.Name == "Small Tree" and v:FindFirstChild("Trunk") then

                                    table.insert(trees,v)

                                end

                            end

                        end

                    end

                    for i,tree in pairs(trees) do

                        if not settings.autoFarm then break end

                        if tree and tree.Parent then

                            local myChar = plr.Character

                            local root = myChar and myChar:FindFirstChild("HumanoidRootPart")

                            if root and tree:FindFirstChild("Trunk") then

                                root.CFrame = tree.Trunk.CFrame * CFrame.new(3,0,0)

                                wait(0.3)

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

    end

})

farmTab:AddToggle({

    Title = "Auto Break (look at tree)",

    Default = false,

    Callback = function(state)

        settings.autoBreak = state

        if state then

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

    end

})

-- Items tab

local itemList = {

    "Log", "Stone", "Rope", "Nails", "Scrap", "Wood", "Cloth", "Bandage", "Meat",

    "Spear", "Knife", "Revolver", "Rifle", "Ammo", "Coal", "Oil", "Radio"

}

for i,item in pairs(itemList) do

    itemTab:AddButton({

        Title = "Get " .. item,

        Callback = function()

            bringItems(item)

            notify("Items", "Brought " .. item)

        end

    })

end

itemTab:AddButton({

    Title = "Bring Everything",

    Callback = function()

        local root = getPlayer()

        if root then

            for i,v in pairs(workspace.Items:GetChildren()) do

                local part = v:FindFirstChildOfClass("BasePart")

                if part then

                    part.CFrame = root.CFrame * CFrame.new(math.random(-8,8), 0, math.random(-8,8))

                end

            end

            notify("Items", "Brought all items")

        end

    end

})

-- ESP tab

espTab:AddToggle({

    Title = "Player ESP",

    Default = false,

    Callback = function(state)

        settings.playerEsp = state

        if state then

            spawn(function()

                while settings.playerEsp do

                    for i,player in pairs(game.Players:GetPlayers()) do

                        if player ~= plr and player.Character then

                            if not player.Character:FindFirstChild("Highlight") then

                                makeEsp(player.Character, Color3.new(0,1,0), player.Name)

                            end

                        end

                    end

                    wait(1)

                end

                for i,player in pairs(game.Players:GetPlayers()) do

                    if player.Character then

                        removeEsp(player.Character)

                    end

                end

            end)

        end

    end

})

espTab:AddToggle({

    Title = "Item ESP",

    Default = false,

    Callback = function(state)

        settings.itemEsp = state

        if state then

            spawn(function()

                while settings.itemEsp do

                    for i,item in pairs(workspace.Items:GetChildren()) do

                        if item:IsA("Model") and not item:FindFirstChild("Highlight") then

                            makeEsp(item, Color3.new(1,1,0), item.Name)

                        end

                    end

                    wait(2)

                end

                for i,item in pairs(workspace.Items:GetChildren()) do

                    removeEsp(item)

                end

            end)

        end

    end

})

-- Hitbox tab

hitboxTab:AddToggle({

    Title = "Wolf Hitbox",

    Default = false,

    Callback = function(state)

        settings.hitboxes.wolves = state

    end

})

hitboxTab:AddToggle({

    Title = "Rabbit Hitbox",

    Default = false,

    Callback = function(state)

        settings.hitboxes.rabbits = state

    end

})

hitboxTab:AddToggle({

    Title = "Cultist Hitbox",

    Default = false,

    Callback = function(state)

        settings.hitboxes.cultists = state

    end

})

hitboxTab:AddSlider({

    Title = "Hitbox Size",

    Min = 5,

    Max = 50,

    Default = 15,

    Callback = function(val)

        settings.hitboxes.size = val

    end

})

hitboxTab:AddToggle({

    Title = "Show Hitboxes",

    Default = false,

    Callback = function(state)

        settings.hitboxes.visible = state

    end

})

-- Misc tab

miscTab:AddToggle({

    Title = "Fast Interact",

    Default = false,

    Callback = function(state)

        for i,v in pairs(workspace:GetDescendants()) do

            if v:IsA("ProximityPrompt") then

                v.HoldDuration = state and 0 or 0.5

            end

        end

    end

})

miscTab:AddButton({

    Title = "Kill Rabbits",

    Callback = function()

        for i,v in pairs(workspace.Characters:GetChildren()) do

            if v.Name == "Bunny" and v:FindFirstChild("Humanoid") then

                v.Humanoid.Health = 0

            end

        end

        notify("Combat", "Killed all rabbits")

    end

})

miscTab:AddButton({

    Title = "Kill Wolves",

    Callback = function()

        for i,v in pairs(workspace.Characters:GetChildren()) do

            if v.Name == "Wolf" and v:FindFirstChild("Humanoid") then

                v.Humanoid.Health = 0

            end

        end

        notify("Combat", "Killed all wolves")

    end

})

miscTab:AddButton({

    Title = "Teleport to Camp",

    Callback = function()

        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then

            plr.Character.HumanoidRootPart.CFrame = CFrame.new(13.287, 3.999, 0.362)

        end

    end

})

-- Background updates

spawn(function()

    while true do

        updateHitboxes()

        wait(1)

    end

end)

notify("Script", "Loaded successfully")

print("Script loaded - have fun!")

-- done
notify("Script", "loaded successfully")
print("script loaded - have fun!")
