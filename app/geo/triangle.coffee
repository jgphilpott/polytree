### Validate a triangle (three distinct vertices) in 3D space.

Notes:

    - This does NOT check for area > 0 beyond coincident points (collinear but distinct points are treated as valid).
    - Use additional orientation/area tests if you need to exclude collinear triangles. ###

isValidTriangle = (triangle) ->

    if DEBUG_GEOMETRY_VALIDATION
        console.log("Validating triangle:", triangle.a, triangle.b, triangle.c)

    return false if triangle.a.equals(triangle.b)
    return false if triangle.a.equals(triangle.c)
    return false if triangle.b.equals(triangle.c)

    if DEBUG_GEOMETRY_VALIDATION
        console.log("Triangle validation passed")

    return true

### Check and register triangle uniqueness in a Set/Map.

Hash Scheme:

    - Generates a directional hash using the ordered vertex triplet (a,b,c).
    - Different vertex order permutations of the same geometric triangle will be treated as different unless normalized before calling.

Usage Guidance:

    - For order-invariant uniqueness, sort or canonicalize vertices first (e.g., by lexicographic (x,y,z)) before invoking.
    - For performance, this function only creates a single concatenated string and performs a Set lookup. ###

isUniqueTriangle = (triangle, set, map) ->

    hash1 = "{#{triangle.a.x},#{triangle.a.y},#{triangle.a.z}}-{#{triangle.b.x},#{triangle.b.y},#{triangle.b.z}}-{#{triangle.c.x},#{triangle.c.y},#{triangle.c.z}}"

    if set.has(hash1) is true

        return false

    else

        set.add(hash1)

        if map

            map.set(triangle, triangle)

        return true

# Epsilon-aware 2D point equality.
pointsEqual2D = (p, q, eps = TRIANGLE_2D_EPSILON) ->

    return Math.abs(p.x - q.x) <= eps and Math.abs(p.y - q.y) <= eps

# Inclusive point-on-segment check for collinear points.
pointOnSegmentInclusive2D = (p, a, b, eps = TRIANGLE_2D_EPSILON) ->

    return pointsEqual2D(p, a, eps) or pointsEqual2D(p, b, eps) if pointsEqual2D(a, b, eps)

    return false if Math.abs(triangleOrientation2D(p, a, b)) > eps

    minX = Math.min(a.x, b.x) - eps
    maxX = Math.max(a.x, b.x) + eps
    minY = Math.min(a.y, b.y) - eps
    maxY = Math.max(a.y, b.y) + eps

    return (p.x >= minX and p.x <= maxX and p.y >= minY and p.y <= maxY)

# Inclusive point-in-triangle test using orientations.
# - Works for CW or CCW input (auto-detects orientation).
# - Inclusive of edges/vertices.
# - Handles degenerate triangles (point or segment) robustly.
pointInTriangleInclusive2D = (p, a, b, c, eps = TRIANGLE_2D_EPSILON) ->

    o = triangleOrientation2D(a, b, c)

    if o > eps

        s1 = triangleOrientation2D(p, a, b)
        s2 = triangleOrientation2D(p, b, c)
        s3 = triangleOrientation2D(p, c, a)

        return (s1 >= -eps) and (s2 >= -eps) and (s3 >= -eps)

    else if o < -eps

        s1 = triangleOrientation2D(p, a, b)
        s2 = triangleOrientation2D(p, b, c)
        s3 = triangleOrientation2D(p, c, a)

        return (s1 <= eps) and (s2 <= eps) and (s3 <= eps)

    else

        # Degenerate triangle: either a point (all equal) or a segment (collinear).

        if pointsEqual2D(a, b, eps) and pointsEqual2D(b, c, eps)

            return pointsEqual2D(p, a, eps)

        # Reduce to the non-degenerate segment and test inclusively.

        if pointsEqual2D(a, b, eps)

            return pointOnSegmentInclusive2D(p, b, c, eps)

        if pointsEqual2D(b, c, eps)

            return pointOnSegmentInclusive2D(p, a, b, eps)

        if pointsEqual2D(c, a, eps)

            return pointOnSegmentInclusive2D(p, a, b, eps)

        # All three distinct but collinear: test against hull segments.

        return pointOnSegmentInclusive2D(p, a, b, eps) or pointOnSegmentInclusive2D(p, b, c, eps) or pointOnSegmentInclusive2D(p, c, a, eps)

### Checks whether two triangles in 3D space intersect.

@param {Object} triangleA - First triangle, with properties {a, b, c} (Vector3 vertices).
@param {Object} triangleB - Second triangle, with properties {a, b, c} (Vector3 vertices).

@param {Object} additions - Optional data object used for storing extra intersection info:

    - coplanar {Boolean} whether the triangles lie in the same plane.
    - source {Vector3} intersection segment start (if applicable).
    - target {Vector3} intersection segment end (if applicable).

