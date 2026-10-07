--!nocheck
-- cfgkotik v37 — Bind Editor (key/mode editor window)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

local UIS = NS.UIS

NS.BindEditor = (function()
    local M = {}
    local sg = nil

    -- ================== close ==================
    function M.close()
        if sg then
            sg:Destroy()
            sg = nil
        end
    end

    -- ================== open ==================
    function M.open()
        if sg then M.close() end

        sg = Instance.new("ScreenGui")
        sg.Name = "cfgkotik_bindeditor"; sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true; sg.DisplayOrder = 400
        NS.protectGui(sg); sg.Parent = NS.getParentGui()

        local UI = NS.UI
        local C  = UI.C

        -- ================== window ==================
        local win = Instance.new("Frame")
        win.Size = UDim2.new(0,420,0,340)
        win.Position = UDim2.new(0.5,-210,0.5,-170)
        win.BackgroundColor3 = C.popupBg
        win.BorderSizePixel = 0
        win.Active = true
        win.Parent = sg
        UI.corner(win, 10)
        UI.stroke(win, C.accent, 2)

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1,-40,0,30)
        title.BackgroundTransparency = 1
        title.Text = "BIND EDITOR"
        title.TextColor3 = C.text
        title.Font = Enum.Font.GothamBold
        title.TextSize = 13
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Position = UDim2.new(0,14,0,0)
        title.Parent = win

        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0,24,0,24)
        closeBtn.Position = UDim2.new(1,-30,0,3)
        closeBtn.BackgroundColor3 = C.danger
        closeBtn.Text = "✕"
        closeBtn.TextColor3 = C.text
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 12
        closeBtn.BorderSizePixel = 0
        closeBtn.Parent = win
        UI.corner(closeBtn, 5)
        closeBtn.MouseButton1Click:Connect(M.close)

        -- ================== scroll ==================
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1,-20,1,-60)
        scroll.Position = UDim2.new(0,10,0,40)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 4
        scroll.ScrollBarImageColor3 = C.accent
        scroll.CanvasSize = UDim2.new(0,0,0,0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Parent = win
        local lay = Instance.new("UIListLayout", scroll)
        lay.Padding = UDim.new(0,4)
        lay.SortOrder = Enum.SortOrder.LayoutOrder

        -- ================== rows ==================
        for _, entry in ipairs(NS.BindList) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1,-8,0,30)
            row.BackgroundColor3 = C.card
            row.BorderSizePixel = 0
            row.Parent = scroll
            UI.corner(row, 5)
            UI.stroke(row, C.border, 1)

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0,140,1,0)
            lbl.Position = UDim2.new(0,10,0,0)
            lbl.BackgroundTransparency = 1
            lbl.Text = entry.label
            lbl.TextColor3 = C.text
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 11
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = row

            -- key button
            local keyBtn = Instance.new("TextButton")
            keyBtn.Size = UDim2.new(0,80,0,22)
            keyBtn.Position = UDim2.new(0,150,0.5,-11)
            keyBtn.BackgroundColor3 = C.track
            keyBtn.Text = NS.keyLabel(NS.getBindKey(entry.id))
            keyBtn.TextColor3 = C.text
            keyBtn.Font = Enum.Font.GothamBold
            keyBtn.TextSize = 10
            keyBtn.BorderSizePixel = 0
            keyBtn.Parent = row
            UI.corner(keyBtn, 4)

            keyBtn.MouseButton1Click:Connect(function()
                if UI.listening then return end
                UI.listening = true
                keyBtn.Text = "..."
                keyBtn.BackgroundColor3 = C.accent

                local conn
                task.spawn(function()
                    task.wait(0.05)
                    if not UI.listening then return end

                    local function stop()
                        if conn then conn:Disconnect(); conn = nil end
                        UI.listening = false
                        keyBtn.Text = NS.keyLabel(NS.getBindKey(entry.id))
                        keyBtn.BackgroundColor3 = C.track
                    end

                    conn = UIS.InputBegan:Connect(function(input)
                        local done = false
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            if input.KeyCode == Enum.KeyCode.Backspace then
                                NS.setBindKey(entry.id, nil)
                                done = true
                            elseif not NS.BLACKLISTED_KEYS[input.KeyCode] then
                                NS.setBindKey(entry.id, input.KeyCode)
                                done = true
                            end
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1
                            or input.UserInputType == Enum.UserInputType.MouseButton2
                            or input.UserInputType == Enum.UserInputType.MouseButton3 then
                            NS.setBindKey(entry.id, input.UserInputType)
                            done = true
                        end

                        if done then
                            stop()
                            if NS.BindStrip and NS.BindStrip.rebuild then
                                NS.BindStrip.rebuild()
                            end
                        end
                    end)
                end)
            end)

            -- mode button
            local modeBtn = Instance.new("TextButton")
            modeBtn.Size = UDim2.new(0,70,0,22)
            modeBtn.Position = UDim2.new(0,240,0.5,-11)
            modeBtn.BackgroundColor3 = C.track
            modeBtn.Text = NS.getBindMode(entry.id)
            modeBtn.TextColor3 = C.text
            modeBtn.Font = Enum.Font.GothamBold
            modeBtn.TextSize = 10
            modeBtn.BorderSizePixel = 0
            modeBtn.Parent = row
            UI.corner(modeBtn, 4)

            modeBtn.MouseButton1Click:Connect(function()
                local cur = NS.getBindMode(entry.id)
                local nxt = (cur == "Hold") and "Toggle" or "Hold"
                NS.setBindMode(entry.id, nxt)
                modeBtn.Text = nxt
            end)

            -- delete button
            local delBtn = Instance.new("TextButton")
            delBtn.Size = UDim2.new(0,28,0,22)
            delBtn.Position = UDim2.new(1,-38,0.5,-11)
            delBtn.BackgroundColor3 = C.danger
            delBtn.Text = "🗑"
            delBtn.TextColor3 = C.text
            delBtn.Font = Enum.Font.GothamBold
            delBtn.TextSize = 11
            delBtn.BorderSizePixel = 0
            delBtn.Parent = row
            UI.corner(delBtn, 4)
            delBtn.MouseButton1Click:Connect(function()
                NS.setBindKey(entry.id, nil)
                keyBtn.Text = "—"
                if NS.BindStrip and NS.BindStrip.rebuild then
                    NS.BindStrip.rebuild()
                end
            end)

            -- live active row highlight
            task.spawn(function()
                while row.Parent do
                    local active = NS.isBindActive(entry.id)
                    row.BackgroundColor3 = active and C.green or C.card
                    task.wait(0.1)
                end
            end)
        end

        -- ================== OK ==================
        local okBtn = Instance.new("TextButton")
        okBtn.Size = UDim2.new(0,110,0,28)
        okBtn.Position = UDim2.new(1,-122,1,-36)
        okBtn.BackgroundColor3 = C.accent
        okBtn.Text = "Close"
        okBtn.TextColor3 = C.text
        okBtn.Font = Enum.Font.GothamBold
        okBtn.TextSize = 12
        okBtn.BorderSizePixel = 0
        okBtn.Parent = win
        UI.corner(okBtn, 6)
        okBtn.MouseButton1Click:Connect(M.close)
    end

    return M
end)()

return NS
