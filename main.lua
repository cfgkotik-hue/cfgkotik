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
  local constants = load("data/constants.lua")
  local helpers = load("utils/helpers.lua")
  local memoryConfig = load("utils/memory-config.lua")
  local themes = load("utils/themes.lua")
  local profiles = load("utils/profiles.lua")
  local misc = load("utils/misc.lua")

  local settings = load("core/settings.lua")
  local hooks = load("core/hooks.lua")
  local scanner = load("core/scanner.lua")
  local spatialGrid = load("core/spatial-grid.lua")
  local visibility = load("core/visibility.lua")

  local aimbot = load("features/aimbot.lua")
  local eSP = load("features/esp.lua")
  local radar = load("features/radar.lua")
  local movement = load("features/movement.lua")
  local hitbox = load("features/hitbox.lua")
  local autoParry = load("features/autoparry.lua")
  local autoLoot = load("features/autoloot.lua")
  local antiAFK = load("features/antiafk.lua")
  local world = load("features/world.lua")

  local UI = load("ui/framework.lua")
  local menu = load("ui/menu.lua")
  local hUD = load("ui/hud.lua")
  local bindStrip = load("ui/bindstrip.lua")
  local colorPicker = load("ui/colorpicker.lua")
  local bindEditor = load("ui/bindeditor.lua")

  -- Boot
  aimbot.start()
  esp.start()
  radar.start()
  visibility.start()
  autoParry.start()
  autoLoot.start()
  antiAFK.start()
  hud.start()
  bindStrip.start()
  menu.build()
  UI.notify("cfgkotik v37 FINAL loaded", "success")
