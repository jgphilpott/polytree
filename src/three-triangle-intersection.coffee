import { Vector2, Vector3 } from "three"

_v1 = new Vector3()
_v2 = new Vector3()
_v3 = new Vector3()

# https://github.com/benardp/contours/blob/master/freestyle/view_map/triangle_triangle_intersection.c
triangleIntersectsTriangle = (triangleA, triangleB, additions = { coplanar: false, source: new Vector3(), target: new Vector3() }) ->
    p1 = triangleA.a
    q1 = triangleA.b
    r1 = triangleA.c

    p2 = triangleB.a
    q2 = triangleB.b
    r2 = triangleB.c

    # Compute distance signs  of p1, q1 and r1
    # to the plane of triangleB (p2,q2,r2)

    # _v1.copy(triangleB.a).sub(triangleB.c);
    # _v2.copy(triangleB.b).sub(triangleB.c);
    _v1.copy(p2).sub(r2)
    _v2.copy(q2).sub(r2)
    N2 = (new Vector3()).copy(_v1).cross(_v2)

    _v1.copy(p1).sub(r2)
    dp1 = _v1.dot(N2)
    _v1.copy(q1).sub(r2)
    dq1 = _v1.dot(N2)
    _v1.copy(r1).sub(r2)
    dr1 = _v1.dot(N2)

    if ((dp1 * dq1) > 0) and ((dp1 * dr1) > 0)
        # console.log("test 1 out");
        return false

    # Compute distance signs  of p2, q2 and r2
    # to the plane of triangleA (p1,q1,r1)
    _v1.copy(q1).sub(p1)
    _v2.copy(r1).sub(p1)
    N1 = (new Vector3()).copy(_v1).cross(_v2)

    _v1.copy(p2).sub(r1)
    dp2 = _v1.dot(N1)
    _v1.copy(q2).sub(r1)
    dq2 = _v1.dot(N1)
    _v1.copy(r2).sub(r1)
    dr2 = _v1.dot(N1)

    if ((dp2 * dq2) > 0) & ((dp2 * dr2) > 0)
        # console.log("test 2 out");
        return false

    # test
    # if (zero_test(dp1) || zero_test(dq1) || zero_test(dr1) || zero_test(dp2) || zero_test(dq2) || zero_test(dr2)) {
    #     additions.coplanar = 1;
    #     return false;
    # }

    additions.N2 = N2
    additions.N1 = N1

    if dp1 > 0
        if dq1 > 0
            tri_tri_intersection(r1, p1, q1, p2, r2, q2, dp2, dr2, dq2, additions)
        else if dr1 > 0
            tri_tri_intersection(q1, r1, p1, p2, r2, q2, dp2, dr2, dq2, additions)
        else
            tri_tri_intersection(p1, q1, r1, p2, q2, r2, dp2, dq2, dr2, additions)
    else if dp1 < 0
        if dq1 < 0
            tri_tri_intersection(r1, p1, q1, p2, q2, r2, dp2, dq2, dr2, additions)
        else if dr1 < 0
            tri_tri_intersection(q1, r1, p1, p2, q2, r2, dp2, dq2, dr2, additions)
        else
            tri_tri_intersection(p1, q1, r1, p2, r2, q2, dp2, dr2, dq2, additions)
    else
        if dq1 < 0
            if dr1 >= 0
                tri_tri_intersection(q1, r1, p1, p2, r2, q2, dp2, dr2, dq2, additions)
            else
                tri_tri_intersection(p1, q1, r1, p2, q2, r2, dp2, dq2, dr2, additions)
        else if dq1 > 0
            if dr1 > 0
                tri_tri_intersection(p1, q1, r1, p2, r2, q2, dp2, dr2, dq2, additions)
            else
                tri_tri_intersection(q1, r1, p1, p2, q2, r2, dp2, dq2, dr2, additions)
        else
            if dr1 > 0
                tri_tri_intersection(r1, p1, q1, p2, q2, r2, dp2, dq2, dr2, additions)
            else if dr1 < 0
                tri_tri_intersection(r1, p1, q1, p2, r2, q2, dp2, dr2, dq2, additions)
            else
                # triangles are co-planar
                additions.coplanar = true
                coplanar_tri_tri3d(p1, q1, r1, p2, q2, r2, N1, N2)

