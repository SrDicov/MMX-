-- ============================================================================
-- MMX++ ENGINE - FINAL
-- ============================================================================

util = require("scripts.core.util")
local sched = require("scripts.core.sched")
local config = require("scripts.config")
local camera = require("scripts.objects.camera").instance
local Player = require("scripts.objects.player")
local Level = require("scripts.objects.level_parkour")
local hud = require("scripts.ui.hud")

batch.init()
console.set_title("Mega Man X++ [Parkour Edition]")
console.log("System Online: " .. util.os())

Level.load()

-- Spawneamos al jugador
local p_pid, p_ent = sched.spawn(Player, {x=50, y=100})
_G.player_instance = p_ent
console.log("Player Ready.")

function _update(dt)
sched.update(dt)
camera:update()
end

function _draw()
batch.begin_draw()

-- 1. Mundo
Level.draw()
sched.draw()

-- 2. UI (HUD Estático)
hud.draw_static(_G.player_instance)

batch.end_draw()
end
