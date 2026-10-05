 -- Rejoin/TeleportToMouse/etc
  local TeleportSvc = game:GetService("TeleportService")
  local LP = game:GetService("Players").LocalPlayer

  local Misc = (function()
      local M = {}
      function M.rejoin() -- logic end
      function M.teleportToMouse() -- logic end
      return M
  end)()

  return Misc