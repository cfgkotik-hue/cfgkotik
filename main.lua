--!nocheck
-- cfgkotik v37 FINAL — Main Loader
local BASE = "https://raw.githubusercontent.com/cfgkotik-hue/cfgkotik/main/"

local function load(path)
    local CACHE_BUST = "?nocache=" .. tostring(os.time())
local function load(path)
    local ok, src = pcall(function() return game:HttpGet(BASE .. path .. CACHE_BUST) end)
    if not ok then
        warn("[cfgkotik] Failed to load: " .. path .. " — " .. tostring(result))
        return nil
    end
    return result
end

-- Load order: data → utils → core → features → UI → boot
local constants    = load("constants.lua")
local helpers      = load("helpers.lua")
local memoryConfig = load("memory-config.lua")
local themes       = load("themes.lua")
local profiles     = load("profiles.lua")
local misc         = load("misc.lua")
local settings     = load("settings.lua")
local hooks        = load("hooks.lua")
local scanner      = load("scanner.lua")
local spatialGrid  = load("spatial-grid.lua")
local visibility   = load("visibility.lua")
local aimbot       = load("aimbot.lua")
local esp          = load("esp.lua")
local radar        = load("radar.lua")
local movement     = load("movement.lua")
local hitbox       = load("hitbox.lua")
local autoParry    = load("autoparry.lua")
local autoLoot     = load("autoloot.lua")
local antiAFK      = load("antiafk.lua")
local world        = load("world.lua")
local UI           = load("framework.lua")
local menu         = load("menu.lua")
local hud          = load("hud.lua")
local bindStrip    = load("bindstrip.lua")
local colorPicker  = load("colorpicker.lua")
local bindEditor   = load("bindeditor.lua")

-- Boot (каждый вызов обёрнут, чтобы один упавший модуль не убил остальные)
local function safeCall(name, fn)
    if type(fn) ~= "function" then
        warn("[cfgkotik] " .. name .. " is not a function or module is nil")
        return
    end
    local ok, err = pcall(fn)
    if not ok then warn("[cfgkotik] " .. name .. " failed: " .. tostring(err)) end
end

if aimbot and aimbot.start then safeCall("aimbot.start", aimbot.start) end
if esp and esp.start then safeCall("esp.start", esp.start) end
if radar and radar.start then safeCall("radar.start", radar.start) end
if visibility and visibility.start then safeCall("visibility.start", visibility.start) end
if autoParry and autoParry.start then safeCall("autoParry.start", autoParry.start) end
if autoLoot and autoLoot.start then safeCall("autoLoot.start", autoLoot.start) end
if antiAFK and antiAFK.start then safeCall("antiAFK.start", antiAFK.start) end
if hud and hud.start then safeCall("hud.start", hud.start) end
if bindStrip and bindStrip.start then safeCall("bindStrip.start", bindStrip.start) end
if menu and menu.build then safeCall("menu.build", menu.build) end
if UI and UI.notify then UI.notify("cfgkotik v37 FINAL loaded", "success") end
