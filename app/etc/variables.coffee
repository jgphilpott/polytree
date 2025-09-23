# =============================================================================
# MATHEMATICAL CONSTANTS
# Constants used for floating-point precision, geometry, and mathematical operations.
# =============================================================================

# Floating-point tolerance for general geometric operations.
GEOMETRIC_EPSILON = 1e-8

# Ultra-high precision tolerance for ray-triangle intersection calculations.
RAY_INTERSECTION_EPSILON = 1e-12

# 2D geometry tolerance for triangle overlap calculations.
TRIANGLE_2D_EPSILON = 1e-14

# Full rotation constant (4π) used in winding number calculations.
WINDING_NUMBER_FULL_ROTATION = 4 * Math.PI

# =============================================================================
# POLYGON CLASSIFICATION CONSTANTS
# Used for determining spatial relationships between polygons and planes.
# =============================================================================

# Polygon lies exactly on the splitting plane.
POLYGON_COPLANAR = 0

# Polygon lies entirely in front of the splitting plane.
POLYGON_FRONT = 1

# Polygon lies entirely behind the splitting plane
POLYGON_BACK = 2

# Polygon crosses the splitting plane (requires splitting).
POLYGON_SPANNING = 3

# =============================================================================
# GENERAL PURPOSE TEMPORARY OBJECTS
# Reusable objects to avoid memory allocation during calculations.
# =============================================================================

# Primary temporary vector for general 3D calculations.
temporaryVector3Primary = new Vector3()

# Secondary temporary vector for 3D calculations when two vectors needed.
temporaryVector3Secondary = new Vector3()

# Tertiary temporary vector for calculations requiring three vectors.
temporaryVector3Tertiary = new Vector3()

# Quaternary temporary vector for triangle-specific calculations.
temporaryVector3Quaternary = new Vector3()

# Temporary bounding box for spatial calculations.
temporaryBoundingBox = new Box3()

# Temporary raycaster for intersection calculations.
temporaryRaycaster = new Raycaster()

# Temporary ray object for geometric queries.
temporaryRay = new Ray()

# Default ray direction pointing along positive Z-axis.
defaultRayDirection = new Vector3(0, 0, 1)

# =============================================================================
# WINDING NUMBER ALGORITHM VARIABLES
# Used for point-in-polygon testing using the winding number method.
# =============================================================================

# First vertex vector relative to test point.
windingNumberVector1 = new Vector3()

# Second vertex vector relative to test point.
windingNumberVector2 = new Vector3()

# Third vertex vector relative to test point.
windingNumberVector3 = new Vector3()

# Test point position vector.
windingNumberTestPoint = new Vector3()

# Epsilon offset vectors for handling edge cases in winding number calculation.
windingNumberEpsilonOffsets = [

    new Vector3(GEOMETRIC_EPSILON, 0, 0)
    new Vector3(0, GEOMETRIC_EPSILON, 0)
    new Vector3(0, 0, GEOMETRIC_EPSILON)
    new Vector3(-GEOMETRIC_EPSILON, 0, 0)
    new Vector3(0, -GEOMETRIC_EPSILON, 0)
    new Vector3(0, 0, -GEOMETRIC_EPSILON)

]

# Count of epsilon offset vectors for iteration.
windingNumberEpsilonOffsetsCount = windingNumberEpsilonOffsets.length

# 3x3 matrix for winding number determinant calculations.
windingNumberMatrix3 = new Matrix3()

# =============================================================================
# RAY-TRIANGLE INTERSECTION VARIABLES
# Used in Möller–Trumbore ray-triangle intersection algorithm.
# =============================================================================

# Triangle edge vector from vertex A to vertex B.
rayTriangleEdge1 = new Vector3()

# Triangle edge vector from vertex A to vertex C.
rayTriangleEdge2 = new Vector3()

# Cross product of ray direction and second edge.
rayTriangleHVector = new Vector3()

# Vector from ray origin to triangle vertex A.
rayTriangleSVector = new Vector3()

# Cross product for final intersection calculation.
rayTriangleQVector = new Vector3()

# =============================================================================
# MATRIX AND TRANSFORMATION VARIABLES
# Used for coordinate transformations and matrix operations.
# =============================================================================

# Temporary vertex position for geometric calculations.
temporaryTriangleVertex = new Vector3()

# Second temporary vertex for calculations requiring multiple vertices.
temporaryTriangleVertexSecondary = new Vector3()

