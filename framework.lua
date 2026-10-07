--!nocheck
-- cfgkotik v37 — Framework (window, folder grid, controls)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

local UIS = NS.UIS or game:GetService("UserInputService")
local TW  = game:GetService("TweenService")

local UI = {}
UI.elements = {}
UI.listening = false
UI._activePicker = nil
UI._notifyHolder = nil
UI.window = nil
UI.C = {
    bg=Color3.fromRGB(14,14,18), card=Color3.fromRGB(22,22,28),
    sidebar=Color3.fromRGB(10,10,14), border=Color3.fromRGB(40,40,50),
    text=Color3.fromRGB(235,235,245), subtext=Color3.fromRGB(130,130,150),
    accent=Color3.fromRGB(0,170,255), danger=Color3.fromRGB(255,70,60),
    track=Color3.fromRGB(44,44,54), green=Color3.fromRGB(60,210,120),
    yellow=Color3.fromRGB(255,190,60), popupBg=Color3.fromRGB(12,12,16),
    cardHover=Color3.fromRGB(30,30,40),
}
NS.UI = UI
local C = UI.C

-- ================== primitives ==================
local function corner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = UDim.new(0, r or 6)
    return c
end
local function stroke(p, col, th)
    local s = Instance.new("UIStroke", p)
    s.Color = col or C.border
    s.Thickness = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s
end
UI.corner = corner
UI.stroke = stroke

