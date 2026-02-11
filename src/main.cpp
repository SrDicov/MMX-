/**
 * src/main.cpp
 * Punto de entrada definitivo del Motor MMX++
 * Compatible con LuaJIT (Lua 5.1)
 *
 * Versión final – SIN GLEW (usa GL_GLEXT_PROTOTYPES)
 * Incluye: SDL2, SDL_image (PNG), SDL_mixer, Lua, OpenGL 3.3 Core
 * Renderer: init_renderer() en subsistemas, módulo graphics registrado
 */

#include "engine.hpp"          // engine.hpp debe definir GL_GLEXT_PROTOTYPES
#include <SDL2/SDL_image.h>    // Carga de PNG
#include <iostream>

// Instancia global del motor
EngineState engine;

// Declaraciones forward de los módulos Lua (bindings)
// SIN extern "C" – se compilan como C++
int luaopen_util(lua_State* L);
int luaopen_input(lua_State* L);
int luaopen_audio(lua_State* L);
int luaopen_graphics(lua_State* L);   // <-- NUEVO: módulo de gráficos

// --- POLYFILL luaL_requiref (LuaJIT / Lua 5.1) ---
void luaL_requiref(lua_State *L, const char *modname, lua_CFunction openf, int glb) {
    lua_pushcfunction(L, openf);
    lua_pushstring(L, modname);
    lua_call(L, 1, 1);                // openf(modname) → tabla del módulo

    lua_getfield(L, LUA_REGISTRYINDEX, "_LOADED");
    lua_pushvalue(L, -2);             // copia del módulo
    lua_setfield(L, -2, modname);    // _LOADED[modname] = módulo
    lua_pop(L, 1);                   // sacar _LOADED

    if (glb) {
        lua_pushvalue(L, -1);        // copia del módulo
        lua_setglobal(L, modname);   // _G[modname] = módulo
    }
    // El módulo permanece en la cima de la pila (como en Lua 5.2+)
}

// --- Manejador de pánico Lua ---
int l_panic(lua_State* L) {
    const char* err = lua_tostring(L, -1);
    std::cerr << "\n========================================\n";
    std::cerr << "!!! LUA PANIC !!!\n";
    std::cerr << "Error: " << (err ? err : "desconocido") << "\n";
    std::cerr << "========================================\n";
    engine.running = false;
    return 0;
}

// --- Inicialización de subsistemas ---
bool init_subsystems() {
    // 1. SDL2 (video, audio, gamecontroller)
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_GAMECONTROLLER) < 0) {
        std::cerr << "[FATAL] SDL Error: " << SDL_GetError() << std::endl;
        return false;
    }

    // 2. SDL_image (PNG)
    int imgFlags = IMG_INIT_PNG;
    if (!(IMG_Init(imgFlags) & imgFlags)) {
        std::cerr << "[FATAL] SDL_image Error: " << IMG_GetError() << std::endl;
        return false;
    }

    // 3. Configurar OpenGL 3.3 Core
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

    // 4. Ventana
    engine.window = SDL_CreateWindow("Mega Man X++ (Arch Dev)",
                                     SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                                     256 * 3, 224 * 3,
                                     SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);
    if (!engine.window) {
        std::cerr << "[FATAL] Window Error: " << SDL_GetError() << std::endl;
        return false;
    }

    // 5. Contexto OpenGL
    engine.gl_context = SDL_GL_CreateContext(engine.window);
    if (!engine.gl_context) {
        std::cerr << "[FATAL] OpenGL Context Error: " << SDL_GetError() << std::endl;
        return false;
    }

    // 6. VSync
    SDL_GL_SetSwapInterval(1);

    // 7. Inicializar sistema de renderizado (batch, shaders, buffers)
    init_renderer();

    // 8. SDL_mixer (audio)
    if (Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 2048) < 0) {
        std::cerr << "[ERROR] Mixer Error: " << Mix_GetError() << std::endl;
        // No detenemos el motor, solo se desactiva el audio
    }
    Mix_AllocateChannels(32);

    // 9. Gamepad (primer mando compatible)
    engine.controller = nullptr;
    for (int i = 0; i < SDL_NumJoysticks(); ++i) {
        if (SDL_IsGameController(i)) {
            engine.controller = SDL_GameControllerOpen(i);
            if (engine.controller) {
                std::cout << "[INPUT] Mando conectado: "
                << SDL_GameControllerName(engine.controller) << std::endl;
                break;
            }
        }
    }

    return true;
}

