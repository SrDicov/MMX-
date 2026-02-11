/**
 * src/main.cpp
 * Punto de entrada definitivo del Motor MMX++
 * Compatible con LuaJIT (Lua 5.1)
 */
#include "engine.hpp"

// Instancia global del estado
EngineState engine;

// --- Helpers de Logging ---
void engine_log(const std::string& msg) {
    std::cout << "[ENGINE] " << msg << std::endl;
}

void engine_error(const std::string& msg) {
    std::cerr << "[FATAL] " << msg << std::endl;
}

// --- POLYFILL LUA 5.1 ---
// Implementación manual de luaL_requiref porque LuaJIT no la tiene.
// Carga un módulo C y lo registra globalmente si se pide.
void luaL_requiref(lua_State *L, const char *modname, lua_CFunction openf, int glb) {
    lua_pushcfunction(L, openf);
    lua_pushstring(L, modname);  // Argumento para la función de carga
    lua_call(L, 1, 1);           // Llama a la función 'openf' -> Retorna el módulo (tabla) en el stack

    // Guardar en package.loaded (_LOADED en el registro)
    lua_getfield(L, LUA_REGISTRYINDEX, "_LOADED");
    lua_pushvalue(L, -2);        // Copia del módulo
    lua_setfield(L, -2, modname); // _LOADED[modname] = module
    lua_pop(L, 1);               // Sacar _LOADED del stack

    // Si glb es true, definir como variable global
    if (glb) {
        lua_pushvalue(L, -1);    // Copia del módulo
        lua_setglobal(L, modname); // _G[modname] = module
    }
    // El módulo original se queda en el stack (como en Lua 5.2)
}

// --- Función Panic (Callback de error para Lua) ---
int l_panic(lua_State* L) {
    const char* err = lua_tostring(L, -1);
    std::cerr << "\n========================================\n";
    std::cerr << "!!! LUA PANIC !!!\n";
    std::cerr << "Error: " << (err ? err : "Unknown") << "\n";
    std::cerr << "========================================\n" << std::endl;
    engine.running = false;
    return 0;
}

// --- Inicialización ---
bool init_subsystems() {
    // 1. SDL
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_EVENTS) < 0) {
        engine_error("SDL Init Failed: " + std::string(SDL_GetError()));
        return false;
    }

    // 2. OpenGL (3.3 Core)
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

    // 3. Ventana
    engine.window = SDL_CreateWindow(
        ENGINE_NAME,
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        WINDOW_W, WINDOW_H,
        SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE
    );

    if (!engine.window) {
        engine_error("Window Creation Failed");
        return false;
    }

    // 4. Contexto GL
    engine.gl_context = SDL_GL_CreateContext(engine.window);
    if (!engine.gl_context) {
        engine_error("GL Context Failed");
        return false;
    }

    // 5. GLEW
    glewExperimental = GL_TRUE;
    if (glewInit() != GLEW_OK) {
        engine_error("GLEW Init Failed");
        return false;
    }

    SDL_GL_SetSwapInterval(1); // VSync
    return true;
}

bool init_lua() {
    engine.L = luaL_newstate();
    if (!engine.L) return false;

    // Cargar librerías estándar
    luaL_openlibs(engine.L);

    // Registrar manejador de pánico
    lua_atpanic(engine.L, l_panic);
    lua_pushcfunction(engine.L, l_panic);
    lua_setglobal(engine.L, "panic");

    // --- CARGAR MÓDULOS C++ (Ahora funciona gracias al Polyfill) ---
    luaL_requiref(engine.L, "input", luaopen_input, 1);
    lua_pop(engine.L, 1);

    luaL_requiref(engine.L, "batch", luaopen_batch, 1);
    lua_pop(engine.L, 1);

    luaL_requiref(engine.L, "texture", luaopen_texture, 1);
    lua_pop(engine.L, 1);

    luaL_requiref(engine.L, "console", luaopen_console, 1);
    lua_pop(engine.L, 1);

    luaL_requiref(engine.L, "util", luaopen_util, 1);
    lua_pop(engine.L, 1);

    luaL_requiref(engine.L, "sandbox", luaopen_sandbox, 1);
    lua_pop(engine.L, 1);

    engine_log("Lua Subsystem Initialized");
    return true;
}

// --- Game Loop ---
void run_loop() {
    SDL_Event e;
    engine.last_tick = SDL_GetPerformanceCounter();

    while (engine.running) {
        // 1. Delta Time
        Uint64 current_tick = SDL_GetPerformanceCounter();
        double dt = (double)((current_tick - engine.last_tick) * 1000 / (double)SDL_GetPerformanceFrequency());
        engine.delta_time = dt / 1000.0;
        engine.last_tick = current_tick;

        if (engine.delta_time > 0.1) engine.delta_time = 0.1;

        // 2. Input
        while (SDL_PollEvent(&e) != 0) {
            if (e.type == SDL_QUIT) {
                engine.running = false;
            }
        }

        // 3. Update (Lua)
        lua_getglobal(engine.L, "_update");
        if (lua_isfunction(engine.L, -1)) {
            lua_pushnumber(engine.L, engine.delta_time);
            if (lua_pcall(engine.L, 1, 0, 0) != LUA_OK) {
                const char* err = lua_tostring(engine.L, -1);
                std::cerr << "[LUA ERROR in update] " << err << std::endl;
                lua_pop(engine.L, 1);
            }
        } else {
            lua_pop(engine.L, 1);
        }

        // 4. Draw (Lua)
        glClearColor(0.1f, 0.1f, 0.15f, 1.0f); // Fondo oscuro
        glClear(GL_COLOR_BUFFER_BIT);

        lua_getglobal(engine.L, "_draw");
        if (lua_isfunction(engine.L, -1)) {
            if (lua_pcall(engine.L, 0, 0, 0) != LUA_OK) {
                const char* err = lua_tostring(engine.L, -1);
                std::cerr << "[LUA ERROR in draw] " << err << std::endl;
                lua_pop(engine.L, 1);
            }
        } else {
            lua_pop(engine.L, 1);
        }

        SDL_GL_SwapWindow(engine.window);
    }
}

// --- Main ---
int main(int argc, char* argv[]) {
    engine_log("Booting System...");

    if (!init_subsystems()) return 1;
    if (!init_lua()) return 1;

    // Cargar Script de Arranque
    std::string boot_script = "scripts/main.lua";
    if (argc > 1) boot_script = argv[1];

    if (luaL_dofile(engine.L, boot_script.c_str()) != LUA_OK) {
        const char* err = lua_tostring(engine.L, -1);
        engine_error("Failed to load boot script: " + std::string(err));
        return 1;
    }

    engine_log("Entering Game Loop");
    run_loop();

    // Cleanup
    lua_close(engine.L);
    SDL_DestroyWindow(engine.window);
    SDL_Quit();

    return 0;
}
