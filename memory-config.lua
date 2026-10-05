 -- In-memory config save/load (per UserId)
  local LP = game:GetService("Players").LocalPlayer
  local Settings = getgenv().Settings

  local MemoryConfigs = (function()
      local M = {}
      local store, named = {}, {}
      -- full memory config logic (uid, deepCopy, deepMerge, save, load, list, remove, available, userId)
      return M
  end)()

  return MemoryConfigs