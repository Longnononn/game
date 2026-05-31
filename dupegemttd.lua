-- ==================== CẤU HÌNH ====================
local TARGET_USERNAME = "sogrrzd"  -- 👈 ĐÃ ĐỔI THEO BẠN

-- ==================== HÀM CLICK AN TOÀN (KHÔNG DÙNG REMOTE) ====================
local function safeClick(guiObject)
    if not guiObject or not guiObject:IsA("GuiObject") then return false end
    
    -- Lấy tọa độ trung tâm của nút
    local pos, success = pcall(function()
        return guiObject.AbsolutePosition + Vector2.new(guiObject.AbsoluteSize.X / 2, guiObject.AbsoluteSize.Y / 2)
    end)
    if not success then return false end
    
    -- Dùng các hàm click phổ biến của executor
    if syn and syn.input then
        syn.input.mouseclick(pos.X, pos.Y)
    elseif mouse1click then
        mouse1click(pos.X, pos.Y)
    elseif fireclickdetector then
        -- Một số nút có ClickDetector con
        local detector = guiObject:FindFirstChildWhichIsA("ClickDetector")
        if detector then fireclickdetector(detector) end
    else
        -- Phương thức dự phòng
        pcall(function() guiObject:Activate() end)
    end
    return true
end

-- Hàm nhập text và kích hoạt sự kiện FocusLost
local function setText(textBox, text)
    if not textBox or not textBox:IsA("TextBox") then return false end
    textBox.Text = text
    pcall(function() textBox:ReleaseFocus(true) end)
    return true
end

-- Tìm nút mở bưu điện (tự động quét toàn bộ PlayerGui)
local function findPostOfficeButton()
    local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, btn in pairs(gui:GetDescendants()) do
                if btn:IsA("ImageButton") or btn:IsA("TextButton") then
                    local name = (btn.Name or ""):lower()
                    if name:find("post") or name:find("mail") or name:find("send") or name:find("gift") then
                        return btn
                    end
                end
            end
        end
    end
    return nil
end

-- Chờ giao diện gửi xuất hiện (khung nhập liệu)
local function waitForSendGui(timeout)
    timeout = timeout or 5
    local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    local start = tick()
    repeat
        for _, gui in pairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled then
                -- Nếu tìm thấy TextBox liên quan đến username/amount thì coi như thành công
                local anyTextBox = false
                for _, obj in pairs(gui:GetDescendants()) do
                    if obj:IsA("TextBox") and obj.Visible then
                        anyTextBox = true
                        break
                    end
                end
                if anyTextBox then return gui end
            end
        end
        task.wait(0.2)
    until tick() - start > timeout
    return nil
end

-- Lấy số Gem hiện có từ leaderstats
local function getTotalGems()
    local stats = game.Players.LocalPlayer:FindFirstChild("leaderstats")
    if stats then
        local gems = stats:FindFirstChild("Gems") or stats:FindFirstChild("GemsCount") or stats:FindFirstChild("Diamonds")
        if gems and (gems:IsA("NumberValue") or gems:IsA("IntValue")) then
            return gems.Value
        end
    end
    return nil
end

-- ==================== LUỒNG CHÍNH ====================
task.spawn(function()
    print("[GemSender] Bắt đầu...")
    
    -- 1. Mở bưu điện
    local postBtn = findPostOfficeButton()
    if postBtn then
        print("[GemSender] Tìm thấy nút Bưu điện, click để mở...")
        safeClick(postBtn)
        task.wait(1.5)
    else
        warn("[GemSender] Không tìm thấy nút Bưu điện. Hãy tự mở thủ công rồi chạy lại script.")
        return
    end
    
    -- 2. Chờ giao diện gửi hiện ra
    local sendGui = waitForSendGui(4)
    if not sendGui then
        warn("[GemSender] Không thấy giao diện nhập liệu. Kiểm tra xem bưu điện đã mở chưa?")
        return
    end
    print("[GemSender] Đã thấy giao diện gửi.")
    
    -- 3. Tìm các ô nhập liệu và nút gửi trong GUI đó
    local usernameBox = nil
    local amountBox = nil
    local sendButton = nil
    
    for _, obj in pairs(sendGui:GetDescendants()) do
        if obj:IsA("TextBox") and obj.Visible then
            local name = (obj.Name or ""):lower()
            if name:find("user") or name:find("name") or name:find("recipient") or name:find("to") then
                usernameBox = obj
            elseif name:find("amount") or name:find("gem") or name:find("count") or name:find("value") then
                amountBox = obj
            end
        elseif obj:IsA("TextButton") and obj.Visible then
            local name = (obj.Name or ""):lower()
            if name:find("send") or name:find("confirm") or name:find("submit") or name:find("ok") then
                sendButton = obj
            end
        end
    end
    
    if not usernameBox then
        error("[GemSender] Không tìm thấy ô nhập tên người nhận. Giao diện có thể khác, hãy chụp ảnh màn hình.")
        return
    end
    
    -- 4. Nhập thông tin
    print("[GemSender] Đang nhập tên: " .. TARGET_USERNAME)
    setText(usernameBox, TARGET_USERNAME)
    task.wait(0.5)
    
    local gems = getTotalGems()
    if not gems then
        warn("[GemSender] Không đọc được số gem, sẽ gửi 999999 (tối đa).")
        gems = 999999
    else
        print("[GemSender] Số gem hiện tại: " .. gems)
    end
    
    if amountBox then
        setText(amountBox, tostring(gems))
        task.wait(0.5)
    end
    
    -- 5. Bấm nút gửi
    if sendButton then
        print("[GemSender] Đang nhấn nút gửi...")
        safeClick(sendButton)
        print("[GemSender] Đã gửi yêu cầu! Kiểm tra trong game sau vài giây.")
    else
        warn("[GemSender] Không tìm thấy nút gửi. Có thể giao diện thay đổi hoặc cần xác nhận thêm.")
    end
    
    -- Kết thúc
    task.wait(2)
    print("[GemSender] Hoàn tất.")
end)