-- ================== window ==================
function UI.createWindow()
    local sg = Instance.new("ScreenGui")
    sg.Name = "cfgkotik_ui"; sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true; sg.DisplayOrder = 100
    NS.protectGui(sg); sg.Parent = NS.getParentGui()

    local main = Instance.new("Frame")
    main.Name = "main"
    main.Size = UDim2.new(0,740,0,500)
    main.Position = UDim2.new(0.5,-370,0.5,-250)
    main.BackgroundColor3 = C.bg; main.BorderSizePixel = 0
    main.Active = true; main.Parent = sg
    main.ClipsDescendants = true
    corner(main, 12); stroke(main, C.border, 1)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1,0,0,38); bar.BackgroundColor3 = C.bg
    bar.BorderSizePixel = 0; bar.Parent = main; corner(bar, 12)

    local glow = Instance.new("Frame")
    glow.Name = "accentGlow"
    glow.Size = UDim2.new(1,0,0,1); glow.Position = UDim2.new(0,0,0,37)
    glow.BackgroundColor3 = C.accent; glow.BorderSizePixel = 0
    glow.BackgroundTransparency = 0.5; glow.Parent = main
    local ag = Instance.new("UIGradient", glow)
    ag.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,1),
        NumberSequenceKeypoint.new(0.5,0),
        NumberSequenceKeypoint.new(1,1),
    })

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0,11,0,11); close.Position = UDim2.new(0,18,0.5,-5.5)
    close.BackgroundColor3 = C.danger; close.Text = ""
    close.BorderSizePixel = 0; close.Parent = bar; corner(close, 6)

    local minBtn = Instance.new("Frame")
    minBtn.Size = UDim2.new(0,11,0,11); minBtn.Position = UDim2.new(0,36,0.5,-5.5)
    minBtn.BackgroundColor3 = Color3.fromRGB(255,189,46)
    minBtn.BorderSizePixel = 0; minBtn.Parent = bar; corner(minBtn, 6)

    local maxBtn = Instance.new("Frame")
    maxBtn.Size = UDim2.new(0,11,0,11); maxBtn.Position = UDim2.new(0,54,0.5,-5.5)
    maxBtn.BackgroundColor3 = Color3.fromRGB(39,201,63)
    maxBtn.BorderSizePixel = 0; maxBtn.Parent = bar; corner(maxBtn, 6)

    local brand = Instance.new("TextLabel")
    brand.Size = UDim2.new(0,200,1,0); brand.Position = UDim2.new(0,80,0,0)
    brand.BackgroundTransparency = 1; brand.Text = "CFGKOTIK"
    brand.TextColor3 = C.text; brand.Font = Enum.Font.GothamBlack
    brand.TextSize = 13; brand.TextXAlignment = Enum.TextXAlignment.Left
    brand.Parent = bar

    local ver = Instance.new("TextLabel")
    ver.Size = UDim2.new(0,80,1,0); ver.Position = UDim2.new(0,180,0,0)
    ver.BackgroundTransparency = 1; ver.Text = "v37 FINAL"
    ver.TextColor3 = C.accent; ver.Font = Enum.Font.GothamBold
    ver.TextSize = 10; ver.TextXAlignment = Enum.TextXAlignment.Left
    ver.Parent = bar

    local back = Instance.new("TextButton")
    back.Name = "backBtn"
    back.Size = UDim2.new(0,100,0,22); back.Position = UDim2.new(0,260,0.5,-11)
    back.BackgroundColor3 = C.card; back.Text = "← Folders"
    back.TextColor3 = C.text; back.Font = Enum.Font.GothamBold
    back.TextSize = 11; back.BorderSizePixel = 0
    back.Visible = false; back.Parent = bar
    corner(back, 5); stroke(back, C.border, 1)

    local statusDot = Instance.new("Frame")
    statusDot.Size = UDim2.new(0,6,0,6); statusDot.Position = UDim2.new(1,-24,0.5,-3)
    statusDot.BackgroundColor3 = C.green; statusDot.BorderSizePixel = 0
    statusDot.Parent = bar; corner(statusDot, 3)

    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(0,110,1,0); statusLbl.Position = UDim2.new(1,-140,0,0)
    statusLbl.BackgroundTransparency = 1; statusLbl.Text = "online"
    statusLbl.TextColor3 = C.subtext; statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 10
    statusLbl.TextXAlignment = Enum.TextXAlignment.Right
    statusLbl.Parent = bar

    -- drag
    local dragging, ds, sa = false, nil, nil
    bar.InputBegan:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton1
           and i.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true
        ds = Vector2.new(i.Position.X, i.Position.Y)
        sa = main.AbsolutePosition
    end)
    UIS.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType ~= Enum.UserInputType.MouseMovement
           and i.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = Vector2.new(i.Position.X, i.Position.Y) - ds
        main.Position = UDim2.new(0, sa.X + d.X, 0, sa.Y + d.Y)
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
           or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- content container
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1,0,1,-40); content.Position = UDim2.new(0,0,0,40)
    content.BackgroundTransparency = 1; content.Parent = main

    -- home folder grid
    local home = Instance.new("ScrollingFrame")
    home.Name = "home"
    home.Size = UDim2.new(1,-20,1,-10); home.Position = UDim2.new(0,10,0,5)
    home.BackgroundTransparency = 1; home.BorderSizePixel = 0
    home.ScrollBarThickness = 4; home.ScrollBarImageColor3 = C.accent
    home.CanvasSize = UDim2.new(0,0,0,0)
    home.AutomaticCanvasSize = Enum.AutomaticSize.Y
    home.Parent = content
    local hg = Instance.new("UIGridLayout", home)
    hg.CellSize = UDim2.new(0,340,0,130)
    hg.CellPadding = UDim2.new(0,10,0,10)
    hg.SortOrder = Enum.SortOrder.LayoutOrder
    hg.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local hp = Instance.new("UIPadding", home)
    hp.PaddingTop = UDim.new(0,8); hp.PaddingBottom = UDim.new(0,20)

    local pages = {}
    local current = nil

    local function goHome()
        for _, p in ipairs(pages) do p.Visible = false end
        home.Visible = true; back.Visible = false; current = nil
    end
    local function openPage(p)
        for _, pp in ipairs(pages) do pp.Visible = false end
        home.Visible = false; p.Visible = true; back.Visible = true; current = p
    end
    back.MouseButton1Click:Connect(goHome)

    local win = { main=main, sg=sg, verLabel=ver, _pages=pages }
    function win:toggle()
        main.Visible = not main.Visible
        if main.Visible then goHome() end
    end
    win._goHome = goHome
    close.MouseButton1Click:Connect(function() win:toggle() end)

    -- folder card factory
    local order = 0
    function win:makeTab(name, icon, desc)
        order = order + 1

        local card = Instance.new("TextButton")
        card.Name = "folder_"..name
        card.BackgroundColor3 = C.card
        card.Text = ""
        card.BorderSizePixel = 0
        card.AutoButtonColor = false
        card.LayoutOrder = order
        card.Parent = home
        corner(card, 10); stroke(card, C.border, 1)

        local iL = Instance.new("TextLabel")
        iL.Size = UDim2.new(1,0,0,50); iL.Position = UDim2.new(0,0,0,15)
        iL.BackgroundTransparency = 1; iL.Text = icon or "📁"
        iL.TextColor3 = C.accent; iL.Font = Enum.Font.GothamBold
        iL.TextSize = 34; iL.Parent = card

        local nL = Instance.new("TextLabel")
        nL.Size = UDim2.new(1,-20,0,22); nL.Position = UDim2.new(0,10,0,70)
        nL.BackgroundTransparency = 1; nL.Text = name
        nL.TextColor3 = C.text; nL.Font = Enum.Font.GothamBold
        nL.TextSize = 15; nL.TextXAlignment = Enum.TextXAlignment.Center
        nL.Parent = card

        local dL = Instance.new("TextLabel")
        dL.Size = UDim2.new(1,-20,0,18); dL.Position = UDim2.new(0,10,0,94)
        dL.BackgroundTransparency = 1; dL.Text = desc or ""
        dL.TextColor3 = C.subtext; dL.Font = Enum.Font.Gotham
        dL.TextSize = 10; dL.TextXAlignment = Enum.TextXAlignment.Center
        dL.TextWrapped = true; dL.Parent = card

        local page = Instance.new("ScrollingFrame")
        page.Name = "page_"..name
        page.Size = UDim2.new(1,-20,1,-10); page.Position = UDim2.new(0,10,0,5)
        page.BackgroundTransparency = 1; page.BorderSizePixel = 0
        page.ScrollBarThickness = 4; page.ScrollBarImageColor3 = C.accent
        page.CanvasSize = UDim2.new(0,0,0,0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false; page.Parent = content
        local lay = Instance.new("UIListLayout", page)
        lay.Padding = UDim.new(0,10); lay.SortOrder = Enum.SortOrder.LayoutOrder
        local pad = Instance.new("UIPadding", page)
        pad.PaddingTop = UDim.new(0,8); pad.PaddingBottom = UDim.new(0,20)
        pages[#pages+1] = page

        card.MouseButton1Click:Connect(function() openPage(page) end)
        card.MouseEnter:Connect(function()
            TW:Create(card, TweenInfo.new(0.12), {BackgroundColor3 = C.cardHover}):Play()
        end)
        card.MouseLeave:Connect(function()
            TW:Create(card, TweenInfo.new(0.12), {BackgroundColor3 = C.card}):Play()
        end)

        return page
    end

    UI.window = win
    return win
end

-- ================== section ==================
function UI.section(parent, title)
    local card = Instance.new("Frame")
    card.BackgroundColor3 = C.card; card.BorderSizePixel = 0
    card.Size = UDim2.new(1,-8,0,60); card.Parent = parent
    corner(card, 8); stroke(card, C.border, 1)

    local pad = Instance.new("UIPadding", card)
    pad.PaddingTop = UDim.new(0,12); pad.PaddingBottom = UDim.new(0,12)
    pad.PaddingLeft = UDim.new(0,14); pad.PaddingRight = UDim.new(0,14)

    local lay = Instance.new("UIListLayout", card)
    lay.Padding = UDim.new(0,6); lay.SortOrder = Enum.SortOrder.LayoutOrder

    if title then
        local hdr = Instance.new("Frame")
        hdr.Size = UDim2.new(1,0,0,16); hdr.BackgroundTransparency = 1
        hdr.LayoutOrder = 0; hdr.Parent = card
        local acc = Instance.new("Frame")
        acc.Size = UDim2.new(0,3,0,10); acc.Position = UDim2.new(0,0,0.5,-5)
        acc.BackgroundColor3 = C.accent; acc.BorderSizePixel = 0
        acc.Parent = hdr; corner(acc, 2)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1,-12,1,0); l.Position = UDim2.new(0,10,0,0)
        l.BackgroundTransparency = 1; l.Text = title
        l.TextColor3 = C.text; l.Font = Enum.Font.GothamBold
        l.TextSize = 10; l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = hdr
    end

    local function resize()
        local h = lay.AbsoluteContentSize.Y + 24
        if h < 40 then h = 40 end
        card.Size = UDim2.new(1,-8,0,h)
    end
    lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
    task.defer(resize)
    return card
end

-- ================== toggle ==================
function UI.toggle(parent, label, key, onChange)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,26); row.BackgroundTransparency = 1; row.Parent = parent
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1; l.Size = UDim2.new(1,-50,1,0); l.Text = label
    l.TextColor3 = C.text; l.Font = Enum.Font.Gotham; l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = row
    local tr = Instance.new("TextButton")
    tr.Size = UDim2.new(0,36,0,20); tr.Position = UDim2.new(1,-36,0.5,-10)
    tr.BackgroundColor3 = C.track; tr.Text = ""; tr.BorderSizePixel = 0
    tr.Parent = row; corner(tr, 10)
    local kn = Instance.new("Frame")
    kn.Size = UDim2.new(0,16,0,16); kn.Position = UDim2.new(0,2,0.5,-8)
    kn.BackgroundColor3 = Color3.fromRGB(255,255,255); kn.BorderSizePixel = 0
    kn.Parent = tr; corner(kn, 8)

    local function paint(anim)
        local on = NS.Settings[key] and true or false
        tr.BackgroundColor3 = on and C.accent or C.track
        local tgt = on and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
        if anim then
            TW:Create(kn, TweenInfo.new(0.15), {Position = tgt}):Play()
        else
            kn.Position = tgt
        end
    end
    tr.MouseButton1Click:Connect(function()
        NS.Settings[key] = not NS.Settings[key]
        paint(true)
        if onChange then pcall(onChange, NS.Settings[key]) end
    end)
    UI.elements[#UI.elements+1] = { key=key, paint=function() paint(false) end }
    paint(false)
    return row
end

-- ================== slider ==================
function UI.slider(parent, label, key, minVal, maxVal, step, fmt)
    fmt = fmt or function(v) return string.format("%.2f", v) end
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,42); row.BackgroundTransparency = 1; row.Parent = parent

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-60,0,16); l.BackgroundTransparency = 1; l.Text = label
    l.TextColor3 = C.text; l.Font = Enum.Font.Gotham; l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = row

    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(0,60,0,16); v.Position = UDim2.new(1,-60,0,0)
    v.BackgroundTransparency = 1; v.TextColor3 = C.accent
    v.Font = Enum.Font.GothamBold; v.TextSize = 11
    v.TextXAlignment = Enum.TextXAlignment.Right; v.Parent = row

    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1,0,0,18); hit.Position = UDim2.new(0,0,0,22)
    hit.BackgroundTransparency = 1; hit.Text = ""; hit.BorderSizePixel = 0
    hit.Parent = row

    local tr = Instance.new("Frame")
    tr.Size = UDim2.new(1,0,0,4); tr.Position = UDim2.new(0,0,0.5,-2)
    tr.BackgroundColor3 = C.track; tr.BorderSizePixel = 0; tr.Parent = hit
    corner(tr, 2)

    local fl = Instance.new("Frame")
    fl.Size = UDim2.new(0,0,1,0); fl.BackgroundColor3 = C.accent
    fl.BorderSizePixel = 0; fl.Parent = tr; corner(fl, 2)

    local kn = Instance.new("Frame")
    kn.Size = UDim2.new(0,12,0,12); kn.AnchorPoint = Vector2.new(0.5,0.5)
    kn.Position = UDim2.new(0,0,0.5,0)
    kn.BackgroundColor3 = Color3.fromRGB(255,255,255)
    kn.BorderSizePixel = 0; kn.ZIndex = 2; kn.Parent = tr; corner(kn, 6)

    local dragging = false
    local function apply(mx)
        local ap = tr.AbsolutePosition.X
        local asz = tr.AbsoluteSize.X
        if asz <= 0 then return end
        local t = math.clamp((mx - ap) / asz, 0, 1)
        local raw = minVal + (maxVal - minVal) * t
        raw = math.floor(raw / step + 0.5) * step
        raw = math.clamp(raw, minVal, maxVal)
        NS.Settings[key] = raw
        fl.Size = UDim2.new(t, 0, 1, 0)
        kn.Position = UDim2.new(t, 0, 0.5, 0)
        v.Text = fmt(raw)
    end

    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
           or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            apply(i.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType ~= Enum.UserInputType.MouseMovement
           and i.UserInputType ~= Enum.UserInputType.Touch then return end
        apply(i.Position.X)
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
           or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local function paint()
        local cur = NS.Settings[key] or minVal
        local t = math.clamp((cur - minVal) / (maxVal - minVal), 0, 1)
        fl.Size = UDim2.new(t, 0, 1, 0)
        kn.Position = UDim2.new(t, 0, 0.5, 0)
        v.Text = fmt(cur)
    end
    UI.elements[#UI.elements+1] = { key=key, paint=paint }
    task.defer(paint)
    return row
end

-- ================== dropdown ==================
function UI.dropdown(parent, label, key, options, onChange)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,26); row.BackgroundTransparency = 1; row.Parent = parent
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-110,1,0); l.BackgroundTransparency = 1; l.Text = label
    l.TextColor3 = C.text; l.Font = Enum.Font.Gotham; l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = row
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,100,0,20); btn.Position = UDim2.new(1,-100,0.5,-10)
    btn.BackgroundColor3 = C.track
    btn.Text = tostring(NS.Settings[key] or options[1])
    btn.TextColor3 = C.text; btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10; btn.BorderSizePixel = 0; btn.Parent = row; corner(btn, 5)

    local panelGui, panel
    local function close()
        if panelGui then panelGui:Destroy(); panelGui = nil end
        panel = nil
    end
    btn.MouseButton1Click:Connect(function()
        if panel then close(); return end
        panelGui = Instance.new("ScreenGui")
        panelGui.Name = "cfgkotik_dd"; panelGui.ResetOnSpawn = false
        panelGui.IgnoreGuiInset = true; panelGui.DisplayOrder = 500
        NS.protectGui(panelGui); panelGui.Parent = NS.getParentGui()
        panel = Instance.new("Frame")
        panel.Size = UDim2.new(0,140,0,#options*22+8)
        local abs = btn.AbsolutePosition
        local sz = btn.AbsoluteSize
        panel.Position = UDim2.new(0, abs.X, 0, abs.Y + sz.Y + 4)
        panel.BackgroundColor3 = C.popupBg; panel.BorderSizePixel = 0
        panel.Parent = panelGui; corner(panel, 6); stroke(panel, C.accent, 1)
        local lay = Instance.new("UIListLayout", panel)
        lay.Padding = UDim.new(0,2); lay.SortOrder = Enum.SortOrder.LayoutOrder
        local pad = Instance.new("UIPadding", panel)
        pad.PaddingTop = UDim.new(0,4); pad.PaddingBottom = UDim.new(0,4)
        pad.PaddingLeft = UDim.new(0,4); pad.PaddingRight = UDim.new(0,4)
        for _, opt in ipairs(options) do
            local ob = Instance.new("TextButton")
            ob.Size = UDim2.new(1,0,0,20); ob.BackgroundColor3 = C.popupBg
            ob.Text = tostring(opt); ob.TextColor3 = C.text
            ob.Font = Enum.Font.Gotham; ob.TextSize = 11
            ob.TextXAlignment = Enum.TextXAlignment.Left
            ob.BorderSizePixel = 0; ob.Parent = panel; corner(ob, 4)
            local op = Instance.new("UIPadding", ob); op.PaddingLeft = UDim.new(0,6)
            ob.MouseEnter:Connect(function() ob.BackgroundColor3 = C.accent end)
            ob.MouseLeave:Connect(function() ob.BackgroundColor3 = C.popupBg end)
            ob.MouseButton1Click:Connect(function()
                NS.Settings[key] = opt
                btn.Text = tostring(opt)
                if onChange then pcall(onChange, opt) end
                close()
            end)
        end
        task.delay(0.1, function()
            local conn
            conn = UIS.InputBegan:Connect(function(inp)
                if panel and inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    local mp = inp.Position
                    local pa = panel.AbsolutePosition
                    local ps = panel.AbsoluteSize
                    if not (mp.X >= pa.X and mp.X <= pa.X + ps.X
                        and mp.Y >= pa.Y and mp.Y <= pa.Y + ps.Y) then
                        close()
                        if conn then conn:Disconnect() end
                    end
                end
            end)
        end)
    end)
    UI.elements[#UI.elements+1] = { key=key, paint=function()
        btn.Text = tostring(NS.Settings[key] or options[1])
    end }
    return row
end

-- ================== multiSelect ==================
function UI.multiSelect(parent, label, key, options, onChange)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,26); row.BackgroundTransparency = 1; row.Parent = parent
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-110,1,0); l.BackgroundTransparency = 1; l.Text = label
    l.TextColor3 = C.text; l.Font = Enum.Font.Gotham; l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = row

    local function summary()
        local on = {}
        local S = NS.Settings[key] or {}
        for _, opt in ipairs(options) do
            if S[opt] then on[#on+1] = opt end
        end
        if #on == 0 then return "—" end
        if #on == #options then return "All" end
        return table.concat(on, ",")
    end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,110,0,20); btn.Position = UDim2.new(1,-110,0.5,-10)
    btn.BackgroundColor3 = C.track; btn.Text = summary()
    btn.TextColor3 = C.text; btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10; btn.BorderSizePixel = 0; btn.Parent = row; corner(btn, 5)

    local panelGui, panel
    btn.MouseButton1Click:Connect(function()
        if panel then panelGui:Destroy(); panelGui = nil; panel = nil; return end
        panelGui = Instance.new("ScreenGui")
        panelGui.Name = "cfgkotik_ms"; panelGui.ResetOnSpawn = false
        panelGui.IgnoreGuiInset = true; panelGui.DisplayOrder = 500
        NS.protectGui(panelGui); panelGui.Parent = NS.getParentGui()
        panel = Instance.new("Frame")
        panel.Size = UDim2.new(0,180,0,#options*24+8)
        local abs = btn.AbsolutePosition
        local sz = btn.AbsoluteSize
        panel.Position = UDim2.new(0, abs.X + sz.X - 180, 0, abs.Y + sz.Y + 4)
        panel.BackgroundColor3 = C.popupBg; panel.BorderSizePixel = 0
        panel.Parent = panelGui; corner(panel, 6); stroke(panel, C.accent, 1)
        local lay = Instance.new("UIListLayout", panel)
        lay.Padding = UDim.new(0,2); lay.SortOrder = Enum.SortOrder.LayoutOrder
        local pad = Instance.new("UIPadding", panel)
        pad.PaddingTop = UDim.new(0,4); pad.PaddingBottom = UDim.new(0,4)
        pad.PaddingLeft = UDim.new(0,4); pad.PaddingRight = UDim.new(0,4)
        for _, opt in ipairs(options) do
            local ob = Instance.new("TextButton")
            ob.Size = UDim2.new(1,0,0,20); ob.BackgroundColor3 = C.popupBg
            ob.TextColor3 = C.text; ob.Font = Enum.Font.Gotham
            ob.TextSize = 11; ob.TextXAlignment = Enum.TextXAlignment.Left
            ob.BorderSizePixel = 0; ob.Parent = panel; corner(ob, 4)
            local function refresh()
                NS.Settings[key] = NS.Settings[key] or {}
                local on = NS.Settings[key][opt]
                ob.Text = (on and "☑ " or "☐ ")..opt
                ob.TextColor3 = on and C.accent or C.text
            end
            refresh()
            local op = Instance.new("UIPadding", ob); op.PaddingLeft = UDim.new(0,8)
            ob.MouseEnter:Connect(function() ob.BackgroundColor3 = C.accent end)
            ob.MouseLeave:Connect(function() ob.BackgroundColor3 = C.popupBg end)
            ob.MouseButton1Click:Connect(function()
                NS.Settings[key] = NS.Settings[key] or {}
                NS.Settings[key][opt] = not NS.Settings[key][opt]
                refresh(); btn.Text = summary()
                if onChange then pcall(onChange, NS.Settings[key]) end
            end)
        end
    end)
    UI.elements[#UI.elements+1] = { key=key, paint=function()
        NS.Settings[key] = NS.Settings[key] or {}
        btn.Text = summary()
    end }
    return row
end

-- ================== keybind ==================
function UI.keybind(parent, label, key)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,26); row.BackgroundTransparency = 1; row.Parent = parent
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-130,1,0); l.BackgroundTransparency = 1; l.Text = label
    l.TextColor3 = C.text; l.Font = Enum.Font.Gotham; l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = row

    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(6,6)
    dot.AnchorPoint = Vector2.new(1,0.5)
    dot.Position = UDim2.new(1,-116,0.5,0)
    dot.BackgroundColor3 = C.track; dot.BorderSizePixel = 0
    dot.Parent = row; corner(dot, 3)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,100,0,20); btn.Position = UDim2.new(1,-100,0.5,-10)
    btn.BackgroundColor3 = C.track; btn.Text = NS.keyLabel(NS.Settings[key])
    btn.TextColor3 = C.text; btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10; btn.BorderSizePixel = 0; btn.Parent = row; corner(btn, 5)

    local function listen()
        if UI.listening then return end
        UI.listening = true
        btn.Text = "..."; btn.BackgroundColor3 = C.accent
        task.spawn(function()
            task.wait(0.05)
            if not UI.listening then return end
            local conn
            local function stop()
                if conn then conn:Disconnect(); conn = nil end
                UI.listening = false
                btn.Text = NS.keyLabel(NS.Settings[key])
                btn.BackgroundColor3 = C.track
            end
            conn = UIS.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    if input.KeyCode == Enum.KeyCode.Backspace then
                        NS.Settings[key] = nil; stop(); return
                    end
                    if NS.BLACKLISTED_KEYS[input.KeyCode] then return end
                    NS.Settings[key] = input.KeyCode
                elseif input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.MouseButton2
                    or input.UserInputType == Enum.UserInputType.MouseButton3 then
                    NS.Settings[key] = input.UserInputType
                else
                    return
                end
                stop()
            end)
        end)
    end
    btn.MouseButton1Click:Connect(listen)
    btn.MouseButton2Click:Connect(function()
        if UI.listening then return end
        NS.Settings[key] = nil
        btn.Text = NS.keyLabel(nil)
    end)

    UI.elements[#UI.elements+1] = { key=key, paint=function()
        if not UI.listening then btn.Text = NS.keyLabel(NS.Settings[key]) end
    end }

    task.spawn(function()
        while dot.Parent do
            dot.BackgroundColor3 = NS.isInputPressed(NS.Settings[key]) and C.green or C.track
            task.wait(0.05)
        end
    end)
    return row
