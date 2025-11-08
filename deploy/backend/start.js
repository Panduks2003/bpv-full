const { exec } = require('child_process');
const path = require('path');

// Start the Node.js application
const server = exec('node server.js', {
  cwd: __dirname
});

server.stdout.on('data', (data) => {
  console.log(`stdout: ${data}`);
});

server.stderr.on('data', (data) => {
  console.error(`stderr: ${data}`);
});

server.on('close', (code) => {
  console.log(`Server process exited with code ${code}`);
});
