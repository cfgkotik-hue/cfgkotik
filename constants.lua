 -- THEMES, RIG_PARTS, HEUR_*, BindList, etc
  local Constants = {
      THEMES = {
          Default = { MenuAccent = Color3.fromRGB(0,170,255), -- etc },
          Cyber = { -- etc },
          -- etc (5 themes)
      },
      RIG_PARTS = { "Head", "Torso", -- etc },
      RIG_GROUP = { Head="Head", -- etc },
      HEUR_HEAD = { "head", "skull", "neck" },
      HEUR_TORSO = { "torso", "chest", -- etc },
      HEUR_LIMB = { "arm", "hand", -- etc },
      BAD_NAME_PATTERNS = { "^handle$", "^grip$", -- etc },
      MOUSE_LABELS = { MouseButton1="ЛКМ", -- etc },
      BLACKLISTED_KEYS = {
          [Enum.KeyCode.Unknown]=true,
          [Enum.KeyCode.Tab]=true,
          -- etc
      },
      ATTACK_HINTS = {"slash","swing","attack","stab","punch","hit","combo","strike","smash"},
      BindList = {
          { id="AimKey", label="Aim Key", icon="🎯", short="A" },
          { id="FovExpand", label="FOV Expand", icon="🔭", short="F" },
          -- etc (7 binds)
      },
  }

  return Constants