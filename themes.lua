--!nocheck
-- cfgkotik v37 — Themes (apply / save / list)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

-- ================== APPLY ==================
function NS.applyTheme(themeName)
    local theme = NS.THEMES[themeName] or NS.SAVED_THEMES[themeName]
    if not theme then
        if NS.UI and NS.UI.notify then
            NS.UI.notify("Theme not found: " .. tostring(themeName), "error")
        end
        return false
    end

    -- menu accent
    if NS.UI and NS.UI.C then
        NS.UI.C.accent = theme.MenuAccent
    end

    -- window glow + version label
    local w = NS.UI and NS.UI.window
    if w and w.main then
        local glow = w.main:FindFirstChild("accentGlow")
        if glow then glow.BackgroundColor3 = theme.MenuAccent end
        if w.verLabel then w.verLabel.TextColor3 = theme.MenuAccent end
    end

    -- settings colors
    local S = NS.Settings
    if S then
        S.AimColor         = theme.FovColor
        S.AimColorLocked   = theme.FovColorLocked
        S.ESPColor         = theme.ESPColor
        S.HudLogoColor     = theme.HudLogo
        S.HudFpsColor      = theme.HudFps
        S.HudTargetColor   = theme.HudTarget
        S.RadarPlayerColor = theme.RadarPlayer
        S.RadarNPCColor    = theme.RadarNPC
        S.CurrentTheme     = themeName
    end

    -- redraw UI + HUD
    if NS.UI and NS.UI.refresh then NS.UI.refresh() end
    if NS.HUD and NS.HUD.applyColors then NS.HUD.applyColors() end

    if NS.UI and NS.UI.notify then
        NS.UI.notify("Theme: " .. themeName, "success")
    end
    return true
end

-- ================== SAVE ==================
function NS.saveTheme(name)
    name = name or NS.Settings and NS.Settings.CustomThemeName or "custom"
    if name == "" then name = "custom" end

    local S = NS.Settings
    local C = NS.UI and NS.UI.C
    if not S or not C then
        if NS.UI and NS.UI.notify then
            NS.UI.notify("Cannot save — UI not ready", "error")
        end
        return false
    end

    NS.SAVED_THEMES[name] = {
        MenuAccent     = C.accent,
        ESPColor       = S.ESPColor,
        FovColor       = S.AimColor,
        FovColorLocked = S.AimColorLocked,
        HudLogo        = S.HudLogoColor,
        HudFps         = S.HudFpsColor,
        HudTarget      = S.HudTargetColor,
        RadarPlayer    = S.RadarPlayerColor,
        RadarNPC       = S.RadarNPCColor,
    }

    if NS.UI and NS.UI.notify then
        NS.UI.notify("Theme saved: " .. name, "success")
    end
    return true
end

-- ================== LIST ==================
function NS.listThemes()
    local out = {}
    for name in pairs(NS.THEMES) do out[#out+1] = name end
    table.sort(out)
    local saved = {}
    for name in pairs(NS.SAVED_THEMES) do saved[#saved+1] = name end
    table.sort(saved)
    return out, saved
end

return NS
