--!nocheck
-- cfgkotik v37 — Bind Strip + Bind System (getKey / getMode / isBindActive)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

local UIS = NS.UIS
local TW  = NS.Tween

-- ================== bind state (shared) ==================
local BindList = NS.BindList or {
    { id="AimKey",     label="Aim Key",     icon="🎯", short="A" },
    { id="FovExpand",  label="FOV Expand",  icon="🔭", short="F" },
    { id="Trigger",    label="Trigger Bot", icon="⚡", short="T" },
    { id="Hitbox",     label="Hitbox",      icon="📦", short="H" },
    { id="Visibility", label="Visibility",  icon="👁", short="V" },
    { id="Speed",      label="SpeedHack",   icon="💨", short="S" },
    { id="Fly",        label="Fly",         icon="🕊", short="Y" },
}
NS.BindList = BindList

local BindStates = {}
for _, b in ipairs(BindList) do
    BindStates[b.id] = { down = false, toggle = false }
end

local function ensure(id)
    if not BindStates[id] then
        BindStates[id] = { down = false, toggle = false }
    end
    return BindStates[id]
end

function NS.getBindKey(id)
    return NS.Settings["Bind"..id.."Key"]
end

function NS.getBindMode(id)
    return NS.Settings["Bind"..id.."Mode"] or "Toggle"
end

function NS.setBindKey(id, v)
    NS.Settings["Bind"..id.."Key"] = v
    BindStates[id] = { down = false, toggle = false }
end

function NS.setBindMode(id, v)
    NS.Settings["Bind"..id.."Mode"] = v
    BindStates[id] = { down = false, toggle = false }
end

function NS.isBindActive(id)
    local s = BindStates[id]
    if not s then return false end
    if NS.getBindMode(id) == "Hold" then return s.down == true end
    return s.toggle == true
end

function NS.anyBindBound()
    for _, b in ipairs(BindList) do
        if NS.getBindKey(b.id) then return true end
    end
    return false
end

