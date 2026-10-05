1. main.lua (Entry Point)

  -- cfgkotik v37 FINAL — Main Loader
  -- loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/cfgkotik/main/main.lua"))()

  local BASE = "https://raw.githubusercontent.com/USER/cfgkotik/main/"

  local function load(path)
      local ok, result = pcall(function()
          return loadstring(game:HttpGet(BASE .. path))()
      end)
      if not ok then warn("[cfgkotik] Failed to load: " .. path) end
      return result
  end

  -- Load order: data → utils → core → features → UI → boot
  local Constants = load("data/constants.lua")
  local Helpers = load("utils/helpers.lua")
  local MemoryConfig = load("utils/memory-config.lua")
  local Themes = load("utils/themes.lua")
  local Profiles = load("utils/profiles.lua")
  local Misc = load("utils/misc.lua")

  local Settings = load("core/settings.lua")
  local Hooks = load("core/hooks.lua")
  local Scanner = load("core/scanner.lua")
  local SpatialGrid = load("core/spatial-grid.lua")
  local Visibility = load("core/visibility.lua")

  local Aimbot = load("features/aimbot.lua")
  local ESP = load("features/esp.lua")
  local Radar = load("features/radar.lua")
  local Movement = load("features/movement.lua")
  local Hitbox = load("features/hitbox.lua")
  local AutoParry = load("features/autoparry.lua")
  local AutoLoot = load("features/autoloot.lua")
  local AntiAFK = load("features/antiafk.lua")
  local World = load("features/world.lua")

  local UI = load("ui/framework.lua")
  local Menu = load("ui/menu.lua")
  local HUD = load("ui/hud.lua")
  local BindStrip = load("ui/bindstrip.lua")
  local ColorPicker = load("ui/colorpicker.lua")
  local BindEditor = load("ui/bindeditor.lua")

  -- Boot
  Aimbot.start()
  ESP.start()
  Radar.start()
  Visibility.start()
  AutoParry.start()
  AutoLoot.start()
  AntiAFK.start()
  HUD.start()
  BindStrip.start()
  Menu.build()
  UI.notify("cfgkotik v37 FINAL loaded", "success")