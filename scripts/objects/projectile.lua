local physics = require("scripts.core.physics")
local util = require("scripts.core.util")
local sched = require("scripts.core.sched")
local particles = require("scripts.core.particles")

local Projectile = {}
Projectile.__index = Projectile

function Projectile.new(args)
local self = setmetatable({}, Projectile)
args = args or {}

self.body = physics.new_body(args.x or 0, args.y or 0, args.w or 8, args.h or 6)
self.body.layer = args.layer or physics.LAYER_PLAYER_SHOT
self.body.mask = args.mask or physics.LAYER_ENEMY
self.body.vx = args.vx or 0
self.body.vy = args.vy or 0

self.damage = args.damage or 1
self.life_time = args.life_time or 60

local status, res = pcall(function() return texture.white() end)
self.tex_id = args.tex_id or (status and res or 0)

return self
end

function Projectile:update()
-- 1. Movimiento
self.body.x = self.body.x + self.body.vx
self.body.y = self.body.y + self.body.vy

-- 2. Colisión con Mundo (Paredes)
local map_solids = _G.map_solids or {}
for _, solid in ipairs(map_solids) do
    if self.body:check_collision(solid) then
        self:on_wall_hit()
        return
        end
        end

        -- 3. Colisión con Entidades (Daño)
        -- Si soy disparo de jugador, busco enemigos
        local target_layer = (self.body.layer == physics.LAYER_PLAYER_SHOT)
        and physics.LAYER_ENEMY
        or physics.LAYER_PLAYER

        local hit_ent = physics.check_entity_overlap(self.body, target_layer)
        if hit_ent then
            self:on_hit_entity(hit_ent)
            return
            end

            -- 4. Vida
            self.life_time = self.life_time - 1
            if self.life_time <= 0 then
                sched.kill(self.pid)
                end
                end

                function Projectile:on_wall_hit()
                particles.spawn_hit(self.body.x, self.body.y)
                sched.kill(self.pid)
                end

                function Projectile:on_hit_entity(ent)
                if ent.take_damage then
                    ent:take_damage(self.damage, self.body.x)
                    particles.spawn_hit(self.body.x, self.body.y)
                    end
                    sched.kill(self.pid)
                    end

                    function Projectile:draw(cx, cy)
                    cx = cx or 0
                    cy = cy or 0
                    local draw_x = self.body.x - cx
                    local draw_y = self.body.y - cy

                    batch.draw(self.tex_id, draw_x, draw_y, 0, 0, self.body.w, self.body.h, self.body.vx < 0)
                    end

                    return Projectile