@returns {Boolean} - True if the triangles intersect, false otherwise. ###
triangleIntersectsTriangle = (triangleA, triangleB, additions = { coplanar: false, source: new Vector3(), target: new Vector3() }) ->

    # Extract vertices of triangle A.
    vertex1TriangleA = triangleA.a
    vertex2TriangleA = triangleA.b
    vertex3TriangleA = triangleA.c

    # Extract vertices of triangle B.
    vertex1TriangleB = triangleB.a
    vertex2TriangleB = triangleB.b
    vertex3TriangleB = triangleB.c

    # Step 1: Compute signed distances of Triangle A’s vertices relative to the plane defined by Triangle B.

    temporaryVector3Primary.copy(vertex1TriangleB).sub(vertex3TriangleB)
    temporaryVector3Secondary.copy(vertex2TriangleB).sub(vertex3TriangleB)

    normal2 = (new Vector3()).copy(temporaryVector3Primary).cross(temporaryVector3Secondary)

    temporaryVector3Primary.copy(vertex1TriangleA).sub(vertex3TriangleB)
    distanceVertex1A = temporaryVector3Primary.dot(normal2)

    temporaryVector3Primary.copy(vertex2TriangleA).sub(vertex3TriangleB)
    distanceVertex2A = temporaryVector3Primary.dot(normal2)

    temporaryVector3Primary.copy(vertex3TriangleA).sub(vertex3TriangleB)
    distanceVertex3A = temporaryVector3Primary.dot(normal2)

    if ((distanceVertex1A * distanceVertex2A) > 0) and ((distanceVertex1A * distanceVertex3A) > 0)

        return false # All vertices of Triangle A are on the same side of Triangle B’s plane.

    # Step 2: Compute signed distances of Triangle B’s vertices relative to the plane defined by Triangle A.

    temporaryVector3Primary.copy(vertex2TriangleA).sub(vertex1TriangleA)
    temporaryVector3Secondary.copy(vertex3TriangleA).sub(vertex1TriangleA)

    normal1 = (new Vector3()).copy(temporaryVector3Primary).cross(temporaryVector3Secondary)

    temporaryVector3Primary.copy(vertex1TriangleB).sub(vertex3TriangleA)
    distanceVertex1B = temporaryVector3Primary.dot(normal1)

    temporaryVector3Primary.copy(vertex2TriangleB).sub(vertex3TriangleA)
    distanceVertex2B = temporaryVector3Primary.dot(normal1)

    temporaryVector3Primary.copy(vertex3TriangleB).sub(vertex3TriangleA)
    distanceVertex3B = temporaryVector3Primary.dot(normal1)

    if ((distanceVertex1B * distanceVertex2B) > 0) and ((distanceVertex1B * distanceVertex3B) > 0)

        return false # All vertices of Triangle B are on the same side of Triangle A’s plane.

    # Step 3: At this point, neither triangle is fully on one side of the other’s plane. This means the triangles potentially intersect.
    # Next, we use the vertex signed distances to decide which configuration applies and call `resolveTriangleIntersection` (or `resolveCoplanarTriangleIntersection` if the triangles are coplanar).

    additions.normal1 = normal1
    additions.normal2 = normal2

    # Decide how to proceed by looking at the signs of distanceVertex1A, distanceVertex2A and distanceVertex3A.
    # These numbers tell us whether each vertex of Triangle A sits above the flat surface of Triangle B (positive), below it (negative), or exactly on it (zero).
    # We then pass the vertices to the resolver in a stable order: the single “different-side” vertex first, followed by the two vertices that are on the same side.

    if distanceVertex1A > 0

        # If distanceVertex1A is positive (the first vertex of Triangle A is above Triangle B's surface):
        if distanceVertex2A > 0

            # Then distanceVertex2A is also positive, while distanceVertex3A is zero or negative.
            # In plain terms: the third vertex of Triangle A lies on the other side of Triangle B’s surface (or exactly on it).
            return resolveTriangleIntersection(vertex3TriangleA, vertex1TriangleA, vertex2TriangleA, vertex1TriangleB, vertex3TriangleB, vertex2TriangleB, distanceVertex1B, distanceVertex3B, distanceVertex2B, additions)

        else if distanceVertex3A > 0

            # Then distanceVertex3A is positive, while distanceVertex2A is zero or negative.
            # That means the second vertex of Triangle A is the one on the other side (or exactly on the surface).
            return resolveTriangleIntersection(vertex2TriangleA, vertex3TriangleA, vertex1TriangleA, vertex1TriangleB, vertex3TriangleB, vertex2TriangleB, distanceVertex1B, distanceVertex3B, distanceVertex2B, additions)

        else

            # Here only the first vertex is above the surface; the second and third are on or below it.
            return resolveTriangleIntersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, distanceVertex1B, distanceVertex2B, distanceVertex3B, additions)

    else if distanceVertex1A < 0

        # If distanceVertex1A is negative (the first vertex of Triangle A is below Triangle B's surface):
        if distanceVertex2A < 0

            # Then distanceVertex2A is also negative, while distanceVertex3A is zero or positive.
            # In other words: the third vertex of Triangle A is on the other side (or exactly on the surface).
            return resolveTriangleIntersection(vertex3TriangleA, vertex1TriangleA, vertex2TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, distanceVertex1B, distanceVertex2B, distanceVertex3B, additions)

        else if distanceVertex3A < 0

            # Then distanceVertex3A is negative, while distanceVertex2A is zero or positive.
            # So the second vertex is the one on the other side (or exactly on the surface).
            return resolveTriangleIntersection(vertex2TriangleA, vertex3TriangleA, vertex1TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, distanceVertex1B, distanceVertex2B, distanceVertex3B, additions)

        else

            # Only the first vertex is below the surface; the second and third are on or above it.
            # Note: We also swap the order of Triangle B’s vertices here to keep a consistent “one different, two the same” pattern for the resolver.
            return resolveTriangleIntersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex3TriangleB, vertex2TriangleB, distanceVertex1B, distanceVertex3B, distanceVertex2B, additions)

    else

        # Then the first vertex of Triangle A lies exactly on Triangle B’s surface (distanceVertex1A is zero).
        # We look at distanceVertex2A and distanceVertex3A to decide which side the other vertices are on.
        if distanceVertex2A < 0

            if distanceVertex3A >= 0

                # The second vertex is below the surface, while the third is on or above it.
                return resolveTriangleIntersection(vertex2TriangleA, vertex3TriangleA, vertex1TriangleA, vertex1TriangleB, vertex3TriangleB, vertex2TriangleB, distanceVertex1B, distanceVertex3B, distanceVertex2B, additions)

            else

                # Both the second and third vertices are below the surface.
                return resolveTriangleIntersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, distanceVertex1B, distanceVertex2B, distanceVertex3B, additions)

        else if distanceVertex2A > 0

            if distanceVertex3A > 0

                # Both the second and third vertices are above the surface.
                return resolveTriangleIntersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex3TriangleB, vertex2TriangleB, distanceVertex1B, distanceVertex3B, distanceVertex2B, additions)

            else

                # The second vertex is above the surface, while the third is on or below it.
                return resolveTriangleIntersection(vertex2TriangleA, vertex3TriangleA, vertex1TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, distanceVertex1B, distanceVertex2B, distanceVertex3B, additions)

        else

            if distanceVertex3A > 0

                # The second vertex is exactly on the surface, and the third is above it.
                return resolveTriangleIntersection(vertex3TriangleA, vertex1TriangleA, vertex2TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, distanceVertex1B, distanceVertex2B, distanceVertex3B, additions)

            else if distanceVertex3A < 0

                # The second vertex is exactly on the surface, and the third is below it.
                return resolveTriangleIntersection(vertex3TriangleA, vertex1TriangleA, vertex2TriangleA, vertex1TriangleB, vertex3TriangleB, vertex2TriangleB, distanceVertex1B, distanceVertex3B, distanceVertex2B, additions)

            else

                additions.coplanar = true # All three vertices of Triangle A lie in Triangle B's plane.
                return resolveCoplanarTriangleIntersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, normal1, normal2)

