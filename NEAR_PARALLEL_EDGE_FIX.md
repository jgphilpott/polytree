# Near-Parallel Edge Detection Fix

## Problem

The `sliceIntoLayers` method was failing to generate segments for edges nearly parallel to the slice plane (< 1° angle). This caused gaps in layer slicing (0.60mm - 5.8mm) which prevented closed path formation in 3D printing applications.

## Root Cause

The original implementation used exact floating-point equality checks:
```coffeescript
continue if startDist is 0 and endDist is 0
if startDist is 0
if endDist is 0
```

For edges nearly parallel to the plane, the distances to the plane (`startDist` and `endDist`) are extremely small but non-zero (e.g., 1e-15). These edges were incorrectly skipped, creating gaps in the generated segment chains.

## Solution

Implemented an **angle-aware adaptive epsilon** approach:

### 1. Calculate Edge Angle
```coffeescript
edgeDir = edgeVector.clone().divideScalar(edgeLength)
dotWithNormal = Math.abs(edgeDir.dot(planeNormal))
```

The dot product between the edge direction and plane normal indicates how parallel the edge is to the plane:
- `dotWithNormal ≈ 0`: Edge is parallel to plane
- `dotWithNormal ≈ 1`: Edge is perpendicular to plane

### 2. Adaptive Epsilon Calculation
```coffeescript
baseEpsilon = Math.max(1e-10, edgeLength * 1e-9)
angleFactor = if dotWithNormal < 0.02 then 100.0 else 1.0
epsilon = baseEpsilon * angleFactor
```

- **Base epsilon**: Scales with edge length to handle floating-point precision errors
- **Angle factor**: For near-parallel edges (< ~1° angle), increase epsilon by 100x
- **Final epsilon**: Product of base and angle factor

### 3. Epsilon-Based Comparisons
```coffeescript
absStartDist = Math.abs(startDist)
absEndDist = Math.abs(endDist)

# Skip edges entirely in plane
continue if absStartDist < epsilon and absEndDist < epsilon

# Check if edge crosses or touches plane
if absStartDist < epsilon
    # Start point on or very near plane
if absEndDist < epsilon
    # End point on or very near plane
```

## Test Coverage

Added 4 comprehensive test cases:

1. **Near-parallel edges**: Edges with vertices within 2e-7 of plane
2. **Very small distances**: Tests 1e-10 precision floating-point errors
3. **Duplicate detection**: Ensures epsilon tolerance doesn't create duplicates
4. **Long edges**: Tests 200+ unit edges with scaled epsilon

All 507 tests pass (503 existing + 4 new).

## Impact

This fix ensures:
- ✅ Edges nearly parallel to slice plane are correctly detected
- ✅ Long edges with accumulated floating-point errors are handled
- ✅ Backward compatible - existing functionality unchanged
- ✅ Resolves gaps in layer slicing for complex geometries (e.g., Benchy model)

## Example

```javascript
const Polytree = require('@jgphilpott/polytree');

// Create geometry with near-parallel edges
const geometry = createGeometryWithNearParallelEdges();
const mesh = new THREE.Mesh(geometry, material);

// Slice at Z=1.0 - now correctly handles near-parallel edges
const layers = Polytree.sliceIntoLayers(mesh, 0.2, 0, 2);
```

Before fix: Missing segments, gaps in paths
After fix: Complete segment chains, closed paths

## References

- Issue analysis: [polyslice PR #69 comment](https://github.com/jgphilpott/polyslice/pull/69#issuecomment-3538692023)
- Performance report: POLYTREE_PERFORMANCE_REPORT.md in polyslice PR #69
- Benchmark analysis: BENCHMARK_SUMMARY.md in polyslice PR #69
