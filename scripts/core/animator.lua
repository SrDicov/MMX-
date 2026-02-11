local animator = {}

local Animator = {}
Animator.__index = Animator

-- Configuración de animaciones (Formato estándar)
-- animations = {
--    idle = { texture_id, frames = { {x=0, y=0, w=32, h=32, dur=10}, ... }, loop = true },
--    run  = { ... }
-- }
function animator.new(animations)
local self = setmetatable({}, Animator)
self.anims = animations or {}
self.current_anim = nil
self.current_name = ""
self.frame_index = 1
self.timer = 0
self.finished = false
return self
end

function Animator:set(name)
if self.current_name == name then return end -- No reiniciar si es la misma

    local anim = self.anims[name]
    if not anim then
        console.error("Animator: Animation '" .. name .. "' not found.")
        return
        end

        self.current_name = name
        self.current_anim = anim
        self.frame_index = 1
        self.timer = anim.frames[1].dur or 10
        self.finished = false
        end

        function Animator:update()
        if not self.current_anim then return end

            -- Si ya terminó y no loopea, no hacer nada
            if self.finished then return end

                self.timer = self.timer - 1
                if self.timer <= 0 then
                    -- Avanzar frame
                    self.frame_index = self.frame_index + 1

                    -- Check final
                    if self.frame_index > #self.current_anim.frames then
                        if self.current_anim.loop then
                            self.frame_index = 1
                            else
                                self.frame_index = #self.current_anim.frames
                                self.finished = true
                                end
                                end

                                -- Reset timer del nuevo frame
                                local frame = self.current_anim.frames[self.frame_index]
                                self.timer = frame.dur or 10
                                end
                                end

                                function Animator:draw(x, y, flip_x)
                                if not self.current_anim then return end

                                    local frame = self.current_anim.frames[self.frame_index]
                                    local tex = self.current_anim.texture_id or 0

                                    -- Dibujar usando el Batch Renderer
                                    -- batch.draw(tex, x, y, src_x, src_y, src_w, src_h, flip)
                                    batch.draw(tex, x, y, frame.x, frame.y, frame.w, frame.h, flip_x)
                                    end

                                    return animator