### Determines the intersection between two 3D triangles given their vertices and the signed distances of Triangle B’s vertices to the plane of Triangle A.
    Goal: Always pass to `constructIntersection` the triangles arranged so the first vertex of each lies alone on one side of the other triangle’s plane (or is on the plane), and the remaining two share the opposite side.
    This function chooses one of several vertex orderings based on the sign pattern of (distanceVertex1B, distanceVertex2B, distanceVertex3B).
    If all three distances for Triangle B are zero → triangles are coplanar and handled by `resolveCoplanarTriangleIntersection`.

@param {Vector2} vertex1TriangleA, vertex2TriangleA, vertex3TriangleA - Vertices of triangle A
@param {Vector2} vertex1TriangleB, vertex2TriangleB, vertex3TriangleB - Vertices of triangle B

@param {Number} distanceVertex1B - Signed distance of vertex1TriangleB to Triangle A’s plane.
@param {Number} distanceVertex2B - Signed distance of vertex2TriangleB to Triangle A’s plane.
@param {Number} distanceVertex3B - Signed distance of vertex3TriangleB to Triangle A’s plane.

@param {Object} additions - Data object used for storing extra intersection info:

    - coplanar {Boolean} whether the triangles lie in the same plane.
    - source {Vector3} intersection segment start (if applicable).
    - target {Vector3} intersection segment end (if applicable).
    - normal1 {Vector3} normal of Triangle A (used in coplanar case).
    - normal2 {Vector3} normal of Triangle B (used in coplanar case).

@returns {Boolean} - True if an intersection is found, false otherwise. ###
resolveTriangleIntersection = (vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, distanceVertex1B, distanceVertex2B, distanceVertex3B, additions) ->

    # Early exit → If all B's distances are strictly positive (totally outside/above) or negative (totally outside/below), there's no intersection.
    if (distanceVertex1B > 0 and distanceVertex2B > 0 and distanceVertex3B > 0) or (distanceVertex1B < 0 and distanceVertex2B < 0 and distanceVertex3B < 0) then return false

    if distanceVertex1B > 0 # First vertex of Triangle B is above (positive side of) Triangle A's plane.

        if distanceVertex2B > 0 # First two vertices of B are positive, third is zero or negative.

            constructIntersection(vertex1TriangleA, vertex3TriangleA, vertex2TriangleA, vertex3TriangleB, vertex1TriangleB, vertex2TriangleB, additions) # Reorder B as (C, A, B) so differing vertex is last.

        else if distanceVertex3B > 0 # First and third vertices of B are positive, second is zero or negative.

            constructIntersection(vertex1TriangleA, vertex3TriangleA, vertex2TriangleA, vertex2TriangleB, vertex3TriangleB, vertex1TriangleB, additions) # Reorder B as (B, C, A).

        else # Only first vertex of B is positive.

            constructIntersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, additions) # Pass original B ordering.

    else if distanceVertex1B < 0 # First vertex of Triangle B is below (negative side of) Triangle A's plane.

        if distanceVertex2B < 0 # First two vertices of B are negative, third is zero or positive.

            constructIntersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex3TriangleB, vertex1TriangleB, vertex2TriangleB, additions) # Reorder B as (C, A, B) so differing vertex is last.

        else if distanceVertex3B < 0 # First and third vertices of B are negative, second is zero or positive.

            constructIntersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex2TriangleB, vertex3TriangleB, vertex1TriangleB, additions) # Reorder B as (B, C, A).

        else # Only first vertex of B is negative.

            constructIntersection(vertex1TriangleA, vertex3TriangleA, vertex2TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, additions) # Pass A, reordered B.

    else # First vertex of Triangle B is exactly on the plane (distance zero).

        if distanceVertex2B < 0 # Second vertex is negative, third will decide.

            if distanceVertex3B >= 0 # Second negative, third zero or positive.

                constructIntersection(vertex1TriangleA, vertex3TriangleA, vertex2TriangleA, vertex2TriangleB, vertex3TriangleB, vertex1TriangleB, additions) # Mixed across the plane.

            else # Second & third negative.

                constructIntersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, additions) # Only first on the plane.

        else if distanceVertex2B > 0 # Second vertex is positive.

            if distanceVertex3B > 0 # Both second and third are positive.

                constructIntersection(vertex1TriangleA, vertex3TriangleA, vertex2TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, additions) # Both above the plane.

            else # Second positive, third zero or negative.

                constructIntersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex2TriangleB, vertex3TriangleB, vertex1TriangleB, additions) # Mixed, split across plane.

        else # Second vertex is exactly on the plane (zero).

            if distanceVertex3B > 0 # Only third is positive.

                constructIntersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex3TriangleB, vertex1TriangleB, vertex2TriangleB, additions) # Third above, first/second on plane.

            else if distanceVertex3B < 0 # Only third is negative.

                constructIntersection(vertex1TriangleA, vertex3TriangleA, vertex2TriangleA, vertex3TriangleB, vertex1TriangleB, vertex2TriangleB, additions) # Third below plane.

            else # All three B vertices are exactly on the plane (coplanar).

                additions.coplanar = true # Mark coplanar.
                resolveCoplanarTriangleIntersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, additions.normal1, additions.normal2)

