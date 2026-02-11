local physics = {}
local util = require("scripts.core.util")

-- ============================================================================
-- 1. SISTEMA DE CAPAS (COLLISION BITMASKS)
-- ============================================================================
-- Usamos potencias de 2 para combinar capas con OR bit a bit
physics.LAYER_NONE        = 0
physics.LAYER_WORLD       = 1  -- Paredes, Suelos, Techos
physics.LAYER_PLAYER      = 2  -- Hitbox del Jugador
physics.LAYER_ENEMY       = 4  -- Hitbox de Enemigos
physics.LAYER_PLAYER_SHOT = 8  -- Disparos de X
physics.LAYER_ENEMY_SHOT  = 16 -- Disparos enemigos
physics.LAYER_ITEM        = 32 -- Cápsulas de vida, tanques, etc.
physics.LAYER_TRIGGER     = 64 -- Puertas, zonas de muerte, eventos

-- ============================================================================
-- 2. CLASE BODY (CUERPO FÍSICO)
-- ============================================================================
local Body = {}
Body.__index = Body

-- Constructor
function physics.new_body(x, y, w, h)
local self = setmetatable({}, Body)

-- Posición y Dimensiones (AABB)
self.x = x or 0
self.y = y or 0
self.w = w or 16
self.h = h or 16

-- Acumuladores de Sub-píxeles (SNES Hardware Accuracy)
self.sub_x = 0
self.sub_y = 0

-- Velocidad (Píxeles por frame)
self.vx = 0
self.vy = 0

-- Configuración de Colisión
self.layer = physics.LAYER_NONE -- ¿Qué soy yo?
self.mask = physics.LAYER_NONE  -- ¿Contra qué choco?
self.is_sensor = false          -- Si es true, detecta pero no empuja (Trigger)

-- Flags de Estado (Read-only para lógica de juego)
self.on_floor = false
self.on_ceiling = false
self.on_wall_left = false
self.on_wall_right = false

return self
end

-- ============================================================================
-- 3. INTEGRACIÓN Y MOVIMIENTO (CORE PHYSICS)
-- ============================================================================

-- Calcula el desplazamiento entero basado en velocidad y sub-píxeles
-- Retorna: int_dx, int_dy (Lo que realmente se mueve en pantalla)
function Body:integrate_velocity()
-- EJE X
local int_vx = math.floor(self.vx)
local frac_vx = self.vx - int_vx

self.sub_x = self.sub_x + frac_vx

-- Manejo de desbordamiento de sub-píxel (Carry bit)
if(self.sub_x >= 1.0) then
    self.sub_x = self.sub_x - 1.0
    int_vx = int_vx + 1
    elseif(self.sub_x <= -1.0) then
        self.sub_x = self.sub_x + 1.0
        int_vx = int_vx - 1
        end

        -- EJE Y
        local int_vy = math.floor(self.vy)
        local frac_vy = self.vy - int_vy

        self.sub_y = self.sub_y + frac_vy

        if(self.sub_y >= 1.0) then
            self.sub_y = self.sub_y - 1.0
            int_vy = int_vy + 1
            elseif(self.sub_y <= -1.0) then
                self.sub_y = self.sub_y + 1.0
                int_vy = int_vy - 1
                end

                return int_vx, int_vy
                end

                -- Verifica colisión AABB contra otro cuerpo
                function Body:check_collision(other)
                -- Chequeo rápido de máscara
                -- (bit.band requiere LuaJIT o librería bit, simulamos lógica simple)
                -- Si (self.mask & other.layer) == 0, ignorar.
                -- Lua 5.1 no tiene operadores bitwise nativos, usaremos lógica booleana simplificada
                -- o asumimos que quien llama filtra la lista.

                return util.aabb(self.x, self.y, self.w, self.h,
                                 other.x, other.y, other.w, other.h)
                end

                -- Movimiento con Deslizamiento (Move and Slide)
                -- @param solids: Lista de cuerpos con los que colisionar (generalmente tiles del mundo)
                function Body:move_and_slide(solids)
                -- 1. Calcular cuánto queremos movernos
                local dx, dy = self:integrate_velocity()

                -- Reset flags
                self.on_floor = false
                self.on_ceiling = false
                self.on_wall_left = false
                self.on_wall_right = false

                -- 2. MOVER EJE X
                self.x = self.x + dx

                -- Resolución de colisiones X
                if(not self.is_sensor) then
                    for _, solid in ipairs(solids) do
                        if(self:check_collision(solid)) then
                            -- Determinar dirección de colisión
                            if(dx > 0) then -- Moviendo derecha
                                self.x = solid.x - self.w -- Pegar al borde izquierdo del obstáculo
                                self.on_wall_right = true
                                elseif(dx < 0) then -- Moviendo izquierda
                                    self.x = solid.x + solid.w -- Pegar al borde derecho del obstáculo
                                    self.on_wall_left = true
                                    end
                                    self.vx = 0 -- Detener velocidad X
                                    end
                                    end
                                    end

                                    -- 3. MOVER EJE Y
                                    self.y = self.y + dy

                                    -- Resolución de colisiones Y
                                    if(not self.is_sensor) then
                                        for _, solid in ipairs(solids) do
                                            if(self:check_collision(solid)) then
                                                if(dy > 0) then -- Cayendo (Suelo)
                                                    self.y = solid.y - self.h
                                                    self.on_floor = true
                                                    self.vy = 0
                                                    elseif(dy < 0) then -- Saltando (Techo)
                                                        self.y = solid.y + solid.h
                                                        self.on_ceiling = true
                                                        self.vy = 0
                                                        end
                                                        end
                                                        end
                                                        end
                                                        end

                                                        -- Helpers de Debug
                                                        function Body:tostring()
                                                        return string.format("Body[x=%.1f y=%.1f vx=%.1f vy=%.1f]", self.x, self.y, self.vx, self.vy)
                                                        end

                                                        -- ... (código anterior de physics.lua)

                                                        -- Busca colisiones con otras entidades activas
                                                        -- @param self_body: El cuerpo que pregunta
                                                        -- @param target_layer: La capa que buscamos (ej: LAYER_ENEMY)
                                                        -- @return: La entidad golpeada (o nil)
                                                        function physics.check_entity_overlap(self_body, target_layer)
                                                        local sched = require("scripts.core.sched")

                                                        -- Recorrer todas las tareas activas
                                                        for _, task in ipairs(sched.tasks) do
                                                            if task.active and task.entity and task.entity.body then
                                                                local other = task.entity.body

                                                                -- Verificar si es de la capa que buscamos
                                                                -- (Usamos bit.band simulado: si la capa coincide)
                                                                if other.layer == target_layer then
                                                                    -- Chequear solapamiento AABB
                                                                    if util.aabb(self_body.x, self_body.y, self_body.w, self_body.h,
                                                                        other.x, other.y, other.w, other.h) then
                                                                        return task.entity
                                                                        end
                                                                        end
                                                                        end
                                                                        end
                                                                        return nil
                                                                        end

                                                                        return physics
