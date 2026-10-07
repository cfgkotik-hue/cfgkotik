--!nocheck
-- cfgkotik v37 — Hooks (services, bindings, GUI protection, ping)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local Stats      = game:GetService("Stats")

-- ================== SERVICE SHORTCUTS ==================
NS.Players    = Players
NS.Workspace  = Workspace
NS.RunService = RunService
NS.UIS        = UIS
NS.Stats      = Stats
NS.LP         = Players.LocalPlayer
NS.Cam        = { cur = Workspace.CurrentCamera }

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if Workspace.CurrentCamera then
        NS.Cam.cur = Workspace.CurrentCamera
    end
end)

-- ================== SAFE BINDINGS ==================
function NS.safeBind(name, prio, fn)
    return RunService:BindToRenderStep(name, prio, fn)
end

function NS.safeHeartbeat(fn)
    return RunService.Heartbeat:Connect(fn)
end

function NS.safeRender(fn)
    return RunService.RenderStepped:Connect(fn)
end

function NS.raycast(...)
    return Workspace:Raycast(...)
end

-- ================== GUI PROTECTION ==================
function NS.protectGui(sg)
    local syn = rawget(_G, "syn")
    if syn and syn.protect_gui then pcall(syn.protect_gui, sg) end
    local pg = rawget(_G, "protect_gui")
    if pg then pcall(pg, sg) end
end

function NS.getParentGui()
    local gh = rawget(_G, "gethui")
    if gh then
        local ok, hui = pcall(gh)
        if ok and hui then return hui end
    end
    return game:GetService("CoreGui")
end

-- ================== CLEANUP OLD UI ==================
do
    local parent = NS.getParentGui()
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("ScreenGui") and child.Name:match("^cfgkotik_") then
            pcall(function() child:Destroy() end)
        end
    end
    local Lighting = game:GetService("Lighting")
    for _, child in ipairs(Lighting:GetChildren()) do
        if child.Name:match("^cfgkotik_") then
            pcall(function() child:Destroy() end)
        end
    end
    for _, n in ipairs({"cfgkotik_rain","cfgkotik_snow"}) do
        if Workspace:FindFirstChild(n) then
            pcall(function() Workspace[n]:Destroy() end)
        end
    end
end

-- ================== PING ==================
local pingCache = { val = 0, at = 0 }
function NS.getPing()
    local now = os.clock()
    if now - pingCache.at > 0.5 then
        local ok, p = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        pingCache.val = (ok and p and p / 1000) or 0
        pingCache.at = now
    end
    return pingCache.val
end

-- ================== BIND FALLBACK ==================
-- Пока bindstrip.lua не загружен, isBindActive вернёт false.
-- После загрузки bindstrip перезапишет эту функцию рабочей версией.
if not NS.isBindActive then
    NS.isBindActive = function(_) return false end
end

return NS
