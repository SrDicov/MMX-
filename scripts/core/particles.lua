local particles = {}
local sched = require("scripts.core.sched")
local physics = require("scripts.core.physics")
local util = require("scripts.core.util")

local Particle = {}
Particle.__index = Particle

-- Constructor de una partícula individual
function Particle.new(args)
local self = setmetatable({}, Particle)

-- Física simple (sin colisiones con el mundo, solo movimiento)
self.x = args.x or 0
self.y = args.y or 0
self.vx = args.vx or 0
self.vy = args.vy or 0
self.w = args.w or 4
self.h = args.h or 4
self.color = args.color or {1, 1, 1, 1} -- Blanco por defecto

self.life = args.life or 60 -- Duración en frames
self.max_life = self.life
self.layer = 100 -- Por encima de todo

return self
end

function Particle:update()
self.x = self.x + self.vx
self.y = self.y + self.vy

self.life = self.life - 1
if self.life <= 0 then
    sched.kill(self.pid)
    end
    end

    function Particle:draw()
    -- Dibujar cuadrado (rudimentario)
    -- Simular opacidad con parpadeo si queda poca vida (estilo retro)
    if self.life < 10 and (self.life % 2 == 0) then return end

        -- Usamos textura blanca (asumiendo que texture.white() existe y funciona)
        batch.draw(texture.white(), self.x, self.y, 0, 0, self.w, self.h, false)
        end

        -- Generador de Explosión de Muerte (4 orbes saliendo en diagonal)
        function particles.spawn_death_explosion(x, y)
        local speed = 2.5
        local dirs = {
            {vx = -speed, vy = -speed}, -- Noroeste
            {vx = speed, vy = -speed},  -- Noreste
            {vx = -speed, vy = speed},  -- Suroeste
            {vx = speed, vy = speed}    -- Sureste
        }

        for _, dir in ipairs(dirs) do
            sched.spawn(Particle, {
                x = x, y = y,
                vx = dir.vx, vy = dir.vy,
                w = 8, h = 8, -- Cuadros un poco más grandes
                life = 120    -- Duran 2 segundos
            })
            end
            end

            -- Generador de Chispas (Hit effect)
            function particles.spawn_hit(x, y)
            for i=1, 4 do
                local vx = math.random(-20, 20) / 10.0
                local vy = math.random(-20, 20) / 10.0
                sched.spawn(Particle, {
                    x = x, y = y,
                    vx = vx, vy = vy,
                    w = 2, h = 2,
                    life = 15
                })
                end
                end

                return particles
