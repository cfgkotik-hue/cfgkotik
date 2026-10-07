--!nocheck
-- cfgkotik v37 — World (weather, atmosphere, post-FX, camera)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

local Lighting  = game:GetService("Lighting")
local Workspace = NS.Workspace

local cache = {
    rainF=nil, rainPE=nil, rainC=nil,
    snowF=nil, snowPE=nil, snowC=nil,
    thunder=false, thunderTask=nil,
    vig=nil, shift=nil, blur=nil,
    origAtm={}, origL={},
    origMin=nil, origMax=nil, origFov=nil,
}
local last = {}

-- ================== snapshot originals ==================
do
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if atm then
        cache.origAtm = {
            Density = atm.Density, Offset = atm.Offset,
            Color   = atm.Color,   Decay  = atm.Decay,
            Haze    = atm.Haze,    Glare  = atm.Glare,
        }
    end
    cache.origL = {
        Brightness = Lighting.Brightness,
        ClockTime  = Lighting.ClockTime,
    }
    local cam = Workspace.CurrentCamera
    if cam then cache.origFov = cam.FieldOfView end
    if NS.LP then
        cache.origMin = NS.LP.CameraMinZoomDistance
        cache.origMax = NS.LP.CameraMaxZoomDistance
    end
end

-- ================== atmosphere ==================
local function getAtm()
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atm then
        atm = Instance.new("Atmosphere")
        atm.Parent = Lighting
    end
    return atm
end

local function restoreAtm()
    local atm = getAtm()
    local o = cache.origAtm
    atm.Density = o.Density or 0.3
    atm.Offset  = o.Offset  or 0
    atm.Color   = o.Color   or Color3.fromRGB(199,199,199)
    atm.Decay   = o.Decay   or Color3.fromRGB(108,112,133)
    atm.Haze    = o.Haze    or 0
    atm.Glare   = o.Glare   or 0
end

local function restoreLighting()
    Lighting.Brightness = cache.origL.Brightness or 2
    Lighting.ClockTime  = cache.origL.ClockTime  or 14
end

local function applyFog(on)
    local atm = getAtm()
    local S = NS.Settings
    if on then
        atm.Density = S.WorldFogDensity or 0.5
        atm.Offset  = 0.25
        atm.Color   = Color3.fromRGB(160,170,190)
        atm.Decay   = Color3.fromRGB(100,110,140)
        atm.Haze    = S.WorldFogHaze or 2
        atm.Glare   = 0.3
    else
        restoreAtm()
    end
end

-- ================== camera ==================
local function applyThirdPerson(on)
    if not NS.LP then return end
    local S = NS.Settings
    if on then
        local d = S.ThirdPersonDistance or 10
        pcall(function()
            NS.LP.CameraMinZoomDistance = d
            NS.LP.CameraMaxZoomDistance = math.max(d, cache.origMax or d)
        end)
    else
        pcall(function()
            NS.LP.CameraMinZoomDistance = cache.origMin or 0.5
            NS.LP.CameraMaxZoomDistance = cache.origMax or 400
        end)
    end
end

local function applyCameraFov(on)
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local S = NS.Settings
    if on then
        local base = cache.origFov or 70
        local amt  = S.CameraFovAmount or 1.0
        pcall(function()
            cam.FieldOfView = math.clamp(base * amt, 20, 120)
        end)
    else
        pcall(function()
            cam.FieldOfView = cache.origFov or 70
        end)
    end
end

