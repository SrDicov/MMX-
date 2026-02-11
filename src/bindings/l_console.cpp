/**
 * src/bindings/l_console.cpp
 * Backend de la Consola: Salida estándar, logs y ejecución dinámica.
 */

#include "../engine.hpp"
#include <sstream>

// Códigos de color ANSI para terminal Linux (Garuda/Arch)
#define COLOR_RESET   "\033[0m"
#define COLOR_CYAN    "\033[36m"
#define COLOR_YELLOW  "\033[33m"
#define COLOR_RED     "\033[31m"
#define COLOR_GREEN   "\033[32m"

// console.log(...)
// Imprime mensajes en la terminal estándar (stdout)
// Acepta múltiples argumentos como print()
static int l_console_log(lua_State* L) {
    int n = lua_gettop(L);  // Número de argumentos
    lua_getglobal(L, "tostring");

    std::cout << COLOR_CYAN << "[LUA] " << COLOR_RESET;

    for (int i = 1; i <= n; i++) {
        lua_pushvalue(L, -1);  // Push tostring
        lua_pushvalue(L, i);   // Push argumento actual
        lua_call(L, 1, 1);     // Llama a tostring(arg)

        const char* s = lua_tostring(L, -1);
        if (s == NULL) return luaL_error(L, "'tostring' must return a string to print");

        if (i > 1) std::cout << "\t";
        std::cout << s;

        lua_pop(L, 1);  // Pop resultado
    }

    std::cout << std::endl;
    lua_pop(L, 1);  // Pop tostring function
    return 0;
}

// console.error(...)
// Imprime errores en stderr (Rojo)
static int l_console_error(lua_State* L) {
    int n = lua_gettop(L);
    lua_getglobal(L, "tostring");

    std::cerr << COLOR_RED << "[ERROR] ";

    for (int i = 1; i <= n; i++) {
        lua_pushvalue(L, -1);
        lua_pushvalue(L, i);
        lua_call(L, 1, 1);

        const char* s = lua_tostring(L, -1);
        if (s) std::cerr << s << " ";
        lua_pop(L, 1);
    }

    std::cerr << COLOR_RESET << std::endl;
    lua_pop(L, 1);
    return 0;
}

// console.execute(cmd_string)
// Ejecuta una cadena de texto como código Lua (backend para el input de consola)
// Retorna: success (bool), error_msg (string o nil)
static int l_console_execute(lua_State* L) {
    const char* cmd = luaL_checkstring(L, 1);

    // Intentar cargar el string como chunk
    if (luaL_loadstring(L, cmd) != LUA_OK) {
        // Error de sintaxis
        lua_pushboolean(L, false);
        lua_pushvalue(L, -2); // Mensaje de error
        return 2;
    }

    // Ejecutar (pcall)
    if (lua_pcall(L, 0, 0, 0) != LUA_OK) {
        // Error de ejecución
        lua_pushboolean(L, false);
        lua_pushvalue(L, -2); // Mensaje de error
        return 2;
    }

    // Éxito
    lua_pushboolean(L, true);
    return 1;
}

// console.set_title(str)
// Cambia el título de la ventana (Útil para mostrar FPS o estado)
static int l_console_set_title(lua_State* L) {
    const char* title = luaL_checkstring(L, 1);
    if (engine.window) {
        SDL_SetWindowTitle(engine.window, title);
    }
    return 0;
}

// Registro del módulo
static const luaL_Reg console_lib[] = {
    {"log", l_console_log},
    {"error", l_console_error},
    {"execute", l_console_execute},
    {"set_title", l_console_set_title},
    {NULL, NULL}
};

int luaopen_console(lua_State* L) {
    luaL_newlib(L, console_lib);
    return 1;
}
