--!nocheck
-- cfgkotik v37 — Aimbot (basic aim + smoothing + silent + trigger)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

local clamp  = math.clamp
local exp    = math.exp
local lookAt = CFrame.lookAt

NS.Aimbot = (function()
    local M = {}
    local st = {
        target=nil, targetPart=nil, lastSeen=0,
        initialized=false, lastFrame=0, lastTrigger=0, targetName=nil,
        lastFilter=nil,
    }

    -- ================== helpers ==================
    local function sameTeam(plr)
        local S = NS.Settings
        if not S.TeamCheck then return false end
        if plr == NS.LP then return true end
        if plr.Team and NS.LP.Team and plr.Team == NS.LP.Team then return true end
        local ok, same = pcall(function()
            return plr.TeamColor and NS.LP.TeamColor
               and plr.TeamColor == NS.LP.TeamColor
        end)
        return ok and same
    end

    local function toScreen(wp)
        local cam = NS.Cam.cur or NS.Workspace.CurrentCamera
        if not cam then return nil end
        local ok, sp, on = pcall(function()
            return cam:WorldToViewportPoint(wp)
        end)
        if not ok or not sp then return nil end
        if not on and sp.Z <= 0 then return nil end
        return Vector2.new(sp.X, sp.Y)
    end

    local function score(sd, wd, hum)
        local pr = NS.Settings.Priority or "FOV"
        if pr == "Distance" then return wd end
        if pr == "Health" then return hum and hum.Health or 100 end
        return sd
    end

    local function filterName(e)
        if e.isPlayer and e.player then return e.player.Name end
        if e.char then return e.char.Name end
        return nil
    end

    local function passesFilter(e)
        local n = filterName(e)
        if not n then return true end
        local S = NS.Settings
        if S.TargetBlacklist and S.TargetBlacklist[n] then return false end
        local wl = S.TargetWhitelist
        if wl and next(wl) ~= nil and not wl[n] then return false end
        return true
    end

    -- ================== scan ==================
    local function scan(center, fovRadius)
        local cam = NS.Cam.cur or NS.Workspace.CurrentCamera
        if not cam then return false end
        local camPos  = cam.CFrame.Position
        local camLook = cam.CFrame.LookVector

        local entities
        if NS.Settings.PerfSpatialGrid and NS.SpatialGrid then
            entities = NS.SpatialGrid.query(camPos, fovRadius * 2)
        else
            entities = NS.Scanner.getEntities()
        end

        local sel = NS.Settings.AimPartList or {}
        local pr  = NS.Settings.Priority or "FOV"
        local bE, bP, bS = nil, nil, math.huge

        for _, e in ipairs(entities) do
            if NS.isAlive(e) and passesFilter(e) then
                local skip = false
                if e.isPlayer and sameTeam(e.player) then skip = true end
                if not skip then
                    local toRoot = e.root.Position - camPos
                    if toRoot.Magnitude > 0.01 then
                        if toRoot.Unit:Dot(camLook) > -0.2 then
                            local pm = e.partMap
                            if pm then
                                for grp, list in pairs(pm) do
                                    if sel[grp] then
                                        for i = 1, #list do
                                            local part = list[i]
                                            if part and part.Parent then
                                                local sp = toScreen(part.Position)
                                                if sp then
                                                    local sd = (sp - center).Magnitude
                                                    local inFov = (pr == "Crosshair")
                                                        or (sd <= fovRadius)
                                                    if inFov and e.visible then
                                                        local wd = (part.Position - camPos).Magnitude
                                                        local s = score(sd, wd, e.hum)
                                                        if grp == "Head" then s = s * 0.9 end
                                                        if s < bS then
                                                            bE, bP, bS = e, part, s
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        if bE then
            if st.target ~= bE then
                st.targetName = bE.isPlayer and bE.player.Name
                             or ("[NPC] " .. bE.char.Name)
            end
            st.target, st.targetPart, st.lastSeen = bE, bP, os.clock()
            return true
        end
        return false
    end

    -- ================== shouldAim ==================
    local function shouldAim()
        local S = NS.Settings
        if not S.Aimbot then return false end
        if S.AimMode == "Always" then return true end
        if NS.isInputPressed(S.AimKey) then return true end
        if NS.isBindActive("AimKey") then return true end
        return false
    end

    -- ================== prediction ==================
    local function predict(part)
        local S = NS.Settings
        local mult = S.PredAmount or 1.0
        if mult <= 0 then return part.Position end
        local ping = clamp(NS.getPing() * mult, 0, 0.5)
        local v = part.AssemblyLinearVelocity
        if not v then return part.Position end
        local pos = part.Position + v * ping
        if S.AimGravityComp then
            local ent = NS.Scanner.findEntity(part.Parent)
            local hum = ent and ent.hum
            if hum then
                local ok, state = pcall(function() return hum:GetState() end)
                if ok and state and (state == Enum.HumanoidStateType.Freefall
                   or state == Enum.HumanoidStateType.Flying) then
                    local g = NS.Workspace.Gravity or 196.2
                    pos = pos - Vector3.new(0, 0.5 * g * ping * ping, 0)
                end
            end
        end
        return pos
    end

    -- ================== smoothing ==================
    -- AimSmooth: 1 = instant, 20 = very smooth
    local function smooth(goalCF, dt)
        local cam = NS.Cam.cur or NS.Workspace.CurrentCamera
        if not cam then return goalCF end
        local speed = NS.Settings.AimSmooth or 5
        if speed <= 1 then return goalCF end

        local cur = cam.CFrame
        local d = clamp(cur.LookVector:Dot(goalCF.LookVector), -1, 1)
        local deg = math.deg(math.acos(d))
        local boost = clamp(deg / 30, 1.0, 3.0)

        local baseAlpha = 1.0 / speed
        local alpha = clamp(baseAlpha * boost * dt * 60, 0, 1)

        local nc = cur:Lerp(goalCF, alpha)

        local j = NS.Settings.Jitter or 0
        if j > 0 then
            local amt = j * 0.01
            nc = nc * CFrame.Angles(
                (math.random()-0.5)*amt,
                (math.random()-0.5)*amt,
                0)
        end
        return nc
    end

    -- ================== main ==================
    local function apply()
        if not shouldAim() then
            st.targetName = nil
            st.target, st.targetPart = nil, nil
            return
        end

        local cam = NS.Cam.cur or NS.Workspace.CurrentCamera
        if not cam then return end
        if not NS.LP.Character
           or not NS.LP.Character:FindFirstChildOfClass("Humanoid") then return end

        local S = NS.Settings
        local now = os.clock()
        local dt = st.lastFrame > 0 and (now - st.lastFrame) or (1/60)
        st.lastFrame = now
        if dt > 0.1 then dt = 0.1 end

        if st.target and not NS.isAlive(st.target) then
            st.target, st.targetPart = nil, nil
        end

        if S.AimPartList ~= st.lastFilter then
            NS.Scanner.setFilter(S.AimPartList)
            st.lastFilter = S.AimPartList
        end

        local cursor  = NS.UIS:GetMouseLocation()
        local found = scan(cursor, S.FOV or 120)

        if not found or not st.targetPart or not st.targetPart.Parent then return end
        if not st.target or not NS.isAlive(st.target) then
            st.target, st.targetPart = nil, nil
            return
        end

        local chance = S.HitChance or 100
        if chance < 100 and math.random() * 100 > chance then return end

        cam.CFrame = smooth(
            lookAt(cam.CFrame.Position, predict(st.targetPart)),
            dt)

        -- trigger bot
        if S.TriggerBot or NS.isBindActive("Trigger") then
            local delay = S.TriggerDelay or 0.1
            if now - st.lastTrigger >= delay then
                pcall(function()
                    local sp = cam:WorldToViewportPoint(st.targetPart.Position)
                    local vim = game:GetService("VirtualInputManager")
                    vim:SendMouseMoveEvent(sp.X, sp.Y, false, game)
                    vim:SendMouseButtonEvent(sp.X, sp.Y, 0, true, game, 1)
                    vim:SendMouseButtonEvent(sp.X, sp.Y, 0, false, game, 1)
                end)
                st.lastTrigger = now
            end
        end
    end

    -- ================== public ==================
    function M.start()
        if st.initialized then return end
        st.initialized = true
        NS.safeBind("Aim_Apply", Enum.RenderPriority.Camera.Value - 1, apply)
    end
    function M.getTargetName() return st.targetName end
    function M.hasTarget() return st.target ~= nil and st.targetPart ~= nil end
    function M.getTargetPart() return st.targetPart end
    function M.addWhitelist(n)
        if not n then return end
        NS.Settings.TargetWhitelist[n] = true
        NS.Settings.TargetBlacklist[n] = nil
    end
    function M.addBlacklist(n)
        if not n then return end
        NS.Settings.TargetBlacklist[n] = true
        NS.Settings.TargetWhitelist[n] = nil
    end
    function M.clearLists()
        NS.Settings.TargetWhitelist = {}
        NS.Settings.TargetBlacklist = {}
    end
    return M
end)()

