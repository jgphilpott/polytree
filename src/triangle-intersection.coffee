import { Vector2, Vector3 } from "three"

tempVector1 = new Vector3()
tempVector2 = new Vector3()
tempVector3 = new Vector3()

### Checks whether two triangles in 3D space intersect.

@param {Object} triangleA - First triangle, with properties {a, b, c} (Vector3 vertices).
@param {Object} triangleB - Second triangle, with properties {a, b, c} (Vector3 vertices).
@param {Object} [additions] - Optional object used for storing extra intersection info:
    - coplanar {Boolean} whether the triangles lie in the same plane
    - source {Vector3} intersection segment start (if applicable)
    - target {Vector3} intersection segment end (if applicable)

@returns {Boolean} true if the triangles intersect, false otherwise. ###
triangleIntersectsTriangle = (triangleA, triangleB, additions = { coplanar: false, source: new Vector3(), target: new Vector3() }) ->

    # Extract vertices of triangle A
    vertex1TriangleA = triangleA.a
    vertex2TriangleA = triangleA.b
    vertex3TriangleA = triangleA.c

    # Extract vertices of triangle B
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

        return false # All vertices of Triangle A are on the same side of Triangle B’s plane

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

        return false # All vertices of Triangle B are on the same side of Triangle A’s plane

    # Step 3: At this point, neither triangle is fully on one side of the other’s plane. This means the triangles potentially intersect.
    # Next, we use the vertex signed distances to decide which configuration applies and call `tri_tri_intersection` (or `coplanar_tri_tri3d` if the triangles are coplanar).

    additions.N1 = N1
    additions.N2 = N2

    if distanceVertex1A > 0

        if distanceVertex2A > 0
            tri_tri_intersection(vertex3TriangleA, vertex1TriangleA, vertex2TriangleA, vertex1TriangleB, vertex3TriangleB, vertex2TriangleB, distanceVertex1B, distanceVertex3B, distanceVertex2B, additions)
        else if distanceVertex3A > 0
            tri_tri_intersection(vertex2TriangleA, vertex3TriangleA, vertex1TriangleA, vertex1TriangleB, vertex3TriangleB, vertex2TriangleB, distanceVertex1B, distanceVertex3B, distanceVertex2B, additions)
        else
            tri_tri_intersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, distanceVertex1B, distanceVertex2B, distanceVertex3B, additions)

    else if distanceVertex1A < 0

        if distanceVertex2A < 0
            tri_tri_intersection(vertex3TriangleA, vertex1TriangleA, vertex2TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, distanceVertex1B, distanceVertex2B, distanceVertex3B, additions)
        else if distanceVertex3A < 0
            tri_tri_intersection(vertex2TriangleA, vertex3TriangleA, vertex1TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, distanceVertex1B, distanceVertex2B, distanceVertex3B, additions)
        else
            tri_tri_intersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex3TriangleB, vertex2TriangleB, distanceVertex1B, distanceVertex3B, distanceVertex2B, additions)

    else

        if distanceVertex2A < 0

            if distanceVertex3A >= 0
                tri_tri_intersection(vertex2TriangleA, vertex3TriangleA, vertex1TriangleA, vertex1TriangleB, vertex3TriangleB, vertex2TriangleB, distanceVertex1B, distanceVertex3B, distanceVertex2B, additions)
            else
                tri_tri_intersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, distanceVertex1B, distanceVertex2B, distanceVertex3B, additions)

        else if distanceVertex2A > 0

            if distanceVertex3A > 0
                tri_tri_intersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex3TriangleB, vertex2TriangleB, distanceVertex1B, distanceVertex3B, distanceVertex2B, additions)
            else
                tri_tri_intersection(vertex2TriangleA, vertex3TriangleA, vertex1TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, distanceVertex1B, distanceVertex2B, distanceVertex3B, additions)

        else

            if distanceVertex3A > 0
                tri_tri_intersection(vertex3TriangleA, vertex1TriangleA, vertex2TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, distanceVertex1B, distanceVertex2B, distanceVertex3B, additions)
            else if distanceVertex3A < 0
                tri_tri_intersection(vertex3TriangleA, vertex1TriangleA, vertex2TriangleA, vertex1TriangleB, vertex3TriangleB, vertex2TriangleB, distanceVertex1B, distanceVertex3B, distanceVertex2B, additions)
            else
                additions.coplanar = true # The triangles are co-planar
                coplanar_tri_tri3d(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, N1, N2)

