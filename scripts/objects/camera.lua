local camera = {}
local util = require("scripts.core.util")
local config = require("scripts.config")

local Camera = {}
Camera.__index = Camera

function Camera.new(target)
local self = setmetatable({}, Camera)

self.vw = config.system.width
self.vh = config.system.height

self.x = 0
self.y = 0

self.target = target

-- Configuración de "Ventana" (Deadzone)
-- El jugador puede moverse libremente en este recuadro central sin mover la cámara.
-- Un margen de 100px a los lados significa que la cámara empieza a moverse
-- cuando el jugador está a 100px del borde.
self.margin_x = 100
self.margin_y = 80

self.bounds = {
    min_x = -999999, min_y = -999999,
    max_x = 999999, max_y = 999999
}

return self
end

function Camera:set_bounds(x, y, w, h)
self.bounds.min_x = x
self.bounds.min_y = y
self.bounds.max_x = x + w
self.bounds.max_y = y + h
self:snap_to_target()
end

function Camera:follow(entity)
self.target = entity
end

function Camera:snap_to_target()
if not self.target then return end
    -- Centrar forzado
    local target_cx = self.target.x + (self.target.w / 2)
    local target_cy = self.target.y + (self.target.h / 2)
    self.x = target_cx - (self.vw / 2)
    self.y = target_cy - (self.vh / 2)
    self:apply_clamping()
    end

    function Camera:apply_clamping()
    if self.x < self.bounds.min_x then self.x = self.bounds.min_x end
        if self.x > self.bounds.max_x - self.vw then self.x = self.bounds.max_x - self.vw end
            if (self.bounds.max_x - self.bounds.min_x) < self.vw then
                self.x = self.bounds.min_x - (self.vw - (self.bounds.max_x - self.bounds.min_x)) / 2
                end

                if self.y < self.bounds.min_y then self.y = self.bounds.min_y end
                    if self.y > self.bounds.max_y - self.vh then self.y = self.bounds.max_y - self.vh end
                        end

                        function Camera:update()
                        if not self.target then return end

                            -- Lógica de Ventana (Deadzone)
                            -- Coordenadas del target relativas a la pantalla
                            local screen_target_x = self.target.x - self.x
                            local screen_target_y = self.target.y - self.y

                            -- 1. Control Horizontal
                            -- Si el jugador toca el margen izquierdo
                            if screen_target_x < self.margin_x then
                                self.x = self.target.x - self.margin_x
                                end
                                -- Si el jugador toca el margen derecho
                                if screen_target_x > (self.vw - self.margin_x - self.target.w) then
                                    self.x = self.target.x - (self.vw - self.margin_x - self.target.w)
                                    end

                                    -- 2. Control Vertical
                                    if screen_target_y < self.margin_y then
                                        self.y = self.target.y - self.margin_y
                                        end
                                        if screen_target_y > (self.vh - self.margin_y - self.target.h) then
                                            self.y = self.target.y - (self.vh - self.margin_y - self.target.h)
                                            end

                                            -- 3. Bounds y Exportar
                                            self:apply_clamping()

                                            self.x = math.floor(self.x)
                                            self.y = math.floor(self.y)

                                            _G.camera_x = self.x
                                            _G.camera_y = self.y
                                            end

                                            -- Singleton
                                            camera.instance = Camera.new(nil)
                                            return camera
