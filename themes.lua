--!nocheck
-- cfgkotik v37 — Themes
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

-- THEMES уже определены в constants.lua, здесь только логика применения.
-- Если constants.lua не загрузился — защитная заглушка, чтобы файл не падал.
NS.THEMES = NS.THEMES or {}
NS.SAVED_THEMES = NS.SAVED_THEMES or {}

-- ===== APPLY THEME =====
function NS.applyTheme(name)
    local t = NS.THEMES[name] or NS.SAVED_THEMES[name]
    if not t then
        if NS.UI and NS.UI.notify then
            NS.UI.notify("Theme not found: " .. tostring(name), "error")
        end
        return
    end

    -- Menu accent
    if NS.UI and NS.UI.C then
        NS.UI.C.accent = t.MenuAccent
    end
    local w = NS.UI and NS.UI.window
    if w and w.main then
        local glow = w.main:FindFirstChild("accentGlow")
        if glow then glow.BackgroundColor3 = t.MenuAccent end
        if w.verLabel then w.verLabel.TextColor3 = t.MenuAccent end
    end

    -- Apply to Settings (safe: only if Settings exists)
    local S = NS.Settings
    if S then
        local map = {
            AimColor = "FovColor",
            AimColorLocked = "FovColorLocked",
            ESPColor = "ESPColor",
            HudLogoColor = "HudLogo",
            HudFpsColor = "HudFps",
            HudTargetColor = "HudTarget",
            RadarPlayerColor = "RadarPlayer",
            RadarNPCColor = "RadarNPC",
        }
        for k, tk in pairs(map) do
            if t[tk] ~= nil then S[k] = t[tk] end
        end
        S.CurrentTheme = name
    end

    -- Refresh
    if NS.UI and NS.UI.refresh then NS.UI.refresh() end
    if NS.HUD and NS.HUD.applyColors then NS.HUD.applyColors() end
    if NS.UI and NS.UI.notify then
        NS.UI.notify("Theme: " .. name, "success")
    end
end

-- ===== SAVE CURRENT AS THEME =====
function NS.saveTheme(name)
    if not name or name == "" then name = "custom" end
    local S = NS.Settings
    local C = NS.UI and NS.UI.C
    if not S or not C then
        if NS.UI and NS.UI.notify then
            NS.UI.notify("Cannot save — UI/Settings not ready", "error")
        end
        return
    end
    NS.SAVED_THEMES[name] = {
        MenuAccent = C.accent,
        ESPColor = S.ESPColor,
        FovColor = S.AimColor,
        FovColorLocked = S.AimColorLocked,
        HudLogo = S.HudLogoColor,
        HudFps = S.HudFpsColor,
        HudTarget = S.HudTargetColor,
        RadarPlayer = S.RadarPlayerColor,
        RadarNPC = S.RadarNPCColor,
    }
    if NS.UI and NS.UI.notify then
        NS.UI.notify("Theme saved: " .. name, "success")
    end
end

return NS
