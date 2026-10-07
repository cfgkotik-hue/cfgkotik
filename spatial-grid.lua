--!nocheck
-- cfgkotik v37 — Spatial Grid (100-stud cells for fast proximity queries)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

NS.SpatialGrid = (function()
    local M = {}
    local CELL_SIZE = 100
    local grid = {}
    local cellDirty = {}

    -- ================== helpers ==================
    local function key(x, y, z) return x .. ":" .. y .. ":" .. z end

    local function cellKey(pos)
        return math.floor(pos.X / CELL_SIZE),
               math.floor(pos.Y / CELL_SIZE),
               math.floor(pos.Z / CELL_SIZE)
    end

    -- ================== clear ==================
    function M.clear()
        grid = {}
        cellDirty = {}
    end

    -- ================== insert ==================
    function M.insert(entity)
        if not entity or not entity.root or not entity.root.Parent then return end
        local x, y, z = cellKey(entity.root.Position)
        local k = key(x, y, z)
        grid[k] = grid[k] or {}
        grid[k][#grid[k] + 1] = entity
        cellDirty[k] = true
    end

    -- ================== query ==================
    function M.query(center, radius)
        local out = {}
        if not center then return out end
        local cx, cy, cz = cellKey(center)
        local range = math.ceil(radius / CELL_SIZE)

        for dx = -range, range do
            for dy = -range, range do
                for dz = -range, range do
                    local cell = grid[key(cx + dx, cy + dy, cz + dz)]
                    if cell then
                        for i = 1, #cell do
                            local e = cell[i]
                            if e.root and e.root.Parent then
                                if (e.root.Position - center).Magnitude <= radius then
                                    out[#out + 1] = e
                                end
                            end
                        end
                    end
                end
            end
        end
        return out
    end

    -- ================== cleanup dead ==================
    function M.cleanup()
        for k in pairs(cellDirty) do
            local cell = grid[k]
            if cell then
                for i = #cell, 1, -1 do
                    local e = cell[i]
                    if not e.model or not e.model.Parent then
                        table.remove(cell, i)
                    end
                end
            end
            cellDirty[k] = nil
        end
    end

    -- ================== stats ==================
    function M.size()
        local n = 0
        for _ in pairs(grid) do n = n + 1 end
        return n
    end

    function M.count()
        local n = 0
        for _, cell in pairs(grid) do
            n = n + #cell
        end
        return n
    end

    function M.cellSize() return CELL_SIZE end

    return M
end)()

return NS
