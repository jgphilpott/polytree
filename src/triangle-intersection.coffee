import { Vector2, Vector3 } from "three"

tempVector1 = new Vector3()
tempVector2 = new Vector3()
tempVector3 = new Vector3()

### Checks whether two triangles in 3D space intersect.

@param {Object} triangleA - First triangle, with properties {a, b, c} (Vector3 vertices).
@param {Object} triangleB - Second triangle, with properties {a, b, c} (Vector3 vertices).

@param {Object} additions - Optional object used for storing extra intersection info:
    - coplanar {Boolean} whether the triangles lie in the same plane
    - source {Vector3} intersection segment start (if applicable)
    - target {Vector3} intersection segment end (if applicable)

@returns {Boolean} true if the triangles intersect, false otherwise. ###
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

    N2 = (new Vector3()).copy(tempVector1).cross(tempVector2)

    tempVector1.copy(vertex1TriangleA).sub(vertex3TriangleB)
    distanceVertex1A = tempVector1.dot(N2)

    tempVector1.copy(vertex2TriangleA).sub(vertex3TriangleB)
    distanceVertex2A = tempVector1.dot(N2)

    tempVector1.copy(vertex3TriangleA).sub(vertex3TriangleB)
    distanceVertex3A = tempVector1.dot(N2)

    if ((distanceVertex1A * distanceVertex2A) > 0) and ((distanceVertex1A * distanceVertex3A) > 0)

        return false # All vertices of Triangle A are on the same side of Triangle B’s plane.

    # Step 2: Compute signed distances of Triangle B’s vertices relative to the plane defined by Triangle A.

    tempVector1.copy(vertex2TriangleA).sub(vertex1TriangleA)
    tempVector2.copy(vertex3TriangleA).sub(vertex1TriangleA)

    N1 = (new Vector3()).copy(tempVector1).cross(tempVector2)

    tempVector1.copy(vertex1TriangleB).sub(vertex3TriangleA)
    distanceVertex1B = tempVector1.dot(N1)

    tempVector1.copy(vertex2TriangleB).sub(vertex3TriangleA)
    distanceVertex2B = tempVector1.dot(N1)

    tempVector1.copy(vertex3TriangleB).sub(vertex3TriangleA)
    distanceVertex3B = tempVector1.dot(N1)

    if ((distanceVertex1B * distanceVertex2B) > 0) and ((distanceVertex1B * distanceVertex3B) > 0)

        return false # All vertices of Triangle B are on the same side of Triangle A’s plane.

    # Step 3: At this point, neither triangle is fully on one side of the other’s plane. This means the triangles potentially intersect.
    # Next, we use the vertex signed distances to decide which configuration applies and call `resolveTriangleIntersection` (or `resolveCoplanarTriangleIntersection` if the triangles are coplanar).

    additions.N1 = N1
    additions.N2 = N2

    if distanceVertex1A > 0

        if distanceVertex2A > 0
            resolveTriangleIntersection(vertex3TriangleA, vertex1TriangleA, vertex2TriangleA, vertex1TriangleB, vertex3TriangleB, vertex2TriangleB, distanceVertex1B, distanceVertex3B, distanceVertex2B, additions)
        else if distanceVertex3A > 0
            resolveTriangleIntersection(vertex2TriangleA, vertex3TriangleA, vertex1TriangleA, vertex1TriangleB, vertex3TriangleB, vertex2TriangleB, distanceVertex1B, distanceVertex3B, distanceVertex2B, additions)
        else
            resolveTriangleIntersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, distanceVertex1B, distanceVertex2B, distanceVertex3B, additions)

    else if distanceVertex1A < 0

        if distanceVertex2A < 0
            resolveTriangleIntersection(vertex3TriangleA, vertex1TriangleA, vertex2TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, distanceVertex1B, distanceVertex2B, distanceVertex3B, additions)
        else if distanceVertex3A < 0
            resolveTriangleIntersection(vertex2TriangleA, vertex3TriangleA, vertex1TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, distanceVertex1B, distanceVertex2B, distanceVertex3B, additions)
        else
            resolveTriangleIntersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex3TriangleB, vertex2TriangleB, distanceVertex1B, distanceVertex3B, distanceVertex2B, additions)

    else

        if distanceVertex2A < 0

            if distanceVertex3A >= 0
                resolveTriangleIntersection(vertex2TriangleA, vertex3TriangleA, vertex1TriangleA, vertex1TriangleB, vertex3TriangleB, vertex2TriangleB, distanceVertex1B, distanceVertex3B, distanceVertex2B, additions)
            else
                resolveTriangleIntersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, distanceVertex1B, distanceVertex2B, distanceVertex3B, additions)

        else if distanceVertex2A > 0

            if distanceVertex3A > 0
                resolveTriangleIntersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex3TriangleB, vertex2TriangleB, distanceVertex1B, distanceVertex3B, distanceVertex2B, additions)
            else
                resolveTriangleIntersection(vertex2TriangleA, vertex3TriangleA, vertex1TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, distanceVertex1B, distanceVertex2B, distanceVertex3B, additions)

        else

            if distanceVertex3A > 0
                resolveTriangleIntersection(vertex3TriangleA, vertex1TriangleA, vertex2TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, distanceVertex1B, distanceVertex2B, distanceVertex3B, additions)
            else if distanceVertex3A < 0
                resolveTriangleIntersection(vertex3TriangleA, vertex1TriangleA, vertex2TriangleA, vertex1TriangleB, vertex3TriangleB, vertex2TriangleB, distanceVertex1B, distanceVertex3B, distanceVertex2B, additions)
            else
                additions.coplanar = true # The triangles are co-planar.
                resolveCoplanarTriangleIntersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, N1, N2)

