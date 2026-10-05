-- ESP rendering + cache
  local Drawing = Drawing or {}
  local Settings = getgenv().Settings

  local ESPCache = (function()
      -- cache logic
  end)()

  local ESP = (function()
      local M = {}
      local pool = setmetatable({}, { __mode = "k" })
      -- full ESP logic (new, hide, ensureHighlight, drawCornerBox, render, start)
      return M
  end)()

  return ESP
