--!nocheck
-- cfgkotik v37 — Menu Build (6 folder tabs)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

local UI = NS.UI

-- ================== build ==================
function NS.buildMenu()
    if NS._menuBuilt then return NS._menuWin end
    NS._menuBuilt = true

    local win = UI.createWindow()
    NS._menuWin = win

    -- ═══════════════════════════════════════════════════
    -- 1. AIM
    -- ═══════════════════════════════════════════════════
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
        local n = NS.Aimbot.getTargetName()
        if n then NS.Aimbot.addWhitelist(n); UI.notify("WL: " .. n, "success")
        else UI.notify("No target", "error") end
    end)
    UI.button(sFilter, "Blacklist Current Target", function()
        local n = NS.Aimbot.getTargetName()
        if n then NS.Aimbot.addBlacklist(n); UI.notify("BL: " .. n, "error")
        else UI.notify("No target", "error") end
    end)
    UI.button(sFilter, "Clear Lists", function()
        NS.Aimbot.clearLists(); UI.notify("Lists cleared", "success")
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
        function(v) NS.Settings.AimStickyStrict = (v == "Strict") end)

    local sParry = UI.section(aimTab, "AUTO-PARRY")
    UI.toggle(sParry, "Enable", "AutoParry")
    UI.keybind(sParry, "Parry Key", "AutoParryKey")
    UI.slider(sParry, "Offset", "AutoParryOffset", 0.01, 0.5, 0.01,
        function(v) return string.format("%.2fs", v) end)
    UI.slider(sParry, "Range", "AutoParryRange", 5, 100, 5,
        function(v) return tostring(math.floor(v)) .. "m" end)

    -- ═══════════════════════════════════════════════════
    -- 2. VISUAL
    -- ═══════════════════════════════════════════════════
    local visTab = win:makeTab("Visual", "👁", "ESP · chams · radar · camera")

    local sEsp = UI.section(visTab, "ESP")
    UI.toggle(sEsp, "Enable ESP", "ESP")
    UI.toggle(sEsp, "Show Players", "ESPShowPlayers")
    UI.toggle(sEsp, "Show NPCs", "ESPShowNPCs")
    UI.colorPalette(sEsp, "ESP Color", "ESPColor")
    UI.toggle(sEsp, "Box", "ESPBox")
    UI.dropdown(sEsp, "Box Style", "ESPBoxStyle", {"full", "corner"})
    UI.toggle(sEsp, "Name", "ESPName")
    UI.toggle(sEsp, "Distance", "ESPDistance")
    UI.toggle(sEsp, "Health Bar", "ESPHealth")
    UI.toggle(sEsp, "Weapon", "ESPWeapon")
    UI.toggle(sEsp, "Tracers", "ESPTracers")
    UI.dropdown(sEsp, "Tracer Origin", "ESPTracerFrom", {"Bottom", "Top", "Mouse"})
    UI.slider(sEsp, "Max Distance", "ESPMaxDist", 100, 5000, 100,
        function(v) return tostring(math.floor(v)) .. "m" end)
    UI.slider(sEsp, "Update Rate", "ESPUpdateRate", 0.01, 0.1, 0.01,
        function(v) return string.format("%.2fs", v) end)
    UI.toggle(sEsp, "Distance Color Coding", "ESPDistanceColors")
    UI.slider(sEsp, "Near Threshold", "ESPNearThreshold", 10, 100, 5,
        function(v) return tostring(math.floor(v)) .. "m" end)
    UI.slider(sEsp, "Mid Threshold", "ESPMidThreshold", 50, 300, 10,
        function(v) return tostring(math.floor(v)) .. "m" end)
    UI.colorPalette(sEsp, "Near Color", "ESPNearColor")
    UI.colorPalette(sEsp, "Mid Color", "ESPMidColor")
    UI.colorPalette(sEsp, "Far Color", "ESPFarColor")

    local sHighlight = UI.section(visTab, "HIGHLIGHT (CHAMS)")
    UI.toggle(sHighlight, "Enable", "ESPHighlight")
    UI.dropdown(sHighlight, "Mode", "ESPHighlightMode", {"AlwaysOnTop", "Occluded"},
        function(v) NS.Settings.ESPHighlightOccluded = (v == "Occluded") end)

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

    -- ═══════════════════════════════════════════════════
    -- 3. WORLD
    -- ═══════════════════════════════════════════════════
    local wTab = win:makeTab("World", "🌦", "weather · fog · post-FX")

    local sWeather = UI.section(wTab, "WEATHER")
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

    local sFog = UI.section(wTab, "ATMOSPHERE")
    UI.toggle(sFog, "Enable Fog", "WorldFog")
    UI.slider(sFog, "Density", "WorldFogDensity", 0.1, 1, 0.05,
        function(v) return string.format("%.2f", v) end)
    UI.slider(sFog, "Haze", "WorldFogHaze", 0, 10, 0.5,
        function(v) return string.format("%.1f", v) end)

    local sPost = UI.section(wTab, "POST-FX")
    UI.toggle(sPost, "Vignette", "WorldVignette")
    UI.slider(sPost, "Vignette Strength", "WorldVignetteStrength", 0.05, 0.5, 0.05,
        function(v) return string.format("%.2f", v) end)
    UI.toggle(sPost, "Color Shift", "WorldColorShift")
    UI.colorPalette(sPost, "Shift Color", "WorldColorShiftColor")
    UI.toggle(sPost, "Blur", "WorldBlur")
    UI.slider(sPost, "Blur Size", "WorldBlurSize", 0, 20, 1,
        function(v) return tostring(math.floor(v)) end)

    -- ═══════════════════════════════════════════════════
    -- 4. AUTO MIX
    -- ═══════════════════════════════════════════════════
    local amTab = win:makeTab("Auto Mix", "🤖", "movement · automation · scanner")

    local sMove = UI.section(amTab, "MOVEMENT")
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
    UI.button(sMove, "Teleport to Mouse", function()
        NS.Misc.teleportToMouse()
    end)

    local sAuto = UI.section(amTab, "AUTOMATION")
    UI.toggle(sAuto, "Auto-Loot", "AutoLoot")
    UI.dropdown(sAuto, "Loot Mode", "AutoLootMode", {"Prompt", "Teleport"})
    UI.slider(sAuto, "Loot Max Distance", "AutoLootMaxDist", 10, 500, 10,
        function(v) return tostring(math.floor(v)) .. "m" end)
    UI.slider(sAuto, "Loot Interval", "AutoLootInterval", 0.05, 2, 0.05,
        function(v) return string.format("%.2fs", v) end)
    UI.input(sAuto, "Item Names (comma)", "AutoLootNamesList",
        "coin,gem,chest,drop",
        function(text)
            local out = {}
            for tok in tostring(text):gmatch("[^,]+") do
                local t = tok:match("^%s*(.-)%s*$")
                if t ~= "" then out[#out+1] = t end
            end
            NS.Settings.AutoLootNames = out
        end)
    UI.toggle(sAuto, "Anti-AFK", "AntiAFK")
    UI.slider(sAuto, "Anti-AFK Interval", "AntiAFKInterval", 5, 120, 5,
        function(v) return tostring(math.floor(v)) .. "s" end)
    UI.toggle(sAuto, "Anti-AFK Chat Spam", "AntiAFKChatSpam")

    local sScan = UI.section(amTab, "SCANNER")
    UI.toggle(sScan, "Strict Mode (Humanoid)", "ScanStrictRig")
    UI.toggle(sScan, "Debug Detector", "DetectorDebug")
    UI.slider(sScan, "Max Distance", "ScanMaxDist", 200, 8000, 100,
        function(v) return tostring(math.floor(v)) .. "m" end)
    UI.slider(sScan, "Max Entities", "ScanMaxEntities", 50, 500, 10,
        function(v) return tostring(math.floor(v)) end)
    UI.slider(sScan, "Scan Interval", "ScanInterval", 0.05, 0.5, 0.01,
        function(v) return string.format("%.2fs", v) end)
    UI.input(sScan, "Ignore Patterns (comma)", "ScanIgnoreList",
        "dummy,target,practice",
        function(text)
            local out = {}
            for tok in tostring(text):gmatch("[^,]+") do
                local t = tok:match("^%s*(.-)%s*$")
                if t ~= "" then out[#out+1] = t end
            end
            NS.Settings.ScanIgnorePatterns = out
        end)

    local sPerf = UI.section(amTab, "PERFORMANCE")
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

    -- ═══════════════════════════════════════════════════
    -- 5. CONFIGS
    -- ═══════════════════════════════════════════════════
    local cTab = win:makeTab("Configs", "⚙️", "themes · save/load · presets")

    local sThemes = UI.section(cTab, "THEMES")
    UI.button(sThemes, "Default (purple-pink)",
        function() NS.applyTheme("Default") end)
    UI.button(sThemes, "Cyber (neon cyan)",
        function() NS.applyTheme("Cyber")   end)
    UI.button(sThemes, "Stealth (dark grey)",
        function() NS.applyTheme("Stealth") end)
    UI.button(sThemes, "Sunset (orange-red)",
        function() NS.applyTheme("Sunset")  end)
    UI.button(sThemes, "Forest (green)",
        function() NS.applyTheme("Forest")  end)
    UI.input(sThemes, "Custom Theme Name", "CustomThemeName", "my_theme")
    UI.button(sThemes, "Save Current as Theme", function()
        local name = NS.Settings.CustomThemeName or "custom"
        NS.SAVED_THEMES[name] = {
            MenuAccent     = UI.C.accent,
            ESPColor       = NS.Settings.ESPColor,
            FovColor       = NS.Settings.AimColor,
            FovColorLocked = NS.Settings.AimColorLocked,
            HudLogo        = NS.Settings.HudLogoColor,
            HudFps         = NS.Settings.HudFpsColor,
            HudTarget      = NS.Settings.HudTargetColor,
            RadarPlayer    = NS.Settings.RadarPlayerColor,
            RadarNPC       = NS.Settings.RadarNPCColor,
        }
        UI.notify("Theme saved: " .. name, "success")
    end)

    local sCf = UI.section(cTab, "CONFIG SAVE / LOAD (in-memory by UserId)")
    UI.info(sCf, "Bound to UserId", NS.MemoryConfigs.userId())
    UI.input(sCf, "Config Name", "CurrentConfig", "default")
    UI.button(sCf, "Save Config", function()
        local ok, msg = NS.MemoryConfigs.save(NS.Settings.CurrentConfig)
        UI.notify(msg, ok and "success" or "error")
    end)
    UI.button(sCf, "Load Config", function()
        local ok, msg = NS.MemoryConfigs.load(NS.Settings.CurrentConfig)
        UI.notify(msg, ok and "success" or "error")
        if ok then UI.refresh() end
    end)
    local list = NS.MemoryConfigs.list()
    UI.info(sCf, "Saved in memory",
        #list > 0 and table.concat(list, ", ") or "—")

    local sProf = UI.section(cTab, "QUICK PRESETS")
    UI.button(sProf, "▶  Legit  (safe)",    NS.Profiles.Legit)
    UI.button(sProf, "▶  HvH    (rage)",    NS.Profiles.HvH)
    UI.button(sProf, "▶  Ghost  (minimal)", NS.Profiles.Ghost)
    UI.button(sProf, "▶  Farm   (auto)",    NS.Profiles.Farm)

    local sBp = UI.section(cTab, "BIND PROFILES")
    UI.input(sBp, "Profile Name", "CurrentBindProfile", "default")
    UI.button(sBp, "Save Binds", function()
        local n = NS.Settings.CurrentBindProfile or "default"
        NS.Settings.BindProfiles = NS.Settings.BindProfiles or {}
        NS.Settings.BindProfiles[n] = {}
        for _, e in ipairs(NS.BindList) do
            NS.Settings.BindProfiles[n][e.id] = {
                key  = NS.getBindKey(e.id),
                mode = NS.getBindMode(e.id),
            }
        end
        UI.notify("Binds saved: " .. n, "success")
    end)
    UI.button(sBp, "Load Binds", function()
        local n = NS.Settings.CurrentBindProfile or "default"
        local p = NS.Settings.BindProfiles and NS.Settings.BindProfiles[n]
        if not p then UI.notify("Not found", "error"); return end
        for _, e in ipairs(NS.BindList) do
            local b = p[e.id]
            if b then
                NS.setBindKey(e.id, b.key)
                NS.setBindMode(e.id, b.mode)
            end
        end
        if NS.BindStrip and NS.BindStrip.rebuild then NS.BindStrip.rebuild() end
        UI.notify("Binds loaded: " .. n, "success")
    end)

    local sServer = UI.section(cTab, "SERVER")
    UI.button(sServer, "Rejoin", function() NS.Misc.rejoin() end)
    UI.button(sServer, "Copy Server Info", function() NS.Misc.copyServerInfo() end)

    -- ═══════════════════════════════════════════════════
    -- 6. SYSTEM
    -- ═══════════════════════════════════════════════════
    local sysTab = win:makeTab("System", "🛠", "binds · HUD · performance")

    local sKeys = UI.section(sysTab, "BINDS")
    UI.keybind(sKeys, "Menu Key", "MenuKey")
    UI.toggle(sKeys, "Show Bind Strip", "BindStripEnabled")
    UI.button(sKeys, "Edit Binds", function() NS.BindEditor.open() end)
    UI.dropdown(sKeys, "Strip Label", "BindStripLabel",
        {"short", "full", "icon", "none"})
    UI.slider(sKeys, "Dot Size", "BindStripSize", 10, 28, 1,
        function(v) return tostring(math.floor(v)) end)
    UI.dropdown(sKeys, "Strip Position", "BindStripPosition",
        {"Top Center", "Bottom Center", "Top Left", "Top Right",
         "Bottom Left", "Bottom Right", "Custom"},
        function() NS.BindStrip.applyPreset() end)

    local sHud = UI.section(sysTab, "HUD")
    UI.toggle(sHud, "Logo", "HudShowLogo")
    UI.toggle(sHud, "Time (MSK)", "HudShowTime")
    UI.toggle(sHud, "FPS", "HudShowFps")
    UI.toggle(sHud, "Ping", "HudShowPing")
    UI.toggle(sHud, "Target", "HudShowTarget")
    UI.toggle(sHud, "Entity Count", "HudShowEntities")
    UI.toggle(sHud, "Show Combat Stats (lock rate, avg dist)", "HudShowCombatStats")

    -- ============================================================
    -- SYNC UI MIRRORS
    -- ============================================================
    NS.Settings.ScanIgnoreList    = table.concat(NS.Settings.ScanIgnorePatterns or {}, ",")
    NS.Settings.AutoLootNamesList = table.concat(NS.Settings.AutoLootNames or {}, ",")
    NS.Settings.AimStickyMode     = NS.Settings.AimStickyStrict and "Strict" or "Soft"
    NS.Settings.ESPHighlightMode  = NS.Settings.ESPHighlightOccluded and "Occluded" or "AlwaysOnTop"

    -- apply saved theme
    if NS.applyTheme then
        NS.applyTheme(NS.Settings.CurrentTheme or "Default")
    end

    UI.refresh()

    return win
end

return NS
