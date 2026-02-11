local config = {}

config.system = {
    width = 256,
    height = 224,
    scale = 4,
    vsync = true,
    fps_limit = 60,
    title = "Mega Man X++ Test"
}

config.input = {
    keys = {
        up = "up", down = "down", left = "left", right = "right",
        jump = "z", shoot = "x", dash = "c",
        start = "enter", select = "rshift", debug = "f1", reset = "f5"
    }
}

-- VALORES EXACTOS DE MEGA MAN X (SNES)
-- Extraídos de TASVideos y Romhacking docs
-- Unidades: Píxeles por Frame (px/f)
config.physics = {
    gravity = 0.25,          -- Gravedad estándar (0x40 subpixels)

    -- Suelo
    walk_speed = 1.296875,   -- Aprox 1.3 (0x014C subpixels)
    dash_speed = 3.5,        -- Velocidad constante de dash (0x0380 subpixels)

    -- Aire
    jump_force = 4.875,      -- Fuerza inicial de salto (0x04E0 subpixels)
    dash_jump_mult = 1.0,    -- Dash Jump conserva la velocidad del dash (3.5)
    term_vel = 5.75,         -- Velocidad terminal de caída (0x05C0 subpixels)

    -- Paredes
    wall_slide_speed = 0.75, -- Velocidad máxima deslizamiento (0x00C0 subpixels)

    -- Wall Kick (El "Salto de Pared")
    -- En MMX, el Wall Kick te empuja hacia arriba y hacia afuera.
    wall_kick_x = 3.5,       -- Fuerza horizontal al patear (0x0380 subpixels)
    wall_kick_y = 4.0,       -- Fuerza vertical al patear (0x0400 subpixels)

    -- Timers (Frames)
    wall_kick_lock = 8,      -- Tiempo que pierdes control tras wall kick (aprox 8-10 frames)
    hit_invincibility = 60,  -- Tiempo de invencibilidad tras golpe (1 seg)
    hit_knockback_x = 2.0,   -- Empuje horizontal al recibir daño
    hit_knockback_y = 3.0    -- Empuje vertical al recibir daño
}

config.debug = {
    enabled = true,
    show_hitboxes = false
}

return config
