-- Quick presets (Legit/HvH/Ghost/Farm)
  local Settings = getgenv().Settings

  local Profiles = (function()
      local M = {}
      local function apply(preset) -- logic end
      M.Legit = function() -- logic end
      M.HvH = function() -- logic end
      M.Ghost = function() -- logic end
      M.Farm = function() -- logic end
      return M
  end)()

  return Profiles