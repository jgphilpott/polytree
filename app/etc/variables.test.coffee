{ Vector3, Box3, Raycaster, Ray, Matrix3 } = require "three"

# Create a context where Three.js is available globally so variables.js can execute.
global.Vector3 = Vector3
global.Box3 = Box3
global.Raycaster = Raycaster
global.Ray = Ray
global.Matrix3 = Matrix3

# Import all variables from the variables module.
{

    # Mathematical Constants
    GEOMETRIC_EPSILON
    RAY_INTERSECTION_EPSILON
    TRIANGLE_2D_EPSILON
    WINDING_NUMBER_FULL_ROTATION

    # Polygon Classification Constants
    POLYGON_COPLANAR
    POLYGON_FRONT
    POLYGON_BACK
    POLYGON_SPANNING

    # General Purpose Temporary Objects
    temporaryVector3Primary
    temporaryVector3Secondary
    temporaryVector3Tertiary
    temporaryVector3Quaternary
    temporaryBoundingBox
    temporaryRaycaster
    temporaryRay
    defaultRayDirection

    # Winding Number Algorithm Variables
    windingNumberVector1
    windingNumberVector2
    windingNumberVector3
    windingNumberTestPoint
    windingNumberEpsilonOffsets
    windingNumberEpsilonOffsetsCount
    windingNumberMatrix3

    # Ray-Triangle Intersection Variables
    rayTriangleEdge1
    rayTriangleEdge2
    rayTriangleHVector
    rayTriangleSVector
    rayTriangleQVector

    # Matrix and Transformation Variables
    temporaryTriangleVertex
    temporaryTriangleVertexSecondary
    temporaryMatrix3
    temporaryMatrixWithNormalCalc

    # CSG and Octree Operation Variables
    OCTREE_MAX_DEPTH
    OCTREE_MAX_POLYGONS_PER_NODE
    OCTREE_MIN_NODE_SIZE
    DEFAULT_MATERIAL_INDEX
    MAX_REFINEMENT_ITERATIONS

    # Performance and Optimization Variables
    DEFAULT_COORDINATE_PRECISION
    POINT_COINCIDENCE_THRESHOLD
    DEFAULT_BUFFER_SIZE
    MAX_WORKER_THREADS
    ASYNC_OPERATION_TIMEOUT
    GARBAGE_COLLECTION_THRESHOLD
    MEMORY_USAGE_WARNING_LIMIT
    GEOMETRY_CACHE_SIZE
    INTERSECTION_CACHE_SIZE

    # Polygon ID Management
    polygonID

    # Debugging and Development Variables
    DEBUG_VERBOSE_LOGGING
    DEBUG_PERFORMANCE_TIMING
    DEBUG_GEOMETRY_VALIDATION
    DEBUG_INTERSECTION_VERIFICATION
    DEBUG_COLOR_FRONT
    DEBUG_COLOR_BACK
    DEBUG_COLOR_COPLANAR
    DEBUG_COLOR_SPANNING

} = require "./variables.js"

# Test tolerance for floating point comparisons.
TOL = 1e-12

