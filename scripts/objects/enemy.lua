local enemy = {}
local physics = require("scripts.core.physics")
local util = require("scripts.core.util")
local sched = require("scripts.core.sched")
local animator = require("scripts.core.animator")
local config = require("scripts.config")

local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(args)
local self = setmetatable({}, Enemy)
args = args or {}

-- 1. FÍSICA
local x = args.x or 0
local y = args.y or 0
local w = args.w or 20
local h = args.h or 20

self.body = physics.new_body(x, y, w, h)
self.body.layer = physics.LAYER_ENEMY
self.body.mask = physics.LAYER_WORLD -- Choca con el suelo
self.stats = config.physics

-- 2. ESTADÍSTICAS DE COMBATE
self.hp = args.hp or 3
self.max_hp = self.hp
self.contact_damage = args.damage or 2 -- Daño al tocar a X

-- Invencibilidad (Flash al ser golpeado)
self.invincible_timer = 0

-- 3. ESTADO E IA
self.state = "idle"
self.facing = -1 -- -1 Izquierda, 1 Derecha
self.target = nil -- Referencia al jugador (se asigna en _init)

-- 4. GRÁFICOS (Animator vacío, los hijos lo llenan)
self.anim = nil
self.tex_id = texture.white()

return self
end

-- Inicialización (busca al jugador)
function Enemy:_init()
-- Buscar al jugador en la lista de tareas del scheduler
-- (Forma simplificada: Asumimos que el PID 1 o 2 es el player, o buscamos por nombre)
-- Para hacerlo robusto, el Player debería registrarse en una global _G.player
self.target = _G.player_instance
end

-- MÉTODOS DE COMBATE
function Enemy:take_damage(amount)
if self.invincible_timer > 0 then return end

    self.hp = self.hp - amount
    self.invincible_timer = 4 -- 4 frames de flash blanco

    -- Sonido de daño (Placeholder)
    -- audio.play("enemy_hit")

    if self.hp <= 0 then
        self:die()
        end
        end

        function Enemy:die()
        -- Efecto de explosión (Placeholder: Spawnear partículas)
        console.log("Enemy died!")
        sched.kill(self.pid) -- Auto-eliminarse
        end

        -- UPDATE BASE
        function Enemy:update()
        -- 1. Gestionar Timers
        if self.invincible_timer > 0 then
            self.invincible_timer = self.invincible_timer - 1
            end

            -- 2. IA (Método vacío para que los hijos lo sobrescriban)
            if self.ai_update then self:ai_update() end

                -- 3. Física (Gravedad básica)
                self.body.vy = self.body.vy + self.stats.gravity
                if self.body.vy > self.stats.term_vel then self.body.vy = self.stats.term_vel end

                    local solids = _G.map_solids or {}
                    self.body:move_and_slide(solids)

                    -- 4. Animación
                    if self.anim then self.anim:update() end
                        end

                        function Enemy:draw(cx, cy) -- Recibe cámara
                        cx = cx or 0
                        cy = cy or 0
                        local draw_x = self.body.x - cx
                        local draw_y = self.body.y - cy

                        if self.invincible_timer > 0 and (self.invincible_timer % 2 == 0) then return end

                            if self.anim then
                                local flip = (self.facing == 1)
                                self.anim:draw(draw_x, draw_y, flip)
                                else
                                    batch.draw(self.tex_id, draw_x, draw_y, 0,0, self.body.w, self.body.h, false)
                                    end
                                    end

                                    return Enemy
