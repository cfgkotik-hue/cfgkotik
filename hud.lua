--!nocheck
-- cfgkotik v37 — HUD (logo, time, FPS, ping, target, entity count)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end
local UIS = NS.UIS or game:GetService("UserInputService")
local UIS = NS.UIS

NS.HUD = (function()
    local M = {}
    local sg, frame = nil, nil
    local parts = {}
    local fps = 0

    local style = {
        bg         = Color3.fromRGB(20,20,26),
        logo       = Color3.fromRGB(10,132,255),
        time       = Color3.fromRGB(240,240,245),
        fps        = Color3.fromRGB(80,200,130),
        ping       = Color3.fromRGB(255,189,46),
        target     = Color3.fromRGB(230,80,100),
        entities   = Color3.fromRGB(170,170,185),
    }

    -- ================== helpers ==================
    local function mskTime()
        local ok, t = pcall(function()
            return os.date("!%H:%M:%S", os.time() + 3*3600)
        end)
        return ok and t or "--:--:--"
    end

    local function makeCell(order, colorKey, default)
        local wrap = Instance.new("Frame")
        wrap.BackgroundTransparency = 1
        wrap.AutomaticSize = Enum.AutomaticSize.X
        wrap.Size = UDim2.new(0, 0, 1, 0)
        wrap.LayoutOrder = order
        wrap.Parent = frame

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.AutomaticSize = Enum.AutomaticSize.X
        lbl.Size = UDim2.new(0, 0, 1, 0)
        lbl.Text = default or ""
        lbl.TextColor3 = style[colorKey]
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Center
        lbl.Parent = wrap

        return lbl
    end

    local function makeSep(order)
        local s = Instance.new("TextLabel")
        s.BackgroundTransparency = 1
        s.AutomaticSize = Enum.AutomaticSize.X
        s.Size = UDim2.new(0, 0, 1, 0)
        s.Text = "|"
        s.TextColor3 = NS.UI.C.border
        s.Font = Enum.Font.Gotham
        s.TextSize = 11
        s.TextXAlignment = Enum.TextXAlignment.Center
        s.TextYAlignment = Enum.TextYAlignment.Center
        s.LayoutOrder = order
        s.Parent = frame
        return s
    end

    -- ================== create ==================
    local function createHud()
        sg = Instance.new("ScreenGui")
        sg.Name = "cfgkotik_hud"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        sg.DisplayOrder = 200
        NS.protectGui(sg)
        sg.Parent = NS.getParentGui()

        frame = Instance.new("Frame")
        frame.AutomaticSize = Enum.AutomaticSize.X
        frame.Size = UDim2.new(0, 0, 0, 24)
        frame.BackgroundColor3 = style.bg
        frame.BackgroundTransparency = 0.05
        frame.BorderSizePixel = 0
        frame.Active = true
        frame.Parent = sg
        NS.UI.corner(frame, 6)
        local fs = NS.UI.stroke(frame, NS.UI.C.accent, 1)

        local pad = Instance.new("UIPadding", frame)
        pad.PaddingLeft = UDim.new(0, 10)
        pad.PaddingRight = UDim.new(0, 10)

        local lay = Instance.new("UIListLayout", frame)
        lay.FillDirection = Enum.FillDirection.Horizontal
        lay.VerticalAlignment = Enum.VerticalAlignment.Center
        lay.Padding = UDim.new(0, 5)
        lay.SortOrder = Enum.SortOrder.LayoutOrder

        parts.logo   = makeCell(0,  "logo",     "cfgkotik")
        parts.logo.Font = Enum.Font.GothamBold
        parts.logo.TextSize = 12

        parts.sep1   = makeSep(1)
        parts.time   = makeCell(2,  "time",     "MSK --:--:--")
        parts.sep2   = makeSep(3)
        parts.fps    = makeCell(4,  "fps",      "FPS 0")
        parts.sep3   = makeSep(5)
        parts.ping   = makeCell(6,  "ping",     "Ping --")
        parts.sep4   = makeSep(7)
        parts.entities = makeCell(8, "entities", "целей: 0")
        parts.sep5   = makeSep(9)
        parts.target = makeCell(10, "target",   "цель: —")

        frame.Position = UDim2.new(0, 12, 0, 12)

        -- drag when menu open
        local drag, ds, sa = false, nil, nil
        frame.InputBegan:Connect(function(i)
            if i.UserInputType ~= Enum.UserInputType.MouseButton1
               and i.UserInputType ~= Enum.UserInputType.Touch then return end
            if not (NS.UI.window and NS.UI.window.main
                    and NS.UI.window.main.Visible) then return end
            drag = true
            ds = Vector2.new(i.Position.X, i.Position.Y)
            sa = frame.AbsolutePosition
        end)
        UIS.InputChanged:Connect(function(i)
            if not drag then return end
            if i.UserInputType ~= Enum.UserInputType.MouseMovement
               and i.UserInputType ~= Enum.UserInputType.Touch then return end
            local d = Vector2.new(i.Position.X, i.Position.Y) - ds
            local cam = NS.Workspace.CurrentCamera
            local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
            local fw, fh = frame.AbsoluteSize.X, frame.AbsoluteSize.Y
            frame.Position = UDim2.new(0,
                math.clamp(sa.X + d.X, 0, math.max(0, vp.X - fw)),
                0, math.clamp(sa.Y + d.Y, 0, math.max(0, vp.Y - fh)))
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
               or i.UserInputType == Enum.UserInputType.Touch then
                drag = false
            end
        end)
    end

    -- ================== colors ==================
    function M.applyColors()
        if not frame then return end
        local S = NS.Settings
        style.bg       = S.HudBgColor       or style.bg
        style.logo     = S.HudLogoColor     or style.logo
        style.time     = S.HudTimeColor     or style.time
        style.fps      = S.HudFpsColor      or style.fps
        style.ping     = S.HudPingColor     or style.ping
        style.target   = S.HudTargetColor   or style.target
        style.entities = S.HudEntitiesColor or style.entities

        frame.BackgroundColor3 = style.bg
        if parts.logo     then parts.logo.TextColor3     = style.logo     end
        if parts.time     then parts.time.TextColor3     = style.time     end
        if parts.fps      then parts.fps.TextColor3      = style.fps      end
        if parts.ping     then parts.ping.TextColor3     = style.ping     end
        if parts.target   then parts.target.TextColor3   = style.target   end
        if parts.entities then parts.entities.TextColor3 = style.entities end
    end

    -- ================== visibility ==================
    local function applyVisibility()
        if not frame then return end
        local S = NS.Settings
        parts.logo.Visible     = S.HudShowLogo
        parts.time.Visible     = S.HudShowTime
        parts.fps.Visible      = S.HudShowFps
        parts.ping.Visible     = S.HudShowPing
        parts.target.Visible   = S.HudShowTarget
        parts.entities.Visible = S.HudShowEntities

        parts.sep1.Visible = S.HudShowLogo
        parts.sep2.Visible = S.HudShowTime
        parts.sep3.Visible = S.HudShowFps
        parts.sep4.Visible = S.HudShowPing
        parts.sep5.Visible = S.HudShowTarget and S.HudShowEntities
    end

    -- ================== fps counter ==================
    local function startFpsCounter()
        local frames = 0
        local last = os.clock()
        NS.safeRender(function()
            frames = frames + 1
            local now = os.clock()
            if now - last >= 1 then
                fps = frames
                frames = 0
                last = now
            end
        end)
    end

    -- ================== update loop ==================
    local function startUpdate()
        task.spawn(function()
            while task.wait(0.25) do
                if not sg or not sg.Parent then break end
                local S = NS.Settings

                parts.time.Text = "MSK " .. mskTime()

                -- fps cell
                if S.HudShowCombatStats then
                    local hist = S.TargetHistory or {}
                    local locked = 0
                    for _, e in ipairs(hist) do
                        if e.result == "locked" then locked = locked + 1 end
                    end
                    local rate = #hist > 0 and math.floor(locked / #hist * 100) or 0
                    parts.fps.Text = string.format("FPS %d | Lock %d%%", fps, rate)
                else
                    parts.fps.Text = "FPS " .. tostring(fps)
                end

                parts.ping.Text = "Ping " ..
                    tostring(math.floor((NS.getPing() or 0) * 1000)) .. "ms"

                parts.entities.Text = "целей: " ..
                    tostring(NS.Scanner and NS.Scanner.count() or 0)

                local name = NS.Aimbot
                    and NS.Aimbot.getTargetName
                    and NS.Aimbot.getTargetName()
                parts.target.Text = "цель: " .. (name or "—")

                applyVisibility()
                M.applyColors()
            end
        end)
    end

    -- ================== public ==================
    function M.getFps() return fps end

    function M.start()
        createHud()
        startFpsCounter()
        M.applyColors()
        applyVisibility()
        startUpdate()
    end

    return M
end)()

return NS
