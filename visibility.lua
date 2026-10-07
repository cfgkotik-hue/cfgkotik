--!nocheck
-- cfgkotik v37 — Visibility (occlusion check + batched runner)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

NS.Visibility = (function()
    local M = {}

    -- ================== check ==================
    function M.get(entity, part)
        local cam = NS.Cam.cur or NS.Workspace.CurrentCamera
        if not cam then return false end

        local target = part
            or (entity.char and (entity.char:FindFirstChild("Head") or entity.root))
        if not target then return false end

        local camPos = cam.CFrame.Position
        local filter = {}
        if entity and entity.char then filter[#filter + 1] = entity.char end
        if NS.LP.Character then filter[#filter + 1] = NS.LP.Character end

        -- primary: GetPartsObscuringTarget
        local ok, obscuring = pcall(function()
            return cam:GetPartsObscuringTarget({camPos, target.Position}, filter)
        end)
        if ok and obscuring then
            return #obscuring == 0
        end

        -- fallback: raycast
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = filter
        local hit = NS.raycast(NS.Workspace, camPos, target.Position - camPos, params)
        return hit == nil
    end

    -- ================== runner ==================
    local function run()
        while true do
            local S = NS.Settings
            task.wait(S.ScanVisibilityInterval or 0.15)

            if not NS.Scanner then break end
            local ents = NS.Scanner.getEntities()

            if not S.ESPVisibilityCheck then
                for _, e in ipairs(ents) do e.visible = true end
            else
                local now = os.clock()
                local interval = S.ScanVisibilityInterval or 0.15

                if S.PerfBatchVis then
                    -- quadrant batching: group by 200-stud cells
                    local batch = {}
                    for _, e in ipairs(ents) do
                        local qx = math.floor(e.root.Position.X / 200)
                        local qz = math.floor(e.root.Position.Z / 200)
                        local k = qx .. ":" .. qz
                        batch[k] = batch[k] or {}
                        batch[k][#batch[k] + 1] = e
                    end
                    for _, group in pairs(batch) do
                        for _, e in ipairs(group) do
                            if now - e.lastVisibleCheck > interval then
                                local target = e.char:FindFirstChild("Head") or e.root
                                e.visible = M.get(e, target)
                                e.lastVisibleCheck = now
                            end
                        end
                    end
                else
                    for _, e in ipairs(ents) do
                        if now - e.lastVisibleCheck > interval then
                            local target = e.char:FindFirstChild("Head") or e.root
                            e.visible = M.get(e, target)
                            e.lastVisibleCheck = now
                        end
                    end
                end
            end
        end
    end

    function M.start()
        task.spawn(run)
    end

    return M
end)()

return NS
