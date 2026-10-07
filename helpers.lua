--!nocheck
-- cfgkotik v37 — Helpers (enum, input, rig classification)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

local UIS = game:GetService("UserInputService")

-- ================== ENUM ==================
function NS.enumTypeName(item)
    if not item then return nil end
    local okE, etype = pcall(function() return item.EnumType end)
    if not okE or not etype then return nil end
    if etype == Enum.KeyCode then return "KeyCode" end
    if etype == Enum.UserInputType then return "UserInputType" end
    return nil
end

function NS.keyLabel(v)
    if not v then return "—" end
    if typeof(v) == "EnumItem" then
        return NS.MOUSE_LABELS[v.Name] or v.Name
    end
    return tostring(v)
end

function NS.isInputPressed(bindVal)
    if not bindVal or typeof(bindVal) ~= "EnumItem" then return false end
    local tn = NS.enumTypeName(bindVal)
    if tn == "KeyCode" then
        local ok, d = pcall(function() return UIS:IsKeyDown(bindVal) end)
        return ok and d or false
    elseif tn == "UserInputType" then
        local ok, d = pcall(function() return UIS:IsMouseButtonPressed(bindVal) end)
        return ok and d or false
    end
    return false
end

function NS.bindMatches(b, input)
    if not b or not input then return false end
    local tn = NS.enumTypeName(b)
    if tn == "KeyCode" then
        return input.UserInputType == Enum.UserInputType.Keyboard
           and input.KeyCode == b
    elseif tn == "UserInputType" then
        return input.UserInputType == b
    end
    return false
end

-- ================== ALIVE ==================
function NS.isAlive(e)
    if not e or not e.hum then return true end
    local ok, hp = pcall(function() return e.hum.Health end)
    return ok and hp and hp > 0 or false
end

-- ================== PART GROUP ==================
local function classifyName(name)
    local ln = name:lower()
    for _, k in ipairs(NS.HEUR_HEAD)  do if ln:find(k,1,true) then return "Head"  end end
    for _, k in ipairs(NS.HEUR_TORSO) do if ln:find(k,1,true) then return "Torso" end end
    for _, k in ipairs(NS.HEUR_LIMB)  do if ln:find(k,1,true) then return "Limbs" end end
    return nil
end

function NS.partGroup(name)
    if not name then return nil end
    return NS.RIG_GROUP[name] or classifyName(name)
end

-- ================== BAD PART ==================
function NS.isBadPart(p)
    if not p then return true end
    local parent = p.Parent
    if parent then
        if parent:IsA("Accessory") or parent:IsA("Tool")
           or parent:IsA("Hat") or parent:IsA("Backpack") then
            return true
        end
        if parent.Name:match("Grip") or parent.Name:match("Handle") then
            return true
        end
    end
    local n = p.Name:lower()
    for _, pat in ipairs(NS.BAD_NAME_PATTERNS) do
        if n:match(pat) then return true end
    end
    return false
end

-- ================== IGNORE PATTERNS ==================
function NS.matchesIgnore(model)
    if not model then return false end
    local S = NS.Settings
    if not S then return false end
    local pats = S.ScanIgnorePatterns
    if not pats or type(pats) ~= "table" or #pats == 0 then return false end
    local n = model.Name:lower()
    for _, pat in ipairs(pats) do
        if type(pat) == "string" and pat ~= ""
           and n:find(pat:lower(), 1, true) then
            return true
        end
    end
    return false
end

-- ================== RIG SCORE ==================
function NS.rigScore(model)
    if NS.matchesIgnore(model) then return -999 end

    local hum  = model:FindFirstChildOfClass("Humanoid")
    local hrp  = model:FindFirstChild("HumanoidRootPart")
    local head = model:FindFirstChild("Head")
    local torso = model:FindFirstChild("UpperTorso")
              or  model:FindFirstChild("Torso")
              or  model:FindFirstChild("LowerTorso")
    local ac = model:FindFirstChildOfClass("AnimationController")

    if not hum and not ac then return -999 end
    if not hrp then return -999 end
    if not head or not head:IsA("BasePart") then return -999 end

    local okD, dist = pcall(function()
        return (head.Position - hrp.Position).Magnitude
    end)
    if not okD or not dist then return -999 end
    if dist < 1.0 or dist > 5.0 then return -999 end

    local score = 0
    if hum   then score = score + 4 end
    if ac    then score = score + 1 end
    if hrp   then score = score + 2 end
    if head  then score = score + 1 end
    if torso then score = score + 1 end

    local partCount = 0
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("BasePart") then partCount = partCount + 1 end
    end
    if partCount < 4 then return -999 end
    score = score + math.min(partCount, 10)
    if model:FindFirstChildOfClass("Tool") then score = score - 2 end
    return score
end

function NS.looksLikeRig(model)
    if not model then return false end
    local s = NS.rigScore(model)
    if s < 0 then return false end
    local S = NS.Settings
    if S and S.ScanStrictRig
       and not model:FindFirstChildOfClass("Humanoid") then
        return false
    end
    return s >= 9
end

-- ================== COLLECT LEGACY PARTS ==================
function NS.collectLegacyParts(model)
    local list, seen = {}, {}
    for i = 1, #NS.RIG_PARTS do
        local p = model:FindFirstChild(NS.RIG_PARTS[i])
        if p and p:IsA("BasePart") and not seen[p] and not NS.isBadPart(p) then
            list[#list+1] = p
            seen[p] = true
        end
    end
    if #list < 3 then
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("BasePart") and not seen[d] and not NS.isBadPart(d) then
                local anc, depth = d, 0
                while anc and anc ~= model and depth < 3 do
                    anc = anc.Parent
                    depth = depth + 1
                end
                if anc == model and NS.partGroup(d.Name) then
                    list[#list+1] = d
                    seen[d] = true
                end
                if #list >= 30 then break end
            end
        end
    end
    return list
end

return NS
