<p align="center">
    <img width="320" height="320" src="https://raw.githubusercontent.com/jgphilpott/polytree/polytree/icon.png" alt="Polytree Logo">
</p>

# Intro

**Polytree** is a modern, modular Constructive Solid Geometry (CSG) library for JavaScript and Node.js, built to utilize the efficiencies of Octree data structure. It is designed for robust 3D modeling, spatial queries, and seamless integration with [three.js](https://github.com/mrdoob/three.js).

## Getting Started

### Node.js

##### Install

```bash
npm install polytree
```

##### Import

```js
import * as THREE from 'three';
import { Polytree } from 'polytree';

// Example usage coming soon!
```

### Browser

For browser usage, use the ES module-compatible bundle:

```html
<script type="importmap">
{
    "imports": {
        "three": "./path/to/three.module.min.js",
        "polytree": "./path/to/polytree.bundle.browser.js"
    }
}
</script>

<script type="module">
import * as THREE from 'three';
import Polytree from 'polytree';

// Example usage coming soon!
</script>
```

The browser bundle (`polytree.bundle.browser.js`) is specifically designed for ES module imports in browsers, while the main bundle (`polytree.bundle.js`) is for Node.js environments.

## Applications

- 3D modeling and design for 3D printing.
- Integration with [Polyslice](https://github.com/jgphilpott/polyslice) FDM slicer.
- General-purpose spatial querying and mesh manipulation.

## Contributing

Contributions, issues, and feature requests are welcome! Please [open an issue](https://github.com/jgphilpott/polytree/issues) or submit a [pull request](https://github.com/jgphilpott/polytree/pulls).

---

**Polytree** is developed and maintained by [@jgphilpott](https://github.com/jgphilpott).