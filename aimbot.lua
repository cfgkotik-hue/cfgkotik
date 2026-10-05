--!nocheck
-- cfgkotik v37 — Aimbot (targeting, prediction, sticky, FOV expand, silent fire)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

local clamp = math.clamp
local exp   = math.exp
local lookAt = CFrame.lookAt

local SMOOTH = {
    Smooth = { smooth = 0.5, maxAng = 450 },
    Ultra  = { smooth = 1.0, maxAng = 750 },
    Soft   = { smooth = 2.0, maxAng = 0   },
}

NS.Aimbot = (function()
    local M = {}

    local st = {
        target = nil, targetPart = nil, lastSeen = 0,
        initialized = false, lastFrame = 0, lastTrigger = 0,
        targetName = nil,
        fovMult = 1.0, fovResetAt = 0,
        lastFilter = nil,
        posHistory = {},
        failCount = 0, lastFailTime = 0,
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
        local ok, sp, on = pcall(function() return cam:WorldToViewportPoint(wp) end)
        if not ok or not sp then return nil end
        if not on and sp.Z <= 0 then return nil end
        return Vector2.new(sp.X, sp.Y)
    end

    local function score(sd, wd, hum)
        local pr = NS.Settings.Priority or "FOV"
        if pr == "Distance" then return wd end
        if pr == "Health"   then return hum and hum.Health or 100 end
        return sd
    end

    local function passesFilter(e)
        local S = NS.Settings
        local n = e.isPlayer and e.player and e.player.Name
                  or (e.char and e.char.Name)
        if not n then return true end
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

        local S = NS.Settings
        local entities
        if S.PerfSpatialGrid and NS.SpatialGrid then
            entities = NS.SpatialGrid.query(camPos, fovRadius * 2)
        else
            entities = NS.Scanner.getEntities()
        end

        local sel = S.AimPartList or {}
        local pr  = S.Priority or "FOV"
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
                                                    local inFov = (pr == "Crosshair") or (sd <= fovRadius)
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

    -- ================== state ==================
    local function shouldAim()
        local S = NS.Settings
        if not S.Aimbot then return false end
        if S.AimMode == "Always" then return true end
        if NS.isInputPressed(S.AimKey) then return true end
        if isBindActive("AimKey") then return true end
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
    local function smooth(goalCF, dt)
        local S = NS.Settings
        local preset = SMOOTH[S.AimSmoothMode] or SMOOTH.Smooth
        local cam = NS.Cam.cur or NS.Workspace.CurrentCamera
        if not cam then return goalCF end
        local cur = cam.CFrame
        local d   = clamp(cur.LookVector:Dot(goalCF.LookVector), -1, 1)
        local deg = math.deg(math.acos(d))
        local boost = clamp(deg / 30, 1.0, 3.0)
        local a = clamp(1 - exp(-preset.smooth * boost * dt * 60), 0, 1)
        local nc = cur:Lerp(goalCF, a)
        if preset.maxAng > 0 then
            local maxDeg = preset.maxAng * dt
            if deg > maxDeg and deg > 0 then
                nc = cur:Lerp(nc, maxDeg / deg)
            end
        end
        local j = S.Jitter or 0
        if j > 0 then
            local amt = j * 0.01
            nc = nc * CFrame.Angles(
                (math.random()-0.5)*amt,
                (math.random()-0.5)*amt,
                0)
        end
        return nc
    end

    local function recordPos(part, now)
        if not part or not part.Parent then
            st.posHistory = {}
            return
        end
        table.insert(st.posHistory, 1, { pos = part.Position, t = now })
        local cap = NS.Settings.PredHistory or 5
        while #st.posHistory > cap do
            table.remove(st.posHistory)
        end
    end

    local function calcAccel()
        if #st.posHistory < 3 then return Vector3.zero end
        local p1, p2, p3 = st.posHistory[1], st.posHistory[2], st.posHistory[3]
        local dt1 = p1.t - p2.t
        local dt2 = p2.t - p3.t
        if dt1 <= 0 or dt2 <= 0 then return Vector3.zero end
        local v1 = (p1.pos - p2.pos) / dt1
        local v2 = (p2.pos - p3.pos) / dt2
        return (v1 - v2) / ((dt1 + dt2) / 2)
    end

    local function predictiveSmooth(goalCF, dt)
        local S = NS.Settings
        local cam = NS.Cam.cur or NS.Workspace.CurrentCamera
        if not cam then return goalCF end
        local cur = cam.CFrame
        local target = st.targetPart
        if not target or not target.Parent or #st.posHistory < 3 then
            return smooth(goalCF, dt)
        end

        local accel = S.PredAccel and calcAccel() or Vector3.zero
        local vel = target.AssemblyLinearVelocity or Vector3.zero
        local velMag = vel.Magnitude

        local camRight = cur.RightVector
        local camUp    = cur.UpVector
        local velProj  = Vector2.new(vel:Dot(camRight), vel:Dot(camUp))
        local fo       = velProj * (dt * 2)

        local leadPos = target.Position + camRight * fo.X + camUp * fo.Y
        if accel.Magnitude > 0 then
            leadPos = leadPos + accel * (dt * dt)
        end

        local toLead = (leadPos - cur.Position).Unit
        local d = clamp(cur.LookVector:Dot(toLead), -1, 1)
        local ad = math.deg(math.acos(d))

        local ls = clamp(velMag / 50, 0.2, 1.0)
        local bs = 0.3 * ls
        local boost = clamp(ad / 30, 1.0, 3.0)
        local alpha = clamp(bs * boost * dt * 60, 0, 1)

        local finalCF = cur:Lerp(lookAt(cur.Position, leadPos), alpha)

        local j = S.Jitter or 0
        if j > 0 then
            local amt = j * 0.01
            finalCF = finalCF * CFrame.Angles(
                (math.random()-0.5)*amt,
                (math.random()-0.5)*amt,
                0)
        end
        return finalCF
    end

    -- ================== fov expand ==================
    local function getFovMult(hasBase)
        local S = NS.Settings
        local now = os.clock()
        if st.fovMult > 1.0 and now < st.fovResetAt then
            return st.fovMult
        end
        st.fovMult = 1.0
        if S.FovExpandStationary and not hasBase
           and (S.FovExpand or isBindActive("FovExpand")) then
            return S.FovExpandStationaryMult or 1.3
        end
        return 1.0
    end

    local function triggerFovExpand()
        local S = NS.Settings
        if not S.FovExpand and not isBindActive("FovExpand") then return end
        st.fovMult = S.FovExpandMult or 1.3
        st.fovResetAt = os.clock() + (S.FovExpandHold or 0.5)
    end

    local function adaptiveFactor()
        local S = NS.Settings
        if not S.AdaptiveFov then return 1.0 end
        local fps = NS.HUD and NS.HUD.getFps and NS.HUD.getFps() or 60
        if fps > 0 and fps < (S.MinFpsThreshold or 45) then
            return S.AdaptiveFovFactor or 0.8
        end
        return 1.0
    end

    local function antiDetectDelay(base)
        if not NS.Settings.AntiDetectionJitter then return base end
        return base + (math.random() - 0.5) * 0.02
    end

    -- ================== main loop ==================
    local function apply()
        local S = NS.Settings
        if not shouldAim() then
            st.targetName = nil
            st.target, st.targetPart = nil, nil
            st.posHistory = {}
            st.failCount = 0
            return
        end

        local cam = NS.Cam.cur or NS.Workspace.CurrentCamera
        if not cam then return end
        if not NS.LP.Character
           or not NS.LP.Character:FindFirstChildOfClass("Humanoid") then return end

        local now = os.clock()
        local dt = st.lastFrame > 0 and (now - st.lastFrame) or (1/60)
        st.lastFrame = now
        if dt > 0.1 then dt = 0.1 end

        if st.target and not NS.isAlive(st.target) then
            st.target, st.targetPart = nil, nil
            st.posHistory = {}
        end

        if S.AimPartList ~= st.lastFilter then
            NS.Scanner.setFilter(S.AimPartList)
            st.lastFilter = S.AimPartList
        end

        local cursor  = NS.UIS:GetMouseLocation()
        local baseFov = S.FOV * adaptiveFactor()

        local found = scan(cursor, baseFov * getFovMult(true))
        if not found then
            local m = getFovMult(false)
            if m > 1.0 then found = scan(cursor, baseFov * m) end
        end

        -- sticky
        if not found and st.targetPart then
            local p = st.targetPart
            if p.Parent and st.target and NS.isAlive(st.target)
               and (now - st.lastSeen) < (S.StickyTime or 0.25) then

                local inRadar = false
                if S.RadarEnabled then
                    local lc = NS.LP.Character
                    if lc then
                        local lr = lc:FindFirstChild("HumanoidRootPart")
                        if lr and st.target.root then
                            local d = (st.target.root.Position - lr.Position).Magnitude
                            if d <= (S.RadarRange or 300) then
                                inRadar = true
                            end
                        end
                    end
                end

                if S.AimStickyStrict then
                    local dist = (p.Position - cam.CFrame.Position).Magnitude
                    local maxSticky = S.ScanMaxDist or 3000
                    if dist <= maxSticky then
                        if not S.Visibility or st.target.visible then
                            found = true
                        else
                            st.target, st.targetPart = nil, nil
                            st.posHistory = {}
                        end
                    else
                        st.target, st.targetPart = nil, nil
                        st.posHistory = {}
                    end
                elseif inRadar then
                    st.lastSeen = now
                    found = true
                else
                    found = true
                end
            end
        end

        if not found and (S.FovExpand or isBindActive("FovExpand")) then
            triggerFovExpand()
            scan(cursor, baseFov * getFovMult(false))
        end

        -- fallback on 3 failures
        if not found then
            st.failCount = st.failCount + 1
            if st.failCount >= 3 and (now - st.lastFailTime > 1) then
                S._UseLegacyScan = true
                NS.UI.notify("Fallback: legacy scan", "error")
                st.lastFailTime = now
                NS.Scanner.invalidate()
            end
        else
            if st.failCount > 0 then
                st.failCount = 0
                S._UseLegacyScan = false
            end
        end

        if not st.targetPart or not st.targetPart.Parent then
            st.posHistory = {}
            return
        end
        if not st.target or not NS.isAlive(st.target) then
            st.target, st.targetPart = nil, nil
            st.posHistory = {}
            return
        end

        recordPos(st.targetPart, now)

        local chance = S.HitChance or 100
        if chance < 100 and math.random() * 100 > chance then return end

        cam.CFrame = predictiveSmooth(
            lookAt(cam.CFrame.Position, predict(st.targetPart)),
            dt)

        -- trigger bot
        if S.TriggerBot or isBindActive("Trigger") then
            local delay = antiDetectDelay(S.TriggerDelay or 0.1)
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
        local S = NS.Settings
        S.TargetWhitelist[n] = true
        S.TargetBlacklist[n] = nil
    end
    function M.addBlacklist(n)
        if not n then return end
        local S = NS.Settings
        S.TargetBlacklist[n] = true
        S.TargetWhitelist[n] = nil
    end
    function M.clearLists()
        local S = NS.Settings
        S.TargetWhitelist = {}
        S.TargetBlacklist = {}
    end

    return M
end)()

-- ================== silent aim hook ==================
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
            local args = {...}
            local S = NS.Settings
            if (method == "FireServer" or method == "InvokeServer") and S.SilentAim then
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
