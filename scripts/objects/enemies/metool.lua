local Enemy = require("scripts.objects.enemy")
local animator = require("scripts.core.animator")
local util = require("scripts.core.util")
local Projectile = require("scripts.objects.projectile")
local sched = require("scripts.core.sched")

local Metool = {}
Metool.__index = Metool
setmetatable(Metool, {__index = Enemy})

function Metool.new(args)
local self = Enemy.new(args)
setmetatable(self, Metool)

self.hp = 2
self.body.w = 18
self.body.h = 18
self.detect_range = 150
self.shoot_timer = 0
self.shoot_interval = 120

-- Intento de cargar textura, si falla, usa blanco
local status, tex = pcall(function() return texture.load("assets/sprites/metool.png") end)
self.has_texture = status and (tex > 0)
if not self.has_texture then tex = texture.white() end

    self.anim = animator.new({
        idle = { texture_id = tex, frames = {{x=0,y=0,w=20,h=20,dur=1}}, loop=true },
        hide = { texture_id = tex, frames = {{x=20,y=0,w=20,h=20,dur=1}}, loop=true },
        shoot = { texture_id = tex, frames = {{x=40,y=0,w=20,h=20,dur=10}}, loop=false }
    })
    self.anim:set("idle")

    return self
    end

    function Metool:ai_update()
    if not self.target then
        self.target = _G.player_instance
        return
        end

        local dx = self.target.body.x - self.body.x
        local dist = math.abs(dx)

        if dist > 300 then return end -- Culling

            if dx > 0 then self.facing = 1 else self.facing = -1 end

                if self.state == "idle" then
                    self.anim:set("idle")
                    if dist < self.detect_range then
                        self.state = "hide"
                        self.invincible_timer = 0
                        else
                            self.shoot_timer = self.shoot_timer + 1
                            if self.shoot_timer > self.shoot_interval then
                                self.state = "shoot"
                                self.shoot_timer = 0
                                self:fire_spread()
                                end
                                end

                                elseif self.state == "hide" then
                                    self.anim:set("hide")
                                    self.invincible_timer = 2 -- Invulnerable mientras se esconde
                                    if dist > self.detect_range + 20 then
                                        self.state = "idle"
                                        self.invincible_timer = 0
                                        end

                                        elseif self.state == "shoot" then
                                            self.anim:set("shoot")
                                            if self.anim.finished or self.anim.timer <= 1 then
                                                self.state = "idle"
                                                end
                                                end
                                                end

                                                function Metool:fire_spread()
                                                local physics = require("scripts.core.physics")
                                                local angles = {-0.5, 0, 0.5}

                                                for _, vy in ipairs(angles) do
                                                    local props = {
                                                        x = self.body.x + 10,
                                                        y = self.body.y + 5,
                                                        w = 6, h = 6,
                                                        vx = self.facing * 3,
                                                        vy = vy,
                                                        damage = 2,
                                                        life_time = 120,
                                                        layer = physics.LAYER_ENEMY_SHOT,
                                                        mask = physics.LAYER_PLAYER,
                                                        tex_id = texture.white()
                                                    }
                                                    sched.spawn(Projectile, props)
                                                    end
                                                    end

                                                    -- OVERRIDE DEL DRAW PARA VERLO AUNQUE NO TENGA TEXTURA
                                                    function Metool:draw(cx, cy)
                                                    cx = cx or 0
                                                    cy = cy or 0
                                                    local draw_x = self.body.x - cx
                                                    local draw_y = self.body.y - cy

                                                    if self.invincible_timer > 0 and (self.invincible_timer % 2 == 0) and self.state ~= "hide" then return end

                                                        if self.has_texture then
                                                            local flip = (self.facing == 1)
                                                            self.anim:draw(draw_x, draw_y, flip)
                                                            else
                                                                -- Fallback Visual si no hay PNG
                                                                if self.state == "hide" then
                                                                    -- Dibujar cuadrado aplastado o de otro color para indicar escondido
                                                                    batch.draw(texture.white(), draw_x, draw_y + 10, 0,0, self.body.w, self.body.h - 10, false)
                                                                    else
                                                                        -- Dibujar normal
                                                                        batch.draw(texture.white(), draw_x, draw_y, 0,0, self.body.w, self.body.h, false)
                                                                        end
                                                                        end
                                                                        end

                                                                        return Metool
