-- ==================== CẤU HÌNH ====================
local TARGET_USERNAME = "sogrrzd"  -- 👈 ĐỔI LẠI THÀNH USERNAME ĐÍCH

-- ==================== HÀM TIỆN ÍCH ====================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Hàm click vào một GUI object (hỗ trợ nhiều executor)
local function clickGuiObject(guiObject)
    if not guiObject or not guiObject:IsA("GuiObject") then return false end
    local absolutePos = guiObject.AbsolutePosition
    local absoluteSize = guiObject.AbsoluteSize
    local clickPos = absolutePos + Vector2.new(absoluteSize.X / 2, absoluteSize.Y / 2)
    
    -- Dùng các hàm click phổ biến
    if syn and syn.input then
        syn.input.mouseclick(clickPos.X, clickPos.Y)
    elseif mouse1click then
        mouse1click(clickPos.X, clickPos.Y)
    elseif fireclickdetector then
        local detector = guiObject:FindFirstChildWhichIsA("ClickDetector")
        if detector then
            fireclickdetector(detector)
        else
            warn("Không tìm thấy ClickDetector, không thể click.")
            return false
        end
    else
        -- Mô phỏng bằng cách kích hoạt sự kiện (không phải lúc nào cũng hiệu quả)
        guiObject:CaptureClicks?()
    end
    return true
end

-- Hàm nhập text vào TextBox
local function setText(textBox, text)
    if not textBox or not textBox:IsA("TextBox") then return false end
    textBox.Text = text
    -- Bắn sự kiện focus lost để game nhận
    textBox:CaptureClicks?()
    if textBox:IsA("TextBox") then
        local focusLost = Instance.new("BindableEvent")
        textBox.FocusLost:Connect(function()
            focusLost:Fire()
        end)
        textBox:ReleaseFocus?()
        focusLost.Event:Wait()
    end
    return true
end

-- Lấy số Gem hiện tại
local function getTotalGems()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local gems = leaderstats:FindFirstChild("Gems") or leaderstats:FindFirstChild("GemsCount") or leaderstats:FindFirstChild("Money")
        if gems and gems:IsA("NumberValue") then
            return gems.Value
        end
    end
    -- Nếu không tìm thấy, scan toàn bộ DataModel (hiếm khi cần)
    for _, v in pairs(LocalPlayer:GetChildren()) do
        if v:IsA("IntValue") and (v.Name:lower():find("gem") or v.Name:lower():find("money")) then
            return v.Value
        end
    end
    return nil
end

-- Tìm nút mở Bưu điện trong PlayerGui
local function findPostOfficeButton()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
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

-- Tìm GUI gửi thư sau khi nhấn nút (thường xuất hiện dưới dạng Frame)
local function waitForSendGui(timeout)
    timeout = timeout or 5
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local startTime = tick()
    repeat
        for _, gui in pairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled then
                local name = (gui.Name or ""):lower()
                if name:find("send") or name:find("mail") or name:find("post") then
                    return gui
                end
                -- Duyệt sâu tìm Frame có chứa TextBox "username"/"recipient"
                local found = gui:FindFirstChild("Frame", true)
                if found and (found:FindFirstChild("TextBox", true)) then
                    return gui
                end
            end
        end
        task.wait(0.2)
    until tick() - startTime > timeout
    return nil
end

-- ==================== LUỒNG CHÍNH ====================
task.spawn(function()
    print("[GEM SENDER] Bắt đầu...")
    
    -- 1. Lấy số gem
    local gems = getTotalGems()
    if not gems then
        warn("[GEM SENDER] Không đọc được số gem. Thử gửi 999999 (tối đa).")
        gems = 999999
    else
        print("[GEM SENDER] Số gem hiện tại: " .. gems)
    end
    
    -- 2. Mở Bưu điện
    local postBtn = findPostOfficeButton()
    if not postBtn then
        error("[GEM SENDER] Không tìm thấy nút Bưu điện. Hãy đảm bảo bạn đang đứng ở khu vực có bưu điện hoặc mở thủ công.")
        return
    end
    
    print("[GEM SENDER] Đã tìm thấy nút Bưu điện, đang click...")
    clickGuiObject(postBtn)
    task.wait(1.5)
    
    -- 3. Chờ giao diện gửi xuất hiện
    local sendGui = waitForSendGui(4)
    if not sendGui then
        error("[GEM SENDER] Không thấy giao diện gửi. Có thể bưu điện chưa sẵn sàng hoặc cần tương tác NPC.")
        return
    end
    print("[GEM SENDER] Đã tìm thấy giao diện gửi.")
    
    -- 4. Tìm các thành phần trong giao diện: ô nhập tên, ô nhập số, nút gửi
    local usernameBox = nil
    local amountBox = nil
    local sendButton = nil
    
    for _, obj in pairs(sendGui:GetDescendants()) do
        if obj:IsA("TextBox") then
            local nameLow = (obj.Name or ""):lower()
            if nameLow:find("user") or nameLow:find("name") or nameLow:find("recipient") or nameLow:find("to") then
                usernameBox = obj
            elseif nameLow:find("amount") or nameLow:find("gem") or nameLow:find("number") or nameLow:find("count") then
                amountBox = obj
            end
        elseif obj:IsA("TextButton") then
            local nameLow = (obj.Name or ""):lower()
            if nameLow:find("send") or nameLow:find("confirm") or nameLow:find("submit") or nameLow:find("ok") then
                sendButton = obj
            end
        end
    end
    
    if not usernameBox then
        error("[GEM SENDER] Không tìm thấy ô nhập tên người nhận. Giao diện có thể đã thay đổi.")
        return
    end
    if not amountBox then
        warn("[GEM SENDER] Không tìm thấy ô nhập số lượng, sẽ thử gửi toàn bộ mặc định.")
    end
    if not sendButton then
        warn("[GEM SENDER] Không tìm thấy nút gửi, sẽ thử click nút 'Send' từ scan chung.")
    end
    
    -- 5. Nhập thông tin
    print("[GEM SENDER] Đang nhập username: " .. TARGET_USERNAME)
    setText(usernameBox, TARGET_USERNAME)
    task.wait(0.5)
    
    if amountBox then
        print("[GEM SENDER] Đang nhập số gem: " .. gems)
        setText(amountBox, tostring(gems))
        task.wait(0.5)
    end
    
    -- 6. Bấm nút gửi
    if sendButton then
        print("[GEM SENDER] Bấm nút gửi...")
        clickGuiObject(sendButton)
    else
        -- Dò lại toàn bộ giao diện lần nữa để tìm nút gửi
        local anySendBtn = nil
        for _, btn in pairs(sendGui:GetDescendants()) do
            if btn:IsA("TextButton") and (btn.Name:lower():find("send") or btn.Text:lower():find("send")) then
                anySendBtn = btn
                break
            end
        end
        if anySendBtn then
            clickGuiObject(anySendBtn)
        else
            error("[GEM SENDER] Không tìm thấy bất kỳ nút gửi nào. Gửi thất bại.")
        end
    end
    
    -- 7. Thông báo hoàn tất
    task.wait(2)
    print("[GEM SENDER] Đã gửi yêu cầu chuyển gem. Kiểm tra lại trong game nhé!")
end)