-- ================== strip ==================
NS.BindStrip = (function()
    local M = {}
    local sg, strip = nil, nil
    local dots = {}

    -- ================== helpers ==================
    local function labelFor(entry)
        local mode = NS.Settings.BindStripLabel or "short"
        if mode == "short" then return entry.short end
        if mode == "icon"  then return entry.icon end
        if mode == "none"  then return "" end
        return entry.label
    end

    local function computePreset(preset)
        local cam = NS.Workspace.CurrentCamera
        if not cam then return Vector2.new(486, 680) end
        local vp = cam.ViewportSize
        local S = NS.Settings
        local w = (strip and strip.AbsoluteSize.X) or 120
        local h = (strip and strip.AbsoluteSize.Y) or ((S.BindStripSize or 14) + 12)
        if w <= 0 then w = 120 end
        if h <= 0 then h = (S.BindStripSize or 14) + 12 end
        local m = 12
        if preset == "Top Center" then
            return Vector2.new(vp.X/2 - w/2, m)
        elseif preset == "Bottom Center" then
            return Vector2.new(vp.X/2 - w/2, vp.Y - h - m)
        elseif preset == "Top Left" then
            return Vector2.new(m, m)
        elseif preset == "Top Right" then
            return Vector2.new(vp.X - w - m, m)
        elseif preset == "Bottom Left" then
            return Vector2.new(m, vp.Y - h - m)
        elseif preset == "Bottom Right" then
            return Vector2.new(vp.X - w - m, vp.Y - h - m)
        else
            return Vector2.new(S.BindStripX or 486, S.BindStripY or 680)
        end
    end

    function M.applyPreset()
        if not strip then return end
        local S = NS.Settings
        if S.BindStripPosition and S.BindStripPosition ~= "Custom" then
            local p = computePreset(S.BindStripPosition)
            S.BindStripX = p.X
            S.BindStripY = p.Y
            strip.Position = UDim2.new(0, p.X, 0, p.Y)
        else
            strip.Position = UDim2.new(0, S.BindStripX or 486, 0, S.BindStripY or 680)
        end
    end

    -- ================== create ==================
    local function create()
        sg = Instance.new("ScreenGui")
        sg.Name = "cfgkotik_bindstrip"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        sg.DisplayOrder = 190
        NS.protectGui(sg)
        sg.Parent = NS.getParentGui()

        strip = Instance.new("Frame")
        strip.AutomaticSize = Enum.AutomaticSize.X
        local sz = NS.Settings.BindStripSize or 14
        strip.Size = UDim2.new(0, 0, 0, sz + 12)
        strip.Position = UDim2.new(0, NS.Settings.BindStripX or 486,
                                   0, NS.Settings.BindStripY or 680)
        strip.BackgroundColor3 = NS.UI.C.bg
        strip.BackgroundTransparency = 0.25
        strip.BorderSizePixel = 0
        strip.Active = true
        strip.Parent = sg

        NS.UI.corner(strip, 8)
        NS.UI.stroke(strip, NS.UI.C.border, 1)

        local pad = Instance.new("UIPadding", strip)
        pad.PaddingTop    = UDim.new(0, 4)
        pad.PaddingBottom = UDim.new(0, 4)
        pad.PaddingLeft   = UDim.new(0, 6)
        pad.PaddingRight  = UDim.new(0, 6)

        local lay = Instance.new("UIListLayout", strip)
        lay.FillDirection = Enum.FillDirection.Horizontal
        lay.Padding = UDim.new(0, 4)
        lay.VerticalAlignment = Enum.VerticalAlignment.Center
        lay.SortOrder = Enum.SortOrder.LayoutOrder

        -- drag
        local drag, ds, sa = false, nil, nil
        strip.InputBegan:Connect(function(i)
            if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if not (NS.UI.window and NS.UI.window.main
                    and NS.UI.window.main.Visible) then return end
            drag = true
            ds = Vector2.new(i.Position.X, i.Position.Y)
            sa = strip.AbsolutePosition
        end)
        UIS.InputChanged:Connect(function(i)
            if not drag then return end
            if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
            local d = Vector2.new(i.Position.X, i.Position.Y) - ds
            local cam = NS.Workspace.CurrentCamera
            local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
            local fw, fh = strip.AbsoluteSize.X, strip.AbsoluteSize.Y
            local nx = math.clamp(sa.X + d.X, 0, math.max(0, vp.X - fw))
            local ny = math.clamp(sa.Y + d.Y, 0, math.max(0, vp.Y - fh))
            strip.Position = UDim2.new(0, nx, 0, ny)
            NS.Settings.BindStripX = nx
            NS.Settings.BindStripY = ny
            NS.Settings.BindStripPosition = "Custom"
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                drag = false
            end
        end)
    end

    -- ================== dots ==================
    local function makeDot(entry, order)
        local sz = NS.Settings.BindStripSize or 14
        local dot = Instance.new("TextButton")
        dot.Size = UDim2.fromOffset(sz, sz)
        dot.BackgroundColor3 = NS.UI.C.card
        dot.Text = labelFor(entry)
        dot.TextColor3 = NS.UI.C.subtext
        dot.Font = Enum.Font.GothamBold
        dot.TextSize = sz <= 12 and 8 or (sz <= 16 and 9 or 10)
        dot.BorderSizePixel = 0
        dot.LayoutOrder = order
        dot.AutoButtonColor = false
        dot.Parent = strip
        NS.UI.corner(dot, 4)
        local st = NS.UI.stroke(dot, NS.UI.C.border, 1)

        local function refresh()
            local bound = NS.getBindKey(entry.id) ~= nil
            local active = NS.isBindActive(entry.id)
            dot.Visible = bound
            dot.Text = labelFor(entry)
            if active then
                dot.BackgroundColor3 = NS.UI.C.green
                dot.TextColor3 = Color3.fromRGB(10,10,14)
                st.Color = NS.UI.C.green
            else
                dot.BackgroundColor3 = NS.UI.C.card
                dot.TextColor3 = NS.UI.C.subtext
                st.Color = NS.UI.C.border
            end
        end

        -- click toggle for toggle-mode binds
        dot.MouseButton1Click:Connect(function()
            if not NS.getBindKey(entry.id) then return end
            local mode = NS.getBindMode(entry.id)
            local s = ensure(entry.id)
            if mode == "Toggle" then
                s.toggle = not s.toggle
            end
            refresh()
        end)

        dots[entry.id] = { dot = dot, st = st, refresh = refresh }
        refresh()
    end

    function M.rebuild()
        if not strip then return end
        for _, d in pairs(dots) do
            pcall(function() d.dot:Destroy() end)
        end
        dots = {}
        local sz = NS.Settings.BindStripSize or 14
        strip.Size = UDim2.new(0, 0, 0, sz + 12)
        local order = 1
        for _, entry in ipairs(BindList) do
            makeDot(entry, order)
            order = order + 1
        end
        M.applyPreset()
    end

    -- ================== start ==================
    function M.start()
        create()
        M.rebuild()

        task.spawn(function()
            local lastLabel  = NS.Settings.BindStripLabel
            local lastSize   = NS.Settings.BindStripSize
            local lastPreset = NS.Settings.BindStripPosition
            local lastVp     = nil

            while sg and sg.Parent do
                local cam = NS.Workspace.CurrentCamera
                local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
                local S = NS.Settings

                -- preset follow
                if S.BindStripPosition ~= "Custom" then
                    if S.BindStripPosition ~= lastPreset
                       or (lastVp and (vp - lastVp).Magnitude > 1) then
                        M.applyPreset()
                        lastPreset = S.BindStripPosition
                        lastVp = vp
                    end
                else
                    strip.Position = UDim2.new(0, S.BindStripX or 486,
                                               0, S.BindStripY or 680)
                    lastPreset = "Custom"
                end

                strip.Visible = S.BindStripEnabled and NS.anyBindBound()

                if S.BindStripLabel ~= lastLabel or S.BindStripSize ~= lastSize then
                    lastLabel = S.BindStripLabel
                    lastSize = S.BindStripSize
                    M.rebuild()
                end

                if strip.Visible then
                    for _, d in pairs(dots) do pcall(d.refresh) end
                end

                task.wait(0.1)
            end
        end)
    end

    return M
end)()

return NS
