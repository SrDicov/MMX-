local hud = {}

function hud.draw_static(player)
if not player then return end

    -- COORDENADAS FIJAS EN PANTALLA
    -- No sumamos ni restamos cámara. 20, 20 siempre es arriba a la izquierda.
    local start_x = 20
    local start_y = 20

    local max_hp = player.max_hp or 16
    local current_hp = player.hp or 16
    local total_h = (max_hp * 3) + 2

    -- Dibujar vida
    for i = 1, max_hp do
        local y_pos = start_y + total_h - (i * 3)

        if i <= current_hp then
            batch.draw(texture.white(), start_x, y_pos, 0, 0, 8, 2, false)
            else
                batch.draw(texture.white(), start_x + 3, y_pos, 0, 0, 2, 2, false)
                end
                end
                end

                return hud
