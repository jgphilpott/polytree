# Helper buffer for 2D vectors.
nbuf2 = (ct) ->

    top: 0
    array: new Float32Array(ct)

    write: (v) ->

        @array[@top++] = v.x
        @array[@top++] = v.y

# Helper buffer for 3D vectors.
nbuf3 = (ct) ->

    top: 0
    array: new Float32Array(ct)

    write: (v) ->

        @array[@top++] = v.x
        @array[@top++] = v.y
        @array[@top++] = v.z

# Raycast sorting function.
raycastIntersectAscSort = (a, b) -> a.distance - b.distance

# Point rounding utility.
pointRounding = (point, num = 15) ->

    point.x = +point.x.toFixed(num)
    point.y = +point.y.toFixed(num)
    point.z = +point.z.toFixed(num)

    return point

# Split polygon by plane.
splitPolygonByPlane = (polygon, plane, result = []) ->

    returnPolygon =

        polygon: polygon
        type: "undecided"

    polygonType = 0
    types = []

    for i in [0...polygon.vertices.length]

        distanceToPlane = plane.normal.dot(polygon.vertices[i].pos) - plane.distanceFromOrigin
        type = if distanceToPlane < -GEOMETRIC_EPSILON then POLYGON_BACK else if distanceToPlane > GEOMETRIC_EPSILON then POLYGON_FRONT else POLYGON_COPLANAR

        polygonType |= type
        types.push(type)

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

            for i in [0...polygon.vertices.length]

                nextIndex = (i + 1) % polygon.vertices.length
                currentType = types[i]
                nextType = types[nextIndex]
                currentVertex = polygon.vertices[i]
                nextVertex = polygon.vertices[nextIndex]

                if currentType != POLYGON_BACK

                    frontVertices.push(currentVertex)

                if currentType != POLYGON_FRONT

                    backVertices.push(if currentType != POLYGON_BACK then currentVertex.clone() else currentVertex)

                if (currentType | nextType) == POLYGON_SPANNING

                    intersectionParameter = (plane.distanceFromOrigin - plane.normal.dot(currentVertex.pos)) / plane.normal.dot(temporaryTriangleVertex.copy(nextVertex.pos).sub(currentVertex.pos))
                    vertexParameter = currentVertex.interpolate(nextVertex, intersectionParameter)

                    frontVertices.push(vertexParameter)
                    backVertices.push(vertexParameter.clone())

            if frontVertices.length >= 3

                if frontVertices.length > 3

                    newPolygons = splitPolygonArr(frontVertices)

                    for polygonIndex in [0...newPolygons.length]

                        result.push(
                            polygon: new Polygon(newPolygons[polygonIndex], polygon.shared)
                            type: "front"
                        )

                else

                    result.push(
                        polygon: new Polygon(frontVertices, polygon.shared)
                        type: "front"
                    )

            if backVertices.length >= 3

                if backVertices.length > 3

                    newPolygons = splitPolygonArr(backVertices)

                    for polygonIndex in [0...newPolygons.length]

                        result.push(
                            polygon: new Polygon(newPolygons[polygonIndex], polygon.shared)
                            type: "back"
                        )

                else

                    result.push(
                        polygon: new Polygon(backVertices, polygon.shared)
                        type: "back"
                    )

    if result.length == 0

        result.push(returnPolygon)

    return result

# Split polygon array utility.
splitPolygonArr = (arr) ->

    resultArr = []

    if arr.length > 4

        console.warn("[splitPolygonArr] arr.length > 4", arr.length)

        for j in [3..arr.length]

            result = []
            result.push(arr[0].clone())
            result.push(arr[j - 2].clone())
            result.push(arr[j - 1].clone())
            resultArr.push(result)

    else

        if arr[0].pos.distanceTo(arr[2].pos) <= arr[1].pos.distanceTo(arr[3].pos)

            resultArr.push([arr[0].clone(), arr[1].clone(), arr[2].clone()], [arr[0].clone(), arr[2].clone(), arr[3].clone()])

        else

            resultArr.push([arr[0].clone(), arr[1].clone(), arr[3].clone()], [arr[1].clone(), arr[2].clone(), arr[3].clone()])

        return resultArr

    return resultArr

# Return XYZ helper for winding number.
returnXYZ = (arr, index) ->

    x: arr[index]
    y: arr[index + 1]
    z: arr[index + 2]

