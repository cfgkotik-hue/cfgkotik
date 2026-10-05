--!nocheck
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

NS.ModelDetector = (function()
    local M = {}
    local function geo(model)
        local hrp = model:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local parts = {}
        for _, c in ipairs(model:GetDescendants()) do
            if c:IsA("BasePart") and c ~= hrp then
                local off = c.Position - hrp.Position
                local d = off.Magnitude
                if d < 3 then
                    if off.Y > 0.5 then parts.head = parts.head or c
                    elseif math.abs(off.Y) < 0.5 then parts.torso = parts.torso or c end
                elseif d < 5 then
                    parts.limbs = parts.limbs or {}
                    table.insert(parts.limbs, c)
                end
            end
        end
        return parts
    end
    local function att(model)
        local r = {}
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("Attachment") and d.Parent and d.Parent:IsA("BasePart") then
                local n = d.Name:lower()
                if n:match("neck") or n:match("head") then r.head = d.Parent
                elseif n:match("waist") or n:match("root") then r.torso = d.Parent
                elseif n:match("shoulder") or n:match("hip") or n:match("wrist") or n:match("ankle") then
                    r.limbs = r.limbs or {}
                    table.insert(r.limbs, d.Parent)
                end
            end
        end
        return r
    end
    local function jt(model)
        local b = {}
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("Motor6D") and d.Part0 and d.Part1 then
                local n = d.Name:lower()
                if n:match("neck") then b.head = d.Part1
                elseif n:match("waist") or n:match("root") then b.torso = d.Part0
                else b.limbs = b.limbs or {}; table.insert(b.limbs, d.Part1) end
            end
        end
        return b
    end
    local function vol(parts)
        local s = {}
        for _, p in ipairs(parts) do
            local sz = p.Size
            local v = sz.X * sz.Y * sz.Z
            local r = math.max(sz.X, sz.Y, sz.Z) / math.min(sz.X, sz.Y, sz.Z)
            if v < 3 and r < 2 then s.head = s.head or p
            elseif v > 3 and v < 20 and r > 1.5 then s.torso = s.torso or p
            elseif v < 5 and r > 3 then s.limbs = s.limbs or {}; table.insert(s.limbs, p) end
        end
        return s
    end
    function M.classify(model)
        local R = { geo(model), att(model), jt(model) }
        local out = { Head = {}, Torso = {}, Limbs = {} }
        local hh, tt, ll = {}, {}, {}
        for _, d in pairs(R) do
            if d and d.head then hh[d.head] = (hh[d.head] or 0) + 1 end
            if d and d.torso then tt[d.torso] = (tt[d.torso] or 0) + 1 end
            if d and d.limbs then
                for _, p in ipairs(d.limbs) do ll[p] = (ll[p] or 0) + 1 end
            end
        end
        for p, sc in pairs(hh) do if sc >= 2 then table.insert(out.Head, p) end end
        for p, sc in pairs(tt) do if sc >= 2 then table.insert(out.Torso, p) end end
        for p, sc in pairs(ll) do if sc >= 1 then table.insert(out.Limbs, p) end end
        if #out.Head == 0 or #out.Torso == 0 then
            local ap = {}
            for _, c in ipairs(model:GetDescendants()) do
                if c:IsA("BasePart") then table.insert(ap, c) end
            end
            local vb = vol(ap)
            if vb.head and #out.Head == 0 then table.insert(out.Head, vb.head) end
            if vb.torso and #out.Torso == 0 then table.insert(out.Torso, vb.torso) end
            if vb.limbs then
                for _, p in ipairs(vb.limbs) do table.insert(out.Limbs, p) end
            end
        end
        return out
    end
    return M
end)()

