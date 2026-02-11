#ifndef ENGINE_HPP
#define ENGINE_HPP

// --- CRÍTICO: Habilita funciones modernas de OpenGL (Shaders, VBOs, VAOs) ---
#define GL_GLEXT_PROTOTYPES

#include <SDL2/SDL.h>
#include <SDL2/SDL_opengl.h>
#include <SDL2/SDL_mixer.h>
#include <SDL2/SDL_image.h> // <--- ESTA ERA LA LÍNEA FALTANTE
#include <lua.hpp>
#include <map>
#include <string>
#include <iostream>
#include <vector>
#include <cmath>

// Resolución Interna (SNES Standard)
const int INTERNAL_W = 256;
const int INTERNAL_H = 224;

struct EngineState {
    SDL_Window* window = nullptr;
    SDL_GLContext gl_context = nullptr;
    lua_State* L = nullptr;
    bool running = true;
    bool debug_mode = true;

    // Control de Tiempo
    double accumulator = 0.0;
    const double MS_PER_UPDATE = 1.0 / 60.0;
    double delta_time = 0.0;
    Uint64 last_tick = 0;

    // Audio
    std::map<std::string, Mix_Chunk*> sfx_cache;
    Mix_Music* current_music = nullptr;

    // Input
    SDL_GameController* controller = nullptr;
};

// ... (includes y structs previos)

extern EngineState engine;

// --- Funciones de Renderizado (Renderer API) ---
void init_renderer();
void flush_batch();
void draw_sprite(GLuint texture, float x, float y, float w, float h,
                 float u0, float v0, float u1, float v1,
                 float r, float g, float b, float a);
void set_camera(float x, float y);

// Funciones de Textura
GLuint load_texture(const char* path, int* w, int* h);

#endif
