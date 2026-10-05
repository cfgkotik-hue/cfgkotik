 -- VisibilityCache + batch visibility checks
  local Cam = { cur = workspace.CurrentCamera }
  workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
      if workspace.CurrentCamera then Cam.cur = workspace.CurrentCamera end
  end)

  local VisibilityCache = (function()
      local M = {}
      -- full visibility logic (get, start with batch loop)
      return M
  end)()

  return VisibilityCache