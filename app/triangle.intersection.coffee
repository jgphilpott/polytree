EPS2D = 1e-10

tempVector1 = new Vector3()
tempVector2 = new Vector3()
tempVector3 = new Vector3()

# Epsilon-aware 2D point equality.
pointsEqual2D = (p, q, eps = EPS2D) ->

    return Math.abs(p.x - q.x) <= eps and Math.abs(p.y - q.y) <= eps

# Inclusive point-on-segment check for collinear points.
pointOnSegmentInclusive2D = (p, a, b, eps = EPS2D) ->

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
pointInTriangleInclusive2D = (p, a, b, c, eps = EPS2D) ->

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

    tempVector1.copy(vertex1TriangleB).sub(vertex3TriangleB)
    tempVector2.copy(vertex2TriangleB).sub(vertex3TriangleB)

    normal2 = (new Vector3()).copy(tempVector1).cross(tempVector2)

    tempVector1.copy(vertex1TriangleA).sub(vertex3TriangleB)
    distanceVertex1A = tempVector1.dot(normal2)

    tempVector1.copy(vertex2TriangleA).sub(vertex3TriangleB)
    distanceVertex2A = tempVector1.dot(normal2)

    tempVector1.copy(vertex3TriangleA).sub(vertex3TriangleB)
    distanceVertex3A = tempVector1.dot(normal2)

    if ((distanceVertex1A * distanceVertex2A) > 0) and ((distanceVertex1A * distanceVertex3A) > 0)

        return false # All vertices of Triangle A are on the same side of Triangle B’s plane.

    # Step 2: Compute signed distances of Triangle B’s vertices relative to the plane defined by Triangle A.

    tempVector1.copy(vertex2TriangleA).sub(vertex1TriangleA)
    tempVector2.copy(vertex3TriangleA).sub(vertex1TriangleA)

    normal1 = (new Vector3()).copy(tempVector1).cross(tempVector2)

    tempVector1.copy(vertex1TriangleB).sub(vertex3TriangleA)
    distanceVertex1B = tempVector1.dot(normal1)

    tempVector1.copy(vertex2TriangleB).sub(vertex3TriangleA)
    distanceVertex2B = tempVector1.dot(normal1)

    tempVector1.copy(vertex3TriangleB).sub(vertex3TriangleA)
    distanceVertex3B = tempVector1.dot(normal1)

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
        - If both degenerate to points, returns true only if the points coincide within EPS2D.
        - Degenerate line triangles are handled by the main CCW intersection routine and by point/segment checks where applicable.

@param {Vector2} vertex1TriangleA, vertex2TriangleA, vertex3TriangleA - Vertices of triangle A
@param {Vector2} vertex1TriangleB, vertex2TriangleB, vertex3TriangleB - Vertices of triangle B

@returns {Boolean} - True if the triangles overlap in 2D, false otherwise. ###
trianglesOverlap2D = (vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB) ->

    # Early handle point-degenerate cases explicitly and efficiently.

    if pointsEqual2D(vertex1TriangleB, vertex2TriangleB, EPS2D) and pointsEqual2D(vertex2TriangleB, vertex3TriangleB, EPS2D)

        return pointInTriangleInclusive2D(vertex1TriangleB, vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, EPS2D)

    if pointsEqual2D(vertex1TriangleA, vertex2TriangleA, EPS2D) and pointsEqual2D(vertex2TriangleA, vertex3TriangleA, EPS2D)

        return pointInTriangleInclusive2D(vertex1TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, EPS2D)

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
    Callers should compare against a small EPS (e.g., EPS2D) when classifying near-collinear inputs.

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

        if Math.abs(o1) <= EPS2D and pointOnSegmentInclusive2D(b1, a1, a2, EPS2D) then return true
        if Math.abs(o2) <= EPS2D and pointOnSegmentInclusive2D(b2, a1, a2, EPS2D) then return true
        if Math.abs(o3) <= EPS2D and pointOnSegmentInclusive2D(a1, b1, b2, EPS2D) then return true
        if Math.abs(o4) <= EPS2D and pointOnSegmentInclusive2D(a2, b1, b2, EPS2D) then return true

        return false

    edgesA = [ [vertex1TriangleA, vertex2TriangleA], [vertex2TriangleA, vertex3TriangleA], [vertex3TriangleA, vertex1TriangleA] ]
    edgesB = [ [vertex1TriangleB, vertex2TriangleB], [vertex2TriangleB, vertex3TriangleB], [vertex3TriangleB, vertex1TriangleB] ]

    for [a1, a2] in edgesA

        for [b1, b2] in edgesB

            return true if segmentIntersectsInclusive(a1, a2, b1, b2)

    false

### Checks for vertex intersection between two triangles in 2D.

@param {Vector2} vertex1TriangleA, vertex2TriangleA, vertex3TriangleA - Vertices of triangle A
@param {Vector2} vertex1TriangleB, vertex2TriangleB, vertex3TriangleB - Vertices of triangle B

