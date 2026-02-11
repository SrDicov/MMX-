-- scripts/core/util.lua
-- CORRECCIÓN: Usamos _G.util para extender el módulo C++ existente
-- en lugar de sobrescribirlo con una tabla vacía.
local util = _G.util or {}

-- ============================================================================
-- 1. CONTROL DE FLUJO (CORRUTINAS)
-- ============================================================================

-- Pausa la ejecución de la entidad actual por 'frames'
function util.wait(frames)
local f = frames or 1
while(f > 0) do
    coroutine.yield()
    f = f - 1
    end
    end

    -- ============================================================================
    -- 2. MATEMÁTICAS Y FÍSICA (MATH HELPERS)
    -- ============================================================================

    function util.clamp(val, min, max)
    return math.max(min, math.min(max, val))
    end

    function util.lerp(a, b, t)
    return a + (b - a) * util.clamp(t, 0, 1)
    end

    function util.sign(x)
    return (x > 0 and 1) or (x < 0 and -1) or 0
    end

    function util.distance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
    end

    function util.aabb(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
    x1 + w1 > x2 and
    y1 < y2 + h2 and
    y1 + h1 > y2
    end

    function util.point_in_rect(px, py, rx, ry, rw, rh)
    return px >= rx and px <= rx + rw and
    py >= ry and py <= ry + rh
    end

    -- ============================================================================
    -- 3. GESTIÓN DE DATOS
    -- ============================================================================

    function util.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if(orig_type == 'table') then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[util.deepcopy(orig_key)] = util.deepcopy(orig_value)
            end
            setmetatable(copy, util.deepcopy(getmetatable(orig)))
            else
                copy = orig
                end
                return copy
                end

                -- ============================================================================
                -- 4. SISTEMA DE MÓDULOS (SANDBOX WRAPPERS)
                -- ============================================================================

                function util.load_module(filename)
                local env, chunk, err = sandbox.loadfile(filename)
                if(err) then
                    console.error("util.load_module failed: " .. filename, err)
                    return nil
                    end
                    rawset(env, "__chunk", chunk)
                    return env
                    end

                    function util.init_module(env)
                    if(env and env.__chunk) then
                        local status, err = pcall(env.__chunk)
                        if(not status) then
                            console.error("util.init_module runtime error", err)
                            end
                            env.__chunk = nil
                            end

                            if(env._init) then
                                env._init()
                                end

                                return env
                                end

                                return util