zero_test = (x) -> x == 0

tri_tri_intersection = (p1, q1, r1, p2, q2, r2, dp2, dq2, dr2, additions) ->
    if dp2 > 0
        if dq2 > 0
            construct_intersection(p1, r1, q1, r2, p2, q2, additions)
        else if dr2 > 0
            construct_intersection(p1, r1, q1, q2, r2, p2, additions)
        else
            construct_intersection(p1, q1, r1, p2, q2, r2, additions)
    else if dp2 < 0
        if dq2 < 0
            construct_intersection(p1, q1, r1, r2, p2, q2, additions)
        else if dr2 < 0
            construct_intersection(p1, q1, r1, q2, r2, p2, additions)
        else
            construct_intersection(p1, r1, q1, p2, q2, r2, additions)
    else
        if dq2 < 0
            if dr2 >= 0
                construct_intersection(p1, r1, q1, q2, r2, p2, additions)
            else
                construct_intersection(p1, q1, r1, p2, q2, r2, additions)
        else if dq2 > 0
            if dr2 > 0
                construct_intersection(p1, r1, q1, p2, q2, r2, additions)
            else
                construct_intersection(p1, q1, r1, q2, r2, p2, additions)
        else
            if dr2 > 0
                construct_intersection(p1, q1, r1, r2, p2, q2, additions)
            else if dr2 < 0
                construct_intersection(p1, r1, q1, r2, p2, q2, additions)
            else
                additions.coplanar = true
                # return coplanar_tri_tri3d(p1, q1, r1, p2, q2, r2, additions);
                coplanar_tri_tri3d(p1, q1, r1, p2, q2, r2, additions.N1, additions.N2)

coplanar_tri_tri3d = (p1, q1, r1, p2, q2, r2, normal_1, normal_2) ->
    P1 = new Vector2(); Q1 = new Vector2(); R1 = new Vector2()
    P2 = new Vector2(); Q2 = new Vector2(); R2 = new Vector2()
    n_x = if normal_1.x < 0 then -normal_1.x else normal_1.x
    n_y = if normal_1.y < 0 then -normal_1.y else normal_1.y
    n_z = if normal_1.z < 0 then -normal_1.z else normal_1.z

    ### Projection of the triangles in 3D onto 2D such that the area of
    the projection is maximized. ###

    if (n_x > n_z) and (n_x >= n_y) # Project onto plane YZ
        P1.x = q1.z; P1.y = q1.y
        Q1.x = p1.z; Q1.y = p1.y
        R1.x = r1.z; R1.y = r1.y

        P2.x = q2.z; P2.y = q2.y
        Q2.x = p2.z; Q2.y = p2.y
        R2.x = r2.z; R2.y = r2.y
    else if (n_y > n_z) and (n_y >= n_x) # Project onto plane XZ
        P1.x = q1.x; P1.y = q1.z
        Q1.x = p1.x; Q1.y = p1.z
        R1.x = r1.x; R1.y = r1.z

        P2.x = q2.x; P2.y = q2.z
        Q2.x = p2.x; Q2.y = p2.z
        R2.x = r2.x; R2.y = r2.z
    else # Project onto plane XY
        P1.x = p1.x; P1.y = p1.y
        Q1.x = q1.x; Q1.y = q1.y
        R1.x = r1.x; R1.y = r1.y

        P2.x = p2.x; P2.y = p2.y
        Q2.x = q2.x; Q2.y = q2.y
        R2.x = r2.x; R2.y = r2.y

    tri_tri_overlap_test_2d(P1, Q1, R1, P2, Q2, R2)