// --- Inicialización de Lua y carga de módulos nativos ---
bool init_lua() {
    engine.L = luaL_newstate();
    if (!engine.L) return false;

    luaL_openlibs(engine.L);

    // Registrar manejador de pánico
    lua_atpanic(engine.L, l_panic);
    lua_pushcfunction(engine.L, l_panic);
    lua_setglobal(engine.L, "panic");

    // Cargar módulos nativos con luaL_requiref (registro en _LOADED y global)
    luaL_requiref(engine.L, "util",   luaopen_util,   1);
    lua_pop(engine.L, 1);
    luaL_requiref(engine.L, "input",  luaopen_input,  1);
    lua_pop(engine.L, 1);
    luaL_requiref(engine.L, "audio",  luaopen_audio,  1);
    lua_pop(engine.L, 1);
    // Módulo de gráficos (batch + texture)
    luaL_requiref(engine.L, "graphics", luaopen_graphics, 1);
    lua_pop(engine.L, 1);

    // Inicializar cachés de audio
    engine.current_music = nullptr;
    engine.sfx_cache.clear();

    return true;
}

// --- Bucle principal con timestep fijo (60 FPS lógicos) ---
void run_loop() {
    SDL_Event e;
    engine.last_tick = SDL_GetPerformanceCounter();
    engine.accumulator = 0.0;
    double perf_freq = (double)SDL_GetPerformanceFrequency();

    while (engine.running) {
        // Tiempo transcurrido
        Uint64 current_tick = SDL_GetPerformanceCounter();
        double frame_time = (double)(current_tick - engine.last_tick) / perf_freq;
        engine.last_tick = current_tick;

        // Espiral de la muerte (máx 0.25s)
        if (frame_time > 0.25) frame_time = 0.25;

        engine.accumulator += frame_time;

        // Eventos SDL
        while (SDL_PollEvent(&e) != 0) {
            if (e.type == SDL_QUIT) engine.running = false;
        }

        // --- Fase de actualización (60 Hz) ---
        while (engine.accumulator >= engine.MS_PER_UPDATE) {
            lua_getglobal(engine.L, "_update");
            if (lua_isfunction(engine.L, -1)) {
                lua_pushnumber(engine.L, engine.MS_PER_UPDATE);
                if (lua_pcall(engine.L, 1, 0, 0) != LUA_OK) {
                    std::cerr << "[UPDATE] " << lua_tostring(engine.L, -1) << std::endl;
                    lua_pop(engine.L, 1);   // sacar error
                    engine.running = false;
                }
            } else {
                lua_pop(engine.L, 1);       // sacar lo que no es función
            }
            engine.accumulator -= engine.MS_PER_UPDATE;
        }

        // --- Fase de renderizado ---
        // alpha (interpolación) reservado para futuro
        // double alpha = engine.accumulator / engine.MS_PER_UPDATE;

        glClearColor(0.1f, 0.1f, 0.15f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);

        lua_getglobal(engine.L, "_draw");
        if (lua_isfunction(engine.L, -1)) {
            if (lua_pcall(engine.L, 0, 0, 0) != LUA_OK) {
                std::cerr << "[DRAW] " << lua_tostring(engine.L, -1) << std::endl;
                lua_pop(engine.L, 1);       // sacar error
                // No detenemos el motor por errores de dibujo
            }
        } else {
            lua_pop(engine.L, 1);           // sacar valor que no es función
        }

        SDL_GL_SwapWindow(engine.window);
    }
}

// --- Limpieza de recursos ---
void cleanup() {
    if (engine.L) lua_close(engine.L);

    // Audio cache
    for (auto const& [path, chunk] : engine.sfx_cache) {
        Mix_FreeChunk(chunk);
    }
    if (engine.current_music) Mix_FreeMusic(engine.current_music);
    Mix_CloseAudio();

    // Game controller
    if (engine.controller) SDL_GameControllerClose(engine.controller);

    // OpenGL y ventana
    SDL_GL_DeleteContext(engine.gl_context);
    SDL_DestroyWindow(engine.window);

    // SDL_image y SDL
    IMG_Quit();
    SDL_Quit();
}

// --- Punto de entrada ---
int main(int argc, char* argv[]) {
    if (!init_subsystems()) return 1;
    if (!init_lua()) return 1;

    // Script de arranque (por defecto o pasado por argumento)
    std::string boot_script = "scripts/main.lua";
    if (argc > 1) boot_script = argv[1];

    if (luaL_dofile(engine.L, boot_script.c_str()) != LUA_OK) {
        std::cerr << "[LUA ERROR] " << lua_tostring(engine.L, -1) << std::endl;
        return 1;
    }

    // Llamar a _init() si existe
    lua_getglobal(engine.L, "_init");
    if (lua_isfunction(engine.L, -1)) {
        if (lua_pcall(engine.L, 0, 0, 0) != LUA_OK) {
            std::cerr << "[LUA _init] " << lua_tostring(engine.L, -1) << std::endl;
            lua_pop(engine.L, 1);
            return 1;
        }
    } else {
        lua_pop(engine.L, 1);
    }

    // ¡Arrancar el motor!
    engine.running = true;
    run_loop();

    cleanup();
    return 0;
}
