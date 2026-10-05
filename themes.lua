 -- Theme system + apply
  local THEMES = {
      Default = { MenuAccent = Color3.fromRGB(0,170,255), -- etc },
      Cyber = { -- etc },
      -- etc
  }
  local SAVED_THEMES = {}

  local function applyTheme(themeName)
      -- full theme logic
  end

  return {
      THEMES = THEMES,
      SAVED_THEMES = SAVED_THEMES,
      applyTheme = applyTheme,
  }