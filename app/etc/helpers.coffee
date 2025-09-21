# === BUFFER UTILITIES ===

# Create a 2D vector buffer with write functionality.
# This helper provides efficient storage and writing of 2D vector data.
# @param vectorCount - The number of vectors this buffer can hold.
# @return Buffer object with write method and Float32Array storage.
createVector2Buffer = (vectorCount) ->

    top: 0
    array: new Float32Array(vectorCount * 2)

    write: (vector) ->

        @array[@top++] = vector.x
        @array[@top++] = vector.y


# Create a 3D vector buffer with write functionality.
# This helper provides efficient storage and writing of 3D vector data.
# @param vectorCount - The number of vectors this buffer can hold.
# @return Buffer object with write method and Float32Array storage.
createVector3Buffer = (vectorCount) ->

    top: 0
    array: new Float32Array(vectorCount * 3)

    write: (vector) ->

        @array[@top++] = vector.x
        @array[@top++] = vector.y
        @array[@top++] = vector.z


# === POINT AND GEOMETRIC UTILITIES ===

# Sort raycast intersections by distance in ascending order.
# Used for ordering ray intersection results from closest to farthest.
# @param intersectionA - First intersection object with distance property.
# @param intersectionB - Second intersection object with distance property.
# @return Comparison result for sorting (-1, 0, or 1).
sortRaycastIntersectionsByDistance = (intersectionA, intersectionB) ->

    intersectionA.distance - intersectionB.distance


# Round point coordinates to specified decimal precision.
# This helps eliminate floating point precision errors in geometric calculations.
# @param point - Vector3 point to round.
# @param decimalPlaces - Number of decimal places to round to (default: 15).
# @return The same point object with rounded coordinates.
roundPointCoordinates = (point, decimalPlaces = 15) ->

    point.x = +point.x.toFixed(decimalPlaces)
    point.y = +point.y.toFixed(decimalPlaces)
    point.z = +point.z.toFixed(decimalPlaces)

    return point


# Extract XYZ coordinates from a flat array at the specified index.
# Helper for working with triangle buffer data in winding number calculations.
# @param coordinatesArray - Float32Array containing XYZ coordinates.
# @param startIndex - Starting index in the array.
# @return Object with x, y, z properties.
extractCoordinatesFromArray = (coordinatesArray, startIndex) ->

    x: coordinatesArray[startIndex]
    y: coordinatesArray[startIndex + 1]
    z: coordinatesArray[startIndex + 2]


# === POLYGON OPERATIONS ===