end

-- ================== colorPalette (button -> picker) ==================
function UI.colorPalette(parent, label, key)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,26); row.BackgroundTransparency = 1; row.Parent = parent
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-40,1,0); l.BackgroundTransparency = 1; l.Text = label
    l.TextColor3 = C.text; l.Font = Enum.Font.Gotham; l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,28,0,20); btn.Position = UDim2.new(1,-28,0.5,-10)
    btn.BackgroundColor3 = NS.Settings[key] or Color3.fromRGB(255,255,255)
    btn.Text = ""; btn.BorderSizePixel = 0; btn.AutoButtonColor = false
    btn.Parent = row; corner(btn, 5); stroke(btn, C.border, 1)

    btn.MouseButton1Click:Connect(function()
        if UI._activePicker then
            pcall(function() UI._activePicker:Destroy() end)
            UI._activePicker = nil
        end
        if UI.openColorPicker then
            UI._activePicker = UI.openColorPicker(
                NS.Settings[key] or Color3.fromRGB(255,255,255),
                function(col)
                    NS.Settings[key] = col
                    btn.BackgroundColor3 = col
                end)
        end
    end)
    UI.elements[#UI.elements+1] = { key=key, paint=function()
        btn.BackgroundColor3 = NS.Settings[key] or Color3.fromRGB(255,255,255)
    end }
    return row
