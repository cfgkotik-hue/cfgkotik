--!nocheck
-- cfgkotik v37 — Auto-Parry (anim hook + key emulation)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

NS.AutoParry = (function()
    local M = {}
    local lastParry = 0
    local hooked = setmetatable({}, { __mode = "k" })
    local HINTS = NS.ATTACK_HINTS or {
        "slash","swing","attack","stab","punch",
        "hit","combo","strike","smash",
    }

    local function isAttack(animId, animName)
        local s = (tostring(animId) .. " " .. tostring(animName)):lower()
        for _, h in ipairs(HINTS) do
            if s:find(h, 1, true) then return true end
        end
        return false
    end

    local function parryNow()
        local now = os.clock()
        if now - lastParry < 0.05 then return end
        lastParry = now
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            local k = NS.Settings.AutoParryKey or Enum.KeyCode.F
            vim:SendKeyEvent(true, k, false, game)
            task.wait(0.03)
            vim:SendKeyEvent(false, k, false, game)
        end)
    end

    local function onAnimPlayed(anim, entity)
        if not NS.Settings.AutoParry then return end
        local lpChar = NS.LP.Character
        if not lpChar then return end
        local lpRoot = lpChar:FindFirstChild("HumanoidRootPart")
        if not lpRoot or not entity.root then return end
        local S = NS.Settings
        if (entity.root.Position - lpRoot.Position).Magnitude
           > (S.AutoParryRange or 30) then
            return
        end
        if isAttack(anim.AnimationId, anim.Name) then
            task.delay(S.AutoParryOffset or 0.05, parryNow)
        end
    end

    local function attach(entity)
        if not entity or not entity.hum then return end
        local animator = entity.hum:FindFirstChildOfClass("Animator")
        if not animator then return end
        if hooked[animator] then return end
        hooked[animator] = true
        animator.AnimationPlayed:Connect(function(anim)
            pcall(onAnimPlayed, anim, entity)
        end)
    end

    local function loop()
        while task.wait(0.5) do
            if NS.Settings.AutoParry and NS.Scanner then
                for _, e in ipairs(NS.Scanner.getEntities()) do
                    if (e.isPlayer and e.player ~= NS.LP)
                       or (not e.isPlayer and e.hum) then
                        attach(e)
                    end
                end
            end
        end
    end

    function M.start() task.spawn(loop) end
    function M.parry() parryNow() end

    return M
end)()

return NS
