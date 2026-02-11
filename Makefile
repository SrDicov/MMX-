CXX = g++

# Configuración de LuaJIT
LUAJIT_CFLAGS := $(shell pkg-config --cflags luajit)
LUAJIT_LIBS := $(shell pkg-config --libs luajit)

CXXFLAGS = -std=c++17 -Wall -O2 $(LUAJIT_CFLAGS)
# AÑADIDO: -lSDL2_image
LDFLAGS = -lSDL2 -lSDL2_image -lGL -lGLEW $(LUAJIT_LIBS)

# AÑADIDO: batch.cpp y texture.cpp
SRC = src/main.cpp \
      src/renderer/batch.cpp \
      src/renderer/texture.cpp \
      src/bindings/l_input.cpp \
      src/bindings/l_console.cpp \
      src/bindings/l_panic.cpp \
      src/bindings/l_sandbox.cpp \
      src/bindings/l_util.cpp

OBJ = $(SRC:.cpp=.o)
TARGET = bin/xpp

all: $(TARGET)

$(TARGET): $(OBJ)
	@mkdir -p bin
	$(CXX) -o $@ $^ $(LDFLAGS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f src/*.o src/renderer/*.o src/bindings/*.o $(TARGET)

run: $(TARGET)
	./$(TARGET)
