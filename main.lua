--!nocheck
-- cfgkotik v37 FINAL — Main Loader
local NS = getgenv().CFGKOTIK or {}
getgenv().CFGKOTIK = NS

local BASE = "https://raw.githubusercontent.com/cfgkotik-hue/cfgkotik/main/"
local CACHE_BUST = "?cb=" .. tostring(math.floor(os.clock() * 100000) % 1000000)

local FILES = {
    "constants.lua",
    "helpers.lua",
    "settings.lua",
    "hooks.lua",
    "spatial-grid.lua",
    "scanner.lua",
    "visibility.lua",
    "framework.lua",
    "themes.lua",
    "colorpicker.lua",
    "bindstrip.lua",
    "bindeditor.lua",
    "aimbot.lua",
    "hitbox.lua",
    "autoparry.lua",
    "esp.lua",
    "radar.lua",
    "world.lua",
    "movement.lua",
    "autoloot.lua",
    "antiafk.lua",
    "memory-config.lua",
    "profiles.lua",
    "misc.lua",
    "hud.lua",
    "menu.lua",
}

local failed = {}

for i = 1, #FILES do
    local path = FILES[i]
    local url = BASE .. path .. CACHE_BUST
    local ok, src = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and src and #src > 0 then
        local fn, cErr = loadstring(src, "@" .. path)
        if fn then
            local ok2, rErr = pcall(fn)
            if not ok2 then
                warn("[cfgkotik] runtime " .. path .. ": " .. tostring(rErr))
            end
        else
            warn("[cfgkotik] compile " .. path .. ": " .. tostring(cErr))
        end
    else
        failed[#failed + 1] = path
        warn("[cfgkotik] fetch failed: " .. path)
    end
end

-- boot
local function call(name, fn)
    if type(fn) == "function" then
        local ok, err = pcall(fn)
        if not ok then
            warn("[cfgkotik] " .. name .. ": " .. tostring(err))
        end
    end
end

if NS.Aimbot    and NS.Aimbot.start    then call("Aimbot",    NS.Aimbot.start)    end
if NS.ESP       and NS.ESP.start       then call("ESP",       NS.ESP.start)       end
if NS.Radar     and NS.Radar.start     then call("Radar",     NS.Radar.start)     end
if NS.HUD       and NS.HUD.start       then call("HUD",       NS.HUD.start)       end
if NS.BindStrip and NS.BindStrip.start then call("BindStrip", NS.BindStrip.start) end

if NS.buildMenu then call("buildMenu", NS.buildMenu) end

if NS.UIS and NS._menuWin and NS.Settings then
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
            if NS.Aimbot and NS.Aimbot.hasTarget and NS.Aimbot.hasTarget() then
                circle.Color = S.AimColorLocked or Color3.fromRGB(255, 80, 120)
            else
                circle.Color = S.AimColor
            end
        end)
    end)
end

if NS.UI and NS.UI.notify then
    NS.UI.notify("cfgkotik v37 FINAL loaded", "success")
end

if #failed > 0 then
    warn("[cfgkotik] missing: " .. table.concat(failed, ", "))
end