tri_tri_intersection = (vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, distanceVertex1B, distanceVertex2B, distanceVertex3B, additions) ->

    if distanceVertex1B > 0

        if distanceVertex2B > 0
            construct_intersection(vertex1TriangleA, vertex3TriangleA, vertex2TriangleA, vertex3TriangleB, vertex1TriangleB, vertex2TriangleB, additions)
        else if distanceVertex3B > 0
            construct_intersection(vertex1TriangleA, vertex3TriangleA, vertex2TriangleA, vertex2TriangleB, vertex3TriangleB, vertex1TriangleB, additions)
        else
            construct_intersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, additions)

    else if distanceVertex1B < 0

        if distanceVertex2B < 0
            construct_intersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex3TriangleB, vertex1TriangleB, vertex2TriangleB, additions)
        else if distanceVertex3B < 0
            construct_intersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex2TriangleB, vertex3TriangleB, vertex1TriangleB, additions)
        else
            construct_intersection(vertex1TriangleA, vertex3TriangleA, vertex2TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, additions)

    else

        if distanceVertex2B < 0

            if distanceVertex3B >= 0
                construct_intersection(vertex1TriangleA, vertex3TriangleA, vertex2TriangleA, vertex2TriangleB, vertex3TriangleB, vertex1TriangleB, additions)
            else
                construct_intersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, additions)

        else if distanceVertex2B > 0

            if distanceVertex3B > 0
                construct_intersection(vertex1TriangleA, vertex3TriangleA, vertex2TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, additions)
            else
                construct_intersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex2TriangleB, vertex3TriangleB, vertex1TriangleB, additions)

        else

            if distanceVertex3B > 0
                construct_intersection(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex3TriangleB, vertex1TriangleB, vertex2TriangleB, additions)
            else if distanceVertex3B < 0
                construct_intersection(vertex1TriangleA, vertex3TriangleA, vertex2TriangleA, vertex3TriangleB, vertex1TriangleB, vertex2TriangleB, additions)
            else
                additions.coplanar = true
                # return coplanar_tri_tri3d(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, additions);
                coplanar_tri_tri3d(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, additions.N1, additions.N2)

coplanar_tri_tri3d = (vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, normal_1, normal_2) ->

    vertex1TriangleA = new Vector2(); vertex2TriangleA = new Vector2(); vertex3TriangleA = new Vector2()
    vertex1TriangleB = new Vector2(); vertex2TriangleB = new Vector2(); vertex3TriangleB = new Vector2()

    n_x = if normal_1.x < 0 then -normal_1.x else normal_1.x
    n_y = if normal_1.y < 0 then -normal_1.y else normal_1.y
    n_z = if normal_1.z < 0 then -normal_1.z else normal_1.z

    ### Projection of the triangles in 3D onto 2D such that the area of
    the projection is maximized. ###

    if (n_x > n_z) and (n_x >= n_y) # Project onto plane YZ

        vertex1TriangleA.x = vertex2TriangleA.z; vertex1TriangleA.y = vertex2TriangleA.y
        vertex2TriangleA.x = vertex1TriangleA.z; vertex2TriangleA.y = vertex1TriangleA.y
        vertex3TriangleA.x = vertex3TriangleA.z; vertex3TriangleA.y = vertex3TriangleA.y

        vertex1TriangleB.x = vertex2TriangleB.z; vertex1TriangleB.y = vertex2TriangleB.y
        vertex2TriangleB.x = vertex1TriangleB.z; vertex2TriangleB.y = vertex1TriangleB.y
        vertex3TriangleB.x = vertex3TriangleB.z; vertex3TriangleB.y = vertex3TriangleB.y

    else if (n_y > n_z) and (n_y >= n_x) # Project onto plane XZ

        vertex1TriangleA.x = vertex2TriangleA.x; vertex1TriangleA.y = vertex2TriangleA.z
        vertex2TriangleA.x = vertex1TriangleA.x; vertex2TriangleA.y = vertex1TriangleA.z
        vertex3TriangleA.x = vertex3TriangleA.x; vertex3TriangleA.y = vertex3TriangleA.z

        vertex1TriangleB.x = vertex2TriangleB.x; vertex1TriangleB.y = vertex2TriangleB.z
        vertex2TriangleB.x = vertex1TriangleB.x; vertex2TriangleB.y = vertex1TriangleB.z
        vertex3TriangleB.x = vertex3TriangleB.x; vertex3TriangleB.y = vertex3TriangleB.z

    else # Project onto plane XY

        vertex1TriangleA.x = vertex1TriangleA.x; vertex1TriangleA.y = vertex1TriangleA.y
        vertex2TriangleA.x = vertex2TriangleA.x; vertex2TriangleA.y = vertex2TriangleA.y
        vertex3TriangleA.x = vertex3TriangleA.x; vertex3TriangleA.y = vertex3TriangleA.y

        vertex1TriangleB.x = vertex1TriangleB.x; vertex1TriangleB.y = vertex1TriangleB.y
        vertex2TriangleB.x = vertex2TriangleB.x; vertex2TriangleB.y = vertex2TriangleB.y
        vertex3TriangleB.x = vertex3TriangleB.x; vertex3TriangleB.y = vertex3TriangleB.y

    tri_tri_overlap_test_2d(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB)

tri_tri_overlap_test_2d = (vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB) ->
    if ORIENT_2D(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA) < 0
        if ORIENT_2D(vertex1TriangleB, vertex2TriangleB, vertex3TriangleB) < 0
            ccw_tri_tri_intersection_2d(vertex1TriangleA, vertex3TriangleA, vertex2TriangleA, vertex1TriangleB, vertex3TriangleB, vertex2TriangleB)
        else
            ccw_tri_tri_intersection_2d(vertex1TriangleA, vertex3TriangleA, vertex2TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB)
    else
        if ORIENT_2D(vertex1TriangleB, vertex2TriangleB, vertex3TriangleB) < 0
            ccw_tri_tri_intersection_2d(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex3TriangleB, vertex2TriangleB)
        else
            ccw_tri_tri_intersection_2d(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB)

