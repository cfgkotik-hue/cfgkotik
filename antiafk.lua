--!nocheck
-- cfgkotik v37 — Anti-AFK (movement, camera, chat spam)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

NS.AntiAFK = (function()
    local M = {}
    local lastChat = 0
    local CHAT_COOLDOWN = 60

    -- ================== movement ==================
    local function randomMove()
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            local keys = {
                Enum.KeyCode.W, Enum.KeyCode.A,
                Enum.KeyCode.S, Enum.KeyCode.D,
            }
            local k = keys[math.random(1, #keys)]
            vim:SendKeyEvent(true, k, false, game)
            task.wait(math.random(10, 30) / 100)
            vim:SendKeyEvent(false, k, false, game)
        end)
    end

    local function randomJump()
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.05)
            vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
    end

    local function randomCamera()
        local cam = NS.Workspace.CurrentCamera
        if not cam then return end
        local yaw = (math.random() - 0.5) * math.rad(60)
        pcall(function()
            cam.CFrame = cam.CFrame * CFrame.Angles(0, yaw, 0)
        end)
    end

    -- ================== chat spam ==================
    local function chatSpam()
        local now = os.clock()
        if now - lastChat < CHAT_COOLDOWN then return end
        lastChat = now

        local S = NS.Settings
        local phrases = S.AntiAFKChatPhrases or {}
        if #phrases == 0 then return end

        local msg = phrases[math.random(1, #phrases)]

        pcall(function()
            local RS = game:GetService("ReplicatedStorage")
            local ev = RS:FindFirstChild("DefaultChatSystemChatEvents")
            if ev then
                local say = ev:FindFirstChild("SayMessageRequest")
                if say then
                    say:FireServer(msg, "All")
                    return
                end
            end
            -- alternate path for newer chat
            local txt = RS:FindFirstChild("DefaultChatSystemChatEvents")
            if txt then
                local ch = txt:FindFirstChild("SayMessageRequest")
                if ch then
                    ch:FireServer(msg, "All")
                end
            end
        end)
    end

    -- ================== loop ==================
    task.spawn(function()
        while true do
            local S = NS.Settings
            task.wait(S.AntiAFKInterval or 30)
            if S.AntiAFK then
                randomMove()
                if math.random() < 0.5 then randomJump() end
                randomCamera()
                if S.AntiAFKChatSpam then chatSpam() end
            end
        end
    end)

    -- ================== public ==================
    function M.ping()
        randomMove()
        randomCamera()
    end

    return M
end)()

return NS
