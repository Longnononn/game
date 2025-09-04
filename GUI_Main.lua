-- 🔥 Final Script by Long Dzz 🔥
-- GUI Rayfield màu mè + Info + Blur + Particles + ToggleButton + Sound

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

-- Modules (từ GitHub raw)
local Controller = loadstring(game:HttpGet("https://raw.githubusercontent.com/Longnononn/game/main/Module.luau"))()
local Quests = loadstring(game:HttpGet("https://raw.githubusercontent.com/Longnononn/game/main/Quests.lua"))()
local Guide = loadstring(game:HttpGet("https://raw.githubusercontent.com/Longnononn/game/main/GuideModule.lua"))()
local Webhooks = loadstring(game:HttpGet("https://raw.githubusercontent.com/Longnononn/game/main/Webhooks.lua"))()

------------------------------------------------
-- 🌟 Tab Info (Thông tin)
------------------------------------------------
local InfoTab = Window:CreateTab("🌟 Info", nil)

local rainbowColors = {Color3.fromRGB(255,0,0),Color3.fromRGB(255,128,0),
    Color3.fromRGB(255,255,0),Color3.fromRGB(0,255,0),
    Color3.fromRGB(0,255,255),Color3.fromRGB(0,128,255),
    Color3.fromRGB(128,0,255),Color3.fromRGB(255,0,255)}

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

-- Credit + Thông tin
RainbowLabel("✨ Script by Long Dzz ✨")
InfoTab:CreateLabel("👤 User: " .. LocalPlayer.Name)
InfoTab:CreateLabel("⚔️ Level: " .. (Controller and Controller.GameData.MaxLevel or "Unknown"))
InfoTab:CreateLabel("🌊 Sea: " .. (Controller and Controller.GameData.SeasName[Controller.GameData.Sea] or "Unknown"))
InfoTab:CreateLabel("🛠️ Executor: " .. (identifyexecutor and identifyexecutor() or "Unknown"))

-- Thông tin cá nhân (cố định)
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
-- 📌 Run FarmQueue
------------------------------------------------
Controller.RunModules.FarmQueue({})
