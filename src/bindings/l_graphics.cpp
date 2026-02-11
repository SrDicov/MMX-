#include "../engine.hpp"

// Lua: batch.draw(tex_id, x, y, w, h, u0, v0, u1, v1)
// Simplificado: opcionalmente color r,g,b,a
static int l_batch_draw(lua_State* L) {
    // Argumentos obligatorios
    GLuint tex = (GLuint)luaL_checkinteger(L, 1);
    float x = luaL_checknumber(L, 2);
    float y = luaL_checknumber(L, 3);
    float w = luaL_checknumber(L, 4);
    float h = luaL_checknumber(L, 5);
    float u0 = luaL_checknumber(L, 6);
    float v0 = luaL_checknumber(L, 7);
    float u1 = luaL_checknumber(L, 8);
    float v1 = luaL_checknumber(L, 9);

    // Opcionales (Color), default blanco
    float r = 1.0f, g = 1.0f, b = 1.0f, a = 1.0f;
    if (lua_gettop(L) >= 13) {
        r = luaL_checknumber(L, 10);
        g = luaL_checknumber(L, 11);
        b = luaL_checknumber(L, 12);
        a = luaL_checknumber(L, 13);
    }

    draw_sprite(tex, x, y, w, h, u0, v0, u1, v1, r, g, b, a);
    return 0;
}

// Lua: batch.set_camera(x, y)
static int l_batch_set_camera(lua_State* L) {
    float x = luaL_checknumber(L, 1);
    float y = luaL_checknumber(L, 2);
    set_camera(x, y);
    return 0;
}

// Lua: batch.flush()
static int l_batch_flush(lua_State* L) {
    flush_batch();
    return 0;
}

// Lua: texture.load(path) -> id, width, height
static int l_texture_load(lua_State* L) {
    const char* path = luaL_checkstring(L, 1);
    int w, h;
    GLuint id = load_texture(path, &w, &h);

    if (id == 0) {
        lua_pushnil(L);
        lua_pushstring(L, "Error loading texture");
        return 2;
    }

    lua_pushinteger(L, id);
    lua_pushinteger(L, w);
    lua_pushinteger(L, h);
    return 3;
}

// Registro de librerías
static const struct luaL_Reg batch_lib[] = {
    {"draw", l_batch_draw},
    {"flush", l_batch_flush},
    {"set_camera", l_batch_set_camera},
    {NULL, NULL}
};

static const struct luaL_Reg texture_lib[] = {
    {"load", l_texture_load},
    {NULL, NULL}
};

int luaopen_graphics(lua_State* L) {
    // Registrar 'batch' global
    luaL_register(L, "batch", batch_lib);

    // Registrar 'texture' global
    luaL_register(L, "texture", texture_lib);
    return 1;
}