ORIENT_2D = (a, b, c) ->
    (a.x - c.x) * (b.y - c.y) - (a.y - c.y) * (b.x - c.y)

ccw_tri_tri_intersection_2d = (vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB) ->
    if ORIENT_2D(vertex1TriangleB, vertex2TriangleB, vertex1TriangleA) >= 0
        if ORIENT_2D(vertex2TriangleB, vertex3TriangleB, vertex1TriangleA) >= 0
            if ORIENT_2D(vertex3TriangleB, vertex1TriangleB, vertex1TriangleA) >= 0
                true
            else
                intersection_test_edge(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB)
        else
            if ORIENT_2D(vertex3TriangleB, vertex1TriangleB, vertex1TriangleA) >= 0
                intersection_test_edge(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex3TriangleB, vertex1TriangleB, vertex2TriangleB)
            else
                intersection_test_vertex(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB)
    else
        if ORIENT_2D(vertex2TriangleB, vertex3TriangleB, vertex1TriangleA) >= 0
            if ORIENT_2D(vertex3TriangleB, vertex1TriangleB, vertex1TriangleA) >= 0
                intersection_test_edge(vertex1TriangleA, vertex2TriangleA, vertex3TriangleB, vertex2TriangleB, vertex3TriangleB, vertex1TriangleB)
            else
                intersection_test_vertex(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex2TriangleB, vertex3TriangleB, vertex1TriangleB)
        else
            intersection_test_vertex(vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex3TriangleB, vertex1TriangleB, vertex2TriangleB)

intersection_test_edge = (vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB) ->
    if ORIENT_2D(vertex3TriangleB, vertex1TriangleB, vertex2TriangleA) >= 0
        if ORIENT_2D(vertex1TriangleA, vertex1TriangleB, vertex2TriangleA) >= 0
            if ORIENT_2D(vertex1TriangleA, vertex2TriangleA, vertex3TriangleB) >= 0
                true
            else
                false
        else
            if ORIENT_2D(vertex2TriangleA, vertex3TriangleA, vertex1TriangleB) >= 0
                if ORIENT_2D(vertex3TriangleA, vertex1TriangleA, vertex1TriangleB) >= 0
                    true
                else
                    false
            else
                false
    else
        if ORIENT_2D(vertex3TriangleB, vertex1TriangleB, vertex3TriangleA) >= 0
            if ORIENT_2D(vertex1TriangleA, vertex1TriangleB, vertex3TriangleA) >= 0
                if ORIENT_2D(vertex1TriangleA, vertex3TriangleA, vertex3TriangleB) >= 0
                    true
                else
                    if ORIENT_2D(vertex2TriangleA, vertex3TriangleA, vertex3TriangleB) >= 0
                        true
                    else
                        false
            else
                false
        else
            false

intersection_test_vertex = (vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB) ->
    if ORIENT_2D(vertex3TriangleB, vertex1TriangleB, vertex2TriangleA) >= 0
        if ORIENT_2D(vertex3TriangleB, vertex2TriangleB, vertex2TriangleA) <= 0
            if ORIENT_2D(vertex1TriangleA, vertex1TriangleB, vertex2TriangleA) > 0
                if ORIENT_2D(vertex1TriangleA, vertex2TriangleB, vertex2TriangleA) <= 0
                    true
                else
                    false
            else
                if ORIENT_2D(vertex1TriangleA, vertex1TriangleB, vertex3TriangleA) >= 0
                    if ORIENT_2D(vertex2TriangleA, vertex3TriangleA, vertex1TriangleB) >= 0
                        true
                    else
                        false
                else
                    false
        else
            if ORIENT_2D(vertex1TriangleA, vertex2TriangleB, vertex2TriangleA) <= 0
                if ORIENT_2D(vertex3TriangleB, vertex2TriangleB, vertex3TriangleA) <= 0
                    if ORIENT_2D(vertex2TriangleA, vertex3TriangleA, vertex2TriangleB) >= 0
                        true
                    else
                        false
                else
                    false
            else
                false
    else
        if ORIENT_2D(vertex3TriangleB, vertex1TriangleB, vertex3TriangleA) >= 0
            if ORIENT_2D(vertex2TriangleA, vertex3TriangleA, vertex3TriangleB) >= 0
                if ORIENT_2D(vertex1TriangleA, vertex1TriangleB, vertex3TriangleA) >= 0
                    true
                else
                    false
            else
                if ORIENT_2D(vertex2TriangleA, vertex3TriangleA, vertex2TriangleB) >= 0
                    if ORIENT_2D(vertex3TriangleB, vertex3TriangleA, vertex2TriangleB) >= 0
                        true
                    else
                        false
                else
                    false
        else
            false

construct_intersection = (vertex1TriangleA, vertex2TriangleA, vertex3TriangleA, vertex1TriangleB, vertex2TriangleB, vertex3TriangleB, additions) ->
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
