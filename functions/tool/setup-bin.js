const fs = require('fs');
const path = require('path');

const binDir = path.join(__dirname, '..', 'node_modules', '.bin');
if (!fs.existsSync(binDir)) {
  fs.mkdirSync(binDir, { recursive: true });
}

const binScript = path.join(binDir, 'firebase-functions');
const target = path.join('..', 'firebase-functions', 'lib', 'bin', 'firebase-functions.js');

try {
  if (fs.existsSync(binScript)) {
    fs.unlinkSync(binScript);
  }
  fs.symlinkSync(target, binScript);
  fs.chmodSync(path.join(binDir, target), 0o755);
} catch (e) {
  // Ignore on Windows or restricted environments where symlinks fail
}