### Determines the intersection between two 3D triangles given their vertices and the signed distances of Triangle B’s vertices to the plane of Triangle A.
    This function decides which case applies (based on the signs of the distances), then calls either `constructIntersection` (for non-coplanar cases) or `coplanarTriangleIntersection` (for coplanar triangles).

@param {Vector2} vertex1TriangleA, vertex2TriangleA, vertex3TriangleA - Vertices of triangle A
@param {Vector2} vertex1TriangleB, vertex2TriangleB, vertex3TriangleB - Vertices of triangle B

@param {Number} distanceVertex1B - Signed distance of vertex1TriangleB to Triangle A’s plane.
@param {Number} distanceVertex2B - Signed distance of vertex2TriangleB to Triangle A’s plane.
@param {Number} distanceVertex3B - Signed distance of vertex3TriangleB to Triangle A’s plane.

@param {Object} additions - Extra data object used for storing extra intersection info:
    - coplanar {Boolean} whether the triangles lie in the same plane
    - source {Vector3} intersection segment start (if applicable)
    - target {Vector3} intersection segment end (if applicable)
    - N1 {Vector3} normal of Triangle A (used in coplanar case)
    - N2 {Vector3} normal of Triangle B (used in coplanar case)

@returns {Boolean|undefined} - Returns true if an intersection is found, false if none, or nothing (constructIntersection handles output). ###
resolveTriangleIntersection = (vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, distanceVertex1B, distanceVertex2B, distanceVertex3B, additions) ->

    if distanceVertex1B > 0

        if distanceVertex2B > 0
            constructIntersection(vertex1TriangleA, vertex3TriangleA, vertex2TriangleA, vertex3TriangleB, vertex1TriangleB, vertex2TriangleB, additions)
        else if distanceVertex3B > 0
            constructIntersection(vertex1TriangleA, vertex3TriangleA, vertex2TriangleA, vertex2TriangleB, vertex3TriangleB, vertex1TriangleB, additions)
        else
            constructIntersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, additions)

    else if distanceVertex1B < 0

        if distanceVertex2B < 0
            constructIntersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex3TriangleB, vertex1TriangleB, vertex2TriangleB, additions)
        else if distanceVertex3B < 0
            constructIntersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex2TriangleB, vertex3TriangleB, vertex1TriangleB, additions)
        else
            constructIntersection(vertex1TriangleA, vertex3TriangleA, vertex2TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, additions)

    else

        if distanceVertex2B < 0

            if distanceVertex3B >= 0
                constructIntersection(vertex1TriangleA, vertex3TriangleA, vertex2TriangleA, vertex2TriangleB, vertex3TriangleB, vertex1TriangleB, additions)
            else
                constructIntersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, additions)

        else if distanceVertex2B > 0

            if distanceVertex3B > 0
                constructIntersection(vertex1TriangleA, vertex3TriangleA, vertex2TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, additions)
            else
                constructIntersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex2TriangleB, vertex3TriangleB, vertex1TriangleB, additions)

        else

            if distanceVertex3B > 0
                constructIntersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex3TriangleB, vertex1TriangleB, vertex2TriangleB, additions)
            else if distanceVertex3B < 0
                constructIntersection(vertex1TriangleA, vertex3TriangleA, vertex2TriangleA, vertex3TriangleB, vertex1TriangleB, vertex2TriangleB, additions)
            else
                additions.coplanar = true # The triangles are co-planar.
                resolveCoplanarTriangleIntersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, additions.N1, additions.N2)

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

        vertex1TriangleA2D.set(vertex1TriangleA.z, vertex1TriangleA.y)
        vertex2TriangleA2D.set(vertex2TriangleA.z, vertex2TriangleA.y)
        vertex3TriangleA2D.set(vertex3TriangleA.z, vertex3TriangleA.y)

        vertex1TriangleB2D.set(vertex1TriangleB.z, vertex1TriangleB.y)
        vertex2TriangleB2D.set(vertex2TriangleB.z, vertex2TriangleB.y)
        vertex3TriangleB2D.set(vertex3TriangleB.z, vertex3TriangleB.y)

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

    Triangles may initially be oriented clockwise (CW) or counter-clockwise (CCW).
    To ensure a consistent comparison, the function:

        1. Checks the orientation of each triangle using `triangleOrientation2D`.
        2. If a triangle is CW, its vertices are reordered to make it CCW.
        3. Calls `triangleIntersectionCCW2D` to test for overlap, assuming both are CCW.

