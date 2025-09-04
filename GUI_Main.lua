-- 🔥 Full Final Script by Long Dzz 🔥
-- GUI Rayfield màu mè + Full chức năng + Hiệu ứng + Nút Toggle + Info Tab cố định

------------------------------------------------
-- Load Rayfield
------------------------------------------------
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "⚡ Blox Fruits GUI ⚡",
    LoadingTitle = "Script by Long Dzz",
    LoadingSubtitle = "VIP Interface",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "BloxFruits",
        FileName = "Config"
    },
    Discord = {
        Enabled = true,
        Invite = "yourdiscordinvite", -- 👈 thay link server của bạn
        RememberJoins = true
    },
    KeySystem = false
})

------------------------------------------------
-- Services
------------------------------------------------
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Modules (từ GitHub raw)
local Controller = loadstring(game:HttpGet("https://raw.githubusercontent.com/Longnononn/game/main/Module.luau"))()
local Quests = loadstring(game:HttpGet("https://raw.githubusercontent.com/Longnononn/game/main/Quests.lua"))()
local Guide = loadstring(game:HttpGet("https://raw.githubusercontent.com/Longnononn/game/main/GuideModule.lua"))()
local Webhooks = loadstring(game:HttpGet("https://raw.githubusercontent.com/Longnononn/game/main/Webhooks.lua"))()

-- Load Codes.json (nếu có)
local codesData = {}
pcall(function()
    if isfile("BloxFruits/Codes.json") then
        codesData = HttpService:JSONDecode(readfile("BloxFruits/Codes.json"))
    end
end)

------------------------------------------------
-- 🌟 Tab Info (Thông tin)
------------------------------------------------
local InfoTab = Window:CreateTab("🌟 Info", nil)

local rainbowColors = {
    Color3.fromRGB(255,0,0),Color3.fromRGB(255,128,0),
    Color3.fromRGB(255,255,0),Color3.fromRGB(0,255,0),
    Color3.fromRGB(0,255,255),Color3.fromRGB(0,128,255),
    Color3.fromRGB(128,0,255),Color3.fromRGB(255,0,255)
}

local function RainbowLabel(text)
    local label = InfoTab:CreateLabel(text)
    local i = 1
    task.spawn(function()
        while task.wait(0.2) do
            i = (i % #rainbowColors) + 1
            pcall(function() label:SetText(text, rainbowColors[i]) end)
        end
    end)
end

RainbowLabel("✨ Script by Long Dzz ✨")
InfoTab:CreateLabel("👤 User: " .. LocalPlayer.Name)
InfoTab:CreateLabel("⚔️ Level: " .. (Controller and Controller.GameData.MaxLevel or "Unknown"))
InfoTab:CreateLabel("🌊 Sea: " .. (Controller and Controller.GameData.SeasName[Controller.GameData.Sea] or "Unknown"))
InfoTab:CreateLabel("🛠️ Executor: " .. (identifyexecutor and identifyexecutor() or "Unknown"))

-- Thông tin cá nhân cố định
InfoTab:CreateLabel("📱 TikTok: @longdzz")
InfoTab:CreateLabel("📘 Facebook: fb.com/longdzz")
InfoTab:CreateLabel("📞 Zalo: 0123456789")

-- Discord
local DiscordInvite = "https://discord.gg/yourinvite"
InfoTab:CreateLabel("🌐 Discord: " .. DiscordInvite)
InfoTab:CreateButton({
    Name = "📋 Copy Discord",
    Callback = function()
        setclipboard(DiscordInvite)
        Rayfield:Notify({
            Title = "✅ Copied!",
            Content = "Discord link đã copy vào clipboard.",
            Duration = 4
        })
    end
})

------------------------------------------------
-- ✨ Hiệu ứng nền Blur + Particles
------------------------------------------------
local Blur = Instance.new("BlurEffect")
Blur.Size = 0
Blur.Parent = Lighting

local ParticlePart = Instance.new("Part")
ParticlePart.Anchored = true
ParticlePart.CanCollide = false
ParticlePart.Transparency = 1
ParticlePart.Size = Vector3.new(1,1,1)
ParticlePart.Position = LocalPlayer.Character and LocalPlayer.Character:WaitForChild("HumanoidRootPart").Position or Vector3.new(0,0,0)
ParticlePart.Parent = workspace

local ParticleEmitter = Instance.new("ParticleEmitter")
ParticleEmitter.Texture = "rbxassetid://241594419" -- sparkle
ParticleEmitter.Rate = 0
ParticleEmitter.Lifetime = NumberRange.new(1,2)
ParticleEmitter.Speed = NumberRange.new(0.5,1)
ParticleEmitter.Size = NumberSequence.new(0.2,0.5)
ParticleEmitter.Parent = ParticlePart

local function ToggleBlur(enable)
    TweenService:Create(Blur, TweenInfo.new(0.5), {Size = enable and 20 or 0}):Play()
    ParticleEmitter.Rate = enable and 10 or 0
end

------------------------------------------------
-- 🔘 Nút tròn bật/tắt GUI
------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.CoreGui

local ToggleButton = Instance.new("ImageButton")
ToggleButton.Size = UDim2.new(0,50,0,50)
ToggleButton.Position = UDim2.new(0.05,0,0.2,0)
ToggleButton.Image = "rbxassetid://3926305904"
ToggleButton.ImageRectOffset = Vector2.new(4, 836)
ToggleButton.ImageRectSize = Vector2.new(48, 48)
ToggleButton.BackgroundTransparency = 1
ToggleButton.Parent = ScreenGui

local dragging, dragInput, dragStart, startPos
ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = ToggleButton.Position
    end
end)
ToggleButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        ToggleButton.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

