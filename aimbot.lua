 -- Aimbot + prediction + sticky + FOV expand
  local UIS = game:GetService("UserInputService")
  local TweenService = game:GetService("TweenService")
  local Settings = getgenv().Settings

  local Aimbot = (function()
      local M = {}
      local st = { target=nil, targetPart=nil, lastSeen=0, -- etc }
      -- full aimbot logic (scan, shouldAim, predict, smooth, apply, start, getTargetName, hasTarget, getTargetPart,
  addWhitelist, addBlacklist, clearLists)
      return M
  end)()

  return Aimbot