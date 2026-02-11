local level = {}
local physics = require("scripts.core.physics")
local camera = require("scripts.objects.camera").instance
local sched = require("scripts.core.sched")
local Metool = require("scripts.objects.enemies.metool")

function level.load()
_G.map_solids = {} -- Limpiar mapa anterior
sched.clear() -- Limpiar enemigos anteriores (cuidado, esto borra al player si ya existe)

-- Helper
local function add_block(x, y, w, h)
local block = physics.new_body(x, y, w, h)
block.layer = physics.LAYER_WORLD
table.insert(_G.map_solids, block)
end

-- === ZONA 1: EL PASILLO INICIAL ===
add_block(0, 200, 300, 50) -- Suelo seguro
add_block(-20, 0, 20, 500) -- Pared tope izquierda

-- === ZONA 2: LOS SALTOS (PARKOUR) ===
-- Bloques flotantes sobre el vacío
add_block(350, 180, 40, 10)
add_block(450, 150, 40, 10)
add_block(550, 120, 30, 10) -- Salto preciso
add_block(650, 150, 40, 10) -- Bajada

-- === ZONA 3: LA ESCALADA VERTICAL ===
-- Pared alta que requiere Wall Kick
add_block(800, 50, 50, 200) -- Muro central

-- Plataforma en la cima
add_block(800, 50, 200, 20)

-- === ZONA 4: COMBATE FINAL ===
-- Una arena plana al final
add_block(1100, 200, 500, 50) -- Suelo Arena
add_block(1600, 0, 20, 500)   -- Pared Final

-- === ENEMIGOS ===
-- Un par de francotiradores en las plataformas
sched.spawn(Metool, {x=560, y=100})

-- Emboscada final
sched.spawn(Metool, {x=1200, y=180})
sched.spawn(Metool, {x=1350, y=180})
sched.spawn(Metool, {x=1500, y=180})

-- Configurar Cámara
camera:set_bounds(0, 0, 1620, 400) -- Permitir scroll horizontal largo
console.log("Nivel Parkour cargado.")
end

function level.draw()
local cx = _G.camera_x or 0
local cy = _G.camera_y or 0
local tex = texture.white()

for _, block in ipairs(_G.map_solids) do
    -- Solo dibujar si está en pantalla (Culling básico)
    if block.x - cx < 300 and block.x + block.w - cx > -50 then
        batch.draw(tex, block.x - cx, block.y - cy, 0, 0, block.w, block.h, false)
        end
        end
        end

    return level
