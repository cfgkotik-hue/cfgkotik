  -- Weather/Fog/Thunder/Cam FX
  local Lighting = game:GetService("Lighting")
  local Settings = getgenv().Settings

  local World = (function()
      local cache = { rainFolder=nil, snowFolder=nil, thunder=false, -- etc }
      -- full world logic (applyFog, applyThirdPerson, applyCameraFov, startRain, stopRain, startSnow, stopSnow,
  startThunder, stopThunder, applyVignette, applyColorShift, applyBlur)
  end)()

  return World