### Resolves intersection between two coplanar triangles in 3D space.
    Since the triangles lie in the same plane, the problem is reduced from 3D to 2D.
    By projecting both triangles onto the axis-aligned plane (XY, YZ, or XZ) that maximizes the projected area.
    This minimizes numerical errors when working in 2D. The function then delegates the overlap test to `trianglesOverlap2D`.

@param {Vector2} vertex1TriangleA, vertex2TriangleA, vertex3TriangleA - Vertices of triangle A
@param {Vector2} vertex1TriangleB, vertex2TriangleB, vertex3TriangleB - Vertices of triangle B

@param {Vector3} normalTriangleA - Normal vector of Triangle A.
@param {Vector3} normalTriangleB - Normal vector of Triangle B.

@returns {Boolean} - True if the coplanar triangles overlap in 2D, false otherwise. ###
resolveCoplanarTriangleIntersection = (vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, normalTriangleA, normalTriangleB) ->

    # Prepare 2D projected vertices.
    vertex1TriangleA2D = new Vector2(); vertex2TriangleA2D = new Vector2(); vertex3TriangleA2D = new Vector2()
    vertex1TriangleB2D = new Vector2(); vertex2TriangleB2D = new Vector2(); vertex3TriangleB2D = new Vector2()

    # Absolute values of the triangle's normal components.
    # Used to determine the dominant axis, which we drop during 2D projection.
    normalAbsX = Math.abs(normalTriangleA.x)
    normalAbsY = Math.abs(normalTriangleA.y)
    normalAbsZ = Math.abs(normalTriangleA.z)

    # Project triangles into 2D by dropping the dominant axis of the normal.
    if (normalAbsX > normalAbsZ) and (normalAbsX >= normalAbsY) # Project onto YZ plane.

        vertex1TriangleA2D.set(vertex1TriangleA.y, vertex1TriangleA.z)
        vertex2TriangleA2D.set(vertex2TriangleA.y, vertex2TriangleA.z)
        vertex3TriangleA2D.set(vertex3TriangleA.y, vertex3TriangleA.z)

        vertex1TriangleB2D.set(vertex1TriangleB.y, vertex1TriangleB.z)
        vertex2TriangleB2D.set(vertex2TriangleB.y, vertex2TriangleB.z)
        vertex3TriangleB2D.set(vertex3TriangleB.y, vertex3TriangleB.z)

    else if (normalAbsY > normalAbsZ) and (normalAbsY >= normalAbsX) # Project onto XZ plane.

        vertex1TriangleA2D.set(vertex1TriangleA.x, vertex1TriangleA.z)
        vertex2TriangleA2D.set(vertex2TriangleA.x, vertex2TriangleA.z)
        vertex3TriangleA2D.set(vertex3TriangleA.x, vertex3TriangleA.z)

        vertex1TriangleB2D.set(vertex1TriangleB.x, vertex1TriangleB.z)
        vertex2TriangleB2D.set(vertex2TriangleB.x, vertex2TriangleB.z)
        vertex3TriangleB2D.set(vertex3TriangleB.x, vertex3TriangleB.z)

    else # Project onto XY plane

        vertex1TriangleA2D.set(vertex1TriangleA.x, vertex1TriangleA.y)
        vertex2TriangleA2D.set(vertex2TriangleA.x, vertex2TriangleA.y)
        vertex3TriangleA2D.set(vertex3TriangleA.x, vertex3TriangleA.y)

        vertex1TriangleB2D.set(vertex1TriangleB.x, vertex1TriangleB.y)
        vertex2TriangleB2D.set(vertex2TriangleB.x, vertex2TriangleB.y)
        vertex3TriangleB2D.set(vertex3TriangleB.x, vertex3TriangleB.y)

    return trianglesOverlap2D(vertex1TriangleA2D, vertex2TriangleA2D, vertex3TriangleA2D, vertex1TriangleB2D, vertex2TriangleB2D, vertex3TriangleB2D)