@param {Vector2} vertex1TriangleA, vertex2TriangleA, vertex3TriangleA - Vertices of triangle A
@param {Vector2} vertex1TriangleB, vertex2TriangleB, vertex3TriangleB - Vertices of triangle B

@returns {Boolean} - True if the triangles overlap in 2D, false otherwise. ###
trianglesOverlap2D = (vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB) ->

    # If triangle A is CW.
    if triangleOrientation2D(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA) < 0

        # If both A and B are CW → reorder both.
        if triangleOrientation2D(vertex1TriangleB, vertex2TriangleB, vertex3TriangleB) < 0

            return triangleIntersectionCCW2D(vertex1TriangleA, vertex3TriangleA, vertex2TriangleA, vertex1TriangleB, vertex3TriangleB, vertex2TriangleB)

        else # Only A is CW → reorder A.

            return triangleIntersectionCCW2D(vertex1TriangleA, vertex3TriangleA, vertex2TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB)

    else # Triangle A is CCW.

        # If only B is CW → reorder B.
        if triangleOrientation2D(vertex1TriangleB, vertex2TriangleB, vertex3TriangleB) < 0

            return triangleIntersectionCCW2D(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex3TriangleB, vertex2TriangleB)

        else # Both A and B are CCW → no reordering.

            return triangleIntersectionCCW2D(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB)

