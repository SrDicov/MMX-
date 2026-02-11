#include "../engine.hpp"

// Cargar textura desde archivo (usando SDL_image)
GLuint load_texture(const char* path, int* w, int* h) {
    SDL_Surface* surface = IMG_Load(path);
    if (!surface) {
        std::cerr << "[TEXTURE] Error cargando " << path << ": " << IMG_GetError() << std::endl;
        return 0;
    }

    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);

    // Configuración Pixel-Art (Nearest Neighbor)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    // Determinar formato (RGB o RGBA)
    GLenum mode = GL_RGB;
    if (surface->format->BytesPerPixel == 4) mode = GL_RGBA;

    glTexImage2D(GL_TEXTURE_2D, 0, mode, surface->w, surface->h, 0, mode, GL_UNSIGNED_BYTE, surface->pixels);

    if (w) *w = surface->w;
    if (h) *h = surface->h;

    SDL_FreeSurface(surface);
    return textureID;
}
