--!nocheck
-- cfgkotik v37 — Scanner (ModelDetector + UniversalScanner + central loop)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

-- ================== MODEL DETECTOR ==================
NS.ModelDetector = (function()
    local M = {}

    local function geometricAnalysis(model)
        local hrp = model:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local parts = {}
        for _, child in ipairs(model:GetDescendants()) do
            if child:IsA("BasePart") and child ~= hrp then
                local offset = child.Position - hrp.Position
                local dist = offset.Magnitude
                if dist < 3 then
                    if offset.Y > 0.5 then
                        parts.head = parts.head or child
                    elseif math.abs(offset.Y) < 0.5 then
                        parts.torso = parts.torso or child
                    end
                elseif dist < 5 then
                    parts.limbs = parts.limbs or {}
                    table.insert(parts.limbs, child)
                end
            end
        end
        return parts
    end

    local function attachmentScan(model)
        local classified = {}
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("Attachment") then
                local parent = desc.Parent
                if parent and parent:IsA("BasePart") then
                    local name = desc.Name:lower()
                    if name:match("neck") or name:match("head") then
                        classified.head = parent
                    elseif name:match("waist") or name:match("root") then
                        classified.torso = parent
                    elseif name:match("shoulder") or name:match("hip")
                        or name:match("wrist") or name:match("ankle") then
                        classified.limbs = classified.limbs or {}
                        table.insert(classified.limbs, parent)
                    end
                end
            end
        end
        return classified
    end

    local function jointScan(model)
        local bones = {}
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("Motor6D") then
                local p0, p1 = desc.Part0, desc.Part1
                if p0 and p1 then
                    local name = desc.Name:lower()
                    if name:match("neck") then
                        bones.head = p1
                    elseif name:match("waist") or name:match("root") then
                        bones.torso = p0
                    else
                        bones.limbs = bones.limbs or {}
                        table.insert(bones.limbs, p1)
                    end
                end
            end
        end
        return bones
    end

    local function volumeAnalysis(parts)
        local scored = {}
        for _, p in ipairs(parts) do
            local size = p.Size
            local volume = size.X * size.Y * size.Z
            local ratio = math.max(size.X, size.Y, size.Z) /
                          math.min(size.X, size.Y, size.Z)
            if volume < 3 and ratio < 2 then
                scored.head = scored.head or p
            elseif volume > 3 and volume < 20 and ratio > 1.5 then
                scored.torso = scored.torso or p
            elseif volume < 5 and ratio > 3 then
                scored.limbs = scored.limbs or {}
                table.insert(scored.limbs, p)
            end
        end
        return scored
    end

    function M.classify(model)
        local results = {
            geometric   = geometricAnalysis(model),
            attachments = attachmentScan(model),
            joints      = jointScan(model),
        }
        local final = { Head = {}, Torso = {}, Limbs = {} }

        local heads = {}
        for _, data in pairs(results) do
            if data and data.head then
                heads[data.head] = (heads[data.head] or 0) + 1
            end
        end
        for part, score in pairs(heads) do
            if score >= 2 then table.insert(final.Head, part) end
        end

        local torsos = {}
        for _, data in pairs(results) do
            if data and data.torso then
                torsos[data.torso] = (torsos[data.torso] or 0) + 1
            end
        end
        for part, score in pairs(torsos) do
            if score >= 2 then table.insert(final.Torso, part) end
        end

        local limbs = {}
        for _, data in pairs(results) do
            if data and data.limbs then
                for _, p in ipairs(data.limbs) do
                    limbs[p] = (limbs[p] or 0) + 1
                end
            end
        end
        for part, score in pairs(limbs) do
            if score >= 1 then table.insert(final.Limbs, part) end
        end

        if #final.Head == 0 or #final.Torso == 0 then
            local allParts = {}
            for _, child in ipairs(model:GetDescendants()) do
                if child:IsA("BasePart") then
                    table.insert(allParts, child)
                end
            end
            local volumeBased = volumeAnalysis(allParts)
            if volumeBased.head and #final.Head == 0 then
                table.insert(final.Head, volumeBased.head)
            end
            if volumeBased.torso and #final.Torso == 0 then
                table.insert(final.Torso, volumeBased.torso)
            end
            if volumeBased.limbs then
                for _, p in ipairs(volumeBased.limbs) do
                    table.insert(final.Limbs, p)
                end
            end
        end
        return final
    end

    return M
end)()

