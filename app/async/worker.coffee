# Web Worker for asynchronous polygon inside testing using winding number algorithm.
# This worker handles computationally intensive winding number calculations
# off the main thread to prevent UI blocking.

onmessage = (e) ->

    { type, point, coplanar, polygonID, triangles } = e.data
    trianglesArray = new Float32Array(triangles)

    if type is 'windingNumber'

        postMessage
            type: type
            result: testPolygonInsideUsingWindingNumber(trianglesArray, point, coplanar)

    else

        postMessage "Unknown worker operation type: #{type}"

# === WINDING NUMBER ALGORITHM ===
# Winding Number algorithm adapted from https://github.com/grame-cncm/faust/blob/master-dev/tools/physicalModeling/mesh2faust/vega/libraries/windingNumber/windingNumber.cpp

# Epsilon value for coplanar offset testing.
EPSILON = 1e-5

# Reusable Vector3 objects to avoid memory allocation during calculations.
windingVector1 = new THREE.Vector3()
windingVector2 = new THREE.Vector3()
windingVector3 = new THREE.Vector3()
windingPoint = new THREE.Vector3()

# Epsilon offset vectors for coplanar triangle testing.
# These small offsets help determine if a point is inside when it lies exactly on the triangle plane.
epsilonOffsets = [
    new THREE.Vector3(EPSILON, 0, 0)
    new THREE.Vector3(0, EPSILON, 0)
    new THREE.Vector3(0, 0, EPSILON)
    new THREE.Vector3(-EPSILON, 0, 0)
    new THREE.Vector3(0, -EPSILON, 0)
    new THREE.Vector3(0, 0, -EPSILON)
]

epsilonOffsetsCount = epsilonOffsets.length
determinantMatrix = new THREE.Matrix3()
windingNumberPi = 4 * Math.PI

# Extract coordinate values from a Float32Array at a specific index.
# @param coordinateArray - Float32Array containing triangle coordinate data.
# @param startIndex - Starting index for the coordinate triplet.
# @return Object with x, y, z properties containing the coordinate values.
extractCoordinatesFromArray = (coordinateArray, startIndex) ->

    x: coordinateArray[startIndex]
    y: coordinateArray[startIndex + 1]
    z: coordinateArray[startIndex + 2]

# Calculate the winding number for a point relative to a set of triangles.
# The winding number indicates how many times the triangles "wind around" the point.
# @param trianglesArray - Float32Array containing triangle vertex coordinates (9 values per triangle).
# @param testPoint - Vector3 point to test.
# @return Integer winding number (0 = outside, non-zero = inside).
calculateWindingNumberFromBuffer = (trianglesArray, testPoint) ->

    windingNumber = 0

    for triangleIndex in [0...trianglesArray.length] by 9

        windingVector1.subVectors(extractCoordinatesFromArray(trianglesArray, triangleIndex), testPoint)
        windingVector2.subVectors(extractCoordinatesFromArray(trianglesArray, triangleIndex + 3), testPoint)
        windingVector3.subVectors(extractCoordinatesFromArray(trianglesArray, triangleIndex + 6), testPoint)

        lengthA = windingVector1.length()
        lengthB = windingVector2.length()
        lengthC = windingVector3.length()

        determinantMatrix.set(
            windingVector1.x, windingVector1.y, windingVector1.z,
            windingVector2.x, windingVector2.y, windingVector2.z,
            windingVector3.x, windingVector3.y, windingVector3.z
        )

        omega = 2 * Math.atan2(
            determinantMatrix.determinant(),
            (lengthA * lengthB * lengthC +
             windingVector1.dot(windingVector2) * lengthC +
             windingVector2.dot(windingVector3) * lengthA +
             windingVector3.dot(windingVector1) * lengthB)
        )

        windingNumber += omega

    windingNumber = Math.round(windingNumber / windingNumberPi)

    return windingNumber

# Test if a point is inside a polygon using the winding number algorithm.
# For coplanar cases, tests multiple epsilon-offset positions to handle edge cases.
# @param trianglesArray - Float32Array containing triangle vertex coordinates.
# @param testPoint - Vector3 point to test for inside/outside status.
# @param isCoplanar - Boolean indicating if the polygon is coplanar with the test point.
# @return Boolean indicating if the point is inside the polygon.
testPolygonInsideUsingWindingNumber = (trianglesArray, testPoint, isCoplanar) ->

    result = false
    windingPoint.copy(testPoint)
    windingNumber = calculateWindingNumberFromBuffer(trianglesArray, windingPoint)
    coplanarFound = false

    if windingNumber is 0

        if isCoplanar

            # For coplanar cases, test with small epsilon offsets to handle numerical precision issues.
            for offsetIndex in [0...epsilonOffsetsCount]

                windingPoint.copy(testPoint).add(epsilonOffsets[offsetIndex])
                windingNumber = calculateWindingNumberFromBuffer(trianglesArray, windingPoint)

                if windingNumber isnt 0

                    result = true
                    coplanarFound = true
                    break

    else

        result = true

    return result
