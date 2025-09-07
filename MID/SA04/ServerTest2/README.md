# WebAssembly "Hello World" Example

This is a complete WebAssembly "Hello World" example that demonstrates how to compile C code to WebAssembly and run it in a web browser.

## Files Created

1. **firstprog.c** - The C source code containing the `c_hello()` function that returns "Hello World"
2. **firstprog.html** - The HTML file that loads and executes the WebAssembly module (tutorial approach)
3. **firstprog_emscripten.html** - Alternative HTML file that uses Emscripten's JavaScript glue code
4. **firstprog.wasm** - The compiled WebAssembly module (COMPLETED ✅)
5. **firstprog.js** - Emscripten-generated JavaScript glue code
6. **test_wasm.js** - Node.js test script to verify the WebAssembly module
7. **README.md** - This instruction file

## ✅ Example is Now Complete!

The WebAssembly module has been compiled using Emscripten, and the example is ready to run!

### Testing the Application

1. Start a local web server in this directory. You can use Python:
   ```bash
   # Python 3
   python3 -m http.server 8000
   
   # Python 2
   python -m SimpleHTTPServer 8000
   ```

2. Open your web browser and navigate to: http://localhost:8000/firstprog.html

3. You should see "Hello World" displayed in orange text in the center of the page

4. Open the browser's developer console (F12) to see:
   - The WebAssembly instance details
   - The "Hello World" string logged to the console

## How It Works

The JavaScript code in `firstprog.html` performs the following steps:

1. **Fetch the .wasm file** using the Fetch API
2. **Convert to ArrayBuffer** to get the binary data
3. **Compile the module** using `WebAssembly.compile()`
4. **Create an instance** using `WebAssembly.Instance()`
5. **Access the exported function** `c_hello()` from the instance
6. **Read the string from memory**:
   - Get the memory buffer from the instance
   - Convert it to a Uint8Array
   - Call `c_hello()` to get the starting memory address of the string
   - Read bytes from memory starting at that address until a null terminator (0) is found
   - Convert each byte to a character using `String.fromCharCode()`
7. **Display the result** in the HTML div element

## Important Notes

- WebAssembly doesn't have a native string type, so strings are stored as sequences of bytes in memory
- The C function returns a pointer (memory address) to the string
- JavaScript needs to manually read the bytes from WebAssembly memory and convert them to a string
- A local web server is required due to CORS restrictions when loading .wasm files
