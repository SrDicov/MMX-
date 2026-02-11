local player = {}
local physics = require("scripts.core.physics")
local config = require("scripts.config")
local util = require("scripts.core.util")
local camera = require("scripts.objects.camera").instance
local animator = require("scripts.core.animator")
local Buster = require("scripts.objects.weapons.buster")
local sched = require("scripts.core.sched")
local particles = require("scripts.core.particles")

local Player = {}
Player.__index = Player

function Player.new(args)
local self = setmetatable({}, Player)
args = args or {}

self.start_x = args.x or 100
self.start_y = args.y or 100

self.body = physics.new_body(self.start_x, self.start_y, 20, 32)
self.body.layer = physics.LAYER_PLAYER
self.body.mask = physics.LAYER_WORLD
self.stats = config.physics

self.hp = 16
self.max_hp = 16
self.state = "fall"
self.facing = 1
self.invincible_timer = 0
self.is_dead = false
self.respawn_timer = 0

self.is_dashing = false
self.dash_timer = 0
self.wall_dir = 0
self.lock_timer = 0 -- Wall kick control lock

-- Buffers
self.jump_buffer = 0
self.coyote_time = 0

self.charge_timer = 0
self.is_charging = false
self.charge_level = 0

local tex_id = texture.load("assets/sprites/x.png")
local anim_defs = {
    idle = { texture_id = tex_id, frames = {{x=0,y=0,w=32,h=32,dur=1}}, loop=true },
    run  = { texture_id = tex_id, frames = {{x=0,y=0,w=32,h=32,dur=1}}, loop=true },
    jump = { texture_id = tex_id, frames = {{x=0,y=0,w=32,h=32,dur=1}}, loop=false },
    fall = { texture_id = tex_id, frames = {{x=0,y=0,w=32,h=32,dur=1}}, loop=true },
    dash = { texture_id = tex_id, frames = {{x=0,y=0,w=32,h=32,dur=1}}, loop=true },
    wall = { texture_id = tex_id, frames = {{x=0,y=0,w=32,h=32,dur=1}}, loop=true },
    hurt = { texture_id = tex_id, frames = {{x=0,y=0,w=32,h=32,dur=1}}, loop=true }
}
self.anim = animator.new(anim_defs)
self.anim:set("idle")

self.prev_keys = {}
return self
end

function Player:_init()
_G.player_instance = self
camera:follow(self.body)
end

