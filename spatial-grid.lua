--!nocheck
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

NS.SpatialGrid = (function()
    local M = {}
    local CELL = 100
    local grid, dirty = {}, {}

    local function key(x,y,z) return x..":"..y..":"..z end
    local function ck(p)
        return math.floor(p.X/CELL), math.floor(p.Y/CELL), math.floor(p.Z/CELL)
    end

    function M.clear() grid = {}; dirty = {} end

    function M.insert(e)
        if not e or not e.root or not e.root.Parent then return end
        local x, y, z = ck(e.root.Position)
        local k = key(x,y,z)
        grid[k] = grid[k] or {}
        grid[k][#grid[k]+1] = e
        dirty[k] = true
    end

    function M.query(center, radius)
        local out = {}
        local cx, cy, cz = ck(center)
        local r = math.ceil(radius / CELL)
        for dx = -r, r do
            for dy = -r, r do
                for dz = -r, r do
                    local cell = grid[key(cx+dx, cy+dy, cz+dz)]
                    if cell then
                        for i = 1, #cell do
                            local e = cell[i]
                            if e.root and e.root.Parent then
                                if (e.root.Position - center).Magnitude <= radius then
                                    out[#out+1] = e
                                end
                            end
                        end
                    end
                end
            end
        end
        return out
    end

    return M
end)()

return NS
