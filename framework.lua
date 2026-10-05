 -- UI builder (section/toggle/slider/dropdown/etc)
  local UI = (function()
      local M = {}
      M.elements = {}
      M.listening = false
      M.C = { bg=Color3.fromRGB(14,14,18), -- etc }
      -- full UI framework (corner, stroke, createWindow, section, toggle, slider, dropdown, multiSelect, keybind,
  colorPalette, info, button, input, notify, refresh, openColorPicker)
      return M
  end)()

  return UI