local Player = require("scripts.objects.player")

local player_inst = nil
-- Variables de cámara
local cam_x = 0
local cam_y = 0

function _init()
print("[MMX++] Iniciando Fase 1 Final: Test de Camara")
player_inst = Player:new(100, 100)
end

function _update(dt)
if player_inst then
    player_inst:update(dt)

    -- Lógica de Cámara: Seguir al jugador
    -- Objetivo: Que el jugador esté en el centro (128, 112)
    local target_x = player_inst.x - 128 + (player_inst.width or 24)/2
    local target_y = player_inst.y - 112 + (player_inst.height or 32)/2

    -- Lerp suave (interpolación) para que no sea brusco
    cam_x = cam_x + (target_x - cam_x) * 5 * dt
    cam_y = cam_y + (target_y - cam_y) * 5 * dt

    -- Opcional: Bloquear cámara para que no muestre coordenadas negativas (limite izquierdo del nivel)
    if cam_x < 0 then cam_x = 0 end
        end
        end

        function _draw()
        -- 1. Configurar Cámara
        -- Importante: Usamos math.floor para evitar "shimmering" (parpadeo) en pixel art
        batch.set_camera(math.floor(cam_x), math.floor(cam_y))

        -- 2. Dibujar Mundo
        if player_inst then
            player_inst:draw()
            end

            -- Dibujar algo estático de referencia (para ver que nos movemos)
            -- Dibujamos un cuadrado en (0,0) y otro en (300, 100)
            if player_inst and player_inst.anim then
                -- Cuadrado de origen (Referencia inicial)
                batch.draw(player_inst.anim.tex_id, 0, 100, 32, 32, 0,0,1,1)
                -- Cuadrado lejano (Para probar scroll)
                batch.draw(player_inst.anim.tex_id, 400, 100, 32, 32, 0,0,1,1)
                end

                batch.flush()
                end
