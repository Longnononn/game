--[[
    Tên script: Auto send all gems to target account (Toilet Tower Defense) - Visual Status Version
    Chức năng: Tự động mở Bưu điện, nhập username người nhận, gửi toàn bộ số gem hiện có và hiển thị trạng thái trên màn hình.
    Cách dùng: 
        1. Paste vào executor, thay "TEN_NGUOI_NHAN" bằng username đích thực.
        2. Chạy script khi đang đứng trong sảnh game (lobby).
--]]

local targetUser = "sogrrzd"  -- 👈 ĐỔI THÀNH TÊN TÀI KHOẢN MUỐN GỬI

-- =========== TẠO GIAO DIỆN TRẠNG THÁI (STATUS GUI) ===========
local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Xóa GUI cũ nếu có
if playerGui:FindFirstChild("GemTransferStatus") then
    playerGui.GemTransferStatus:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GemTransferStatus"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 300, 0, 50)
statusLabel.Position = UDim2.new(0.5, -150, 0.1, 0) -- Hiển thị ở phía trên giữa màn hình
statusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
statusLabel.BackgroundTransparency = 0.2
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextSize = 16
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.Text = "[HỆ THỐNG] Đang chuẩn bị..."
statusLabel.Parent = screenGui

-- Bo góc cho giao diện đẹp hơn
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = statusLabel

local function setStatus(text, color)
    statusLabel.Text = "[HỆ THỐNG] " .. text
    if color then
        statusLabel.TextColor3 = color
    else
        statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

-- =========== HÀM TIỆN ÍCH ===========
local function safeClick(button)
    if not button then return end
    
    -- Kiểm tra nếu nút bấm thực sự là ClickDetector thì mới gọi fireclickdetector
    if fireclickdetector and button:IsA("ClickDetector") then
        pcall(function()
            fireclickdetector(button)
        end)
    elseif button:IsA("GuiButton") then
        -- Giả lập nhấn chuột bằng phương thức ảo hóa của Roblox dành cho nút GUI
        pcall(function()
            button:Activate()
        end)
    end

    -- Sử dụng tọa độ nếu executor hỗ trợ các hàm click chuột phần cứng
    local success, pos = pcall(function()
        return button.AbsolutePosition + Vector2.new(button.AbsoluteSize.X / 2, button.AbsoluteSize.Y / 2)
    end)
    
    if success then
        if syn and syn.input and syn.input.mouseclick then
            syn.input.mouseclick(pos.X, pos.Y)
        elseif mouse1click then
            mouse1click(pos.X, pos.Y)
        end
    end
end

local function findPostOfficeButton()
    local postOfficeBtn = nil
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, btn in pairs(gui:GetDescendants()) do
                if btn:IsA("ImageButton") or btn:IsA("TextButton") then
                    local name = btn.Name:lower()
                    if name:find("post") or name:find("mail") or name:find("send") then
                        postOfficeBtn = btn
                        break
                    end
                end
            end
        end
        if postOfficeBtn then break end
    end
    return postOfficeBtn
end

local function waitForGui(guiName, timeout)
    timeout = timeout or 5
    local start = tick()
    repeat
        local target = playerGui:FindFirstChild(guiName, true)
        if target and (target:IsA("ScreenGui") or target:IsA("Frame")) then 
            return target 
        end
        task.wait(0.2)
    until tick() - start > timeout
    return nil
end

local function getOwnedGems()
    -- Thử tìm trong leaderstats chuẩn
    local stats = player:FindFirstChild("leaderstats")
    if stats then
        local gemStat = stats:FindFirstChild("Gems") or stats:FindFirstChild("GemsCount") or stats:FindFirstChild("Diamonds")
        if gemStat and (gemStat:IsA("NumberValue") or gemStat:IsA("IntValue")) then
            return gemStat.Value
        end
    end
    
    -- Thử quét tất cả các biến số trong Player để tìm số lượng đá quý
    for _, child in pairs(player:GetDescendants()) do
        if (child:IsA("NumberValue") or child:IsA("IntValue")) and (child.Name:lower():find("gem") or child.Name:lower():find("coin")) then
            return child.Value
        end
    end
    
    return nil
end

