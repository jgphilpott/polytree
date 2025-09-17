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

# Raycast sorting function
raycastIntersectAscSort = (a, b) -> a.distance - b.distance

# Point rounding utility
pointRounding = (point, num = 15) ->

    point.x = +point.x.toFixed(num)
    point.y = +point.y.toFixed(num)
    point.z = +point.z.toFixed(num)
    point

# Split polygon by plane
splitPolygonByPlane = (polygon, plane, result = []) ->

    returnPolygon =
        polygon: polygon
        type: "undecided"

    polygonType = 0
    types = []

    for i in [0...polygon.vertices.length]

        distanceToPlane = plane.normal.dot(polygon.vertices[i].pos) - plane.w
        type = if distanceToPlane < -EPSILON then BACK else if distanceToPlane > EPSILON then FRONT else COPLANAR
        polygonType |= type
        types.push(type)

    switch polygonType

        when COPLANAR

            returnPolygon.type = if plane.normal.dot(polygon.plane.normal) > 0 then "coplanar-front" else "coplanar-back"
            result.push(returnPolygon)

        when FRONT

            returnPolygon.type = "front"
            result.push(returnPolygon)

        when BACK

            returnPolygon.type = "back"
            result.push(returnPolygon)

        when SPANNING

            frontVertices = []
            backVertices = []

            for i in [0...polygon.vertices.length]

                nextIndex = (i + 1) % polygon.vertices.length
                currentType = types[i]
                nextType = types[nextIndex]
                currentVertex = polygon.vertices[i]
                nextVertex = polygon.vertices[nextIndex]

                if currentType != BACK

                    frontVertices.push(currentVertex)

                if currentType != FRONT

                    backVertices.push(if currentType != BACK then currentVertex.clone() else currentVertex)

                if (currentType | nextType) == SPANNING

                    intersectionParameter = (plane.w - plane.normal.dot(currentVertex.pos)) / plane.normal.dot(triangleVertex0.copy(nextVertex.pos).sub(currentVertex.pos))
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

# Split polygon array utility
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

            resultArr.push([arr[0].clone(), arr[1].clone(), arr[2].clone()],
                [arr[0].clone(), arr[2].clone(), arr[3].clone()])

        else

            resultArr.push([arr[0].clone(), arr[1].clone(), arr[3].clone()],
                [arr[1].clone(), arr[2].clone(), arr[3].clone()])

        return resultArr

    return resultArr

# Return XYZ helper for winding number
returnXYZ = (arr, index) ->
    x: arr[index]
    y: arr[index + 1]
    z: arr[index + 2]

# Calculate winding number from buffer
calcWindingNumber_buffer = (trianglesArr, point) ->

    wN = 0

    for i in [0...trianglesArr.length] by 9

        _wV1.subVectors(returnXYZ(trianglesArr, i), point)
        _wV2.subVectors(returnXYZ(trianglesArr, i + 3), point)
        _wV3.subVectors(returnXYZ(trianglesArr, i + 6), point)
        lenA = _wV1.length()
        lenB = _wV2.length()
        lenC = _wV3.length()
        _matrix3.set(_wV1.x, _wV1.y, _wV1.z, _wV2.x, _wV2.y, _wV2.z, _wV3.x, _wV3.y, _wV3.z)
        omega = 2 * Math.atan2(_matrix3.determinant(), (lenA * lenB * lenC + _wV1.dot(_wV2) * lenC + _wV2.dot(_wV3) * lenA + _wV3.dot(_wV1) * lenB))
        wN += omega

    wN = Math.round(wN / wNPI)
    return wN

# Check if polygon is inside using winding number
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

# Prepare triangle buffer for winding number calculations
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

# Ray-triangle intersection using Möller–Trumbore algorithm
rayIntersectsTriangle = (ray, triangle, target = new Vector3()) ->

    edge1.subVectors(triangle.b, triangle.a)
    edge2.subVectors(triangle.c, triangle.a)
    h.crossVectors(ray.direction, edge2)
    a = edge1.dot(h)

    if a > -RAY_EPSILON and a < RAY_EPSILON

        return null # Ray is parallel to the triangle

    f = 1 / a
    s.subVectors(ray.origin, triangle.a)
    u = f * s.dot(h)

    if u < 0 or u > 1

        return null

    q.crossVectors(s, edge1)
    v = f * ray.direction.dot(q)

    if v < 0 or u + v > 1

        return null

    t = f * edge2.dot(q)

    if t > RAY_EPSILON

        return target.copy(ray.direction).multiplyScalar(t).add(ray.origin)

    return null

# Handle intersecting polytrees
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

# Dispose polytree utility
disposePolytree = (...polytrees) ->

    if Polytree.disposePolytree

        polytrees.forEach((polytree) -> polytree.delete())
