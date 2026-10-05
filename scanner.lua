 -- UniversalScanner + ModelDetector
  local Players = game:GetService("Players")
  local Workspace = game:GetService("Workspace")
  local LP = Players.LocalPlayer

  local Helpers = require("utils/helpers") -- or pass via args
  local Settings = getgenv().Settings

  local ModelDetector = (function()
      -- full ModelDetector logic (geometricAnalysis, attachmentScan, jointScan, volumeAnalysis, classify)
  end)()

  local UniversalScanner = (function()
      -- full scanner logic (enumerateModels, buildEntry, heavyScan, tick, invalidate, getEntities, count, findEntity)
  end)()

  return {
      Scanner = UniversalScanner,
      Detector = ModelDetector,
  }