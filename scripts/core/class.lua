-- scripts/core/class.lua
local function class(base)
local c = {}
if type(base) == 'table' then
    for k,v in pairs(base) do c[k] = v end
        c._base = base
        end
        c.__index = c
        function c:new(...)
        local obj = {}
        setmetatable(obj, c)
        if obj.init then obj:init(...) end
            return obj
            end
            return c
            end
            return class
