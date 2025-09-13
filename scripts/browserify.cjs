#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

/**
 * Convert CommonJS polytree.bundle.js to ES module polytree.bundle.browser.js.
 * This creates a browser-compatible ES module that can be imported using ES6 import syntax.
 */

console.log('Creating browser ES module bundle...');

// Read the CommonJS bundle.
const bundlePath = path.join(__dirname, '..', 'polytree.bundle.js');
const browserBundlePath = path.join(__dirname, '..', 'polytree.bundle.browser.js');

if (!fs.existsSync(bundlePath)) {
    console.error('Error: polytree.bundle.js not found. Run npm run build:node first.');
    process.exit(1);
}

let content = fs.readFileSync(bundlePath, 'utf8');

// 1. Replace destructured require of three with ES module import.
//    CoffeeScript outputs a pattern like: ({Vector2, Vector3, ...} = require("three"));
//    BUT it also pre-declares those identifiers in the giant leading `var` line.
//    If we simply add an ES import we get duplicate identifier errors.
//    So we:
//      a) Capture the identifier list.
//      b) Remove them from the first leading `var` declaration.
//      c) Insert an import statement.
const threeRequireRegex = /\(\{([^}]+)\} = require\("three"\)\);/;

let threeIdListMatch = content.match(threeRequireRegex);
let threeIdentifiers = [];

if (threeIdListMatch) {

    threeIdentifiers = threeIdListMatch[1]
        .split(',')
        .map(s => s.trim())
        .filter(Boolean);

    // Remove destructuring require line and replace with import.
    content = content.replace(threeRequireRegex, `import { ${threeIdentifiers.join(', ')} } from "three";`);

}

// 2. Remove imported identifiers from the first giant CoffeeScript var declaration line to avoid redeclaration.
if (threeIdentifiers.length) {
    const lines = content.split('\n');
    const idSet = new Set(threeIdentifiers);
    for (let i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('var ')) {
            // Support multiple consecutive CoffeeScript generated var lines.
            const decl = lines[i].slice(4).replace(/;$/, '');
            let parts = decl.split(',').map(p => p.trim()).filter(Boolean);
            const filtered = parts.filter(p => !idSet.has(p));
            if (filtered.length !== parts.length) {
                lines[i] = filtered.length ? ('var ' + filtered.join(', ') + ';') : '';
            }
        }
    }
    // Remove any blank lines created by eliminating entire var declarations.
    content = lines.filter(l => l !== '').join('\n');
}

// Find all module.exports assignments and collect them.
const moduleExports = [];
const exportRegex = /module\.exports\.(\w+) = (\w+);/g;
let match;

while ((match = exportRegex.exec(content)) !== null) {
    moduleExports.push({ name: match[1], value: match[2] });
}

// Remove all module.exports property assignment lines (named re-exports).
content = content.replace(/module\.exports\.\w+ = \w+;\n?/g, '');

// Remove the composite CommonJS export object if present (we'll supply pure ESM exports).
content = content.replace(/module\.exports\s*=\s*\{[\s\S]*?\};\n?/g, '');

// Find the main default export (usually the last large assignment).
// Look for patterns like "module.exports = Something" or similar.
const defaultExportMatch = content.match(/(\w+) = (function\([^)]*\)[\s\S]*?)(?=\n\w+\s*=|\nmodule\.exports|\n$)/);
let defaultExportName = 'Polytree'; // fallback

// If we can find the main Polytree class/function definition, use that.
const polytreeMatch = content.match(/Polytree = (function\([^)]*\)[\s\S]*?)(?=\n\w+\s*=|\nmodule\.exports|\n$)/);

if (polytreeMatch) {
    defaultExportName = 'Polytree';
}

// Add ES module exports at the end (dedupe names in case of prior duplicates).
const seen = new Set();
let esExports = '\n// ES module exports\n';
esExports += `export default ${defaultExportName};\n`;

moduleExports.forEach(exp => {
    if (!seen.has(exp.name)) {
        esExports += `export { ${exp.value} as ${exp.name} };\n`;
        seen.add(exp.name);
    }
});

content += esExports;

// Write the browser bundle.
fs.writeFileSync(browserBundlePath, content);

console.log(`Browser ES module bundle created: ${browserBundlePath}`);
console.log(`Exports: default (${defaultExportName}) + ${moduleExports.length} named exports`);