# Polytree Spatial Query Capabilities

This document outlines the enhanced spatial query capabilities added to Polytree, inspired by the `three-mesh-bvh` library. These functions transform Polytree from a pure CSG library into a general-purpose spatial querying tool, particularly useful for 3D printing slicer applications.

## Overview

The new spatial query functions provide advanced geometric analysis capabilities beyond basic CSG operations. These methods are particularly valuable for:

- **3D Printing**: Layer slicing, support generation, collision detection
- **CAD Applications**: Distance analysis, proximity testing, geometric validation
- **Game Development**: Collision detection, spatial partitioning, physics simulation
- **Mesh Processing**: Surface analysis, repair operations, quality assessment

## Core Spatial Query Methods

### Point-Based Queries

#### `Polytree.closestPointToPoint(input, targetPoint, target?, maxDistance?)`

Finds the closest point on any triangle surface to a given point.

**Parameters:**
- `input`: Three.js Mesh, BufferGeometry, or Polytree instance to query
- `targetPoint`: Vector3 point to find closest surface point to
- `target`: Optional object to store result data
- `maxDistance`: Maximum search distance (default: Infinity)

**Returns:** Object with `point`, `distance`, and `triangle` properties, or `null`

**Use Cases:**
- Collision detection and response
- Mesh repair and smoothing
- Support structure generation for 3D printing
- Surface analysis and measurement

```javascript
// Works with any input type
const mesh = new THREE.Mesh(geometry, material);
const geometry = new THREE.BoxGeometry(2, 2, 2);
const polytree = Polytree.fromMesh(mesh);

const testPoint = new Vector3(5, 0, 0);

// All of these work the same way
const result1 = Polytree.closestPointToPoint(mesh, testPoint);
const result2 = Polytree.closestPointToPoint(geometry, testPoint);  
const result3 = Polytree.closestPointToPoint(polytree, testPoint);

if (result1) {
    console.log(`Closest distance: ${result1.distance}`);
    console.log(`Closest point: ${result1.point.x}, ${result1.point.y}, ${result1.point.z}`);
}
```

#### `Polytree.distanceToPoint(input, targetPoint)`

Calculates the shortest distance from a point to any surface.

**Parameters:**
- `input`: Three.js Mesh, BufferGeometry, or Polytree instance to query

**Returns:** Distance as number, or `Infinity` if no surfaces found

**Use Cases:**
- Distance field generation
- Proximity analysis
- Spatial optimization
- Quality control measurements

### Volume-Based Queries

#### `Polytree.intersectsSphere(input, sphere)`

Tests if a sphere intersects with the geometry.

**Parameters:**
- `input`: Three.js Mesh, BufferGeometry, or Polytree instance to test
- `sphere`: Sphere object with `center` and `radius` properties

**Returns:** Boolean indicating intersection

#### `Polytree.intersectsBox(input, boundingBox)`

Tests if a bounding box intersects with the geometry.

**Parameters:**
- `input`: Three.js Mesh, BufferGeometry, or Polytree instance to test
- `boundingBox`: Three.js Box3 object

**Returns:** Boolean indicating intersection

## Slicing Operations (Critical for 3D Printing)

### `Polytree.intersectPlane(polytree, plane, target?)`

Finds intersection line segments between a plane and the mesh surface.

**Parameters:**
- `polytree`: The Polytree instance to slice
- `plane`: Three.js Plane object defining the slicing plane
- `target`: Optional array to store results

**Returns:** Array of Line3 objects representing intersection segments

**Use Cases:**
- Cross-section analysis
- 2D profile extraction
- Geometric validation
- Single-layer slicing

```javascript
const slicePlane = new Plane(new Vector3(0, 0, 1), 0); // Z=0 plane
const intersections = Polytree.intersectPlane(polytree, slicePlane);

intersections.forEach(segment => {
    console.log(`Segment from ${segment.start.x},${segment.start.y} to ${segment.end.x},${segment.end.y}`);
});
```

### `Polytree.sliceIntoLayers(polytree, layerHeight, minZ, maxZ, normal?)`

Creates multiple parallel plane intersections for layer-by-layer slicing - the core operation for 3D printing.

**Parameters:**
- `polytree`: The Polytree instance to slice
- `layerHeight`: Distance between each layer
- `minZ`: Starting Z coordinate
- `maxZ`: Ending Z coordinate
- `normal`: Plane normal vector (default: Z-up)

**Returns:** Array of arrays, each containing Line3 segments for that layer

**Use Cases:**
- 3D printer toolpath generation
- Layer-based analysis
- Manufacturing process simulation
- Additive manufacturing preparation

```javascript
const layers = Polytree.sliceIntoLayers(polytree, 0.2, -5, 5);
console.log(`Generated ${layers.length} layers`);

layers.forEach((layer, index) => {
    console.log(`Layer ${index} has ${layer.length} line segments`);
});
```

## Advanced Spatial Queries

### `Polytree.shapecast(polytree, queryCallback, collectCallback?)`

Generic spatial query system using custom callback functions.

**Parameters:**
- `polytree`: The Polytree instance to query
- `queryCallback`: Function that tests each triangle `(triangle, originalTriangle) => boolean`
- `collectCallback`: Optional function to collect/process matching triangles

