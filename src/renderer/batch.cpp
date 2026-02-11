#include "../engine.hpp"
#include <vector>

// --- CONSTANTES ---
const int MAX_QUADS = 1000; // Máximos sprites por draw call
const int MAX_VERTICES = MAX_QUADS * 4;
const int MAX_INDICES = MAX_QUADS * 6;

// --- SHADERS (GLSL) ---
const char* VERTEX_SOURCE = R"(
    #version 330 core
    layout (location = 0) in vec2 aPos;
    layout (location = 1) in vec2 aTexCoord;
    layout (location = 2) in vec4 aColor;

    out vec2 TexCoord;
    out vec4 Color;

    uniform mat4 projection;

    void main() {
        gl_Position = projection * vec4(aPos, 0.0, 1.0);
        TexCoord = aTexCoord;
        Color = aColor;
    }
)";

const char* FRAGMENT_SOURCE = R"(
    #version 330 core
    out vec4 FragColor;

    in vec2 TexCoord;
    in vec4 Color;

    uniform sampler2D image;

    void main() {
        FragColor = texture(image, TexCoord) * Color;
    }
)";

// --- ESTRUCTURAS ---
struct Vertex {
    float x, y;
    float u, v;
    float r, g, b, a;
};

// --- ESTADO INTERNO ---
struct BatchState {
    GLuint VAO, VBO, EBO;
    GLuint shaderProgram;
    GLuint currentTexture = 0;

    std::vector<Vertex> vertices;
    int indexCount = 0;
} batch;

// Compilar Shader Helper
GLuint compileShader(GLenum type, const char* source) {
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &source, NULL);
    glCompileShader(shader);

    // Check errores
    int success;
    char infoLog[512];
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(shader, 512, NULL, infoLog);
        std::cerr << "[SHADER ERROR] " << infoLog << std::endl;
    }
    return shader;
}

// Inicializar Render (Llamado una vez al inicio)
void init_renderer() {
    // 1. Shaders
    GLuint vertex = compileShader(GL_VERTEX_SHADER, VERTEX_SOURCE);
    GLuint fragment = compileShader(GL_FRAGMENT_SHADER, FRAGMENT_SOURCE);
    batch.shaderProgram = glCreateProgram();
    glAttachShader(batch.shaderProgram, vertex);
    glAttachShader(batch.shaderProgram, fragment);
    glLinkProgram(batch.shaderProgram);
    glDeleteShader(vertex);
    glDeleteShader(fragment);

    // 2. Buffers
    glGenVertexArrays(1, &batch.VAO);
    glGenBuffers(1, &batch.VBO);
    glGenBuffers(1, &batch.EBO);

    glBindVertexArray(batch.VAO);

    glBindBuffer(GL_ARRAY_BUFFER, batch.VBO);
    // Reservamos memoria dinámica
    glBufferData(GL_ARRAY_BUFFER, MAX_VERTICES * sizeof(Vertex), nullptr, GL_DYNAMIC_DRAW);

    // EBO (Indices constantes para Quads)
    unsigned int indices[MAX_INDICES];
    int offset = 0;
    for (int i = 0; i < MAX_INDICES; i += 6) {
        indices[i + 0] = 0 + offset;
        indices[i + 1] = 1 + offset;
        indices[i + 2] = 2 + offset;
        indices[i + 3] = 2 + offset;
        indices[i + 4] = 3 + offset;
        indices[i + 5] = 0 + offset;
        offset += 4;
    }
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, batch.EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    // Atributos: Pos(2), Tex(2), Color(4)
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)0);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)(2 * sizeof(float)));
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(2, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)(4 * sizeof(float)));
    glEnableVertexAttribArray(2);

    // Matriz de Proyección (Orto 2D)
    // Coordenadas internas: 0,0 a 256,224
    glUseProgram(batch.shaderProgram);
    // Matriz Orto manual: 2/w, 2/h, ... simple para 2D
    // O mejor, usamos una librería math o hardcodeamos la matriz uniforme
    // Para simplificar y no añadir GLM, calculamos la matriz aquí:
    float l = 0, r = INTERNAL_W, b = INTERNAL_H, t = 0; // Top-Left origin
    float ortho[16] = {
        2.0f/(r-l), 0, 0, 0,
        0, 2.0f/(t-b), 0, 0,
        0, 0, -1, 0,
        -(r+l)/(r-l), -(t+b)/(t-b), 0, 1
    };
    GLint projLoc = glGetUniformLocation(batch.shaderProgram, "projection");
    glUniformMatrix4fv(projLoc, 1, GL_FALSE, ortho);
}

