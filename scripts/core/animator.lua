-- scripts/core/animator.lua
local class = require("scripts.core.class")
local Animator = class()

function Animator:init(tex_id, w, h)
self.tex_id = tex_id
self.w, self.h = w, h
self.current_anim = nil
self.timer = 0
self.frame = 1
self.flipped = false
self.anims = {}
end

function Animator:add_anim(name, frames, loop)
self.anims[name] = { frames = frames, loop = (loop ~= false) }
end

function Animator:play(name)
if self.current_anim ~= name then
    self.current_anim = name
    self.timer, self.frame = 0, 1
    end
    end

    function Animator:update(dt)
    if not self.current_anim then return end
        local anim = self.anims[self.current_anim]
        local fr = anim.frames[self.frame]
        local duration = fr[5] or 0.1

        self.timer = self.timer + dt
        if self.timer >= duration then
            self.timer = self.timer - duration
            self.frame = self.frame + 1
            if self.frame > #anim.frames then
                self.frame = anim.loop and 1 or #anim.frames
                end
                end
                end

                function Animator:draw(x, y)
                if not self.current_anim then return end
                    local anim = self.anims[self.current_anim]
                    local fr = anim.frames[self.frame]
                    -- {x, y, w, h, duration}
                    local fx, fy, fw, fh = fr[1], fr[2], fr[3], fr[4]

                    -- Calcular UVs
                    local u0, v0 = fx/self.w, fy/self.h
                    local u1, v1 = (fx+fw)/self.w, (fy+fh)/self.h

                    -- Aplicar Flip
                    if self.flipped then
                        local temp = u0; u0 = u1; u1 = temp
                        end

                        -- Llamada correcta a nuestro motor C++ (9 argumentos numéricos)
                        batch.draw(self.tex_id, x, y, fw, fh, u0, v0, u1, v1)
                        end

                        return Animator