function Player:is_down(action) return input.down(config.input.keys[action]) end
function Player:is_pressed(action)
local key = config.input.keys[action]
return input.down(key) and not (self.prev_keys[key] or false)
end
function Player:update_input_state()
for _, key in pairs(config.input.keys) do self.prev_keys[key] = input.down(key) end
    end

    function Player:take_damage(amount, source_x)
    if self.invincible_timer > 0 or self.is_dead then return end

        self.hp = self.hp - amount
        self.invincible_timer = self.stats.hit_invincibility

        -- KNOCKBACK EXACTO MMX
        self.body.vy = -self.stats.hit_knockback_y
        if source_x then
            self.body.vx = (self.body.x < source_x) and -self.stats.hit_knockback_x or self.stats.hit_knockback_x
            self.lock_timer = 15 -- Pierdes control brevemente
            end

            self:change_state("hurt")
            if self.hp <= 0 then self:die() end
                end

                function Player:die()
                if self.is_dead then return end
                    self.is_dead = true
                    self.respawn_timer = 120
                    particles.spawn_death_explosion(self.body.x + 10, self.body.y + 16)
                    end

                    function Player:respawn()
                    self.is_dead = false
                    self.hp = self.max_hp
                    self.body.x = self.start_x
                    self.body.y = self.start_y
                    self.body.vx = 0
                    self.body.vy = 0
                    self.state = "fall"
                    self.invincible_timer = 120
                    camera:snap_to_target()
                    end

                    function Player:handle_shoot()
                    if self.is_dead or self.state == "hurt" then return end

                        if self:is_pressed("shoot") then
                            Buster.shoot(self.body.x, self.body.y, self.facing, 0)
                            self.is_charging = true
                            self.charge_timer = 0
                            end

                            if self:is_down("shoot") then
                                self.is_charging = true
                                self.charge_timer = self.charge_timer + 1
                                if self.charge_timer > 120 then self.charge_level = 2
                                    elseif self.charge_timer > 40 then self.charge_level = 1
                                        else self.charge_level = 0 end
                                            else
                                                if self.is_charging then
                                                    if self.charge_level > 0 then
                                                        Buster.shoot(self.body.x, self.body.y, self.facing, self.charge_level)
                                                        self.charge_level = 0
                                                        end
                                                        self.is_charging = false
                                                        self.charge_timer = 0
                                                        end
                                                        end
                                                        end

                                                        function Player:change_state(new_state)
                                                        if self.is_dead then return end
                                                            self.state = new_state
                                                            if self.anim then self.anim:set(new_state) end
                                                                if new_state == "idle" or new_state == "run" then self.is_dashing = false end
                                                                    end

                                                                    function Player:update()
                                                                    if self.is_dead then
                                                                        self.respawn_timer = self.respawn_timer - 1
                                                                        if self.respawn_timer <= 0 then self:respawn() end
                                                                            return
                                                                            end

                                                                            if self.invincible_timer > 0 then self.invincible_timer = self.invincible_timer - 1 end
                                                                                if self.lock_timer > 0 then self.lock_timer = self.lock_timer - 1 end

                                                                                    if self:is_pressed("jump") then self.jump_buffer = 6 end
                                                                                        if self.jump_buffer > 0 then self.jump_buffer = self.jump_buffer - 1 end
                                                                                            if self.body.on_floor then self.coyote_time = 6 end
                                                                                                if self.coyote_time > 0 then self.coyote_time = self.coyote_time - 1 end

                                                                                                    local x_input = 0
                                                                                                    if self.lock_timer <= 0 then
                                                                                                        if self:is_down("right") then x_input = 1 end
                                                                                                            if self:is_down("left") then x_input = -1 end
                                                                                                                end

                                                                                                                self:handle_shoot()
                                                                                                                if self.body.y > 800 then self:die() end -- Limite de caida

                                                                                                                    local function try_jump()
                                                                                                                    if self.jump_buffer > 0 and self.coyote_time > 0 then
                                                                                                                        self.body.vy = -self.stats.jump_force
                                                                                                                        if self.is_dashing then
                                                                                                                            self.body.vx = self.facing * self.stats.dash_speed * self.stats.dash_jump_mult
                                                                                                                            end
                                                                                                                            self:change_state("jump")
                                                                                                                            self.jump_buffer = 0
                                                                                                                            self.coyote_time = 0
                                                                                                                            return true
                                                                                                                            end
                                                                                                                            return false
                                                                                                                            end

                                                                                                                            -- MÁQUINA DE ESTADOS
                                                                                                                            if self.state == "idle" or self.state == "run" then
                                                                                                                                if x_input == 0 then
                                                                                                                                    self.body.vx = 0
                                                                                                                                    if self.state ~= "idle" then self:change_state("idle") end
                                                                                                                                        else
                                                                                                                                            self.facing = x_input
                                                                                                                                            self.body.vx = x_input * self.stats.walk_speed
                                                                                                                                            if self.state ~= "run" then self:change_state("run") end
                                                                                                                                                end

                                                                                                                                                if self:is_pressed("dash") then
                                                                                                                                                    self:change_state("dash")
                                                                                                                                                    self.dash_timer = 20
                                                                                                                                                    self.is_dashing = true
                                                                                                                                                    self.body.vx = self.facing * self.stats.dash_speed
                                                                                                                                                    end

                                                                                                                                                    try_jump()
                                                                                                                                                    if not self.body.on_floor then self:change_state("fall") end

                                                                                                                                                        elseif self.state == "dash" then
                                                                                                                                                            self.body.vx = self.facing * self.stats.dash_speed
                                                                                                                                                            self.dash_timer = self.dash_timer - 1
                                                                                                                                                            if self.dash_timer <= 0 or (x_input ~= 0 and x_input ~= self.facing) then
                                                                                                                                                                self:change_state("idle")
                                                                                                                                                                self.body.vx = 0
                                                                                                                                                                end
                                                                                                                                                                try_jump()
                                                                                                                                                                if not self.body.on_floor then self:change_state("fall") end

                                                                                                                                                                    elseif self.state == "jump" or self.state == "fall" or self.state == "hurt" then
                                                                                                                                                                        if self.state ~= "hurt" and self.lock_timer <= 0 then
                                                                                                                                                                            if x_input ~= 0 then
                                                                                                                                                                                if not self.is_dashing then
                                                                                                                                                                                    self.body.vx = x_input * self.stats.walk_speed
                                                                                                                                                                                    self.facing = x_input
                                                                                                                                                                                    end
                                                                                                                                                                                    else
                                                                                                                                                                                        if not self.is_dashing then self.body.vx = 0 end
                                                                                                                                                                                            end
                                                                                                                                                                                            end

                                                                                                                                                                                            if self.state == "jump" and not self:is_down("jump") and self.body.vy < -2 then
                                                                                                                                                                                                self.body.vy = -2 -- Variable Jump Height
                                                                                                                                                                                                self:change_state("fall")
                                                                                                                                                                                                end
                                                                                                                                                                                                if self.body.vy > 0 then self:change_state("fall") end

                                                                                                                                                                                                    if self.body.on_floor then
                                                                                                                                                                                                        self.is_dashing = false
                                                                                                                                                                                                        if not try_jump() then
                                                                                                                                                                                                            if x_input == 0 then self:change_state("idle") else self:change_state("run") end
                                                                                                                                                                                                                end
                                                                                                                                                                                                                end

                                                                                                                                                                                                                local wall_check = (self.body.on_wall_left and x_input == -1) or (self.body.on_wall_right and x_input == 1)
                                                                                                                                                                                                                if wall_check and self.body.vy > 0 and self.state ~= "hurt" then
                                                                                                                                                                                                                    self:change_state("wall")
                                                                                                                                                                                                                    self.wall_dir = self.body.on_wall_left and -1 or 1
                                                                                                                                                                                                                    self.facing = -self.wall_dir
                                                                                                                                                                                                                    self.is_dashing = false
                                                                                                                                                                                                                    end

                                                                                                                                                                                                                    elseif self.state == "wall" then
                                                                                                                                                                                                                        self.body.vy = self.stats.wall_slide_speed
                                                                                                                                                                                                                        self.coyote_time = 0

                                                                                                                                                                                                                        -- LÓGICA DE WALL KICK (MECÁNICA MMX EXACTA)
                                                                                                                                                                                                                        -- En MMX, si presionas SALTO estando en la pared:
                                                                                                                                                                                                                        -- 1. Se ejecuta el salto siempre.
                                                                                                                                                                                                                        -- 2. La dirección depende del INPUT.

                                                                                                                                                                                                                        if self:is_pressed("jump") then
                                                                                                                                                                                                                            local input_dir = 0
                                                                                                                                                                                                                            if self:is_down("right") then input_dir = 1 end
                                                                                                                                                                                                                                if self:is_down("left") then input_dir = -1 end

                                                                                                                                                                                                                                    -- KICK (Alejarse): Presionando OPUESTO a la pared
                                                                                                                                                                                                                                    local is_kicking = (input_dir == -self.wall_dir)

                                                                                                                                                                                                                                    -- CLIMB (Escalar): Presionando HACIA la pared o NEUTRO
                                                                                                                                                                                                                                    local is_climbing = (input_dir == self.wall_dir) or (input_dir == 0)

                                                                                                                                                                                                                                    if is_climbing then
                                                                                                                                                                                                                                        -- Escalar: Fuerza Y normal, Fuerza X CERO (te mantienes pegado)
                                                                                                                                                                                                                                        self.body.vy = -self.stats.wall_kick_y
                                                                                                                                                                                                                                        self.body.vx = 0
                                                                                                                                                                                                                                        -- Nota: MMX permite escalar paredes verticales infinitamente así.
                                                                                                                                                                                                                                        self:change_state("jump")
                                                                                                                                                                                                                                        else
                                                                                                                                                                                                                                            -- Patear: Fuerza Y normal, Fuerza X fuerte hacia afuera
                                                                                                                                                                                                                                            self.body.vy = -self.stats.wall_kick_y
                                                                                                                                                                                                                                            self.body.vx = -self.wall_dir * self.stats.wall_kick_x
                                                                                                                                                                                                                                            self.facing = -self.wall_dir
                                                                                                                                                                                                                                            self.lock_timer = self.stats.wall_kick_lock -- Bloqueo de input
                                                                                                                                                                                                                                            self:change_state("jump")
                                                                                                                                                                                                                                            end
                                                                                                                                                                                                                                            end

                                                                                                                                                                                                                                            local pushing_wall = (self.wall_dir == -1 and x_input == -1) or (self.wall_dir == 1 and x_input == 1)
                                                                                                                                                                                                                                            if not pushing_wall then self:change_state("fall") end
                                                                                                                                                                                                                                                if self.body.on_floor then self:change_state("idle") end
                                                                                                                                                                                                                                                    end

                                                                                                                                                                                                                                                    if self.state ~= "wall" then
                                                                                                                                                                                                                                                        self.body.vy = self.body.vy + self.stats.gravity
                                                                                                                                                                                                                                                        if self.body.vy > self.stats.term_vel then self.body.vy = self.stats.term_vel end
                                                                                                                                                                                                                                                            end

                                                                                                                                                                                                                                                            local solids = _G.map_solids or {}
                                                                                                                                                                                                                                                            self.body:move_and_slide(solids)

                                                                                                                                                                                                                                                            self:update_input_state()
                                                                                                                                                                                                                                                            if self.anim then self.anim:update() end
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                function Player:draw(cx, cy)
                                                                                                                                                                                                                                                                if self.is_dead then return end
                                                                                                                                                                                                                                                                if self.invincible_timer > 0 and (self.invincible_timer % 4 < 2) then return end

                                                                                                                                                                                                                                                                local draw_x = self.body.x - (cx or 0)
                                                                                                                                                                                                                                                                local draw_y = self.body.y - (cy or 0)
                                                                                                                                                                                                                                                                local flip = (self.facing == -1)

                                                                                                                                                                                                                                                                if self.charge_level == 1 then
                                                                                                                                                                                                                                                                batch.draw(texture.white(), draw_x-2, draw_y-2, 0,0, self.body.w+4, self.body.h+4, false)
                                                                                                                                                                                                                                                                elseif self.charge_level == 2 then
                                                                                                                                                                                                                                                                batch.draw(texture.white(), draw_x-4, draw_y-4, 0,0, self.body.w+8, self.body.h+8, false)
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                self.anim:draw(draw_x, draw_y, flip)
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                return Player
