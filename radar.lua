--!nocheck
-- cfgkotik v37 — Radar (top-down minimap with entity dots)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

NS.Radar = (function()
    local M = {}
    local frame, selfDot = nil, nil
    local dots = {}
    local cachedCorner, cachedSize, cachedPos, lastVp = nil, nil, nil, nil

    -- ================== corner ==================
    local function computeCorner()
        local cam = NS.Workspace.CurrentCamera
        if not cam then return Vector2.new(0, 0) end
        local vp = cam.ViewportSize
        local S = NS.Settings
        local size = S.RadarSize or 180
        local pos  = S.RadarPosition or "TopRight"
        local m = 20
        if pos == "TopRight" then
            return Vector2.new(vp.X - size - m, m)
        elseif pos == "TopLeft" then
            return Vector2.new(m, m)
        elseif pos == "BottomRight" then
            return Vector2.new(vp.X - size - m, vp.Y - size - m)
        else
            return Vector2.new(m, vp.Y - size - m)
        end
    end

    local function getCachedCorner()
        local cam = NS.Workspace.CurrentCamera
        if not cam then return Vector2.new(0, 0) end
        local vp = cam.ViewportSize
        local S = NS.Settings
        local size = S.RadarSize or 180
        local pos  = S.RadarPosition or "TopRight"

        if cachedCorner and cachedSize == size and cachedPos == pos
           and lastVp and (lastVp - vp).Magnitude < 1 then
            return cachedCorner
        end

        cachedCorner = computeCorner()
        cachedSize = size
        cachedPos = pos
        lastVp = vp
        return cachedCorner
    end

    -- ================== render ==================
    local function render()
        local S = NS.Settings

        if not S.RadarEnabled then
            if frame then frame.Visible = false end
            if selfDot then selfDot.Visible = false end
            for _, d in pairs(dots) do d.Visible = false end
            return
        end

        local cam = NS.Workspace.CurrentCamera
        if not cam then return end

        local size   = S.RadarSize or 180
        local corner = getCachedCorner()
        local center = Vector2.new(corner.X + size/2, corner.Y + size/2)
        local scale  = S.RadarScale or 0.7

        -- frame
        if not frame then
            frame = Drawing.new("Square")
            frame.Filled = false
            frame.Thickness = 2
            frame.Color = NS.UI.C.border
        end
        frame.Visible = true
        frame.Size = Vector2.new(size, size)
        frame.Position = corner

        -- self dot
        if not selfDot then
            selfDot = Drawing.new("Circle")
            selfDot.Radius = 3
            selfDot.Filled = true
            selfDot.NumSides = 8
            selfDot.Color = Color3.fromRGB(255, 255, 255)
        end
        selfDot.Visible = true
        selfDot.Position = center

        local lpChar = NS.LP.Character
        if not lpChar then return end
        local lpRoot = lpChar:FindFirstChild("HumanoidRootPart")
        if not lpRoot then return end
        local lpPos = lpRoot.Position

        local entities = NS.Scanner.getEntities()
        local seen = {}
        local range = S.RadarRange or 300

        for _, e in ipairs(entities) do
            local show = false
            if e.isPlayer and S.RadarShowPlayers then
                show = true
            elseif (not e.isPlayer) and S.RadarShowNPCs then
                show = true
            end

            if show and e.root then
                local off = e.root.Position - lpPos
                local d2 = Vector2.new(off.X, off.Z).Magnitude
                if d2 <= range then
                    seen[e] = true
                    local dot = dots[e]
                    if not dot then
                        dot = Drawing.new("Circle")
                        dot.Radius = 3
                        dot.Filled = true
                        dot.NumSides = 8
                        dots[e] = dot
                    end
                    dot.Visible = true
                    dot.Position = Vector2.new(
                        center.X + off.X * scale,
                        center.Y + off.Z * scale)

                    if e.isPlayer then
                        local sameTeam = false
                        if NS.LP.Team and e.player
                           and e.player.Team == NS.LP.Team then
                            sameTeam = true
                        end
                        if sameTeam then
                            dot.Color = Color3.fromRGB(80, 200, 130)
                        else
                            dot.Color = S.RadarPlayerColor
                                      or Color3.fromRGB(230, 80, 100)
                        end
                    else
                        dot.Color = S.RadarNPCColor
                                  or Color3.fromRGB(255, 200, 60)
                    end
                end
            end
        end

        -- cleanup hidden / destroyed
        for e, dot in pairs(dots) do
            if not seen[e] then
                dot.Visible = false
                if not e.model or not e.model.Parent then
                    pcall(function() dot:Remove() end)
                    dots[e] = nil
                end
            end
        end
    end

    -- ================== public ==================
    function M.start()
        NS.safeRender(render)
    end

    return M
end)()

return NS
