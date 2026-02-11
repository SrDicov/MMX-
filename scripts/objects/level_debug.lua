local level = {}
local physics = require("scripts.core.physics")
local camera = require("scripts.objects.camera").instance

function level.load_test_room()
-- Lista global de colisionadores (para que physics.lua la lea)
_G.map_solids = {}

-- Helper para crear bloques
local function add_block(x, y, w, h)
local block = physics.new_body(x, y, w, h)
block.layer = physics.LAYER_WORLD
table.insert(_G.map_solids, block)
end

-- === GEOMETRÍA DEL NIVEL (Pixel Art Style) ===

-- 1. Suelo Principal
add_block(0, 200, 1000, 50) -- Un piso largo en Y=200

-- 2. Pared Izquierda (Tope)
add_block(-20, 0, 20, 300)

-- 3. Pared Derecha (Tope)
add_block(800, 0, 20, 300)

-- 4. Plataformas
add_block(200, 150, 100, 10) -- Plataforma baja
add_block(350, 120, 50, 10)  -- Plataforma media
add_block(450, 90,  100, 10) -- Plataforma alta

-- 5. Pared para probar Wall Kick
add_block(600, 100, 32, 100) -- Un pilar vertical

-- Configurar límites de cámara para esta habitación
camera:set_bounds(0, 0, 800, 224)

console.log("Nivel Debug cargado: " .. #_G.map_solids .. " bloques.")
end

-- Dibujado de Debug (Verde = Suelo)
function level.draw()
local tex = texture.white() -- Usamos la textura blanca del paso 1

for _, block in ipairs(_G.map_solids) do
    -- Dibujar rectángulo verde oscuro
    -- Hack: batch.draw no tiene color, pero los shaders suelen multiplicar.
    -- Como nuestro shader básico usa color vertex attribute = 1,1,1,1 (blanco),
    -- esto saldrá blanco. Para debug es suficiente.
    batch.draw(tex, block.x, block.y, 0, 0, block.w, block.h, false)
    end
    end

    return level