### Determines whether two triangles in 2D overlap.

    Behavior and notes:

    - Orientation: Triangles may be CW or CCW; inputs are normalized to CCW before testing.
    - Inclusivity: Overlap is inclusive of shared edges and shared vertices.
    - Degenerate handling:

        - If one triangle degenerates to a point, returns whether that point lies in (or on) the other triangle.
        - If both degenerate to points, returns true only if the points coincide within TRIANGLE_2D_EPSILON.
        - Degenerate line triangles are handled by the main CCW intersection routine and by point/segment checks where applicable.

@param {Vector2} vertex1TriangleA, vertex2TriangleA, vertex3TriangleA - Vertices of triangle A
@param {Vector2} vertex1TriangleB, vertex2TriangleB, vertex3TriangleB - Vertices of triangle B

@returns {Boolean} - True if the triangles overlap in 2D, false otherwise. ###
trianglesOverlap2D = (vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB) ->

    # Early handle point-degenerate cases explicitly and efficiently.

    if pointsEqual2D(vertex1TriangleB, vertex2TriangleB, TRIANGLE_2D_EPSILON) and pointsEqual2D(vertex2TriangleB, vertex3TriangleB, TRIANGLE_2D_EPSILON)

        return pointInTriangleInclusive2D(vertex1TriangleB, vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, TRIANGLE_2D_EPSILON)

    if pointsEqual2D(vertex1TriangleA, vertex2TriangleA, TRIANGLE_2D_EPSILON) and pointsEqual2D(vertex2TriangleA, vertex3TriangleA, TRIANGLE_2D_EPSILON)

        return pointInTriangleInclusive2D(vertex1TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, TRIANGLE_2D_EPSILON)

    # If both are line-degenerate (not points): reduce to segment overlap test.
    isLineDegenerate = (v1, v2, v3) ->

        (pointsEqual2D(v1, v2, TRIANGLE_2D_EPSILON) and not pointsEqual2D(v2, v3, TRIANGLE_2D_EPSILON)) or
        (pointsEqual2D(v2, v3, TRIANGLE_2D_EPSILON) and not pointsEqual2D(v1, v2, TRIANGLE_2D_EPSILON)) or
        (pointsEqual2D(v3, v1, TRIANGLE_2D_EPSILON) and not pointsEqual2D(v1, v2, TRIANGLE_2D_EPSILON))

    extractSegment = (v1, v2, v3) ->

        # Return the two distinct endpoints in stable order.
        if pointsEqual2D(v1, v2, TRIANGLE_2D_EPSILON) then [v2, v3] else if pointsEqual2D(v2, v3, TRIANGLE_2D_EPSILON) then [v1, v2] else [v1, v2] # fallback (should not reach if collinear case handled earlier)

    if isLineDegenerate(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA) and isLineDegenerate(vertex1TriangleB, vertex2TriangleB, vertex3TriangleB)

        [aS, aE] = extractSegment(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA)
        [bS, bE] = extractSegment(vertex1TriangleB, vertex2TriangleB, vertex3TriangleB)

        # Fast reject by axis-aligned bounding boxes.
        minAx = Math.min(aS.x, aE.x); maxAx = Math.max(aS.x, aE.x)
        minAy = Math.min(aS.y, aE.y); maxAy = Math.max(aS.y, aE.y)
        minBx = Math.min(bS.x, bE.x); maxBx = Math.max(bS.x, bE.x)
        minBy = Math.min(bS.y, bE.y); maxBy = Math.max(bS.y, bE.y)

        return false if maxAx < minBx - TRIANGLE_2D_EPSILON or maxBx < minAx - TRIANGLE_2D_EPSILON or maxAy < minBy - TRIANGLE_2D_EPSILON or maxBy < minAy - TRIANGLE_2D_EPSILON

        # Collinear check: orientation of any mixed triple should be ~0; since we know each triangle is a line, test one.
        if Math.abs(triangleOrientation2D(aS, aE, bS)) > TRIANGLE_2D_EPSILON

            return false

        # 1D overlap test along dominant axis (choose axis with larger span to reduce precision issues).
        spanAx = Math.abs(aE.x - aS.x); spanAy = Math.abs(aE.y - aS.y)

        if spanAx >= spanAy

            # Project onto X.
            aMin = Math.min(aS.x, aE.x) - TRIANGLE_2D_EPSILON; aMax = Math.max(aS.x, aE.x) + TRIANGLE_2D_EPSILON
            bMin = Math.min(bS.x, bE.x) - TRIANGLE_2D_EPSILON; bMax = Math.max(bS.x, bE.x) + TRIANGLE_2D_EPSILON

            return not (aMax < bMin or bMax < aMin)

        else

            aMin = Math.min(aS.y, aE.y) - TRIANGLE_2D_EPSILON; aMax = Math.max(aS.y, aE.y) + TRIANGLE_2D_EPSILON
            bMin = Math.min(bS.y, bE.y) - TRIANGLE_2D_EPSILON; bMax = Math.max(bS.y, bE.y) + TRIANGLE_2D_EPSILON

            return not (aMax < bMin or bMax < aMin)

    if triangleOrientation2D(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA) < 0 # If triangle A is CW.

        if triangleOrientation2D(vertex1TriangleB, vertex2TriangleB, vertex3TriangleB) < 0 # If both A and B are CW → reorder both.

            return triangleIntersectionCCW2D(vertex1TriangleA, vertex3TriangleA, vertex2TriangleA, vertex1TriangleB, vertex3TriangleB, vertex2TriangleB)

        else # Only A is CW → reorder A.

            return triangleIntersectionCCW2D(vertex1TriangleA, vertex3TriangleA, vertex2TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB)

    else # Triangle A is CCW.

        if triangleOrientation2D(vertex1TriangleB, vertex2TriangleB, vertex3TriangleB) < 0 # If only B is CW → reorder B.

            return triangleIntersectionCCW2D(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex3TriangleB, vertex2TriangleB)

        else # Both A and B are CCW → no reordering.

            return triangleIntersectionCCW2D(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB)

