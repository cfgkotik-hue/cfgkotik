--!nocheck
-- cfgkotik v37 — Misc utilities (rejoin, teleport, character helpers)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

NS.Misc = NS.Misc or {}
local M = NS.Misc

-- ================== rejoin ==================
function M.rejoin()
    local TS = game:GetService("TeleportService")
    local ok = pcall(function()
        TS:Teleport(game.PlaceId, NS.LP)
    end)
    if ok then return true end
    ok = pcall(function()
        TS:TeleportToPlaceInstance(game.PlaceId, game.JobId, NS.LP)
    end)
    if not ok and NS.UI and NS.UI.notify then
        NS.UI.notify("Rejoin failed", "error")
    end
    return ok
end

-- ================== teleport to mouse ==================
function M.teleportToMouse()
    local mouse = NS.LP:GetMouse()
    if not mouse or not mouse.Hit then return false end
    local c = NS.LP.Character
    if not c then return false end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local pos = mouse.Hit.Position + Vector3.new(0, 3, 0)
    pcall(function()
        hrp.CFrame = CFrame.new(pos)
    end)
    return true
end

-- ================== teleport to position ==================
function M.teleportTo(pos)
    if not pos then return false end
    local c = NS.LP.Character
    if not c then return false end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    pcall(function()
        hrp.CFrame = CFrame.new(pos)
    end)
    return true
end

-- ================== character helpers ==================
function M.getChar()
    return NS.LP.Character
end

function M.getHumanoid()
    local c = NS.LP.Character
    if not c then return nil end
    return c:FindFirstChildOfClass("Humanoid")
end

function M.getRoot()
    local c = NS.LP.Character
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart")
end

function M.getPosition()
    local r = M.getRoot()
    return r and r.Position or nil
end

-- ================== server info ==================
function M.getServerInfo()
    return {
        placeId = game.PlaceId,
        jobId   = game.JobId,
        players = #NS.Players:GetPlayers(),
        maxPlayers = NS.Players.MaxPlayers,
    }
end

function M.copyServerInfo()
    local info = M.getServerInfo()
    local text = string.format("PlaceId: %d | JobId: %s | Players: %d/%d",
        info.placeId, info.jobId, info.players, info.maxPlayers)
    if setclipboard then
        pcall(function() setclipboard(text) end)
    end
    if NS.UI and NS.UI.notify then
        NS.UI.notify("Server info copied", "success")
    end
    return text
end

-- ================== get all entities names ==================
function M.listEntities()
    if not NS.Scanner then return {} end
    local out = {}
    for _, e in ipairs(NS.Scanner.getEntities()) do
        if e.isPlayer and e.player then
            out[#out+1] = e.player.Name
        elseif e.char then
            out[#out+1] = "[NPC] " .. e.char.Name
        end
    end
    return out
end

-- ================== distance helper ==================
function M.distanceBetween(a, b)
    if not a or not b then return nil end
    return (a - b).Magnitude
end

-- ================== humanoid state ==================
function M.getHumanoidState()
    local h = M.getHumanoid()
    if not h then return nil end
    local ok, state = pcall(function() return h:GetState() end)
    return ok and state or nil
end

-- ================== kick/respawn (self) ==================
function M.respawn()
    local h = M.getHumanoid()
    if not h then return end
    pcall(function()
        h.Health = 0
    end)
end

return NS