# Split a polygon by a plane into front and back fragments.
# This is a core CSG operation that classifies polygon parts relative to a plane.
# The algorithm handles coplanar, front, back, and spanning polygon cases.
# @param polygon - The polygon to split.
# @param plane - The cutting plane with normal and distance properties.
# @param result - Array to store results (optional).
# @return Array of polygon fragments with classification types.
splitPolygonByPlane = (polygon, plane, result = []) ->

    returnPolygon =
        polygon: polygon
        type: "undecided"

    polygonType = 0
    vertexTypes = []

    # Classify each vertex relative to the plane.
    for vertexIndex in [0...polygon.vertices.length]

        distanceToPlane = plane.normal.dot(polygon.vertices[vertexIndex].pos) - plane.distanceFromOrigin
        vertexType = if distanceToPlane < -GEOMETRIC_EPSILON then POLYGON_BACK else if distanceToPlane > GEOMETRIC_EPSILON then POLYGON_FRONT else POLYGON_COPLANAR

        polygonType |= vertexType
        vertexTypes.push(vertexType)

    # Handle polygon classification based on vertex types.
    switch polygonType

        when POLYGON_COPLANAR

            returnPolygon.type = if plane.normal.dot(polygon.plane.normal) > 0 then "coplanar-front" else "coplanar-back"
            result.push(returnPolygon)

        when POLYGON_FRONT

            returnPolygon.type = "front"
            result.push(returnPolygon)

        when POLYGON_BACK

            returnPolygon.type = "back"
            result.push(returnPolygon)

        when POLYGON_SPANNING

            frontVertices = []
            backVertices = []

            # Process each edge to build front and back vertex lists.
            for vertexIndex in [0...polygon.vertices.length]

                nextVertexIndex = (vertexIndex + 1) % polygon.vertices.length
                currentVertexType = vertexTypes[vertexIndex]
                nextVertexType = vertexTypes[nextVertexIndex]
                currentVertex = polygon.vertices[vertexIndex]
                nextVertex = polygon.vertices[nextVertexIndex]

                # Add vertex to front list if not behind plane.
                if currentVertexType != POLYGON_BACK

                    frontVertices.push(currentVertex)

                # Add vertex to back list if not in front of plane.
                if currentVertexType != POLYGON_FRONT

                    backVertices.push(if currentVertexType != POLYGON_BACK then currentVertex.clone() else currentVertex)

                # Handle edge intersections with the plane.
                if (currentVertexType | nextVertexType) == POLYGON_SPANNING

                    intersectionParameter = (plane.distanceFromOrigin - plane.normal.dot(currentVertex.pos)) / plane.normal.dot(temporaryTriangleVertex.copy(nextVertex.pos).sub(currentVertex.pos))
                    interpolatedVertex = currentVertex.interpolate(nextVertex, intersectionParameter)

                    frontVertices.push(interpolatedVertex)
                    backVertices.push(interpolatedVertex.clone())

            # Create front polygon fragments if we have enough vertices.
            if frontVertices.length >= 3

                if frontVertices.length > 3

                    frontPolygonFragments = splitPolygonVertexArray(frontVertices)

                    for fragmentIndex in [0...frontPolygonFragments.length]

                        result.push(
                            polygon: new Polygon(frontPolygonFragments[fragmentIndex], polygon.shared)
                            type: "front"
                        )

                else

                    result.push(
                        polygon: new Polygon(frontVertices, polygon.shared)
                        type: "front"
                    )

            # Create back polygon fragments if we have enough vertices.
            if backVertices.length >= 3

                if backVertices.length > 3

                    backPolygonFragments = splitPolygonVertexArray(backVertices)

                    for fragmentIndex in [0...backPolygonFragments.length]

                        result.push(
                            polygon: new Polygon(backPolygonFragments[fragmentIndex], polygon.shared)
                            type: "back"
                        )

                else

                    result.push(
                        polygon: new Polygon(backVertices, polygon.shared)
                        type: "back"
                    )

    # If no fragments were created, return the original polygon.
    if result.length == 0

        result.push(returnPolygon)

    return result


# Split a polygon vertex array into triangulated fragments.
# This handles polygons with more than 3 vertices by creating triangle fans.
# @param vertexArray - Array of vertices to triangulate.
# @return Array of vertex arrays, each representing a triangle.
splitPolygonVertexArray = (vertexArray) ->

    triangleFragments = []

    # Handle polygons with more than 4 vertices using fan triangulation.
    if vertexArray.length > 4

        console.warn("[splitPolygonVertexArray] vertexArray.length > 4", vertexArray.length)

        for triangleIndex in [3..vertexArray.length]

            triangleVertices = []
            triangleVertices.push(vertexArray[0].clone())
            triangleVertices.push(vertexArray[triangleIndex - 2].clone())
            triangleVertices.push(vertexArray[triangleIndex - 1].clone())
            triangleFragments.push(triangleVertices)

    else

        # For quadrilaterals, choose the best diagonal based on distance.
        if vertexArray[0].pos.distanceTo(vertexArray[2].pos) <= vertexArray[1].pos.distanceTo(vertexArray[3].pos)

            triangleFragments.push(
                [vertexArray[0].clone(), vertexArray[1].clone(), vertexArray[2].clone()],
                [vertexArray[0].clone(), vertexArray[2].clone(), vertexArray[3].clone()]
            )

        else

            triangleFragments.push(
                [vertexArray[0].clone(), vertexArray[1].clone(), vertexArray[3].clone()],
                [vertexArray[1].clone(), vertexArray[2].clone(), vertexArray[3].clone()]
            )

    return triangleFragments

# === WINDING NUMBER CALCULATIONS ===

