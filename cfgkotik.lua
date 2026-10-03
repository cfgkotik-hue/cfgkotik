--!nocheck
-- language: Lua/Luau, file: cfgkotik_v37_final.lua, target: Roblox executor
-- ==================================================================
-- cfgkotik v37 FINAL — themes · folder grid · in-memory configs
-- ==================================================================

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local Workspace    = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local TeleportSvc  = game:GetService("TeleportService")
local Stats        = game:GetService("Stats")
local Lighting     = game:GetService("Lighting")
local HttpService  = game:GetService("HttpService")
local LP           = Players.LocalPlayer

-- ================== HOOK PROTECTION ==================
local _BindToRenderStep = RunService.BindToRenderStep
local _HeartbeatSignal  = RunService.Heartbeat
local _RenderSignal     = RunService.RenderStepped
local _WorkspaceRaycast = Workspace.Raycast

local function safeBind(name, prio, fn) return _BindToRenderStep(RunService, name, prio, fn) end
local function safeHeartbeat(fn) return _HeartbeatSignal:Connect(fn) end
local function safeRender(fn) return _RenderSignal:Connect(fn) end

local function protectGui(sg)
    local syn = rawget(_G, "syn")
    if syn and syn.protect_gui then pcall(syn.protect_gui, sg) end
    local pg = rawget(_G, "protect_gui")
    if pg then pcall(pg, sg) end
end
local function getParentGui()
    local gh = rawget(_G, "gethui")
    if gh then
        local ok, hui = pcall(gh)
        if ok and hui then return hui end
    end
    return game:GetService("CoreGui")
end

do
    local parent = getParentGui()
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("ScreenGui") and child.Name:match("^cfgkotik_") then
            pcall(function() child:Destroy() end)
        end
    end
    for _, child in ipairs(Lighting:GetChildren()) do
        if child.Name:match("^cfgkotik_") then
            pcall(function() child:Destroy() end)
        end
    end
    for _, n in ipairs({"cfgkotik_rain","cfgkotik_snow"}) do
        if Workspace:FindFirstChild(n) then
            pcall(function() Workspace[n]:Destroy() end)
        end
    end
end

-- ================== THEMES SYSTEM ==================
local THEMES = {
    Default = {
        MenuAccent = Color3.fromRGB(0,170,255),
        ESPColor = Color3.fromRGB(230,80,100),
        FovColor = Color3.fromRGB(140,100,255),
        FovColorLocked = Color3.fromRGB(255,80,120),
        HudLogo = Color3.fromRGB(10,132,255),
        HudFps = Color3.fromRGB(80,200,130),
        HudTarget = Color3.fromRGB(230,80,100),
        RadarPlayer = Color3.fromRGB(230,80,100),
        RadarNPC = Color3.fromRGB(255,200,60),
    },
    Cyber = {
        MenuAccent = Color3.fromRGB(0,255,255),
        ESPColor = Color3.fromRGB(0,255,255),
        FovColor = Color3.fromRGB(0,200,255),
        FovColorLocked = Color3.fromRGB(255,0,255),
        HudLogo = Color3.fromRGB(0,255,255),
        HudFps = Color3.fromRGB(0,255,200),
        HudTarget = Color3.fromRGB(255,0,255),
        RadarPlayer = Color3.fromRGB(0,255,255),
        RadarNPC = Color3.fromRGB(255,100,255),
    },
    Stealth = {
        MenuAccent = Color3.fromRGB(140,140,160),
        ESPColor = Color3.fromRGB(80,80,90),
        FovColor = Color3.fromRGB(120,120,140),
        FovColorLocked = Color3.fromRGB(160,100,120),
        HudLogo = Color3.fromRGB(140,140,160),
        HudFps = Color3.fromRGB(100,160,120),
        HudTarget = Color3.fromRGB(160,100,100),
        RadarPlayer = Color3.fromRGB(160,100,100),
        RadarNPC = Color3.fromRGB(160,140,100),
    },
    Sunset = {
        MenuAccent = Color3.fromRGB(255,120,50),
        ESPColor = Color3.fromRGB(255,80,60),
        FovColor = Color3.fromRGB(255,140,60),
        FovColorLocked = Color3.fromRGB(255,50,80),
        HudLogo = Color3.fromRGB(255,120,50),
        HudFps = Color3.fromRGB(255,180,80),
        HudTarget = Color3.fromRGB(255,80,80),
        RadarPlayer = Color3.fromRGB(255,80,60),
        RadarNPC = Color3.fromRGB(255,180,80),
    },
    Forest = {
        MenuAccent = Color3.fromRGB(80,200,120),
        ESPColor = Color3.fromRGB(60,200,100),
        FovColor = Color3.fromRGB(80,180,80),
        FovColorLocked = Color3.fromRGB(200,200,80),
        HudLogo = Color3.fromRGB(80,200,120),
        HudFps = Color3.fromRGB(80,220,140),
        HudTarget = Color3.fromRGB(180,200,80),
        RadarPlayer = Color3.fromRGB(60,200,100),
        RadarNPC = Color3.fromRGB(200,180,80),
    },
}
local SAVED_THEMES = {}

-- ================== SETTINGS ==================
local Settings = {
    Aimbot=false, AimKey=Enum.KeyCode.E, AimMode="Hold",
    AimSmoothMode="Smooth", FOV=120, TeamCheck=false,
    ShowFov=true, AimColor=Color3.fromRGB(140,100,255),
    AimColorLocked=Color3.fromRGB(255,80,120),
    AimPartList={Head=true, Torso=false, Limbs=false},
    Priority="FOV", Visibility=true, HitChance=100,
    Jitter=0, PredAmount=1.0, StickyTime=0.25,
    AimStickyStrict=true, AimGravityComp=true,
    FovExpand=false, FovExpandMult=1.3, FovExpandHold=0.5,
    FovExpandStationary=false, FovExpandStationaryMult=1.3,
    AdaptiveFov=true, AdaptiveFovFactor=0.8,

    SilentAim=false, SilentAimMaxFireRate=60,
    TriggerBot=false, TriggerDelay=0.1,
    AntiDetectionJitter=false,
    HitboxExpand=false, HitboxSize=5,
    HitboxPartList={Head=true, Torso=true, Limbs=true},

    TargetNPCs=false, TargetPlayers=true,
    ScanIgnorePatterns={"dummy","target","practice","npc_","prop_","vehicle","car","bike","crate"},
    ScanStrictRig=true, ScanMaxDist=3000,
    ScanInterval=0.2, ScanVisibilityInterval=0.15,
    ScanMaxEntities=200,
    DetectorDebug=false,
    _UseLegacyScan=false,

    ESP=false,
    ESPBox=true, ESPName=true, ESPDistance=false,
    ESPHealth=true, ESPHighlight=false,
    ESPHighlightOccluded=false, ESPHighlightMode="AlwaysOnTop",
    ESPTracers=false, ESPWeapon=true, ESPBoxStyle="full",
    ESPColor=Color3.fromRGB(230,80,100),
    ESPTracerFrom="Bottom", ESPMaxDist=2000,
    ESPShowPlayers=true, ESPShowNPCs=true,
    ESPVisibilityCheck=true, ESPShowVisLabel=true,
    ESPUpdateRate=0.03,
    ESPDistanceColors=false,
    ESPNearThreshold=50, ESPMidThreshold=200,
    ESPNearColor=Color3.fromRGB(255,69,58),
    ESPMidColor=Color3.fromRGB(255,214,10),
    ESPFarColor=Color3.fromRGB(52,199,89),

    SpeedHack=false, Speed=50,
    Fly=false, FlySpeed=80,
    JumpPower=50, JumpPowerEnable=false,
    InfiniteJump=false, Noclip=false,

    WorldRain=false, WorldRainRate=300, WorldRainSpeed=90, WorldRainSize=0.08,
    WorldSnow=false, WorldSnowRate=200, WorldSnowSpeed=4, WorldSnowSize=0.25,
    WorldThunder=false, WorldThunderMin=3, WorldThunderMax=8, WorldThunderBright=60,
    WorldFog=false, WorldFogDensity=0.5, WorldFogHaze=2,
    WorldVignette=false, WorldVignetteStrength=0.15,
    WorldColorShift=false, WorldColorShiftColor=Color3.fromRGB(80,40,120),
    WorldBlur=false, WorldBlurSize=4,

    ThirdPerson=false, ThirdPersonDistance=10,
    CameraFov=false, CameraFovAmount=1.0,

    AutoParry=false, AutoParryOffset=0.05,
    AutoParryKey=Enum.KeyCode.F, AutoParryRange=30,
    AutoLoot=false, AutoLootMode="Prompt",
    AutoLootNames={"coin","gem","chest","drop","loot","crystal","orb"},
    AutoLootMaxDist=100, AutoLootInterval=0.2,
    AntiAFK=false, AntiAFKInterval=30,
    AntiAFKChatSpam=false,
    AntiAFKChatPhrases={"still here","gg","nice"},

    RadarEnabled=false, RadarSize=180, RadarScale=0.7,
    RadarRange=300, RadarPosition="TopRight",
    RadarShowPlayers=true, RadarShowNPCs=false,
    RadarPlayerColor=Color3.fromRGB(230,80,100),
    RadarNPCColor=Color3.fromRGB(255,200,60),

    BindAimKeyKey=nil, BindAimKeyMode="Hold",
    BindFovExpandKey=nil, BindFovExpandMode="Toggle",
    BindTriggerKey=nil, BindTriggerMode="Toggle",
    BindHitboxKey=nil, BindHitboxMode="Toggle",
    BindVisibilityKey=nil, BindVisibilityMode="Toggle",
    BindSpeedKey=nil, BindSpeedMode="Toggle",
    BindFlyKey=nil, BindFlyMode="Toggle",
    BindStripEnabled=true, BindStripLabel="short",
    BindStripSize=14, BindStripX=486, BindStripY=680,
    BindStripPosition="Bottom Center",
    CurrentBindProfile="default",
    BindProfiles={},

    HudShowLogo=true, HudShowTime=true, HudShowFps=true,
    HudShowPing=true, HudShowTarget=true, HudShowEntities=false,
    HudShowCombatStats=false,
    HudBgColor=Color3.fromRGB(20,20,26),
    HudLogoColor=Color3.fromRGB(10,132,255),
    HudTimeColor=Color3.fromRGB(240,240,245),
    HudFpsColor=Color3.fromRGB(80,200,130),
    HudPingColor=Color3.fromRGB(255,189,46),
    HudTargetColor=Color3.fromRGB(230,80,100),
    HudEntitiesColor=Color3.fromRGB(170,170,185),

    MenuKey=Enum.KeyCode.RightShift,
    CurrentConfig="default",
    TargetWhitelist={},
    TargetBlacklist={},
    TargetHistory={},
    AutoOptimize=false,
    MinFpsThreshold=45,

    PerfSpatialGrid=true, PerfCacheESP=true, PerfBatchVis=true,
    ESPMoveThreshold=5, ESPCacheInterval=0.05,

    PredHistory=5, PredAccel=true,

    CurrentTheme="Default",
    CustomThemeName="my_theme",

    ScanIgnoreList="dummy,target,practice",
    AutoLootNamesList="coin,gem,chest,drop",
    AimStickyMode="Strict",
}
getgenv().Settings = Settings

-- ================== INTEGRITY ==================
do
    local frozen, lockedHashes, violations = {}, {}, 0
    local lastCheck, CHECK_INTERVAL, seed = 0, 3, 0

    local function hashValue(v)
        local s = tostring(v); local h = 5381 + seed
        for i = 1, #s do h = (h * 33 + s:byte(i) + seed) % 2147483647 end
        return h
    end
    local function hashTable(t)
        if type(t) ~= "table" then return hashValue(t) end
        local keys = {}
        for k in pairs(t) do keys[#keys+1] = tostring(k) end
        table.sort(keys)
        local h = seed
        for _, k in ipairs(keys) do
            h = (h * 31 + hashValue(k) + seed) % 2147483647
            local v = t[k]
            if type(v) == "table" then h = (h * 31 + hashTable(v)) % 2147483647
            else h = (h * 31 + hashValue(v)) % 2147483647 end
        end
        return h
    end

    math.randomseed(os.clock() * 1e6 % 2^31)
    seed = math.random(1, 2^31 - 1)

    local function seal()
        frozen = {}; lockedHashes = {}
        for k, v in pairs(Settings) do
            frozen[k] = v
            if type(v) == "table" then lockedHashes[k] = hashTable(v) end
        end
    end

    local OUR_THREAD = coroutine.running()
    local function isOurThread()
        local ok, co = pcall(coroutine.running)
        return ok and co == OUR_THREAD
    end

    local function flag()
        violations = violations + 1
        if violations >= 3 then
            pcall(function() Settings.Aimbot = false end)
            pcall(function() Settings.ESP = false end)
            pcall(function() Settings.SilentAim = false end)
            pcall(function() Settings.SpeedHack = false end)
            pcall(function() Settings.Fly = false end)
            pcall(function() Settings.TriggerBot = false end)
            pcall(function() Settings.HitboxExpand = false end)
        end
    end

    local function check()
        if not isOurThread() then return end
        if next(frozen) == nil then return end
        for k, v in pairs(frozen) do
            if type(v) == "table" then
                local cur = Settings[k]
                if type(cur) ~= "table" then flag()
                elseif hashTable(cur) ~= lockedHashes[k] then flag() end
            elseif type(v) == "number" and type(Settings[k]) ~= "number" then
                flag()
            end
        end
    end

    seal()
    task.spawn(function()
        while task.wait(1) do
            local now = os.clock()
            if now - lastCheck >= CHECK_INTERVAL then
                lastCheck = now
                pcall(check)
            end
        end
    end)
end

-- ================== CAM ==================
local Cam = { cur = Workspace.CurrentCamera }
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if Workspace.CurrentCamera then Cam.cur = Workspace.CurrentCamera end
end)

-- ================== ENUM ==================
local function enumTypeName(item)
    if not item then return nil end
    local okE, etype = pcall(function() return item.EnumType end)
    if not okE or not etype then return nil end
    local okK, k = pcall(function() return etype == Enum.KeyCode end)
    if okK and k then return "KeyCode" end
    local okU, u = pcall(function() return etype == Enum.UserInputType end)
    if okU and u then return "UserInputType" end
    return nil
end

local MOUSE_LABELS = {
    MouseButton1="ЛКМ", MouseButton2="ПКМ", MouseButton3="СКМ",
    MouseMovement="Мышь", Touch="Тач",
}
local function keyLabel(v)
    if not v then return "—" end
    if typeof(v) == "EnumItem" then return MOUSE_LABELS[v.Name] or v.Name end
    return tostring(v)
end

local function isInputPressed(bindVal)
    if not bindVal or typeof(bindVal) ~= "EnumItem" then return false end
    local tn = enumTypeName(bindVal)
    if tn == "KeyCode" then
        local ok, d = pcall(function() return UIS:IsKeyDown(bindVal) end)
        return ok and d or false
    elseif tn == "UserInputType" then
        local ok, d = pcall(function() return UIS:IsMouseButtonPressed(bindVal) end)
        return ok and d or false
    end
    return false
end

local function bindMatches(b, input)
    if not b then return false end
    local tn = enumTypeName(b)
    if tn == "KeyCode" then
        return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == b
    elseif tn == "UserInputType" then
        return input.UserInputType == b
    end
    return false
end

local BLACKLISTED_KEYS = {
    [Enum.KeyCode.Unknown]=true, [Enum.KeyCode.Tab]=true,
    [Enum.KeyCode.Backspace]=true, [Enum.KeyCode.Escape]=true,
}

-- ================== RIG HELPERS ==================
local RIG_PARTS = {
    "Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg",
    "UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","LeftHand",
    "RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg",
    "LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot",
}
local RIG_GROUP = {
    Head="Head", Torso="Torso", UpperTorso="Torso", LowerTorso="Torso", Chest="Torso",
    LeftUpperArm="Limbs", LeftLowerArm="Limbs", LeftHand="Limbs",
    RightUpperArm="Limbs", RightLowerArm="Limbs", RightHand="Limbs",
    LeftUpperLeg="Limbs", LeftLowerLeg="Limbs", LeftFoot="Limbs",
    RightUpperLeg="Limbs", RightLowerLeg="Limbs", RightFoot="Limbs",
    ["Left Arm"]="Limbs", ["Right Arm"]="Limbs",
    ["Left Leg"]="Limbs", ["Right Leg"]="Limbs",
}
local HEUR_HEAD  = { "head", "skull", "neck" }
local HEUR_TORSO = { "torso", "chest", "spine", "body", "upper", "lower", "hip", "pelvis", "root" }
local HEUR_LIMB  = { "arm", "hand", "leg", "foot", "shoulder", "thigh", "shin", "knee", "elbow", "forearm", "wrist" }

local function classifyName(name)
    local ln = name:lower()
    for _, k in ipairs(HEUR_HEAD) do if ln:find(k,1,true) then return "Head" end end
    for _, k in ipairs(HEUR_TORSO) do if ln:find(k,1,true) then return "Torso" end end
    for _, k in ipairs(HEUR_LIMB) do if ln:find(k,1,true) then return "Limbs" end end
    return nil
end
local function partGroup(name) return RIG_GROUP[name] or classifyName(name) end

local BAD_NAME_PATTERNS = {
    "^handle$", "^grip$", "^weapon$", "^gun$", "^rifle$", "^pistol$",
    "^ammo", "^mag", "^scope$", "attachment",
}
local function isBadPart(p)
    local parent = p.Parent
    if parent then
        if parent:IsA("Accessory") or parent:IsA("Tool")
           or parent:IsA("Hat") or parent:IsA("Backpack") then return true end
        if parent.Name:match("Grip") or parent.Name:match("Handle") then return true end
    end
    local n = p.Name:lower()
    for _, pat in ipairs(BAD_NAME_PATTERNS) do if n:match(pat) then return true end end
    return false
end

local function matchesIgnorePattern(model)
    local pats = Settings.ScanIgnorePatterns
    if not pats or type(pats) ~= "table" or #pats == 0 then return false end
    local n = model.Name:lower()
    for _, pat in ipairs(pats) do
        if type(pat) == "string" and pat ~= "" and n:find(pat:lower(), 1, true) then return true end
    end
    return false
end

local function rigScore(model)
    if matchesIgnorePattern(model) then return -999 end
    local hum = model:FindFirstChildOfClass("Humanoid")
    local hrp = model:FindFirstChild("HumanoidRootPart")
    local head = model:FindFirstChild("Head")
    local torso = model:FindFirstChild("UpperTorso")
                  or model:FindFirstChild("Torso")
                  or model:FindFirstChild("LowerTorso")
    local ac = model:FindFirstChildOfClass("AnimationController")
    if not hum and not ac then return -999 end
    if not hrp then return -999 end
    if not head or not head:IsA("BasePart") then return -999 end
    local okD, dist = pcall(function() return (head.Position - hrp.Position).Magnitude end)
    if not okD or not dist then return -999 end
    if dist < 1.0 or dist > 5.0 then return -999 end
    local score = 0
    if hum then score = score + 4 end
    if ac then score = score + 1 end
    if hrp then score = score + 2 end
    if head then score = score + 1 end
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

local function looksLikeRig(model)
    local s = rigScore(model)
    if s < 0 then return false end
    if Settings.ScanStrictRig and not model:FindFirstChildOfClass("Humanoid") then
        return false
    end
    return s >= 9
end

-- ================== UNIVERSAL MODEL DETECTOR ==================
local ModelDetector = (function()
    local M = {}

    local function geometricAnalysis(model)
        local hrp = model:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local parts = {}
        for _, child in ipairs(model:GetDescendants()) do
            if child:IsA("BasePart") and child ~= hrp then
                local offset = child.Position - hrp.Position
                local dist = offset.Magnitude
                if dist < 3 then
                    if offset.Y > 0.5 then parts.head = parts.head or child
                    elseif math.abs(offset.Y) < 0.5 then parts.torso = parts.torso or child end
                elseif dist < 5 then
                    parts.limbs = parts.limbs or {}
                    table.insert(parts.limbs, child)
                end
            end
        end
        return parts
    end

    local function attachmentScan(model)
        local classified = {}
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("Attachment") then
                local parent = desc.Parent
                if parent and parent:IsA("BasePart") then
                    local name = desc.Name:lower()
                    if name:match("neck") or name:match("head") then
                        classified.head = parent
                    elseif name:match("waist") or name:match("root") then
                        classified.torso = parent
                    elseif name:match("shoulder") or name:match("hip")
                        or name:match("wrist") or name:match("ankle") then
                        classified.limbs = classified.limbs or {}
                        table.insert(classified.limbs, parent)
                    end
                end
            end
        end
        return classified
    end

    local function jointScan(model)
        local bones = {}
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("Motor6D") then
                local p0, p1 = desc.Part0, desc.Part1
                if p0 and p1 then
                    local name = desc.Name:lower()
                    if name:match("neck") then bones.head = p1
                    elseif name:match("waist") or name:match("root") then bones.torso = p0
                    else
                        bones.limbs = bones.limbs or {}
                        table.insert(bones.limbs, p1)
                    end
                end
            end
        end
        return bones
    end

    local function volumeAnalysis(parts)
        local scored = {}
        for _, p in ipairs(parts) do
            local size = p.Size
            local volume = size.X * size.Y * size.Z
            local ratio = math.max(size.X, size.Y, size.Z) /
                          math.min(size.X, size.Y, size.Z)
            if volume < 3 and ratio < 2 then
                scored.head = scored.head or p
            elseif volume > 3 and volume < 20 and ratio > 1.5 then
                scored.torso = scored.torso or p
            elseif volume < 5 and ratio > 3 then
                scored.limbs = scored.limbs or {}
                table.insert(scored.limbs, p)
            end
        end
        return scored
    end

    function M.classify(model)
        local results = {
            geometric   = geometricAnalysis(model),
            attachments = attachmentScan(model),
            joints      = jointScan(model),
        }
        local final = { Head = {}, Torso = {}, Limbs = {} }

        local heads = {}
        for _, data in pairs(results) do
            if data and data.head then heads[data.head] = (heads[data.head] or 0) + 1 end
        end
        for part, score in pairs(heads) do
            if score >= 2 then table.insert(final.Head, part) end
        end

        local torsos = {}
        for _, data in pairs(results) do
            if data and data.torso then torsos[data.torso] = (torsos[data.torso] or 0) + 1 end
        end
        for part, score in pairs(torsos) do
            if score >= 2 then table.insert(final.Torso, part) end
        end

        local limbs = {}
        for _, data in pairs(results) do
            if data and data.limbs then
                for _, p in ipairs(data.limbs) do
                    limbs[p] = (limbs[p] or 0) + 1
                end
            end
        end
        for part, score in pairs(limbs) do
            if score >= 1 then table.insert(final.Limbs, part) end
        end

        if #final.Head == 0 or #final.Torso == 0 then
            local allParts = {}
            for _, child in ipairs(model:GetDescendants()) do
                if child:IsA("BasePart") then table.insert(allParts, child) end
            end
            local volumeBased = volumeAnalysis(allParts)
            if volumeBased.head and #final.Head == 0 then table.insert(final.Head, volumeBased.head) end
            if volumeBased.torso and #final.Torso == 0 then table.insert(final.Torso, volumeBased.torso) end
            if volumeBased.limbs then
                for _, p in ipairs(volumeBased.limbs) do table.insert(final.Limbs, p) end
            end
        end
        return final
    end

    return M
end)()