tri_tri_overlap_test_2d = (p1, q1, r1, p2, q2, r2) ->
    if ORIENT_2D(p1, q1, r1) < 0
        if ORIENT_2D(p2, q2, r2) < 0
            ccw_tri_tri_intersection_2d(p1, r1, q1, p2, r2, q2)
        else
            ccw_tri_tri_intersection_2d(p1, r1, q1, p2, q2, r2)
    else
        if ORIENT_2D(p2, q2, r2) < 0
            ccw_tri_tri_intersection_2d(p1, q1, r1, p2, r2, q2)
        else
            ccw_tri_tri_intersection_2d(p1, q1, r1, p2, q2, r2)

ORIENT_2D = (a, b, c) ->
    (a.x - c.x) * (b.y - c.y) - (a.y - c.y) * (b.x - c.y)

ccw_tri_tri_intersection_2d = (p1, q1, r1, p2, q2, r2) ->
    if ORIENT_2D(p2, q2, p1) >= 0
        if ORIENT_2D(q2, r2, p1) >= 0
            if ORIENT_2D(r2, p2, p1) >= 0
                true
            else
                intersection_test_edge(p1, q1, r1, p2, q2, r2)
        else
            if ORIENT_2D(r2, p2, p1) >= 0
                intersection_test_edge(p1, q1, r1, r2, p2, q2)
            else
                intersection_test_vertex(p1, q1, r1, p2, q2, r2)
    else
        if ORIENT_2D(q2, r2, p1) >= 0
            if ORIENT_2D(r2, p2, p1) >= 0
                intersection_test_edge(p1, q1, r2, q2, r2, p2)
            else
                intersection_test_vertex(p1, q1, r1, q2, r2, p2)
        else
            intersection_test_vertex(p1, q1, r1, r2, p2, q2)

intersection_test_edge = (P1, Q1, R1, P2, Q2, R2) ->
    if ORIENT_2D(R2, P2, Q1) >= 0
        if ORIENT_2D(P1, P2, Q1) >= 0
            if ORIENT_2D(P1, Q1, R2) >= 0
                true
            else
                false
        else
            if ORIENT_2D(Q1, R1, P2) >= 0
                if ORIENT_2D(R1, P1, P2) >= 0
                    true
                else
                    false
            else
                false
    else
        if ORIENT_2D(R2, P2, R1) >= 0
            if ORIENT_2D(P1, P2, R1) >= 0
                if ORIENT_2D(P1, R1, R2) >= 0
                    true
                else
                    if ORIENT_2D(Q1, R1, R2) >= 0
                        true
                    else
                        false
            else
                false
        else
            false

intersection_test_vertex = (P1, Q1, R1, P2, Q2, R2) ->
    if ORIENT_2D(R2, P2, Q1) >= 0
        if ORIENT_2D(R2, Q2, Q1) <= 0
            if ORIENT_2D(P1, P2, Q1) > 0
                if ORIENT_2D(P1, Q2, Q1) <= 0
                    true
                else
                    false
            else
                if ORIENT_2D(P1, P2, R1) >= 0
                    if ORIENT_2D(Q1, R1, P2) >= 0
                        true
                    else
                        false
                else
                    false
        else
            if ORIENT_2D(P1, Q2, Q1) <= 0
                if ORIENT_2D(R2, Q2, R1) <= 0
                    if ORIENT_2D(Q1, R1, Q2) >= 0
                        true
                    else
                        false
                else
                    false
            else
                false
    else
        if ORIENT_2D(R2, P2, R1) >= 0
            if ORIENT_2D(Q1, R1, R2) >= 0
                if ORIENT_2D(P1, P2, R1) >= 0
                    true
                else
                    false
            else
                if ORIENT_2D(Q1, R1, Q2) >= 0
                    if ORIENT_2D(R2, R1, Q2) >= 0
                        true
                    else
                        false
                else
                    false
        else
            false

