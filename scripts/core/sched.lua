local sched = {}
local util = require("scripts.core.util")

-- ============================================================================
-- ESTADO INTERNO
-- ============================================================================
sched.tasks = {}        -- Lista de procesos activos (para iterar)
sched.task_map = {}     -- Mapa PID -> Proceso (para búsqueda rápida)
sched.new_tasks = {}    -- Buffer de procesos creados durante un frame

local next_pid = 1

-- ============================================================================
-- GESTIÓN DE PROCESOS
-- ============================================================================

-- sched.spawn(class_or_func, args)
-- Crea un nuevo proceso/entidad y lo pone en cola.
-- @param proto: Puede ser una Clase (tabla con :update) o una Función.
-- @param args: Argumentos pasados al constructor (:new) o a la función.
-- @return: pid (number), entity (table/nil)
function sched.spawn(proto, args)
local entity = nil
local co = nil
local name = "unknown"

-- CASO 1: Prototipo es una Tabla (Objeto/Clase)
if(type(proto) == "table") then
    -- Instanciar
    if(proto.new) then
        entity = proto.new(args)
        else
            entity = util.deepcopy(proto) -- Fallback si no hay new
            end

            name = entity.name or "obj"

            -- Crear Corrutina: Bucle infinito llamando a update()
            co = coroutine.create(function()
            -- Inicialización opcional
            if(entity._init) then entity:_init() end

                -- Ciclo de vida
                while(true) do
                    if(entity.update) then entity:update() end
                        coroutine.yield() -- Esperar al siguiente frame
                        end
                        end)

            -- CASO 2: Prototipo es una Función (Script simple)
            elseif(type(proto) == "function") then
                name = "func"
                -- La función ES el cuerpo de la corrutina
                co = coroutine.create(function()
                proto(args)
                -- Si la función termina, el proceso muere.
                -- Para mantenerlo vivo, la función debe tener su propio while(true)
                end)
                else
                    console.error("sched.spawn: Invalid prototype type " .. type(proto))
                    return -1, nil
                    end

                    -- Crear descriptor de proceso (PCB)
                    local pid = next_pid
                    next_pid = next_pid + 1

                    local task = {
                        pid = pid,
                        co = co,
                        entity = entity,
                        active = true,
                        name = name,
                        layer = (entity and entity.layer) or 0 -- Orden de dibujado
                    }

                    -- Encolar para el siguiente ciclo (evita modificar lista mientras iteramos)
                    table.insert(sched.new_tasks, task)

                    -- Mapear inmediatamente para que sea accesible
                    sched.task_map[pid] = task

                    return pid, entity
                    end

                    -- sched.kill(pid)
                    -- Marca un proceso para ser eliminado.
                    function sched.kill(pid)
                    local task = sched.task_map[pid]
                    if(task) then
                        task.active = false
                        if(task.entity and task.entity.on_destroy) then
                            task.entity:on_destroy()
                            end
                            end
                            end

                            -- sched.get_entity(pid)
                            -- Recupera la entidad asociada a un PID.
                            function sched.get_entity(pid)
                            local task = sched.task_map[pid]
                            return (task and task.entity) or nil
                            end

                            -- ============================================================================
                            -- BUCLE PRINCIPAL (SYSTEM LOOP)
                            -- ============================================================================

                            -- sched.update(dt)
                            -- Avanza la lógica de todos los procesos activos.
                            function sched.update(dt)
                            -- 1. Inyectar nuevos procesos al pool principal
                            if(#sched.new_tasks > 0) then
                                for i, task in ipairs(sched.new_tasks) do
                                    table.insert(sched.tasks, task)
                                    end
                                    sched.new_tasks = {}

                                    -- Reordenar por capa (Z-Index) para el dibujado correcto
                                    -- (Optimizacion: Hacer esto solo si hay cambios de layer, pero por ahora en spawn)
                                    table.sort(sched.tasks, function(a, b) return a.layer < b.layer end)
                                    end

                                    -- 2. Ejecutar procesos
                                    local alive_count = 0
                                    local i = 1

                                    while(i <= #sched.tasks) do
                                        local task = sched.tasks[i]

                                        if(task.active and coroutine.status(task.co) ~= "dead") then
                                            -- Inyectar 'dt' globales o locales si es necesario
                                            -- (Por diseño MMX++ usa fixed timestep lógico, pero pasamos dt real por si acaso)

                                            local status, err = coroutine.resume(task.co, dt)

                                            if(not status) then
                                                -- Error en el script del objeto
                                                console.error("Runtime Error (PID " .. task.pid .. "): " .. tostring(err))
                                                -- Opcional: Matar proceso para no spammear error
                                                task.active = false
                                                end

                                                i = i + 1
                                                else
                                                    -- Limpieza de cadáveres (Garbage Collection del Scheduler)
                                                    sched.task_map[task.pid] = nil
                                                    table.remove(sched.tasks, i)
                                                    end
                                                    end
                                                    end

                                                    -- sched.draw()
                                                    -- Dibuja todos los procesos que tengan componente visual.
                                                    -- scripts/core/sched.lua

                                                    -- ... (código anterior)

                                                    function sched.draw()
                                                    -- Obtenemos cámara global
                                                    local cx = _G.camera_x or 0
                                                    local cy = _G.camera_y or 0

                                                    for _, task in ipairs(sched.tasks) do
                                                        if(task.active and task.entity and task.entity.draw) then
                                                            task.entity:draw(cx, cy)
                                                            end
                                                            end
                                                            end

                                                            -- sched.clear()
                                                            -- Elimina todos los procesos (ej: cambio de nivel)
                                                            function sched.clear()
                                                            sched.tasks = {}
                                                            sched.task_map = {}
                                                            sched.new_tasks = {}
                                                            -- Nota: No reseteamos next_pid para evitar colisiones con referencias viejas
                                                            end

                                                            return sched