-- ================== collectRigParts ==================
local function collectLegacyParts(model)
    local list, seen = {}, {}
    for i = 1, #RIG_PARTS do
        local p = model:FindFirstChild(RIG_PARTS[i])
        if p and p:IsA("BasePart") and not seen[p] and not isBadPart(p) then
            list[#list+1] = p; seen[p] = true
        end
    end
    if #list < 3 then
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("BasePart") and not seen[d] and not isBadPart(d) then
                local anc, depth = d, 0
                while anc and anc ~= model and depth < 3 do
                    anc = anc.Parent; depth = depth + 1
                end
                if anc == model and partGroup(d.Name) then
                    list[#list+1] = d; seen[d] = true
                end
                if #list >= 30 then break end
            end
        end
    end
    return list
end

local function buildPartMap(model, parts)
    local pm = { Head = {}, Torso = {}, Limbs = {} }
    local named = { Head=false, Torso=false, Limbs=false }
    local seen = {}

    for _, p in ipairs(parts) do
        local g = partGroup(p.Name)
        if g and pm[g] then
            pm[g][#pm[g]+1] = p
            seen[p] = true
            named[g] = true
        end
    end

    if not (named.Head and named.Torso and named.Limbs) then
        local cls = ModelDetector.classify(model)
        local function topUp(dst, src)
            for _, p in ipairs(src) do
                if not seen[p] then
                    dst[#dst+1] = p; seen[p] = true
                end
            end
        end
        if not named.Head  then topUp(pm.Head,  cls.Head)  end
        if not named.Torso then topUp(pm.Torso, cls.Torso) end
        if not named.Limbs then topUp(pm.Limbs, cls.Limbs) end
    end

    return pm
end

local function collectRigParts(model, filter)
    if Settings._UseLegacyScan then
        local list, seen = {}, {}
        for i = 1, #RIG_PARTS do
            local p = model:FindFirstChild(RIG_PARTS[i])
            if p and p:IsA("BasePart") and not seen[p] and not isBadPart(p) then
                local grp = partGroup(p.Name)
                if (not filter) or (grp and filter[grp]) then
                    list[#list+1] = p; seen[p] = true
                end
            end
        end
        return list
    end

    local parts = collectLegacyParts(model)
    if #parts >= 3 then return parts end

    local cls = ModelDetector.classify(model)
    local out = {}
    local function push(seq)
        for _, p in ipairs(seq) do out[#out+1] = p end
    end
    if filter then
        if filter.Head  then push(cls.Head)  end
        if filter.Torso then push(cls.Torso) end
        if filter.Limbs then push(cls.Limbs) end
    else
        push(cls.Head); push(cls.Torso); push(cls.Limbs)
    end
    return #out > 0 and out or parts
end

local function isAlive(e)
    if not e.hum then return true end
    local ok, hp = pcall(function() return e.hum.Health end)
    if ok and hp then return hp > 0 end
    return false
end

-- ================== SPATIAL GRID ==================
local SpatialGrid = (function()
    local M = {}
    local CELL_SIZE = 100
    local grid, cellDirty = {}, {}

    local function key(x,y,z) return x..":"..y..":"..z end
    local function cellKey(pos)
        return math.floor(pos.X / CELL_SIZE),
               math.floor(pos.Y / CELL_SIZE),
               math.floor(pos.Z / CELL_SIZE)
    end

    function M.clear() grid = {}; cellDirty = {} end

    function M.insert(entity)
        if not entity or not entity.root or not entity.root.Parent then return end
        local x, y, z = cellKey(entity.root.Position)
        local k = key(x,y,z)
        grid[k] = grid[k] or {}
        grid[k][#grid[k]+1] = entity
        cellDirty[k] = true
    end

    function M.query(center, radius)
        local out = {}
        local cx, cy, cz = cellKey(center)
        local range = math.ceil(radius / CELL_SIZE)
        for dx = -range, range do
            for dy = -range, range do
                for dz = -range, range do
                    local cell = grid[key(cx+dx, cy+dy, cz+dz)]
                    if cell then
                        for i = 1, #cell do
                            local e = cell[i]
                            if e.root and e.root.Parent then
                                if (e.root.Position - center).Magnitude <= radius then
                                    out[#out+1] = e
                                end
                            end
                        end
                    end
                end
            end
        end
        return out
    end

    function M.cleanup()
        for k in pairs(cellDirty) do
            local cell = grid[k]
            if cell then
                for i = #cell, 1, -1 do
                    local e = cell[i]
                    if not e.model or not e.model.Parent or not isAlive(e) then
                        table.remove(cell, i)
                    end
                end
            end
            cellDirty[k] = nil
        end
    end

    return M
end)()

-- ================== SCANNER ==================
local UniversalScanner = (function()
    local M = {}
    local entities, entityMap = {}, {}
    local lastScan, cachedCount = 0, 0
    local dirty = true
    local liveAimFilter, filterVersion, seenFilterVersion = nil, 0, -1
    local lastDebugViz = 0

    local function enumerateModels()
        local out = {}
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("Model") then out[#out+1] = obj
            elseif obj:IsA("Folder") then
                for _, sub in ipairs(obj:GetChildren()) do
                    if sub:IsA("Model") then out[#out+1] = sub end
                end
            end
        end
        return out
    end

    local function buildEntry(model, hum, plr)
        local root = model:FindFirstChild("HumanoidRootPart")
        if not root and hum then root = hum.RootPart end
        if not root and model.PrimaryPart then root = model.PrimaryPart end
        if not root then return nil end

        local parts = collectLegacyParts(model)
        local partMap = buildPartMap(model, parts)
        local anyPart = false
        for _, g in ipairs({"Head","Torso","Limbs"}) do
            if #partMap[g] > 0 then anyPart = true; break end
        end
        if not anyPart and #parts == 0 then return nil end

        return {
            model=model, char=model, hum=hum, player=plr, isPlayer=plr~=nil,
            root=root, parts=parts, partMap=partMap,
            visible=true, lastVisibleCheck=0,
        }
    end

    local function heavyScan()
        local cam = Cam.cur or Workspace.CurrentCamera
        local camPos = cam and cam.CFrame.Position or Vector3.zero
        local maxDist = Settings.ScanMaxDist or 3000
        local fresh, freshMap, already = {}, {}, {}

        if Settings.TargetPlayers then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP and plr.Character then
                    already[plr.Character] = true
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                        if hrp and (hrp.Position - camPos).Magnitude <= maxDist then
                            local e = buildEntry(plr.Character, hum, plr)
                            if e then fresh[#fresh+1] = e; freshMap[plr.Character] = e end
                        end
                    end
                end
            end
        end

        if Settings.TargetNPCs then
            for _, model in ipairs(enumerateModels()) do
                if not already[model] and not Players:GetPlayerFromCharacter(model) then
                    if looksLikeRig(model) then
                        local hum = model:FindFirstChildOfClass("Humanoid")
                        local ok = false
                        if hum then ok = hum.Health > 0
                        else
                            local ac = model:FindFirstChildOfClass("AnimationController")
                            if ac then ok = true end
                        end
                        if ok then
                            local hrp = model:FindFirstChild("HumanoidRootPart")
                            if hrp and (hrp.Position - camPos).Magnitude <= maxDist then
                                already[model] = true
                                local e = buildEntry(model, hum, nil)
                                if e then fresh[#fresh+1] = e; freshMap[model] = e end
                            end
                        end
                    end
                end
            end
        end

        local cap = Settings.ScanMaxEntities or 200
        if #fresh > cap then
            table.sort(fresh, function(a, b)
                return (a.root.Position - camPos).Magnitude < (b.root.Position - camPos).Magnitude
            end)
            for i = cap + 1, #fresh do fresh[i] = nil end
        end

        for _, e in ipairs(fresh) do
            local prev = entityMap[e.model]
            if prev then
                e.visible = prev.visible
                e.lastVisibleCheck = prev.lastVisibleCheck
            end
        end
        entities = fresh; entityMap = freshMap
        cachedCount = #fresh

        if Settings.PerfSpatialGrid then
            SpatialGrid.clear()
            for _, e in ipairs(entities) do SpatialGrid.insert(e) end
        end
    end

    local function debugViz()
        for _, e in ipairs(entities) do
            local c = ModelDetector.classify(e.model)
            local function paint(seq, col)
                for _, p in ipairs(seq) do
                    local hl = Instance.new("Highlight")
                    hl.FillColor = col
                    hl.FillTransparency = 0.5
                    hl.OutlineColor = col:Lerp(Color3.new(1,1,1), 0.4)
                    hl.Parent = p
                    task.delay(2, function() pcall(function() hl:Destroy() end) end)
                end
            end
            paint(c.Head,  Color3.fromRGB(255,0,0))
            paint(c.Torso, Color3.fromRGB(0,255,0))
            paint(c.Limbs, Color3.fromRGB(0,0,255))
        end
    end

    function M.setFilter(f)
        if liveAimFilter ~= f then
            liveAimFilter = f
            filterVersion = filterVersion + 1
        end
    end

    function M.tick()
        local now = os.clock()
        local interval = Settings.ScanInterval or 0.2
        if dirty or (filterVersion ~= seenFilterVersion) or (now - lastScan >= interval) then
            lastScan = now
            dirty = false
            seenFilterVersion = filterVersion
            heavyScan()
            if Settings.DetectorDebug and (now - lastDebugViz > 2.0) then
                lastDebugViz = now
                pcall(debugViz)
            end
        end
    end

    function M.invalidate() dirty = true end
    function M.getEntities() return entities end
    function M.count() return cachedCount end
    function M.findEntity(model)
        for _, e in ipairs(entities) do
            if e.model == model then return e end
        end
        return nil
    end
    return M
end)()

-- ================== VISIBILITY ==================
local VisibilityCache = (function()
    local M = {}
    function M.get(entity, part)
        local cam = Cam.cur or Workspace.CurrentCamera
        if not cam then return false end
        local target = part or (entity.char and (entity.char:FindFirstChild("Head") or entity.root))
        if not target then return false end
        local camPos = cam.CFrame.Position
        local filter = {}
        if entity and entity.char then filter[#filter+1] = entity.char end
        if LP.Character then filter[#filter+1] = LP.Character end
        local ok, obscuring = pcall(function()
            return cam:GetPartsObscuringTarget({camPos, target.Position}, filter)
        end)
        if ok and obscuring then return #obscuring == 0 end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = filter
        return _WorkspaceRaycast(Workspace, camPos, target.Position - camPos, params) == nil
    end

    local function run()
        while true do
            task.wait(Settings.ScanVisibilityInterval or 0.15)
            local ents = UniversalScanner.getEntities()
            if not Settings.ESPVisibilityCheck then
                for _, e in ipairs(ents) do e.visible = true end
            else
                local now = os.clock()
                local batch = {}
                if Settings.PerfBatchVis then
                    for _, e in ipairs(ents) do
                        local qx = math.floor(e.root.Position.X / 200)
                        local qz = math.floor(e.root.Position.Z / 200)
                        local k = qx..":"..qz
                        batch[k] = batch[k] or {}
                        batch[k][#batch[k]+1] = e
                    end
                    for k, group in pairs(batch) do
                        for _, e in ipairs(group) do
                            if now - e.lastVisibleCheck > (Settings.ScanVisibilityInterval or 0.15) then
                                local target = e.char:FindFirstChild("Head") or e.root
                                e.visible = M.get(e, target)
                                e.lastVisibleCheck = now
                            end
                        end
                    end
                else
                    for _, e in ipairs(ents) do
                        if now - e.lastVisibleCheck > (Settings.ScanVisibilityInterval or 0.15) then
                            local target = e.char:FindFirstChild("Head") or e.root
                            e.visible = M.get(e, target)
                            e.lastVisibleCheck = now
                        end
                    end
                end
            end
        end
    end

    M.start = function() task.spawn(run) end
    return M
end)()

-- ================== ESP CACHE ==================
local ESPCache = (function()
    local M = {}
    local cache = setmetatable({}, {__mode="k"})
    function M.get(entity)
        local e = cache[entity]
        if not e then
            e = { lastPos = entity.root.Position, lastScreen = nil, lastUpdate = 0 }
            cache[entity] = e
        end
        return e
    end
    function M.shouldUpdate(entity, now)
        if not Settings.PerfCacheESP then return true end
        local e = M.get(entity)
        if now - e.lastUpdate < (Settings.ESPCacheInterval or 0.05) then return false end
        if (entity.root.Position - e.lastPos).Magnitude < (Settings.ESPMoveThreshold or 5) then
            return false
        end
        return true
    end
    function M.update(entity, screenPos, now)
        local e = M.get(entity)
        e.lastPos = entity.root.Position
        e.lastScreen = screenPos
        e.lastUpdate = now
    end
    return M
end)()

-- ================== SILENT AIM HOOK ==================
do
    local targetPartCache, lastCacheTime = nil, 0
    local fireCount, lastResetTime = 0, 0
    local CACHE_TTL = 0.016
    local function getTargetPart()
        local now = os.clock()
        if targetPartCache and (now - lastCacheTime) < CACHE_TTL then
            return targetPartCache
        end
        if Aimbot and Aimbot.getTargetPart then
            targetPartCache = Aimbot.getTargetPart()
            lastCacheTime = now
        end
        return targetPartCache
    end
    local old = nil
    pcall(function()
        local hmm = rawget(_G, "hookmetamethod")
        local gnm = rawget(_G, "getnamecallmethod")
        if not hmm or not gnm then return end
        old = hmm(game, "__namecall", function(self, ...)
            local method = gnm()
            local args = {...}
            if (method == "FireServer" or method == "InvokeServer")
               and Settings.SilentAim then
                local now = os.clock()
                if now - lastResetTime >= 1.0 then
                    fireCount, lastResetTime = 0, now
                end
                fireCount = fireCount + 1
                if fireCount > (Settings.SilentAimMaxFireRate or 60) then
                    Settings.SilentAim = false
                    return old(self, unpack(args))
                end
                local targetPart = getTargetPart()
                if targetPart and targetPart.Parent then
                    for i = 1, #args do
                        if typeof(args[i]) == "Vector3" then
                            args[i] = targetPart.Position
                            break
                        elseif typeof(args[i]) == "CFrame" then
                            args[i] = CFrame.new(targetPart.Position)
                            break
                        end
                    end
                end
            end
            return old(self, unpack(args))
        end)
    end)
end

-- ================== BIND SYSTEM ==================
local BindList = {
    { id="AimKey",     label="Aim Key",     icon="🎯", short="A" },
    { id="FovExpand",  label="FOV Expand",  icon="🔭", short="F" },
    { id="Trigger",    label="Trigger Bot", icon="⚡", short="T" },
    { id="Hitbox",     label="Hitbox",      icon="📦", short="H" },
    { id="Visibility", label="Visibility",  icon="👁", short="V" },
    { id="Speed",      label="SpeedHack",   icon="💨", short="S" },
    { id="Fly",        label="Fly",         icon="🕊", short="Y" },
}
local BindStates = {}
for _, b in ipairs(BindList) do BindStates[b.id] = { down=false, toggle=false } end

local function ensureBindState(id)
    if not BindStates[id] then BindStates[id] = { down=false, toggle=false } end
    return BindStates[id]
end
local function getBindKey(id) return Settings["Bind"..id.."Key"] end
local function getBindMode(id) return Settings["Bind"..id.."Mode"] or "Toggle" end
local function setBindKey(id, v)
    Settings["Bind"..id.."Key"] = v
    BindStates[id] = { down=false, toggle=false }
end
local function setBindMode(id, v)
    Settings["Bind"..id.."Mode"] = v
    BindStates[id] = { down=false, toggle=false }
end
local function isBindActive(id)
    local s = BindStates[id]
    if not s then return false end
    if getBindMode(id) == "Hold" then return s.down == true end
    return s.toggle == true
end
local function hasAnyBind()
    for _, b in ipairs(BindList) do if getBindKey(b.id) then return true end end
    return false
end

-- ================== IN-MEMORY CONFIGS (per UserId) ==================
local MemoryConfigs = (function()
    local M = {}
    local store, named = {}, {}

    local function uid()
        local ok, id = pcall(function() return LP.UserId end)
        if ok and id then return tostring(id) end
        return "0"
    end

    local function deepCopy(t)
        if type(t) ~= "table" then return t end
        local out = {}
        for k, v in pairs(t) do
            out[k] = type(v) == "table" and deepCopy(v) or v
        end
        return out
    end

    local function deepMerge(dst, src)
        for k, v in pairs(src) do
            if type(v) == "table" and type(dst[k]) == "table" then
                deepMerge(dst[k], v)
            else
                dst[k] = v
            end
        end
    end

    function M.save(name)
        name = name or Settings.CurrentConfig or "default"
        local u = uid()
        store[u] = store[u] or {}
        named[u] = named[u] or {}
        store[u][name] = deepCopy(Settings)
        local exists = false
        for _, n in ipairs(named[u]) do
            if n == name then exists = true; break end
        end
        if not exists then named[u][#named[u]+1] = name end
        Settings.CurrentConfig = name
        return true, "saved (memory)"
    end

    function M.load(name)
        name = name or Settings.CurrentConfig or "default"
        local u = uid()
        if not store[u] or not store[u][name] then return false, "not found" end
        deepMerge(Settings, store[u][name])
        Settings.CurrentConfig = name
        return true, "loaded"
    end

    function M.list()
        local u = uid()
        return named[u] or {}
    end

    function M.remove(name)
        local u = uid()
        if not store[u] or not store[u][name] then return false end
        store[u][name] = nil
        if named[u] then
            for i, n in ipairs(named[u]) do
                if n == name then table.remove(named[u], i); break end
            end
        end
        return true
    end

    function M.available() return true end
    function M.userId() return uid() end
    return M
end)()

-- ================== UI ==================
local UI = (function()
    local M = {}
    M.elements = {}
    M.listening = false
    M._activePicker = nil
    M._notifyHolder = nil

    local C = {
        bg=Color3.fromRGB(14,14,18), card=Color3.fromRGB(22,22,28),
        sidebar=Color3.fromRGB(10,10,14), border=Color3.fromRGB(40,40,50),
        text=Color3.fromRGB(235,235,245), subtext=Color3.fromRGB(130,130,150),
        accent=Color3.fromRGB(0,170,255), danger=Color3.fromRGB(255,70,60),
        track=Color3.fromRGB(44,44,54), green=Color3.fromRGB(60,210,120),
        yellow=Color3.fromRGB(255,190,60),
        popupBg=Color3.fromRGB(12,12,16),
        cardHover=Color3.fromRGB(30,30,40),
    }
    M.C = C

    local function corner(p, r)
        local c = Instance.new("UICorner", p); c.CornerRadius = UDim.new(0, r or 6); return c
    end
    local function stroke(p, col, th)
        local s = Instance.new("UIStroke", p)
        s.Color = col or C.border; s.Thickness = th or 1
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; return s
    end
    M.corner = corner; M.stroke = stroke

    function M.createWindow()
        local sg = Instance.new("ScreenGui")
        sg.Name="cfgkotik_ui"; sg.ResetOnSpawn=false
        sg.IgnoreGuiInset=true; sg.DisplayOrder=100
        protectGui(sg); sg.Parent = getParentGui()

        local main = Instance.new("Frame")
        main.Name = "main"
        main.Size=UDim2.new(0,740,0,500)
        main.Position=UDim2.new(0.5,-370,0.5,-250)
        main.BackgroundColor3=C.bg; main.BorderSizePixel=0
        main.Active=true; main.Parent=sg
        main.ClipsDescendants = true
        corner(main,12); stroke(main,C.border,1)

        local bar = Instance.new("Frame")
        bar.Size=UDim2.new(1,0,0,38); bar.BackgroundColor3=C.bg
        bar.BorderSizePixel=0; bar.Parent=main; corner(bar,12)

        local accentGlow = Instance.new("Frame")
        accentGlow.Name = "accentGlow"
        accentGlow.Size=UDim2.new(1,0,0,1); accentGlow.Position=UDim2.new(0,0,0,37)
        accentGlow.BackgroundColor3=C.accent; accentGlow.BorderSizePixel=0
        accentGlow.BackgroundTransparency = 0.5; accentGlow.Parent=main
        local ag = Instance.new("UIGradient", accentGlow)
        ag.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1),
        })

        local win = { main=main, sg=sg }
        function win:toggle()
            main.Visible = not main.Visible
            if main.Visible and win._goHome then win._goHome() end
        end

        local closeBtn = Instance.new("TextButton")
        closeBtn.Size=UDim2.new(0,11,0,11); closeBtn.Position=UDim2.new(0,18,0.5,-5.5)
        closeBtn.BackgroundColor3=C.danger; closeBtn.Text=""
        closeBtn.BorderSizePixel=0; closeBtn.Parent=bar; corner(closeBtn,6)
        closeBtn.MouseButton1Click:Connect(function() win:toggle() end)

        local minBtn = Instance.new("Frame")
        minBtn.Size=UDim2.new(0,11,0,11); minBtn.Position=UDim2.new(0,36,0.5,-5.5)
        minBtn.BackgroundColor3=Color3.fromRGB(255,189,46)
        minBtn.BorderSizePixel=0; minBtn.Parent=bar; corner(minBtn,6)

        local maxBtn = Instance.new("Frame")
        maxBtn.Size=UDim2.new(0,11,0,11); maxBtn.Position=UDim2.new(0,54,0.5,-5.5)
        maxBtn.BackgroundColor3=Color3.fromRGB(39,201,63)
        maxBtn.BorderSizePixel=0; maxBtn.Parent=bar; corner(maxBtn,6)

        local brand = Instance.new("TextLabel")
        brand.Size=UDim2.new(0,200,1,0); brand.Position=UDim2.new(0,80,0,0)
        brand.BackgroundTransparency=1; brand.Text="CFGKOTIK"
        brand.TextColor3=C.text; brand.Font=Enum.Font.GothamBlack
        brand.TextSize=13; brand.TextXAlignment=Enum.TextXAlignment.Left; brand.Parent=bar

        local verLbl = Instance.new("TextLabel")
        verLbl.Size=UDim2.new(0,80,1,0); verLbl.Position=UDim2.new(0,180,0,0)
        verLbl.BackgroundTransparency=1; verLbl.Text="v37 FINAL"
        verLbl.TextColor3=C.accent; verLbl.Font=Enum.Font.GothamBold
        verLbl.TextSize=10; verLbl.TextXAlignment=Enum.TextXAlignment.Left; verLbl.Parent=bar
        win.verLabel = verLbl

        local backBtn = Instance.new("TextButton")
        backBtn.Name = "backBtn"
        backBtn.Size = UDim2.new(0, 100, 0, 22)
        backBtn.Position = UDim2.new(0, 260, 0.5, -11)
        backBtn.BackgroundColor3 = C.card
        backBtn.Text = "← Folders"
        backBtn.TextColor3 = C.text
        backBtn.Font = Enum.Font.GothamBold
        backBtn.TextSize = 11
        backBtn.BorderSizePixel = 0
        backBtn.Visible = false
        backBtn.Parent = bar
        corner(backBtn, 5); stroke(backBtn, C.border, 1)

        local statusDot = Instance.new("Frame")
        statusDot.Size=UDim2.new(0,6,0,6); statusDot.Position=UDim2.new(1,-24,0.5,-3)
        statusDot.BackgroundColor3=C.green; statusDot.BorderSizePixel=0
        statusDot.Parent=bar; corner(statusDot,3)

        local statusLbl = Instance.new("TextLabel")
        statusLbl.Size=UDim2.new(0,110,1,0); statusLbl.Position=UDim2.new(1,-140,0,0)
        statusLbl.BackgroundTransparency=1; statusLbl.Text="online"
        statusLbl.TextColor3=C.subtext; statusLbl.Font=Enum.Font.Gotham
        statusLbl.TextSize=10; statusLbl.TextXAlignment=Enum.TextXAlignment.Right; statusLbl.Parent=bar

        local dragging, dragStart, startAbs = false, nil, nil
        bar.InputBegan:Connect(function(i)
            if i.UserInputType ~= Enum.UserInputType.MouseButton1
               and i.UserInputType ~= Enum.UserInputType.Touch then return end
            dragging = true
            dragStart = Vector2.new(i.Position.X, i.Position.Y)
            startAbs = main.AbsolutePosition
        end)
        UIS.InputChanged:Connect(function(i)
            if not dragging then return end
            if i.UserInputType ~= Enum.UserInputType.MouseMovement
               and i.UserInputType ~= Enum.UserInputType.Touch then return end
            local d = Vector2.new(i.Position.X, i.Position.Y) - dragStart
            main.Position = UDim2.new(0, startAbs.X + d.X, 0, startAbs.Y + d.Y)
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
               or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)

        local content = Instance.new("Frame")
        content.Size = UDim2.new(1, 0, 1, -40)
        content.Position = UDim2.new(0, 0, 0, 40)
        content.BackgroundTransparency = 1
        content.Parent = main

        local home = Instance.new("ScrollingFrame")
        home.Name = "home"
        home.Size = UDim2.new(1, -20, 1, -10)
        home.Position = UDim2.new(0, 10, 0, 5)
        home.BackgroundTransparency = 1; home.BorderSizePixel = 0
        home.ScrollBarThickness = 4; home.ScrollBarImageColor3 = C.accent
        home.CanvasSize = UDim2.new(0, 0, 0, 0)
        home.AutomaticCanvasSize = Enum.AutomaticSize.Y
        home.Parent = content
        local homeGrid = Instance.new("UIGridLayout", home)
        homeGrid.CellSize = UDim2.new(0, 340, 0, 130)
        homeGrid.CellPadding = UDim2.new(0, 10, 0, 10)
        homeGrid.SortOrder = Enum.SortOrder.LayoutOrder
        homeGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
        local homePad = Instance.new("UIPadding", home)
        homePad.PaddingTop = UDim.new(0, 8)
        homePad.PaddingBottom = UDim.new(0, 20)

        local pages = {}
        local currentPage = nil

        local function goHome()
            for _, p in ipairs(pages) do p.Visible = false end
            home.Visible = true
            backBtn.Visible = false
            currentPage = nil
        end

        local function openPage(page)
            for _, p in ipairs(pages) do p.Visible = false end
            home.Visible = false
            page.Visible = true
            backBtn.Visible = true
            currentPage = page
        end

        backBtn.MouseButton1Click:Connect(goHome)
        win._goHome = goHome

        local folderOrder = 0

        function win:makeTab(name, icon, desc)
            folderOrder = folderOrder + 1

            local card = Instance.new("TextButton")
            card.Name = "folder_" .. name
            card.BackgroundColor3 = C.card
            card.Text = ""
            card.BorderSizePixel = 0
            card.AutoButtonColor = false
            card.LayoutOrder = folderOrder
            card.Parent = home
            corner(card, 10); stroke(card, C.border, 1)

            local iconLbl = Instance.new("TextLabel")
            iconLbl.Size = UDim2.new(1, 0, 0, 50)
            iconLbl.Position = UDim2.new(0, 0, 0, 15)
            iconLbl.BackgroundTransparency = 1
            iconLbl.Text = icon or "📁"
            iconLbl.TextColor3 = C.accent
            iconLbl.Font = Enum.Font.GothamBold
            iconLbl.TextSize = 34
            iconLbl.Parent = card

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -20, 0, 22)
            nameLbl.Position = UDim2.new(0, 10, 0, 70)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text = name
            nameLbl.TextColor3 = C.text
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextSize = 15
            nameLbl.TextXAlignment = Enum.TextXAlignment.Center
            nameLbl.Parent = card

            local descLbl = Instance.new("TextLabel")
            descLbl.Size = UDim2.new(1, -20, 0, 18)
            descLbl.Position = UDim2.new(0, 10, 0, 94)
            descLbl.BackgroundTransparency = 1
            descLbl.Text = desc or ""
            descLbl.TextColor3 = C.subtext
            descLbl.Font = Enum.Font.Gotham
            descLbl.TextSize = 10
            descLbl.TextXAlignment = Enum.TextXAlignment.Center
            descLbl.TextWrapped = true
            descLbl.Parent = card

            local page = Instance.new("ScrollingFrame")
            page.Name = "page_" .. name
            page.Size = UDim2.new(1, -20, 1, -10)
            page.Position = UDim2.new(0, 10, 0, 5)
            page.BackgroundTransparency = 1; page.BorderSizePixel = 0
            page.ScrollBarThickness = 4; page.ScrollBarImageColor3 = C.accent
            page.CanvasSize = UDim2.new(0, 0, 0, 0)
            page.AutomaticCanvasSize = Enum.AutomaticSize.Y
            page.Visible = false
            page.Parent = content
            local lay = Instance.new("UIListLayout", page)
            lay.Padding = UDim.new(0, 10); lay.SortOrder = Enum.SortOrder.LayoutOrder
            local padLay = Instance.new("UIPadding", page)
            padLay.PaddingBottom = UDim.new(0, 20)
            padLay.PaddingTop = UDim.new(0, 8)

            pages[#pages + 1] = page

            card.MouseButton1Click:Connect(function() openPage(page) end)
            card.MouseEnter:Connect(function()
                TweenService:Create(card, TweenInfo.new(0.12), { BackgroundColor3 = C.cardHover }):Play()
            end)
            card.MouseLeave:Connect(function()
                TweenService:Create(card, TweenInfo.new(0.12), { BackgroundColor3 = C.card }):Play()
            end)

            return page
        end

        M.window = win
        return win
    end

    function M.section(parent, title)
        local card = Instance.new("Frame")
        card.BackgroundColor3 = C.card
        card.BorderSizePixel = 0
        card.Size = UDim2.new(1, -8, 0, 60)
        card.Parent = parent
        corner(card, 8); stroke(card, C.border, 1)

        local pad = Instance.new("UIPadding", card)
        pad.PaddingTop = UDim.new(0, 12); pad.PaddingBottom = UDim.new(0, 12)
        pad.PaddingLeft = UDim.new(0, 14); pad.PaddingRight = UDim.new(0, 14)

        local lay = Instance.new("UIListLayout", card)
        lay.Padding = UDim.new(0, 6); lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay.FillDirection = Enum.FillDirection.Vertical

        if title then
            local hdr = Instance.new("Frame")
            hdr.Size = UDim2.new(1, 0, 0, 16)
            hdr.BackgroundTransparency = 1; hdr.LayoutOrder = 0; hdr.Parent = card
            local accent = Instance.new("Frame")
            accent.Size = UDim2.new(0, 3, 0, 10)
            accent.Position = UDim2.new(0, 0, 0.5, -5)
            accent.BackgroundColor3 = C.accent; accent.BorderSizePixel = 0
            accent.Parent = hdr; corner(accent, 2)
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -12, 1, 0)
            lbl.Position = UDim2.new(0, 10, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = title; lbl.TextColor3 = C.text
            lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 10
            lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = hdr
        end

        lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            local h = lay.AbsoluteContentSize.Y + 24
            if h < 40 then h = 40 end
            card.Size = UDim2.new(1, -8, 0, h)
        end)
        task.defer(function()
            local h = lay.AbsoluteContentSize.Y + 24
            if h < 40 then h = 40 end
            card.Size = UDim2.new(1, -8, 0, h)
        end)
        return card
    end

    function M.toggle(parent, label, key, onChange)
        local row = Instance.new("Frame")
        row.Size=UDim2.new(1,0,0,26); row.BackgroundTransparency=1; row.Parent=parent
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(1, -50, 1, 0)
        lbl.Text=label; lbl.TextColor3=C.text
        lbl.Font=Enum.Font.Gotham; lbl.TextSize=12
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row
        local track = Instance.new("TextButton")
        track.Size=UDim2.new(0,36,0,20); track.Position=UDim2.new(1,-36,0.5,-10)
        track.BackgroundColor3=C.track; track.Text=""; track.BorderSizePixel=0
        track.Parent=row; corner(track,10)
        local knob = Instance.new("Frame")
        knob.Size=UDim2.new(0,16,0,16); knob.Position=UDim2.new(0,2,0.5,-8)
        knob.BackgroundColor3=Color3.fromRGB(255,255,255)
        knob.BorderSizePixel=0; knob.Parent=track; corner(knob,8)

        local function paint(animate)
            local on = Settings[key] and true or false
            track.BackgroundColor3 = on and C.accent or C.track
            if animate then
                TweenService:Create(knob, TweenInfo.new(0.15), {
                    Position = on and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
                }):Play()
            else
                knob.Position = on and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
            end
        end
        track.MouseButton1Click:Connect(function()
            Settings[key] = not Settings[key]; paint(true)
            if onChange then pcall(onChange, Settings[key]) end
        end)
        M.elements[#M.elements+1] = { key=key, paint=function() paint(false) end }
        paint(false)
        return row
    end

    function M.slider(parent, label, key, min, max, step, fmt)
        fmt = fmt or function(v) return string.format("%.2f", v) end
        local row = Instance.new("Frame")
        row.Size=UDim2.new(1,0,0,42); row.BackgroundTransparency=1; row.Parent=parent
        local lbl = Instance.new("TextLabel")
        lbl.Size=UDim2.new(1,-60,0,16); lbl.BackgroundTransparency=1
        lbl.Text=label; lbl.TextColor3=C.text
        lbl.Font=Enum.Font.Gotham; lbl.TextSize=12
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row
        local val = Instance.new("TextLabel")
        val.Size=UDim2.new(0,60,0,16); val.Position=UDim2.new(1,-60,0,0)
        val.BackgroundTransparency=1; val.Text=""
        val.TextColor3=C.accent; val.Font=Enum.Font.GothamBold
        val.TextSize=11; val.TextXAlignment=Enum.TextXAlignment.Right; val.Parent=row
        local hit = Instance.new("TextButton")
        hit.Size=UDim2.new(1,0,0,18); hit.Position=UDim2.new(0,0,0,22)
        hit.BackgroundTransparency=1; hit.Text=""; hit.BorderSizePixel=0; hit.Parent=row
        local track = Instance.new("Frame")
        track.Size=UDim2.new(1,0,0,4); track.Position=UDim2.new(0,0,0.5,-2)
        track.BackgroundColor3=C.track; track.BorderSizePixel=0; track.Parent=hit; corner(track,2)
        local fill = Instance.new("Frame")
        fill.Size=UDim2.new(0,0,1,0); fill.BackgroundColor3=C.accent
        fill.BorderSizePixel=0; fill.Parent=track; corner(fill,2)
        local knob = Instance.new("Frame")
        knob.Size=UDim2.new(0,12,0,12)
        knob.AnchorPoint=Vector2.new(0.5,0.5)
        knob.Position=UDim2.new(0,0,0.5,0)
        knob.BackgroundColor3=Color3.fromRGB(255,255,255)
        knob.BorderSizePixel=0; knob.ZIndex=2; knob.Parent=track; corner(knob,6)
        local dragging = false
        local function apply(mx)
            local absP = track.AbsolutePosition.X
            local absS = track.AbsoluteSize.X
            if absS <= 0 then return end
            local t = math.clamp((mx - absP) / absS, 0, 1)
            local raw = min + (max - min) * t
            raw = math.floor(raw / step + 0.5) * step
            raw = math.clamp(raw, min, max)
            Settings[key] = raw
            fill.Size = UDim2.new(t,0,1,0)
            knob.Position = UDim2.new(t,0,0.5,0)
            val.Text = fmt(raw)
        end
        hit.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true; apply(i.Position.X)
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if not dragging then return end
            if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
            apply(i.Position.X)
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        local function paint()
            local v = Settings[key] or min
            local t = math.clamp((v - min) / (max - min), 0, 1)
            fill.Size=UDim2.new(t,0,1,0)
            knob.Position=UDim2.new(t,0,0.5,0)
            val.Text=fmt(v)
        end
        M.elements[#M.elements+1] = { key=key, paint=paint }
        task.defer(paint)
        return row
    end

    function M.dropdown(parent, label, key, options, onChange)
        local row = Instance.new("Frame")
        row.Size=UDim2.new(1,0,0,26); row.BackgroundTransparency=1; row.Parent=parent
        local lbl = Instance.new("TextLabel")
        lbl.Size=UDim2.new(1,-110,1,0); lbl.BackgroundTransparency=1
        lbl.Text=label; lbl.TextColor3=C.text
        lbl.Font=Enum.Font.Gotham; lbl.TextSize=12
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row
        local btn = Instance.new("TextButton")
        btn.Size=UDim2.new(0,100,0,20); btn.Position=UDim2.new(1,-100,0.5,-10)
        btn.BackgroundColor3=C.track; btn.Text=tostring(Settings[key] or options[1])
        btn.TextColor3=C.text; btn.Font=Enum.Font.GothamBold
        btn.TextSize=10; btn.BorderSizePixel=0; btn.Parent=row; corner(btn,5)
        local panelGui, panel
        local function closePanel()
            if panelGui then panelGui:Destroy(); panelGui = nil end
            panel = nil
        end
        btn.MouseButton1Click:Connect(function()
            if panel then closePanel(); return end
            panelGui = Instance.new("ScreenGui")
            panelGui.Name="cfgkotik_dd"; panelGui.ResetOnSpawn=false
            panelGui.IgnoreGuiInset=true; panelGui.DisplayOrder=500
            protectGui(panelGui); panelGui.Parent = getParentGui()
            panel = Instance.new("Frame")
            panel.Size=UDim2.new(0,140,0,#options*22+8)
            local abs = btn.AbsolutePosition; local sz = btn.AbsoluteSize
            panel.Position = UDim2.new(0, abs.X, 0, abs.Y + sz.Y + 4)
            panel.BackgroundColor3=C.popupBg; panel.BorderSizePixel=0
            panel.Parent=panelGui; corner(panel,6); stroke(panel,C.accent,1)
            local lay = Instance.new("UIListLayout", panel)
            lay.Padding=UDim.new(0,2); lay.SortOrder=Enum.SortOrder.LayoutOrder
            local pad = Instance.new("UIPadding", panel)
            pad.PaddingTop=UDim.new(0,4); pad.PaddingBottom=UDim.new(0,4)
            pad.PaddingLeft=UDim.new(0,4); pad.PaddingRight=UDim.new(0,4)
            for _, opt in ipairs(options) do
                local ob = Instance.new("TextButton")
                ob.Size=UDim2.new(1,0,0,20); ob.BackgroundColor3=C.popupBg
                ob.Text=tostring(opt); ob.TextColor3=C.text
                ob.Font=Enum.Font.Gotham; ob.TextSize=11
                ob.TextXAlignment=Enum.TextXAlignment.Left
                ob.BorderSizePixel=0; ob.Parent=panel; corner(ob,4)
                local opad = Instance.new("UIPadding", ob); opad.PaddingLeft=UDim.new(0,6)
                ob.MouseEnter:Connect(function() ob.BackgroundColor3 = C.accent end)
                ob.MouseLeave:Connect(function() ob.BackgroundColor3 = C.popupBg end)
                ob.MouseButton1Click:Connect(function()
                    Settings[key] = opt; btn.Text = tostring(opt)
                    if onChange then pcall(onChange, opt) end
                    closePanel()
                end)
            end
            task.delay(0.1, function()
                local conn
                conn = UIS.InputBegan:Connect(function(inp)
                    if panel and inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        local mp = inp.Position
                        local pAbs = panel.AbsolutePosition
                        local pSz = panel.AbsoluteSize
                        if not (mp.X >= pAbs.X and mp.X <= pAbs.X + pSz.X
                            and mp.Y >= pAbs.Y and mp.Y <= pAbs.Y + pSz.Y) then
                            closePanel()
                            if conn then conn:Disconnect() end
                        end
                    end
                end)
            end)
        end)
        M.elements[#M.elements+1] = { key=key, paint=function() btn.Text = tostring(Settings[key] or options[1]) end }
        return row
    end

    function M.multiSelect(parent, label, key, options, onChange)
        local row = Instance.new("Frame")
        row.Size=UDim2.new(1,0,0,26); row.BackgroundTransparency=1; row.Parent=parent
        local lbl = Instance.new("TextLabel")
        lbl.Size=UDim2.new(1,-110,1,0); lbl.BackgroundTransparency=1
        lbl.Text=label; lbl.TextColor3=C.text
        lbl.Font=Enum.Font.Gotham; lbl.TextSize=12
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row
        local function summary()
            local on = {}
            for _, opt in ipairs(options) do
                if Settings[key] and Settings[key][opt] then on[#on+1] = opt end
            end
            if #on == 0 then return "—" end
            if #on == #options then return "All" end
            return table.concat(on, ",")
        end
        local btn = Instance.new("TextButton")
        btn.Size=UDim2.new(0,110,0,20); btn.Position=UDim2.new(1,-110,0.5,-10)
        btn.BackgroundColor3=C.track; btn.Text=summary()
        btn.TextColor3=C.text; btn.Font=Enum.Font.GothamBold
        btn.TextSize=10; btn.BorderSizePixel=0; btn.Parent=row; corner(btn,5)
        local panelGui, panel
        btn.MouseButton1Click:Connect(function()
            if panel then panelGui:Destroy(); panelGui = nil; panel = nil; return end
            panelGui = Instance.new("ScreenGui")
            panelGui.Name="cfgkotik_ms"; panelGui.ResetOnSpawn=false
            panelGui.IgnoreGuiInset=true; panelGui.DisplayOrder=500
            protectGui(panelGui); panelGui.Parent = getParentGui()
            panel = Instance.new("Frame")
            panel.Size=UDim2.new(0,180,0,#options*24+8)
            local abs = btn.AbsolutePosition; local sz = btn.AbsoluteSize
            panel.Position = UDim2.new(0, abs.X + sz.X - 180, 0, abs.Y + sz.Y + 4)
            panel.BackgroundColor3=C.popupBg; panel.BorderSizePixel=0
            panel.Parent=panelGui; corner(panel,6); stroke(panel,C.accent,1)
            local lay = Instance.new("UIListLayout", panel)
            lay.Padding=UDim.new(0,2); lay.SortOrder=Enum.SortOrder.LayoutOrder
            local pad = Instance.new("UIPadding", panel)
            pad.PaddingTop=UDim.new(0,4); pad.PaddingBottom=UDim.new(0,4)
            pad.PaddingLeft=UDim.new(0,4); pad.PaddingRight=UDim.new(0,4)
            for _, opt in ipairs(options) do
                local ob = Instance.new("TextButton")
                ob.Size=UDim2.new(1,0,0,20); ob.BackgroundColor3=C.popupBg
                ob.TextColor3=C.text; ob.Font=Enum.Font.Gotham
                ob.TextSize=11; ob.TextXAlignment=Enum.TextXAlignment.Left
                ob.BorderSizePixel=0; ob.Parent=panel; corner(ob,4)
                local function refresh()
                    Settings[key] = Settings[key] or {}
                    local on = Settings[key][opt]
                    ob.Text = (on and "☑ " or "☐ ") .. opt
                    ob.TextColor3 = on and C.accent or C.text
                end
                refresh()
                local opad = Instance.new("UIPadding", ob); opad.PaddingLeft=UDim.new(0,8)
                ob.MouseEnter:Connect(function() ob.BackgroundColor3 = C.accent end)
                ob.MouseLeave:Connect(function() ob.BackgroundColor3 = C.popupBg end)
                ob.MouseButton1Click:Connect(function()
                    Settings[key] = Settings[key] or {}
                    Settings[key][opt] = not Settings[key][opt]
                    refresh(); btn.Text = summary()
                    if onChange then pcall(onChange, Settings[key]) end
                end)
            end
        end)
        M.elements[#M.elements+1] = { key=key, paint=function()
            Settings[key] = Settings[key] or {}
            btn.Text = summary()
        end }
        return row
    end

    function M.keybind(parent, label, key)
        local row = Instance.new("Frame")
        row.Size=UDim2.new(1,0,0,26); row.BackgroundTransparency=1; row.Parent=parent
        local lbl = Instance.new("TextLabel")
        lbl.Size=UDim2.new(1,-130,1,0); lbl.BackgroundTransparency=1
        lbl.Text=label; lbl.TextColor3=C.text
        lbl.Font=Enum.Font.Gotham; lbl.TextSize=12
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row
        local dot = Instance.new("Frame")
        dot.Size = UDim2.fromOffset(6, 6)
        dot.AnchorPoint = Vector2.new(1, 0.5)
        dot.Position = UDim2.new(1, -116, 0.5, 0)
        dot.BackgroundColor3 = C.track
        dot.BorderSizePixel = 0
        dot.Parent = row; corner(dot, 3)
        local btn = Instance.new("TextButton")
        btn.Size=UDim2.new(0,100,0,20); btn.Position=UDim2.new(1,-100,0.5,-10)
        btn.BackgroundColor3=C.track; btn.Text=keyLabel(Settings[key]); btn.TextColor3=C.text
        btn.Font=Enum.Font.GothamBold; btn.TextSize=10
        btn.BorderSizePixel=0; btn.Parent=row; corner(btn,5)
        local function listen()
            if M.listening then return end
            M.listening = true
            btn.Text = "..."
            btn.BackgroundColor3 = C.accent
            task.spawn(function()
                task.wait(0.05)
                if not M.listening then return end
                local conn
                local function stop()
                    if conn then conn:Disconnect(); conn = nil end
                    M.listening = false
                    btn.Text = keyLabel(Settings[key])
                    btn.BackgroundColor3 = C.track
                end
                conn = UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode == Enum.KeyCode.Backspace then
                            Settings[key] = nil; stop(); return
                        end
                        if BLACKLISTED_KEYS[input.KeyCode] then return end
                        Settings[key] = input.KeyCode
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.MouseButton2
                        or input.UserInputType == Enum.UserInputType.MouseButton3 then
                        Settings[key] = input.UserInputType
                    else return end
                    stop()
                end)
            end)
        end
        btn.MouseButton1Click:Connect(listen)
        btn.MouseButton2Click:Connect(function()
            if M.listening then return end
            Settings[key] = nil
            btn.Text = keyLabel(nil)
        end)
        M.elements[#M.elements+1] = { key=key, paint=function()
            if not M.listening then btn.Text = keyLabel(Settings[key]) end
        end }
        task.spawn(function()
            while dot.Parent do
                dot.BackgroundColor3 = isInputPressed(Settings[key]) and C.green or C.track
                task.wait(0.05)
            end
        end)
        return row
    end

    function M.colorPalette(parent, label, key)
        local row = Instance.new("Frame")
        row.Size=UDim2.new(1,0,0,26); row.BackgroundTransparency=1; row.Parent=parent
        local lbl = Instance.new("TextLabel")
        lbl.Size=UDim2.new(1,-40,1,0); lbl.BackgroundTransparency=1
        lbl.Text=label; lbl.TextColor3=C.text
        lbl.Font=Enum.Font.Gotham; lbl.TextSize=12
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row
        local btn = Instance.new("TextButton")
        btn.Size=UDim2.new(0,28,0,20); btn.Position=UDim2.new(1,-28,0.5,-10)
        btn.BackgroundColor3 = Settings[key] or Color3.fromRGB(255,255,255)
        btn.Text=""; btn.BorderSizePixel=0; btn.AutoButtonColor=false
        btn.Parent=row; corner(btn,5); stroke(btn,C.border,1)
        local plus = Instance.new("TextLabel")
        plus.Size=UDim2.new(1,0,1,0); plus.BackgroundTransparency=1
        plus.Text="+"; plus.TextColor3=Color3.fromRGB(255,255,255)
        plus.Font=Enum.Font.GothamBold; plus.TextSize=12
        plus.TextStrokeTransparency=0.4
        plus.TextStrokeColor3=Color3.fromRGB(0,0,0)
        plus.Parent=btn
        btn.MouseButton1Click:Connect(function()
            if M._activePicker then pcall(function() M._activePicker:Destroy() end); M._activePicker = nil end
            local picker = M.openColorPicker(Settings[key] or Color3.fromRGB(255,255,255), function(col)
                Settings[key] = col
                btn.BackgroundColor3 = col
            end)
            M._activePicker = picker
        end)
        M.elements[#M.elements+1] = { key=key, paint=function()
            btn.BackgroundColor3 = Settings[key] or Color3.fromRGB(255,255,255)
        end }
        return row
    end

    function M.info(parent, label, keyText)
        local row = Instance.new("Frame")
        row.Size=UDim2.new(1,0,0,22); row.BackgroundTransparency=1; row.Parent=parent
        local lbl = Instance.new("TextLabel")
        lbl.Size=UDim2.new(1,-140,1,0); lbl.BackgroundTransparency=1
        lbl.Text=label; lbl.TextColor3=C.subtext
        lbl.Font=Enum.Font.Gotham; lbl.TextSize=11
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row
        local key = Instance.new("TextLabel")
        key.Size=UDim2.new(0,130,0,18); key.Position=UDim2.new(1,-130,0.5,-9)
        key.BackgroundColor3=C.card
        key.Text = keyText or "—"
        key.TextColor3=C.accent; key.Font=Enum.Font.GothamBold
        key.TextSize = 10; key.TextXAlignment = Enum.TextXAlignment.Center
        key.TextTruncate = Enum.TextTruncate.AtEnd
        key.BorderSizePixel = 0; key.Parent = row; corner(key,4)
        return row
    end

    function M.button(parent, label, cb)
        local btn = Instance.new("TextButton")
        btn.Size=UDim2.new(1,0,0,26); btn.BackgroundColor3=C.track
        btn.Text=label; btn.TextColor3=C.text
        btn.Font=Enum.Font.GothamBold; btn.TextSize=11
        btn.BorderSizePixel=0; btn.Parent=parent; corner(btn,5)
        btn.MouseButton1Click:Connect(function() if cb then pcall(cb) end end)
        return btn
    end

    function M.input(parent, label, key, placeholder, onSubmit)
        local row = Instance.new("Frame")
        row.Size=UDim2.new(1,0,0,42); row.BackgroundTransparency=1; row.Parent=parent
        local lbl = Instance.new("TextLabel")
        lbl.Size=UDim2.new(1,0,0,14); lbl.BackgroundTransparency=1
        lbl.Text=label; lbl.TextColor3=C.text
        lbl.Font=Enum.Font.Gotham; lbl.TextSize=12
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row
        local box = Instance.new("TextBox")
        box.Size=UDim2.new(1,0,0,22); box.Position=UDim2.new(0,0,0,18)
        box.BackgroundColor3=C.track; box.BorderSizePixel=0
        box.Text=Settings[key] or ""
        box.PlaceholderText=placeholder or "ввод..."
        box.PlaceholderColor3=C.subtext
        box.TextColor3=C.text
        box.Font=Enum.Font.Gotham; box.TextSize=11
        box.TextXAlignment=Enum.TextXAlignment.Left
        box.ClearTextOnFocus=false
        box.Parent=row; corner(box,5); stroke(box,C.border,1)
        local pad = Instance.new("UIPadding", box); pad.PaddingLeft=UDim.new(0,8)
        box.FocusLost:Connect(function(enter)
            Settings[key]=box.Text
            if enter and onSubmit then pcall(onSubmit, box.Text) end
        end)
        return row
    end

    function M.notify(text, kind)
        if not M._notifyHolder or not M._notifyHolder.Parent then
            local sg = Instance.new("ScreenGui")
            sg.Name="cfgkotik_notify"; sg.ResetOnSpawn=false
            sg.IgnoreGuiInset=true; sg.DisplayOrder=2000
            protectGui(sg); sg.Parent = getParentGui()
            local holder = Instance.new("Frame")
            holder.Size = UDim2.new(0, 300, 1, -60)
            holder.Position = UDim2.new(1, -320, 0, 40)
            holder.BackgroundTransparency = 1; holder.Parent = sg
            local lay = Instance.new("UIListLayout", holder)
            lay.Padding = UDim.new(0, 6)
            lay.VerticalAlignment = Enum.VerticalAlignment.Top
            lay.SortOrder = Enum.SortOrder.LayoutOrder
            M._notifyHolder = holder
        end
        local col = C.accent
        if kind == "error" then col = C.danger
        elseif kind == "success" then col = C.green end
        local box = Instance.new("Frame")
        box.Size=UDim2.new(1,0,0,38)
        box.BackgroundColor3=C.card; box.BackgroundTransparency=1
        box.BorderSizePixel=0; box.Parent=M._notifyHolder
        corner(box,8); stroke(box,col,1)
        local lbl = Instance.new("TextLabel")
        lbl.Size=UDim2.new(1,-20,1,0); lbl.Position=UDim2.new(0,12,0,0)
        lbl.BackgroundTransparency=1; lbl.Text=tostring(text)
        lbl.TextColor3=C.text; lbl.Font=Enum.Font.Gotham
        lbl.TextSize=11; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=box
        TweenService:Create(box, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
        task.spawn(function()
            task.wait(3)
            TweenService:Create(box, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
            task.wait(0.3); box:Destroy()
        end)
    end

    function M.refresh()
        for _, e in ipairs(M.elements) do pcall(function() e.paint() end) end
    end

    function M.openColorPicker(initial, onChanged)
        local sg = Instance.new("ScreenGui")
        sg.Name="cfgkotik_cp"; sg.ResetOnSpawn=false
        sg.IgnoreGuiInset=true; sg.DisplayOrder=300
        protectGui(sg); sg.Parent = getParentGui()
        local win = Instance.new("Frame")
        win.Size=UDim2.new(0,240,0,210); win.Position=UDim2.new(0.5,-120,0.5,-105)
        win.BackgroundColor3=C.popupBg; win.BorderSizePixel=0
        win.Active=true; win.Parent=sg
        corner(win,10); stroke(win,C.accent,2)
        local title = Instance.new("TextLabel")
        title.Size=UDim2.new(1,0,0,22); title.BackgroundTransparency=1
        title.Text="Цвет"; title.TextColor3=C.text
        title.Font=Enum.Font.GothamBold; title.TextSize=12; title.Parent=win
        local close = Instance.new("TextButton")
        close.Size=UDim2.new(0,20,0,20); close.Position=UDim2.new(1,-26,0,2)
        close.BackgroundColor3=C.danger; close.Text="✕"
        close.TextColor3=C.text; close.Font=Enum.Font.GothamBold
        close.TextSize=11; close.BorderSizePixel=0; close.Parent=win; corner(close,5)
        close.MouseButton1Click:Connect(function() sg:Destroy() end)
        local preview = Instance.new("Frame")
        preview.Size=UDim2.new(1,-20,0,24); preview.Position=UDim2.new(0,10,0,24)
        preview.BackgroundColor3=initial; preview.BorderSizePixel=0
        preview.Parent=win; corner(preview,5); stroke(preview,C.border,1)
        local h, s, v = initial:ToHSV()
        local function makeSlider(name, y, min, max, step, val, cb)
            local lbl = Instance.new("TextLabel")
            lbl.Size=UDim2.new(0,60,0,12); lbl.Position=UDim2.new(0,10,0,y)
            lbl.BackgroundTransparency=1; lbl.Text=name
            lbl.TextColor3=C.subtext; lbl.Font=Enum.Font.Gotham; lbl.TextSize=10
            lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=win
            local valLbl = Instance.new("TextLabel")
            valLbl.Size=UDim2.new(0,50,0,12); valLbl.Position=UDim2.new(1,-60,0,y)
            valLbl.BackgroundTransparency=1; valLbl.Text=tostring(math.floor(val*100)/100)
            valLbl.TextColor3=C.accent; valLbl.Font=Enum.Font.GothamBold
            valLbl.TextSize=10; valLbl.TextXAlignment=Enum.TextXAlignment.Right; valLbl.Parent=win
            local track = Instance.new("Frame")
            track.Size=UDim2.new(1,-20,0,4); track.Position=UDim2.new(0,10,0,y+14)
            track.BackgroundColor3=C.track; track.BorderSizePixel=0
            track.Parent=win; corner(track,2)
            local fill = Instance.new("Frame")
            fill.Size=UDim2.new(val,0,1,0); fill.BackgroundColor3=C.accent
            fill.BorderSizePixel=0; fill.Parent=track; corner(fill,2)
            local knob = Instance.new("Frame")
            knob.Size=UDim2.new(0,10,0,10)
            knob.AnchorPoint=Vector2.new(0.5,0.5)
            knob.Position=UDim2.new(val,0,0.5,0)
            knob.BackgroundColor3=Color3.fromRGB(255,255,255)
            knob.BorderSizePixel=0; knob.ZIndex=2; knob.Parent=track; corner(knob,5)
            local drag = false
            local function apply(mx)
                local absP = track.AbsolutePosition.X
                local absS = track.AbsoluteSize.X
                if absS <= 0 then return end
                local t = math.clamp((mx - absP)/absS, 0, 1)
                local raw = min + (max-min)*t
                raw = math.floor(raw/step + 0.5)*step
                raw = math.clamp(raw, min, max)
                fill.Size = UDim2.new(t,0,1,0)
                knob.Position = UDim2.new(t,0,0.5,0)
                valLbl.Text = tostring(math.floor(raw*100)/100)
                cb(raw)
            end
            track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    drag = true; apply(i.Position.X)
                end
            end)
            UIS.InputChanged:Connect(function(i)
                if not drag then return end
                if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                apply(i.Position.X)
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
            end)
        end
        local function updateColor()
            local col = Color3.fromHSV(h, s, v)
            preview.BackgroundColor3 = col
            if onChanged then pcall(onChanged, col) end
        end
        makeSlider("Hue", 58, 0, 1, 0.01, h, function(v2) h = v2; updateColor() end)
        makeSlider("Sat", 92, 0, 1, 0.01, s, function(v2) s = v2; updateColor() end)
        makeSlider("Val", 126, 0, 1, 0.01, v, function(v2) v = v2; updateColor() end)
        local palRow = Instance.new("Frame")
        palRow.Size=UDim2.new(1,-20,0,18); palRow.Position=UDim2.new(0,10,0,170)
        palRow.BackgroundTransparency=1; palRow.Parent=win
        local pl = Instance.new("UIListLayout", palRow)
        pl.FillDirection=Enum.FillDirection.Horizontal; pl.Padding=UDim.new(0,4)
        for _, c in ipairs({Color3.fromRGB(10,132,255), Color3.fromRGB(140,100,255),
            Color3.fromRGB(80,200,130), Color3.fromRGB(255,189,46),
            Color3.fromRGB(255,69,58), Color3.fromRGB(255,255,255)}) do
            local sw = Instance.new("TextButton")
            sw.Size=UDim2.new(0,18,0,18); sw.BackgroundColor3=c
            sw.Text=""; sw.BorderSizePixel=0; sw.Parent=palRow; corner(sw,4)
            sw.MouseButton1Click:Connect(function()
                local hh,ss,vv = c:ToHSV()
                h,s,v = hh,ss,vv
                updateColor()
            end)
        end
        local drag, dStart, sAbs = false, nil, nil
        title.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                drag = true; dStart = Vector2.new(i.Position.X, i.Position.Y)
                sAbs = win.AbsolutePosition
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if not drag then return end
            if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
            local d = Vector2.new(i.Position.X, i.Position.Y) - dStart
            win.Position = UDim2.new(0, sAbs.X + d.X, 0, sAbs.Y + d.Y)
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
        end)
        return sg
    end

    return M
end)()

-- ================== BIND STRIP ==================
local BindStrip = (function()
    local M = {}
    local sg, strip
    local dots = {}

    local function labelFor(entry)
        local mode = Settings.BindStripLabel or "short"
        if mode == "short" then return entry.short end
        if mode == "icon" then return entry.icon end
        if mode == "none" then return "" end
        return entry.label
    end

    local function computePreset(preset)
        local cam = Workspace.CurrentCamera
        if not cam then return Vector2.new(486, 680) end
        local vp = cam.ViewportSize
        local w = strip and strip.AbsoluteSize.X or 120
        local h = strip and strip.AbsoluteSize.Y or ((Settings.BindStripSize or 14) + 12)
        if w <= 0 then w = 120 end
        if h <= 0 then h = (Settings.BindStripSize or 14) + 12 end
        if preset == "Top Center"    then return Vector2.new(vp.X/2 - w/2, 12)
        elseif preset == "Bottom Center" then return Vector2.new(vp.X/2 - w/2, vp.Y - h - 12)
        elseif preset == "Top Left"      then return Vector2.new(12, 12)
        elseif preset == "Top Right"     then return Vector2.new(vp.X - w - 12, 12)
        elseif preset == "Bottom Left"   then return Vector2.new(12, vp.Y - h - 12)
        elseif preset == "Bottom Right"  then return Vector2.new(vp.X - w - 12, vp.Y - h - 12)
        else return Vector2.new(Settings.BindStripX or 486, Settings.BindStripY or 680) end
    end

    function M.applyPreset()
        if not strip then return end
        if Settings.BindStripPosition and Settings.BindStripPosition ~= "Custom" then
            local p = computePreset(Settings.BindStripPosition)
            Settings.BindStripX = p.X
            Settings.BindStripY = p.Y
            strip.Position = UDim2.new(0, p.X, 0, p.Y)
        else
            strip.Position = UDim2.new(0, Settings.BindStripX or 486, 0, Settings.BindStripY or 680)
        end
    end

    local function create()
        sg = Instance.new("ScreenGui")
        sg.Name = "cfgkotik_bindstrip"; sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true; sg.DisplayOrder = 190
        protectGui(sg); sg.Parent = getParentGui()
        strip = Instance.new("Frame")
        strip.AutomaticSize = Enum.AutomaticSize.X
        local sz = Settings.BindStripSize or 14
        strip.Size = UDim2.new(0, 0, 0, sz + 12)
        strip.Position = UDim2.new(0, Settings.BindStripX or 486, 0, Settings.BindStripY or 680)
        strip.BackgroundColor3 = UI.C.bg
        strip.BackgroundTransparency = 0.25
        strip.BorderSizePixel = 0; strip.Active = true; strip.Parent = sg
        UI.corner(strip, 8); UI.stroke(strip, UI.C.border, 1)
        local pad = Instance.new("UIPadding", strip)
        pad.PaddingTop = UDim.new(0, 4); pad.PaddingBottom = UDim.new(0, 4)
        pad.PaddingLeft = UDim.new(0, 6); pad.PaddingRight = UDim.new(0, 6)
        local lay = Instance.new("UIListLayout", strip)
        lay.FillDirection = Enum.FillDirection.Horizontal
        lay.Padding = UDim.new(0, 4)
        lay.VerticalAlignment = Enum.VerticalAlignment.Center
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        local dragging, dStart, sAbs = false, nil, nil
        strip.InputBegan:Connect(function(i)
            if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if not (UI.window and UI.window.main and UI.window.main.Visible) then return end
            dragging = true
            dStart = Vector2.new(i.Position.X, i.Position.Y)
            sAbs = strip.AbsolutePosition
        end)
        UIS.InputChanged:Connect(function(i)
            if not dragging then return end
            if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
            local d = Vector2.new(i.Position.X, i.Position.Y) - dStart
            local cam = Workspace.CurrentCamera
            local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
            local fw, fh = strip.AbsoluteSize.X, strip.AbsoluteSize.Y
            local nx = math.clamp(sAbs.X + d.X, 0, math.max(0, vp.X - fw))
            local ny = math.clamp(sAbs.Y + d.Y, 0, math.max(0, vp.Y - fh))
            strip.Position = UDim2.new(0, nx, 0, ny)
            Settings.BindStripX = nx; Settings.BindStripY = ny
            Settings.BindStripPosition = "Custom"
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
    end

    local function makeDot(entry, order)
        local sz = Settings.BindStripSize or 14
        local dot = Instance.new("TextButton")
        dot.Size = UDim2.fromOffset(sz, sz)
        dot.BackgroundColor3 = UI.C.card
        dot.Text = labelFor(entry)
        dot.TextColor3 = UI.C.subtext
        dot.Font = Enum.Font.GothamBold
        dot.TextSize = sz <= 12 and 8 or (sz <= 16 and 9 or 10)
        dot.BorderSizePixel = 0
        dot.LayoutOrder = order
        dot.AutoButtonColor = false
        dot.Parent = strip
        UI.corner(dot, 4)
        local st = UI.stroke(dot, UI.C.border, 1)
        local function refresh()
            local bound = getBindKey(entry.id) ~= nil
            local active = isBindActive(entry.id)
            dot.Visible = bound
            dot.Text = labelFor(entry)
            if active then
                dot.BackgroundColor3 = UI.C.green
                dot.TextColor3 = Color3.fromRGB(10,10,14)
                st.Color = UI.C.green
            else
                dot.BackgroundColor3 = UI.C.card
                dot.TextColor3 = UI.C.subtext
                st.Color = UI.C.border
            end
        end
        dot.MouseButton1Click:Connect(function()
            if not getBindKey(entry.id) then return end
            local mode = getBindMode(entry.id)
            local s = ensureBindState(entry.id)
            if mode == "Toggle" then s.toggle = not s.toggle end
            refresh()
        end)
        dots[entry.id] = { dot=dot, st=st, refresh=refresh }
        refresh()
    end

    function M.rebuild()
        if not strip then return end
        for _, d in pairs(dots) do pcall(function() d.dot:Destroy() end) end
        dots = {}
        local sz = Settings.BindStripSize or 14
        strip.Size = UDim2.new(0, 0, 0, sz + 12)
        local order = 1
        for _, entry in ipairs(BindList) do
            makeDot(entry, order); order = order + 1
        end
        M.applyPreset()
    end

    function M.start()
        create(); M.rebuild()
        task.spawn(function()
            local lastLabel = Settings.BindStripLabel
            local lastSize = Settings.BindStripSize
            local lastPreset = Settings.BindStripPosition
            local lastVpSize = nil
            while sg and sg.Parent do
                local cam = Workspace.CurrentCamera
                local vp = cam and cam.ViewportSize or Vector2.new(1280,720)
                if Settings.BindStripPosition ~= "Custom" then
                    if Settings.BindStripPosition ~= lastPreset
                       or (lastVpSize and (vp - lastVpSize).Magnitude > 1) then
                        M.applyPreset()
                        lastPreset = Settings.BindStripPosition
                        lastVpSize = vp
                    end
                else
                    strip.Position = UDim2.new(0, Settings.BindStripX or 486, 0, Settings.BindStripY or 680)
                    lastPreset = "Custom"
                end
                local anyBound = hasAnyBind()
                strip.Visible = Settings.BindStripEnabled and anyBound
                if Settings.BindStripLabel ~= lastLabel or Settings.BindStripSize ~= lastSize then
                    lastLabel = Settings.BindStripLabel
                    lastSize = Settings.BindStripSize
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

-- ================== PING ==================
local pingCache = { val = 0, at = 0 }
local function getPing()
    local now = os.clock()
    if now - pingCache.at > 0.5 then
        local ok, p = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        pingCache.val = (ok and p and p / 1000) or 0
        pingCache.at = now
    end
    return pingCache.val
end

-- ================== AIMBOT ==================
local Aimbot = (function()
    local M = {}
    local clamp=math.clamp; local exp=math.exp; local lookAt=CFrame.lookAt
    local st = {
        target=nil, targetPart=nil, lastSeen=0,
        initialized=false, lastFrame=0, lastTrigger=0, targetName=nil,
        fovMult=1.0, fovResetAt=0,
        lastFilter=nil,
        posHistory = {},
        failCount = 0, lastFailTime = 0,
    }
    local SMOOTH_PRESETS = {
        Smooth = { smooth = 0.5, maxAng = 450 },
        Ultra  = { smooth = 1.0, maxAng = 750 },
        Soft   = { smooth = 2.0, maxAng = 0 },
    }
    local function sameTeam(plr)
        if not Settings.TeamCheck then return false end
        if plr == LP then return true end
        if plr.Team and LP.Team and plr.Team == LP.Team then return true end
        local ok, same = pcall(function()
            return plr.TeamColor and LP.TeamColor and plr.TeamColor == LP.TeamColor
        end)
        if ok and same then return true end
        return false
    end
    local function toScreen(wp)
        local cam = Cam.cur or Workspace.CurrentCamera
        if not cam then return nil end
        local ok, sp, on = pcall(function() return cam:WorldToViewportPoint(wp) end)
        if not ok or not sp then return nil end
        if not on and sp.Z <= 0 then return nil end
        return Vector2.new(sp.X, sp.Y)
    end
    local function score(sd, wd, hum)
        local pr = Settings.Priority or "FOV"
        if pr == "Distance" then return wd end
        if pr == "Health" then return hum and hum.Health or 100 end
        return sd
    end
    local function filterName(e)
        if e.isPlayer and e.player then return e.player.Name end
        if e.char then return e.char.Name end
        return nil
    end
    local function passesFilter(e)
        local n = filterName(e)
        if not n then return true end
        local bl = Settings.TargetBlacklist
        if bl and bl[n] then return false end
        local wl = Settings.TargetWhitelist
        if wl and next(wl) ~= nil and not wl[n] then return false end
        return true
    end

    local function scan(center, fovRadius)
        local cam = Cam.cur or Workspace.CurrentCamera
        if not cam then return false end
        local camPos = cam.CFrame.Position
        local camLook = cam.CFrame.LookVector
        local entities
        if Settings.PerfSpatialGrid then
            entities = SpatialGrid.query(camPos, fovRadius * 2)
        else
            entities = UniversalScanner.getEntities()
        end
        local sel = Settings.AimPartList or {}
        local pr = Settings.Priority or "FOV"
        local bestE, bestP, bestS = nil, nil, math.huge
        for _, e in ipairs(entities) do
            if isAlive(e) and passesFilter(e) then
                local skipTeam = false
                if e.isPlayer and sameTeam(e.player) then skipTeam = true end
                if not skipTeam then
                    local toRoot = e.root.Position - camPos
                    if toRoot.Magnitude > 0.01 then
                        local dot = toRoot.Unit:Dot(camLook)
                        if dot > -0.2 then
                            local pm = e.partMap
                            if pm then
                                for grp, list in pairs(pm) do
                                    if sel[grp] then
                                        for i = 1, #list do
                                            local part = list[i]
                                            if part and part.Parent then
                                                local sp = toScreen(part.Position)
                                                if sp then
                                                    local sd = (sp - center).Magnitude
                                                    local inFov = (pr == "Crosshair") or (sd <= fovRadius)
                                                    if inFov and e.visible then
                                                        local wd = (part.Position - camPos).Magnitude
                                                        local s = score(sd, wd, e.hum)
                                                        if grp == "Head" then s = s * 0.9 end
                                                        if s < bestS then bestE, bestP, bestS = e, part, s end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            else
                                for i = 1, #e.parts do
                                    local part = e.parts[i]
                                    if part and part.Parent then
                                        local grp = partGroup(part.Name)
                                        if grp and sel[grp] then
                                            local sp = toScreen(part.Position)
                                            if sp then
                                                local sd = (sp - center).Magnitude
                                                local inFov = (pr == "Crosshair") or (sd <= fovRadius)
                                                if inFov and e.visible then
                                                    local wd = (part.Position - camPos).Magnitude
                                                    local s = score(sd, wd, e.hum)
                                                    if part.Name == "Head" then s = s * 0.9 end
                                                    if s < bestS then bestE, bestP, bestS = e, part, s end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if bestE then
            if st.target ~= bestE then
                st.targetName = bestE.isPlayer and bestE.player.Name
                                 or ("[NPC] " .. bestE.char.Name)
            end
            st.target, st.targetPart, st.lastSeen = bestE, bestP, os.clock()
            return true
        end
        return false
    end
    local function shouldAim()
        if not Settings.Aimbot then return false end
        if Settings.AimMode == "Always" then return true end
        if isInputPressed(Settings.AimKey) then return true end
        if isBindActive("AimKey") then return true end
        return false
    end
    local function predict(part)
        local mult = Settings.PredAmount or 1.0
        if mult <= 0 then return part.Position end
        local ping = clamp(getPing() * mult, 0, 0.5)
        local v = part.AssemblyLinearVelocity
        if not v then return part.Position end
        local pos = part.Position + v * ping
        if Settings.AimGravityComp then
            local ent = UniversalScanner.findEntity(part.Parent)
            local hum = ent and ent.hum
            if hum then
                local ok, state = pcall(function() return hum:GetState() end)
                if ok and state and (state == Enum.HumanoidStateType.Freefall
                   or state == Enum.HumanoidStateType.Flying) then
                    local g = Workspace.Gravity or 196.2
                    pos = pos - Vector3.new(0, 0.5 * g * ping * ping, 0)
                end
            end
        end
        return pos
    end
    local function smooth(goalCF, dt)
        local mode = Settings.AimSmoothMode or "Smooth"
        local preset = SMOOTH_PRESETS[mode] or SMOOTH_PRESETS.Smooth
        local cam = Cam.cur or Workspace.CurrentCamera
        if not cam then return goalCF end
        local cur = cam.CFrame
        local d = clamp(cur.LookVector:Dot(goalCF.LookVector), -1, 1)
        local deg = math.deg(math.acos(d))
        local boost = clamp(deg / 30, 1.0, 3.0)
        local a = clamp(1 - exp(-preset.smooth * boost * dt * 60), 0, 1)
        local nc = cur:Lerp(goalCF, a)
        if preset.maxAng > 0 then
            local maxDeg = preset.maxAng * dt
            if deg > maxDeg and deg > 0 then nc = cur:Lerp(nc, maxDeg / deg) end
        end
        local j = Settings.Jitter or 0
        if j > 0 then
            local amt = j * 0.01
            nc = nc * CFrame.Angles((math.random()-0.5)*amt, (math.random()-0.5)*amt, 0)
        end
        return nc
    end

    local function recordPos(part, now)
        if not part or not part.Parent then
            st.posHistory = {}
            return
        end
        table.insert(st.posHistory, 1, { pos = part.Position, t = now })
        local cap = Settings.PredHistory or 5
        while #st.posHistory > cap do table.remove(st.posHistory) end
    end

    local function calcAccel()
        if #st.posHistory < 3 then return Vector3.zero end
        local p1, p2, p3 = st.posHistory[1], st.posHistory[2], st.posHistory[3]
        local dt1 = p1.t - p2.t
        local dt2 = p2.t - p3.t
        if dt1 <= 0 or dt2 <= 0 then return Vector3.zero end
        local v1 = (p1.pos - p2.pos) / dt1
        local v2 = (p2.pos - p3.pos) / dt2
        return (v1 - v2) / ((dt1 + dt2) / 2)
    end

    local function predictiveSmooth(goalCF, dt)
        local cam = Cam.cur or Workspace.CurrentCamera
        if not cam then return goalCF end
        local cur = cam.CFrame
        local target = st.targetPart
        if not target or not target.Parent or #st.posHistory < 3 then
            return smooth(goalCF, dt)
        end
        local accel = Settings.PredAccel and calcAccel() or Vector3.zero
        local vel = target.AssemblyLinearVelocity or Vector3.zero
        local velMag = vel.Magnitude
        local camRight = cur.RightVector
        local camUp    = cur.UpVector
        local velProj  = Vector2.new(vel:Dot(camRight), vel:Dot(camUp))
        local futureOffset = velProj * (dt * 2)
        local leadPos = target.Position
            + camRight * futureOffset.X
            + camUp * futureOffset.Y
        if accel.Magnitude > 0 then
            leadPos = leadPos + accel * (dt * dt)
        end
        local toLead = (leadPos - cur.Position).Unit
        local d = clamp(cur.LookVector:Dot(toLead), -1, 1)
        local angularDist = math.deg(math.acos(d))
        local leadStrength = clamp(velMag / 50, 0.2, 1.0)
        local baseSmooth   = 0.3 * leadStrength
        local boost        = clamp(angularDist / 30, 1.0, 3.0)
        local alpha        = clamp(baseSmooth * boost * dt * 60, 0, 1)
        local finalCF = cur:Lerp(CFrame.lookAt(cur.Position, leadPos), alpha)
        local j = Settings.Jitter or 0
        if j > 0 then
            local amt = j * 0.01
            finalCF = finalCF * CFrame.Angles(
                (math.random()-0.5)*amt,
                (math.random()-0.5)*amt,
                0
            )
        end
        return finalCF
    end

    local function getFovMult(hasBaseTarget)
        local now = os.clock()
        if st.fovMult > 1.0 and now < st.fovResetAt then return st.fovMult end
        st.fovMult = 1.0
        if Settings.FovExpandStationary and not hasBaseTarget
           and (Settings.FovExpand or isBindActive("FovExpand")) then
            return Settings.FovExpandStationaryMult or 1.3
        end
        return 1.0
    end
    local function triggerFovExpand()
        if not Settings.FovExpand and not isBindActive("FovExpand") then return end
        st.fovMult = Settings.FovExpandMult or 1.3
        st.fovResetAt = os.clock() + (Settings.FovExpandHold or 0.5)
    end

    local function adaptiveFactor()
        if not Settings.AdaptiveFov then return 1.0 end
        local fps = HUD and HUD.getFps and HUD.getFps() or 60
        if fps > 0 and fps < (Settings.MinFpsThreshold or 45) then
            return Settings.AdaptiveFovFactor or 0.8
        end
        return 1.0
    end

    local function antiDetectDelay(base)
        if not Settings.AntiDetectionJitter then return base end
        return base + (math.random() - 0.5) * 0.02
    end

    local function apply()
        if not shouldAim() then
            st.targetName = nil
            st.target, st.targetPart = nil, nil
            st.posHistory = {}
            st.failCount = 0
            return
        end
        local cam = Cam.cur or Workspace.CurrentCamera
        if not cam then return end
        if not LP.Character or not LP.Character:FindFirstChildOfClass("Humanoid") then return end
        local now = os.clock()
        local dt = st.lastFrame > 0 and (now - st.lastFrame) or (1/60)
        st.lastFrame = now
        if dt > 0.1 then dt = 0.1 end
        if st.target and not isAlive(st.target) then
            st.target, st.targetPart = nil, nil
            st.posHistory = {}
        end
        if Settings.AimPartList ~= st.lastFilter then
            UniversalScanner.setFilter(Settings.AimPartList)
            st.lastFilter = Settings.AimPartList
        end
        local cursor = UIS:GetMouseLocation()
        local baseFov = Settings.FOV * adaptiveFactor()
        local found = scan(cursor, baseFov * getFovMult(true))
        if not found then
            local expanded = getFovMult(false)
            if expanded > 1.0 then found = scan(cursor, baseFov * expanded) end
        end
        if not found and st.targetPart then
            local p = st.targetPart
            if p.Parent and st.target and isAlive(st.target)
               and (now - st.lastSeen) < (Settings.StickyTime or 0.25) then
                local inRadar = false
                if Settings.RadarEnabled then
                    local lpChar = LP.Character
                    if lpChar then
                        local lpRoot = lpChar:FindFirstChild("HumanoidRootPart")
                        if lpRoot and st.target.root then
                            local d = (st.target.root.Position - lpRoot.Position).Magnitude
                            if d <= (Settings.RadarRange or 300) then
                                inRadar = true
                            end
                        end
                    end
                end
                if Settings.AimStickyStrict then
                    local dist = (p.Position - cam.CFrame.Position).Magnitude
                    local maxSticky = Settings.ScanMaxDist or 3000
                    if dist <= maxSticky then
                        if not Settings.Visibility or st.target.visible then
                            found = true
                        else
                            st.target, st.targetPart = nil, nil
                            st.posHistory = {}
                        end
                    else
                        st.target, st.targetPart = nil, nil
                        st.posHistory = {}
                    end
                elseif inRadar then
                    st.lastSeen = now
                    found = true
                else
                    found = true
                end
            end
        end
        if not found and (Settings.FovExpand or isBindActive("FovExpand")) then
            triggerFovExpand()
            scan(cursor, baseFov * getFovMult(false))
        end
        if not found then
            st.failCount = st.failCount + 1
            if st.failCount >= 3 and (now - st.lastFailTime > 1) then
                Settings._UseLegacyScan = true
                UI.notify("Fallback to legacy scan", "error")
                st.lastFailTime = now
                UniversalScanner.invalidate()
            end
        else
            if st.failCount > 0 then
                st.failCount = 0
                Settings._UseLegacyScan = false
            end
        end
        if not st.targetPart or not st.targetPart.Parent then
            st.posHistory = {}
            return
        end
        if not st.target or not isAlive(st.target) then
            st.target, st.targetPart = nil, nil
            st.posHistory = {}
            return
        end
        recordPos(st.targetPart, now)
        local chance = Settings.HitChance or 100
        if chance < 100 and math.random() * 100 > chance then return end
        cam.CFrame = predictiveSmooth(lookAt(cam.CFrame.Position, predict(st.targetPart)), dt)
        if Settings.TriggerBot or isBindActive("Trigger") then
            local delay = antiDetectDelay(Settings.TriggerDelay or 0.1)
            if now - st.lastTrigger >= delay then
                pcall(function()
                    local sp = cam:WorldToViewportPoint(st.targetPart.Position)
                    local vim = game:GetService("VirtualInputManager")
                    vim:SendMouseMoveEvent(sp.X, sp.Y, false, game)
                    vim:SendMouseButtonEvent(sp.X, sp.Y, 0, true, game, 1)
                    vim:SendMouseButtonEvent(sp.X, sp.Y, 0, false, game, 1)
                end)
                st.lastTrigger = now
            end
        end
    end
    function M.start()
        if st.initialized then return end
        st.initialized = true
        safeBind("Aim_Apply", Enum.RenderPriority.Camera.Value - 1, apply)
    end
    function M.getTargetName() return st.targetName end
    function M.hasTarget() return st.target ~= nil and st.targetPart ~= nil end
    function M.getTargetPart() return st.targetPart end
    function M.addWhitelist(n)
        if not n then return end
        Settings.TargetWhitelist[n] = true
        Settings.TargetBlacklist[n] = nil
    end
    function M.addBlacklist(n)
        if not n then return end
        Settings.TargetBlacklist[n] = true
        Settings.TargetWhitelist[n] = nil
    end
    function M.clearLists()
        Settings.TargetWhitelist = {}
        Settings.TargetBlacklist = {}
    end
    return M
end)()

-- ================== ESP ==================
local ESP = (function()
    local M = {}
    local pool = setmetatable({}, { __mode = "k" })
    local lastUpdate = 0

    local function pickColor(dist, baseCol)
        if not Settings.ESPDistanceColors then return baseCol end
        local n = Settings.ESPNearThreshold or 50
        local m = Settings.ESPMidThreshold or 200
        if dist <= n then return Settings.ESPNearColor or baseCol end
        if dist <= m then return Settings.ESPMidColor or baseCol end
        return Settings.ESPFarColor or baseCol
    end

    local function inViewFrustum(pos)
        local cam = Cam.cur or Workspace.CurrentCamera
        if not cam then return false end
        local _, onScreen = cam:WorldToViewportPoint(pos)
        return onScreen
    end

    local function new(ent)
        if pool[ent] then return pool[ent] end
        local d = {}
        d.box = Drawing.new("Square")
        d.box.Thickness = 1.5; d.box.Filled = false; d.box.Visible = false
        d.corner = {}
        for i = 1, 4 do
            d.corner[i] = Drawing.new("Line")
            d.corner[i].Thickness = 2
            d.corner[i].Visible = false
        end
        d.name = Drawing.new("Text")
        d.name.Size = 13; d.name.Center = true
        d.name.Outline = true; d.name.Visible = false
        d.hpBg = Drawing.new("Square")
        d.hpBg.Filled = true; d.hpBg.Thickness = 0
        d.hpBg.Color = Color3.fromRGB(20,20,20); d.hpBg.Visible = false
        d.hp = Drawing.new("Square")
        d.hp.Filled = true; d.hp.Thickness = 0; d.hp.Visible = false
        d.tracer = Drawing.new("Line")
        d.tracer.Thickness = 1; d.tracer.Visible = false
        d.weapon = Drawing.new("Text")
        d.weapon.Size = 12; d.weapon.Center = true
        d.weapon.Outline = true; d.weapon.Visible = false
        d.highlight = nil
        pool[ent] = d
        return d
    end

    local function hide(d)
        if not d then return end
        d.box.Visible = false
        for i = 1, 4 do d.corner[i].Visible = false end
        d.name.Visible = false
        d.hpBg.Visible = false; d.hp.Visible = false
        d.tracer.Visible = false; d.weapon.Visible = false
        if d.highlight then d.highlight.Enabled = false end
    end

    local function ensureHighlight(d, char)
        if d.highlight and d.highlight.Parent then return end
        if not Settings.ESPHighlight then return end
        local h = Instance.new("Highlight")
        h.Name = "cfgkotik_hl"
        h.FillTransparency = 0.6
        h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = char
        d.highlight = h
    end

    local function drawCornerBox(d, x, y, w, h, col)
        local len = math.min(w, h) * 0.25
        local pts = {
            {x, y, x+len, y}, {x, y, x, y+len},
            {x+w, y, x+w-len, y}, {x+w, y, x+w, y+len},
            {x, y+h, x+len, y+h}, {x, y+h, x, y+h-len},
            {x+w, y+h, x+w-len, y+h}, {x+w, y+h, x+w, y+h-len},
        }
        for i = 1, 4 do
            local ln = d.corner[i]
            ln.Visible = true
            ln.Color = col
            ln.From = Vector2.new(pts[i*2-1][1], pts[i*2-1][2])
            ln.To = Vector2.new(pts[i*2][1], pts[i*2][2])
        end
    end

    local function render()
        if not Settings.ESP then
            for _, d in pairs(pool) do hide(d) end
            return
        end
        local cam = Cam.cur or Workspace.CurrentCamera
        if not cam then return end
        local entities = UniversalScanner.getEntities()
        local camPos = cam.CFrame.Position
        local camLook = cam.CFrame.LookVector
        local vp = cam.ViewportSize
        local seen = {}
        local interval = Settings.ESPUpdateRate or 0.03
        local now = os.clock()
        local doUpdate = (now - lastUpdate >= interval)
        local maxDist = Settings.ESPMaxDist

        for _, ent in ipairs(entities) do
            if (ent.isPlayer and Settings.ESPShowPlayers) or (not ent.isPlayer and Settings.ESPShowNPCs) then
                local char = ent.char
                local root = ent.root
                if char and char.Parent and isAlive(ent) and root then
                    local dist = (root.Position - camPos).Magnitude
                    if dist <= maxDist and inViewFrustum(root.Position) then
                        local col = pickColor(dist, Settings.ESPColor)
                        local toTarget = (root.Position - camPos).Unit
                        local dot = toTarget:Dot(camLook)
                        if dot > -0.1 then
                            local spRoot, onScreen = cam:WorldToViewportPoint(root.Position)
                            if onScreen and spRoot.Z > 0 then
                                seen[char] = true
                                local d = new(char)
                                local canUpdate = doUpdate and (ESPCache.shouldUpdate(ent, now) or not Settings.PerfCacheESP)
                                if canUpdate then
                                    local hum = ent.hum
                                    local head = char:FindFirstChild("Head")
                                    local topWorld = (head and head.Position + Vector3.new(0, 0.5, 0))
                                                   or (root.Position + Vector3.new(0, 3, 0))
                                    local botWorld = root.Position - Vector3.new(0, 3, 0)
                                    local topS, topOn = cam:WorldToViewportPoint(topWorld)
                                    local botS, botOn = cam:WorldToViewportPoint(botWorld)
                                    if topOn and botOn then
                                        local hh = math.abs(botS.Y - topS.Y)
                                        if hh < 4 then hh = 30 end
                                        local w = hh * 0.55
                                        local x, y = topS.X - w/2, topS.Y
                                        if Settings.ESPBox then
                                            if Settings.ESPBoxStyle == "corner" then
                                                d.box.Visible = false
                                                drawCornerBox(d, x, y, w, hh, col)
                                            else
                                                for i = 1, 4 do d.corner[i].Visible = false end
                                                d.box.Visible = true
                                                d.box.Size = Vector2.new(w, hh)
                                                d.box.Position = Vector2.new(x, y)
                                                d.box.Color = col
                                            end
                                        else
                                            d.box.Visible = false
                                            for i = 1, 4 do d.corner[i].Visible = false end
                                        end
                                        local labelY = y - 16
                                        if Settings.ESPName then
                                            d.name.Visible = true
                                            local label = ent.isPlayer and ent.player.Name or ("[NPC] " .. char.Name)
                                            if Settings.ESPDistance then
                                                label = label .. " [" .. math.floor(dist) .. "m]"
                                            end
                                            if Settings.ESPVisibilityCheck and Settings.ESPShowVisLabel then
                                                label = label .. (ent.visible and " • vis" or " • hid")
                                            end
                                            d.name.Text = label
                                            d.name.Position = Vector2.new(topS.X, labelY)
                                            d.name.Color = col
                                            labelY = labelY - 14
                                        else d.name.Visible = false end
                                        if Settings.ESPWeapon then
                                            local tool = char:FindFirstChildOfClass("Tool")
                                            if tool then
                                                d.weapon.Visible = true
                                                d.weapon.Text = "[" .. tool.Name .. "]"
                                                d.weapon.Position = Vector2.new(topS.X, labelY)
                                                d.weapon.Color = Color3.fromRGB(255, 220, 120)
                                            else d.weapon.Visible = false end
                                        else d.weapon.Visible = false end
                                        if Settings.ESPHealth then
                                            local frac
                                            if hum and hum.MaxHealth and hum.MaxHealth > 0 then
                                                frac = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                                            else frac = 1 end
                                            local bh = hh * frac
                                            d.hpBg.Visible = true
                                            d.hpBg.Size = Vector2.new(3, hh)
                                            d.hpBg.Position = Vector2.new(x - 6, y)
                                            d.hp.Visible = true
                                            d.hp.Size = Vector2.new(3, bh)
                                            d.hp.Position = Vector2.new(x - 6, y + (hh - bh))
                                            d.hp.Color = Color3.fromRGB(230,80,100):Lerp(Color3.fromRGB(80,200,130), frac)
                                        else
                                            d.hpBg.Visible = false; d.hp.Visible = false
                                        end
                                        if Settings.ESPTracers then
                                            local from
                                            if Settings.ESPTracerFrom == "Top" then from = Vector2.new(vp.X/2, 0)
                                            elseif Settings.ESPTracerFrom == "Mouse" then from = UIS:GetMouseLocation()
                                            else from = Vector2.new(vp.X/2, vp.Y) end
                                            d.tracer.Visible = true
                                            d.tracer.From = from
                                            d.tracer.To = Vector2.new(topS.X, y + hh)
                                            d.tracer.Color = col
                                        else d.tracer.Visible = false end
                                        ESPCache.update(ent, Vector2.new(topS.X, topS.Y), now)
                                    else hide(d) end
                                end
                                if Settings.ESPHighlight then
                                    ensureHighlight(d, char)
                                    if d.highlight then
                                        d.highlight.Enabled = true
                                        d.highlight.OutlineColor = col
                                        if Settings.ESPHighlightOccluded then
                                            d.highlight.DepthMode = Enum.HighlightDepthMode.Occluded
                                            d.highlight.FillColor = Color3.fromRGB(
                                                math.floor(col.R * 80),
                                                math.floor(col.G * 80),
                                                math.floor(col.B * 80)
                                            )
                                            d.highlight.FillTransparency = 0.7
                                        else
                                            d.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                            d.highlight.FillColor = col
                                            d.highlight.FillTransparency = 0.6
                                        end
                                    end
                                elseif d.highlight then d.highlight.Enabled = false end
                            end
                        end
                    else
                        local d = pool[char]
                        if d then hide(d) end
                    end
                end
            end
        end
        lastUpdate = now
        for model, d in pairs(pool) do
            if not seen[model] then
                hide(d)
                if not model.Parent then
                    if d.highlight then pcall(function() d.highlight:Destroy() end) end
                    pcall(function() d.box:Remove() end)
                    pcall(function() d.name:Remove() end)
                    pcall(function() d.hpBg:Remove() end)
                    pcall(function() d.hp:Remove() end)
                    pcall(function() d.tracer:Remove() end)
                    pcall(function() d.weapon:Remove() end)
                    for i = 1, 4 do pcall(function() d.corner[i]:Remove() end) end
                    pool[model] = nil
                end
            end
        end
    end

    function M.start() safeRender(render) end
    return M
end)()

-- ================== AUTOPARRY ==================
local AutoParry = (function()
    local M = {}
    local lastParry = 0
    local hookedAnims = setmetatable({}, { __mode = "k" })
    local ATTACK_HINTS = {"slash","swing","attack","stab","punch","hit","combo","strike","smash"}
    local function isAttackAnim(animId, animName)
        local s = (tostring(animId) .. " " .. tostring(animName)):lower()
        for _, hint in ipairs(ATTACK_HINTS) do
            if s:find(hint, 1, true) then return true end
        end
        return false
    end
    local function parryNow()
        local now = os.clock()
        if now - lastParry < 0.05 then return end
        lastParry = now
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            local key = Settings.AutoParryKey or Enum.KeyCode.F
            vim:SendKeyEvent(true, key, false, game)
            task.wait(0.03)
            vim:SendKeyEvent(false, key, false, game)
        end)
    end
    local function jitterOffset(base)
        if not Settings.AntiDetectionJitter then return base end
        return base + (math.random() - 0.5) * 0.02
    end
    local function onAnimPlayed(anim, entity)
        if not Settings.AutoParry then return end
        local lpChar = LP.Character
        if not lpChar then return end
        local lpRoot = lpChar:FindFirstChild("HumanoidRootPart")
        if not lpRoot or not entity.root then return end
        if (entity.root.Position - lpRoot.Position).Magnitude > (Settings.AutoParryRange or 30) then
            return
        end
        if isAttackAnim(anim.AnimationId, anim.Name) then
            task.delay(jitterOffset(Settings.AutoParryOffset or 0.05), parryNow)
        end
    end
    local function attachTo(entity)
        if not entity.hum then return end
        local animator = entity.hum:FindFirstChildOfClass("Animator")
        if not animator then return end
        if hookedAnims[animator] then return end
        hookedAnims[animator] = true
        animator.AnimationPlayed:Connect(function(anim)
            pcall(onAnimPlayed, anim, entity)
        end)
    end
    local function loop()
        while task.wait(0.5) do
            if Settings.AutoParry then
                for _, e in ipairs(UniversalScanner.getEntities()) do
                    if (e.isPlayer and e.player ~= LP) or (not e.isPlayer and e.hum) then
                        attachTo(e)
                    end
                end
            end
        end
    end
    function M.start() task.spawn(loop) end
    return M
end)()

-- ================== AUTOLOOT ==================
local AutoLoot = (function()
    local M = {}
    local function scanLoot()
        local out = {}
        local names = Settings.AutoLootNames or {}
        local maxDist = Settings.AutoLootMaxDist or 100
        local lpChar = LP.Character
        if not lpChar then return out end
        local lpRoot = lpChar:FindFirstChild("HumanoidRootPart")
        if not lpRoot then return out end
        local lpPos = lpRoot.Position
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled then
                local parent = obj.Parent
                if parent then
                    local pos = nil
                    if parent:IsA("BasePart") then pos = parent.Position
                    elseif parent:IsA("Model") and parent.PrimaryPart then pos = parent.PrimaryPart.Position end
                    if pos then
                        local d = (pos - lpPos).Magnitude
                        if d <= maxDist then
                            out[#out+1] = { kind="prompt", prompt=obj, pos=pos, dist=d }
                        end
                    end
                end
            elseif obj:IsA("BasePart") and not obj.Anchored and not obj:FindFirstAncestorOfClass("Tool") then
                local n = obj.Name:lower()
                for _, want in ipairs(names) do
                    if n:find(want:lower(), 1, true) then
                        local d = (obj.Position - lpPos).Magnitude
                        if d <= maxDist then
                            out[#out+1] = { kind="part", part=obj, pos=obj.Position, dist=d }
                        end
                        break
                    end
                end
            end
        end
        table.sort(out, function(a, b) return a.dist < b.dist end)
        return out
    end
    local function doLoot(item)
        if item.kind == "prompt" then
            pcall(function()
                local fp = rawget(_G, "fireproximityprompt")
                if fp then fp(item.prompt) end
            end)
        elseif item.kind == "part" and Settings.AutoLootMode == "Teleport" then
            local c = LP.Character
            if c then
                local hrp = c:FindFirstChild("HumanoidRootPart")
                if hrp then
                    pcall(function() hrp.CFrame = CFrame.new(item.pos + Vector3.new(0, 3, 0)) end)
                end
            end
        end
    end
    local function loop()
        while true do
            task.wait(Settings.AutoLootInterval or 0.2)
            if Settings.AutoLoot then
                local loot = scanLoot()
                if #loot > 0 then doLoot(loot[1]) end
            end
        end
    end
    function M.start() task.spawn(loop) end
    return M
end)()

-- ================== ANTIAFK ==================
local AntiAFK = (function()
    local M = {}
    local lastChat = 0
    local function randomMove()
        local keys = {Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D}
        local k = keys[math.random(1, #keys)]
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendKeyEvent(true, k, false, game)
            task.wait(math.random(10, 30) / 100)
            vim:SendKeyEvent(false, k, false, game)
        end)
    end
    local function randomJump()
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.05)
            vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
    end
    local function randomCamera()
        local cam = Workspace.CurrentCamera
        if not cam then return end
        local yaw = (math.random() - 0.5) * math.rad(60)
        pcall(function() cam.CFrame = cam.CFrame * CFrame.Angles(0, yaw, 0) end)
    end
    local function chatSpam()
        local now = os.clock()
        if now - lastChat < 60 then return end
        lastChat = now
        local phrases = Settings.AntiAFKChatPhrases or {}
        if #phrases == 0 then return end
        local msg = phrases[math.random(1, #phrases)]
        pcall(function()
            local ev = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
            if ev and ev:FindFirstChild("SayMessageRequest") then
                ev.SayMessageRequest:FireServer(msg, "All")
            end
        end)
    end
    local function loop()
        while true do
            task.wait(Settings.AntiAFKInterval or 30)
            if Settings.AntiAFK then
                randomMove()
                if math.random() < 0.5 then randomJump() end
                randomCamera()
                if Settings.AntiAFKChatSpam then chatSpam() end
            end
        end
    end
    function M.start() task.spawn(loop) end
    return M
end)()

-- ================== RADAR ==================
local Radar = (function()
    local M = {}
    local frame, selfDot
    local dots = {}
    local cachedCorner, cachedSize, cachedPosition, lastVpSize = nil, nil, nil, nil
    local function computeCorner()
        local cam = Workspace.CurrentCamera
        if not cam then return Vector2.new(0,0) end
        local vp = cam.ViewportSize
        local size = Settings.RadarSize or 180
        local pos = Settings.RadarPosition or "TopRight"
        local margin = 20
        if pos == "TopRight" then return Vector2.new(vp.X - size - margin, margin)
        elseif pos == "TopLeft" then return Vector2.new(margin, margin)
        elseif pos == "BottomRight" then return Vector2.new(vp.X - size - margin, vp.Y - size - margin)
        else return Vector2.new(margin, vp.Y - size - margin) end
    end
    local function getCachedCorner()
        local cam = Workspace.CurrentCamera
        if not cam then return Vector2.new(0,0) end
        local vp = cam.ViewportSize
        local size = Settings.RadarSize or 180
        local pos = Settings.RadarPosition or "TopRight"
        if cachedCorner and cachedSize == size and cachedPosition == pos
           and lastVpSize and (lastVpSize - vp).Magnitude < 1 then
            return cachedCorner
        end
        cachedCorner = computeCorner()
        cachedSize = size
        cachedPosition = pos
        lastVpSize = vp
        return cachedCorner
    end
    local function render()
        if not Settings.RadarEnabled then
            if frame then frame.Visible = false end
            if selfDot then selfDot.Visible = false end
            for _, d in pairs(dots) do d.Visible = false end
            return
        end
        local cam = Workspace.CurrentCamera
        if not cam then return end
        local size = Settings.RadarSize or 180
        local corner = getCachedCorner()
        local center = Vector2.new(corner.X + size/2, corner.Y + size/2)
        local scale = Settings.RadarScale or 0.7
        if not frame then
            frame = Drawing.new("Square")
            frame.Filled = false
            frame.Thickness = 2
            frame.Color = UI.C.border
        end
        frame.Visible = true
        frame.Size = Vector2.new(size, size)
        frame.Position = corner
        if not selfDot then
            selfDot = Drawing.new("Circle")
            selfDot.Radius = 3
            selfDot.Filled = true
            selfDot.NumSides = 8
            selfDot.Color = Color3.fromRGB(255,255,255)
        end
        selfDot.Visible = true
        selfDot.Position = center
        local lpChar = LP.Character
        if not lpChar then return end
        local lpRoot = lpChar:FindFirstChild("HumanoidRootPart")
        if not lpRoot then return end
        local lpPos = lpRoot.Position
        local entities = UniversalScanner.getEntities()
        local seen = {}
        local range = Settings.RadarRange or 300
        for _, e in ipairs(entities) do
            local show = false
            if e.isPlayer and Settings.RadarShowPlayers then show = true
            elseif not e.isPlayer and Settings.RadarShowNPCs then show = true end
            if show and e.root then
                local offset = e.root.Position - lpPos
                local d = Vector2.new(offset.X, offset.Z).Magnitude
                if d <= range then
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
                    dot.Position = Vector2.new(center.X + offset.X * scale, center.Y + offset.Z * scale)
                    if e.isPlayer then
                        local sameTeamFlag = false
                        if LP.Team and e.player and e.player.Team == LP.Team then sameTeamFlag = true end
                        dot.Color = sameTeamFlag and Color3.fromRGB(80,200,130)
                                     or (Settings.RadarPlayerColor or Color3.fromRGB(230,80,100))
                    else
                        dot.Color = Settings.RadarNPCColor or Color3.fromRGB(255,200,60)
                    end
                end
            end
        end
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
    function M.start() safeRender(render) end
    return M
end)()

-- ================== WORLD + CAMERA ==================
local _World = (function()
    local cache = {
        rainFolder=nil, rainPE=nil, rainConn=nil,
        snowFolder=nil, snowPE=nil, snowConn=nil,
        thunder=false, thunderTask=nil,
        vig=nil, shift=nil, blur=nil,
        originalAtm={}, originalLighting={},
        originalMinZoom=nil, originalMaxZoom=nil, originalFov=nil,
    }
    local last = {}
    do
        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then
            cache.originalAtm = {
                Density=atm.Density, Offset=atm.Offset,
                Color=atm.Color, Decay=atm.Decay,
                Haze=atm.Haze, Glare=atm.Glare,
            }
        end
        cache.originalLighting = {
            Brightness=Lighting.Brightness, ClockTime=Lighting.ClockTime,
        }
        local cam = Workspace.CurrentCamera
        if cam then cache.originalFov = cam.FieldOfView end
        if LP then
            cache.originalMinZoom = LP.CameraMinZoomDistance
            cache.originalMaxZoom = LP.CameraMaxZoomDistance
        end
    end
    local function getAtm()
        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if not atm then atm = Instance.new("Atmosphere"); atm.Parent = Lighting end
        return atm
    end
    local function restoreAtm()
        local atm = getAtm(); local o = cache.originalAtm
        atm.Density = o.Density or 0.3
        atm.Offset = o.Offset or 0
        atm.Color = o.Color or Color3.fromRGB(199,199,199)
        atm.Decay = o.Decay or Color3.fromRGB(108,112,133)
        atm.Haze = o.Haze or 0
        atm.Glare = o.Glare or 0
    end
    local function restoreLighting()
        local o = cache.originalLighting
        Lighting.Brightness = o.Brightness or 2
        Lighting.ClockTime = o.ClockTime or 14
    end
    local function applyFog(on)
        local atm = getAtm()
        if on then
            atm.Density = Settings.WorldFogDensity or 0.5
            atm.Offset = 0.25
            atm.Color = Color3.fromRGB(160, 170, 190)
            atm.Decay = Color3.fromRGB(100, 110, 140)
            atm.Haze = Settings.WorldFogHaze or 2
            atm.Glare = 0.3
        else restoreAtm() end
    end
    local function applyThirdPerson(on)
        if not LP then return end
        if cache.originalMinZoom == nil then
            cache.originalMinZoom = LP.CameraMinZoomDistance
            cache.originalMaxZoom = LP.CameraMaxZoomDistance
        end
        if on then
            local d = Settings.ThirdPersonDistance or 10
            pcall(function()
                LP.CameraMinZoomDistance = d
                LP.CameraMaxZoomDistance = math.max(d, cache.originalMaxZoom or d)
            end)
        else
            pcall(function()
                LP.CameraMinZoomDistance = cache.originalMinZoom or 0.5
                LP.CameraMaxZoomDistance = cache.originalMaxZoom or 400
            end)
        end
    end
    local function applyCameraFov(on)
        local cam = Workspace.CurrentCamera
        if not cam then return end
        if cache.originalFov == nil then cache.originalFov = cam.FieldOfView end
        if on then
            local base = cache.originalFov or 70
            local amt = Settings.CameraFovAmount or 1.0
            pcall(function() cam.FieldOfView = math.clamp(base * amt, 20, 120) end)
        else
            pcall(function() cam.FieldOfView = cache.originalFov or 70 end)
        end
    end
    local function startRain()
        if cache.rainFolder then return end
        local folder = Instance.new("Folder")
        folder.Name = "cfgkotik_rain"; folder.Parent = Workspace
        local emitter = Instance.new("Part")
        emitter.Name = "rain_emitter"; emitter.Size = Vector3.new(200,1,200)
        emitter.Anchored = true; emitter.CanCollide = false; emitter.Transparency = 1
        emitter.Parent = folder
        local att = Instance.new("Attachment", emitter)
        local pe = Instance.new("ParticleEmitter")
        pe.Texture = "rbxassetid://241876428"
        pe.Rate = Settings.WorldRainRate or 300
        pe.Lifetime = NumberRange.new(0.4, 0.7)
        local sp = Settings.WorldRainSpeed or 90
        pe.Speed = NumberRange.new(sp*0.8, sp*1.2)
        pe.SpreadAngle = Vector2.new(0,0); pe.Rotation = NumberRange.new(0,0)
        pe.Color = ColorSequence.new(Color3.fromRGB(180,200,230))
        pe.Size = NumberSequence.new(Settings.WorldRainSize or 0.08)
        pe.Transparency = NumberSequence.new(0.4)
        pe.LightEmission = 0; pe.LightInfluence = 0
        pe.Acceleration = Vector3.new(0, -sp*2, 0)
        pe.EmissionDirection = Enum.NormalId.Bottom
        pe.Parent = att
        cache.rainFolder = folder; cache.rainPE = pe
        cache.rainConn = safeRender(function()
            local cam = Cam.cur or Workspace.CurrentCamera
            if cam then emitter.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0,40,0)) end
        end)
    end
    local function stopRain()
        if cache.rainConn then cache.rainConn:Disconnect(); cache.rainConn = nil end
        if cache.rainFolder then cache.rainFolder:Destroy(); cache.rainFolder = nil end
        cache.rainPE = nil
    end
    local function startSnow()
        if cache.snowFolder then return end
        local folder = Instance.new("Folder")
        folder.Name = "cfgkotik_snow"; folder.Parent = Workspace
        local emitter = Instance.new("Part")
        emitter.Name = "snow_emitter"; emitter.Size = Vector3.new(300,1,300)
        emitter.Anchored = true; emitter.CanCollide = false; emitter.Transparency = 1
        emitter.Parent = folder
        local att = Instance.new("Attachment", emitter)
        local pe = Instance.new("ParticleEmitter")
        pe.Texture = "rbxassetid://6075971289"
        pe.Rate = Settings.WorldSnowRate or 200
        pe.Lifetime = NumberRange.new(4, 8)
        local ss = Settings.WorldSnowSpeed or 4
        pe.Speed = NumberRange.new(ss*0.5, ss*1.5)
        pe.SpreadAngle = Vector2.new(180, 180)
        pe.Rotation = NumberRange.new(0, 360)
        pe.RotSpeed = NumberRange.new(-20, 20)
        pe.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
        local sz = Settings.WorldSnowSize or 0.25
        pe.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.1, sz),
            NumberSequenceKeypoint.new(1, sz),
        })
        pe.Transparency = NumberSequence.new(0.2)
        pe.LightEmission = 0.4; pe.LightInfluence = 0
        pe.Acceleration = Vector3.new(0, -ss, 0)
        pe.EmissionDirection = Enum.NormalId.Bottom
        pe.Parent = att
        cache.snowFolder = folder; cache.snowPE = pe
        cache.snowConn = safeRender(function()
            local cam = Cam.cur or Workspace.CurrentCamera
            if cam then emitter.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0,60,0)) end
        end)
    end
    local function stopSnow()
        if cache.snowConn then cache.snowConn:Disconnect(); cache.snowConn = nil end
        if cache.snowFolder then cache.snowFolder:Destroy(); cache.snowFolder = nil end
        cache.snowPE = nil
    end
    local function startThunder()
        if cache.thunder then return end
        cache.thunder = true
        Lighting.ClockTime = 22; Lighting.Brightness = 1
        local atm = getAtm()
        atm.Density = 0.5
        atm.Color = Color3.fromRGB(40, 40, 55)
        atm.Decay = Color3.fromRGB(20, 20, 35)
        atm.Haze = 3
        cache.thunderTask = task.spawn(function()
            while cache.thunder do
                local mn = Settings.WorldThunderMin or 3
                local mx = Settings.WorldThunderMax or 8
                if mx < mn then mx = mn end
                task.wait(math.random()*(mx-mn) + mn)
                if not cache.thunder then break end
                local br = Settings.WorldThunderBright or 60
                Lighting.Brightness = br / 10
                task.wait(0.05)
                if not cache.thunder then break end
                Lighting.Brightness = 1
                task.wait(0.08)
                if not cache.thunder then break end
                Lighting.Brightness = (br*0.8) / 10
                task.wait(0.04)
                Lighting.Brightness = 1
            end
        end)
    end
    local function stopThunder()
        if not cache.thunder then return end
        cache.thunder = false
        restoreLighting(); restoreAtm()
    end
    local function applyVignette(on)
        if on and (not cache.vig or not cache.vig.Parent) then
            local cc = Instance.new("ColorCorrectionEffect")
            cc.Name = "cfgkotik_vignette"
            cc.Contrast = Settings.WorldVignetteStrength or 0.15
            cc.Saturation = -(Settings.WorldVignetteStrength or 0.15)
            cc.Brightness = -0.08
            cc.TintColor = Color3.fromRGB(200,190,220)
            cc.Parent = Lighting; cache.vig = cc
        elseif on and cache.vig then
            cache.vig.Contrast = Settings.WorldVignetteStrength or 0.15
            cache.vig.Saturation = -(Settings.WorldVignetteStrength or 0.15)
        elseif not on and cache.vig then
            cache.vig:Destroy(); cache.vig = nil
        end
    end
    local function applyColorShift(on)
        if on and (not cache.shift or not cache.shift.Parent) then
            local cc = Instance.new("ColorCorrectionEffect")
            cc.Name = "cfgkotik_colorshift"
            cc.TintColor = Settings.WorldColorShiftColor
            cc.Saturation = 0.2
            cc.Parent = Lighting; cache.shift = cc
        elseif on and cache.shift then
            cache.shift.TintColor = Settings.WorldColorShiftColor
        elseif not on and cache.shift then
            cache.shift:Destroy(); cache.shift = nil
        end
    end
    local function applyBlur(on)
        if on and (not cache.blur or not cache.blur.Parent) then
            local b = Instance.new("BlurEffect")
            b.Name = "cfgkotik_blur"; b.Size = Settings.WorldBlurSize or 4
            b.Parent = Lighting; cache.blur = b
        elseif on and cache.blur then cache.blur.Size = Settings.WorldBlurSize or 4
        elseif not on and cache.blur then cache.blur:Destroy(); cache.blur = nil end
    end
    safeHeartbeat(function()
        if Settings.WorldFog ~= last.fog
           or Settings.WorldFogDensity ~= last.fogD
           or Settings.WorldFogHaze ~= last.fogH then
            applyFog(Settings.WorldFog)
            last.fog = Settings.WorldFog; last.fogD = Settings.WorldFogDensity; last.fogH = Settings.WorldFogHaze
        end
        if Settings.WorldVignette ~= last.vig or Settings.WorldVignetteStrength ~= last.vigS then
            applyVignette(Settings.WorldVignette)
            last.vig = Settings.WorldVignette; last.vigS = Settings.WorldVignetteStrength
        end
        if Settings.WorldColorShift ~= last.shift or Settings.WorldColorShiftColor ~= last.shiftC then
            applyColorShift(Settings.WorldColorShift)
            last.shift = Settings.WorldColorShift; last.shiftC = Settings.WorldColorShiftColor
        end
        if Settings.WorldBlur ~= last.blur or Settings.WorldBlurSize ~= last.blurS then
            applyBlur(Settings.WorldBlur)
            last.blur = Settings.WorldBlur; last.blurS = Settings.WorldBlurSize
        end
        if Settings.WorldRain ~= last.rain then
            if Settings.WorldRain then startRain() else stopRain() end
            last.rain = Settings.WorldRain
        end
        if Settings.WorldSnow ~= last.snow then
            if Settings.WorldSnow then startSnow() else stopSnow() end
            last.snow = Settings.WorldSnow
        end
        if Settings.WorldThunder ~= last.thunder then
            if Settings.WorldThunder then startThunder() else stopThunder() end
            last.thunder = Settings.WorldThunder
        end
        if Settings.ThirdPerson ~= last.third or Settings.ThirdPersonDistance ~= last.thirdD then
            applyThirdPerson(Settings.ThirdPerson)
            last.third = Settings.ThirdPerson; last.thirdD = Settings.ThirdPersonDistance
        end
        if Settings.CameraFov ~= last.camFov or Settings.CameraFovAmount ~= last.camFovA then
            applyCameraFov(Settings.CameraFov)
            last.camFov = Settings.CameraFov; last.camFovA = Settings.CameraFovAmount
        end
    end)
    return {}
end)()

-- ================== HUD ==================
local HUD = (function()
    local M = {}
    local sg, frame
    local parts = {}
    local fps = 0
    local style = {
        bg=Color3.fromRGB(20,20,26), logo=Color3.fromRGB(10,132,255),
        time=Color3.fromRGB(240,240,245), fps=Color3.fromRGB(80,200,130),
        ping=Color3.fromRGB(255,189,46), target=Color3.fromRGB(230,80,100),
        entities=Color3.fromRGB(170,170,185),
    }
    local function makeCell(order, colorKey)
        local wrap = Instance.new("Frame")
        wrap.BackgroundTransparency = 1
        wrap.AutomaticSize = Enum.AutomaticSize.X
        wrap.Size = UDim2.new(0, 0, 1, 0)
        wrap.LayoutOrder = order; wrap.Parent = frame
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.AutomaticSize = Enum.AutomaticSize.X
        lbl.Size = UDim2.new(0, 0, 1, 0)
        lbl.TextColor3 = style[colorKey]
        lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11
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
        s.Text = "|"; s.TextColor3 = UI.C.border
        s.Font = Enum.Font.Gotham; s.TextSize = 11
        s.TextXAlignment = Enum.TextXAlignment.Center
        s.TextYAlignment = Enum.TextYAlignment.Center
        s.LayoutOrder = order; s.Parent = frame
        return s
    end
    local function createHud()
        sg = Instance.new("ScreenGui")
        sg.Name="cfgkotik_hud"; sg.ResetOnSpawn=false
        sg.IgnoreGuiInset=true; sg.DisplayOrder=200
        protectGui(sg); sg.Parent = getParentGui()
        frame = Instance.new("Frame")
        frame.AutomaticSize = Enum.AutomaticSize.X
        frame.Size = UDim2.new(0, 0, 0, 24)
        frame.BackgroundColor3 = style.bg
        frame.BackgroundTransparency = 0.05
        frame.BorderSizePixel = 0; frame.Active = true; frame.Parent = sg
        local fc = Instance.new("UICorner", frame); fc.CornerRadius = UDim.new(0, 6)
        local fs = Instance.new("UIStroke", frame); fs.Color = UI.C.accent; fs.Thickness = 1
        local pad = Instance.new("UIPadding", frame)
        pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10)
        local lay = Instance.new("UIListLayout", frame)
        lay.FillDirection = Enum.FillDirection.Horizontal
        lay.VerticalAlignment = Enum.VerticalAlignment.Center
        lay.Padding = UDim.new(0, 5)
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        parts.logo = makeCell(0, "logo"); parts.logo.Text = "cfgkotik"
        parts.logo.Font = Enum.Font.GothamBold; parts.logo.TextSize = 12
        parts.sep1 = makeSep(1)
        parts.time = makeCell(2, "time"); parts.time.Text = "MSK --:--:--"
        parts.sep2 = makeSep(3)
        parts.fps = makeCell(4, "fps"); parts.fps.Text = "FPS 0"
        parts.sep3 = makeSep(5)
        parts.ping = makeCell(6, "ping"); parts.ping.Text = "Ping --"
        parts.sep4 = makeSep(7)
        parts.entities = makeCell(8, "entities"); parts.entities.Text = "целей: 0"
        parts.sep5 = makeSep(9)
        parts.target = makeCell(10, "target"); parts.target.Text = "цель: —"
        frame.Position = UDim2.new(0, 12, 0, 12)
        local dragging, dragStart, startAbs = false, nil, nil
        frame.InputBegan:Connect(function(i)
            if i.UserInputType ~= Enum.UserInputType.MouseButton1
               and i.UserInputType ~= Enum.UserInputType.Touch then return end
            if not (UI.window and UI.window.main and UI.window.main.Visible) then return end
            dragging = true
            dragStart = Vector2.new(i.Position.X, i.Position.Y)
            startAbs = frame.AbsolutePosition
        end)
        UIS.InputChanged:Connect(function(i)
            if not dragging then return end
            if i.UserInputType ~= Enum.UserInputType.MouseMovement
               and i.UserInputType ~= Enum.UserInputType.Touch then return end
            local d = Vector2.new(i.Position.X, i.Position.Y) - dragStart
            local cam = Workspace.CurrentCamera
            local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
            local fw, fh = frame.AbsoluteSize.X, frame.AbsoluteSize.Y
            frame.Position = UDim2.new(0,
                math.clamp(startAbs.X + d.X, 0, math.max(0, vp.X - fw)),
                0, math.clamp(startAbs.Y + d.Y, 0, math.max(0, vp.Y - fh)))
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
               or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
    end
    function M.applyColors()
        if not frame then return end
        style.bg = Settings.HudBgColor or style.bg
        style.logo = Settings.HudLogoColor or style.logo
        style.time = Settings.HudTimeColor or style.time
        style.fps = Settings.HudFpsColor or style.fps
        style.ping = Settings.HudPingColor or style.ping
        style.target = Settings.HudTargetColor or style.target
        style.entities = Settings.HudEntitiesColor or style.entities
        frame.BackgroundColor3 = style.bg
        if parts.logo then parts.logo.TextColor3 = style.logo end
        if parts.time then parts.time.TextColor3 = style.time end
        if parts.fps then parts.fps.TextColor3 = style.fps end
        if parts.ping then parts.ping.TextColor3 = style.ping end
        if parts.target then parts.target.TextColor3 = style.target end
        if parts.entities then parts.entities.TextColor3 = style.entities end
    end
    local function applyVisibility()
        if not frame then return end
        parts.logo.Visible = Settings.HudShowLogo
        parts.time.Visible = Settings.HudShowTime
        parts.fps.Visible = Settings.HudShowFps
        parts.ping.Visible = Settings.HudShowPing
        parts.target.Visible = Settings.HudShowTarget
        parts.entities.Visible = Settings.HudShowEntities
        parts.sep1.Visible = Settings.HudShowLogo
        parts.sep2.Visible = Settings.HudShowTime
        parts.sep3.Visible = Settings.HudShowFps
        parts.sep4.Visible = Settings.HudShowPing
        parts.sep5.Visible = Settings.HudShowEntities and Settings.HudShowTarget
    end
    local function fpsLoop()
        local frames = 0; local last = os.clock()
        safeRender(function()
            frames = frames + 1
            local now = os.clock()
            if now - last >= 1 then fps = frames; frames = 0; last = now end
        end)
    end
    local function mskTime()
        local ok, t = pcall(function() return os.date("!%H:%M:%S", os.time() + 3*3600) end)
        if ok and t then return t end
        return "--:--:--"
    end
    function M.getFps() return fps end
    function M.start()
        createHud(); fpsLoop()
        M.applyColors(); applyVisibility()
        task.spawn(function()
            while task.wait(0.25) do
                if not sg or not sg.Parent then break end
                parts.time.Text = "MSK " .. mskTime()
                if Settings.HudShowCombatStats then
                    local hist = Settings.TargetHistory or {}
                    local locked = 0
                    for _, e in ipairs(hist) do
                        if e.result == "locked" then locked = locked + 1 end
                    end
                    local rate = #hist > 0 and math.floor(locked / #hist * 100) or 0
                    local avg = 0
                    local cnt = 0
                    for _, e in ipairs(hist) do avg = avg + (e.dist or 0); cnt = cnt + 1 end
                    if cnt > 0 then avg = math.floor(avg / cnt) end
                    parts.fps.Text = string.format("FPS %d | Lock %d%% | Avg %dm", fps, rate, avg)
                else
                    parts.fps.Text = "FPS " .. tostring(fps)
                end
                parts.ping.Text = "Ping " .. tostring(math.floor(getPing() * 1000)) .. "ms"
                parts.entities.Text = "целей: " .. UniversalScanner.count()
                local name = Aimbot.getTargetName and Aimbot.getTargetName()
                parts.target.Text = "цель: " .. (name or "—")
                applyVisibility(); M.applyColors()
            end
        end)
    end
    return M
end)()

-- ================== MOVEMENT ==================
local _Hitbox = (function()
    local orig, lastSize = {}, nil
    local function shouldExpand(n)
        local sel = Settings.HitboxPartList or {}
        local grp = partGroup(n)
        return grp and sel[grp] == true
    end
    local function revertOne(p)
        local o = orig[p]
        if o then pcall(function() p.Size = o.size end); orig[p] = nil end
    end
    task.spawn(function()
        while task.wait(0.15) do
            if not (Settings.HitboxExpand or isBindActive("Hitbox")) then
                for p in pairs(orig) do revertOne(p) end
                lastSize = nil
            else
                local sizeChanged = (lastSize ~= Settings.HitboxSize)
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LP and plr.Character then
                        for _, p in ipairs(plr.Character:GetDescendants()) do
                            if p:IsA("BasePart") and shouldExpand(p.Name) and not isBadPart(p) then
                                if sizeChanged and orig[p] then
                                    p.Size = orig[p].size * Settings.HitboxSize
                                elseif not orig[p] then
                                    orig[p] = { size = p.Size }
                                    p.Size = orig[p].size * Settings.HitboxSize
                                end
                            end
                        end
                    end
                end
                for p in pairs(orig) do
                    if not p.Parent or not shouldExpand(p.Name) then revertOne(p) end
                end
                lastSize = Settings.HitboxSize
            end
        end
    end)
    return {}
end)()

local _Speed = (function()
    local savedOrig = nil
    local trackedChar = nil
    task.spawn(function()
        while task.wait(0.1) do
            local c = LP.Character
            if c ~= trackedChar then trackedChar = c; savedOrig = nil end
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h then
                    if Settings.SpeedHack or isBindActive("Speed") then
                        if not savedOrig then savedOrig = h.WalkSpeed end
                        if h.WalkSpeed ~= Settings.Speed then h.WalkSpeed = Settings.Speed end
                    elseif savedOrig then
                        if h.WalkSpeed == Settings.Speed then h.WalkSpeed = savedOrig end
                        savedOrig = nil
                    end
                end
            end
        end
    end)
    return {}
end)()

local _Jump = (function()
    task.spawn(function()
        while task.wait(0.1) do
            local c = LP.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h and Settings.JumpPowerEnable then
                    pcall(function()
                        h.UseJumpPower = true
                        h.JumpPower = Settings.JumpPower
                    end)
                end
            end
        end
    end)
    return {}
end)()

local _InfiniteJump = (function()
    local conn
    local function start()
        if conn then return end
        conn = UIS.JumpRequest:Connect(function()
            if Settings.InfiniteJump then
                local c = LP.Character
                if c then
                    local h = c:FindFirstChildOfClass("Humanoid")
                    if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
                end
            end
        end)
    end
    local function stop()
        if conn then conn:Disconnect(); conn = nil end
    end
    safeHeartbeat(function()
        if Settings.InfiniteJump then start() else stop() end
    end)
    return {}
end)()

local _Noclip = (function()
    task.spawn(function()
        while task.wait(0.1) do
            if Settings.Noclip then
                local c = LP.Character
                if c then
                    for _, p in ipairs(c:GetDescendants()) do
                        if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
                    end
                end
            end
        end
    end)
    return {}
end)()

local _Fly = (function()
    local st = { on=false, hb=nil, att=nil, lv=nil, ao=nil, starting=false }
    local function flyOn() return Settings.Fly or isBindActive("Fly") end
    local function startFly()
        if st.starting then return end
        st.starting = true
        local c = LP.Character
        if not c then st.starting = false; return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hrp then st.starting = false; return end
        if st.lv then pcall(function() st.lv:Destroy() end) end
        if st.ao then pcall(function() st.ao:Destroy() end) end
        if st.att then pcall(function() st.att:Destroy() end) end
        local att = Instance.new("Attachment")
        att.Name = "cfgkotik_fly_att"; att.Parent = hrp
        local lv = Instance.new("LinearVelocity")
        lv.Attachment0 = att
        lv.MaxForce = math.huge
        lv.RelativeTo = Enum.ActuatorRelativeTo.World
        lv.VectorVelocity = Vector3.zero
        lv.Parent = hrp
        local ao = Instance.new("AlignOrientation")
        ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
        ao.Attachment0 = att
        ao.MaxTorque = math.huge
        ao.Responsiveness = 200
        ao.Parent = hrp
        st.att, st.lv, st.ao = att, lv, ao
        if st.hb then st.hb:Disconnect() end
        st.hb = safeHeartbeat(function()
            if not flyOn() or not st.lv or not st.lv.Parent then return end
            local cam = Cam.cur or Workspace.CurrentCamera
            if not cam then return end
            local cf = cam.CFrame
            local move = Vector3.zero
            local spd = Settings.FlySpeed or 80
            if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + cf.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - cf.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,1,0) end
            st.lv.VectorVelocity = move.Magnitude > 0 and move.Unit * spd or Vector3.zero
            st.ao.CFrame = cf
        end)
        st.starting = false
    end
    local function stopFly()
        if st.hb then st.hb:Disconnect(); st.hb = nil end
        if st.lv then pcall(function() st.lv:Destroy() end); st.lv = nil end
        if st.ao then pcall(function() st.ao:Destroy() end); st.ao = nil end
        if st.att then pcall(function() st.att:Destroy() end); st.att = nil end
    end
    LP.CharacterAdded:Connect(function()
        if flyOn() then
            task.wait(0.2)
            st.on = false
            stopFly()
            st.on = true
            startFly()
        end
    end)
    safeHeartbeat(function()
        if flyOn() and not st.on then st.on = true; startFly()
        elseif not flyOn() and st.on then st.on = false; stopFly() end
    end)
    return {}
end)()

-- ================== MISC ==================
local Misc = (function()
    local M = {}
    function M.rejoin()
        local ok = pcall(function() TeleportSvc:Teleport(game.PlaceId, LP) end)
        if not ok then
            local ok2 = pcall(function() TeleportSvc:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end)
            if not ok2 then UI.notify("Rejoin failed", "error") end
        end
    end
    function M.teleportToMouse()
        local mouse = LP:GetMouse()
        if not mouse or not mouse.Hit then return end
        local target = mouse.Hit.Position
        local c = LP.Character
        if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        pcall(function() hrp.CFrame = CFrame.new(target + Vector3.new(0, 3, 0)) end)
    end
    return M
end)()

-- ================== CENTRAL SCANNER LOOP ==================
task.spawn(function()
    while true do
        pcall(UniversalScanner.tick)
        task.wait(Settings.ScanInterval or 0.2)
    end
end)

-- ================== FPS OPTIMIZER ==================
local FPSOptimizer = (function()
    local M = {}
    local warned = {}
    local function fire(key, msg)
        if warned[key] then return end
        warned[key] = true
        UI.notify(msg, "error")
        task.delay(10, function() warned[key] = nil end)
    end
    local function loop()
        while task.wait(1) do
            if not Settings.AutoOptimize then
                warned = {}
            else
                local fps = HUD.getFps and HUD.getFps() or 60
                local th  = Settings.MinFpsThreshold or 45
                if fps > 0 and fps < th then
                    if Settings.ESPHighlightOccluded then
                        Settings.ESPHighlightOccluded = false
                        fire("occ", "Occluded OFF (low FPS)")
                    end
                    if Settings.WorldRain or Settings.WorldSnow then
                        Settings.WorldRain = false
                        Settings.WorldSnow = false
                        fire("weather", "Weather OFF (low FPS)")
                    end
                    if Settings.WorldBlur and (Settings.WorldBlurSize or 0) > 5 then
                        Settings.WorldBlurSize = 2
                        fire("blur", "Blur reduced (low FPS)")
                    end
                end
            end
        end
    end
    function M.start() task.spawn(loop) end
    return M
end)()

-- ================== TARGET HISTORY ==================
local TargetHistory = (function()
    local M = {}
    local lastTarget, lastResult = nil, nil
    function M.push(entry)
        Settings.TargetHistory = Settings.TargetHistory or {}
        table.insert(Settings.TargetHistory, 1, entry)
        while #Settings.TargetHistory > 10 do table.remove(Settings.TargetHistory) end
    end
    function M.tick()
        local cur = Aimbot.getTargetName and Aimbot.getTargetName()
        if cur and cur ~= lastTarget then
            local part = Aimbot.getTargetPart and Aimbot.getTargetPart()
            local cam = Cam.cur or Workspace.CurrentCamera
            local d = 0
            if part and cam then
                d = math.floor((part.Position - cam.CFrame.Position).Magnitude)
            end
            M.push({ time = os.date("%H:%M:%S"), name = cur, dist = d, result = "locked" })
            lastTarget = cur; lastResult = "locked"
        elseif not cur and lastTarget and lastResult == "locked" then
            if Settings.TargetHistory[1] then
                Settings.TargetHistory[1].result = "lost"
            end
            lastTarget = nil; lastResult = nil
        end
    end
    function M.start()
        task.spawn(function()
            while task.wait(0.5) do pcall(M.tick) end
        end)
    end
    return M
end)()

-- ================== PROFILES ==================
local Profiles = (function()
    local M = {}
    local function apply(preset)
        for k, v in pairs(preset) do Settings[k] = v end
        UI.refresh()
        if BindStrip and BindStrip.rebuild then BindStrip.rebuild() end
    end
    M.Legit = function()
        apply({
            Aimbot = true, FOV = 80, AimSmoothMode = "Smooth",
            SilentAim = false, HitboxExpand = false,
            ESPBox = true, ESPName = true, ESPHighlight = false,
            ESPTracers = false, ESPDistanceColors = false,
            SpeedHack = false, Fly = false, TriggerBot = false,
            AutoParry = false, AutoLoot = false, AntiAFK = false,
        })
        UI.notify("Legit loaded", "success")
    end
    M.HvH = function()
        apply({
            Aimbot = true, FOV = 300, AimSmoothMode = "Ultra",
            SilentAim = true, HitboxExpand = true,
            ESPBox = true, ESPName = true, ESPHighlight = true,
            ESPHighlightOccluded = true,
            ESPTracers = true, ESPDistanceColors = true,
            SpeedHack = true, Speed = 80, Fly = true, TriggerBot = true,
        })
        UI.notify("HvH loaded", "success")
    end
    M.Ghost = function()
        apply({
            Aimbot = true, Priority = "Crosshair", FOV = 60,
            SilentAim = false, HitboxExpand = false,
            ESP = false, ESPHighlight = false, ESPTracers = false,
            RadarEnabled = true,
            SpeedHack = false, Fly = false,
        })
        UI.notify("Ghost loaded", "success")
    end
    M.Farm = function()
        apply({
            Aimbot = false, ESP = true,
            ESPShowPlayers = false, ESPShowNPCs = true,
            ESPBox = true, ESPHealth = false,
            SpeedHack = true, Speed = 60, Fly = true,
            AutoLoot = true, AntiAFK = true,
        })
        UI.notify("Farm loaded", "success")
    end
    return M
end)()

-- ================== applyTheme ==================
local function applyTheme(themeName)
    local theme = THEMES[themeName] or SAVED_THEMES[themeName]
    if not theme then
        UI.notify("Theme not found: " .. tostring(themeName), "error")
        return
    end
    UI.C.accent = theme.MenuAccent
    if UI.window and UI.window.main then
        local glow = UI.window.main:FindFirstChild("accentGlow")
        if glow then glow.BackgroundColor3 = theme.MenuAccent end
        local ver = UI.window.verLabel
        if ver then ver.TextColor3 = theme.MenuAccent end
    end
    Settings.AimColor = theme.FovColor
    Settings.AimColorLocked = theme.FovColorLocked
    Settings.ESPColor = theme.ESPColor
    Settings.HudLogoColor = theme.HudLogo
    Settings.HudFpsColor = theme.HudFps
    Settings.HudTargetColor = theme.HudTarget
    Settings.RadarPlayerColor = theme.RadarPlayer
    Settings.RadarNPCColor = theme.RadarNPC
    Settings.CurrentTheme = themeName
    if UI.refresh then UI.refresh() end
    if HUD.applyColors then HUD.applyColors() end
    UI.notify("Theme applied: " .. themeName, "success")
end

-- ================== BIND EDITOR ==================
local BindEditor = (function()
    local M = {}
    local sg = nil
    function M.close() if sg then sg:Destroy(); sg = nil end end
    function M.open()
        if sg then M.close() end
        sg = Instance.new("ScreenGui")
        sg.Name = "cfgkotik_bindeditor"; sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true; sg.DisplayOrder = 400
        protectGui(sg); sg.Parent = getParentGui()
        local win = Instance.new("Frame")
        win.Size = UDim2.new(0, 420, 0, 340)
        win.Position = UDim2.new(0.5, -210, 0.5, -170)
        win.BackgroundColor3 = UI.C.popupBg; win.BorderSizePixel = 0
        win.Active = true; win.Parent = sg
        UI.corner(win, 10); UI.stroke(win, UI.C.accent, 2)
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -40, 0, 30); title.BackgroundTransparency = 1
        title.Text = "BIND EDITOR"; title.TextColor3 = UI.C.text
        title.Font = Enum.Font.GothamBold; title.TextSize = 13
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Position = UDim2.new(0, 14, 0, 0); title.Parent = win
        local close = Instance.new("TextButton")
        close.Size = UDim2.new(0, 24, 0, 24); close.Position = UDim2.new(1, -30, 0, 3)
        close.BackgroundColor3 = UI.C.danger; close.Text = "✕"
        close.TextColor3 = UI.C.text; close.Font = Enum.Font.GothamBold
        close.TextSize = 12; close.BorderSizePixel = 0; close.Parent = win
        UI.corner(close, 5)
        close.MouseButton1Click:Connect(M.close)
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, -20, 1, -60); scroll.Position = UDim2.new(0, 10, 0, 40)
        scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 4; scroll.ScrollBarImageColor3 = UI.C.accent
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Parent = win
        local lay = Instance.new("UIListLayout", scroll)
        lay.Padding = UDim.new(0, 4); lay.SortOrder = Enum.SortOrder.LayoutOrder
        for _, entry in ipairs(BindList) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -8, 0, 30); row.BackgroundColor3 = UI.C.card
            row.BorderSizePixel = 0; row.Parent = scroll
            UI.corner(row, 5); UI.stroke(row, UI.C.border, 1)
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0, 140, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0)
            lbl.BackgroundTransparency = 1; lbl.Text = entry.label
            lbl.TextColor3 = UI.C.text; lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = row
            local keyBtn = Instance.new("TextButton")
            keyBtn.Size = UDim2.new(0, 80, 0, 22); keyBtn.Position = UDim2.new(0, 150, 0.5, -11)
            keyBtn.BackgroundColor3 = UI.C.track; keyBtn.Text = keyLabel(getBindKey(entry.id))
            keyBtn.TextColor3 = UI.C.text; keyBtn.Font = Enum.Font.GothamBold
            keyBtn.TextSize = 10; keyBtn.BorderSizePixel = 0; keyBtn.Parent = row
            UI.corner(keyBtn, 4)
            keyBtn.MouseButton1Click:Connect(function()
                if UI.listening then return end
                UI.listening = true
                keyBtn.Text = "..."
                keyBtn.BackgroundColor3 = UI.C.accent
                local conn
                task.wait(0.05)
                conn = UIS.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode == Enum.KeyCode.Backspace then
                            setBindKey(entry.id, nil)
                            keyBtn.Text = "—"; UI.listening = false
                            if conn then conn:Disconnect() end
                            BindStrip.rebuild()
                            return
                        end
                        if BLACKLISTED_KEYS[input.KeyCode] then return end
                        setBindKey(entry.id, input.KeyCode)
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.MouseButton2
                        or input.UserInputType == Enum.UserInputType.MouseButton3 then
                        setBindKey(entry.id, input.UserInputType)
                    else return end
                    keyBtn.Text = keyLabel(getBindKey(entry.id))
                    keyBtn.BackgroundColor3 = UI.C.track
                    UI.listening = false
                    if conn then conn:Disconnect() end
                    BindStrip.rebuild()
                end)
            end)
            local modeBtn = Instance.new("TextButton")
            modeBtn.Size = UDim2.new(0, 70, 0, 22); modeBtn.Position = UDim2.new(0, 240, 0.5, -11)
            modeBtn.BackgroundColor3 = UI.C.track
            modeBtn.Text = getBindMode(entry.id) or "Toggle"
            modeBtn.TextColor3 = UI.C.text; modeBtn.Font = Enum.Font.GothamBold
            modeBtn.TextSize = 10; modeBtn.BorderSizePixel = 0; modeBtn.Parent = row
            UI.corner(modeBtn, 4)
            modeBtn.MouseButton1Click:Connect(function()
                local cur = getBindMode(entry.id)
                local nxt = (cur == "Hold") and "Toggle" or "Hold"
                setBindMode(entry.id, nxt)
                modeBtn.Text = nxt
            end)
            local delBtn = Instance.new("TextButton")
            delBtn.Size = UDim2.new(0, 28, 0, 22); delBtn.Position = UDim2.new(1, -38, 0.5, -11)
            delBtn.BackgroundColor3 = UI.C.danger; delBtn.Text = "🗑"
            delBtn.TextColor3 = UI.C.text; delBtn.Font = Enum.Font.GothamBold
            delBtn.TextSize = 11; delBtn.BorderSizePixel = 0; delBtn.Parent = row
            UI.corner(delBtn, 4)
            delBtn.MouseButton1Click:Connect(function()
                setBindKey(entry.id, nil)
                keyBtn.Text = "—"
                BindStrip.rebuild()
            end)
            task.spawn(function()
                while row.Parent do
                    row.BackgroundColor3 = isBindActive(entry.id) and UI.C.green or UI.C.card
                    task.wait(0.1)
                end
            end)
        end
        local okBtn = Instance.new("TextButton")
        okBtn.Size = UDim2.new(0, 110, 0, 28); okBtn.Position = UDim2.new(1, -122, 1, -36)
        okBtn.BackgroundColor3 = UI.C.accent; okBtn.Text = "Close"
        okBtn.TextColor3 = UI.C.text; okBtn.Font = Enum.Font.GothamBold
        okBtn.TextSize = 12; okBtn.BorderSizePixel = 0; okBtn.Parent = win
        UI.corner(okBtn, 6)
        okBtn.MouseButton1Click:Connect(M.close)
    end
    return M
end)()

-- ================== MENU BUILD (6 folders in grid) ==================
local win = UI.createWindow()

-- ───────── FOLDER 1: Aim ─────────
local aimTab = win:makeTab("Aim", "🎯", "targeting · smoothing · silent aim")
local sTarget = UI.section(aimTab, "TARGETING")
UI.toggle(sTarget, "Enable Aimbot", "Aimbot")
UI.keybind(sTarget, "Aim Key", "AimKey")
UI.dropdown(sTarget, "Trigger Mode", "AimMode", {"Always", "Hold", "Toggle"})
UI.dropdown(sTarget, "Priority", "Priority", {"FOV", "Crosshair", "Distance", "Health"})
UI.multiSelect(sTarget, "Aim Parts", "AimPartList", {"Head", "Torso", "Limbs"})
UI.toggle(sTarget, "Target Players", "TargetPlayers")
UI.toggle(sTarget, "Target NPCs", "TargetNPCs")
UI.toggle(sTarget, "Team Check", "TeamCheck")
UI.toggle(sTarget, "Visibility Required", "Visibility")

local sFilter = UI.section(aimTab, "PLAYER FILTER")
UI.button(sFilter, "Whitelist Current Target", function()
    local n = Aimbot.getTargetName()
    if n then Aimbot.addWhitelist(n); UI.notify("WL: " .. n, "success")
    else UI.notify("No target", "error") end
end)
UI.button(sFilter, "Blacklist Current Target", function()
    local n = Aimbot.getTargetName()
    if n then Aimbot.addBlacklist(n); UI.notify("BL: " .. n, "error")
    else UI.notify("No target", "error") end
end)
UI.button(sFilter, "Clear Lists", function()
    Aimbot.clearLists(); UI.notify("Lists cleared", "success")
end)

local sBehavior = UI.section(aimTab, "BEHAVIOR")
UI.slider(sBehavior, "FOV Radius", "FOV", 10, 800, 5,
    function(v) return tostring(math.floor(v)) end)
UI.toggle(sBehavior, "Show FOV Circle", "ShowFov")
UI.colorPalette(sBehavior, "FOV Color", "AimColor")
UI.colorPalette(sBehavior, "FOV Color (Locked)", "AimColorLocked")
UI.dropdown(sBehavior, "Smoothing", "AimSmoothMode", {"Smooth", "Ultra", "Soft"})
UI.slider(sBehavior, "Prediction (ping)", "PredAmount", 0, 3, 0.1,
    function(v) return string.format("%.1fx", v) end)
UI.toggle(sBehavior, "Velocity Prediction", "PredAccel")
UI.slider(sBehavior, "Prediction History", "PredHistory", 2, 8, 1,
    function(v) return tostring(math.floor(v)) .. " frames" end)
UI.toggle(sBehavior, "Gravity Compensation", "AimGravityComp")
UI.slider(sBehavior, "Hit Chance", "HitChance", 0, 100, 1,
    function(v) return tostring(math.floor(v)) .. "%" end)
UI.slider(sBehavior, "Jitter", "Jitter", 0, 10, 0.5,
    function(v) return string.format("%.1f", v) end)

local sAdvanced = UI.section(aimTab, "ADVANCED")
UI.toggle(sAdvanced, "Silent Aim", "SilentAim")
UI.slider(sAdvanced, "Max Fire Rate (auto-off)", "SilentAimMaxFireRate", 10, 200, 10,
    function(v) return tostring(math.floor(v)) .. "/s" end)
UI.toggle(sAdvanced, "Hitbox Expand", "HitboxExpand")
UI.multiSelect(sAdvanced, "Expand Parts", "HitboxPartList", {"Head", "Torso", "Limbs"})
UI.slider(sAdvanced, "Hitbox Size", "HitboxSize", 1, 20, 0.5,
    function(v) return string.format("%.1fx", v) end)
UI.toggle(sAdvanced, "Trigger Bot", "TriggerBot")
UI.slider(sAdvanced, "Trigger Delay", "TriggerDelay", 0.01, 1, 0.01,
    function(v) return string.format("%.2fs", v) end)
UI.toggle(sAdvanced, "Anti-Detect Jitter", "AntiDetectionJitter")
UI.toggle(sAdvanced, "FOV Expand", "FovExpand")
UI.slider(sAdvanced, "Expand Multiplier", "FovExpandMult", 1.1, 3.0, 0.1,
    function(v) return string.format("×%.1f", v) end)
UI.slider(sAdvanced, "Expand Hold", "FovExpandHold", 0.1, 2.0, 0.1,
    function(v) return string.format("%.1fs", v) end)
UI.toggle(sAdvanced, "Adaptive FOV on low FPS", "AdaptiveFov")
UI.slider(sAdvanced, "Adaptive Factor", "AdaptiveFovFactor", 0.5, 1.0, 0.05,
    function(v) return string.format("×%.2f", v) end)
UI.slider(sAdvanced, "Sticky Time", "StickyTime", 0, 1, 0.05,
    function(v) return string.format("%.2fs", v) end)
UI.dropdown(sAdvanced, "Sticky Mode", "AimStickyMode", {"Strict", "Soft"},
    function(v) Settings.AimStickyStrict = (v == "Strict") end)

local sParry = UI.section(aimTab, "AUTO-PARRY")
UI.toggle(sParry, "Enable", "AutoParry")
UI.keybind(sParry, "Parry Key", "AutoParryKey")
UI.slider(sParry, "Offset", "AutoParryOffset", 0.01, 0.5, 0.01,
    function(v) return string.format("%.2fs", v) end)
UI.slider(sParry, "Range", "AutoParryRange", 5, 100, 5,
    function(v) return tostring(math.floor(v)) .. "m" end)

-- ───────── FOLDER 2: Visual ─────────
local visTab = win:makeTab("Visual", "👁", "ESP · chams · radar · camera")
local sDisplay = UI.section(visTab, "ESP")
UI.toggle(sDisplay, "Enable ESP", "ESP")
UI.toggle(sDisplay, "Show Players", "ESPShowPlayers")
UI.toggle(sDisplay, "Show NPCs", "ESPShowNPCs")
UI.colorPalette(sDisplay, "ESP Color", "ESPColor")
UI.toggle(sDisplay, "Box", "ESPBox")
UI.dropdown(sDisplay, "Box Style", "ESPBoxStyle", {"full", "corner"})
UI.toggle(sDisplay, "Name", "ESPName")
UI.toggle(sDisplay, "Distance", "ESPDistance")
UI.toggle(sDisplay, "Health Bar", "ESPHealth")
UI.toggle(sDisplay, "Weapon", "ESPWeapon")
UI.toggle(sDisplay, "Tracers", "ESPTracers")
UI.dropdown(sDisplay, "Tracer Origin", "ESPTracerFrom", {"Bottom", "Top", "Mouse"})
UI.slider(sDisplay, "Max Distance", "ESPMaxDist", 100, 5000, 100,
    function(v) return tostring(math.floor(v)) .. "m" end)
UI.slider(sDisplay, "Update Rate", "ESPUpdateRate", 0.01, 0.1, 0.01,
    function(v) return string.format("%.2fs", v) end)
UI.toggle(sDisplay, "Distance Color Coding", "ESPDistanceColors")
UI.slider(sDisplay, "Near Threshold", "ESPNearThreshold", 10, 100, 5,
    function(v) return tostring(math.floor(v)) .. "m" end)
UI.slider(sDisplay, "Mid Threshold", "ESPMidThreshold", 50, 300, 10,
    function(v) return tostring(math.floor(v)) .. "m" end)
UI.colorPalette(sDisplay, "Near Color", "ESPNearColor")
UI.colorPalette(sDisplay, "Mid Color", "ESPMidColor")
UI.colorPalette(sDisplay, "Far Color", "ESPFarColor")

local sHighlight = UI.section(visTab, "HIGHLIGHT (CHAMS)")
UI.toggle(sHighlight, "Enable", "ESPHighlight")
UI.dropdown(sHighlight, "Mode", "ESPHighlightMode", {"AlwaysOnTop", "Occluded"},
    function(v) Settings.ESPHighlightOccluded = (v == "Occluded") end)

local sVis = UI.section(visTab, "VISIBILITY CHECK")
UI.toggle(sVis, "Hide Enemies Behind Walls", "ESPVisibilityCheck")
UI.toggle(sVis, "Show vis/hid Label", "ESPShowVisLabel")
UI.slider(sVis, "Check Interval", "ScanVisibilityInterval", 0.05, 0.5, 0.01,
    function(v) return string.format("%.2fs", v) end)

local sRadar = UI.section(visTab, "RADAR")
UI.toggle(sRadar, "Enable Radar", "RadarEnabled")
UI.slider(sRadar, "Size", "RadarSize", 100, 400, 10,
    function(v) return tostring(math.floor(v)) .. " px" end)
UI.slider(sRadar, "Scale", "RadarScale", 0.2, 3.0, 0.1,
    function(v) return string.format("%.1fx", v) end)
UI.slider(sRadar, "Range", "RadarRange", 50, 2000, 50,
    function(v) return tostring(math.floor(v)) .. "m" end)
UI.dropdown(sRadar, "Position", "RadarPosition",
    {"TopRight", "TopLeft", "BottomRight", "BottomLeft"})
UI.toggle(sRadar, "Show Players", "RadarShowPlayers")
UI.toggle(sRadar, "Show NPCs", "RadarShowNPCs")
UI.colorPalette(sRadar, "Player Color", "RadarPlayerColor")
UI.colorPalette(sRadar, "NPC Color", "RadarNPCColor")

local sCam = UI.section(visTab, "CAMERA")
UI.toggle(sCam, "Third Person", "ThirdPerson")
UI.slider(sCam, "Distance", "ThirdPersonDistance", 3, 50, 1,
    function(v) return tostring(math.floor(v)) end)
UI.toggle(sCam, "Custom FOV", "CameraFov")
UI.slider(sCam, "FOV Multiplier", "CameraFovAmount", 0.5, 2.0, 0.05,
    function(v) return string.format("×%.2f", v) end)

-- ───────── FOLDER 3: World ─────────
local worldTab = win:makeTab("World", "🌦", "weather · fog · post-FX")
local sWeather = UI.section(worldTab, "WEATHER")
UI.toggle(sWeather, "Rain", "WorldRain")
UI.slider(sWeather, "Rain Rate", "WorldRainRate", 30, 1000, 10,
    function(v) return tostring(math.floor(v)) end)
UI.slider(sWeather, "Rain Speed", "WorldRainSpeed", 20, 300, 5,
    function(v) return tostring(math.floor(v)) end)
UI.slider(sWeather, "Rain Size", "WorldRainSize", 0.02, 0.5, 0.01,
    function(v) return string.format("%.2f", v) end)
UI.toggle(sWeather, "Snow", "WorldSnow")
UI.slider(sWeather, "Snow Rate", "WorldSnowRate", 30, 800, 10,
    function(v) return tostring(math.floor(v)) end)
UI.slider(sWeather, "Snow Speed", "WorldSnowSpeed", 1, 30, 1,
    function(v) return tostring(math.floor(v)) end)
UI.slider(sWeather, "Snow Size", "WorldSnowSize", 0.05, 1, 0.05,
    function(v) return string.format("%.2f", v) end)
UI.toggle(sWeather, "Thunderstorm", "WorldThunder")
UI.slider(sWeather, "Thunder Min Pause", "WorldThunderMin", 1, 15, 1,
    function(v) return tostring(math.floor(v)) .. "s" end)
UI.slider(sWeather, "Thunder Max Pause", "WorldThunderMax", 2, 30, 1,
    function(v) return tostring(math.floor(v)) .. "s" end)
UI.slider(sWeather, "Thunder Brightness", "WorldThunderBright", 20, 100, 5,
    function(v) return tostring(math.floor(v)) end)

local sFog = UI.section(worldTab, "ATMOSPHERE")
UI.toggle(sFog, "Enable Fog", "WorldFog")
UI.slider(sFog, "Density", "WorldFogDensity", 0.1, 1, 0.05,
    function(v) return string.format("%.2f", v) end)
UI.slider(sFog, "Haze", "WorldFogHaze", 0, 10, 0.5,
    function(v) return string.format("%.1f", v) end)

local sPost = UI.section(worldTab, "POST-FX")
UI.toggle(sPost, "Vignette", "WorldVignette")
UI.slider(sPost, "Vignette Strength", "WorldVignetteStrength", 0.05, 0.5, 0.05,
    function(v) return string.format("%.2f", v) end)
UI.toggle(sPost, "Color Shift", "WorldColorShift")
UI.colorPalette(sPost, "Shift Color", "WorldColorShiftColor")
UI.toggle(sPost, "Blur", "WorldBlur")
UI.slider(sPost, "Blur Size", "WorldBlurSize", 0, 20, 1,
    function(v) return tostring(math.floor(v)) end)

-- ───────── FOLDER 4: Auto Mix ─────────
local autoTab = win:makeTab("Auto Mix", "🤖", "movement · automation · scanner")
local sMove = UI.section(autoTab, "MOVEMENT")
UI.toggle(sMove, "SpeedHack", "SpeedHack")
UI.slider(sMove, "Speed", "Speed", 16, 300, 2,
    function(v) return tostring(math.floor(v)) end)
UI.toggle(sMove, "Fly", "Fly")
UI.slider(sMove, "Fly Speed", "FlySpeed", 10, 500, 5,
    function(v) return tostring(math.floor(v)) end)
UI.toggle(sMove, "Noclip", "Noclip")
UI.toggle(sMove, "Infinite Jump", "InfiniteJump")
UI.toggle(sMove, "Custom Jump Power", "JumpPowerEnable")
UI.slider(sMove, "Jump Power", "JumpPower", 50, 500, 5,
    function(v) return tostring(math.floor(v)) end)
UI.button(sMove, "Teleport to Mouse", function() Misc.teleportToMouse() end)

local sAutomation = UI.section(autoTab, "AUTOMATION")
UI.toggle(sAutomation, "Auto-Loot", "AutoLoot")
UI.dropdown(sAutomation, "Loot Mode", "AutoLootMode", {"Prompt", "Teleport"})
UI.slider(sAutomation, "Loot Max Distance", "AutoLootMaxDist", 10, 500, 10,
    function(v) return tostring(math.floor(v)) .. "m" end)
UI.slider(sAutomation, "Loot Interval", "AutoLootInterval", 0.05, 2, 0.05,
    function(v) return string.format("%.2fs", v) end)
UI.input(sAutomation, "Item Names (comma)", "AutoLootNamesList",
    "coin,gem,chest,drop",
    function(text)
        local out = {}
        for token in tostring(text):gmatch("[^,]+") do
            local t = token:match("^%s*(.-)%s*$")
            if t ~= "" then out[#out+1] = t end
        end
        Settings.AutoLootNames = out
    end)
UI.toggle(sAutomation, "Anti-AFK", "AntiAFK")
UI.slider(sAutomation, "Anti-AFK Interval", "AntiAFKInterval", 5, 120, 5,
    function(v) return tostring(math.floor(v)) .. "s" end)
UI.toggle(sAutomation, "Anti-AFK Chat Spam", "AntiAFKChatSpam")

local sScanner = UI.section(autoTab, "SCANNER")
UI.toggle(sScanner, "Strict Mode (Humanoid)", "ScanStrictRig")
UI.toggle(sScanner, "Debug Detector", "DetectorDebug")
UI.slider(sScanner, "Max Distance", "ScanMaxDist", 200, 8000, 100,
    function(v) return tostring(math.floor(v)) .. "m" end)
UI.slider(sScanner, "Max Entities", "ScanMaxEntities", 50, 500, 10,
    function(v) return tostring(math.floor(v)) end)
UI.slider(sScanner, "Scan Interval", "ScanInterval", 0.05, 0.5, 0.01,
    function(v) return string.format("%.2fs", v) end)
UI.input(sScanner, "Ignore Patterns (comma)", "ScanIgnoreList",
    "dummy,target,practice",
    function(text)
        local out = {}
        for token in tostring(text):gmatch("[^,]+") do
            local t = token:match("^%s*(.-)%s*$")
            if t ~= "" then out[#out+1] = t end
        end
        Settings.ScanIgnorePatterns = out
    end)

-- ───────── FOLDER 5: Configs ─────────
local cfgTab = win:makeTab("Configs", "⚙️", "themes · save/load · presets")
local sThemes = UI.section(cfgTab, "THEMES")
UI.button(sThemes, "Default (purple-pink)",  function() applyTheme("Default") end)
UI.button(sThemes, "Cyber (neon cyan)",     function() applyTheme("Cyber")   end)
UI.button(sThemes, "Stealth (dark grey)",   function() applyTheme("Stealth") end)
UI.button(sThemes, "Sunset (orange-red)",   function() applyTheme("Sunset")  end)
UI.button(sThemes, "Forest (green)",        function() applyTheme("Forest")  end)
UI.input(sThemes, "Custom Theme Name", "CustomThemeName", "my_theme")
UI.button(sThemes, "Save Current as Theme", function()
    local name = Settings.CustomThemeName or "custom"
    SAVED_THEMES[name] = {
        MenuAccent = UI.C.accent,
        ESPColor = Settings.ESPColor,
        FovColor = Settings.AimColor,
        FovColorLocked = Settings.AimColorLocked,
        HudLogo = Settings.HudLogoColor,
        HudFps = Settings.HudFpsColor,
        HudTarget = Settings.HudTargetColor,
        RadarPlayer = Settings.RadarPlayerColor,
        RadarNPC = Settings.RadarNPCColor,
    }
    UI.notify("Theme saved: " .. name, "success")
end)

local sConfigs = UI.section(cfgTab, "CONFIG SAVE / LOAD (in-memory by UserId)")
UI.info(sConfigs, "Bound to UserId", tostring(MemoryConfigs.userId()))
UI.input(sConfigs, "Config Name", "CurrentConfig", "default")
UI.button(sConfigs, "Save Config", function()
    local ok, msg = MemoryConfigs.save(Settings.CurrentConfig)
    UI.notify(msg, ok and "success" or "error")
end)
UI.button(sConfigs, "Load Config", function()
    local ok, msg = MemoryConfigs.load(Settings.CurrentConfig)
    UI.notify(msg, ok and "success" or "error")
    if ok then UI.refresh() end
end)
local cfgList = MemoryConfigs.list()
UI.info(sConfigs, "Saved in memory", #cfgList > 0 and table.concat(cfgList, ", ") or "—")

local sProf = UI.section(cfgTab, "QUICK PRESETS")
UI.button(sProf, "▶  Legit  (safe)",    Profiles.Legit)
UI.button(sProf, "▶  HvH    (rage)",    Profiles.HvH)
UI.button(sProf, "▶  Ghost  (minimal)", Profiles.Ghost)
UI.button(sProf, "▶  Farm   (auto)",    Profiles.Farm)

local sBindProf = UI.section(cfgTab, "BIND PROFILES")
UI.input(sBindProf, "Profile Name", "CurrentBindProfile", "default")
UI.button(sBindProf, "Save Binds", function()
    local name = Settings.CurrentBindProfile or "default"
    Settings.BindProfiles = Settings.BindProfiles or {}
    Settings.BindProfiles[name] = {}
    for _, entry in ipairs(BindList) do
        Settings.BindProfiles[name][entry.id] = {
            key = getBindKey(entry.id),
            mode = getBindMode(entry.id),
        }
    end
    UI.notify("Binds saved: " .. name, "success")
end)
UI.button(sBindProf, "Load Binds", function()
    local name = Settings.CurrentBindProfile or "default"
    local p = Settings.BindProfiles and Settings.BindProfiles[name]
    if not p then UI.notify("Not found", "error"); return end
    for _, entry in ipairs(BindList) do
        local b = p[entry.id]
        if b then
            setBindKey(entry.id, b.key)
            setBindMode(entry.id, b.mode)
        end
    end
    BindStrip.rebuild()
    UI.notify("Binds loaded: " .. name, "success")
end)

local sServer = UI.section(cfgTab, "SERVER")
UI.button(sServer, "Rejoin", function() Misc.rejoin() end)

-- ───────── FOLDER 6: System ─────────
local sysTab = win:makeTab("System", "🛠", "binds · HUD · performance")
local sKeys = UI.section(sysTab, "BINDS")
UI.keybind(sKeys, "Menu Key", "MenuKey")
UI.toggle(sKeys, "Show Bind Strip", "BindStripEnabled")
UI.button(sKeys, "Edit Binds", function() BindEditor.open() end)
UI.dropdown(sKeys, "Strip Label", "BindStripLabel", {"short", "full", "icon", "none"})
UI.slider(sKeys, "Dot Size", "BindStripSize", 10, 28, 1,
    function(v) return tostring(math.floor(v)) end)
UI.dropdown(sKeys, "Strip Position", "BindStripPosition",
    {"Top Center", "Bottom Center", "Top Left", "Top Right",
     "Bottom Left", "Bottom Right", "Custom"},
    function() BindStrip.applyPreset() end)

local sHud = UI.section(sysTab, "HUD")
UI.toggle(sHud, "Logo", "HudShowLogo")
UI.toggle(sHud, "Time (MSK)", "HudShowTime")
UI.toggle(sHud, "FPS", "HudShowFps")
UI.toggle(sHud, "Ping", "HudShowPing")
UI.toggle(sHud, "Target", "HudShowTarget")
UI.toggle(sHud, "Entity Count", "HudShowEntities")
UI.toggle(sHud, "Show Combat Stats (lock rate, avg dist)", "HudShowCombatStats")

local sPerf = UI.section(sysTab, "PERFORMANCE")
UI.toggle(sPerf, "Spatial Grid (faster scan)", "PerfSpatialGrid")
UI.toggle(sPerf, "Cache ESP (faster)", "PerfCacheESP")
UI.toggle(sPerf, "Batch Visibility (faster)", "PerfBatchVis")
UI.slider(sPerf, "ESP Move Threshold", "ESPMoveThreshold", 1, 30, 1,
    function(v) return tostring(math.floor(v)) .. " studs" end)
UI.slider(sPerf, "ESP Cache Interval", "ESPCacheInterval", 0.01, 0.2, 0.01,
    function(v) return string.format("%.2fs", v) end)
UI.toggle(sPerf, "Auto-optimize on low FPS", "AutoOptimize")
UI.slider(sPerf, "Min FPS Threshold", "MinFpsThreshold", 30, 60, 1,
    function(v) return tostring(math.floor(v)) end)

-- sync UI mirrors
do
    Settings.ScanIgnoreList = table.concat(Settings.ScanIgnorePatterns or {}, ",")
    Settings.AutoLootNamesList = table.concat(Settings.AutoLootNames or {}, ",")
    Settings.AimStickyMode = Settings.AimStickyStrict and "Strict" or "Soft"
end
if Settings.ESPHighlightOccluded then
    Settings.ESPHighlightMode = "Occluded"
else
    Settings.ESPHighlightMode = "AlwaysOnTop"
end

applyTheme(Settings.CurrentTheme or "Default")

-- ================== MENU KEY ==================
UIS.InputBegan:Connect(function(input)
    if UI.listening then return end
    local mk = Settings.MenuKey
    if not mk then return end
    local tn = enumTypeName(mk)
    if tn == "KeyCode" then
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == mk then
            win:toggle()
        end
    elseif tn == "UserInputType" then
        if input.UserInputType == mk then win:toggle() end
    end
end)

-- ================== BIND LISTENER ==================
UIS.InputBegan:Connect(function(input)
    if UI.listening then return end
    for _, entry in ipairs(BindList) do
        local key = getBindKey(entry.id)
        if key and bindMatches(key, input) then
            local mode = getBindMode(entry.id)
            local s = ensureBindState(entry.id)
            if mode == "Hold" then s.down = true
            else s.toggle = not s.toggle end
        end
    end
end)
UIS.InputEnded:Connect(function(input)
    for _, entry in ipairs(BindList) do
        local key = getBindKey(entry.id)
        if key and bindMatches(key, input) then
            if getBindMode(entry.id) == "Hold" then
                local s = ensureBindState(entry.id)
                s.down = false
            end
        end
    end
end)
UIS.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode ~= Enum.KeyCode.Backspace then return end
    if UI.listening then return end
    if UI._activePicker then pcall(function() UI._activePicker:Destroy() end); UI._activePicker = nil end
end)

-- ================== FOV CIRCLE ==================
task.spawn(function()
    local circle = Drawing.new("Circle")
    circle.Thickness=1.5; circle.NumSides=96
    circle.Filled=false; circle.Transparency=1
    safeRender(function()
        if not Settings.ShowFov or not Settings.Aimbot then circle.Visible = false; return end
        circle.Visible = true
        local c = UIS:GetMouseLocation()
        circle.Position = Vector2.new(c.X, c.Y)
        local mult = 1.0
        if Settings.FovExpand and Settings.FovExpandStationary then
            mult = Settings.FovExpandStationaryMult or 1.3
        end
        circle.Radius = Settings.FOV * mult
        if Aimbot.hasTarget() then
            circle.Color = Settings.AimColorLocked or Color3.fromRGB(255,80,120)
        else
            circle.Color = Settings.AimColor
        end
    end)
end)

-- ================== BOOT ==================
Aimbot.start()
ESP.start()
Radar.start()
VisibilityCache.start()
AutoParry.start()
AutoLoot.start()
AntiAFK.start()
HUD.start()
BindStrip.start()
FPSOptimizer.start()
TargetHistory.start()
UI.refresh()
BindStrip.applyPreset()
UI.notify("cfgkotik v37 FINAL loaded", "success")