local Projectile = require("scripts.objects.projectile")
local physics = require("scripts.core.physics")
local sched = require("scripts.core.sched")

local Buster = {}

-- Definición de niveles de carga
Buster.TYPES = {
    [0] = { -- LEMON (Normal)
        w = 6, h = 4,
        speed = 5.0,
        damage = 1,
        color = {1, 1, 0}, -- Amarillo (Conceptual)
        sfx = "buster_shot"
    },
    [1] = { -- SEMI-CHARGED (Verde)
        w = 16, h = 10,
        speed = 6.0,
        damage = 2, -- Daño medio
        color = {0, 1, 0}, -- Verde
        sfx = "buster_mid"
    },
    [2] = { -- FULL-CHARGED (Azul)
        w = 24, h = 18,
        speed = 7.0,
        damage = 4, -- Daño fuerte
        color = {0, 0, 1}, -- Azul
        sfx = "buster_full"
    }
}

function Buster.shoot(x, y, facing, charge_level)
-- Validar nivel de carga (0, 1, 2)
local lvl = charge_level or 0
if lvl > 2 then lvl = 2 end

    local props = Buster.TYPES[lvl]

    -- Posición de salida relativa a X
    local spawn_x = x
    local spawn_y = y + 10 -- Altura del cañón

    if facing == 1 then
        spawn_x = spawn_x + 20
        else
            spawn_x = spawn_x - props.w
            end

            -- Configurar Proyectil
            local p_args = {
                x = spawn_x,
                y = spawn_y,
                w = props.w,
                h = props.h,
                vx = facing * props.speed,
                vy = 0,
                damage = props.damage,
                life_time = 60, -- 1 segundo
                layer = physics.LAYER_PLAYER_SHOT,
                mask = physics.LAYER_ENEMY, -- Choca con enemigos
                tex_id = texture.white() -- Usar blanco y confiar en el tamaño para diferenciar
            }

            -- Spawnear
            sched.spawn(Projectile, p_args)

            -- Reproducir sonido (si tuviéramos los archivos)
            -- audio.play("assets/sfx/" .. props.sfx .. ".wav")
            end

            return Buster
