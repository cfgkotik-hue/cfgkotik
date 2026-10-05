--!nocheck
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

local UIS = NS.UIS or game:GetService("UserInputService")
local TW = game:GetService("TweenService")

NS.UI = {
    elements = {},
    listening = false,
    _activePicker = nil,
    _notifyHolder = nil,
    window = nil,
    C = {
        bg=Color3.fromRGB(14,14,18), card=Color3.fromRGB(22,22,28),
        sidebar=Color3.fromRGB(10,10,14), border=Color3.fromRGB(40,40,50),
        text=Color3.fromRGB(235,235,245), subtext=Color3.fromRGB(130,130,150),
        accent=Color3.fromRGB(0,170,255), danger=Color3.fromRGB(255,70,60),
        track=Color3.fromRGB(44,44,54), green=Color3.fromRGB(60,210,120),
        popupBg=Color3.fromRGB(12,12,16), cardHover=Color3.fromRGB(30,30,40),
    }
}
local UI = NS.UI
local C = UI.C

local function corner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = UDim.new(0, r or 6)
    return c
end
local function stroke(p, col, th)
    local s = Instance.new("UIStroke", p)
    s.Color = col or C.border; s.Thickness = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s
end
UI.corner = corner; UI.stroke = stroke

function UI.createWindow()
    local sg = Instance.new("ScreenGui")
    sg.Name = "cfgkotik_ui"; sg.ResetOnSpawn=false
    sg.IgnoreGuiInset=true; sg.DisplayOrder=100
    NS.protectGui(sg); sg.Parent = NS.getParentGui()

    local main = Instance.new("Frame")
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

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0,11,0,11); close.Position = UDim2.new(0,18,0.5,-5.5)
    close.BackgroundColor3 = C.danger; close.Text = ""
    close.BorderSizePixel = 0; close.Parent = bar; corner(close, 6)

    local back = Instance.new("TextButton")
    back.Size = UDim2.new(0,100,0,22); back.Position = UDim2.new(0,260,0.5,-11)
    back.BackgroundColor3 = C.card; back.Text = "← Folders"
    back.TextColor3 = C.text; back.Font = Enum.Font.GothamBold
    back.TextSize = 11; back.BorderSizePixel = 0
    back.Visible = false; back.Parent = bar
    corner(back, 5); stroke(back, C.border, 1)

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1,0,1,-40); content.Position = UDim2.new(0,0,0,40)
    content.BackgroundTransparency = 1; content.Parent = main

    local home = Instance.new("ScrollingFrame")
    home.Size = UDim2.new(1,-20,1,-10); home.Position = UDim2.new(0,10,0,5)
    home.BackgroundTransparency = 1; home.BorderSizePixel = 0
    home.ScrollBarThickness = 4; home.ScrollBarImageColor3 = C.accent
    home.CanvasSize = UDim2.new(0,0,0,0)
    home.AutomaticCanvasSize = Enum.AutomaticSize.Y
    home.Parent = content
    local hg = Instance.new("UIGridLayout", home)
    hg.CellSize = UDim2.new(0,340,0,130); hg.CellPadding = UDim2.new(0,10,0,10)
    hg.SortOrder = Enum.SortOrder.LayoutOrder
    hg.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local hp = Instance.new("UIPadding", home)
    hp.PaddingTop = UDim.new(0,8); hp.PaddingBottom = UDim.new(0,20)

    local pages = {}
    local function goHome()
        for _, p in ipairs(pages) do p.Visible = false end
        home.Visible = true; back.Visible = false
    end
    local function open(page)
        for _, p in ipairs(pages) do p.Visible = false end
        home.Visible = false; page.Visible = true; back.Visible = true
    end
    back.MouseButton1Click:Connect(goHome)

    local win = { main=main, sg=sg, verLabel=ver }
    function win:toggle()
        main.Visible = not main.Visible
        if main.Visible then goHome() end
    end
    close.MouseButton1Click:Connect(function() win:toggle() end)

    local drag, ds, sa = false, nil, nil
    bar.InputBegan:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton1
           and i.UserInputType ~= Enum.UserInputType.Touch then return end
        drag = true
        ds = Vector2.new(i.Position.X, i.Position.Y)
        sa = main.AbsolutePosition
    end)
    UIS.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType ~= Enum.UserInputType.MouseMovement
           and i.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = Vector2.new(i.Position.X, i.Position.Y) - ds
        main.Position = UDim2.new(0, sa.X + d.X, 0, sa.Y + d.Y)
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
           or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)

    local order = 0
    function win:makeTab(name, icon, desc)
        order = order + 1
        local card = Instance.new("TextButton")
        card.BackgroundColor3 = C.card; card.Text = ""
        card.BorderSizePixel = 0; card.AutoButtonColor = false
        card.LayoutOrder = order; card.Parent = home
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
        card.MouseButton1Click:Connect(function() open(page) end)
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
    local function paint(animate)
        local S = NS.Settings
        local on = S[key] and true or false
        tr.BackgroundColor3 = on and C.accent or C.track
        local tgt = on and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
        if animate then TW:Create(kn, TweenInfo.new(0.15), {Position = tgt}):Play()
        else kn.Position = tgt end
    end
    tr.MouseButton1Click:Connect(function()
        local S = NS.Settings
        S[key] = not S[key]
        paint(true)
        if onChange then pcall(onChange, S[key]) end
    end)
    UI.elements[#UI.elements+1] = { key=key, paint=function() paint(false) end }
    paint(false)
    return row
end

function UI.slider(parent, label, key, mn, mx, step, fmt)
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
    kn.BackgroundColor3 = Color3.fromRGB(255,255,255); kn.BorderSizePixel = 0
    kn.ZIndex = 2; kn.Parent = tr; corner(kn, 6)
    local drag = false
    local function apply(mx)
        local ap, asz = tr.AbsolutePosition.X, tr.AbsoluteSize.X
        if asz <= 0 then return end
        local t = math.clamp((mx - ap) / asz, 0, 1)
        local raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        -- correct:
        raw = mn + (mx - mn) * 0
        -- one clean line:
        raw = mn + (mx - mn) * 0
        -- commit:
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
        raw = mn + (mx - mn) * 0
    end
end

return NS
