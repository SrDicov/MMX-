#include "../engine.hpp"

// Mapeo simple de Scancodes (Teclado) a Botones (Gamepad)
static int map_key_to_button(int scancode) {
    switch (scancode) {
        case SDL_SCANCODE_Z:     return SDL_CONTROLLER_BUTTON_A;
        case SDL_SCANCODE_X:     return SDL_CONTROLLER_BUTTON_X;
        case SDL_SCANCODE_C:     return SDL_CONTROLLER_BUTTON_B;
        case SDL_SCANCODE_UP:    return SDL_CONTROLLER_BUTTON_DPAD_UP;
        case SDL_SCANCODE_DOWN:  return SDL_CONTROLLER_BUTTON_DPAD_DOWN;
        case SDL_SCANCODE_LEFT:  return SDL_CONTROLLER_BUTTON_DPAD_LEFT;
        case SDL_SCANCODE_RIGHT: return SDL_CONTROLLER_BUTTON_DPAD_RIGHT;
        case SDL_SCANCODE_RETURN: return SDL_CONTROLLER_BUTTON_START;
        default: return -1;
    }
}

// Lua: input.is_down(scancode)
static int l_is_down(lua_State* L) {
    int key = luaL_checkinteger(L, 1);

    // 1. Chequear Teclado
    const Uint8* state = SDL_GetKeyboardState(NULL);
    bool down = state[key];

    // 2. Chequear Mando (si no se pulsó en teclado)
    if (!down && engine.controller) {
        int btn = map_key_to_button(key);
        if (btn != -1) {
            down = SDL_GameControllerGetButton(engine.controller, (SDL_GameControllerButton)btn);
        }
    }

    lua_pushboolean(L, down);
    return 1;
}

// Array de funciones a registrar
static const struct luaL_Reg input_lib[] = {
    {"is_down", l_is_down}, // <--- ESTA LÍNEA ES CRÍTICA
    {NULL, NULL}
};

// Función de apertura del módulo
int luaopen_input(lua_State* L) {
    std::cout << "[DEBUG] Registrando modulo 'input'..." << std::endl;
    luaL_register(L, "input", input_lib);
    return 1;
}