### Computes the orientation (signed area) of a 2D triangle defined by three vertices.
    The result indicates whether the points are arranged clockwise (CW), counter-clockwise (CCW), or collinear.

    Note: This returns the raw signed area (twice the triangle area), without applying an epsilon threshold.
    Callers should compare against a small EPS (e.g., TRIANGLE_2D_EPSILON) when classifying near-collinear inputs.

    Formula: orientation(a, b, c) = (a.x - c.x) * (b.y - c.y) - (a.y - c.y) * (b.x - c.x)

    - If result > 0 → counter-clockwise (CCW).
    - If result < 0 → clockwise (CW).
    - If result = 0 → points are collinear.

@param {Vector2} a - First vertex.
@param {Vector2} b - Second vertex.
@param {Vector2} c - Third vertex.

@returns {Number} - Positive if CCW, negative if CW, zero if collinear. ###
triangleOrientation2D = (a, b, c) ->

    # Compute the signed area of the triangle (a, b, c).
    (a.x - c.x) * (b.y - c.y) - (a.y - c.y) * (b.x - c.x)

### Determines if two counter-clockwise (CCW) triangles in 2D overlap.
    The function checks the relative orientation of triangle B's vertices with respect to triangle A.
    Then recursively tests for edge or vertex intersection depending on the configuration.

@param {Vector2} vertex1TriangleA, vertex2TriangleA, vertex3TriangleA - Vertices of triangle A (CCW order)
@param {Vector2} vertex1TriangleB, vertex2TriangleB, vertex3TriangleB - Vertices of triangle B (CCW order)

@return {Boolean} True if triangles overlap, false otherwise. ###
triangleIntersectionCCW2D = (vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB) ->

    # If vertex1TriangleB is on or to the left of edge vertex1TriangleA-vertex2TriangleA-vertex3TriangleA.
    if triangleOrientation2D(vertex1TriangleB, vertex2TriangleB, vertex1TriangleA) >= 0

        # If vertex2TriangleB is on or to the left of edge vertex2TriangleA-vertex3TriangleA-vertex1TriangleA.
        if triangleOrientation2D(vertex2TriangleB, vertex3TriangleB, vertex1TriangleA) >= 0

            # If vertex3TriangleB is on or to the left of edge vertex3TriangleA-vertex1TriangleA-vertex1TriangleA.
            if triangleOrientation2D(vertex3TriangleB, vertex1TriangleB, vertex1TriangleA) >= 0

                return true  # All vertices of B are inside A.

            else # Then vertex3TriangleB is outside, test edge intersection.

                return intersectionTestEdge2D(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB)

        else # Then vertex2TriangleB is outside.

            # If vertex3TriangleB is on or to the left of edge vertex3TriangleA-vertex1TriangleA-vertex1TriangleA, test edge intersection.
            if triangleOrientation2D(vertex3TriangleB, vertex1TriangleB, vertex1TriangleA) >= 0

                return intersectionTestEdge2D(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex3TriangleB, vertex1TriangleB, vertex2TriangleB)

            else # Then both vertex2TriangleB and vertex3TriangleB are outside, test vertex intersection.

                return intersectionTestVertex2D(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB)

    else # Then vertex2TriangleB is on or to the left of edge vertex2TriangleA-vertex3TriangleA-vertex1TriangleA.

        # If vertex2TriangleB is on or to the left of edge vertex2TriangleA-vertex3TriangleA-vertex1TriangleA.
        if triangleOrientation2D(vertex2TriangleB, vertex3TriangleB, vertex1TriangleA) >= 0

            # If vertex3TriangleB is on or to the left of edge vertex3TriangleA-vertex1TriangleA-vertex1TriangleA, test edge intersection.
            if triangleOrientation2D(vertex3TriangleB, vertex1TriangleB, vertex1TriangleA) >= 0

                return intersectionTestEdge2D(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex2TriangleB, vertex3TriangleB, vertex1TriangleB)

            else # Then vertex3TriangleB is outside, test vertex intersection.

                return intersectionTestVertex2D(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex2TriangleB, vertex3TriangleB, vertex1TriangleB)

        else # Then both vertex1TriangleB and vertex2TriangleB are outside, test vertex intersection.

            return intersectionTestVertex2D(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex3TriangleB, vertex1TriangleB, vertex2TriangleB)

### Checks for edge intersection between two triangles in 2D.

@param {Vector2} vertex1TriangleA, vertex2TriangleA, vertex3TriangleA - Vertices of triangle A
@param {Vector2} vertex1TriangleB, vertex2TriangleB, vertex3TriangleB - Vertices of triangle B