### Computes the orientation (signed area) of a 2D triangle defined by three vertices.
    The result indicates whether the points are arranged clockwise (CW), counter-clockwise (CCW), or collinear.

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

                true  # All vertices of B are inside A.

            else # Then vertex3TriangleB is outside, test edge intersection.

                intersectionTestEdge2D(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB)

        else # Then vertex2TriangleB is outside.

            # If vertex3TriangleB is on or to the left of edge vertex3TriangleA-vertex1TriangleA-vertex1TriangleA, test edge intersection.
            if triangleOrientation2D(vertex3TriangleB, vertex1TriangleB, vertex1TriangleA) >= 0

                intersectionTestEdge2D(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex3TriangleB, vertex1TriangleB, vertex2TriangleB)

            else # Then both vertex2TriangleB and vertex3TriangleB are outside, test vertex intersection.

                intersectionTestVertex2D(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB)

    else # Then vertex2TriangleB is on or to the left of edge vertex2TriangleA-vertex3TriangleA-vertex1TriangleA.

        # If vertex2TriangleB is on or to the left of edge vertex2TriangleA-vertex3TriangleA-vertex1TriangleA.
        if triangleOrientation2D(vertex2TriangleB, vertex3TriangleB, vertex1TriangleA) >= 0

            # If vertex3TriangleB is on or to the left of edge vertex3TriangleA-vertex1TriangleA-vertex1TriangleA, test edge intersection.
            if triangleOrientation2D(vertex3TriangleB, vertex1TriangleB, vertex1TriangleA) >= 0

                intersectionTestEdge2D(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex2TriangleB, vertex3TriangleB, vertex1TriangleB)

            else # Then vertex3TriangleB is outside, test vertex intersection.

                intersectionTestVertex2D(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex2TriangleB, vertex3TriangleB, vertex1TriangleB)

        else # Then both vertex1TriangleB and vertex2TriangleB are outside, test vertex intersection.

            intersectionTestVertex2D(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex3TriangleB, vertex1TriangleB, vertex2TriangleB)

### Checks for edge intersection between two triangles in 2D.

@param {Vector2} vertex1TriangleA, vertex2TriangleA, vertex3TriangleA - Vertices of triangle A
@param {Vector2} vertex1TriangleB, vertex2TriangleB, vertex3TriangleB - Vertices of triangle B

@return {Boolean} ###
intersectionTestEdge2D = (vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB) ->

    if triangleOrientation2D(vertex3TriangleB, vertex1TriangleB, vertex2TriangleA) >= 0
        if triangleOrientation2D(vertex1TriangleA, vertex1TriangleB, vertex2TriangleA) >= 0
            if triangleOrientation2D(vertex1TriangleA, vertex2TriangleA, vertex3TriangleB) >= 0
                true
            else
                false
        else
            if triangleOrientation2D(vertex2TriangleA, vertex3TriangleA, vertex1TriangleB) >= 0
                if triangleOrientation2D(vertex3TriangleA, vertex1TriangleA, vertex1TriangleB) >= 0
                    true
                else
                    false
            else
                false
    else
        if triangleOrientation2D(vertex3TriangleB, vertex1TriangleB, vertex3TriangleA) >= 0
            if triangleOrientation2D(vertex1TriangleA, vertex1TriangleB, vertex3TriangleA) >= 0
                if triangleOrientation2D(vertex1TriangleA, vertex3TriangleA, vertex3TriangleB) >= 0
                    true
                else
                    if triangleOrientation2D(vertex2TriangleA, vertex3TriangleA, vertex3TriangleB) >= 0
                        true
                    else
                        false
            else
                false
        else
            false

### Checks for vertex intersection between two triangles in 2D.

@param {Vector2} vertex1TriangleA, vertex2TriangleA, vertex3TriangleA - Vertices of triangle A
@param {Vector2} vertex1TriangleB, vertex2TriangleB, vertex3TriangleB - Vertices of triangle B

@return {Boolean} ###
intersectionTestVertex2D = (vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB) ->

    if triangleOrientation2D(vertex3TriangleB, vertex1TriangleB, vertex2TriangleA) >= 0
        if triangleOrientation2D(vertex3TriangleB, vertex2TriangleB, vertex2TriangleA) <= 0
            if triangleOrientation2D(vertex1TriangleA, vertex1TriangleB, vertex2TriangleA) > 0
                if triangleOrientation2D(vertex1TriangleA, vertex2TriangleB, vertex2TriangleA) <= 0
                    true
                else
                    false
            else
                if triangleOrientation2D(vertex1TriangleA, vertex1TriangleB, vertex3TriangleA) >= 0
                    if triangleOrientation2D(vertex2TriangleA, vertex3TriangleA, vertex1TriangleB) >= 0
                        true
                    else
                        false
                else
                    false
        else
            if triangleOrientation2D(vertex1TriangleA, vertex2TriangleB, vertex2TriangleA) <= 0
                if triangleOrientation2D(vertex3TriangleB, vertex2TriangleB, vertex3TriangleA) <= 0
                    if triangleOrientation2D(vertex2TriangleA, vertex3TriangleA, vertex2TriangleB) >= 0
                        true
                    else
                        false
                else
                    false
            else
                false
    else
        if triangleOrientation2D(vertex3TriangleB, vertex1TriangleB, vertex3TriangleA) >= 0
            if triangleOrientation2D(vertex2TriangleA, vertex3TriangleA, vertex3TriangleB) >= 0
                if triangleOrientation2D(vertex1TriangleA, vertex1TriangleB, vertex3TriangleA) >= 0
                    true
                else
                    false
            else
                if triangleOrientation2D(vertex2TriangleA, vertex3TriangleA, vertex2TriangleB) >= 0
                    if triangleOrientation2D(vertex3TriangleB, vertex3TriangleA, vertex2TriangleB) >= 0
                        true
                    else
                        false
                else
                    false
        else
            false