------------------------------------------------
-- 🔊 Âm thanh hiệu ứng mở/tắt GUI
------------------------------------------------
local OpenSound = Instance.new("Sound")
OpenSound.SoundId = "rbxassetid://1843525456" -- whoosh
OpenSound.Volume = 1
OpenSound.Parent = SoundService

local CloseSound = Instance.new("Sound")
CloseSound.SoundId = "rbxassetid://12222058" -- click
CloseSound.Volume = 1
CloseSound.Parent = SoundService

-- Toggle GUI
local isVisible = true
ToggleButton.MouseButton1Click:Connect(function()
    isVisible = not isVisible
    game:GetService("CoreGui").Rayfield.Enabled = isVisible
    ToggleBlur(isVisible)
    if isVisible then
        OpenSound:Play()
    else
        CloseSound:Play()
    end
end)

------------------------------------------------
-- 📌 Farm Options
------------------------------------------------
local FarmOptions = {}

------------------------------------------------
-- ⚔️ Farm Tab
------------------------------------------------
local FarmTab = Window:CreateTab("Farm", nil)
FarmTab:CreateToggle({
    Name = "Auto Farm Level",
    CurrentValue = false,
    Flag = "AutoFarmLevel",
    Callback = function(Value)
        FarmOptions.AutoFarmLevel = {
            Name = "AutoFarmLevel",
            Function = function()
                if Value then
                    local questKey = nil
                    for qKey, qData in pairs(Quests) do
                        if qData[1].LevelReq <= Controller.GameData.MaxLevel then
                            questKey = qKey
                            break
                        end
                    end
                    if questKey and Controller.IsAlive(LocalPlayer.Character) then
                        Controller.Services.Network.InvokeCommF("TakeQuest", questKey)
                        local enemy = Controller.Services.Enemies:GetClosestByTag(Quests[questKey][1].Task[1].Name)
                        if enemy then
                            Controller.TweenBodyVelocity.Velocity = (enemy.PrimaryPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Unit * 50
                            return true
                        end
                    end
                end
                return false
            end
        }
        Controller.OnFarm = Value
    end
})
FarmTab:CreateToggle({
    Name = "Auto Farm Chest",
    CurrentValue = false,
    Flag = "AutoChest",
    Callback = function(Value)
        FarmOptions.AutoChest = {
            Name = "AutoChest",
            Function = function()
                if Value then
                    local chest = Controller.GetClosestChest()
                    if chest and Controller.IsAlive(LocalPlayer.Character) then
                        Controller.TweenBodyVelocity.Velocity = (chest:GetPivot().Position - LocalPlayer.Character.HumanoidRootPart.Position).Unit * 50
                        return true
                    end
                end
                return false
            end
        }
        Controller.OnFarm = Value
    end
})
FarmTab:CreateToggle({
    Name = "Auto Farm Berry",
    CurrentValue = false,
    Flag = "AutoBerry",
    Callback = function(Value)
        FarmOptions.AutoBerry = {
            Name = "AutoBerry",
            Function = function()
                if Value then
                    local berry = Controller.GetClosestBerry()
                    if berry and Controller.IsAlive(LocalPlayer.Character) then
                        Controller.TweenBodyVelocity.Velocity = (berry.Parent:GetPivot().Position - LocalPlayer.Character.HumanoidRootPart.Position).Unit * 50
                        return true
                    end
                end
                return false
            end
        }
        Controller.OnFarm = Value
    end
})
FarmTab:CreateToggle({
    Name = "Auto Haki",
    CurrentValue = false,
    Flag = "AutoHaki",
    Callback = function(Value)
        FarmOptions.AutoHaki = {
            Name = "AutoHaki",
            Function = function()
                if Value then
                    pcall(function()
                        Controller.Services.ToolService.EnableBuso()
                    end)
                    return true
                end
                return false
            end
        }
    end
})
FarmTab:CreateToggle({
    Name = "No Clip",
    CurrentValue = false,
    Flag = "NoClip",
    Callback = function(Value)
        Controller.OnFarm = Value
        if Value then
            Controller.DisableCanTouch()
        end
    end
})

------------------------------------------------
-- 📜 Quest Tab
------------------------------------------------
local QuestTab = Window:CreateTab("Quest", nil)
local questNames = {}
for questKey, questData in pairs(Quests) do
    table.insert(questNames, questKey .. " (Lv." .. questData[1].LevelReq .. ")")
end
QuestTab:CreateDropdown({
    Name = "Chọn Quest",
    Options = questNames,
    CurrentOption = {questNames[1] or ""},
    Flag = "QuestSelect",
    Callback = function(opt)
        local questKey = opt[1]:match("^(%w+)")
        pcall(function()
            Controller.Services.Network.InvokeCommF("TakeQuest", questKey)
        end)
    end
})
QuestTab:CreateButton({
    Name = "Teleport tới NPC",
    Callback = function()
        local questKey = questNames[1]:match("^(%w+)") or ""
        local npc = Guide.Data.NPCs[questKey]
        if npc and Controller.IsAlive(LocalPlayer.Character) then
            local npcPos = workspace.NPCs:FindFirstChild(npc)
            if npcPos then
                Controller.TweenBodyVelocity.Velocity = (npcPos:GetPivot().Position - LocalPlayer.Character.HumanoidRootPart.Position).Unit * 50
                task.wait(2)
                Controller.TweenBodyVelocity.Velocity = Vector3.zero
            end
        end
    end
})

------------------------------------------------
-- 👑 Bosses Tab
------------------------------------------------
local BossesTab = Window:CreateTab("Bosses", nil)
local bossNames = {"rip_indra True Form", "Blank Buddy", "Deandre", "Diablo", "Urban"}
BossesTab:CreateDropdown({
    Name = "Chọn Boss",
    Options = bossNames,
    CurrentOption = {bossNames[1] or ""},
    Flag = "BossSelect",
    Callback = function(opt)
        local boss = Controller.Services.Enemies:GetEnemyByTag(opt[1])
        if boss and Controller.IsAlive(LocalPlayer.Character) then
            Controller.TweenBodyVelocity.Velocity = (boss.PrimaryPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Unit * 50
            task.wait(2)
            Controller.TweenBodyVelocity.Velocity = Vector3.zero
        end
    end
})
BossesTab:CreateToggle({
    Name = "Auto Kill Boss",
    CurrentValue = false,
    Flag = "AutoKillBoss",
    Callback = function(Value)
        FarmOptions.AutoKillBoss = {
            Name = "AutoKillBoss",
            Function = function()
                if Value then
                    local boss = Controller.Services.Enemies:GetEnemyByTag(bossNames[1])
                    if boss and Controller.IsAlive(LocalPlayer.Character) then
                        Controller.TweenBodyVelocity.Velocity = (boss.PrimaryPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Unit * 50
                        return true
                    end
                end
                return false
            end
        }
        Controller.OnFarm = Value
    end
})

------------------------------------------------
-- 🍎 Fruit/Raid Tab
------------------------------------------------
local FruitRaidTab = Window:CreateTab("Fruit/Raid", nil)
FruitRaidTab:CreateToggle({
    Name = "Auto Store Fruits",
    CurrentValue = false,
    Flag = "AutoStoreFruits",
    Callback = function(Value)
        FarmOptions.AutoStoreFruits = {
            Name = "AutoStoreFruits",
            Function = function()
                if Value then
                    pcall(function()
                        Controller.Services.Network.InvokeCommF("StoreFruit")
                    end)
                    return true
                end
                return false
            end
        }
    end
})
FruitRaidTab:CreateToggle({
    Name = "Auto Buy Chip",
    CurrentValue = false,
    Flag = "AutoBuyChip",
    Callback = function(Value)
        FarmOptions.AutoBuyChip = {
            Name = "AutoBuyChip",
            Function = function()
                if Value then
                    pcall(function()
                        Controller.Services.Network.InvokeCommF("BuyChip")
                    end)
                    return true
                end
                return false
            end
        }
    end
})

------------------------------------------------
-- 👁️ ESP Tab
------------------------------------------------
local ESPTab = Window:CreateTab("ESP", nil)
ESPTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(Value)
        if Value then
            for _, enemy in pairs(Controller.Services.Enemies:GetTagged("BasicMob")) do
                pcall(function()
                    Controller.HookManager.HookProperty(enemy, "Transparency", 0.5)
                end)
            end
        else
            for _, enemy in pairs(Controller.Services.Enemies:GetTagged("BasicMob")) do
                pcall(function()
                    Controller.HookManager.UnhookProperty(enemy, "Transparency")
                end)
            end
        end
    end
})

------------------------------------------------
-- 🗺️ Teleport Tab
------------------------------------------------
local TeleportTab = Window:CreateTab("Teleport", nil)
local islandNames = {}
for _, island in pairs(workspace._WorldOrigin.Locations:GetChildren()) do
    table.insert(islandNames, island.Name)
end
TeleportTab:CreateDropdown({
    Name = "Chọn Island",
    Options = islandNames,
    CurrentOption = {islandNames[1] or ""},
    Flag = "IslandSelect",
    Callback = function(opt)
        local island = workspace._WorldOrigin.Locations:FindFirstChild(opt[1])
        if island and Controller.IsAlive(LocalPlayer.Character) then
            Controller.TweenBodyVelocity.Velocity = (island:GetPivot().Position - LocalPlayer.Character.HumanoidRootPart.Position).Unit * 50
            task.wait(2)
            Controller.TweenBodyVelocity.Velocity = Vector3.zero
        end
    end
})

------------------------------------------------
-- 🌊 Sea Tab
------------------------------------------------
local SeaTab = Window:CreateTab("Sea", nil)
SeaTab:CreateToggle({
    Name = "Auto Sea Beast",
    CurrentValue = false,
    Flag = "AutoSeaBeast",
    Callback = function(Value)
        FarmOptions.AutoSeaBeast = {
            Name = "AutoSeaBeast",
            Function = function()
                if Value then
                    for _, seaBeast in pairs(workspace.SeaBeasts:GetChildren()) do
                        if Controller.IsAlive(LocalPlayer.Character) and Controller.IsAlive(seaBeast) then
                            Controller.TweenBodyVelocity.Velocity = (seaBeast:GetPivot().Position - LocalPlayer.Character.HumanoidRootPart.Position).Unit * 50
                            return true
                        end
                    end
                end
                return false
            end
        }
        Controller.OnFarm = Value
    end
})

------------------------------------------------
-- 🛒 Shop Tab
------------------------------------------------
local ShopTab = Window:CreateTab("Shop", nil)
ShopTab:CreateButton({
    Name = "Buy Buso Haki",
    Callback = function()
        pcall(function()
            Controller.Services.ToolService.EnableBuso()
        end)
    end
})
ShopTab:CreateButton({
    Name = "Buy Fighting Style",
    Callback = function()
        pcall(function()
            Controller.Services.Network.InvokeCommF("BuyFightingStyle")
        end)
    end
})

------------------------------------------------
-- 🏴 Team Tab
------------------------------------------------
local TeamTab = Window:CreateTab("Team", nil)
TeamTab:CreateButton({
    Name = "Join Pirates",
    Callback = function()
        pcall(function()
            Controller.Services.Network.InvokeCommF("JoinTeam", "Pirates")
        end)
    end
})
TeamTab:CreateButton({
    Name = "Join Marines",
    Callback = function()
        pcall(function()
            Controller.Services.Network.InvokeCommF("JoinTeam", "Marines")
        end)
    end
})

------------------------------------------------
-- 🎁 Codes Tab
------------------------------------------------
local CodesTab = Window:CreateTab("Codes", nil)
CodesTab:CreateButton({
    Name = "Redeem All Codes",
    Callback = function()
        for _, code in ipairs(codesData) do
            pcall(function()
                Controller.Services.Network.InvokeCommF("RedeemCode", code)
            end)
        end
        Rayfield:Notify({
            Title = "✅ Codes",
            Content = "Đã thử redeem toàn bộ code!",
            Duration = 4
        })
    end
})

------------------------------------------------
-- ⚙️ Config Tab
------------------------------------------------
local ConfigTab = Window:CreateTab("Config", nil)
ConfigTab:CreateButton({
    Name = "Save Config",
    Callback = function()
        pcall(function()
            writefile("BloxFruits/Config.json", HttpService:JSONEncode(Rayfield:GetCurrentConfig()))
            Rayfield:Notify({
                Title = "💾 Config",
                Content = "Đã lưu cấu hình.",
                Duration = 3
            })
        end)
    end
})
ConfigTab:CreateButton({
    Name = "Load Config",
    Callback = function()
        pcall(function()
            local config = HttpService:JSONDecode(readfile("BloxFruits/Config.json"))
            Rayfield:LoadConfiguration(config)
            Rayfield:Notify({
                Title = "📂 Config",
                Content = "Đã load cấu hình.",
                Duration = 3
            })
        end)
    end
})

------------------------------------------------
-- 🔧 Misc Tab
------------------------------------------------
local MiscTab = Window:CreateTab("Misc", nil)
MiscTab:CreateToggle({
    Name = "Enable Webhook",
    CurrentValue = false,
    Flag = "Webhook",
    Callback = function(Value)
        if Value then
            Webhooks.Enable()
            Rayfield:Notify({Title="🌐 Webhook", Content="Đã bật webhook", Duration=3})
        else
            Webhooks.Disable()
            Rayfield:Notify({Title="🌐 Webhook", Content="Đã tắt webhook", Duration=3})
        end
    end
})
MiscTab:CreateToggle({
    Name = "Walkspeed Bypass",
    CurrentValue = false,
    Flag = "WalkspeedBypass",
    Callback = function(Value)
        pcall(function()
            Controller.HookManager.HookProperty(LocalPlayer.Character.Humanoid, "WalkSpeed", Value and 100 or 16)
        end)
    end
})

------------------------------------------------
-- 🚀 Run FarmQueue
------------------------------------------------
Controller.RunModules.FarmQueue(FarmOptions)

Rayfield:Notify({
    Title = "🎉 Script Loaded!",
    Content = "Full GUI đã sẵn sàng 🚀",
    Duration = 6
})
