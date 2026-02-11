/**
 * src/engine.hpp
 * Cabecera Global del Motor MMX++
 * Define constantes, macros y declaraciones de módulos.
 */
#pragma once

// Inclusiones estándar
#include <iostream>
#include <string>
#include <vector>

// Dependencias Externas
#include <GL/glew.h>
#include <SDL2/SDL.h>
#include <SDL2/SDL_opengl.h>
#include <lua.hpp>

// --- Configuración del Motor ---
#define ENGINE_NAME "Mega Man X++ [Dev]"
#define ENGINE_VERSION "0.1.0-alpha"

// Resolución interna (SNES NTSC)
constexpr int INTERNAL_W = 256;
constexpr int INTERNAL_H = 224;

// Resolución de ventana (Escala inicial 3x)
constexpr int WINDOW_W = INTERNAL_W * 3;
constexpr int WINDOW_H = INTERNAL_H * 3;

// --- Gestor de Estado Global (Singleton Simplificado) ---
struct EngineState {
    SDL_Window* window = nullptr;
    SDL_GLContext gl_context = nullptr;
    lua_State* L = nullptr;
    bool running = true;
    bool debug_mode = true;

    // Control de tiempo
    double delta_time = 0.0;
    Uint64 last_tick = 0;
};

// Acceso global (definido en main.cpp)
extern EngineState engine;

// --- Declaración de Bindings (Módulos C++ -> Lua) ---
// Estos son los módulos que Lua podrá cargar con require() o usar globalmente
extern "C" {
    int luaopen_input(lua_State* L);
    int luaopen_console(lua_State* L);
    int luaopen_util(lua_State* L);
    int luaopen_sandbox(lua_State* L);

    // --- NUEVOS MÓDULOS GRÁFICOS ---
    int luaopen_batch(lua_State* L);   // Sistema de dibujado
    int luaopen_texture(lua_State* L); // Gestor de texturas

    int l_panic(lua_State* L);
}

// Helpers
void engine_log(const std::string& msg);
void engine_error(const std::string& msg);
