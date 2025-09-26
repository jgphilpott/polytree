<p align="center">
    <img width="321" height="321" src="https://raw.githubusercontent.com/jgphilpott/polytree/polytree/icon.png" alt="Polytree Icon">
</p>

# Polytree

<details open>

<summary><h2 style="display:inline">Intro</h2></summary>

**Polytree** is a modern, high-performance Constructive Solid Geometry (CSG) library for JavaScript and Node.js, built to utilize the efficiencies of Octree data structure. It is designed for robust 3D modeling, spatial queries, and seamless integration with [three.js](https://github.com/mrdoob/three.js).

### Features

- **Complete CSG Operations**: Union, subtraction, and intersection with full test coverage.
- **Advanced Spatial Queries**: Point-based queries, distance calculations, and intersection testing inspired by three-mesh-bvh.
- **3D Printing Support**: Layer slicing, volume analysis, and spatial operations for manufacturing applications.
- **High Performance**: Optimized Octree-based spatial partitioning for fast operations.
- **Dual API**: Both synchronous and asynchronous operation modes.
- **Multi-Input Support**: Works directly with Three.js meshes, BufferGeometry, and Polytree instances.
- **Lightweight**: Minimal dependencies with efficient memory usage.
- **Three.js Integration**: Direct mesh-to-mesh operations with material preservation.
- **Well Documented**: Comprehensive API documentation and examples.
- **Robust Testing**: 497+ tests ensuring reliability across edge cases.

</details>

<details open>

<summary><h2 style="display:inline">Getting Started</h2></summary>

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

<summary><h2 style="display:inline">Spatial Query Functions</h2></summary>

Polytree now includes advanced spatial query capabilities inspired by the mature `three-mesh-bvh` library, transforming it from a pure CSG library into a comprehensive spatial querying tool optimized for 3D printing applications.

### Point-based Queries

Find the closest points and calculate distances for collision detection and mesh analysis:

```js
const geometry = new THREE.BoxGeometry(2, 2, 2);
const mesh = new THREE.Mesh(geometry, material);
const testPoint = new THREE.Vector3(5, 0, 0);

// Find closest point on surface - works with Mesh, BufferGeometry, or Polytree
const closestPoint = Polytree.closestPointToPoint(mesh, testPoint);
console.log(`Closest point: (${closestPoint.x}, ${closestPoint.y}, ${closestPoint.z})`);

// Calculate distance to surface
const distance = Polytree.distanceToPoint(mesh, testPoint);
console.log(`Distance: ${distance} units`);
```

### Volume Analysis

Perform both exact and statistical volume calculations:

```js
// Exact volume calculation
const exactVolume = Polytree.getVolume(mesh);

// Monte Carlo volume estimation for complex geometries  
const estimatedVolume = Polytree.estimateVolumeViaSampling(mesh, 50000);
console.log(`Exact: ${exactVolume}, Estimated: ${estimatedVolume}`);
```

### Intersection Testing

Test intersections with bounding volumes for collision detection:

```js
// Test sphere intersection
const sphere = new THREE.Sphere(new THREE.Vector3(0, 0, 0), 2);
const intersectsSphere = Polytree.intersectsSphere(mesh, sphere);

// Test bounding box intersection  
const box = new THREE.Box3(min, max);
const intersectsBox = Polytree.intersectsBox(mesh, box);
```

### 3D Printing Layer Slicing

Generate layer slices for 3D printing applications:

```js
// Slice geometry into horizontal layers
const layers = Polytree.sliceIntoLayers(
    mesh,           // Input geometry
    0.2,           // Layer height (0.2mm)
    -10,           // Minimum Z
    10,            // Maximum Z
    new THREE.Vector3(0, 0, 1)  // Optional normal (default: Z-up)
);

console.log(`Generated ${layers.length} layers for 3D printing`);

// Single plane intersection for cross-section analysis
const plane = new THREE.Plane(new THREE.Vector3(0, 0, 1), 0);
const crossSection = Polytree.intersectPlane(mesh, plane);
```

### Advanced Spatial Operations

Custom spatial queries and triangle-based operations:

```js
// Get triangles near a specific point
const nearbyTriangles = Polytree.getTrianglesNearPoint(mesh, point, 2.0);

// Custom spatial query with callback
const results = Polytree.shapecast(mesh, (triangle) => {
    // Custom query logic - return true to collect triangle
    return triangle.normal.y > 0.8; // Find upward-facing triangles
}, (triangle) => {
    // Optional collection callback for processing results
    return { triangle, area: triangle.getArea() };
});
```

### Multi-Input Support

All spatial query functions accept Three.js meshes, BufferGeometry, or Polytree instances:

```js
const geometry = new THREE.BoxGeometry(2, 2, 2);
const mesh = new THREE.Mesh(geometry, material);  
const polytree = Polytree.fromMesh(mesh);

// All of these work identically
const result1 = Polytree.closestPointToPoint(mesh, testPoint);     // Mesh
const result2 = Polytree.closestPointToPoint(geometry, testPoint); // BufferGeometry
const result3 = Polytree.closestPointToPoint(polytree, testPoint); // Polytree
```

</details>

<details open>

<summary><h2 style="display:inline">Usage</h2></summary>

<details open>

<summary><h3 style="display:inline">Utility Functions</h3></summary>

Polytree provides utility functions for geometry analysis and calculations:

#### Surface Area Calculation

Calculate the surface area of Three.js meshes or geometries:

```js
// Calculate surface area from a mesh:
const boxGeometry = new THREE.BoxGeometry(2, 3, 4);
const boxMesh = new THREE.Mesh(boxGeometry, new THREE.MeshBasicMaterial());
const surfaceArea = Polytree.getSurface(boxMesh);

console.log(`Surface area: ${surfaceArea}`); // Output: 52

// Calculate surface area directly from geometry:
const sphereGeometry = new THREE.SphereGeometry(1);
const sphereSurfaceArea = Polytree.getSurface(sphereGeometry);

console.log(`Sphere surface area: ${sphereSurfaceArea}`); // Output: ~12.47
```

The `getSurface()` method:

- Accepts either Three.js `Mesh` objects or `BufferGeometry` objects.
- Returns the total surface area as a number.
- Works by summing the areas of all triangular faces.
- Handles both indexed and non-indexed geometries.

#### Volume Calculation

Calculate the volume of Three.js meshes or geometries:

```js
// Calculate volume from a mesh:
const boxGeometry = new THREE.BoxGeometry(2, 2, 2);
const boxMesh = new THREE.Mesh(boxGeometry, new THREE.MeshBasicMaterial());
const volume = Polytree.getVolume(boxMesh);

console.log(`Volume: ${volume}`); // Output: 8

// Calculate volume directly from geometry:
const sphereGeometry = new THREE.SphereGeometry(1);
const sphereVolume = Polytree.getVolume(sphereGeometry);

console.log(`Sphere volume: ${sphereVolume}`); // Output: ~4.19 (approx 4/3 * π)
```

The `getVolume()` method:

- Accepts either Three.js `Mesh` objects or `BufferGeometry` objects.
- Returns the total volume as a number.
- Uses the divergence theorem with signed tetrahedron volumes.
- Handles both indexed and non-indexed geometries.
- Automatically handles edge cases like empty geometries.

</details>

<details open>

<summary><h3 style="display:inline">Basic CSG Operations</h3></summary>

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

<details>

<summary><h3 style="display:inline">Async CSG Operations</h3></summary>

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

<summary><h3 style="display:inline">Async Array Operations</h3></summary>

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

<details>

<summary><h3 style="display:inline">Advanced Polytree-to-Polytree Operations</h3></summary>

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

</details>

<details open>

<summary><h2 style="display:inline">Performance</h2></summary>

Polytree is designed for high-performance CSG operations:

- **Octree Optimization**: Spatial partitioning reduces computational complexity for both CSG and spatial query operations.
- **Memory Efficient**: Smart resource management with cleanup methods and automatic temporary object disposal.
- **Unified Architecture**: CSG operations + spatial queries in one optimized library, eliminating the need for multiple tools.
- **Multi-Input Support**: Functions work directly with Three.js meshes, geometries, and Polytree instances without manual conversion.
- **Comprehensive Testing**: 497+ test cases ensuring reliability and performance across all operations.
- **Async Support**: Non-blocking operations for smooth user experiences.
- **Minimal Dependencies**: Only Three.js as a dependency for lightweight integration.

</details>

<details open>

<summary><h2 style="display:inline">Applications</h2></summary>

- **3D Modeling**: Professional-grade boolean operations for CAD applications.
- **Game Development**: Runtime mesh manipulation and procedural geometry.
- **3D Printing & Manufacturing**: Complete slicing pipeline with layer generation, support analysis, and volume calculations.
- **Collision Detection**: Fast spatial queries for physics engines and interactive applications.
- **Mesh Analysis & Repair**: Distance field calculations, closest point queries, and geometric validation.
- **Architectural Visualization**: Complex building geometry operations with spatial analysis.
- **Educational Tools**: Interactive 3D geometry learning applications with real-time feedback.
- **Integration with [Polyslice](https://github.com/jgphilpott/polyslice)**: Advanced FDM slicing workflows and manufacturing optimization.

</details>

<details open>

<summary><h2 style="display:inline">Contributing</h2></summary>

Contributions, issues, and feature requests are welcome! Please [open an issue](https://github.com/jgphilpott/polytree/issues) or submit a [pull request](https://github.com/jgphilpott/polytree/pulls).

</details>

---

**Polytree** is developed and maintained by [@jgphilpott](https://github.com/jgphilpott).
