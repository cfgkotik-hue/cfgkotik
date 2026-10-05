--!nocheck
-- cfgkotik v37 — Quick Presets (Legit / HvH / Ghost / Farm)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

NS.Profiles = (function()
    local M = {}

    -- ================== apply helper ==================
    local function apply(preset, name)
        local S = NS.Settings
        for k, v in pairs(preset) do
            S[k] = v
        end
        if NS.UI and NS.UI.refresh then NS.UI.refresh() end
        if NS.BindStrip and NS.BindStrip.rebuild then NS.BindStrip.rebuild() end
        if NS.UI and NS.UI.notify then
            NS.UI.notify(name .. " loaded", "success")
        end
    end

    -- ================== presets ==================
    M.Legit = function()
        apply({
            Aimbot = true,
            FOV = 80,
            AimSmoothMode = "Smooth",
            AimStickyStrict = true,
            SilentAim = false,
            TriggerBot = false,
            HitboxExpand = false,
            ESP = false,
            ESPBox = true,
            ESPName = true,
            ESPHealth = true,
            ESPHighlight = false,
            ESPTracers = false,
            ESPDistanceColors = false,
            SpeedHack = false,
            Fly = false,
            Noclip = false,
            AutoParry = false,
            AutoLoot = false,
            AntiAFK = false,
            RadarEnabled = false,
            CameraFov = false,
            ThirdPerson = false,
        }, "Legit")
    end

    M.HvH = function()
        apply({
            Aimbot = true,
            FOV = 300,
            AimSmoothMode = "Ultra",
            AimStickyStrict = false,
            SilentAim = true,
            SilentAimMaxFireRate = 60,
            TriggerBot = true,
            HitboxExpand = true,
            HitboxSize = 5,
            ESP = true,
            ESPBox = true,
            ESPName = true,
            ESPHealth = true,
            ESPHighlight = true,
            ESPHighlightOccluded = true,
            ESPTracers = true,
            ESPDistanceColors = true,
            SpeedHack = true,
            Speed = 80,
            Fly = true,
            FlySpeed = 120,
            Noclip = true,
            AutoParry = true,
            AutoLoot = false,
            AntiAFK = true,
            RadarEnabled = true,
            RadarRange = 500,
            CameraFov = true,
            CameraFovAmount = 1.15,
        }, "HvH")
    end

    M.Ghost = function()
        apply({
            Aimbot = true,
            Priority = "Crosshair",
            FOV = 60,
            AimSmoothMode = "Smooth",
            AimStickyStrict = false,
            SilentAim = false,
            TriggerBot = false,
            HitboxExpand = false,
            ESP = false,
            ESPBox = false,
            ESPName = false,
            ESPHealth = false,
            ESPHighlight = false,
            ESPTracers = false,
            ESPDistanceColors = false,
            SpeedHack = false,
            Fly = false,
            Noclip = false,
            AutoParry = false,
            AutoLoot = false,
            AntiAFK = true,
            RadarEnabled = true,
            RadarShowPlayers = true,
            RadarShowNPCs = false,
            RadarRange = 250,
            CameraFov = false,
            ThirdPerson = false,
        }, "Ghost")
    end

    M.Farm = function()
        apply({
            Aimbot = false,
            SilentAim = false,
            TriggerBot = false,
            HitboxExpand = false,
            ESP = true,
            ESPShowPlayers = false,
            ESPShowNPCs = true,
            ESPBox = true,
            ESPName = true,
            ESPHealth = false,
            ESPHighlight = false,
            ESPTracers = false,
            ESPDistanceColors = false,
            SpeedHack = true,
            Speed = 60,
            Fly = true,
            FlySpeed = 100,
            Noclip = true,
            AutoParry = false,
            AutoLoot = true,
            AutoLootMode = "Teleport",
            AutoLootMaxDist = 150,
            AntiAFK = true,
            RadarEnabled = false,
            CameraFov = false,
            ThirdPerson = false,
        }, "Farm")
    end

    -- ================== custom ==================
    function M.apply(custom, name)
        apply(custom or {}, name or "Custom")
    end

    function M.list()
        return { "Legit", "HvH", "Ghost", "Farm" }
    end

    return M
end)()

return NS
