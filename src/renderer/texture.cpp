#include "../engine.hpp"
#include <SDL2/SDL_image.h>
#include <unordered_map>
#include <vector>

static std::unordered_map<std::string, GLuint> texture_cache;

// Textura blanca 1x1 para dibujar rectángulos sólidos
GLuint WHITE_TEXTURE_ID = 0;

void create_white_texture() {
    glGenTextures(1, &WHITE_TEXTURE_ID);
    glBindTexture(GL_TEXTURE_2D, WHITE_TEXTURE_ID);
    unsigned char pixel[] = {255, 255, 255, 255};
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixel);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
}

static int l_texture_load(lua_State* L) {
    const char* filename = luaL_checkstring(L, 1);

    if (texture_cache.find(filename) != texture_cache.end()) {
        lua_pushinteger(L, texture_cache[filename]);
        return 1;
    }

    SDL_Surface* surface = IMG_Load(filename);
    if (!surface) {
        // FALLBACK: Si no encuentra la imagen, retorna la textura blanca y avisa
        // Esto evita que el juego crashee por falta de assets
        std::cerr << "[TEXTURE WARNING] Missing: " << filename << ". Using fallback." << std::endl;
        lua_pushinteger(L, WHITE_TEXTURE_ID);
        return 1;
    }

    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    GLenum mode = (surface->format->BytesPerPixel == 4) ? GL_RGBA : GL_RGB;
    glTexImage2D(GL_TEXTURE_2D, 0, mode, surface->w, surface->h, 0, mode, GL_UNSIGNED_BYTE, surface->pixels);

    SDL_FreeSurface(surface);
    texture_cache[filename] = textureID;

    lua_pushinteger(L, textureID);
    return 1;
}

// texture.white() -> retorna el ID de la textura blanca
static int l_texture_white(lua_State* L) {
    lua_pushinteger(L, WHITE_TEXTURE_ID);
    return 1;
}

int luaopen_texture(lua_State* L) {
    // Inicializar la textura blanca al cargar el módulo
    create_white_texture();

    luaL_Reg regs[] = {
        {"load", l_texture_load},
        {"white", l_texture_white},
        {NULL, NULL}
    };
    luaL_newlib(L, regs);
    return 1;
}