-- ================== rain ==================
local function startRain()
    if cache.rainF then return end
    local S = NS.Settings
    local folder = Instance.new("Folder")
    folder.Name = "cfgkotik_rain"; folder.Parent = Workspace

    local e = Instance.new("Part")
    e.Name = "rain_emitter"
    e.Size = Vector3.new(200, 1, 200)
    e.Anchored = true; e.CanCollide = false; e.Transparency = 1
    e.Parent = folder

    local att = Instance.new("Attachment", e)
    local pe = Instance.new("ParticleEmitter")
    pe.Texture = "rbxassetid://241876428"
    pe.Rate = S.WorldRainRate or 300
    pe.Lifetime = NumberRange.new(0.4, 0.7)
    local sp = S.WorldRainSpeed or 90
    pe.Speed = NumberRange.new(sp * 0.8, sp * 1.2)
    pe.SpreadAngle = Vector2.new(0, 0)
    pe.Rotation = NumberRange.new(0, 0)
    pe.Color = ColorSequence.new(Color3.fromRGB(180, 200, 230))
    pe.Size = NumberSequence.new(S.WorldRainSize or 0.08)
    pe.Transparency = NumberSequence.new(0.4)
    pe.LightEmission = 0
    pe.LightInfluence = 0
    pe.Acceleration = Vector3.new(0, -sp * 2, 0)
    pe.EmissionDirection = Enum.NormalId.Bottom
    pe.Parent = att

    cache.rainF = folder
    cache.rainPE = pe
    cache.rainC = NS.safeRender(function()
        local cam = NS.Cam.cur or Workspace.CurrentCamera
        if cam then
            e.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, 40, 0))
        end
    end)
end

local function stopRain()
    if cache.rainC then cache.rainC:Disconnect(); cache.rainC = nil end
    if cache.rainF then cache.rainF:Destroy(); cache.rainF = nil end
    cache.rainPE = nil
end

-- ================== snow ==================
local function startSnow()
    if cache.snowF then return end
    local S = NS.Settings
    local folder = Instance.new("Folder")
    folder.Name = "cfgkotik_snow"; folder.Parent = Workspace

    local e = Instance.new("Part")
    e.Name = "snow_emitter"
    e.Size = Vector3.new(300, 1, 300)
    e.Anchored = true; e.CanCollide = false; e.Transparency = 1
    e.Parent = folder

    local att = Instance.new("Attachment", e)
    local pe = Instance.new("ParticleEmitter")
    pe.Texture = "rbxassetid://6075971289"
    pe.Rate = S.WorldSnowRate or 200
    pe.Lifetime = NumberRange.new(4, 8)
    local ss = S.WorldSnowSpeed or 4
    pe.Speed = NumberRange.new(ss * 0.5, ss * 1.5)
    pe.SpreadAngle = Vector2.new(180, 180)
    pe.Rotation = NumberRange.new(0, 360)
    pe.RotSpeed = NumberRange.new(-20, 20)
    pe.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    local sz = S.WorldSnowSize or 0.25
    pe.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.1, sz),
        NumberSequenceKeypoint.new(1, sz),
    })
    pe.Transparency = NumberSequence.new(0.2)
    pe.LightEmission = 0.4
    pe.LightInfluence = 0
    pe.Acceleration = Vector3.new(0, -ss, 0)
    pe.EmissionDirection = Enum.NormalId.Bottom
    pe.Parent = att

    cache.snowF = folder
    cache.snowPE = pe
    cache.snowC = NS.safeRender(function()
        local cam = NS.Cam.cur or Workspace.CurrentCamera
        if cam then
            e.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, 60, 0))
        end
    end)
end

local function stopSnow()
    if cache.snowC then cache.snowC:Disconnect(); cache.snowC = nil end
    if cache.snowF then cache.snowF:Destroy(); cache.snowF = nil end
    cache.snowPE = nil
end

-- ================== thunder ==================
local function startThunder()
    if cache.thunder then return end
    local S = NS.Settings
    cache.thunder = true
    Lighting.ClockTime = 22
    Lighting.Brightness = 1
    local atm = getAtm()
    atm.Density = 0.5
    atm.Color   = Color3.fromRGB(40, 40, 55)
    atm.Decay   = Color3.fromRGB(20, 20, 35)
    atm.Haze    = 3

    cache.thunderTask = task.spawn(function()
        while cache.thunder do
            local mn = S.WorldThunderMin or 3
            local mx = S.WorldThunderMax or 8
            if mx < mn then mx = mn end
            task.wait(math.random() * (mx - mn) + mn)
            if not cache.thunder then break end
            local br = S.WorldThunderBright or 60
            Lighting.Brightness = br / 10
            task.wait(0.05)
            if not cache.thunder then break end
            Lighting.Brightness = 1
            task.wait(0.08)
            if not cache.thunder then break end
            Lighting.Brightness = (br * 0.8) / 10
            task.wait(0.04)
            Lighting.Brightness = 1
        end
    end)