# Calculate the winding number for a point relative to triangle mesh data.
# The winding number determines how many times the mesh winds around the test point.
# This is used for robust inside/outside testing of complex 3D geometry.
# @param triangleDataArray - Float32Array containing triangle vertex coordinates.
# @param testPoint - Point to test for winding number.
# @return Integer winding number (0 = outside, non-zero = inside).
calculateWindingNumberFromBuffer = (triangleDataArray, testPoint) ->

    windingNumber = 0

    # Process each triangle in the buffer (9 floats per triangle: 3 vertices × 3 coordinates).
    for triangleStartIndex in [0...triangleDataArray.length] by 9

        windingNumberVector1.subVectors(extractCoordinatesFromArray(triangleDataArray, triangleStartIndex), testPoint)
        windingNumberVector2.subVectors(extractCoordinatesFromArray(triangleDataArray, triangleStartIndex + 3), testPoint)
        windingNumberVector3.subVectors(extractCoordinatesFromArray(triangleDataArray, triangleStartIndex + 6), testPoint)

        vectorLengthA = windingNumberVector1.length()
        vectorLengthB = windingNumberVector2.length()
        vectorLengthC = windingNumberVector3.length()

        # Calculate the solid angle using the determinant formula.
        windingNumberMatrix3.set(
            windingNumberVector1.x, windingNumberVector1.y, windingNumberVector1.z,
            windingNumberVector2.x, windingNumberVector2.y, windingNumberVector2.z,
            windingNumberVector3.x, windingNumberVector3.y, windingNumberVector3.z
        )

        solidAngle = 2 * Math.atan2(
            windingNumberMatrix3.determinant(),
            (vectorLengthA * vectorLengthB * vectorLengthC +
             windingNumberVector1.dot(windingNumberVector2) * vectorLengthC +
             windingNumberVector2.dot(windingNumberVector3) * vectorLengthA +
             windingNumberVector3.dot(windingNumberVector1) * vectorLengthB)
        )

        windingNumber += solidAngle

    # Round to nearest integer to get the final winding number.
    windingNumber = Math.round(windingNumber / WINDING_NUMBER_FULL_ROTATION)

    return windingNumber


# Test if a polygon is inside a mesh using winding number algorithm.
# This provides robust inside/outside testing that handles complex cases.
# For coplanar polygons, epsilon offsets are tested to resolve ambiguity.
# @param triangleDataArray - Float32Array containing mesh triangle data.
# @param testPoint - Point to test for inside/outside status.
# @param isCoplanar - Whether the polygon is coplanar with mesh surfaces.
# @return Boolean indicating if the polygon is inside the mesh.
testPolygonInsideUsingWindingNumber = (triangleDataArray, testPoint, isCoplanar) ->

    isInside = false
    windingNumberTestPoint.copy(testPoint)
    windingNumber = calculateWindingNumberFromBuffer(triangleDataArray, windingNumberTestPoint)

    # For non-coplanar cases, winding number directly indicates inside/outside.
    if windingNumber is 0

        if isCoplanar

            # For coplanar cases, test multiple epsilon-offset points.
            for offsetIndex in [0...windingNumberEpsilonOffsetsCount]

                windingNumberTestPoint.copy(testPoint).add(windingNumberEpsilonOffsets[offsetIndex])
                windingNumber = calculateWindingNumberFromBuffer(triangleDataArray, windingNumberTestPoint)

                if windingNumber isnt 0

                    isInside = true
                    break

    else

        isInside = true

    return isInside


# Prepare a triangle buffer from polygon array for winding number calculations.
# This converts polygon data into a flat Float32Array for efficient processing.
# @param polygonArray - Array of polygons to convert.
# @return Float32Array containing triangle vertex coordinates.
prepareTriangleBufferFromPolygons = (polygonArray) ->

    triangleCount = polygonArray.length
    coordinateArray = new Float32Array(triangleCount * 3 * 3) # 3 vertices × 3 coordinates per triangle
    bufferIndex = 0

    for polygonIndex in [0...triangleCount]

        triangle = polygonArray[polygonIndex].triangle

        # Store first vertex coordinates.
        coordinateArray[bufferIndex++] = triangle.a.x
        coordinateArray[bufferIndex++] = triangle.a.y
        coordinateArray[bufferIndex++] = triangle.a.z

        # Store second vertex coordinates.
        coordinateArray[bufferIndex++] = triangle.b.x
        coordinateArray[bufferIndex++] = triangle.b.y
        coordinateArray[bufferIndex++] = triangle.b.z

        # Store third vertex coordinates.
        coordinateArray[bufferIndex++] = triangle.c.x
        coordinateArray[bufferIndex++] = triangle.c.y
        coordinateArray[bufferIndex++] = triangle.c.z

    return coordinateArray

# === RAY-TRIANGLE INTERSECTION ===

