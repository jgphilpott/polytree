# GitHub Pages Configuration

The examples are automatically deployed to GitHub Pages via the workflow in `.github/workflows/deploy-pages.yml`.

## Local Development

To run the examples locally:

1. Build the project:
   ```bash
   npm run build
   ```

2. Copy the bundle to the examples directory:
   ```bash
   cp polytree.bundle.browser.js examples/
   ```

3. Serve the examples directory with a local server:
   ```bash
   cd examples
   python -m http.server 8000
   # or
   npx serve .
   ```

4. Open `http://localhost:8000` in your browser

## GitHub Pages Deployment

The GitHub Pages deployment automatically:
- Builds the Polytree bundles
- Copies all example files to the docs directory
- Includes the necessary bundle files
- Deploys to GitHub Pages

## Examples Available

1. **Basic CSG Operations** (`basic.html`) - Interactive CSG demonstrations
2. **Real-time CSG Demo** (`realtime.html`) - Advanced real-time operations  
3. **Spatial Queries & Slicing** (`spatial.html`) - 3D printing spatial analysis

All examples include comprehensive documentation and interactive controls.