#!/bin/bash

# Alternative compilation method using Emscripten
# This requires Emscripten SDK to be installed

echo "Compiling firstprog.c to WebAssembly using Emscripten..."

# Compile C to WebAssembly with proper exports
emcc firstprog.c \
    -o firstprog.wasm \
    -s EXPORTED_FUNCTIONS='["_c_hello"]' \
    -s EXPORTED_RUNTIME_METHODS='["ccall", "cwrap"]' \
    -s MODULARIZE=0 \
    -s SIDE_MODULE=1 \
    -O2

echo "Compilation complete! firstprog.wasm has been generated."
echo "You can now open firstprog.html in a web browser (via a local server)."
