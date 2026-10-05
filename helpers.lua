
  -- Rig helpers + partGroup + enum utils
  local RIG_PARTS = { "Head", "Torso", -- etc }
  local RIG_GROUP = { Head="Head", -- etc }
  local HEUR_HEAD = { "head", "skull", "neck" }
  -- etc

  local function classifyName(name) -- logic end
  local function partGroup(name) -- logic end
  local function isBadPart(p) -- logic end
  local function matchesIgnorePattern(model) -- logic end
  local function rigScore(model) -- logic end
  local function looksLikeRig(model) -- logic end
  local function collectRigParts(model, filter) -- logic end
  local function isAlive(e) -- logic end

  return {
      RIG_PARTS = RIG_PARTS,
      RIG_GROUP = RIG_GROUP,
      classifyName = classifyName,
      partGroup = partGroup,
      isBadPart = isBadPart,
      matchesIgnorePattern = matchesIgnorePattern,
      rigScore = rigScore,
      looksLikeRig = looksLikeRig,
      collectRigParts = collectRigParts,
      isAlive = isAlive,
  }