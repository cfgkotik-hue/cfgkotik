--!nocheck
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

local UIS = game:GetService("UserInputService")

local MOUSE = NS.MOUSE_LABELS or {
    MouseButton1="ЛКМ", MouseButton2="ПКМ", MouseButton3="СКМ",
    MouseMovement="Мышь", Touch="Тач",
}
local BLACK = NS.BLACKLISTED_KEYS or {}

function NS.enumTypeName(item)
    if not item then return nil end
    local ok, et = pcall(function() return item.EnumType end)
    if not ok or not et then return nil end
    if et == Enum.KeyCode then return "KeyCode" end
    if et == Enum.UserInputType then return "UserInputType" end
    return nil
end

function NS.keyLabel(v)
    if not v then return "—" end
    if typeof(v) == "EnumItem" then return MOUSE[v.Name] or v.Name end
    return tostring(v)
end

function NS.isInputPressed(v)
    if not v or typeof(v) ~= "EnumItem" then return false end
    local t = NS.enumTypeName(v)
    if t == "KeyCode" then
        local ok, d = pcall(function() return UIS:IsKeyDown(v) end)
        return ok and d or false
    end
    if t == "UserInputType" then
        local ok, d = pcall(function() return UIS:IsMouseButtonPressed(v) end)
        return ok and d or false
    end
    return false
end

function NS.bindMatches(b, i)
    if not b then return false end
    local t = NS.enumTypeName(b)
    if t == "KeyCode" then
        return i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == b
    end
    if t == "UserInputType" then return i.UserInputType == b end
    return false
end

function NS.isAlive(e)
    if not e or not e.hum then return true end
    local ok, hp = pcall(function() return e.hum.Health end)
    return ok and hp and hp > 0
end

function NS.partGroup(name)
    if NS.RIG_GROUP and NS.RIG_GROUP[name] then return NS.RIG_GROUP[name] end
    local ln = name:lower()
    for _, k in ipairs(NS.HEUR_HEAD) do if ln:find(k,1,true) then return "Head" end end
    for _, k in ipairs(NS.HEUR_TORSO) do if ln:find(k,1,true) then return "Torso" end end
    for _, k in ipairs(NS.HEUR_LIMB) do if ln:find(k,1,true) then return "Limbs" end end
    return nil
end

function NS.isBadPart(p)
    local par = p.Parent
    if par then
        if par:IsA("Accessory") or par:IsA("Tool") or par:IsA("Hat") or par:IsA("Backpack") then
            return true
        end
        if par.Name:match("Grip") or par.Name:match("Handle") then return true end
    end
    local n = p.Name:lower()
    for _, pat in ipairs(NS.BAD_NAME_PATTERNS) do
        if n:match(pat) then return true end
    end
    return false
end

function NS.matchesIgnore(model)
    local S = NS.Settings
    local pats = S and S.ScanIgnorePatterns
    if not pats or #pats == 0 then return false end
    local n = model.Name:lower()
    for _, pat in ipairs(pats) do
        if type(pat) == "string" and pat ~= "" and n:find(pat:lower(),1,true) then return true end
    end
    return false
end

function NS.rigScore(model)
    if NS.matchesIgnore(model) then return -999 end
    local hum = model:FindFirstChildOfClass("Humanoid")
    local hrp = model:FindFirstChild("HumanoidRootPart")
    local head = model:FindFirstChild("Head")
    local ac = model:FindFirstChildOfClass("AnimationController")
    if not hum and not ac then return -999 end
    if not hrp then return -999 end
    if not head or not head:IsA("BasePart") then return -999 end
    local ok, dist = pcall(function() return (head.Position - hrp.Position).Magnitude end)
    if not ok or not dist or dist < 1 or dist > 5 then return -999 end
    local sc = 0
    if hum then sc = sc + 4 end
    if ac then sc = sc + 1 end
    sc = sc + 2 + 1
    local pc = 0
    for _, ch in ipairs(model:GetChildren()) do
        if ch:IsA("BasePart") then pc = pc + 1 end
    end
    if pc < 4 then return -999 end
    sc = sc + math.min(pc, 10)
    if model:FindFirstChildOfClass("Tool") then sc = sc - 2 end
    return sc
end

function NS.looksLikeRig(model)
    local s = NS.rigScore(model)
    if s < 0 then return false end
    local S = NS.Settings
    if S and S.ScanStrictRig and not model:FindFirstChildOfClass("Humanoid") then return false end
    return s >= 9
end

function NS.collectLegacyParts(model)
    local list, seen = {}, {}
    for i = 1, #NS.RIG_PARTS do
        local p = model:FindFirstChild(NS.RIG_PARTS[i])
        if p and p:IsA("BasePart") and not seen[p] and not NS.isBadPart(p) then
            list[#list+1] = p; seen[p] = true
        end
    end
    if #list < 3 then
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("BasePart") and not seen[d] and not NS.isBadPart(d) then
                local anc, depth = d, 0
                while anc and anc ~= model and depth < 3 do
                    anc = anc.Parent; depth = depth + 1
                end
                if anc == model and NS.partGroup(d.Name) then
                    list[#list+1] = d; seen[d] = true
                end
                if #list >= 30 then break end
            end
        end
    end
    return list
end

return NS
