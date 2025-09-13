#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

/**
 * Convert CommonJS polytree.bundle.js to ES module polytree.bundle.browser.js
 * This creates a browser-compatible ES module that can be imported using ES6 import syntax.
 */

console.log('Creating browser ES module bundle...');

// Read the CommonJS bundle
const bundlePath = path.join(__dirname, '..', 'polytree.bundle.js');
const browserBundlePath = path.join(__dirname, '..', 'polytree.bundle.browser.js');

if (!fs.existsSync(bundlePath)) {
    console.error('Error: polytree.bundle.js not found. Run npm run build:node first.');
    process.exit(1);
}

let content = fs.readFileSync(bundlePath, 'utf8');

// Replace require("three") with import from three
content = content.replace(
    /\(\{([^}]+)\} = require\("three"\)\);/,
    'import { $1 } from "three";'
);

// Find all module.exports assignments and collect them
const moduleExports = [];
const exportRegex = /module\.exports\.(\w+) = (\w+);/g;
let match;

while ((match = exportRegex.exec(content)) !== null) {
    moduleExports.push({ name: match[1], value: match[2] });
}

// Remove all module.exports lines
content = content.replace(/module\.exports\.\w+ = \w+;\n?/g, '');

// Find the main default export (usually the last large assignment)
// Look for patterns like "module.exports = Something" or similar
const defaultExportMatch = content.match(/(\w+) = (function\([^)]*\)[\s\S]*?)(?=\n\w+\s*=|\nmodule\.exports|\n$)/);
let defaultExportName = 'Polytree'; // fallback

// If we can find the main Polytree class/function definition, use that
const polytreeMatch = content.match(/Polytree = (function\([^)]*\)[\s\S]*?)(?=\n\w+\s*=|\nmodule\.exports|\n$)/);
if (polytreeMatch) {
    defaultExportName = 'Polytree';
}

// Add ES module exports at the end
let esExports = '\n// ES module exports\n';
esExports += `export default ${defaultExportName};\n`;

// Add named exports
moduleExports.forEach(exp => {
    esExports += `export { ${exp.value} as ${exp.name} };\n`;
});

// Add the exports to the content
content += esExports;

// Write the browser bundle
fs.writeFileSync(browserBundlePath, content);

console.log(`Browser ES module bundle created: ${browserBundlePath}`);
console.log(`Exports: default (${defaultExportName}) + ${moduleExports.length} named exports`);