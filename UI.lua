-- Main menu window + 6 folder tabs
  local UI = require("ui/framework") -- or pass via args
  local Settings = getgenv().Settings

  local Menu = {}

  function Menu.build()
      local win = UI.createWindow()
      -- Build all 6 tabs: Aim, Visual, World, Auto Mix, Configs, System
      -- (exact same tab structure as original)
      return win
  end

  return Menu