describe "Variables module", ->

    describe "Mathematical Constants", ->

        it "GEOMETRIC_EPSILON should be a number with correct value", ->

            expect(typeof GEOMETRIC_EPSILON).toBe("number")
            expect(GEOMETRIC_EPSILON).toBe(1e-5)

        it "RAY_INTERSECTION_EPSILON should be a number with correct value", ->

            expect(typeof RAY_INTERSECTION_EPSILON).toBe("number")
            expect(RAY_INTERSECTION_EPSILON).toBe(0.0000001)

        it "TRIANGLE_2D_EPSILON should be a number with correct value", ->

            expect(typeof TRIANGLE_2D_EPSILON).toBe("number")
            expect(TRIANGLE_2D_EPSILON).toBe(1e-10)

        it "WINDING_NUMBER_FULL_ROTATION should be a number with correct value", ->

            expect(typeof WINDING_NUMBER_FULL_ROTATION).toBe("number")
            expect(Math.abs(WINDING_NUMBER_FULL_ROTATION - 4 * Math.PI)).toBeLessThan(TOL)

    describe "Polygon Classification Constants", ->

        it "POLYGON_COPLANAR should be a number with value 0", ->

            expect(typeof POLYGON_COPLANAR).toBe("number")
            expect(POLYGON_COPLANAR).toBe(0)

        it "POLYGON_FRONT should be a number with value 1", ->

            expect(typeof POLYGON_FRONT).toBe("number")
            expect(POLYGON_FRONT).toBe(1)

        it "POLYGON_BACK should be a number with value 2", ->

            expect(typeof POLYGON_BACK).toBe("number")
            expect(POLYGON_BACK).toBe(2)

        it "POLYGON_SPANNING should be a number with value 3", ->

            expect(typeof POLYGON_SPANNING).toBe("number")
            expect(POLYGON_SPANNING).toBe(3)

    describe "General Purpose Temporary Objects", ->

        it "temporaryVector3Primary should be a Vector3 instance", ->

            expect(temporaryVector3Primary).toBeInstanceOf(Vector3)

        it "temporaryVector3Secondary should be a Vector3 instance", ->

            expect(temporaryVector3Secondary).toBeInstanceOf(Vector3)

        it "temporaryVector3Tertiary should be a Vector3 instance", ->

            expect(temporaryVector3Tertiary).toBeInstanceOf(Vector3)

        it "temporaryVector3Quaternary should be a Vector3 instance", ->

            expect(temporaryVector3Quaternary).toBeInstanceOf(Vector3)

        it "temporaryBoundingBox should be a Box3 instance", ->

            expect(temporaryBoundingBox).toBeInstanceOf(Box3)

        it "temporaryRaycaster should be a Raycaster instance", ->

            expect(temporaryRaycaster).toBeInstanceOf(Raycaster)

        it "temporaryRay should be a Ray instance", ->

            expect(temporaryRay).toBeInstanceOf(Ray)

        it "defaultRayDirection should be a Vector3 with correct initial value", ->

            expect(defaultRayDirection).toBeInstanceOf(Vector3)

            expect(defaultRayDirection.x).toBe(0)
            expect(defaultRayDirection.y).toBe(0)
            expect(defaultRayDirection.z).toBe(1)

    describe "Winding Number Algorithm Variables", ->

        it "windingNumberVector1 should be a Vector3 instance", ->

            expect(windingNumberVector1).toBeInstanceOf(Vector3)

        it "windingNumberVector2 should be a Vector3 instance", ->

            expect(windingNumberVector2).toBeInstanceOf(Vector3)

        it "windingNumberVector3 should be a Vector3 instance", ->

            expect(windingNumberVector3).toBeInstanceOf(Vector3)

        it "windingNumberTestPoint should be a Vector3 instance", ->

            expect(windingNumberTestPoint).toBeInstanceOf(Vector3)

        it "windingNumberEpsilonOffsets should be an array of Vector3 instances", ->

            expect(Array.isArray(windingNumberEpsilonOffsets)).toBe(true)
            expect(windingNumberEpsilonOffsets.length).toBe(6)

            windingNumberEpsilonOffsets.forEach (offset) ->

                expect(offset).toBeInstanceOf(Vector3)

        it "windingNumberEpsilonOffsetsCount should equal array length", ->

            expect(typeof windingNumberEpsilonOffsetsCount).toBe("number")
            expect(windingNumberEpsilonOffsetsCount).toBe(windingNumberEpsilonOffsets.length)

        it "windingNumberMatrix3 should be a Matrix3 instance", ->

            expect(windingNumberMatrix3).toBeInstanceOf(Matrix3)

    describe "Ray-Triangle Intersection Variables", ->

        it "rayTriangleEdge1 should be a Vector3 instance", ->

            expect(rayTriangleEdge1).toBeInstanceOf(Vector3)

        it "rayTriangleEdge2 should be a Vector3 instance", ->

            expect(rayTriangleEdge2).toBeInstanceOf(Vector3)

        it "rayTriangleHVector should be a Vector3 instance", ->

            expect(rayTriangleHVector).toBeInstanceOf(Vector3)

        it "rayTriangleSVector should be a Vector3 instance", ->

            expect(rayTriangleSVector).toBeInstanceOf(Vector3)

        it "rayTriangleQVector should be a Vector3 instance", ->

            expect(rayTriangleQVector).toBeInstanceOf(Vector3)

    describe "Matrix and Transformation Variables", ->

        it "temporaryTriangleVertex should be a Vector3 instance", ->

            expect(temporaryTriangleVertex).toBeInstanceOf(Vector3)

        it "temporaryTriangleVertexSecondary should be a Vector3 instance", ->

            expect(temporaryTriangleVertexSecondary).toBeInstanceOf(Vector3)

        it "temporaryMatrix3 should be a Matrix3 instance", ->

            expect(temporaryMatrix3).toBeInstanceOf(Matrix3)

        it "temporaryMatrixWithNormalCalc should be a Matrix3 instance with getNormalMatrix method", ->

            expect(temporaryMatrixWithNormalCalc).toBeInstanceOf(Matrix3)
            expect(typeof temporaryMatrixWithNormalCalc.getNormalMatrix).toBe("function")

    describe "CSG and Octree Operation Variables", ->

        it "OCTREE_MAX_DEPTH should be a number", ->

            expect(typeof OCTREE_MAX_DEPTH).toBe("number")
            expect(OCTREE_MAX_DEPTH).toBe(10)

        it "OCTREE_MAX_POLYGONS_PER_NODE should be a number", ->

            expect(typeof OCTREE_MAX_POLYGONS_PER_NODE).toBe("number")
            expect(OCTREE_MAX_POLYGONS_PER_NODE).toBe(50)

        it "OCTREE_MIN_NODE_SIZE should be a number", ->

            expect(typeof OCTREE_MIN_NODE_SIZE).toBe("number")
            expect(OCTREE_MIN_NODE_SIZE).toBe(0.001)

        it "DEFAULT_MATERIAL_INDEX should be a number", ->

            expect(typeof DEFAULT_MATERIAL_INDEX).toBe("number")
            expect(DEFAULT_MATERIAL_INDEX).toBe(0)

        it "MAX_REFINEMENT_ITERATIONS should be a number", ->

            expect(typeof MAX_REFINEMENT_ITERATIONS).toBe("number")
            expect(MAX_REFINEMENT_ITERATIONS).toBe(100)

    describe "Performance and Optimization Variables", ->

        it "DEFAULT_COORDINATE_PRECISION should be a number", ->

            expect(typeof DEFAULT_COORDINATE_PRECISION).toBe("number")
            expect(DEFAULT_COORDINATE_PRECISION).toBe(15)

        it "POINT_COINCIDENCE_THRESHOLD should be a number", ->

            expect(typeof POINT_COINCIDENCE_THRESHOLD).toBe("number")
            expect(POINT_COINCIDENCE_THRESHOLD).toBe(1e-12)

        it "DEFAULT_BUFFER_SIZE should be a number", ->

            expect(typeof DEFAULT_BUFFER_SIZE).toBe("number")
            expect(DEFAULT_BUFFER_SIZE).toBe(1024)

        it "MAX_WORKER_THREADS should be a number", ->

            expect(typeof MAX_WORKER_THREADS).toBe("number")
            expect(MAX_WORKER_THREADS).toBe(4)

        it "ASYNC_OPERATION_TIMEOUT should be a number", ->

            expect(typeof ASYNC_OPERATION_TIMEOUT).toBe("number")
            expect(ASYNC_OPERATION_TIMEOUT).toBe(30000)

        it "GARBAGE_COLLECTION_THRESHOLD should be a number", ->

            expect(typeof GARBAGE_COLLECTION_THRESHOLD).toBe("number")
            expect(GARBAGE_COLLECTION_THRESHOLD).toBe(10000)

        it "MEMORY_USAGE_WARNING_LIMIT should be a number", ->

            expect(typeof MEMORY_USAGE_WARNING_LIMIT).toBe("number")
            expect(MEMORY_USAGE_WARNING_LIMIT).toBe(0.8)

        it "GEOMETRY_CACHE_SIZE should be a number", ->

            expect(typeof GEOMETRY_CACHE_SIZE).toBe("number")
            expect(GEOMETRY_CACHE_SIZE).toBe(1000)

        it "INTERSECTION_CACHE_SIZE should be a number", ->

            expect(typeof INTERSECTION_CACHE_SIZE).toBe("number")
            expect(INTERSECTION_CACHE_SIZE).toBe(5000)

    describe "Polygon ID Management Variables", ->

        it "polygonID should be a number", ->

            expect(typeof polygonID).toBe("number")
            expect(polygonID).toBeGreaterThanOrEqual(0)

    describe "Debugging and Development Variables", ->

        it "DEBUG_VERBOSE_LOGGING should be a boolean", ->

            expect(typeof DEBUG_VERBOSE_LOGGING).toBe("boolean")
            expect(DEBUG_VERBOSE_LOGGING).toBe(false)

        it "DEBUG_PERFORMANCE_TIMING should be a boolean", ->

            expect(typeof DEBUG_PERFORMANCE_TIMING).toBe("boolean")
            expect(DEBUG_PERFORMANCE_TIMING).toBe(false)

        it "DEBUG_GEOMETRY_VALIDATION should be a boolean", ->

            expect(typeof DEBUG_GEOMETRY_VALIDATION).toBe("boolean")
            expect(DEBUG_GEOMETRY_VALIDATION).toBe(false)

        it "DEBUG_INTERSECTION_VERIFICATION should be a boolean", ->

            expect(typeof DEBUG_INTERSECTION_VERIFICATION).toBe("boolean")
            expect(DEBUG_INTERSECTION_VERIFICATION).toBe(false)

        it "DEBUG_COLOR_FRONT should be a number (hex color)", ->

            expect(typeof DEBUG_COLOR_FRONT).toBe("number")
            expect(DEBUG_COLOR_FRONT).toBe(0x00ff00)

        it "DEBUG_COLOR_BACK should be a number (hex color)", ->

            expect(typeof DEBUG_COLOR_BACK).toBe("number")
            expect(DEBUG_COLOR_BACK).toBe(0xff0000)

        it "DEBUG_COLOR_COPLANAR should be a number (hex color)", ->

            expect(typeof DEBUG_COLOR_COPLANAR).toBe("number")
            expect(DEBUG_COLOR_COPLANAR).toBe(0x0000ff)

        it "DEBUG_COLOR_SPANNING should be a number (hex color)", ->

            expect(typeof DEBUG_COLOR_SPANNING).toBe("number")
            expect(DEBUG_COLOR_SPANNING).toBe(0xffff00)