local function fireRemoteSend(recipient, amount)
    local replicatedStorage = game:GetService("ReplicatedStorage")
    -- Quét tìm các Remote Event có khả năng xử lý giao dịch thư tín
    for _, remote in pairs(replicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") then
            local name = remote.Name:lower()
            if name:find("send") or name:find("mail") or name:find("post") then
                pcall(function()
                    remote:FireServer(recipient, amount)
                end)
                return true
            end
        end
    end
    return false
end

-- =========== LUỒNG CHÍNH ===========
task.spawn(function()
    setStatus("Đang tìm nút Bưu điện...", Color3.fromRGB(255, 200, 0))
    local postBtn = findPostOfficeButton()
    
    if postBtn then
        setStatus("Đã thấy nút Bưu điện, đang mở...", Color3.fromRGB(100, 255, 100))
        safeClick(postBtn)
        task.wait(1.5)
    else
        setStatus("Không thấy nút tự động. Hãy tự mở thủ công!", Color3.fromRGB(255, 100, 100))
        task.wait(2)
    end
    
    -- Chờ giao diện gửi thư xuất hiện
    setStatus("Đang quét giao diện gửi thư...")
    local sendGui = waitForGui("SendMailGui", 3) or waitForGui("PostOfficeGui", 3) or waitForGui("MailGui", 3)
    
    -- Tìm các thành phần nhập liệu
    local searchRoot = sendGui or playerGui
    local usernameBox = nil
    local amountBox = nil
    local confirmBtn = nil
    
    for _, obj in pairs(searchRoot:GetDescendants()) do
        if obj:IsA("TextBox") and obj.Visible then
            local nameLow = obj.Name:lower()
            if nameLow:find("user") or nameLow:find("name") or nameLow:find("recipient") or nameLow:find("player") then
                usernameBox = obj
            elseif nameLow:find("amount") or nameLow:find("gem") or nameLow:find("val") then
                amountBox = obj
            end
        elseif obj:IsA("TextButton") and obj.Visible then
            local nameLow = obj.Name:lower()
            if nameLow:find("send") or nameLow:find("confirm") or nameLow:find("gift") or nameLow:find("yes") then
                confirmBtn = obj
            end
        end
    end
    
    -- Thực hiện nhập liệu và gửi
    if usernameBox then
        setStatus("Đang nhập tên người nhận...", Color3.fromRGB(100, 200, 255))
        usernameBox.Text = targetUser
        pcall(function() usernameBox:ReleaseFocus(true) end)
        task.wait(0.5)
        
        -- Lấy số gem hiện tại
        local totalGems = getOwnedGems()
        if not totalGems or totalGems <= 0 then
            totalGems = 999999
            setStatus("Không đọc được số gem, điền mặc định.", Color3.fromRGB(255, 150, 100))
        else
            setStatus("Gems hiện có: " .. totalGems, Color3.fromRGB(100, 255, 100))
        end
        task.wait(0.5)
        
        if amountBox then
            amountBox.Text = tostring(totalGems)
            pcall(function() amountBox:ReleaseFocus(true) end)
            task.wait(0.5)
        end
        
        if confirmBtn then
            setStatus("Đang nhấn nút gửi...", Color3.fromRGB(100, 255, 100))
            safeClick(confirmBtn)
            setStatus("ĐÃ GỬI THÀNH CÔNG!", Color3.fromRGB(0, 255, 0))
        else
            setStatus("Thử gửi trực tiếp qua Remote...", Color3.fromRGB(255, 200, 0))
            fireRemoteSend(targetUser, totalGems)
            setStatus("Đã gửi lệnh qua Remote!", Color3.fromRGB(0, 255, 0))
        end
    else
        setStatus("Không thấy ô nhập liệu! Hãy mở sẵn bảng Mail.", Color3.fromRGB(255, 100, 100))
        -- Thử gửi dự phòng qua Remote nếu UI bị lỗi
        local totalGems = getOwnedGems() or 1000
        fireRemoteSend(targetUser, totalGems)
    end
    
    -- Tự động ẩn thông báo sau 5 giây khi hoàn tất
    task.wait(5)
    if screenGui then
        screenGui:Destroy()
    end
end)
