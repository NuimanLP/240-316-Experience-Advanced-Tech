const fs = require('fs');

// Load and test the WebAssembly module
async function testWasm() {
    try {
        // Read the .wasm file
        const wasmBuffer = fs.readFileSync('firstprog.wasm');
        
        // Compile the module
        const wasmModule = await WebAssembly.compile(wasmBuffer);
        
        // Create an instance with imported memory
        const memory = new WebAssembly.Memory({ initial: 1 });
        const instance = await WebAssembly.instantiate(wasmModule, {
            env: { memory: memory }
        });
        
        console.log('WebAssembly module loaded successfully!');
        console.log('Exported functions:', Object.keys(instance.exports));
        
        // Call c_hello function
        const ptr = instance.exports.c_hello();
        console.log('Pointer returned by c_hello():', ptr);
        
        // Read the string from memory
        const buffer = new Uint8Array(instance.exports.memory.buffer);
        let result = '';
        for (let i = ptr; buffer[i] !== 0; i++) {
            result += String.fromCharCode(buffer[i]);
        }
        
        console.log('Result:', result);
        
    } catch (error) {
        console.error('Error:', error);
    }
}

testWasm();
