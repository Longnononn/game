--[[
    Tên script: Auto send all gems to target account (Toilet Tower Defense)
    Chức năng: Tự động mở Bưu điện, nhập username người nhận, gửi toàn bộ số gem hiện có.
    Cách dùng: 
        1. Paste vào executor, thay "TÊN_NGƯỜI_NHẬN" bằng username đích thực.
        2. Chạy script khi đang đứng trong game (không cần mở giao diện trước).
        3. Script sẽ tự tìm và thao tác.
--]]

local targetUser = "sogrrzd"  -- 👈 ĐỔI THÀNH TÊN TÀI KHOẢN MUỐN GỬI

-- =========== HÀM TIỆN ÍCH ===========
local function findPostOfficeButton()
    -- Tìm nút mở Bưu điện (thường có trong thanh công cụ hoặc màn hình chính)
    local players = game:GetService("Players")
    local localPlayer = players.LocalPlayer
    local playerGui = localPlayer:WaitForChild("PlayerGui")
    
    -- Duyệt tìm GUI có tên chứa "PostOffice", "Mail", "Send"
    local postOfficeBtn = nil
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
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
    -- Chờ xuất hiện GUI con (ví dụ khung gửi thư)
    timeout = timeout or 5
    local start = tick()
    local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    repeat
        local target = playerGui:FindFirstChild(guiName, true)
        if target and target:IsA("ScreenGui") then return target end
        task.wait(0.2)
    until tick() - start > timeout
    return nil
end

local function getOwnedGems()
    -- Lấy số gem hiện tại (thường lưu ở leaderstats hoặc một giá trị trong DataModel)
    local player = game.Players.LocalPlayer
    local stats = player:FindFirstChild("leaderstats")
    if stats then
        local gemStat = stats:FindFirstChild("Gems") or stats:FindFirstChild("GemsCount") or stats:FindFirstChild("Money")
        if gemStat and gemStat:IsA("NumberValue") then
            return gemStat.Value
        end
    end
    -- Fallback: tìm trong các LocalScript/ModuleScript (ít chính xác)
    warn("Không tìm thấy leaderstats.Gems, thử scan remotes...")
    return nil
end

local function fireRemoteSend(recipient, amount)
    -- Cách 1: Gọi trực tiếp RemoteEvent (nếu biết tên)
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local remote = replicatedStorage:FindFirstChild("SendGem") or replicatedStorage:FindFirstChild("MailGem")
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer(recipient, amount)
        return true
    end
    -- Nếu không có remote, cần mô phỏng thao tác chuột (cách 2)
    return false
end

-- =========== LUỒNG CHÍNH ===========
task.spawn(function()
    print("[SCRIPT] Bắt đầu - Tìm Bưu điện...")
    local postBtn = findPostOfficeButton()
    if not postBtn then
        warn("[SCRIPT] Không tìm thấy nút Bưu điện. Hãy mở thủ công hoặc cập nhật tên.")
        return
    end
    
    -- Nhấn mở Bưu điện
    postBtn:CaptureClicks?() or fireclickdetector? -- tùy executor
    -- Dùng tọa độ nếu executor hỗ trợ click
    local clickPos = postBtn.AbsolutePosition + Vector2.new(postBtn.AbsoluteSize.X/2, postBtn.AbsoluteSize.Y/2)
    if syn and syn.input then
        syn.input.mouseclick(clickPos.X, clickPos.Y)
    elseif mouse1click then
        mouse1click(clickPos.X, clickPos.Y)
    else
        postBtn:CaptureClicks?()
    end
    task.wait(1)
    
    -- Chờ giao diện gửi thư xuất hiện (thường là GUI con)
    local sendGui = waitForGui("SendMailGui", 3) or waitForGui("PostOfficeGui", 3)
    if not sendGui then
        print("[SCRIPT] Không thấy giao diện gửi. Có thể Bưu điện đã mở sẵn.")
    end
    
    -- Tìm ô nhập username
    local usernameBox = nil
    local amountBox = nil
    local confirmBtn = nil
    if sendGui then
        for _, obj in pairs(sendGui:GetDescendants()) do
            if obj:IsA("TextBox") then
                local nameLow = obj.Name:lower()
                if nameLow:find("user") or nameLow:find("name") or nameLow:find("recipient") then
                    usernameBox = obj
                elseif nameLow:find("amount") or nameLow:find("gem") then
                    amountBox = obj
                end
            elseif obj:IsA("TextButton") and (obj.Name:lower():find("send") or obj.Name:lower():find("confirm")) then
                confirmBtn = obj
            end
        end
    end
    
    if not usernameBox then
        warn("[SCRIPT] Không tìm thấy ô nhập username. Hãy tự nhập tay rồi chạy tiếp.")
        return
    end
    
    -- Nhập username
    usernameBox:CaptureClicks?()
    usernameBox.Text = targetUser
    -- Kích hoạt sự kiện FocusLost để game nhận
    usernameBox:ReleaseFocus?()
    task.wait(0.5)
    
    -- Lấy số gem hiện tại
    local totalGems = getOwnedGems()
    if not totalGems then
        -- Nếu không đọc được, cho phép người dùng nhập tay hoặc gửi max (999999)
        totalGems = 999999
        print("[SCRIPT] Không xác định được số gem, sẽ thử gửi 999999 (hoặc số tối đa).")
    else
        print("[SCRIPT] Số gem hiện có: " .. totalGems)
    end
    
    if amountBox then
        amountBox.Text = tostring(totalGems)
        amountBox:ReleaseFocus?()
    end
    
    task.wait(0.5)
    
    -- Xác nhận gửi
    if confirmBtn then
        confirmBtn:CaptureClicks?()
        -- click confirm
        if syn and syn.input then
            local pos = confirmBtn.AbsolutePosition + Vector2.new(confirmBtn.AbsoluteSize.X/2, confirmBtn.AbsoluteSize.Y/2)
            syn.input.mouseclick(pos.X, pos.Y)
        elseif mouse1click then
            local pos = confirmBtn.AbsolutePosition + Vector2.new(confirmBtn.AbsoluteSize.X/2, confirmBtn.AbsoluteSize.Y/2)
            mouse1click(pos.X, pos.Y)
        else
            confirmBtn:CaptureClicks?()
        end
        print("[SCRIPT] Đã gửi lệnh chuyển gem!")
    else
        -- Thử gửi bằng remote
        local success = fireRemoteSend(targetUser, totalGems)
        if success then
            print("[SCRIPT] Gửi qua remote thành công!")
        else
            print("[SCRIPT] Không tìm thấy nút xác nhận hoặc remote. Có thể giao diện thay đổi.")
        end
    end
    
    -- Đóng giao diện (tuỳ chọn)
    task.wait(1)
    local closeBtn = sendGui and sendGui:FindFirstChild("CloseButton", true)
    if closeBtn and closeBtn:IsA("TextButton") then
        -- click đóng
    end
    print("[SCRIPT] Hoàn tất.")
end)
