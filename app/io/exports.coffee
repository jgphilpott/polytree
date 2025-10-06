# === CORE GEOMETRY CLASSES ===
# Primary geometric data structures for CSG operations.

module.exports.Polytree = Polytree

module.exports.Plane = Plane
module.exports.Vertex = Vertex
module.exports.Polygon = Polygon

# === BUFFER UTILITIES ===
# Efficient storage and writing of vector data for geometric calculations.

module.exports.createVector2Buffer = createVector2Buffer
module.exports.createVector3Buffer = createVector3Buffer

# === TRIANGLE VALIDATION AND INTERSECTION ===
# Core triangle operations including validation, uniqueness checking, and intersection testing.

module.exports.isValidTriangle = isValidTriangle
module.exports.isUniqueTriangle = isUniqueTriangle
module.exports.rayIntersectsTriangle = testRayTriangleIntersection
module.exports.triangleIntersectsTriangle = triangleIntersectsTriangle

# === TRIANGLE INTERSECTION RESOLUTION ===
# Advanced intersection resolution for both general and coplanar triangle cases.

module.exports.resolveTriangleIntersection = resolveTriangleIntersection
module.exports.resolveCoplanarTriangleIntersection = resolveCoplanarTriangleIntersection

# === GEOMETRIC UTILITIES ===
# Point manipulation, coordinate extraction, and spatial calculations.

module.exports.sortRaycastIntersectionsByDistance = sortRaycastIntersectionsByDistance
module.exports.roundPointCoordinates = roundPointCoordinates
module.exports.extractCoordinatesFromArray = extractCoordinatesFromArray

# === POLYGON OPERATIONS ===
# Polygon splitting, buffer preparation, and CSG-related polygon management.

module.exports.splitPolygonByPlane = splitPolygonByPlane
module.exports.splitPolygonVertexArray = splitPolygonVertexArray
module.exports.prepareTriangleBufferFromPolygons = prepareTriangleBufferFromPolygons

# === WINDING NUMBER AND INSIDE/OUTSIDE TESTING ===
# Robust point-in-polygon testing using winding number algorithms.

module.exports.calculateWindingNumberFromBuffer = calculateWindingNumberFromBuffer
module.exports.testPolygonInsideUsingWindingNumber = testPolygonInsideUsingWindingNumber

# === RAY-TRIANGLE INTERSECTION ===
# High-performance ray-triangle intersection testing for raycasting operations.

module.exports.testRayTriangleIntersection = testRayTriangleIntersection

# === POLYTREE RESOURCE MANAGEMENT ===
# Memory management and cleanup utilities for Polytree operations.

module.exports.handleIntersectingPolytrees = handleIntersectingPolytrees
module.exports.disposePolytreeResources = disposePolytreeResources

# === 2D TRIANGLE OPERATIONS ===
# Specialized 2D triangle overlap and intersection testing for planar geometry.

module.exports.trianglesOverlap2D = trianglesOverlap2D
module.exports.triangleOrientation2D = triangleOrientation2D
module.exports.triangleIntersectionCCW2D = triangleIntersectionCCW2D

# === 2D INTERSECTION TESTING ===
# Low-level 2D edge and vertex intersection tests for triangle operations.

module.exports.intersectionTestEdge2D = intersectionTestEdge2D
module.exports.intersectionTestVertex2D = intersectionTestVertex2D

# === INTERSECTION CONSTRUCTION ===
# Low-level intersection construction utilities for building intersection results.

module.exports.constructIntersection = constructIntersection

# === VOLUME CALCULATION UTILITIES ===
# Helper functions for calculating volumes of 3D geometries.

module.exports.signedVolumeOfTriangle = signedVolumeOfTriangle

# === MESH CONVERSION AND ANALYSIS FUNCTIONS ===
# Mesh conversion utilities and surface/volume analysis functions.

module.exports.toGeometry = Polytree.toGeometry
module.exports.toMesh = Polytree.toMesh
module.exports.fromMesh = Polytree.fromMesh
module.exports.getSurface = Polytree.getSurface
module.exports.getVolume = Polytree.getVolume

# === SPATIAL QUERY FUNCTIONS ===
# Advanced spatial querying capabilities for 3D printing, CAD operations, and geometric analysis.

module.exports.closestPointToPoint = Polytree.closestPointToPoint
module.exports.distanceToPoint = Polytree.distanceToPoint
module.exports.intersectsSphere = Polytree.intersectsSphere
module.exports.intersectsBox = Polytree.intersectsBox
module.exports.intersectPlane = Polytree.intersectPlane
module.exports.sliceIntoLayers = Polytree.sliceIntoLayers
module.exports.shapecast = Polytree.shapecast
module.exports.getTrianglesNearPoint = Polytree.getTrianglesNearPoint
module.exports.estimateVolumeViaSampling = Polytree.estimateVolumeViaSampling