constructIntersection = (vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, additions) ->

    alpha = undefined
    N = new Vector3()
    tempVector1.subVectors(vertex2TriangleA, vertex1TriangleA)
    tempVector2.subVectors(vertex3TriangleB, vertex1TriangleA)
    N.copy(tempVector1).cross(tempVector2)
    tempVector3.subVectors(vertex1TriangleB, vertex1TriangleA)
    if tempVector3.dot(N) > 0
        tempVector1.subVectors(vertex3TriangleA, vertex1TriangleA)
        N.copy(tempVector1).cross(tempVector2)
        if tempVector3.dot(N) <= 0
            tempVector2.subVectors(vertex2TriangleB, vertex1TriangleA)
            N.copy(tempVector1).cross(tempVector2)
            if tempVector3.dot(N) > 0
                tempVector1.subVectors(vertex1TriangleA, vertex1TriangleB)
                tempVector2.subVectors(vertex1TriangleA, vertex3TriangleA)
                alpha = tempVector1.dot(additions.N2) / tempVector2.dot(additions.N2)
                tempVector1.copy(tempVector2).multiplyScalar(alpha)
                additions.source.subVectors(vertex1TriangleA, tempVector1)
                tempVector1.subVectors(vertex1TriangleB, vertex1TriangleA)
                tempVector2.subVectors(vertex1TriangleB, vertex3TriangleB)
                alpha = tempVector1.dot(additions.N1) / tempVector2.dot(additions.N1)
                tempVector1.copy(tempVector2).multiplyScalar(alpha)
                additions.target.subVectors(vertex1TriangleB, tempVector1)
                true
            else
                tempVector1.subVectors(vertex1TriangleB, vertex1TriangleA)
                tempVector2.subVectors(vertex1TriangleB, vertex2TriangleB)
                alpha = tempVector1.dot(additions.N1) / tempVector2.dot(additions.N1)
                tempVector1.copy(tempVector2).multiplyScalar(alpha)
                additions.source.subVectors(vertex1TriangleB, tempVector1)
                tempVector1.subVectors(vertex1TriangleB, vertex1TriangleA)
                tempVector2.subVectors(vertex1TriangleB, vertex3TriangleB)
                alpha = tempVector1.dot(additions.N1) / tempVector2.dot(additions.N1)
                tempVector1.copy(tempVector2).multiplyScalar(alpha)
                additions.target.subVectors(vertex1TriangleB, tempVector1)
                true
        else
            false
    else
        tempVector2.subVectors(vertex2TriangleB, vertex1TriangleA)
        N.copy(tempVector1).cross(tempVector2)
        if tempVector3.dot(N) < 0
            false
        else
            tempVector1.subVectors(vertex3TriangleA, vertex1TriangleA)
            N.copy(tempVector1).cross(tempVector2)
            if tempVector3.dot(N) < 0
                tempVector1.subVectors(vertex1TriangleB, vertex1TriangleA)
                tempVector2.subVectors(vertex1TriangleB, vertex2TriangleB)
                alpha = tempVector1.dot(additions.N1) / tempVector2.dot(additions.N1)
                tempVector1.copy(tempVector2).multiplyScalar(alpha)
                additions.source.subVectors(vertex1TriangleB, tempVector1)
                tempVector1.subVectors(vertex1TriangleB, vertex1TriangleA)
                tempVector2.subVectors(vertex1TriangleB, vertex3TriangleB)
                alpha = tempVector1.dot(additions.N1) / tempVector2.dot(additions.N1)
                tempVector1.copy(tempVector2).multiplyScalar(alpha)
                additions.target.subVectors(vertex1TriangleB, tempVector1)
                true
            else
                tempVector1.subVectors(vertex1TriangleA, vertex1TriangleB)
                tempVector2.subVectors(vertex1TriangleA, vertex3TriangleA)
                alpha = tempVector1.dot(additions.N2) / tempVector2.dot(additions.N2)
                tempVector1.copy(tempVector2).multiplyScalar(alpha)
                additions.source.subVectors(vertex1TriangleA, tempVector1)
                tempVector1.subVectors(vertex1TriangleA, vertex1TriangleB)
                tempVector2.subVectors(vertex1TriangleA, vertex2TriangleA)
                alpha = tempVector1.dot(additions.N2) / tempVector2.dot(additions.N2)
                tempVector1.copy(tempVector2).multiplyScalar(alpha)
                additions.target.subVectors(vertex1TriangleA, tempVector1)
                true

