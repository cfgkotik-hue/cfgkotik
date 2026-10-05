--!nocheck
-- cfgkotik v37 FINAL — Main Loader
local NS = getgenv().CFGKOTIK or {}
getgenv().CFGKOTIK = NS

local BASE = "https://cdn.jsdelivr.net/gh/cfgkotik-hue/cfgkotik@main/"
local CACHE_BUST = ""

local FILES = {
    -- 0. base
    "constants.lua",
    "helpers.lua",
    "settings.lua",

    -- 1. core
    "hooks.lua",
    "spatial-grid.lua",
    "scanner.lua",
    "visibility.lua",

    -- 2. UI
    "framework.lua",
    "themes.lua",
    "colorpicker.lua",
    "bindstrip.lua",
    "bindeditor.lua",

    -- 3. combat
    "aimbot.lua",
    "hitbox.lua",
    "autoparry.lua",

    -- 4. visual
    "esp.lua",
    "radar.lua",
    "world.lua",

    -- 5. movement / automation
    "movement.lua",
    "autoloot.lua",
    "antiafk.lua",

    -- 6. utility
    "memory-config.lua",
    "profiles.lua",
    "misc.lua",

    -- 7. hud
    "hud.lua",

    -- 8. menu (последним — зависит от всего выше)
    "menu.lua",
}

-- ================== fetch + run ==================
local failed = {}

for _, path in ipairs(FILES) do
    local ok, src = pcall(function()
        return game:HttpGet(BASE .. path .. CACHE_BUST)
    end)

    if not ok or not src or #src == 0
       or src:sub(1, 3) == "404"
       or src:sub(1, 15) == "<!DOCTYPE html>" then
        failed[#failed+1] = path
        warn("[cfgkotik] fetch failed: " .. path)
    else
        local fn, cErr = loadstring(src, "@" .. path)
        if not fn then
            warn("[cfgkotik] compile " .. path .. ": " .. tostring(cErr))
        else
            local ok2, rErr = pcall(fn)
            if not ok2 then
                warn("[cfgkotik] runtime " .. path .. ": " .. tostring(rErr))
            end
        end
    end
end

-- ================== BOOT ==================
local function safeCall(name, fn)
    if type(fn) ~= "function" then
        warn("[cfgkotik] " .. name .. " not a function")
        return
    end
    local ok, err = pcall(fn)
    if not ok then
        warn("[cfgkotik] " .. name .. " failed: " .. tostring(err))
    end
end

if NS.Aimbot    and NS.Aimbot.start    then safeCall("Aimbot.start", NS.Aimbot.start) end
if NS.ESP       and NS.ESP.start       then safeCall("ESP.start", NS.ESP.start) end
if NS.Radar     and NS.Radar.start     then safeCall("Radar.start", NS.Radar.start) end
if NS.HUD       and NS.HUD.start       then safeCall("HUD.start", NS.HUD.start) end
if NS.BindStrip and NS.BindStrip.start then safeCall("BindStrip.start", NS.BindStrip.start) end

if NS.buildMenu then
    safeCall("buildMenu", NS.buildMenu)
end

-- ================== MENU KEY ==================
if NS.UIS and NS._menuWin and NS.Settings and NS.Settings.MenuKey then
    local mk = NS.Settings.MenuKey
    NS.UIS.InputBegan:Connect(function(input)
        if NS.UI and NS.UI.listening then return end
        local t = NS.enumTypeName and NS.enumTypeName(mk)
        if t == "KeyCode" then
            if input.UserInputType == Enum.UserInputType.Keyboard
               and input.KeyCode == mk then
                NS._menuWin:toggle()
            end
        elseif t == "UserInputType" then
            if input.UserInputType == mk then NS._menuWin:toggle() end
        end
    end)
end

-- ================== FOV CIRCLE ==================
if NS.safeRender and Drawing then
    task.spawn(function()
        local circle = Drawing.new("Circle")
        circle.Thickness = 1.5
        circle.NumSides = 96
        circle.Filled = false
        circle.Transparency = 1
        NS.safeRender(function()
            local S = NS.Settings
            if not S or not S.ShowFov or not S.Aimbot then
                circle.Visible = false
                return
            end
            circle.Visible = true
            local c = NS.UIS:GetMouseLocation()
            circle.Position = Vector2.new(c.X, c.Y)
            local mult = 1.0
            if S.FovExpand and S.FovExpandStationary then
                mult = S.FovExpandStationaryMult or 1.3
            end
            circle.Radius = S.FOV * mult
            if NS.Aimbot.hasTarget and NS.Aimbot.hasTarget() then
                circle.Color = S.AimColorLocked or Color3.fromRGB(255, 80, 120)
            else
                circle.Color = S.AimColor
            end
        end)
    end)
end

-- ================== DONE ==================
if NS.UI and NS.UI.notify then
    NS.UI.notify("cfgkotik v37 FINAL loaded", "success")
end

if #failed > 0 then
    warn("[cfgkotik] missing files: " .. table.concat(failed, ", "))
end