@return {Boolean} True if an edge intersection is found, false otherwise. ###
intersectionTestEdge2D = (vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB) ->

    segmentIntersectsInclusive = (a1, a2, b1, b2) ->

        # Fast reject by bounding boxes.

        minAx = Math.min(a1.x, a2.x); maxAx = Math.max(a1.x, a2.x)
        minAy = Math.min(a1.y, a2.y); maxAy = Math.max(a1.y, a2.y)

        minBx = Math.min(b1.x, b2.x); maxBx = Math.max(b1.x, b2.x)
        minBy = Math.min(b1.y, b2.y); maxBy = Math.max(b1.y, b2.y)

        return false if maxAx < minBx or maxBx < minAx or maxAy < minBy or maxBy < minAy

        o1 = triangleOrientation2D(a1, a2, b1)
        o2 = triangleOrientation2D(a1, a2, b2)
        o3 = triangleOrientation2D(b1, b2, a1)
        o4 = triangleOrientation2D(b1, b2, a2)

        if (o1 > 0 and o2 < 0 or o1 < 0 and o2 > 0) and (o3 > 0 and o4 < 0 or o3 < 0 and o4 > 0)

            return true # Proper intersection.

        # Collinear / endpoint inclusion checks.

        if Math.abs(o1) <= TRIANGLE_2D_EPSILON and pointOnSegmentInclusive2D(b1, a1, a2, TRIANGLE_2D_EPSILON) then return true
        if Math.abs(o2) <= TRIANGLE_2D_EPSILON and pointOnSegmentInclusive2D(b2, a1, a2, TRIANGLE_2D_EPSILON) then return true
        if Math.abs(o3) <= TRIANGLE_2D_EPSILON and pointOnSegmentInclusive2D(a1, b1, b2, TRIANGLE_2D_EPSILON) then return true
        if Math.abs(o4) <= TRIANGLE_2D_EPSILON and pointOnSegmentInclusive2D(a2, b1, b2, TRIANGLE_2D_EPSILON) then return true

        return false

    edgesA = [ [vertex1TriangleA, vertex2TriangleA], [vertex2TriangleA, vertex3TriangleA], [vertex3TriangleA, vertex1TriangleA] ]
    edgesB = [ [vertex1TriangleB, vertex2TriangleB], [vertex2TriangleB, vertex3TriangleB], [vertex3TriangleB, vertex1TriangleB] ]

    for [a1, a2] in edgesA

        for [b1, b2] in edgesB

            return true if segmentIntersectsInclusive(a1, a2, b1, b2)

    return false

### Checks for vertex intersection between two triangles in 2D.

@param {Vector2} vertex1TriangleA, vertex2TriangleA, vertex3TriangleA - Vertices of triangle A
@param {Vector2} vertex1TriangleB, vertex2TriangleB, vertex3TriangleB - Vertices of triangle B

@return {Boolean} True if a vertex intersection is found, false otherwise. ###
intersectionTestVertex2D = (vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB) ->

    # Returns true if any vertex of triangle B lies inside (or on) triangle A OR any vertex of triangle A lies inside (or on) triangle B.

    return true if pointInTriangleInclusive2D(vertex1TriangleB, vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, TRIANGLE_2D_EPSILON)
    return true if pointInTriangleInclusive2D(vertex2TriangleB, vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, TRIANGLE_2D_EPSILON)
    return true if pointInTriangleInclusive2D(vertex3TriangleB, vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, TRIANGLE_2D_EPSILON)

    return true if pointInTriangleInclusive2D(vertex1TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, TRIANGLE_2D_EPSILON)
    return true if pointInTriangleInclusive2D(vertex2TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, TRIANGLE_2D_EPSILON)
    return true if pointInTriangleInclusive2D(vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, TRIANGLE_2D_EPSILON)

    return false

### Determines the intersection segment (if any) between two triangles in 3D space.
    If an intersection segment exists, its endpoints are written to `additions.source` and `additions.target`.

@param {Vector3} vertex1TriangleA, vertex2TriangleA, vertex3TriangleA - Vertices of triangle A
@param {Vector3} vertex1TriangleB, vertex2TriangleB, vertex3TriangleB - Vertices of triangle B

@param {Object} additions - Data object used for storing extra intersection info:

    - coplanar {Boolean} whether the triangles lie in the same plane.
    - source {Vector3} intersection segment start (if applicable).
    - target {Vector3} intersection segment end (if applicable).
    - normal1 {Vector3} normal of Triangle A (used in coplanar case).
    - normal2 {Vector3} normal of Triangle B (used in coplanar case).