-- ================== SILENT AIM HOOK ==================
do
    local cacheTP, cacheT = nil, 0
    local fireCount, lastReset = 0, 0
    local TTL = 0.016

    local function getTP()
        local now = os.clock()
        if cacheTP and (now - cacheT) < TTL then return cacheTP end
        if NS.Aimbot and NS.Aimbot.getTargetPart then
            cacheTP = NS.Aimbot.getTargetPart()
            cacheT = now
        end
        return cacheTP
    end

    local old
    pcall(function()
        local hmm = rawget(_G, "hookmetamethod")
        local gnm = rawget(_G, "getnamecallmethod")
        if not hmm or not gnm then return end

        old = hmm(game, "__namecall", function(self, ...)
            local method = gnm()
            local args = { ... }
            local S = NS.Settings

            if (method == "FireServer" or method == "InvokeServer")
               and S.SilentAim then
                local now = os.clock()
                if now - lastReset >= 1.0 then
                    fireCount, lastReset = 0, now
                end
                fireCount = fireCount + 1
                if fireCount > (S.SilentAimMaxFireRate or 60) then
                    S.SilentAim = false
                    return old(self, unpack(args))
                end
                local tp = getTP()
                if tp and tp.Parent then
                    for i = 1, #args do
                        if typeof(args[i]) == "Vector3" then
                            args[i] = tp.Position
                            break
                        elseif typeof(args[i]) == "CFrame" then
                            args[i] = CFrame.new(tp.Position)
                            break
                        end
                    end
                end
            end
            return old(self, unpack(args))
        end)
    end)
end

return NS
