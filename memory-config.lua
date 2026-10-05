--!nocheck
-- cfgkotik v37 — Memory Configs (per-UserId in-memory profiles)
local NS = getgenv().CFGKOTIK
if not NS then NS = {}; getgenv().CFGKOTIK = NS end

NS.MemoryConfigs = (function()
    local M = {}

    -- store[userId][configName] = settings copy
    -- named[userId] = { list of config names in insertion order }
    local store = {}
    local named = {}

    -- ================== user id ==================
    local function uid()
        local ok, id = pcall(function() return NS.LP.UserId end)
        return (ok and id) and tostring(id) or "0"
    end

    -- ================== deep copy ==================
    local function deepCopy(t, seen)
        if type(t) ~= "table" then return t end
        seen = seen or {}
        if seen[t] then return seen[t] end
        local out = {}
        seen[t] = out
        for k, v in pairs(t) do
            if type(v) == "table" then
                out[k] = deepCopy(v, seen)
            else
                out[k] = v
            end
        end
        return out
    end

    -- ================== deep merge ==================
    local function deepMerge(dst, src)
        for k, v in pairs(src) do
            if type(v) == "table" and type(dst[k]) == "table" then
                deepMerge(dst[k], v)
            else
                dst[k] = v
            end
        end
    end

    -- ================== sanitize (skip runtime-only) ==================
    local SKIP_KEYS = {
        _UseLegacyScan = true,
        TargetHistory = true,
    }

    local function snapshot()
        local out = {}
        for k, v in pairs(NS.Settings) do
            if not SKIP_KEYS[k] then
                out[k] = v
            end
        end
        return deepCopy(out)
    end

    -- ================== public API ==================
    function M.save(name)
        name = name or NS.Settings.CurrentConfig or "default"
        local u = uid()
        store[u] = store[u] or {}
        named[u] = named[u] or {}

        store[u][name] = snapshot()

        local exists = false
        for _, n in ipairs(named[u]) do
            if n == name then exists = true; break end
        end
        if not exists then
            named[u][#named[u]+1] = name
        end

        NS.Settings.CurrentConfig = name
        return true, "saved (memory)"
    end

    function M.load(name)
        name = name or NS.Settings.CurrentConfig or "default"
        local u = uid()
        if not store[u] or not store[u][name] then
            return false, "not found"
        end
        deepMerge(NS.Settings, store[u][name])
        NS.Settings.CurrentConfig = name
        return true, "loaded"
    end

    function M.remove(name)
        name = name or NS.Settings.CurrentConfig or "default"
        local u = uid()
        if not store[u] or not store[u][name] then
            return false, "not found"
        end
        store[u][name] = nil
        if named[u] then
            for i, n in ipairs(named[u]) do
                if n == name then
                    table.remove(named[u], i)
                    break
                end
            end
        end
        return true, "removed"
    end

    function M.list()
        return named[uid()] or {}
    end

    function M.exists(name)
        local u = uid()
        return store[u] and store[u][name] ~= nil
    end

    function M.clear()
        local u = uid()
        store[u] = {}
        named[u] = {}
        return true, "cleared"
    end

    function M.count()
        local u = uid()
        return #(named[u] or {})
    end

    function M.userId()
        return uid()
    end

    function M.available()
        return true
    end

    return M
end)()

return NS