construct_intersection = (p1, q1, r1, p2, q2, r2, additions) ->
    alpha = undefined
    N = new Vector3()
    _v1.subVectors(q1, p1)
    _v2.subVectors(r2, p1)
    N.copy(_v1).cross(_v2)
    _v3.subVectors(p2, p1)
    if _v3.dot(N) > 0
        _v1.subVectors(r1, p1)
        N.copy(_v1).cross(_v2)
        if _v3.dot(N) <= 0
            _v2.subVectors(q2, p1)
            N.copy(_v1).cross(_v2)
            if _v3.dot(N) > 0
                _v1.subVectors(p1, p2)
                _v2.subVectors(p1, r1)
                alpha = _v1.dot(additions.N2) / _v2.dot(additions.N2)
                _v1.copy(_v2).multiplyScalar(alpha)
                additions.source.subVectors(p1, _v1)
                _v1.subVectors(p2, p1)
                _v2.subVectors(p2, r2)
                alpha = _v1.dot(additions.N1) / _v2.dot(additions.N1)
                _v1.copy(_v2).multiplyScalar(alpha)
                additions.target.subVectors(p2, _v1)
                true
            else
                _v1.subVectors(p2, p1)
                _v2.subVectors(p2, q2)
                alpha = _v1.dot(additions.N1) / _v2.dot(additions.N1)
                _v1.copy(_v2).multiplyScalar(alpha)
                additions.source.subVectors(p2, _v1)
                _v1.subVectors(p2, p1)
                _v2.subVectors(p2, r2)
                alpha = _v1.dot(additions.N1) / _v2.dot(additions.N1)
                _v1.copy(_v2).multiplyScalar(alpha)
                additions.target.subVectors(p2, _v1)
                true
        else
            false
    else
        _v2.subVectors(q2, p1)
        N.copy(_v1).cross(_v2)
        if _v3.dot(N) < 0
            false
        else
            _v1.subVectors(r1, p1)
            N.copy(_v1).cross(_v2)
            if _v3.dot(N) < 0
                _v1.subVectors(p2, p1)
                _v2.subVectors(p2, q2)
                alpha = _v1.dot(additions.N1) / _v2.dot(additions.N1)
                _v1.copy(_v2).multiplyScalar(alpha)
                additions.source.subVectors(p2, _v1)
                _v1.subVectors(p2, p1)
                _v2.subVectors(p2, r2)
                alpha = _v1.dot(additions.N1) / _v2.dot(additions.N1)
                _v1.copy(_v2).multiplyScalar(alpha)
                additions.target.subVectors(p2, _v1)
                true
            else
                _v1.subVectors(p1, p2)
                _v2.subVectors(p1, r1)
                alpha = _v1.dot(additions.N2) / _v2.dot(additions.N2)
                _v1.copy(_v2).multiplyScalar(alpha)
                additions.source.subVectors(p1, _v1)
                _v1.subVectors(p1, p2)
                _v2.subVectors(p1, q1)
                alpha = _v1.dot(additions.N2) / _v2.dot(additions.N2)
                _v1.copy(_v2).multiplyScalar(alpha)
                additions.target.subVectors(p1, _v1)
                true

pointOnLine = (line, point) ->
    ab = _v1.copy(line.end).sub(line.start)
    ac = _v2.copy(point).sub(line.start)
    area = _v3.copy(ab).cross(ac).length()
    CD = area / ab.length()
    CD

lineIntersects = (line1, line2, points) ->
    r = (new Vector3()).copy(line1.end).sub(line1.start)
    s = (new Vector3()).copy(line2.end).sub(line2.start)
    q = (new Vector3()).copy(line1.start).sub(line2.start)
    # w = _v3.copy(line2.start).sub(line1.start)

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
    p1 = s.multiplyScalar(u).add(line2.start)

    onSegment = false
    intersects = false

    if (0 <= t <= 1) and (0 <= u <= 1)
        onSegment = true

    p0p1Length = _v1.copy(p0).sub(p1).length()
    if p0p1Length <= 1e-5
        intersects = true

    # console.log("lineIntersects?", intersects, onSegment, p0, p1, denom, numer, t, u)
    unless intersects and onSegment
        # return []
        return false

    points and points.push(p0, p1)
    # return [p0, p1]
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