# Temporary 3x3 matrix for normal transformations and general calculations.
temporaryMatrix3 = new Matrix3()

# Extended temporary matrix with normal matrix calculation method.
temporaryMatrixWithNormalCalc = new Matrix3()

# Method to calculate normal matrix from 4x4 transformation matrix.
temporaryMatrixWithNormalCalc.getNormalMatrix = (matrix) ->

    @setFromMatrix4(matrix).invert().transpose()

# Temporary vector for mesh normal calculations and geometry operations.
meshOperationNormalVector = new Vector3()

# Temporary vertex vector for mesh transformation and vertex operations.
meshOperationVertexVector = new Vector3()

# =============================================================================
# CSG AND POLYTREE OPERATION VARIABLES
# Variables for Constructive Solid Geometry and spatial partitioning.
# =============================================================================

# Maximum subdivision depth for polytree structures.
POLYTREE_MAX_DEPTH = 1000

# Maximum polygons per polytree node before subdivision.
POLYTREE_MAX_POLYGONS_PER_NODE = 100000

# Minimum polytree node size to prevent excessive subdivision.
POLYTREE_MIN_NODE_SIZE = 1e-6

# Default material index for CSG operations.
DEFAULT_MATERIAL_INDEX = 0

# Maximum iterations for iterative refinement algorithms.
MAX_REFINEMENT_ITERATIONS = 10000

# =============================================================================
# PERFORMANCE AND OPTIMIZATION VARIABLES
# Settings for balancing accuracy vs performance.
# =============================================================================

# Default precision for point coordinate rounding.
DEFAULT_COORDINATE_PRECISION = 15

# Threshold for considering two points as identical.
POINT_COINCIDENCE_THRESHOLD = 1e-15

# Buffer size for batch processing operations.
DEFAULT_BUFFER_SIZE = 16384

# Maximum number of worker threads for parallel processing.
MAX_WORKER_THREADS = Infinity

# Timeout for async operations (in milliseconds).
ASYNC_OPERATION_TIMEOUT = Infinity

# Memory management thresholds.
GARBAGE_COLLECTION_THRESHOLD = 100000
MEMORY_USAGE_WARNING_LIMIT = 0.95

# Cache size limits.
GEOMETRY_CACHE_SIZE = Infinity
INTERSECTION_CACHE_SIZE = Infinity

# =============================================================================
# POLYGON ID MANAGEMENT
# Global counter for assigning unique IDs to polygon instances.
# =============================================================================

# Global polygon ID counter for unique polygon identification.
polygonID = 0

# =============================================================================
# DEBUGGING AND DEVELOPMENT VARIABLES
# Variables useful for debugging and development.
# =============================================================================

# Enable detailed logging for debugging.
DEBUG_VERBOSE_LOGGING = false

# Enable performance timing measurements.
DEBUG_PERFORMANCE_TIMING = false

# Enable geometry validation checks.
DEBUG_GEOMETRY_VALIDATION = false

# Enable intersection result verification.
DEBUG_INTERSECTION_VERIFICATION = false

# Color codes for debug visualization.
DEBUG_COLOR_FRONT = 0x00ff00
DEBUG_COLOR_BACK = 0xff0000
DEBUG_COLOR_COPLANAR = 0x0000ff
DEBUG_COLOR_SPANNING = 0xffff00

# =============================================================================
# EXPORTS FOR TESTING
# Export all variables so they can be tested.
# =============================================================================