-- ================== UNIVERSAL SCANNER ==================
NS.Scanner = (function()
    local M = {}
    local entities = {}
    local entityMap = {}
    local lastScan = 0
    local cachedCount = 0
    local dirty = true
    local liveAimFilter = nil
    local filterVersion = 0
    local seenFilterVersion = -1
    local lastDebugViz = 0

    local function enumerateModels()
        local out = {}
        local Workspace = NS.Workspace
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("Model") then
                out[#out + 1] = obj
            elseif obj:IsA("Folder") then
                for _, sub in ipairs(obj:GetChildren()) do
                    if sub:IsA("Model") then out[#out + 1] = sub end
                end
            end
        end
        return out
    end

    -- named parts first; top-up from detector only for missing groups
    local function buildPartMap(model, parts)
        local pm = { Head = {}, Torso = {}, Limbs = {} }
        local named = { Head = false, Torso = false, Limbs = false }
        local seen = {}

        for _, p in ipairs(parts) do
            local g = NS.partGroup(p.Name)
            if g and pm[g] then
                pm[g][#pm[g] + 1] = p
                seen[p] = true
                named[g] = true
            end
        end

        if not (named.Head and named.Torso and named.Limbs) then
            local cls = NS.ModelDetector.classify(model)
            local function topUp(dst, src)
                for _, p in ipairs(src) do
                    if not seen[p] then
                        dst[#dst + 1] = p
                        seen[p] = true
                    end
                end
            end
            if not named.Head  then topUp(pm.Head,  cls.Head)  end
            if not named.Torso then topUp(pm.Torso, cls.Torso) end
            if not named.Limbs then topUp(pm.Limbs, cls.Limbs) end
        end

        return pm
    end

    local function buildEntry(model, hum, plr)
        local root = model:FindFirstChild("HumanoidRootPart")
        if not root and hum then root = hum.RootPart end
        if not root and model.PrimaryPart then root = model.PrimaryPart end
        if not root then return nil end

        local parts = NS.collectLegacyParts(model)
        local partMap = buildPartMap(model, parts)
        local anyPart = false
        for _, g in ipairs({"Head", "Torso", "Limbs"}) do
            if #partMap[g] > 0 then anyPart = true; break end
        end
        if not anyPart and #parts == 0 then return nil end

        return {
            model = model, char = model, hum = hum, player = plr,
            isPlayer = plr ~= nil,
            root = root, parts = parts, partMap = partMap,
            visible = true, lastVisibleCheck = 0,
        }
    end

    local function heavyScan()
        local S = NS.Settings
        local Players = NS.Players
        local LP = NS.LP
        local cam = NS.Cam.cur or NS.Workspace.CurrentCamera
        local camPos = cam and cam.CFrame.Position or Vector3.zero
        local maxDist = S.ScanMaxDist or 3000
        local fresh, freshMap, already = {}, {}, {}

        if S.TargetPlayers then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP and plr.Character then
                    already[plr.Character] = true
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                        if hrp and (hrp.Position - camPos).Magnitude <= maxDist then
                            local e = buildEntry(plr.Character, hum, plr)
                            if e then
                                fresh[#fresh + 1] = e
                                freshMap[plr.Character] = e
                            end
                        end
                    end
                end
            end
        end

        if S.TargetNPCs then
            for _, model in ipairs(enumerateModels()) do
                if not already[model]
                   and not Players:GetPlayerFromCharacter(model) then
                    if NS.looksLikeRig(model) then
                        local hum = model:FindFirstChildOfClass("Humanoid")
                        local ok = false
                        if hum then
                            ok = hum.Health > 0
                        else
                            ok = model:FindFirstChildOfClass("AnimationController") ~= nil
                        end
                        if ok then
                            local hrp = model:FindFirstChild("HumanoidRootPart")
                            if hrp and (hrp.Position - camPos).Magnitude <= maxDist then
                                already[model] = true
                                local e = buildEntry(model, hum, nil)
                                if e then
                                    fresh[#fresh + 1] = e
                                    freshMap[model] = e
                                end
                            end
                        end
                    end
                end
            end
        end

        local cap = S.ScanMaxEntities or 200
        if #fresh > cap then
            table.sort(fresh, function(a, b)
                return (a.root.Position - camPos).Magnitude
                     < (b.root.Position - camPos).Magnitude
            end)
            for i = cap + 1, #fresh do fresh[i] = nil end
        end

        for _, e in ipairs(fresh) do
            local prev = entityMap[e.model]
            if prev then
                e.visible = prev.visible
                e.lastVisibleCheck = prev.lastVisibleCheck
            end
        end

        entities = fresh
        entityMap = freshMap
        cachedCount = #fresh

        if S.PerfSpatialGrid and NS.SpatialGrid then
            NS.SpatialGrid.clear()
            for _, e in ipairs(entities) do NS.SpatialGrid.insert(e) end
        end
    end

    local function debugViz()
        for _, e in ipairs(entities) do
            local c = NS.ModelDetector.classify(e.model)
            local function paint(seq, col)
                for _, p in ipairs(seq) do
                    local hl = Instance.new("Highlight")
                    hl.FillColor = col
                    hl.FillTransparency = 0.5
                    hl.OutlineColor = col:Lerp(Color3.new(1,1,1), 0.4)
                    hl.Parent = p
                    task.delay(2, function()
                        pcall(function() hl:Destroy() end)
                    end)
                end
            end
            paint(c.Head,  Color3.fromRGB(255, 0, 0))
            paint(c.Torso, Color3.fromRGB(0, 255, 0))
            paint(c.Limbs, Color3.fromRGB(0, 0, 255))
        end
    end

    function M.setFilter(f)
        if liveAimFilter ~= f then
            liveAimFilter = f
            filterVersion = filterVersion + 1
        end
    end

    function M.tick()
        local S = NS.Settings
        local now = os.clock()
        local interval = S.ScanInterval or 0.2
        if dirty or filterVersion ~= seenFilterVersion
           or now - lastScan >= interval then
            lastScan = now
            dirty = false
            seenFilterVersion = filterVersion
            heavyScan()
            if S.DetectorDebug and (now - lastDebugViz > 2.0) then
                lastDebugViz = now
                pcall(debugViz)
            end
        end
    end

    function M.invalidate() dirty = true end
    function M.getEntities() return entities end
    function M.count() return cachedCount end
    function M.findEntity(model)
        for _, e in ipairs(entities) do
            if e.model == model then return e end
        end
        return nil
    end

    return M
end)()

-- ================== CENTRAL LOOP ==================
task.spawn(function()
    while true do
        local S = NS.Settings
        pcall(NS.Scanner.tick)
        task.wait((S and S.ScanInterval) or 0.2)
    end
end)

return NS
