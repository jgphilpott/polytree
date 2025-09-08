# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Common Development Commands

- **Install dependencies**:
  ```bash
  npm install
  ```
- **Build (compile CoffeeScript to JS)**:
  ```bash
  npm run compile
  ```
  - For incremental development: `npm run compile:watch`
- **Run tests (Jest)**:
  ```bash
  npm test
  ```
- **Linting**: No explicit lint script present; if adding, use CoffeeScript/eslint plugins as appropriate.

## Key Development Notes

- The library is implemented in CoffeeScript; edits are made to `.coffee` files and then compiled to JavaScript.
- Main entry points: `polytree.coffee` and `src/PolytreeCSG.coffee` (and related files in `src/`).
- Unit tests are in `polytree.test.coffee` and use Jest. To run a single test interactively, use Jest’s built-in filter options, e.g.:
  ```bash
  npx jest polytree.test.coffee -t "Test name or regex"
  ```

## High-Level Architecture

### Overview
Polytree is a modern Constructive Solid Geometry (CSG) library that leverages Octree spatial data structures for high-performance and scalable 3D geometric modeling. It is designed for Node.js/JavaScript and integrates closely with [three.js](https://threejs.org/).

### Architecture
- **Core Data Structure: OctreeCSG**
  - CSG operations and geometry management are implemented through custom Octree-backed data structures (`OctreeCSG`, `Octree`, extensions).
  - Octrees allow highly efficient spatial queries, intersection tests, and partitioning for complex 3D models.
- **Integration with three.js**
  - The library expects three.js primitives for most geometry operations (Triangle, Vector3, Plane, etc.).
  - Mesh manipulation and conversion utilities interact directly with three.js types.
- **Web Worker Offloading**
  - Complex geometric calculations (e.g., winding number, triangle-triangle intersection) are designed for isolation and may be offloaded to a worker for computational efficiency (see `PolytreeCSG.worker.coffee`).
- **Algorithms**
  - Intersection, spatial queries, and geometry validation routines are implemented in file `src/triangle-intersection.coffee` and related modules; functions are generally documented for clarity.

### Extensibility & Contributing
- While the package is generic, it is designed as a core engine for advanced 3D modeling, spatial-analysis, or use as a backend for other tools (such as Polyslice, see README Applications).
- Contributions should follow idiomatic CoffeeScript and aim to extend OctreeCSG without breaking three.js compatibility.

## Project Entry and Examples
- Main package entry: `polytree.js` (compiled from `polytree.coffee`).   
- Internal codebase uses ES modules and standard `import`/`export` syntax in CoffeeScript.
- For usage, refer to integration patterns outlined in the README; the typical import is:
  ```js
  import { Polytree } from 'polytree';
  ```

## Links
- Main repo: https://github.com/jgphilpott/polytree
- Issues/PRs: Contributions and questions via GitHub.

---
For further details, review inline documentation in the source files—and test coverage for expected usage patterns.
