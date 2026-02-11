/**
 * src/bindings/l_sandbox.cpp
 * Módulo de Sandbox: Carga segura de scripts con entornos aislados.
 * Compatible con LuaJIT (Lua 5.1)
 */

#include "../engine.hpp"

// Helper: Crea una nueva tabla y la configura para heredar de _G (Global)
static void create_sandbox_env(lua_State* L) {
    lua_newtable(L);                // 1. La tabla del entorno (env)
    lua_newtable(L);                // 2. La metatabla (mt)

    // --- CORRECCIÓN LUAJIT (Lua 5.1) ---
    // En lugar de lua_pushglobaltable(L), usamos LUA_GLOBALSINDEX
    lua_pushvalue(L, LUA_GLOBALSINDEX);

    lua_setfield(L, -2, "__index"); // mt.__index = _G

    lua_setmetatable(L, -2);        // setmetatable(env, mt)
}

// sandbox.loadfile(filename)
static int l_sandbox_loadfile(lua_State* L) {
    const char* filename = luaL_checkstring(L, 1);

    if (luaL_loadfile(L, filename) != LUA_OK) {
        lua_pushnil(L);
        lua_pushnil(L);
        lua_pushvalue(L, -3);
        return 3;
    }

    create_sandbox_env(L);

    // Lua 5.1 usa setfenv
    lua_pushvalue(L, -1);
    lua_setfenv(L, -3);

    lua_pushvalue(L, -1);
    lua_pushvalue(L, -3);

    return 2;
}

// sandbox.dofile(filename)
static int l_sandbox_dofile(lua_State* L) {
    const char* filename = luaL_checkstring(L, 1);

    if (luaL_loadfile(L, filename) != LUA_OK) {
        lua_pushnil(L);
        lua_pushvalue(L, -2);
        return 2;
    }

    create_sandbox_env(L);
    lua_pushvalue(L, -1);
    lua_setfenv(L, -3);

    if (lua_pcall(L, 0, 0, 0) != LUA_OK) {
        lua_pushnil(L);
        lua_pushvalue(L, -2);
        return 2;
    }

    return 1;
}

static const luaL_Reg sandbox_lib[] = {
    {"loadfile", l_sandbox_loadfile},
    {"dofile", l_sandbox_dofile},
    {NULL, NULL}
};

int luaopen_sandbox(lua_State* L) {
    luaL_newlib(L, sandbox_lib);
    return 1;
}
