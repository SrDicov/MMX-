#include "../engine.hpp"
#include <SDL2/SDL_mixer.h>

// Función auxiliar local para reutilizar lógica de caché
static Mix_Chunk* get_chunk(const char* path) {
    std::string s_path = path;
    auto it = engine.sfx_cache.find(s_path);

    // Si está en caché, devolverlo
    if (it != engine.sfx_cache.end()) {
        return it->second;
    }

    // Si no, cargar, cachear y devolver
    Mix_Chunk* chunk = Mix_LoadWAV(path);
    if (chunk) {
        engine.sfx_cache[s_path] = chunk;
    } else {
        std::cerr << "[LUA AUDIO] Error cargando SFX: " << path << " -> " << Mix_GetError() << std::endl;
    }
    return chunk;
}

// Lua: audio.play_sfx(path)
static int l_play_sfx(lua_State* L) {
    const char* path = luaL_checkstring(L, 1);

    Mix_Chunk* chunk = get_chunk(path);
    if (chunk) {
        // Canal -1 (automático), loop 0 (reproducir 1 vez)
        Mix_PlayChannel(-1, chunk, 0);
    }

    return 0;
}

// Lua: audio.play_music(path, loop)
static int l_play_music(lua_State* L) {
    const char* path = luaL_checkstring(L, 1);
    bool loop = lua_toboolean(L, 2);

    // Detener y liberar música anterior si existe
    if (engine.current_music) {
        Mix_HaltMusic();
        Mix_FreeMusic(engine.current_music);
        engine.current_music = nullptr;
    }

    engine.current_music = Mix_LoadMUS(path);
    if (engine.current_music) {
        // SDL_mixer: -1 para loop infinito, 1 para reproducir una vez
        Mix_PlayMusic(engine.current_music, loop ? -1 : 1);
    } else {
        std::cerr << "[LUA AUDIO] Error cargando Musica: " << path << " -> " << Mix_GetError() << std::endl;
    }

    return 0;
}

// Lua: audio.set_volume(vol)
// vol: 0 a 128 (MIX_MAX_VOLUME)
static int l_set_volume(lua_State* L) {
    int vol = luaL_checkinteger(L, 1);
    if (vol < 0) vol = 0;
    if (vol > MIX_MAX_VOLUME) vol = MIX_MAX_VOLUME;

    Mix_Volume(-1, vol);       // Volumen global de SFX
    Mix_VolumeMusic(vol);      // Volumen de Música
    return 0;
}

// Registro de funciones
static const struct luaL_Reg audio_lib[] = {
    {"play_sfx", l_play_sfx},
    {"play_music", l_play_music},
    {"set_volume", l_set_volume},
    {NULL, NULL}
};

// Punto de entrada para registrar la librería
int luaopen_audio(lua_State* L) {
    luaL_register(L, "audio", audio_lib);
    return 1;
}
