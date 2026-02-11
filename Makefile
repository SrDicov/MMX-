CXX = g++

# 1. Configuración automática de rutas (Arch Linux Standard)
# Obtiene flags como -I/usr/include/SDL2 automáticamente
SDL_CFLAGS := $(shell sdl2-config --cflags)
SDL_LIBS   := $(shell sdl2-config --libs) -lSDL2_image -lSDL2_mixer

# LuaJIT: pkg-config suele llamarlo 'luajit' en Arch
LUA_CFLAGS := $(shell pkg-config --cflags luajit)
LUA_LIBS   := $(shell pkg-config --libs luajit)

# Flags combinadas
CXXFLAGS = -std=c++17 -Wall -O2 $(SDL_CFLAGS) $(LUA_CFLAGS)
LIBS = $(SDL_LIBS) $(LUA_LIBS) -lGL

# Archivos fuente
SRCS = src/main.cpp src/renderer/batch.cpp src/renderer/texture.cpp src/bindings/l_input.cpp src/bindings/l_util.cpp src/bindings/l_audio.cpp src/bindings/l_graphics.cpp
OBJS = $(SRCS:.cpp=.o)
TARGET = bin/xpp

# Reglas
all: $(TARGET)

$(TARGET): $(OBJS)
	@mkdir -p bin
	$(CXX) $(OBJS) -o $(TARGET) $(LIBS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f src/*.o src/renderer/*.o src/bindings/*.o $(TARGET)

run: all
	./$(TARGET)
