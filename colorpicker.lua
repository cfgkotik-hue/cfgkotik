--!nocheck
-- cfgkotik v37 — Color Picker (HSV + palette, drag window)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

local UIS = NS.UIS

NS.UI = NS.UI or {}
local UI = NS.UI
local C = UI.C

-- ================== create picker ==================
function UI.openColorPicker(initial, onChanged)
    local sg = Instance.new("ScreenGui")
    sg.Name = "cfgkotik_cp"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 300
    NS.protectGui(sg)
    sg.Parent = NS.getParentGui()

    local win = Instance.new("Frame")
    win.Size = UDim2.new(0, 240, 0, 210)
    win.Position = UDim2.new(0.5, -120, 0.5, -105)
    win.BackgroundColor3 = C.popupBg
    win.BorderSizePixel = 0
    win.Active = true
    win.Parent = sg
    UI.corner(win, 10)
    UI.stroke(win, C.accent, 2)

    -- ================== title + close ==================
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 22)
    title.BackgroundTransparency = 1
    title.Text = "Цвет"
    title.TextColor3 = C.text
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Position = UDim2.new(0, 12, 0, 0)
    title.Parent = win

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 20, 0, 20)
    close.Position = UDim2.new(1, -26, 0, 2)
    close.BackgroundColor3 = C.danger
    close.Text = "✕"
    close.TextColor3 = C.text
    close.Font = Enum.Font.GothamBold
    close.TextSize = 11
    close.BorderSizePixel = 0
    close.Parent = win
    UI.corner(close, 5)
    close.MouseButton1Click:Connect(function()
        sg:Destroy()
    end)

    -- ================== preview ==================
    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(1, -20, 0, 24)
    preview.Position = UDim2.new(0, 10, 0, 24)
    preview.BackgroundColor3 = initial or Color3.fromRGB(255, 255, 255)
    preview.BorderSizePixel = 0
    preview.Parent = win
    UI.corner(preview, 5)
    UI.stroke(preview, C.border, 1)

    -- ================== HSV state ==================
    local h, s, v = (initial or Color3.fromRGB(255, 255, 255)):ToHSV()

    local function updateColor()
        local col = Color3.fromHSV(h, s, v)
        preview.BackgroundColor3 = col
        if onChanged then pcall(onChanged, col) end
    end

    -- ================== hsv slider ==================
    local function makeSlider(name, y, minV, maxV, step, val, cb)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 60, 0, 12)
        lbl.Position = UDim2.new(0, 10, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextColor3 = C.subtext
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 10
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = win

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(0, 50, 0, 12)
        valLbl.Position = UDim2.new(1, -60, 0, y)
        valLbl.BackgroundTransparency = 1
        valLbl.Text = tostring(math.floor(val * 100) / 100)
        valLbl.TextColor3 = C.accent
        valLbl.Font = Enum.Font.GothamBold
        valLbl.TextSize = 10
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.Parent = win

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -20, 0, 4)
        track.Position = UDim2.new(0, 10, 0, y + 14)
        track.BackgroundColor3 = C.track
        track.BorderSizePixel = 0
        track.Parent = win
        UI.corner(track, 2)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(val, 0, 1, 0)
        fill.BackgroundColor3 = C.accent
        fill.BorderSizePixel = 0
        fill.Parent = track
        UI.corner(fill, 2)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 10, 0, 10)
        knob.AnchorPoint = Vector2.new(0.5, 0.5)
        knob.Position = UDim2.new(val, 0, 0.5, 0)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.ZIndex = 2
        knob.Parent = track
        UI.corner(knob, 5)

        local drag = false
        local function apply(mouseX)
            local ap = track.AbsolutePosition.X
            local asz = track.AbsoluteSize.X
            if asz <= 0 then return end
            local t = math.clamp((mouseX - ap) / asz, 0, 1)
            local raw = minV + (maxV - minV) * t
            raw = math.floor(raw / step + 0.5) * step
            raw = math.clamp(raw, minV, maxV)
            fill.Size = UDim2.new(t, 0, 1, 0)
            knob.Position = UDim2.new(t, 0, 0.5, 0)
            valLbl.Text = tostring(math.floor(raw * 100) / 100)
            cb(raw)
        end

        track.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                drag = true
                apply(i.Position.X)
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if not drag then return end
            if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
            apply(i.Position.X)
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                drag = false
            end
        end)
    end

    makeSlider("Hue", 58, 0, 1, 0.01, h, function(x) h = x; updateColor() end)
    makeSlider("Sat", 92, 0, 1, 0.01, s, function(x) s = x; updateColor() end)
    makeSlider("Val", 126, 0, 1, 0.01, v, function(x) v = x; updateColor() end)

    -- ================== palette ==================
    local palRow = Instance.new("Frame")
    palRow.Size = UDim2.new(1, -20, 0, 18)
    palRow.Position = UDim2.new(0, 10, 0, 170)
    palRow.BackgroundTransparency = 1
    palRow.Parent = win
    local pl = Instance.new("UIListLayout", palRow)
    pl.FillDirection = Enum.FillDirection.Horizontal
    pl.Padding = UDim.new(0, 4)

    for _, c in ipairs({
        Color3.fromRGB(10, 132, 255),
        Color3.fromRGB(140, 100, 255),
        Color3.fromRGB(80, 200, 130),
        Color3.fromRGB(255, 189, 46),
        Color3.fromRGB(255, 69, 58),
        Color3.fromRGB(255, 255, 255),
    }) do
        local sw = Instance.new("TextButton")
        sw.Size = UDim2.new(0, 18, 0, 18)
        sw.BackgroundColor3 = c
        sw.Text = ""
        sw.BorderSizePixel = 0
        sw.Parent = palRow
        UI.corner(sw, 4)
        sw.MouseButton1Click:Connect(function()
            local hh, ss, vv = c:ToHSV()
            h, s, v = hh, ss, vv
            -- refresh sliders display
            updateColor()
            -- rebuild sliders to reflect new values
            sg:Destroy()
            -- reopen with new
            if NS.UI.openColorPicker then
                local newPicker = NS.UI.openColorPicker(Color3.fromHSV(h, s, v), onChanged)
                NS.UI._activePicker = newPicker
            end
        end)
    end

    -- ================== drag window ==================
    local drag, ds, sa = false, nil, nil
    title.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true
            ds = Vector2.new(i.Position.X, i.Position.Y)
            sa = win.AbsolutePosition
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local d = Vector2.new(i.Position.X, i.Position.Y) - ds
        win.Position = UDim2.new(0, sa.X + d.X, 0, sa.Y + d.Y)
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = false
        end
    end)

    return sg
end

return NS