@return {Boolean} True if intersection segment exists, false otherwise. ###
constructIntersection = (vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, additions) ->

    alpha = undefined
    crossNormal = new Vector3()

    # Compute cross product for triangle orientation.
    temporaryVector3Primary.subVectors(vertex2TriangleA, vertex1TriangleA)
    temporaryVector3Secondary.subVectors(vertex3TriangleB, vertex1TriangleA)
    crossNormal.copy(temporaryVector3Primary).cross(temporaryVector3Secondary)
    temporaryVector3Quaternary.subVectors(vertex1TriangleB, vertex1TriangleA)

    if temporaryVector3Quaternary.dot(crossNormal) > 0

        # Check orientation with triangle A's third vertex.
        temporaryVector3Primary.subVectors(vertex3TriangleA, vertex1TriangleA)
        crossNormal.copy(temporaryVector3Primary).cross(temporaryVector3Secondary)

        if temporaryVector3Quaternary.dot(crossNormal) <= 0

            # Check orientation with triangle B's second vertex.
            temporaryVector3Secondary.subVectors(vertex2TriangleB, vertex1TriangleA)
            crossNormal.copy(temporaryVector3Primary).cross(temporaryVector3Secondary)

            if temporaryVector3Quaternary.dot(crossNormal) > 0

                # Compute intersection segment endpoints (case 1).
                temporaryVector3Primary.subVectors(vertex1TriangleA, vertex1TriangleB)
                temporaryVector3Secondary.subVectors(vertex1TriangleA, vertex3TriangleA)
                alpha = temporaryVector3Primary.dot(additions.normal2) / temporaryVector3Secondary.dot(additions.normal2)

                return false unless isFinite(alpha)

                temporaryVector3Primary.copy(temporaryVector3Secondary).multiplyScalar(alpha)
                additions.source.subVectors(vertex1TriangleA, temporaryVector3Primary)

                temporaryVector3Primary.subVectors(vertex1TriangleB, vertex1TriangleA)
                temporaryVector3Secondary.subVectors(vertex1TriangleB, vertex3TriangleB)
                alpha = temporaryVector3Primary.dot(additions.normal1) / temporaryVector3Secondary.dot(additions.normal1)

                return false unless isFinite(alpha)

                temporaryVector3Primary.copy(temporaryVector3Secondary).multiplyScalar(alpha)
                additions.target.subVectors(vertex1TriangleB, temporaryVector3Primary)

                return true

            else

                # Compute intersection segment endpoints (case 2).
                temporaryVector3Primary.subVectors(vertex1TriangleB, vertex1TriangleA)
                temporaryVector3Secondary.subVectors(vertex1TriangleB, vertex2TriangleB)
                alpha = temporaryVector3Primary.dot(additions.normal1) / temporaryVector3Secondary.dot(additions.normal1)

                return false unless isFinite(alpha)

                temporaryVector3Primary.copy(temporaryVector3Secondary).multiplyScalar(alpha)
                additions.source.subVectors(vertex1TriangleB, temporaryVector3Primary)

                temporaryVector3Primary.subVectors(vertex1TriangleB, vertex1TriangleA)
                temporaryVector3Secondary.subVectors(vertex1TriangleB, vertex3TriangleB)
                alpha = temporaryVector3Primary.dot(additions.normal1) / temporaryVector3Secondary.dot(additions.normal1)

                return false unless isFinite(alpha)

                temporaryVector3Primary.copy(temporaryVector3Secondary).multiplyScalar(alpha)
                additions.target.subVectors(vertex1TriangleB, temporaryVector3Primary)

                return true

        else

            return false # No intersection, orientation test failed.

    else

        temporaryVector3Secondary.subVectors(vertex2TriangleB, vertex1TriangleA)
        crossNormal.copy(temporaryVector3Primary).cross(temporaryVector3Secondary)

        if temporaryVector3Quaternary.dot(crossNormal) < 0

            return false # No intersection, orientation test failed.

        else

            temporaryVector3Primary.subVectors(vertex3TriangleA, vertex1TriangleA)
            crossNormal.copy(temporaryVector3Primary).cross(temporaryVector3Secondary)

            if temporaryVector3Quaternary.dot(crossNormal) < 0

                # Compute intersection segment endpoints (case 3).
                temporaryVector3Primary.subVectors(vertex1TriangleB, vertex1TriangleA)
                temporaryVector3Secondary.subVectors(vertex1TriangleB, vertex2TriangleB)
                alpha = temporaryVector3Primary.dot(additions.normal1) / temporaryVector3Secondary.dot(additions.normal1)

                return false unless isFinite(alpha)

                temporaryVector3Primary.copy(temporaryVector3Secondary).multiplyScalar(alpha)
                additions.source.subVectors(vertex1TriangleB, temporaryVector3Primary)

                temporaryVector3Primary.subVectors(vertex1TriangleB, vertex1TriangleA)
                temporaryVector3Secondary.subVectors(vertex1TriangleB, vertex3TriangleB)
                alpha = temporaryVector3Primary.dot(additions.normal1) / temporaryVector3Secondary.dot(additions.normal1)

                return false unless isFinite(alpha)

                temporaryVector3Primary.copy(temporaryVector3Secondary).multiplyScalar(alpha)
                additions.target.subVectors(vertex1TriangleB, temporaryVector3Primary)

                return true

            else

                # Compute intersection segment endpoints (case 4).
                temporaryVector3Primary.subVectors(vertex1TriangleA, vertex1TriangleB)
                temporaryVector3Secondary.subVectors(vertex1TriangleA, vertex3TriangleA)
                alpha = temporaryVector3Primary.dot(additions.normal2) / temporaryVector3Secondary.dot(additions.normal2)

                return false unless isFinite(alpha)

                temporaryVector3Primary.copy(temporaryVector3Secondary).multiplyScalar(alpha)
                additions.source.subVectors(vertex1TriangleA, temporaryVector3Primary)

                temporaryVector3Primary.subVectors(vertex1TriangleA, vertex1TriangleB)
                temporaryVector3Secondary.subVectors(vertex1TriangleA, vertex2TriangleA)
                alpha = temporaryVector3Primary.dot(additions.normal2) / temporaryVector3Secondary.dot(additions.normal2)

                return false unless isFinite(alpha)

                temporaryVector3Primary.copy(temporaryVector3Secondary).multiplyScalar(alpha)
                additions.target.subVectors(vertex1TriangleA, temporaryVector3Primary)

                return true

    return false # If none of the above, no intersection found.
