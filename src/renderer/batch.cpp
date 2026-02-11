#include "../engine.hpp"
#include <vector>

// Estructura de Vértice para el Batch
struct Vertex {
    float x, y;       // Posición
    float u, v;       // UVs
    float r, g, b, a; // Color
};

// Estado interno del Batch Renderer
struct BatchState {
    GLuint VAO, VBO;
    GLuint shaderProgram;
    std::vector<Vertex> vertices;
    // Capacidad máxima por draw call (1000 sprites * 6 vértices)
    const size_t MAX_SPRITES = 1000;
};

static BatchState batch;

// Shaders básicos incrustados (Core Profile 3.3)
const char* vertexShaderSource = "#version 330 core\n"
"layout (location = 0) in vec2 aPos;\n"
"layout (location = 1) in vec2 aTexCoord;\n"
"layout (location = 2) in vec4 aColor;\n"
"out vec2 TexCoord;\n"
"out vec4 Color;\n"
"uniform mat4 projection;\n"
"void main() {\n"
"   gl_Position = projection * vec4(aPos, 0.0, 1.0);\n"
"   TexCoord = aTexCoord;\n"
"   Color = aColor;\n"
"}\0";

const char* fragmentShaderSource = "#version 330 core\n"
"in vec2 TexCoord;\n"
"in vec4 Color;\n"
"out vec4 FragColor;\n"
"uniform sampler2D image;\n"
"void main() {\n"
"   FragColor = texture(image, TexCoord) * Color;\n"
"}\0";

// Función auxiliar para compilar shaders
GLuint compileShader(GLenum type, const char* source) {
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &source, NULL);
    glCompileShader(shader);

    int success;
    char infoLog[512];
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(shader, 512, NULL, infoLog);
        std::cerr << "[SHADER ERROR] " << infoLog << std::endl;
    }
    return shader;
}

// Inicialización del Renderizador
void init_renderer() {
    // 1. Compilar Shaders
    GLuint vertex = compileShader(GL_VERTEX_SHADER, vertexShaderSource);
    GLuint fragment = compileShader(GL_FRAGMENT_SHADER, fragmentShaderSource);

    batch.shaderProgram = glCreateProgram();
    glAttachShader(batch.shaderProgram, vertex);
    glAttachShader(batch.shaderProgram, fragment);
    glLinkProgram(batch.shaderProgram);

    // Verificar errores de linkeo
    int success;
    char infoLog[512];
    glGetProgramiv(batch.shaderProgram, GL_LINK_STATUS, &success);
    if(!success) {
        glGetProgramInfoLog(batch.shaderProgram, 512, NULL, infoLog);
        std::cerr << "[PROGRAM ERROR] " << infoLog << std::endl;
    }

    glDeleteShader(vertex);
    glDeleteShader(fragment);

    // 2. Configurar Buffers (VAO/VBO)
    glGenVertexArrays(1, &batch.VAO);
    glGenBuffers(1, &batch.VBO);

    glBindVertexArray(batch.VAO);
    glBindBuffer(GL_ARRAY_BUFFER, batch.VBO);

    // Reservar memoria (Buffer huérfano dinámico)
    glBufferData(GL_ARRAY_BUFFER, batch.MAX_SPRITES * 6 * sizeof(Vertex), nullptr, GL_DYNAMIC_DRAW);

    // Atributos: Pos(2) + UV(2) + Color(4) = 8 floats stride
    // 0: Pos
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)0);
    glEnableVertexAttribArray(0);
    // 1: UV
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)(2 * sizeof(float)));
    glEnableVertexAttribArray(1);
    // 2: Color
    glVertexAttribPointer(2, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)(4 * sizeof(float)));
    glEnableVertexAttribArray(2);

    // 3. Configurar Matriz de Proyección (Ortho)
    glUseProgram(batch.shaderProgram);

    // Matriz Ortográfica Manual (0,0 top-left -> INTERNAL_W, INTERNAL_H bottom-right)
    float l = 0, r = (float)INTERNAL_W;
    float b = (float)INTERNAL_H, t = 0; // Invertido Y para coordenadas de pantalla

    float ortho[16] = {
        2.0f/(r-l),   0,            0, 0,
        0,            2.0f/(t-b),   0, 0,
        0,            0,           -1, 0,
        -(r+l)/(r-l), -(t+b)/(t-b), 0, 1
    };

    GLint projLoc = glGetUniformLocation(batch.shaderProgram, "projection");
    glUniformMatrix4fv(projLoc, 1, GL_FALSE, ortho);
}

// Enviar geometría a la GPU

void draw_sprite(GLuint texture, float x, float y, float w, float h,
                 float u0, float v0, float u1, float v1,
                 float r, float g, float b, float a)
{
    // Si el batch está lleno o cambiamos de textura (opcional), podríamos hacer flush automático.
    // Por simplicidad en este paso, asumimos una sola textura atlas o que Lua gestiona los cambios.
    // NOTA: Para un motor real, deberíamos chequear si 'texture' cambia y hacer flush.

    // Si superamos la capacidad, dibujamos lo que hay y limpiamos
    if (batch.vertices.size() + 6 > batch.MAX_SPRITES * 6) {
        flush_batch();
    }

    // Definir los 4 vértices del quad (x, y, u, v, r, g, b, a)
    // Orden: Top-Left, Bottom-Left, Bottom-Right, Top-Left, Bottom-Right, Top-Right (2 triángulos)

    // Vértices
    float x1 = x;
    float y1 = y;
    float x2 = x + w;
    float y2 = y + h;

    // Triángulo 1
    batch.vertices.push_back({x1, y1, u0, v0, r, g, b, a}); // TL
    batch.vertices.push_back({x1, y2, u0, v1, r, g, b, a}); // BL
    batch.vertices.push_back({x2, y2, u1, v1, r, g, b, a}); // BR

    // Triángulo 2
    batch.vertices.push_back({x1, y1, u0, v0, r, g, b, a}); // TL
    batch.vertices.push_back({x2, y2, u1, v1, r, g, b, a}); // BR
    batch.vertices.push_back({x2, y1, u1, v0, r, g, b, a}); // TR
}

void flush_batch() {
    if (batch.vertices.empty()) return;

    glBindBuffer(GL_ARRAY_BUFFER, batch.VBO);
    // Subir datos
    glBufferSubData(GL_ARRAY_BUFFER, 0, batch.vertices.size() * sizeof(Vertex), batch.vertices.data());

    glUseProgram(batch.shaderProgram);
    glBindVertexArray(batch.VAO);

    // Dibujar
    glDrawArrays(GL_TRIANGLES, 0, batch.vertices.size());

    // Limpiar para el siguiente frame
    batch.vertices.clear();
}

void set_camera(float x, float y) {
    // Aseguramos que el shader esté activo
    glUseProgram(batch.shaderProgram);

    // Recalcular Matriz Ortográfica
    // La cámara mueve el "mundo", así que los límites de proyección cambian.
    // Left = x, Right = x + 256, Bottom = y + 224, Top = y

    float l = x;
    float r = x + (float)INTERNAL_W;
    float b = y + (float)INTERNAL_H;
    float t = y;

    float ortho[16] = {
        2.0f/(r-l),   0,            0, 0,
        0,            2.0f/(t-b),   0, 0,
        0,            0,           -1, 0,
        -(r+l)/(r-l), -(t+b)/(t-b), 0, 1
    };

    GLint projLoc = glGetUniformLocation(batch.shaderProgram, "projection");
    glUniformMatrix4fv(projLoc, 1, GL_FALSE, ortho);
}