end

local function stopThunder()
    if not cache.thunder then return end
    cache.thunder = false
    restoreLighting()
    restoreAtm()
end

-- ================== post-fx ==================
local function applyVignette(on)
    local S = NS.Settings
    if on and (not cache.vig or not cache.vig.Parent) then
        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "cfgkotik_vignette"
        cc.Contrast = S.WorldVignetteStrength or 0.15
        cc.Saturation = -(S.WorldVignetteStrength or 0.15)
        cc.Brightness = -0.08
        cc.TintColor = Color3.fromRGB(200, 190, 220)
        cc.Parent = Lighting
        cache.vig = cc
    elseif on and cache.vig then
        cache.vig.Contrast = S.WorldVignetteStrength or 0.15
        cache.vig.Saturation = -(S.WorldVignetteStrength or 0.15)
    elseif not on and cache.vig then
        cache.vig:Destroy()
        cache.vig = nil
    end
end

local function applyColorShift(on)
    local S = NS.Settings
    if on and (not cache.shift or not cache.shift.Parent) then
        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "cfgkotik_colorshift"
        cc.TintColor = S.WorldColorShiftColor
        cc.Saturation = 0.2
        cc.Parent = Lighting
        cache.shift = cc
    elseif on and cache.shift then
        cache.shift.TintColor = S.WorldColorShiftColor
    elseif not on and cache.shift then
        cache.shift:Destroy()
        cache.shift = nil
    end
end

local function applyBlur(on)
    local S = NS.Settings
    if on and (not cache.blur or not cache.blur.Parent) then
        local b = Instance.new("BlurEffect")
        b.Name = "cfgkotik_blur"
        b.Size = S.WorldBlurSize or 4
        b.Parent = Lighting
        cache.blur = b
    elseif on and cache.blur then
        cache.blur.Size = S.WorldBlurSize or 4
    elseif not on and cache.blur then
        cache.blur:Destroy()
        cache.blur = nil
    end
end

-- ================== main loop ==================
NS.safeHeartbeat(function()
    local S = NS.Settings

    if S.WorldFog ~= last.fog
       or S.WorldFogDensity ~= last.fogD
       or S.WorldFogHaze ~= last.fogH then
        applyFog(S.WorldFog)
        last.fog = S.WorldFog
        last.fogD = S.WorldFogDensity
        last.fogH = S.WorldFogHaze
    end

    if S.WorldVignette ~= last.vig
       or S.WorldVignetteStrength ~= last.vigS then
        applyVignette(S.WorldVignette)
        last.vig = S.WorldVignette
        last.vigS = S.WorldVignetteStrength
    end

    if S.WorldColorShift ~= last.shift
       or S.WorldColorShiftColor ~= last.shiftC then
        applyColorShift(S.WorldColorShift)
        last.shift = S.WorldColorShift
        last.shiftC = S.WorldColorShiftColor
    end

    if S.WorldBlur ~= last.blur
       or S.WorldBlurSize ~= last.blurS then
        applyBlur(S.WorldBlur)
        last.blur = S.WorldBlur
        last.blurS = S.WorldBlurSize
    end

    if S.WorldRain ~= last.rain then
        if S.WorldRain then startRain() else stopRain() end
        last.rain = S.WorldRain
    end

    if S.WorldSnow ~= last.snow then
        if S.WorldSnow then startSnow() else stopSnow() end
        last.snow = S.WorldSnow
    end

    if S.WorldThunder ~= last.thunder then
        if S.WorldThunder then startThunder() else stopThunder() end
        last.thunder = S.WorldThunder
    end

    if S.ThirdPerson ~= last.third
       or S.ThirdPersonDistance ~= last.thirdD then
        applyThirdPerson(S.ThirdPerson)
        last.third = S.ThirdPerson
        last.thirdD = S.ThirdPersonDistance
    end

    if S.CameraFov ~= last.camFov
       or S.CameraFovAmount ~= last.camFovA then
        applyCameraFov(S.CameraFov)
        last.camFov = S.CameraFov
        last.camFovA = S.CameraFovAmount
    end
end)

return NS
