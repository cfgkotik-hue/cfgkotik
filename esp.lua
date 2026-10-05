--!nocheck
-- cfgkotik v37 — ESP (boxes, names, health, tracers, chams)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

NS.ESPCache = (function()
    local M = {}
    local cache = setmetatable({}, {__mode = "k"})
    function M.get(e)
        local c = cache[e]
        if not c then
            c = { lastPos = e.root.Position, lastUpdate = 0 }
            cache[e] = c
        end
        return c
    end
    function M.shouldUpdate(e, now)
        local S = NS.Settings
        if not S.PerfCacheESP then return true end
        local c = M.get(e)
        if now - c.lastUpdate < (S.ESPCacheInterval or 0.05) then return false end
        if (e.root.Position - c.lastPos).Magnitude < (S.ESPMoveThreshold or 5) then
            return false
        end
        return true
    end
    function M.update(e, now)
        local c = M.get(e)
        c.lastPos = e.root.Position
        c.lastUpdate = now
    end
    return M
end)()

NS.ESP = (function()
    local M = {}
    local pool = setmetatable({}, {__mode = "k"})
    local lastUpdate = 0

    -- ================== helpers ==================
    local function pickColor(dist, baseCol)
        local S = NS.Settings
        if not S.ESPDistanceColors then return baseCol end
        if dist <= (S.ESPNearThreshold or 50) then
            return S.ESPNearColor or baseCol
        end
        if dist <= (S.ESPMidThreshold or 200) then
            return S.ESPMidColor or baseCol
        end
        return S.ESPFarColor or baseCol
    end

    local function inViewFrustum(pos)
        local cam = NS.Cam.cur or NS.Workspace.CurrentCamera
        if not cam then return false end
        local _, on = cam:WorldToViewportPoint(pos)
        return on
    end

    -- ================== pool ==================
    local function new(char)
        if pool[char] then return pool[char] end
        local d = {}

        d.box = Drawing.new("Square")
        d.box.Thickness = 1.5
        d.box.Filled = false
        d.box.Visible = false

        d.corner = {}
        for i = 1, 4 do
            d.corner[i] = Drawing.new("Line")
            d.corner[i].Thickness = 2
            d.corner[i].Visible = false
        end

        d.name = Drawing.new("Text")
        d.name.Size = 13
        d.name.Center = true
        d.name.Outline = true
        d.name.Visible = false

        d.hpBg = Drawing.new("Square")
        d.hpBg.Filled = true
        d.hpBg.Thickness = 0
        d.hpBg.Color = Color3.fromRGB(20, 20, 20)
        d.hpBg.Visible = false

        d.hp = Drawing.new("Square")
        d.hp.Filled = true
        d.hp.Thickness = 0
        d.hp.Visible = false

        d.tracer = Drawing.new("Line")
        d.tracer.Thickness = 1
        d.tracer.Visible = false

        d.weapon = Drawing.new("Text")
        d.weapon.Size = 12
        d.weapon.Center = true
        d.weapon.Outline = true
        d.weapon.Visible = false

        d.highlight = nil

        pool[char] = d
        return d
    end

    local function hide(d)
        if not d then return end
        d.box.Visible = false
        for i = 1, 4 do d.corner[i].Visible = false end
        d.name.Visible = false
        d.hpBg.Visible = false
        d.hp.Visible = false
        d.tracer.Visible = false
        d.weapon.Visible = false
        if d.highlight then d.highlight.Enabled = false end
    end

    local function ensureHighlight(d, char)
        if d.highlight and d.highlight.Parent then return end
        if not NS.Settings.ESPHighlight then return end
        local h = Instance.new("Highlight")
        h.Name = "cfgkotik_hl"
        h.FillTransparency = 0.6
        h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = char
        d.highlight = h
    end

    local function drawCornerBox(d, x, y, w, h, col)
        local len = math.min(w, h) * 0.25
        local pts = {
            {x, y, x+len, y},
            {x, y, x, y+len},
            {x+w, y, x+w-len, y},
            {x+w, y, x+w, y+len},
            {x, y+h, x+len, y+h},
            {x, y+h, x, y+h-len},
            {x+w, y+h, x+w-len, y+h},
            {x+w, y+h, x+w, y+h-len},
        }
        for i = 1, 4 do
            local ln = d.corner[i]
            ln.Visible = true
            ln.Color = col
            ln.From = Vector2.new(pts[i*2-1][1], pts[i*2-1][2])
            ln.To   = Vector2.new(pts[i*2][1],   pts[i*2][2])
        end
    end

    -- ================== render ==================
    local function render()
        local S = NS.Settings
        if not S.ESP then
            for _, d in pairs(pool) do hide(d) end
            return
        end

        local cam = NS.Cam.cur or NS.Workspace.CurrentCamera
        if not cam then return end

        local entities = NS.Scanner.getEntities()
        local camPos = cam.CFrame.Position
        local camLook = cam.CFrame.LookVector
        local vp = cam.ViewportSize
        local seen = {}

        local interval = S.ESPUpdateRate or 0.03
        local now = os.clock()
        local doUpdate = (now - lastUpdate >= interval)
        local maxD = S.ESPMaxDist or 2000

        for _, ent in ipairs(entities) do
            local show = (ent.isPlayer and S.ESPShowPlayers)
                      or ((not ent.isPlayer) and S.ESPShowNPCs)
            if show then
                local char = ent.char
                local root = ent.root
                if char and char.Parent and NS.isAlive(ent) and root then
                    local dist = (root.Position - camPos).Magnitude
                    if dist <= maxD and inViewFrustum(root.Position) then
                        local col = pickColor(dist, S.ESPColor)
                        local toT = (root.Position - camPos).Unit
                        if toT:Dot(camLook) > -0.1 then
                            local spRoot, on = cam:WorldToViewportPoint(root.Position)
                            if on and spRoot.Z > 0 then
                                seen[char] = true
                                local d = new(char)

                                local canUpdate = doUpdate and
                                    (NS.ESPCache.shouldUpdate(ent, now)
                                     or not S.PerfCacheESP)

                                if canUpdate then
                                    local hum = ent.hum
                                    local head = char:FindFirstChild("Head")
                                    local topWorld = (head and head.Position + Vector3.new(0, 0.5, 0))
                                                   or (root.Position + Vector3.new(0, 3, 0))
                                    local botWorld = root.Position - Vector3.new(0, 3, 0)
                                    local tS, tOn = cam:WorldToViewportPoint(topWorld)
                                    local bS, bOn = cam:WorldToViewportPoint(botWorld)

                                    if tOn and bOn then
                                        local hh = math.abs(bS.Y - tS.Y)
                                        if hh < 4 then hh = 30 end
                                        local w  = hh * 0.55
                                        local x, y = tS.X - w/2, tS.Y

                                        -- box
                                        if S.ESPBox then
                                            if S.ESPBoxStyle == "corner" then
                                                d.box.Visible = false
                                                drawCornerBox(d, x, y, w, hh, col)
                                            else
                                                for i = 1, 4 do d.corner[i].Visible = false end
                                                d.box.Visible = true
                                                d.box.Size = Vector2.new(w, hh)
                                                d.box.Position = Vector2.new(x, y)
                                                d.box.Color = col
                                            end
                                        else
                                            d.box.Visible = false
                                            for i = 1, 4 do d.corner[i].Visible = false end
                                        end

                                        -- labels
                                        local labelY = y - 16

                                        if S.ESPName then
                                            d.name.Visible = true
                                            local label
                                            if ent.isPlayer then
                                                label = ent.player.Name
                                            else
                                                label = "[NPC] " .. char.Name
                                            end
                                            if S.ESPDistance then
                                                label = label .. " [" .. math.floor(dist) .. "m]"
                                            end
                                            if S.ESPVisibilityCheck and S.ESPShowVisLabel then
                                                label = label .. (ent.visible and " • vis" or " • hid")
                                            end
                                            d.name.Text = label
                                            d.name.Position = Vector2.new(tS.X, labelY)
                                            d.name.Color = col
                                            labelY = labelY - 14
                                        else
                                            d.name.Visible = false
                                        end

                                        if S.ESPWeapon then
                                            local tool = char:FindFirstChildOfClass("Tool")
                                            if tool then
                                                d.weapon.Visible = true
                                                d.weapon.Text = "[" .. tool.Name .. "]"
                                                d.weapon.Position = Vector2.new(tS.X, labelY)
                                                d.weapon.Color = Color3.fromRGB(255, 220, 120)
                                            else
                                                d.weapon.Visible = false
                                            end
                                        else
                                            d.weapon.Visible = false
                                        end

                                        -- health bar
                                        if S.ESPHealth then
                                            local frac = 1
                                            if hum and hum.MaxHealth and hum.MaxHealth > 0 then
                                                frac = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                                            end
                                            local bh = hh * frac
                                            d.hpBg.Visible = true
                                            d.hpBg.Size = Vector2.new(3, hh)
                                            d.hpBg.Position = Vector2.new(x - 6, y)
                                            d.hp.Visible = true
                                            d.hp.Size = Vector2.new(3, bh)
                                            d.hp.Position = Vector2.new(x - 6, y + (hh - bh))
                                            d.hp.Color = Color3.fromRGB(230, 80, 100)
                                                :Lerp(Color3.fromRGB(80, 200, 130), frac)
                                        else
                                            d.hpBg.Visible = false
                                            d.hp.Visible = false
                                        end

                                        -- tracers
                                        if S.ESPTracers then
                                            local from
                                            if S.ESPTracerFrom == "Top" then
                                                from = Vector2.new(vp.X/2, 0)
                                            elseif S.ESPTracerFrom == "Mouse" then
                                                from = (NS.UIS or game:GetService("UserInputService")):GetMouseLocation()
                                            else
                                                from = Vector2.new(vp.X/2, vp.Y)
                                            end
                                            d.tracer.Visible = true
                                            d.tracer.From = from
                                            d.tracer.To = Vector2.new(tS.X, y + hh)
                                            d.tracer.Color = col
                                        else
                                            d.tracer.Visible = false
                                        end

                                        NS.ESPCache.update(ent, now)
                                    else
                                        hide(d)
                                    end
                                end

                                -- highlight (chams)
                                if S.ESPHighlight then
                                    ensureHighlight(d, char)
                                    if d.highlight then
                                        d.highlight.Enabled = true
                                        d.highlight.OutlineColor = col
                                        if S.ESPHighlightOccluded then
                                            d.highlight.DepthMode = Enum.HighlightDepthMode.Occluded
                                            d.highlight.FillColor = Color3.fromRGB(
                                                math.floor(col.R * 80),
                                                math.floor(col.G * 80),
                                                math.floor(col.B * 80))
                                            d.highlight.FillTransparency = 0.7
                                        else
                                            d.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                            d.highlight.FillColor = col
                                            d.highlight.FillTransparency = 0.6
                                        end
                                    end
                                elseif d.highlight then
                                    d.highlight.Enabled = false
                                end
                            end
                        end
                    else
                        local d = pool[char]
                        if d then hide(d) end
                    end
                end
            end
        end

        lastUpdate = now

        -- cleanup + hide disappeared
        for char, d in pairs(pool) do
            if not seen[char] then
                hide(d)
                if not char.Parent then
                    if d.highlight then pcall(function() d.highlight:Destroy() end) end
                    pcall(function() d.box:Remove() end)
                    pcall(function() d.name:Remove() end)
                    pcall(function() d.hpBg:Remove() end)
                    pcall(function() d.hp:Remove() end)
                    pcall(function() d.tracer:Remove() end)
                    pcall(function() d.weapon:Remove() end)
                    for i = 1, 4 do
                        pcall(function() d.corner[i]:Remove() end)
                    end
                    pool[char] = nil
                end
            end
        end
    end

    function M.start()
        NS.safeRender(render)
    end

    return M
end)()

return NS