pointOnLine = (line, point) ->

    ab = tempVector1.copy(line.end).sub(line.start)
    ac = tempVector2.copy(point).sub(line.start)
    area = tempVector3.copy(ab).cross(ac).length()
    CD = area / ab.length()
    return CD

lineIntersects = (line1, line2, points) ->

    r = (new Vector3()).copy(line1.end).sub(line1.start)
    s = (new Vector3()).copy(line2.end).sub(line2.start)
    q = (new Vector3()).copy(line1.start).sub(line2.start)
    # w = tempVector3.copy(line2.start).sub(line1.start)

    dotqr = q.dot(r)
    dotqs = q.dot(s)
    dotrs = r.dot(s)
    dotrr = r.dot(r)
    dotss = s.dot(s)

    denom = (dotrr * dotss) - (dotrs * dotrs)
    numer = (dotqs * dotrs) - (dotqr * dotss)

    t = numer / denom
    u = (dotqs + t * dotrs) / dotss

    p0 = r.multiplyScalar(t).add(line1.start)
    vertex1TriangleA = s.multiplyScalar(u).add(line2.start)

    onSegment = false
    intersects = false

    if (0 <= t <= 1) and (0 <= u <= 1)

        onSegment = true

    p0p1Length = tempVector1.copy(p0).sub(vertex1TriangleA).length()

    if p0p1Length <= 1e-5

        intersects = true

    # console.log("lineIntersects?", intersects, onSegment, p0, vertex1TriangleA, denom, numer, t, u)
    unless intersects and onSegment
        # return []
        return false

    points and points.push(p0, vertex1TriangleA)
    # return [p0, vertex1TriangleA]
    true

getLines = (triangle) ->

    [
        { start: triangle.a, end: triangle.b }
        { start: triangle.b, end: triangle.c }
        { start: triangle.c, end: triangle.a }
    ]

checkTrianglesIntersection = (triangle1, triangle2, additions = { coplanar: false, source: new Vector3(), target: new Vector3() }) ->
    # additions =
    #     coplanar: false
    #     source: new Vector3()
    #     target: new Vector3()
    triangleIntersects = triangleIntersectsTriangle(triangle1, triangle2, additions)
    # console.log("??? 1", triangleIntersects, additions)
    additions.triangleCheck = triangleIntersects

    if not triangleIntersects and additions.coplanar
        # console.log("check failed, checking lines")
        triangle1Lines = getLines(triangle1)
        triangle2Lines = getLines(triangle2)
        intersects = false

        for i in [0...3]
            intersects = false
            for j in [0...3]
                intersects = lineIntersects(triangle1Lines[i], triangle2Lines[j])
                break if intersects
            break if intersects

        return intersects

    triangleIntersects

export { triangleIntersectsTriangle, checkTrianglesIntersection, getLines, lineIntersects }
