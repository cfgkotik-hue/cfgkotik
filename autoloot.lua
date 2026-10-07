--!nocheck
-- cfgkotik v37 — Auto-Loot (ProximityPrompt fire + named part pickup)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

local Workspace = NS.Workspace

NS.AutoLoot = (function()
    local M = {}

    -- ================== scan ==================
    local function scanLoot()
        local out = {}
        local S = NS.Settings
        local names = S.AutoLootNames or {}
        local maxDist = S.AutoLootMaxDist or 100

        local lpChar = NS.LP.Character
        if not lpChar then return out end
        local lpRoot = lpChar:FindFirstChild("HumanoidRootPart")
        if not lpRoot then return out end
        local lpPos = lpRoot.Position

        for _, obj in ipairs(Workspace:GetDescendants()) do
            -- proximity prompts
            if obj:IsA("ProximityPrompt") and obj.Enabled then
                local parent = obj.Parent
                if parent then
                    local pos = nil
                    if parent:IsA("BasePart") then
                        pos = parent.Position
                    elseif parent:IsA("Model") and parent.PrimaryPart then
                        pos = parent.PrimaryPart.Position
                    end
                    if pos then
                        local d = (pos - lpPos).Magnitude
                        if d <= maxDist then
                            out[#out+1] = {
                                kind = "prompt",
                                prompt = obj,
                                pos = pos,
                                dist = d,
                            }
                        end
                    end
                end

            -- unanchored named parts
            elseif obj:IsA("BasePart")
               and not obj.Anchored
               and not obj:FindFirstAncestorOfClass("Tool") then
                local n = obj.Name:lower()
                for _, want in ipairs(names) do
                    if n:find(want:lower(), 1, true) then
                        local d = (obj.Position - lpPos).Magnitude
                        if d <= maxDist then
                            out[#out+1] = {
                                kind = "part",
                                part = obj,
                                pos = obj.Position,
                                dist = d,
                            }
                        end
                        break
                    end
                end
            end
        end

        table.sort(out, function(a, b) return a.dist < b.dist end)
        return out
    end

    -- ================== do loot ==================
    local function doLoot(item)
        if not item then return end
        local S = NS.Settings

        if item.kind == "prompt" then
            pcall(function()
                local fp = rawget(_G, "fireproximityprompt")
                if fp then
                    fp(item.prompt)
                else
                    -- fallback via InputHold
                    item.prompt.HoldDuration = 0
                    item.prompt:InputHoldBegin()
                    task.wait(0.05)
                    item.prompt:InputHoldEnd()
                end
            end)

        elseif item.kind == "part" and S.AutoLootMode == "Teleport" then
            local c = NS.LP.Character
            if c then
                local hrp = c:FindFirstChild("HumanoidRootPart")
                if hrp then
                    pcall(function()
                        hrp.CFrame = CFrame.new(item.pos + Vector3.new(0, 3, 0))
                    end)
                end
            end
        end
    end

    -- ================== loop ==================
    task.spawn(function()
        while true do
            local S = NS.Settings
            task.wait(S.AutoLootInterval or 0.2)
            if S.AutoLoot then
                local loot = scanLoot()
                if #loot > 0 then
                    doLoot(loot[1])
                end
            end
        end
    end)

    -- ================== public ==================
    function M.scan() return scanLoot() end
    function M.take(item) doLoot(item) end

    return M
end)()

return NS--!nocheck
-- cfgkotik v37 — Auto-Loot (ProximityPrompt fire + named part pickup)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

local Workspace = NS.Workspace

NS.AutoLoot = (function()
    local M = {}

    -- ================== scan ==================
    local function scanLoot()
        local out = {}
        local S = NS.Settings
        local names = S.AutoLootNames or {}
        local maxDist = S.AutoLootMaxDist or 100

        local lpChar = NS.LP.Character
        if not lpChar then return out end
        local lpRoot = lpChar:FindFirstChild("HumanoidRootPart")
        if not lpRoot then return out end
        local lpPos = lpRoot.Position

        for _, obj in ipairs(Workspace:GetDescendants()) do
            -- 1) proximity prompts
            if obj:IsA("ProximityPrompt") and obj.Enabled then
                local parent = obj.Parent
                if parent then
                    local pos = nil
                    if parent:IsA("BasePart") then
                        pos = parent.Position
                    elseif parent:IsA("Model") and parent.PrimaryPart then
                        pos = parent.PrimaryPart.Position
                    end
                    if pos then
                        local d = (pos - lpPos).Magnitude
                        if d <= maxDist then
                            out[#out+1] = {
                                kind = "prompt",
                                prompt = obj,
                                pos = pos,
                                dist = d,
                            }
                        end
                    end
                end

            -- 2) unanchored parts with matching names
            elseif obj:IsA("BasePart")
               and not obj.Anchored
               and not obj:FindFirstAncestorOfClass("Tool") then
                local n = obj.Name:lower()
                for _, want in ipairs(names) do
                    if n:find(want:lower(), 1, true) then
                        local d = (obj.Position - lpPos).Magnitude
                        if d <= maxDist then
                            out[#out+1] = {
                                kind = "part",
                                part = obj,
                                pos = obj.Position,
                                dist = d,
                            }
                        end
                        break
                    end
                end
            end
        end

        table.sort(out, function(a, b) return a.dist < b.dist end)
        return out
    end

    -- ================== do loot ==================
    local function doLoot(item)
        if not item then return end
        local S = NS.Settings

        if item.kind == "prompt" then
            pcall(function()
                local fp = rawget(_G, "fireproximityprompt")
                if fp then
                    fp(item.prompt)
                else
                    -- fallback: direct hold-begin + hold-end
                    item.prompt.HoldDuration = 0
                    item.prompt:InputHoldBegin()
                    task.wait(0.05)
                    item.prompt:InputHoldEnd()
                end
            end)

        elseif item.kind == "part" and S.AutoLootMode == "Teleport" then
            local c = NS.LP.Character
            if c then
                local hrp = c:FindFirstChild("HumanoidRootPart")
                if hrp then
                    pcall(function()
                        hrp.CFrame = CFrame.new(item.pos + Vector3.new(0, 3, 0))
                    end)
                end
            end
        end
    end

    -- ================== loop ==================
    task.spawn(function()
        while true do
            local S = NS.Settings
            task.wait(S.AutoLootInterval or 0.2)
            if S.AutoLoot then
                local loot = scanLoot()
                if #loot > 0 then
                    doLoot(loot[1])
                end
            end
        end
    end)

    -- ================== public API ==================
    function M.scan() return scanLoot() end
    function M.take(item) doLoot(item) end

    return M
end)()

return NS
