
  -- Settings table + integrity check
  local Settings = {
      Aimbot=false, AimKey=Enum.KeyCode.E, FOV=120, -- etc (full table from original)
  }
  getgenv().Settings = Settings

  -- Integrity system (frozen hashes + violation counter)
  local frozen, lockedHashes, violations = {}, {}, 0
  local function hashTable(t) --[[ original hash logic ]] end
  local function seal() --[[ seal logic ]] end
  local function check() --[[ check logic ]] end

  seal()
  task.spawn(function()
      while task.wait(3) do pcall(check) end
  end)

  return Settings

 
