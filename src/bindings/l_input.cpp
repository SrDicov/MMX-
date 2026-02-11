#include "../engine.hpp"
#include <string>
#include <unordered_map>
#include <iostream>

// Mapa de teclas: String de Lua -> Scancode de SDL
// Esto permite que en Lua escribas input.down("jump") o input.down("z")
static std::unordered_map<std::string, SDL_Scancode> key_map = {
    {"up", SDL_SCANCODE_UP},
    {"down", SDL_SCANCODE_DOWN},
    {"left", SDL_SCANCODE_LEFT},
    {"right", SDL_SCANCODE_RIGHT},
    {"z", SDL_SCANCODE_Z},         // Dash / Jump
    {"x", SDL_SCANCODE_X},         // Shoot
    {"c", SDL_SCANCODE_C},         // Special
    {"enter", SDL_SCANCODE_RETURN}, // Start
    {"escape", SDL_SCANCODE_ESCAPE},
    {"space", SDL_SCANCODE_SPACE}
};

// input.down(key_name)
// Retorna true si la tecla está presionada en este frame
static int l_input_down(lua_State* L) {
    const char* key_name = luaL_checkstring(L, 1);

    // Buscar la tecla en nuestro mapa
    auto it = key_map.find(key_name);
    if (it == key_map.end()) {
        // Si no conocemos la tecla, retornamos false (o podríamos lanzar error)
        lua_pushboolean(L, false);
        return 1;
    }

    // Leer estado real de SDL
    const Uint8* state = SDL_GetKeyboardState(NULL);
    bool is_down = state[it->second];

    lua_pushboolean(L, is_down);
    return 1;
}

// input.quit()
// Helper para cerrar el juego desde Lua (útil para desarrollo)
static int l_input_quit(lua_State* L) {
    SDL_Event quit_event;
    quit_event.type = SDL_QUIT;
    SDL_PushEvent(&quit_event);
    return 0;
}

// Registro de la librería 'input'
static const luaL_Reg input_lib[] = {
    {"down", l_input_down},
    {"quit", l_input_quit},
    {NULL, NULL}
};

int luaopen_input(lua_State* L) {
    luaL_newlib(L, input_lib);
    return 1;
}
