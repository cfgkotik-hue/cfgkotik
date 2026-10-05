
  -- Hook protection + safe wrappers
  local RunService = game:GetService("RunService")
  local Workspace = game:GetService("Workspace")

  local _BindToRenderStep = RunService.BindToRenderStep
  local _HeartbeatSignal = RunService.Heartbeat
  local _RenderSignal = RunService.RenderStepped
  local _WorkspaceRaycast = Workspace.Raycast

  local function safeBind(name, prio, fn)
      return _BindToRenderStep(RunService, name, prio, fn)
  end
  local function safeHeartbeat(fn)
      return _HeartbeatSignal:Connect(fn)
  end
  local function safeRender(fn)
      return _RenderSignal:Connect(fn)
  end

  local function protectGui(sg)
      local syn = rawget(_G, "syn")
      if syn and syn.protect_gui then pcall(syn.protect_gui, sg) end
      local pg = rawget(_G, "protect_gui")
      if pg then pcall(pg, sg) end
  end

  local function getParentGui()
      local gh = rawget(_G, "gethui")
      if gh then
          local ok, hui = pcall(gh)
          if ok and hui then return hui end
      end
      return game:GetService("CoreGui")
  end

  return {
      safeBind = safeBind,
      safeHeartbeat = safeHeartbeat,
      safeRender = safeRender,
      protectGui = protectGui,
      getParentGui = getParentGui,
      _WorkspaceRaycast = _WorkspaceRaycast,
  }