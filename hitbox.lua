--!nocheck
-- cfgkotik v37 — Hitbox Expander (per-player BasePart size multiplier)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

do
    local orig = {}          -- orig[part] = { size = Vector3 }
    local lastSize = nil     -- last applied HitboxSize (for change detection)

    -- ================== should expand ==================
    local function shouldExpand(name)
        local sel = NS.Settings.HitboxPartList or {}
        local grp = NS.partGroup(name)
        return grp and sel[grp] == true
    end

    -- ================== revert single ==================
    local function revert(part)
        local o = orig[part]
        if not o then return end
        pcall(function() part.Size = o.size end)
        orig[part] = nil
    end

    -- ================== revert all ==================
    local function revertAll()
        for p in pairs(orig) do
            revert(p)
        end
        lastSize = nil
    end

    -- ================== apply to all players ==================
    local function applyAll()
        local S = NS.Settings
        local mult = S.HitboxSize or 5
        local sizeChanged = (lastSize ~= mult)

        for _, plr in ipairs(NS.Players:GetPlayers()) do
            if plr ~= NS.LP and plr.Character then
                for _, p in ipairs(plr.Character:GetDescendants()) do
                    if p:IsA("BasePart")
                       and shouldExpand(p.Name)
                       and not NS.isBadPart(p) then

                        if sizeChanged and orig[p] then
                            p.Size = orig[p].size * mult
                        elseif not orig[p] then
                            orig[p] = { size = p.Size }
                            p.Size = orig[p].size * mult
                        end
                    end
                end
            end
        end

        -- clean up orphaned / no-longer-selected parts
        for p in pairs(orig) do
            if not p.Parent or not shouldExpand(p.Name) then
                revert(p)
            end
        end

        lastSize = mult
    end

    -- ================== main loop ==================
    task.spawn(function()
        while task.wait(0.15) do
            local on = NS.Settings.HitboxExpand or NS.isBindActive("Hitbox")
            if on then
                applyAll()
            elseif next(orig) ~= nil then
                revertAll()
            end
        end
    end)
end

return NS