# Only export when in a testing environment (when module.exports exists).
if typeof module != 'undefined' and module.exports

    # Mathematical Constants
    module.exports.GEOMETRIC_EPSILON = GEOMETRIC_EPSILON
    module.exports.RAY_INTERSECTION_EPSILON = RAY_INTERSECTION_EPSILON
    module.exports.TRIANGLE_2D_EPSILON = TRIANGLE_2D_EPSILON
    module.exports.WINDING_NUMBER_FULL_ROTATION = WINDING_NUMBER_FULL_ROTATION

    # Polygon Classification Constants
    module.exports.POLYGON_COPLANAR = POLYGON_COPLANAR
    module.exports.POLYGON_FRONT = POLYGON_FRONT
    module.exports.POLYGON_BACK = POLYGON_BACK
    module.exports.POLYGON_SPANNING = POLYGON_SPANNING

    # General Purpose Temporary Objects
    module.exports.temporaryVector3Primary = temporaryVector3Primary
    module.exports.temporaryVector3Secondary = temporaryVector3Secondary
    module.exports.temporaryVector3Tertiary = temporaryVector3Tertiary
    module.exports.temporaryVector3Quaternary = temporaryVector3Quaternary
    module.exports.temporaryBoundingBox = temporaryBoundingBox
    module.exports.temporaryRaycaster = temporaryRaycaster
    module.exports.temporaryRay = temporaryRay
    module.exports.defaultRayDirection = defaultRayDirection

    # Winding Number Algorithm Variables
    module.exports.windingNumberVector1 = windingNumberVector1
    module.exports.windingNumberVector2 = windingNumberVector2
    module.exports.windingNumberVector3 = windingNumberVector3
    module.exports.windingNumberTestPoint = windingNumberTestPoint
    module.exports.windingNumberEpsilonOffsets = windingNumberEpsilonOffsets
    module.exports.windingNumberEpsilonOffsetsCount = windingNumberEpsilonOffsetsCount
    module.exports.windingNumberMatrix3 = windingNumberMatrix3

    # Ray-Triangle Intersection Variables
    module.exports.rayTriangleEdge1 = rayTriangleEdge1
    module.exports.rayTriangleEdge2 = rayTriangleEdge2
    module.exports.rayTriangleHVector = rayTriangleHVector
    module.exports.rayTriangleSVector = rayTriangleSVector
    module.exports.rayTriangleQVector = rayTriangleQVector

    # Matrix and Transformation Variables
    module.exports.temporaryTriangleVertex = temporaryTriangleVertex
    module.exports.temporaryTriangleVertexSecondary = temporaryTriangleVertexSecondary
    module.exports.temporaryMatrix3 = temporaryMatrix3
    module.exports.temporaryMatrixWithNormalCalc = temporaryMatrixWithNormalCalc
    module.exports.meshOperationNormalVector = meshOperationNormalVector
    module.exports.meshOperationVertexVector = meshOperationVertexVector

    # CSG and Polytree Operation Variables
    module.exports.POLYTREE_MAX_DEPTH = POLYTREE_MAX_DEPTH
    module.exports.POLYTREE_MAX_POLYGONS_PER_NODE = POLYTREE_MAX_POLYGONS_PER_NODE
    module.exports.POLYTREE_MIN_NODE_SIZE = POLYTREE_MIN_NODE_SIZE
    module.exports.DEFAULT_MATERIAL_INDEX = DEFAULT_MATERIAL_INDEX
    module.exports.MAX_REFINEMENT_ITERATIONS = MAX_REFINEMENT_ITERATIONS

    # Performance and Optimization Variables
    module.exports.DEFAULT_COORDINATE_PRECISION = DEFAULT_COORDINATE_PRECISION
    module.exports.POINT_COINCIDENCE_THRESHOLD = POINT_COINCIDENCE_THRESHOLD
    module.exports.DEFAULT_BUFFER_SIZE = DEFAULT_BUFFER_SIZE
    module.exports.MAX_WORKER_THREADS = MAX_WORKER_THREADS
    module.exports.ASYNC_OPERATION_TIMEOUT = ASYNC_OPERATION_TIMEOUT
    module.exports.GARBAGE_COLLECTION_THRESHOLD = GARBAGE_COLLECTION_THRESHOLD
    module.exports.MEMORY_USAGE_WARNING_LIMIT = MEMORY_USAGE_WARNING_LIMIT
    module.exports.GEOMETRY_CACHE_SIZE = GEOMETRY_CACHE_SIZE
    module.exports.INTERSECTION_CACHE_SIZE = INTERSECTION_CACHE_SIZE

    # Polygon ID Management
    module.exports.polygonID = polygonID

    # Debugging and Development Variables
    module.exports.DEBUG_VERBOSE_LOGGING = DEBUG_VERBOSE_LOGGING
    module.exports.DEBUG_PERFORMANCE_TIMING = DEBUG_PERFORMANCE_TIMING
    module.exports.DEBUG_GEOMETRY_VALIDATION = DEBUG_GEOMETRY_VALIDATION
    module.exports.DEBUG_INTERSECTION_VERIFICATION = DEBUG_INTERSECTION_VERIFICATION
    module.exports.DEBUG_COLOR_FRONT = DEBUG_COLOR_FRONT
    module.exports.DEBUG_COLOR_BACK = DEBUG_COLOR_BACK
    module.exports.DEBUG_COLOR_COPLANAR = DEBUG_COLOR_COPLANAR
    module.exports.DEBUG_COLOR_SPANNING = DEBUG_COLOR_SPANNING