@return {Boolean} True if a vertex intersection is found, false otherwise. ###
intersectionTestVertex2D = (vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB) ->

    # If vertex3TriangleB is on or to the left of edge vertex1TriangleB-vertex2TriangleA.
    if triangleOrientation2D(vertex3TriangleB, vertex1TriangleB, vertex2TriangleA) >= 0

        # If vertex3TriangleB is on or to the right of edge vertex2TriangleB-vertex2TriangleA.
        if triangleOrientation2D(vertex3TriangleB, vertex2TriangleB, vertex2TriangleA) <= 0

            # If vertex1TriangleA is on the right of edge vertex1TriangleB-vertex2TriangleA.
            if triangleOrientation2D(vertex1TriangleA, vertex1TriangleB, vertex2TriangleA) > 0

                # If vertex1TriangleA is on or to the left of edge vertex2TriangleB-vertex2TriangleA.
                if triangleOrientation2D(vertex1TriangleA, vertex2TriangleB, vertex2TriangleA) <= 0
                    return true
                else # Then vertex1TriangleA is outside edge vertex2TriangleB-vertex2TriangleA.
                    return false

            else # Then vertex1TriangleA is on or to the left of edge vertex1TriangleB-vertex2TriangleA.

                # If vertex1TriangleA is on or to the left of edge vertex1TriangleB-vertex3TriangleA.
                if triangleOrientation2D(vertex1TriangleA, vertex1TriangleB, vertex3TriangleA) >= 0

                    # If vertex2TriangleA is on or to the left of edge vertex3TriangleA-vertex1TriangleB.
                    if triangleOrientation2D(vertex2TriangleA, vertex3TriangleA, vertex1TriangleB) >= 0
                        return true
                    else # Then vertex2TriangleA is outside edge vertex3TriangleA-vertex1TriangleB.
                        return false

                else # Then vertex1TriangleA is outside edge vertex1TriangleB-vertex3TriangleA.

                    return false

        else # Then vertex3TriangleB is on the left of edge vertex2TriangleB-vertex2TriangleA.

            # If vertex1TriangleA is on or to the left of edge vertex2TriangleB-vertex2TriangleA.
            if triangleOrientation2D(vertex1TriangleA, vertex2TriangleB, vertex2TriangleA) <= 0

                # If vertex3TriangleB is on or to the left of edge vertex2TriangleB-vertex3TriangleA.
                if triangleOrientation2D(vertex3TriangleB, vertex2TriangleB, vertex3TriangleA) <= 0

                    # If vertex2TriangleA is on or to the left of edge vertex3TriangleA-vertex2TriangleB.
                    if triangleOrientation2D(vertex2TriangleA, vertex3TriangleA, vertex2TriangleB) >= 0
                        return true
                    else # Then vertex2TriangleA is outside edge vertex3TriangleA-vertex2TriangleB.
                        return false

                else # Then vertex3TriangleB is outside edge vertex2TriangleB-vertex3TriangleA.

                    return false

            else # Then vertex1TriangleA is outside edge vertex2TriangleB-vertex2TriangleA.

                return false

    else # Then vertex3TriangleB is outside edge vertex1TriangleB-vertex2TriangleA.

        # If vertex3TriangleB is on or to the left of edge vertex1TriangleB-vertex3TriangleA.
        if triangleOrientation2D(vertex3TriangleB, vertex1TriangleB, vertex3TriangleA) >= 0

            # If vertex2TriangleA is on or to the left of edge vertex3TriangleA-vertex3TriangleB.
            if triangleOrientation2D(vertex2TriangleA, vertex3TriangleA, vertex3TriangleB) >= 0

                # If vertex1TriangleA is on or to the left of edge vertex1TriangleB-vertex3TriangleA.
                if triangleOrientation2D(vertex1TriangleA, vertex1TriangleB, vertex3TriangleA) >= 0
                    return true
                else # Then vertex1TriangleA is outside edge vertex1TriangleB-vertex3TriangleA.
                    return false

            else # Then vertex2TriangleA is outside edge vertex3TriangleA-vertex3TriangleB.

                # If vertex2TriangleA is on or to the left of edge vertex3TriangleA-vertex2TriangleB.
                if triangleOrientation2D(vertex2TriangleA, vertex3TriangleA, vertex2TriangleB) >= 0

                    # If vertex3TriangleB is on or to the left of edge vertex3TriangleA-vertex2TriangleB.
                    if triangleOrientation2D(vertex3TriangleB, vertex3TriangleA, vertex2TriangleB) >= 0
                        return true
                    else # Then vertex3TriangleB is outside edge vertex3TriangleA-vertex2TriangleB.
                        return false

                else # Then vertex2TriangleA is outside edge vertex3TriangleA-vertex2TriangleB.

                    return false

        else # Then vertex3TriangleB is outside edge vertex1TriangleB-vertex3TriangleA.

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
    tempVector1.subVectors(vertex2TriangleA, vertex1TriangleA)
    tempVector2.subVectors(vertex3TriangleB, vertex1TriangleA)
    crossNormal.copy(tempVector1).cross(tempVector2)
    tempVector3.subVectors(vertex1TriangleB, vertex1TriangleA)

    if tempVector3.dot(crossNormal) > 0

        # Check orientation with triangle A's third vertex.
        tempVector1.subVectors(vertex3TriangleA, vertex1TriangleA)
        crossNormal.copy(tempVector1).cross(tempVector2)

        if tempVector3.dot(crossNormal) <= 0

            # Check orientation with triangle B's second vertex.
            tempVector2.subVectors(vertex2TriangleB, vertex1TriangleA)
            crossNormal.copy(tempVector1).cross(tempVector2)

            if tempVector3.dot(crossNormal) > 0

                # Compute intersection segment endpoints (case 1).
                tempVector1.subVectors(vertex1TriangleA, vertex1TriangleB)
                tempVector2.subVectors(vertex1TriangleA, vertex3TriangleA)
                alpha = tempVector1.dot(additions.normal2) / tempVector2.dot(additions.normal2)
                tempVector1.copy(tempVector2).multiplyScalar(alpha)
                additions.source.subVectors(vertex1TriangleA, tempVector1)

                tempVector1.subVectors(vertex1TriangleB, vertex1TriangleA)
                tempVector2.subVectors(vertex1TriangleB, vertex3TriangleB)
                alpha = tempVector1.dot(additions.normal1) / tempVector2.dot(additions.normal1)
                tempVector1.copy(tempVector2).multiplyScalar(alpha)
                additions.target.subVectors(vertex1TriangleB, tempVector1)

                return true

            else

                # Compute intersection segment endpoints (case 2).
                tempVector1.subVectors(vertex1TriangleB, vertex1TriangleA)
                tempVector2.subVectors(vertex1TriangleB, vertex2TriangleB)
                alpha = tempVector1.dot(additions.normal1) / tempVector2.dot(additions.normal1)
                tempVector1.copy(tempVector2).multiplyScalar(alpha)
                additions.source.subVectors(vertex1TriangleB, tempVector1)

                tempVector1.subVectors(vertex1TriangleB, vertex1TriangleA)
                tempVector2.subVectors(vertex1TriangleB, vertex3TriangleB)
                alpha = tempVector1.dot(additions.normal1) / tempVector2.dot(additions.normal1)
                tempVector1.copy(tempVector2).multiplyScalar(alpha)
                additions.target.subVectors(vertex1TriangleB, tempVector1)

                return true

        else

            return false # No intersection, orientation test failed.

    else

        tempVector2.subVectors(vertex2TriangleB, vertex1TriangleA)
        crossNormal.copy(tempVector1).cross(tempVector2)

        if tempVector3.dot(crossNormal) < 0

            return false # No intersection, orientation test failed.

        else

            tempVector1.subVectors(vertex3TriangleA, vertex1TriangleA)
            crossNormal.copy(tempVector1).cross(tempVector2)

            if tempVector3.dot(crossNormal) < 0

                # Compute intersection segment endpoints (case 3).
                tempVector1.subVectors(vertex1TriangleB, vertex1TriangleA)
                tempVector2.subVectors(vertex1TriangleB, vertex2TriangleB)
                alpha = tempVector1.dot(additions.normal1) / tempVector2.dot(additions.normal1)
                tempVector1.copy(tempVector2).multiplyScalar(alpha)
                additions.source.subVectors(vertex1TriangleB, tempVector1)

                tempVector1.subVectors(vertex1TriangleB, vertex1TriangleA)
                tempVector2.subVectors(vertex1TriangleB, vertex3TriangleB)
                alpha = tempVector1.dot(additions.normal1) / tempVector2.dot(additions.normal1)
                tempVector1.copy(tempVector2).multiplyScalar(alpha)
                additions.target.subVectors(vertex1TriangleB, tempVector1)

                return true

            else

                # Compute intersection segment endpoints (case 4).
                tempVector1.subVectors(vertex1TriangleA, vertex1TriangleB)
                tempVector2.subVectors(vertex1TriangleA, vertex3TriangleA)
                alpha = tempVector1.dot(additions.normal2) / tempVector2.dot(additions.normal2)
                tempVector1.copy(tempVector2).multiplyScalar(alpha)
                additions.source.subVectors(vertex1TriangleA, tempVector1)

                tempVector1.subVectors(vertex1TriangleA, vertex1TriangleB)
                tempVector2.subVectors(vertex1TriangleA, vertex2TriangleA)
                alpha = tempVector1.dot(additions.normal2) / tempVector2.dot(additions.normal2)
                tempVector1.copy(tempVector2).multiplyScalar(alpha)
                additions.target.subVectors(vertex1TriangleA, tempVector1)

                return true

    return false # If none of the above, no intersection found.

module.exports = { triangleIntersectsTriangle, resolveTriangleIntersection, resolveCoplanarTriangleIntersection, trianglesOverlap2D, triangleOrientation2D, triangleIntersectionCCW2D, intersectionTestEdge2D, intersectionTestVertex2D, constructIntersection }
