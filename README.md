<p align="center">
    <img width="321" height="321" src="https://raw.githubusercontent.com/jgphilpott/polytree/polytree/icon.png" alt="Polytree Icon">
</p>

# Polytree

<details open>
<summary><h2>Intro</h2></summary>

**Polytree** is a modern, high-performance Constructive Solid Geometry (CSG) library for JavaScript and Node.js, built to utilize the efficiencies of Octree data structure. It is designed for robust 3D modeling, spatial queries, and seamless integration with [three.js](https://github.com/mrdoob/three.js).

### Features

- **Complete CSG Operations**: Union, subtraction, and intersection with full test coverage.
- **High Performance**: Optimized Octree-based spatial partitioning for fast operations.
- **Dual API**: Both synchronous and asynchronous operation modes.
- **Lightweight**: Minimal dependencies with efficient memory usage.
- **Three.js Integration**: Direct mesh-to-mesh operations with material preservation.
- **Well Documented**: Comprehensive API documentation and examples.
- **Robust Testing**: 450+ tests ensuring reliability across edge cases.

</details>

<details open>
<summary><h2>Getting Started</h2></summary>

### Node.js

#### Install

```bash
npm install polytree
```

#### Import

```js
import * as THREE from 'three';
import { Polytree } from 'polytree';
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
</script>
```

The browser bundle (`polytree.bundle.browser.js`) is specifically designed for ES module imports in browsers, while the main bundle (`polytree.bundle.js`) is for Node.js environments.

</details>

<details open>
<summary><h2>Usage</h2></summary>

<details open>
<summary><h3>Basic CSG Operations</h3></summary>

Polytree provides three core CSG operations that work directly with Three.js meshes:

#### Unite (Join)

Join two 3D objects into a single merged object:

```js
// Create two identical boxes.
const geometry1 = new THREE.BoxGeometry(2, 2, 2);
const geometry2 = new THREE.BoxGeometry(2, 2, 2);

const mesh1 = new THREE.Mesh(geometry1, new THREE.MeshBasicMaterial());
const mesh2 = new THREE.Mesh(geometry2, new THREE.MeshBasicMaterial());

// Offset the position of one box.
mesh1.position.set(1, 1, 1);

// Join the boxes together.
const result = await Polytree.unite(mesh1, mesh2);

scene.add(result);
```

#### Subtract (Remove)

Remove one object's volume from another:

```js
// Create a box and a sphere.
const boxGeometry = new THREE.BoxGeometry(2, 2, 2);
const sphereGeometry = new THREE.SphereGeometry(1.5);

const boxMesh = new THREE.Mesh(boxGeometry, new THREE.MeshBasicMaterial());
const sphereMesh = new THREE.Mesh(sphereGeometry, new THREE.MeshBasicMaterial());

// Remove the sphere from the box (creates a cavity).
const result = await Polytree.subtract(boxMesh, sphereMesh);

scene.add(result);
```

#### Intersect (Overlap)

Keep only the overlapping volume of two objects:

```js
// Create two overlapping spheres.
const sphere1 = new THREE.Mesh(
    new THREE.SphereGeometry(1),
    new THREE.MeshBasicMaterial()
);

const sphere2 = new THREE.Mesh(
    new THREE.SphereGeometry(1),
    new THREE.MeshBasicMaterial()
);

// Offset the position of one sphere.
sphere1.position.set(1, 0, 0);

// Keep only the overlapping volume.
const result = await Polytree.intersect(sphere1, sphere2);

scene.add(result);
```

</details>

<details open>
<summary><h3>Asynchronous Operations</h3></summary>

For better performance in web applications, use async operations to prevent UI blocking:

```js
// Async union with Promise.
const unionPromise = Polytree.unite(mesh1, mesh2);
unionPromise.then(result => {
    scene.add(result);
});

// Async with await.
const unionResult = await Polytree.unite(mesh1, mesh2);
scene.add(unionResult);
```

</details>

<details>
<summary><h3>Advanced: Polytree-to-Polytree Operations</h3></summary>

For maximum performance when chaining operations, work directly with Polytree objects:

```js
// Convert meshes to polytrees once.
const polytree1 = Polytree.fromMesh(mesh1);
const polytree2 = Polytree.fromMesh(mesh2);
const polytree3 = Polytree.fromMesh(mesh3);

// Chain operations efficiently.
const intermediate = await Polytree.unite(polytree1, polytree2);
const final = await Polytree.subtract(intermediate, polytree3);

// Convert back to mesh for rendering.
const finalMesh = Polytree.toMesh(final);

scene.add(finalMesh);

// Clean up resources.
polytree1.delete();
polytree2.delete();
polytree3.delete();
intermediate.delete();
final.delete();
```

</details>

<details>
<summary><h3>Async Array Operations</h3></summary>

Process multiple objects efficiently:

```js
// Unite multiple objects asynchronously.
const meshArray = [mesh1, mesh2, mesh3, mesh4 ... meshX];
const polytreeArray = meshArray.map(mesh => Polytree.fromMesh(mesh));

Polytree.async.uniteArray(polytreeArray).then(result => {

    const finalMesh = Polytree.toMesh(result);
    scene.add(finalMesh);

    // Clean up.
    polytreeArray.forEach(polytree => {
        polytree.delete()
    });

    result.delete();

});
```

</details>

</details>

<details open>
<summary><h2>Performance</h2></summary>

Polytree is designed for high-performance CSG operations:

- **Octree Optimization**: Spatial partitioning reduces computational complexity.
- **Memory Efficient**: Smart resource management with cleanup methods.
- **Comprehensive Testing**: 450+ test cases ensuring reliability and performance.
- **Async Support**: Non-blocking operations for smooth user experiences.
- **Minimal Dependencies**: Only Three.js as a dependency for lightweight integration.

</details>

<details open>
<summary><h2>Applications</h2></summary>

- **3D Modeling**: Professional-grade boolean operations for CAD applications.
- **Game Development**: Runtime mesh manipulation and procedural geometry.
- **3D Printing**: Solid geometry preparation and mesh optimization.
- **Architectural Visualization**: Complex building geometry operations.
- **Educational Tools**: Interactive 3D geometry learning applications.
- **Integration with [Polyslice](https://github.com/jgphilpott/polyslice)**: Advanced FDM slicing workflows.

</details>

<details open>
<summary><h2>Contributing</h2></summary>

Contributions, issues, and feature requests are welcome! Please [open an issue](https://github.com/jgphilpott/polytree/issues) or submit a [pull request](https://github.com/jgphilpott/polytree/pulls).

</details>

---

**Polytree** is developed and maintained by [@jgphilpott](https://github.com/jgphilpott).
