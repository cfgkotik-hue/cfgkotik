--!nocheck
-- cfgkotik v37 — Constants (themes, rig tables, binds, hints)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

-- ================== THEMES ==================
NS.THEMES = {
    Default = {
        MenuAccent     = Color3.fromRGB(0,170,255),
        ESPColor       = Color3.fromRGB(230,80,100),
        FovColor       = Color3.fromRGB(140,100,255),
        FovColorLocked = Color3.fromRGB(255,80,120),
        HudLogo        = Color3.fromRGB(10,132,255),
        HudFps         = Color3.fromRGB(80,200,130),
        HudTarget      = Color3.fromRGB(230,80,100),
        RadarPlayer    = Color3.fromRGB(230,80,100),
        RadarNPC       = Color3.fromRGB(255,200,60),
    },
    Cyber = {
        MenuAccent     = Color3.fromRGB(0,255,255),
        ESPColor       = Color3.fromRGB(0,255,255),
        FovColor       = Color3.fromRGB(0,200,255),
        FovColorLocked = Color3.fromRGB(255,0,255),
        HudLogo        = Color3.fromRGB(0,255,255),
        HudFps         = Color3.fromRGB(0,255,200),
        HudTarget      = Color3.fromRGB(255,0,255),
        RadarPlayer    = Color3.fromRGB(0,255,255),
        RadarNPC       = Color3.fromRGB(255,100,255),
    },
    Stealth = {
        MenuAccent     = Color3.fromRGB(140,140,160),
        ESPColor       = Color3.fromRGB(80,80,90),
        FovColor       = Color3.fromRGB(120,120,140),
        FovColorLocked = Color3.fromRGB(160,100,120),
        HudLogo        = Color3.fromRGB(140,140,160),
        HudFps         = Color3.fromRGB(100,160,120),
        HudTarget      = Color3.fromRGB(160,100,100),
        RadarPlayer    = Color3.fromRGB(160,100,100),
        RadarNPC       = Color3.fromRGB(160,140,100),
    },
    Sunset = {
        MenuAccent     = Color3.fromRGB(255,120,50),
        ESPColor       = Color3.fromRGB(255,80,60),
        FovColor       = Color3.fromRGB(255,140,60),
        FovColorLocked = Color3.fromRGB(255,50,80),
        HudLogo        = Color3.fromRGB(255,120,50),
        HudFps         = Color3.fromRGB(255,180,80),
        HudTarget      = Color3.fromRGB(255,80,80),
        RadarPlayer    = Color3.fromRGB(255,80,60),
        RadarNPC       = Color3.fromRGB(255,180,80),
    },
    Forest = {
        MenuAccent     = Color3.fromRGB(80,200,120),
        ESPColor       = Color3.fromRGB(60,200,100),
        FovColor       = Color3.fromRGB(80,180,80),
        FovColorLocked = Color3.fromRGB(200,200,80),
        HudLogo        = Color3.fromRGB(80,200,120),
        HudFps         = Color3.fromRGB(80,220,140),
        HudTarget      = Color3.fromRGB(180,200,80),
        RadarPlayer    = Color3.fromRGB(60,200,100),
        RadarNPC       = Color3.fromRGB(200,180,80),
    },
}
NS.SAVED_THEMES = {}

-- ================== RIG PARTS ==================
NS.RIG_PARTS = {
    "Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg",
    "UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","LeftHand",
    "RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg",
    "LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot",
}

NS.RIG_GROUP = {
    Head="Head", Torso="Torso", UpperTorso="Torso", LowerTorso="Torso", Chest="Torso",
    LeftUpperArm="Limbs", LeftLowerArm="Limbs", LeftHand="Limbs",
    RightUpperArm="Limbs", RightLowerArm="Limbs", RightHand="Limbs",
    LeftUpperLeg="Limbs", LeftLowerLeg="Limbs", LeftFoot="Limbs",
    RightUpperLeg="Limbs", RightLowerLeg="Limbs", RightFoot="Limbs",
    ["Left Arm"]="Limbs", ["Right Arm"]="Limbs",
    ["Left Leg"]="Limbs", ["Right Leg"]="Limbs",
}

-- ================== HEURISTICS ==================
NS.HEUR_HEAD  = { "head", "skull", "neck" }
NS.HEUR_TORSO = { "torso", "chest", "spine", "body", "upper", "lower", "hip", "pelvis", "root" }
NS.HEUR_LIMB  = { "arm", "hand", "leg", "foot", "shoulder", "thigh", "shin", "knee", "elbow", "forearm", "wrist" }

-- ================== BAD PART NAMES ==================
NS.BAD_NAME_PATTERNS = {
    "^handle$", "^grip$", "^weapon$", "^gun$", "^rifle$", "^pistol$",
    "^ammo", "^mag", "^scope$", "attachment",
}

-- ================== INPUT LABELS ==================
NS.MOUSE_LABELS = {
    MouseButton1="ЛКМ", MouseButton2="ПКМ", MouseButton3="СКМ",
    MouseMovement="Мышь", Touch="Тач",
}

NS.BLACKLISTED_KEYS = {
    [Enum.KeyCode.Unknown]=true,
    [Enum.KeyCode.Tab]=true,
    [Enum.KeyCode.Backspace]=true,
    [Enum.KeyCode.Escape]=true,
}

-- ================== AUTOPARRY HINTS ==================
NS.ATTACK_HINTS = {
    "slash","swing","attack","stab","punch",
    "hit","combo","strike","smash",
}

-- ================== BIND LIST ==================
NS.BindList = {
    { id="AimKey",     label="Aim Key",     icon="🎯", short="A" },
    { id="FovExpand",  label="FOV Expand",  icon="🔭", short="F" },
    { id="Trigger",    label="Trigger Bot", icon="⚡", short="T" },
    { id="Hitbox",     label="Hitbox",      icon="📦", short="H" },
    { id="Visibility", label="Visibility",  icon="👁", short="V" },
    { id="Speed",      label="SpeedHack",   icon="💨", short="S" },
    { id="Fly",        label="Fly",         icon="🕊", short="Y" },
}

return NS