# Test ray-triangle intersection using the Möller–Trumbore algorithm.
# This is a fast, efficient algorithm for ray-triangle intersection testing.
# Returns the intersection point if found, or null if no intersection exists.
# @param ray - Ray object with origin and direction properties.
# @param triangle - Triangle object with a, b, c vertex properties.
# @param targetVector - Optional Vector3 to store the intersection point.
# @return Vector3 intersection point or null if no intersection.
testRayTriangleIntersection = (ray, triangle, targetVector = new Vector3()) ->

    # Calculate triangle edge vectors.
    rayTriangleEdge1.subVectors(triangle.b, triangle.a)
    rayTriangleEdge2.subVectors(triangle.c, triangle.a)

    # Calculate determinant to check if ray is parallel to triangle.
    rayTriangleHVector.crossVectors(ray.direction, rayTriangleEdge2)
    determinant = rayTriangleEdge1.dot(rayTriangleHVector)

    # If determinant is near zero, ray is parallel to triangle plane.
    if determinant > -RAY_INTERSECTION_EPSILON and determinant < RAY_INTERSECTION_EPSILON

        return null

    inverseDeterminant = 1 / determinant
    rayTriangleSVector.subVectors(ray.origin, triangle.a)
    firstBarycentricCoordinate = inverseDeterminant * rayTriangleSVector.dot(rayTriangleHVector)

    # Check if intersection point is outside triangle (first barycentric test).
    if firstBarycentricCoordinate < 0 or firstBarycentricCoordinate > 1

        return null

    rayTriangleQVector.crossVectors(rayTriangleSVector, rayTriangleEdge1)
    secondBarycentricCoordinate = inverseDeterminant * ray.direction.dot(rayTriangleQVector)

    # Check if intersection point is outside triangle (second barycentric test).
    if secondBarycentricCoordinate < 0 or firstBarycentricCoordinate + secondBarycentricCoordinate > 1

        return null

    # Calculate intersection distance along ray.
    intersectionDistance = inverseDeterminant * rayTriangleEdge2.dot(rayTriangleQVector)

    # Check if intersection is in front of ray origin.
    if intersectionDistance > RAY_INTERSECTION_EPSILON

        return targetVector.copy(ray.direction).multiplyScalar(intersectionDistance).add(ray.origin)

    return null

# === POLYTREE MANAGEMENT ===

# Handle intersection processing between two polytrees.
# This coordinates the CSG intersection algorithm by preparing triangle buffers
# and calling intersection handling methods on the polytree instances.
# @param polytreeA - First polytree for intersection processing.
# @param polytreeB - Second polytree for intersection processing.
# @param processBothDirections - Whether to process intersections in both directions.
handleIntersectingPolytrees = (polytreeA, polytreeB, processBothDirections = true) ->

    polytreeABuffer = undefined
    polytreeBBuffer = undefined

    # Prepare triangle buffers if winding number algorithm is enabled.
    if Polytree.useWindingNumber is true

        if processBothDirections

            polytreeABuffer = prepareTriangleBufferFromPolygons(polytreeA.getPolygons())

        polytreeBBuffer = prepareTriangleBufferFromPolygons(polytreeB.getPolygons())

    # Process intersections from A's perspective.
    polytreeA.handleIntersectingPolygons(polytreeB, polytreeBBuffer)

    # Process intersections from B's perspective if requested.
    if processBothDirections

        polytreeB.handleIntersectingPolygons(polytreeA, polytreeABuffer)

    # Clean up buffers to free memory.
    if polytreeABuffer isnt undefined

        polytreeABuffer = undefined
        polytreeBBuffer = undefined


# Dispose of polytree resources to prevent memory leaks.
# This utility safely calls the delete method on polytree instances
# if the disposal feature is enabled in the Polytree configuration.
# @param polytreeInstances - Variable number of polytree instances to dispose.
disposePolytreeResources = (...polytreeInstances) ->

    if Polytree.disposePolytree

        polytreeInstances.forEach((polytreeInstance) -> polytreeInstance.delete())


# === BACKWARD COMPATIBILITY ALIASES ===

# Legacy function name aliases for backward compatibility.
# These maintain existing API while using the new descriptive names internally.
nbuf2 = createVector2Buffer
nbuf3 = createVector3Buffer
raycastIntersectAscSort = sortRaycastIntersectionsByDistance
pointRounding = roundPointCoordinates
returnXYZ = extractCoordinatesFromArray
calcWindingNumber_buffer = calculateWindingNumberFromBuffer
polyInside_WindingNumber_buffer = testPolygonInsideUsingWindingNumber
prepareTriangleBuffer = prepareTriangleBufferFromPolygons
rayIntersectsTriangle = testRayTriangleIntersection
disposePolytree = disposePolytreeResources
splitPolygonArr = splitPolygonVertexArray