// Flush: Manda los datos a la GPU
void flush_batch() {
    if (batch.indexCount == 0) return;

    glBindBuffer(GL_ARRAY_BUFFER, batch.VBO);
    glBufferSubData(GL_ARRAY_BUFFER, 0, batch.vertices.size() * sizeof(Vertex), batch.vertices.data());

    glBindTexture(GL_TEXTURE_2D, batch.currentTexture);
    glUseProgram(batch.shaderProgram);
    glBindVertexArray(batch.VAO);

    glDrawElements(GL_TRIANGLES, batch.indexCount, GL_UNSIGNED_INT, 0);

    batch.vertices.clear();
    batch.indexCount = 0;
}

// --- LUA BINDINGS ---

// batch.init()
static int l_batch_init(lua_State* L) {
    init_renderer();
    return 0;
}

// batch.begin()
static int l_batch_begin(lua_State* L) {
    batch.vertices.clear();
    batch.indexCount = 0;
    return 0;
}

// batch.end()
static int l_batch_end(lua_State* L) {
    flush_batch();
    return 0;
}

// batch.draw(texID, x, y, srcX, srcY, srcW, srcH, flipX)
static int l_batch_draw(lua_State* L) {
    GLuint texID = (GLuint)luaL_checkinteger(L, 1);
    float x = luaL_checknumber(L, 2);
    float y = luaL_checknumber(L, 3);

    // Source rect (para spritesheets)
    float sx = luaL_checknumber(L, 4);
    float sy = luaL_checknumber(L, 5);
    float sw = luaL_checknumber(L, 6);
    float sh = luaL_checknumber(L, 7);

    bool flipX = lua_toboolean(L, 8);

    // Cambio de textura = Flush forzoso
    if (texID != batch.currentTexture) {
        flush_batch();
        batch.currentTexture = texID;
    }

    // Calcular UVs
    // Necesitamos el tamaño de la textura para normalizar UVs (0.0 - 1.0)
    // Por simplicidad, asumimos que el usuario o Lua sabe el tamaño o pasamos UVs directas
    // OJO: Para hacerlo bien, texture.cpp debería guardar tamaños.
    // HACK TEMPORAL: Consultar tamaño a OpenGL (lento pero funcional)
    int texW, texH;
    glBindTexture(GL_TEXTURE_2D, texID);
    glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_WIDTH, &texW);
    glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_HEIGHT, &texH);

    float u0 = sx / texW;
    float v0 = sy / texH;
    float u1 = (sx + sw) / texW;
    float v1 = (sy + sh) / texH;

    if (flipX) { float tmp = u0; u0 = u1; u1 = tmp; }

    // Añadir 4 vértices (Quad)
    // Top-Left, Bottom-Left, Bottom-Right, Top-Right
    batch.vertices.push_back({x, y,       u0, v0, 1,1,1,1});
    batch.vertices.push_back({x, y+sh,    u0, v1, 1,1,1,1});
    batch.vertices.push_back({x+sw, y+sh, u1, v1, 1,1,1,1});
    batch.vertices.push_back({x+sw, y,    u1, v0, 1,1,1,1});

    batch.indexCount += 6;

    // Si llenamos el buffer, flush automático
    if (batch.indexCount >= MAX_INDICES) {
        flush_batch();
    }

    return 0;
}

int luaopen_batch(lua_State* L) {
    luaL_Reg regs[] = {
        {"init", l_batch_init},
        {"begin_draw", l_batch_begin},
        {"end_draw", l_batch_end},
        {"draw", l_batch_draw},
        {NULL, NULL}
    };
    luaL_newlib(L, regs);
    return 1;
}
