/**
 * src/bindings/l_util.cpp
 * Utilidades de Sistema: Tiempo, Plataforma y herramientas de bajo nivel.
 */

#include "../engine.hpp"

// util.ticks()
// Retorna los milisegundos transcurridos desde que inició el motor (SDL_GetTicks)
// Útil para temporizadores o sincronización no crítica.
static int l_util_ticks(lua_State* L) {
    lua_pushinteger(L, SDL_GetTicks());
    return 1;
}

// util.time()
// Retorna el tiempo en segundos con alta precisión (double).
// Útil para profiling o cálculos físicos independientes del frame.
static int l_util_time(lua_State* L) {
    Uint64 counter = SDL_GetPerformanceCounter();
    Uint64 freq = SDL_GetPerformanceFrequency();
    lua_pushnumber(L, (double)counter / (double)freq);
    return 1;
}

// util.os()
// Retorna el nombre del Sistema Operativo ("Windows", "Linux", "Mac OS X", etc.)
static int l_util_os(lua_State* L) {
    lua_pushstring(L, SDL_GetPlatform());
    return 1;
}

// util.file_exists(path)
// Verifica si un archivo existe en el disco.
static int l_util_file_exists(lua_State* L) {
    const char* filename = luaL_checkstring(L, 1);
    SDL_RWops* file = SDL_RWFromFile(filename, "r");
    if (file) {
        SDL_RWclose(file);
        lua_pushboolean(L, true);
    } else {
        lua_pushboolean(L, false);
    }
    return 1;
}

// Registro del módulo
static const luaL_Reg util_lib[] = {
    {"ticks", l_util_ticks},
    {"time", l_util_time},
    {"os", l_util_os},
    {"file_exists", l_util_file_exists},
    {NULL, NULL}
};

int luaopen_util(lua_State* L) {
    luaL_newlib(L, util_lib);
    return 1;
}