**Returns:** Array of results

**Use Cases:**
- Custom geometric analysis
- Complex filtering operations
- Performance optimization
- Specialized measurements

```javascript
// Find triangles facing upward
const upwardTriangles = Polytree.shapecast(polytree, (triangle) => {
    const normal = triangle.getNormal(new Vector3());
    return normal.z > 0.8; // Nearly vertical
});

// Collect triangle centers
const centers = Polytree.shapecast(polytree, 
    () => true, // Accept all triangles
    (triangle) => {
        const center = new Vector3();
        center.add(triangle.a).add(triangle.b).add(triangle.c);
        return center.multiplyScalar(1/3);
    }
);
```

### `Polytree.getTrianglesNearPoint(polytree, targetPoint, searchRadius)`

Finds all triangles within a specified distance of a target point.

**Parameters:**
- `targetPoint`: Vector3 center of search area
- `searchRadius`: Maximum distance to include triangles

**Returns:** Array of triangles within the radius

**Use Cases:**
- Local mesh operations
- Region-based analysis
- Adaptive mesh processing
- Localized modifications

## Volume Analysis

### `Polytree.estimateVolumeViaSampling(polytree, sampleCount?, boundingBox?)`

Calculates approximate volume using Monte Carlo sampling method.

**Parameters:**
- `sampleCount`: Number of random samples (default: 10000)
- `boundingBox`: Optional bounding region for sampling

**Returns:** Estimated volume as number

**Use Cases:**
- Complex geometry volume calculation
- Statistical analysis
- Approximate measurements when exact calculation is too expensive
- Quality control validation

```javascript
// Quick estimate
const roughVolume = Polytree.estimateVolumeViaSampling(polytree, 10000);

// High accuracy estimate
const preciseVolume = Polytree.estimateVolumeViaSampling(polytree, 100000);

console.log(`Estimated volume: ${preciseVolume.toFixed(4)} cubic units`);
```

## 3D Printing Applications

### Complete Slicing Workflow

```javascript
// 1. Load and prepare mesh
const polytree = Polytree.fromMesh(mesh);

// 2. Calculate optimal layer height based on geometry
const boundingBox = new Box3().setFromObject(mesh);
const height = boundingBox.max.z - boundingBox.min.z;
const layerHeight = 0.2; // 0.2mm layers

// 3. Generate all layers
const layers = Polytree.sliceIntoLayers(
    polytree, 
    layerHeight, 
    boundingBox.min.z, 
    boundingBox.max.z
);

// 4. Process each layer for printing
layers.forEach((layer, index) => {
    const zHeight = boundingBox.min.z + (index * layerHeight);
    
    // Generate toolpaths from line segments
    const toolpaths = generateToolpaths(layer);
    
    // Add support structures if needed
    if (needsSupport(layer)) {
        const supports = generateSupports(polytree, zHeight);
        toolpaths.push(...supports);
    }
    
    console.log(`Layer ${index} at Z=${zHeight}: ${toolpaths.length} paths`);
});
```

### Support Structure Generation

```javascript
// Find overhanging areas that need support
const overhangAngle = 45; // degrees
const supportPoints = [];

layers.forEach((layer, index) => {
    layer.forEach(segment => {
        // Check if this segment needs support
        const testPoint = new Vector3().addVectors(segment.start, segment.end).multiplyScalar(0.5);
        const belowPoint = testPoint.clone();
        belowPoint.z -= layerHeight;
        
        // Use closest point to find if there's geometry below
        const result = Polytree.closestPointToPoint(polytree, belowPoint);
        
        if (!result || result.distance > supportThreshold) {
            supportPoints.push(testPoint);
        }
    });
});
```

## Performance Considerations

- **Spatial Partitioning**: Polytree's octree structure provides efficient spatial queries
- **Memory Usage**: Large meshes may require memory optimization
- **Sampling Accuracy**: Volume estimation accuracy increases with sample count
- **Query Optimization**: Use appropriate bounding volumes to limit search space

## Best Practices

1. **Precompute When Possible**: Build Polytree once, query multiple times
2. **Use Appropriate Tolerances**: Set reasonable distance thresholds
3. **Batch Operations**: Group similar queries for better performance
4. **Memory Management**: Call `delete()` on unused Polytree instances
5. **Validation**: Check for valid geometry before complex operations

## Migration from three-mesh-bvh

If migrating from three-mesh-bvh, these Polytree functions provide equivalent functionality:

| three-mesh-bvh | Polytree Equivalent |
|----------------|---------------------|
| `bvh.closestPointToPoint()` | `Polytree.closestPointToPoint()` |
| `bvh.intersectsSphere()` | `Polytree.intersectsSphere()` |
| `bvh.intersectsBox()` | `Polytree.intersectsBox()` |
| `bvh.shapecast()` | `Polytree.shapecast()` |

## Future Enhancements

Planned additions based on three-mesh-bvh capabilities:
- GPU-accelerated queries using compute shaders
- Worker support for background processing
- Advanced BVH optimization strategies
- Specialized collision detection optimizations
- Integration with physics engines