# Calculate winding number from buffer.
calcWindingNumber_buffer = (trianglesArr, point) ->

    wN = 0

    for i in [0...trianglesArr.length] by 9

        windingNumberVector1.subVectors(returnXYZ(trianglesArr, i), point)
        windingNumberVector2.subVectors(returnXYZ(trianglesArr, i + 3), point)
        windingNumberVector3.subVectors(returnXYZ(trianglesArr, i + 6), point)

        lenA = windingNumberVector1.length()
        lenB = windingNumberVector2.length()
        lenC = windingNumberVector3.length()

        windingNumberMatrix3.set(windingNumberVector1.x, windingNumberVector1.y, windingNumberVector1.z, windingNumberVector2.x, windingNumberVector2.y, windingNumberVector2.z, windingNumberVector3.x, windingNumberVector3.y, windingNumberVector3.z)
        omega = 2 * Math.atan2(windingNumberMatrix3.determinant(), (lenA * lenB * lenC + windingNumberVector1.dot(windingNumberVector2) * lenC + windingNumberVector2.dot(windingNumberVector3) * lenA + windingNumberVector3.dot(windingNumberVector1) * lenB))
        wN += omega

    wN = Math.round(wN / WINDING_NUMBER_FULL_ROTATION)

    return wN

# Check if polygon is inside using winding number.
polyInside_WindingNumber_buffer = (trianglesArr, point, coplanar) ->

    result = false
    _wP.copy(point)
    wN = calcWindingNumber_buffer(trianglesArr, _wP)

    if wN is 0

        if coplanar

            for j in [0..._wP_EPS_ARR_COUNT]

                _wP.copy(point).add(_wP_EPS_ARR[j])
                wN = calcWindingNumber_buffer(trianglesArr, _wP)

                if wN isnt 0

                    result = true

                    break

    else

        result = true

    return result

# Prepare triangle buffer for winding number calculations.
prepareTriangleBuffer = (polygons) ->

    numOfTriangles = polygons.length
    array = new Float32Array(numOfTriangles * 3 * 3)
    bufferIndex = 0

    for i in [0...numOfTriangles]

        triangle = polygons[i].triangle

        array[bufferIndex++] = triangle.a.x
        array[bufferIndex++] = triangle.a.y
        array[bufferIndex++] = triangle.a.z

        array[bufferIndex++] = triangle.b.x
        array[bufferIndex++] = triangle.b.y
        array[bufferIndex++] = triangle.b.z

        array[bufferIndex++] = triangle.c.x
        array[bufferIndex++] = triangle.c.y
        array[bufferIndex++] = triangle.c.z

    return array

# Ray-triangle intersection using Möller–Trumbore algorithm.
rayIntersectsTriangle = (ray, triangle, target = new Vector3()) ->

    rayTriangleEdge1.subVectors(triangle.b, triangle.a)
    rayTriangleEdge2.subVectors(triangle.c, triangle.a)

    rayTriangleHVector.crossVectors(ray.direction, rayTriangleEdge2)
    a = rayTriangleEdge1.dot(rayTriangleHVector)

    if a > -RAY_INTERSECTION_EPSILON and a < RAY_INTERSECTION_EPSILON

        return null # Ray is parallel to the triangle.

    f = 1 / a
    rayTriangleSVector.subVectors(ray.origin, triangle.a)
    u = f * rayTriangleSVector.dot(rayTriangleHVector)

    if u < 0 or u > 1

        return null

    rayTriangleQVector.crossVectors(rayTriangleSVector, rayTriangleEdge1)
    v = f * ray.direction.dot(rayTriangleQVector)

    if v < 0 or u + v > 1

        return null

    t = f * rayTriangleEdge2.dot(rayTriangleQVector)

    if t > RAY_INTERSECTION_EPSILON

        return target.copy(ray.direction).multiplyScalar(t).add(ray.origin)

    return null

# Handle intersecting polytrees.
handleIntersectingPolytrees = (polytreeA, polytreeB, bothPolytrees = true) ->

    polytreeA_buffer = undefined
    polytreeB_buffer = undefined

    if Polytree.useWindingNumber is true

        if bothPolytrees

            polytreeA_buffer = prepareTriangleBuffer(polytreeA.getPolygons())

        polytreeB_buffer = prepareTriangleBuffer(polytreeB.getPolygons())

    polytreeA.handleIntersectingPolygons(polytreeB, polytreeB_buffer)

    if bothPolytrees

        polytreeB.handleIntersectingPolygons(polytreeA, polytreeA_buffer)

    if polytreeA_buffer isnt undefined

        polytreeA_buffer = undefined
        polytreeB_buffer = undefined

# Dispose polytree utility.
disposePolytree = (...polytrees) ->

    if Polytree.disposePolytree

        polytrees.forEach((polytree) -> polytree.delete())