end

-- ================== info ==================
function UI.info(parent, label, keyText)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,22); row.BackgroundTransparency = 1; row.Parent = parent
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-140,1,0); l.BackgroundTransparency = 1; l.Text = label
    l.TextColor3 = C.subtext; l.Font = Enum.Font.Gotham; l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = row
    local k = Instance.new("TextLabel")
    k.Size = UDim2.new(0,130,0,18); k.Position = UDim2.new(1,-130,0.5,-9)
    k.BackgroundColor3 = C.card; k.Text = keyText or "—"
    k.TextColor3 = C.accent; k.Font = Enum.Font.GothamBold
    k.TextSize = 10; k.TextXAlignment = Enum.TextXAlignment.Center
    k.TextTruncate = Enum.TextTruncate.AtEnd
    k.BorderSizePixel = 0; k.Parent = row; corner(k, 4)
    return row
end

-- ================== button ==================
function UI.button(parent, label, cb)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,26); btn.BackgroundColor3 = C.track
    btn.Text = label; btn.TextColor3 = C.text
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 11
    btn.BorderSizePixel = 0; btn.Parent = parent; corner(btn, 5)
    btn.MouseButton1Click:Connect(function()
        if cb then pcall(cb) end
    end)
    return btn
end

-- ================== input ==================
function UI.input(parent, label, key, placeholder, onSubmit)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,42); row.BackgroundTransparency = 1; row.Parent = parent
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,0,14); l.BackgroundTransparency = 1; l.Text = label
    l.TextColor3 = C.text; l.Font = Enum.Font.Gotham; l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = row
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1,0,0,22); box.Position = UDim2.new(0,0,0,18)
    box.BackgroundColor3 = C.track; box.BorderSizePixel = 0
    box.Text = NS.Settings[key] or ""
    box.PlaceholderText = placeholder or "ввод..."
    box.PlaceholderColor3 = C.subtext
    box.TextColor3 = C.text
    box.Font = Enum.Font.Gotham; box.TextSize = 11
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.Parent = row; corner(box, 5); stroke(box, C.border, 1)
    local pad = Instance.new("UIPadding", box); pad.PaddingLeft = UDim.new(0,8)
    box.FocusLost:Connect(function(enter)
        NS.Settings[key] = box.Text
        if enter and onSubmit then pcall(onSubmit, box.Text) end
    end)
    return row
