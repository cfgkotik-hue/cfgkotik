--!nocheck
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

NS.Visibility = (function()
    local M = {}
    function M.get(entity, part)
        local cam = NS.Cam.cur or NS.Workspace.CurrentCamera
        if not cam then return false end
        local t = part or (entity.char and (entity.char:FindFirstChild("Head") or entity.root))
        if not t then return false end
        local cp = cam.CFrame.Position
        local f = {}
        if entity.char then f[#f+1] = entity.char end
        if NS.LP.Character then f[#f+1] = NS.LP.Character end
        local ok, obs = pcall(function()
            return cam:GetPartsObscuringTarget({cp, t.Position}, f)
        end)
        if ok and obs then return #obs == 0 end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = f
        return NS.raycast(NS.Workspace, cp, t.Position - cp, params) == nil
    end
    task.spawn(function()
        while true do
            local S = NS.Settings
            task.wait(S and S.ScanVisibilityInterval or 0.15)
            local ents = NS.Scanner.getEntities()
            if S and not S.ESPVisibilityCheck then
                for _, e in ipairs(ents) do e.visible = true end
            else
                local now = os.clock()
                for _, e in ipairs(ents) do
                    if now - e.lastVisibleCheck > (S and S.ScanVisibilityInterval or 0.15) then
                        local t = e.char:FindFirstChild("Head") or e.root
                        e.visible = M.get(e, t)
                        e.lastVisibleCheck = now
                    end
                end
            end
        end
    end)
    return M
end)()

return NS