NS.Scanner = (function()
    local M = {}
    local entities, entityMap = {}, {}
    local lastScan, cached, dirty = 0, 0, true
    local filter, fv, seenFv = nil, 0, -1

    local function enumerate()
        local o = {}
        for _, obj in ipairs(NS.Workspace:GetChildren()) do
            if obj:IsA("Model") then o[#o+1] = obj
            elseif obj:IsA("Folder") then
                for _, sub in ipairs(obj:GetChildren()) do
                    if sub:IsA("Model") then o[#o+1] = sub end
                end
            end
        end
        return o
    end

    local function buildPM(model, parts)
        local pm = { Head = {}, Torso = {}, Limbs = {} }
        local named = { Head=false, Torso=false, Limbs=false }
        local seen = {}
        for _, p in ipairs(parts) do
            local g = NS.partGroup(p.Name)
            if g and pm[g] then
                pm[g][#pm[g]+1] = p
                seen[p] = true
                named[g] = true
            end
        end
        if not (named.Head and named.Torso and named.Limbs) then
            local cls = NS.ModelDetector.classify(model)
            local function top(dst, src)
                for _, p in ipairs(src) do
                    if not seen[p] then dst[#dst+1] = p; seen[p] = true end
                end
            end
            if not named.Head then top(pm.Head, cls.Head) end
            if not named.Torso then top(pm.Torso, cls.Torso) end
            if not named.Limbs then top(pm.Limbs, cls.Limbs) end
        end
        return pm
    end

    local function buildEntry(model, hum, plr)
        local root = model:FindFirstChild("HumanoidRootPart")
        if not root and hum then root = hum.RootPart end
        if not root and model.PrimaryPart then root = model.PrimaryPart end
        if not root then return nil end
        local parts = NS.collectLegacyParts(model)
        local partMap = buildPM(model, parts)
        local any = false
        for _, g in ipairs({"Head","Torso","Limbs"}) do
            if #partMap[g] > 0 then any = true; break end
        end
        if not any and #parts == 0 then return nil end
        return {
            model=model, char=model, hum=hum, player=plr, isPlayer=plr~=nil,
            root=root, parts=parts, partMap=partMap,
            visible=true, lastVisibleCheck=0,
        }
    end

    local function heavy()
        local S = NS.Settings
        local cam = NS.Cam.cur or NS.Workspace.CurrentCamera
        local cp = cam and cam.CFrame.Position or Vector3.zero
        local md = S.ScanMaxDist or 3000
        local fresh, fmap, already = {}, {}, {}

        if S.TargetPlayers then
            for _, plr in ipairs(NS.Players:GetPlayers()) do
                if plr ~= NS.LP and plr.Character then
                    already[plr.Character] = true
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                        if hrp and (hrp.Position - cp).Magnitude <= md then
                            local e = buildEntry(plr.Character, hum, plr)
                            if e then fresh[#fresh+1] = e; fmap[plr.Character] = e end
                        end
                    end
                end
            end
        end

        if S.TargetNPCs then
            for _, model in ipairs(enumerate()) do
                if not already[model] and not NS.Players:GetPlayerFromCharacter(model) then
                    if NS.looksLikeRig(model) then
                        local hum = model:FindFirstChildOfClass("Humanoid")
                        local ok = false
                        if hum then ok = hum.Health > 0
                        else ok = model:FindFirstChildOfClass("AnimationController") ~= nil end
                        if ok then
                            local hrp = model:FindFirstChild("HumanoidRootPart")
                            if hrp and (hrp.Position - cp).Magnitude <= md then
                                already[model] = true
                                local e = buildEntry(model, hum, nil)
                                if e then fresh[#fresh+1] = e; fmap[model] = e end
                            end
                        end
                    end
                end
            end
        end

        local cap = S.ScanMaxEntities or 200
        if #fresh > cap then
            table.sort(fresh, function(a,b)
                return (a.root.Position - cp).Magnitude < (b.root.Position - cp).Magnitude
            end)
            for i = cap+1, #fresh do fresh[i] = nil end
        end

        for _, e in ipairs(fresh) do
            local prev = entityMap[e.model]
            if prev then
                e.visible = prev.visible
                e.lastVisibleCheck = prev.lastVisibleCheck
            end
        end
        entities = fresh; entityMap = fmap; cached = #fresh

        if S.PerfSpatialGrid and NS.SpatialGrid then
            NS.SpatialGrid.clear()
            for _, e in ipairs(entities) do NS.SpatialGrid.insert(e) end
        end
    end

    function M.setFilter(f)
        if filter ~= f then filter = f; fv = fv + 1 end
    end

    function M.tick()
        local S = NS.Settings
        local now = os.clock()
        local iv = S.ScanInterval or 0.2
        if dirty or fv ~= seenFv or now - lastScan >= iv then
            lastScan = now; dirty = false; seenFv = fv
            heavy()
        end
    end

    function M.invalidate() dirty = true end
    function M.getEntities() return entities end
    function M.count() return cached end
    function M.findEntity(model)
        for _, e in ipairs(entities) do
            if e.model == model then return e end
        end
        return nil
    end
    return M
end)()

task.spawn(function()
    while true do
        pcall(NS.Scanner.tick)
        local S = NS.Settings
        task.wait(S and S.ScanInterval or 0.2)
    end
end)

return NS
