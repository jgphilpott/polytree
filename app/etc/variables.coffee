# =============================================================================
# MATHEMATICAL CONSTANTS
# Constants used for floating-point precision, geometry, and mathematical operations
# =============================================================================

# Floating-point tolerance for general geometric operations
GEOMETRIC_EPSILON = 1e-5

# Ultra-high precision tolerance for ray-triangle intersection calculations
RAY_INTERSECTION_EPSILON = 0.0000001

# 2D geometry tolerance for triangle overlap calculations  
TRIANGLE_2D_EPSILON = 1e-10

# Full rotation constant (4π) used in winding number calculations
WINDING_NUMBER_FULL_ROTATION = 4 * Math.PI


# =============================================================================
# POLYGON CLASSIFICATION CONSTANTS
# Used for determining spatial relationships between polygons and planes
# =============================================================================

# Polygon lies exactly on the splitting plane
POLYGON_COPLANAR = 0

# Polygon lies entirely in front of the splitting plane
POLYGON_FRONT = 1

# Polygon lies entirely behind the splitting plane  
POLYGON_BACK = 2

# Polygon crosses the splitting plane (requires splitting)
POLYGON_SPANNING = 3


# =============================================================================
# GENERAL PURPOSE TEMPORARY OBJECTS
# Reusable objects to avoid memory allocation during calculations
# =============================================================================

# Primary temporary vector for general 3D calculations
temporaryVector3Primary = new Vector3()

# Secondary temporary vector for 3D calculations when two vectors needed
temporaryVector3Secondary = new Vector3()

# Tertiary temporary vector for calculations requiring three vectors
temporaryVector3Tertiary = new Vector3()

# Temporary bounding box for spatial calculations
temporaryBoundingBox = new Box3()

# Temporary raycaster for intersection calculations
temporaryRaycaster = new Raycaster()

# Temporary ray object for geometric queries
temporaryRay = new Ray()

# Default ray direction pointing along positive Z-axis
defaultRayDirection = new Vector3(0, 0, 1)


# =============================================================================
# WINDING NUMBER ALGORITHM VARIABLES
# Used for point-in-polygon testing using the winding number method
# =============================================================================

# First vertex vector relative to test point
windingNumberVector1 = new Vector3()

# Second vertex vector relative to test point  
windingNumberVector2 = new Vector3()

# Third vertex vector relative to test point
windingNumberVector3 = new Vector3()

# Test point position vector
windingNumberTestPoint = new Vector3()

# Epsilon offset vectors for handling edge cases in winding number calculation
windingNumberEpsilonOffsets = [
    new Vector3(GEOMETRIC_EPSILON, 0, 0)
    new Vector3(0, GEOMETRIC_EPSILON, 0)
    new Vector3(0, 0, GEOMETRIC_EPSILON)
    new Vector3(-GEOMETRIC_EPSILON, 0, 0)
    new Vector3(0, -GEOMETRIC_EPSILON, 0)
    new Vector3(0, 0, -GEOMETRIC_EPSILON)
]

# Count of epsilon offset vectors for iteration
windingNumberEpsilonOffsetsCount = windingNumberEpsilonOffsets.length

# 3x3 matrix for winding number determinant calculations
windingNumberMatrix3 = new Matrix3()


# =============================================================================
# RAY-TRIANGLE INTERSECTION VARIABLES
# Used in Möller–Trumbore ray-triangle intersection algorithm
# =============================================================================

# Triangle edge vector from vertex A to vertex B
rayTriangleEdge1 = new Vector3()

# Triangle edge vector from vertex A to vertex C  
rayTriangleEdge2 = new Vector3()

# Cross product of ray direction and second edge
rayTriangleHVector = new Vector3()

# Vector from ray origin to triangle vertex A
rayTriangleSVector = new Vector3()

# Cross product for final intersection calculation
rayTriangleQVector = new Vector3()


# =============================================================================
# MATRIX AND TRANSFORMATION VARIABLES
# Used for coordinate transformations and matrix operations
# =============================================================================

# Temporary vertex position for geometric calculations
temporaryTriangleVertex = new Vector3()

# Second temporary vertex for calculations requiring multiple vertices
temporaryTriangleVertexSecondary = new Vector3()

# Temporary 3x3 matrix for normal transformations and general calculations
temporaryMatrix3 = new Matrix3()

# Extended temporary matrix with normal matrix calculation method
temporaryMatrixWithNormalCalc = new Matrix3()

# Method to calculate normal matrix from 4x4 transformation matrix
temporaryMatrixWithNormalCalc.getNormalMatrix = (matrix) ->
    @setFromMatrix4(matrix).invert().transpose()


# =============================================================================
# CSG AND OCTREE OPERATION VARIABLES
# Variables for Constructive Solid Geometry and spatial partitioning
# =============================================================================

# Maximum subdivision depth for octree structures
OCTREE_MAX_DEPTH = 10

# Maximum polygons per octree node before subdivision
OCTREE_MAX_POLYGONS_PER_NODE = 50

# Minimum octree node size to prevent excessive subdivision
OCTREE_MIN_NODE_SIZE = 0.001


# =============================================================================
# PERFORMANCE AND OPTIMIZATION VARIABLES
# Settings for balancing accuracy vs performance
# =============================================================================

# Default precision for point coordinate rounding
DEFAULT_COORDINATE_PRECISION = 15

# Threshold for considering two points as identical
POINT_COINCIDENCE_THRESHOLD = 1e-12

# Buffer size for batch processing operations
DEFAULT_BUFFER_SIZE = 1024


# =============================================================================
# BACKWARDS COMPATIBILITY ALIASES
# Maintain compatibility with existing code while transitioning
# =============================================================================

# Legacy aliases for temporary vectors (to be removed in future versions)
tempVector1 = temporaryVector3Primary
tempVector2 = temporaryVector3Secondary
tempBox3 = temporaryBoundingBox
tempRaycaster = temporaryRaycaster
tempRay = temporaryRay
tempRayDirection = defaultRayDirection

# Legacy aliases for constants
EPSILON = GEOMETRIC_EPSILON
COPLANAR = POLYGON_COPLANAR
FRONT = POLYGON_FRONT
BACK = POLYGON_BACK
SPANNING = POLYGON_SPANNING

# Legacy aliases for winding number variables
_wV1 = windingNumberVector1
_wV2 = windingNumberVector2
_wV3 = windingNumberVector3
_wP = windingNumberTestPoint
_wP_EPS_ARR = windingNumberEpsilonOffsets
_wP_EPS_ARR_COUNT = windingNumberEpsilonOffsetsCount
_matrix3 = windingNumberMatrix3
wNPI = WINDING_NUMBER_FULL_ROTATION

# Legacy aliases for ray-triangle intersection
edge1 = rayTriangleEdge1
edge2 = rayTriangleEdge2
h = rayTriangleHVector
s = rayTriangleSVector
q = rayTriangleQVector
RAY_EPSILON = RAY_INTERSECTION_EPSILON

# Legacy aliases for matrix operations
triangleVertex0 = temporaryTriangleVertex
tmpm3 = temporaryMatrixWithNormalCalc