end

-- ================== notify ==================
function UI.notify(text, kind)
    if not UI._notifyHolder or not UI._notifyHolder.Parent then
        local sg = Instance.new("ScreenGui")
        sg.Name = "cfgkotik_notify"; sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true; sg.DisplayOrder = 2000
        NS.protectGui(sg); sg.Parent = NS.getParentGui()
        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(0,300,1,-60)
        holder.Position = UDim2.new(1,-320,0,40)
        holder.BackgroundTransparency = 1; holder.Parent = sg
        local lay = Instance.new("UIListLayout", holder)
        lay.Padding = UDim.new(0,6)
        lay.VerticalAlignment = Enum.VerticalAlignment.Top
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        UI._notifyHolder = holder
    end
    local col = C.accent
    if kind == "error" then col = C.danger
    elseif kind == "success" then col = C.green end
    local box = Instance.new("Frame")
    box.Size = UDim2.new(1,0,0,38)
    box.BackgroundColor3 = C.card; box.BackgroundTransparency = 1
    box.BorderSizePixel = 0; box.Parent = UI._notifyHolder
    corner(box, 8); stroke(box, col, 1)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-20,1,0); l.Position = UDim2.new(0,12,0,0)
    l.BackgroundTransparency = 1; l.Text = tostring(text)
    l.TextColor3 = C.text; l.Font = Enum.Font.Gotham
    l.TextSize = 11; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = box
    TW:Create(box, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
    task.spawn(function()
        task.wait(3)
        TW:Create(box, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        task.wait(0.3); box:Destroy()
    end)
end

-- ================== refresh ==================
function UI.refresh()
    for _, e in ipairs(UI.elements) do
        pcall(function() e.paint() end)
    end
end

-- openColorPicker — определяется в colorpicker.lua (загружается после framework)

return NS
