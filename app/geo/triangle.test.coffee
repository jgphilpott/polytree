{ Vector2, Vector3 } = require "three"

{

    isValidTriangle
    isUniqueTriangle
    triangleIntersectsTriangle
    resolveTriangleIntersection
    resolveCoplanarTriangleIntersection
    trianglesOverlap2D
    triangleOrientation2D
    triangleIntersectionCCW2D
    intersectionTestEdge2D
    intersectionTestVertex2D
    constructIntersection

} = require "../../polytree.bundle.js"

# Helper functions to keep tests DRY.

v2 = (x, y) -> new Vector2(x, y)
v3 = (x, y, z) -> new Vector3(x, y, z)
n = (x, y, z) -> new Vector3(x, y, z).normalize()

sign = (x, eps = 1e-12) ->

    if x > eps then 1 else if x < -eps then -1 else 0

tri = (aX, aY, aZ, bX, bY, bZ, cX, cY, cZ) ->

    a: new Vector3(aX, aY, aZ)
    b: new Vector3(bX, bY, bZ)
    c: new Vector3(cX, cY, cZ)

triCCW = (aX, aY, bX, bY, cX, cY) ->

    a: v2(aX, aY)
    b: v2(bX, bY)
    c: v2(cX, cY)

triCW = (aX, aY, bX, bY, cX, cY) ->

    a: v2(aX, aY)
    b: v2(cX, cY)
    c: v2(bX, bY)

ccw = (a, b, c) ->

    o = triangleOrientation2D(a, b, c)

    if o > 0 then [a, b, c] else if o < 0 then [a, c, b] else [a, b, c]

callCCW = (A, B) -> triangleIntersectionCCW2D(A[0], A[1], A[2], B[0], B[1], B[2])

assertBool = (label, expected, fn) ->

    result = fn()

    unless result is expected

        throw new Error "triangleIntersectionCCW2D #{label}: expected #{expected} got #{result}"

assertIntersection = (tA, tB, expected, { coplanar: expectedCoplanar = undefined, intersection: expectSegment = false, approx = 1e-6, label } = {}) ->

    additions =

        coplanar: false
        source: new Vector3()
        target: new Vector3()

    result = triangleIntersectsTriangle(tA, tB, additions)

    unless result is expected

        throw new Error "intersection result mismatch#{if label then " (#{label})" else ""}: expected #{expected} got #{result}"

    if expectedCoplanar isnt undefined

        unless additions.coplanar is expectedCoplanar

            throw new Error "coplanar flag mismatch#{if label then " (#{label})" else ""}: expected #{expectedCoplanar} got #{additions.coplanar}"

    if expectSegment

        dist = additions.source.distanceTo(additions.target)

        unless dist > approx

            throw new Error "expected non-zero segment#{if label then " (#{label})" else ""}, got length #{dist}"

describe "triangle validation helpers", ->

    describe "isValidTriangle", ->

        it "returns true for distinct non-collinear triangle", ->

            t = tri(0,0,0, 1,0,0, 0,1,0)
            expect(isValidTriangle(t)).toBe true

        it "returns true for distinct but collinear triangle (allowed)", ->

            t = tri(0,0,0, 1,0,0, 2,0,0)
            expect(isValidTriangle(t)).toBe true

        it "returns false when a==b", ->

            t = tri(0,0,0, 0,0,0, 0,1,0)
            expect(isValidTriangle(t)).toBe false

        it "returns false when a==c", ->

            t = tri(0,0,0, 1,0,0, 0,0,0)
            expect(isValidTriangle(t)).toBe false

        it "returns false when b==c", ->

            t = tri(0,0,0, 1,0,0, 1,0,0)
            expect(isValidTriangle(t)).toBe false

    describe "isUniqueTriangle", ->

        it "returns true then false for duplicate directional hash", ->

            set = new Set()

            t = tri(0,0,0, 1,0,0, 0,1,0)

            expect(isUniqueTriangle(t, set)).toBe true
            expect(isUniqueTriangle(t, set)).toBe false

        it "treats different vertex order as distinct (directional)", ->

            set = new Set()

            t1 = tri(0,0,0, 1,0,0, 0,1,0)
            t2 = tri(1,0,0, 0,1,0, 0,0,0) # same geometric triangle different order

            expect(isUniqueTriangle(t1, set)).toBe true
            expect(isUniqueTriangle(t2, set)).toBe true # directional hash => distinct

        it "stores entry in optional map when provided", ->

            set = new Set()
            map = new Map()

            t = tri(0,0,0, 1,0,0, 0,1,0)

            expect(isUniqueTriangle(t, set, map)).toBe true
            expect(map.get(t)).toBe t

describe "triangleIntersectsTriangle", ->

    it "separated triangles (parallel planes)", ->

        tA = tri(0,0,0, 1,0,0, 0,1,0)
        tB = tri(0,0,2, 1,0,2, 0,1,2)

        assertIntersection tA, tB, false,

            coplanar: false
            label: "separated parallel planes"

    it "separated triangles (skew planes)", ->

        tA = tri(0,0,0, 2,0,0, 0,2,0)
        tB = tri(3,3,1, 4,3,2, 3,4,1.5)

        assertIntersection tA, tB, false,

            coplanar: false
            label: "skew planes no overlap"

    it "segment intersection (non-coplanar)", ->

        tA = tri(0,0,0, 2,0,0, 1,1,0)
        tB = tri(1,-1,0, 1,2,0, 1,0,1)

        assertIntersection tA, tB, true,

            coplanar: false
            intersection: true
            label: "non-coplanar segment"

    it "shared edge (coplanar)", ->

        tA = tri(0,0,0, 1,0,0, 0,1,0)
        tB = tri(1,0,0, 0,0,0, 1,1,0)

        assertIntersection tA, tB, true,

            coplanar: true
            label: "coplanar shared edge"

    it "vertex pierce (B through A)", ->

        tA = tri(0,0,0, 2,0,0, 0,2,0)
        tB = tri(1,0.5,0, 1,0.5,1, 1,0.5,-1)

        assertIntersection tA, tB, true,

            coplanar: true
            intersection: false
            label: "vertex pierce (degenerate vertical line)"

    it "coplanar separated", ->

        tA = tri(0,0,0, 1,0,0, 0,1,0)
        tB = tri(2,2,0, 3,2,0, 2,3,0)

        assertIntersection tA, tB, false,

            coplanar: true
            label: "coplanar separated"

    it "coplanar partial overlap", ->

        tA = tri(0,0,0, 3,0,0, 0,3,0)
        tB = tri(1,0,0, 2,0,0, 1,2,0)

        assertIntersection tA, tB, true,

            coplanar: true
            label: "coplanar overlap"

    it "coplanar containment", ->

        tA = tri(0,0,0, 5,0,0, 0,5,0)
        tB = tri(1,1,0, 2,1,0, 1,2,0)

        assertIntersection tA, tB, true,

            coplanar: true
            label: "coplanar containment"

    it "near coplanar (epsilon offsets)", ->

        eps = 1e-8
        tA = tri(0,0,0, 2,0,0, 0,2,0)
        tB = tri(0.5,0.5,eps, 1.5,0.5,-eps, 0.5,1.5,eps)

        assertIntersection tA, tB, true,

            coplanar: false
            label: "near coplanar small epsilon"

    it "shared vertex only (treated as intersect)", ->

        tA = tri(0,0,0, 1,0,0, 0,1,0)
        tB = tri(0,0,0, -1,0,0, 0,-1,0)

        assertIntersection tA, tB, true,

            coplanar: true
            label: "shared vertex"

    it "degenerate A (no area) vs valid triangle", ->

        tA = tri(0,0,0, 0,0,0, 0,0,0)
        tB = tri(0,1,0, 1,0,0, 0,0,1)

        assertIntersection tA, tB, false,

            coplanar: false
            label: "degenerate A"

    it "degenerate point inside other (coplanar)", ->

        tA = tri(0.2,0.2,0, 0.2,0.2,0, 0.2,0.2,0)
        tB = tri(0,0,0, 2,0,0, 0,2,0)

        assertIntersection tA, tB, true,

            coplanar: true
            label: "degenerate point inside"

    it "skew oblique intersection", ->

        tA = tri(0,0,0, 2,0,0, 0,2,1)
        tB = tri(0,0,0.5, 1,1,0.5, 0,1,2)

        assertIntersection tA, tB, true,

            coplanar: false
            label: "skew oblique"

    it "skew disjoint", ->

        tA = tri(0,0,0, 2,0,0, 0,2,1)
        tB = tri(3,0,0.5, 4,1,0.5, 3,1,2)

        assertIntersection tA, tB, false,

            coplanar: false
            label: "skew disjoint"

    it "identical triangles (full overlap)", ->

        tA = tri(0,0,0, 2,0,0, 0,2,0)
        tB = tri(0,0,0, 2,0,0, 0,2,0)

        assertIntersection tA, tB, true,

            coplanar: true
            label: "identical full overlap"

describe "resolveCoplanarTriangleIntersection", ->

    it "returns false for separated coplanar triangles", ->

        result = resolveCoplanarTriangleIntersection(
            v3(0,0,0), v3(1,0,0), v3(0,1,0),
            v3(2,2,0), v3(3,2,0), v3(2,3,0),
            n(0,0,1), n(0,0,1)
        )

        expect(result).toBe false

    it "returns true for coplanar triangles sharing an edge", ->

        result = resolveCoplanarTriangleIntersection(
            v3(0,0,0), v3(1,0,0), v3(0,1,0),
            v3(1,0,0), v3(0,0,0), v3(1,1,0),
            n(0,0,1), n(0,0,1)
        )

        expect(result).toBe true

    it "returns true for coplanar triangles with partial overlap", ->

        result = resolveCoplanarTriangleIntersection(
            v3(0,0,0), v3(3,0,0), v3(0,3,0),
            v3(1,0,0), v3(2,0,0), v3(1,2,0),
            n(0,0,1), n(0,0,1)
        )

        expect(result).toBe true

    it "returns true for full containment (B inside A)", ->

        result = resolveCoplanarTriangleIntersection(
            v3(0,0,0), v3(5,0,0), v3(0,5,0),
            v3(1,1,0), v3(2,1,0), v3(1,2,0),
            n(0,0,1), n(0,0,1)
        )

        expect(result).toBe true

    it "returns true for identical triangles", ->

        result = resolveCoplanarTriangleIntersection(
            v3(0,0,0), v3(2,0,0), v3(0,2,0),
            v3(0,0,0), v3(2,0,0), v3(0,2,0),
            n(0,0,1), n(0,0,1)
        )

        expect(result).toBe true

    it "returns true for coplanar shared vertex only", ->

        result = resolveCoplanarTriangleIntersection(
            v3(0,0,0), v3(1,0,0), v3(0,1,0),
            v3(0,0,0), v3(-1,0,0), v3(0,-1,0),
            n(0,0,1), n(0,0,1)
        )

        expect(result).toBe true

describe "trianglesOverlap2D", ->

    it "returns false for clearly separated triangles", ->

        A = triCCW(0,0, 2,0, 0,2)
        B = triCCW(3,3, 4,3, 3,4)

        expect(trianglesOverlap2D(A.a, A.b, A.c, B.a, B.b, B.c)).toBe false

    it "returns true for simple overlapping area (both CCW)", ->

        A = triCCW(0,0, 3,0, 0,3)
        B = triCCW(1,0, 2,0, 1,2)

        expect(trianglesOverlap2D(A.a, A.b, A.c, B.a, B.b, B.c)).toBe true

    it "returns true when B is fully inside A (containment)", ->

        A = triCCW(0,0, 5,0, 0,5)
        B = triCCW(1,1, 2,1, 1,2)

        expect(trianglesOverlap2D(A.a, A.b, A.c, B.a, B.b, B.c)).toBe true

    it "returns true for shared edge", ->

        A = triCCW(0,0, 1,0, 0,1)
        B = triCCW(1,0, 0,0, 1,1)

        expect(trianglesOverlap2D(A.a, A.b, A.c, B.a, B.b, B.c)).toBe true

    it "returns true for shared vertex only", ->

        A = triCCW(0,0, 1,0, 0,1)
        B = triCCW(0,0, -1,0, 0,-1)

        expect(trianglesOverlap2D(A.a, A.b, A.c, B.a, B.b, B.c)).toBe true

    it "handles A CW, B CCW (reorders A to CCW)", ->

        A = triCW(0,0, 3,0, 0,3) # same shape as earlier, CW order
        B = triCCW(1,0, 2,0, 1,2)

        expect(trianglesOverlap2D(A.a, A.b, A.c, B.a, B.b, B.c)).toBe true

    it "handles A CCW, B CW (reorders B to CCW)", ->

        A = triCCW(0,0, 3,0, 0,3)
        B = triCW(1,0, 2,0, 1,2)

        expect(trianglesOverlap2D(A.a, A.b, A.c, B.a, B.b, B.c)).toBe true

    it "handles both CW (reorders both to CCW)", ->

        A = triCW(0,0, 3,0, 0,3)
        B = triCW(1,0, 2,0, 1,2)

        expect(trianglesOverlap2D(A.a, A.b, A.c, B.a, B.b, B.c)).toBe true

    it "returns false for separated triangles (CW/CCW mix)", ->

        A = triCW(0,0, 2,0, 0,2)
        B = triCCW(3,3, 4,3, 3,4)

        expect(trianglesOverlap2D(A.a, A.b, A.c, B.a, B.b, B.c)).toBe false

    it "returns true for degenerate line across interior", ->

        A = triCCW(0,0, 4,0, 0,4)
        B = triCCW(1,1, 3,1, 1,1) # B is a line: two distinct points + one repeated to form zero-area triangle.

        expect(trianglesOverlap2D(A.a, A.b, A.c, B.a, B.b, B.c)).toBe true

    it "returns true for degenerate point inside", ->

        A = triCCW(0,0, 2,0, 0,2)

        B = # B is a point: all three vertices equal.

            a: v2(0.5, 0.5)
            b: v2(0.5, 0.5)
            c: v2(0.5, 0.5)

        expect(trianglesOverlap2D(A.a, A.b, A.c, B.a, B.b, B.c)).toBe true

    it "returns false for degenerate point outside", ->

        A = triCCW(0,0, 2,0, 0,2)
        B =

            a: v2(3, 3)
            b: v2(3, 3)
            c: v2(3, 3)

        expect(trianglesOverlap2D(A.a, A.b, A.c, B.a, B.b, B.c)).toBe false

    it "returns true when both triangles degenerate to same point", ->

        P = v2(1,1)
        A = a: P, b: P, c: P
        B = a: P.clone(), b: P.clone(), c: P.clone()

        expect(trianglesOverlap2D(A.a, A.b, A.c, B.a, B.b, B.c)).toBe true

    it "returns false when both degenerate to different points", ->

        A = a: v2(1,1), b: v2(1,1), c: v2(1,1)
        B = a: v2(2,2), b: v2(2,2), c: v2(2,2)

        expect(trianglesOverlap2D(A.a, A.b, A.c, B.a, B.b, B.c)).toBe false

    it "returns true when both degenerate to overlapping collinear segments", ->

        A = a: v2(0,0), b: v2(3,0), c: v2(0,0)
        B = a: v2(1,0), b: v2(2,0), c: v2(1,0)

        expect(trianglesOverlap2D(A.a, A.b, A.c, B.a, B.b, B.c)).toBe true

    it "returns false when both degenerate to disjoint collinear segments", ->

        A = a: v2(0,0), b: v2(1,0), c: v2(0,0)
        B = a: v2(2,0), b: v2(3,0), c: v2(2,0)

        expect(trianglesOverlap2D(A.a, A.b, A.c, B.a, B.b, B.c)).toBe false

describe "triangleOrientation2D", ->

    it "returns > 0 for CCW", ->

        a = v2(0, 0)
        b = v2(1, 0)
        c = v2(0, 1)

        val = triangleOrientation2D(a, b, c)

        expect(sign(val)).toBe 1

    it "returns < 0 for CW", ->

        a = v2(0, 0)
        b = v2(0, 1)
        c = v2(1, 0)

        val = triangleOrientation2D(a, b, c)

        expect(sign(val)).toBe -1

    it "returns 0 for collinear (horizontal line)", ->

        a = v2(0, 1)
        b = v2(2, 1)
        c = v2(5, 1)

        val = triangleOrientation2D(a, b, c)

        expect(sign(val)).toBe 0

    it "returns 0 for collinear (diagonal line)", ->

        a = v2(0, 0)
        b = v2(1, 1)
        c = v2(2, 2)

        val = triangleOrientation2D(a, b, c)

        expect(sign(val)).toBe 0

    it "returns 0 when two points are identical (degenerate)", ->

        a = v2(0, 0)
        b = v2(0, 0)
        c = v2(1, 1)

        val = triangleOrientation2D(a, b, c)

        expect(sign(val)).toBe 0

    it "preserves sign under uniform scaling", ->

        a = v2(0, 0); b = v2(2, 0); c = v2(0, 3)
        s = 10

        val1 = triangleOrientation2D(a, b, c)

        a2 = v2(a.x * s, a.y * s)
        b2 = v2(b.x * s, b.y * s)
        c2 = v2(c.x * s, c.y * s)

        val2 = triangleOrientation2D(a2, b2, c2)

        expect(sign(val1)).toBe 1
        expect(sign(val2)).toBe 1

    it "handles large coordinates without flipping sign", ->

        a = v2(1e6, 1e6)
        b = v2(2e6, 1e6)
        c = v2(1e6, 3e6)

        val = triangleOrientation2D(a, b, c)

        expect(sign(val)).toBe 1

describe "triangleIntersectionCCW2D (embedded subset)", ->

    baseA = ccw(v2(0,0), v2(4,0), v2(0,4))
    smallInside = ccw(v2(1,1), v2(2,1), v2(1,2))
    shifted = ccw(v2(5,5), v2(6,5), v2(5,6))
    edgeShare = ccw(v2(0,0), v2(4,0), v2(2,2))
    vertexShare = ccw(v2(0,0), v2(-1,0), v2(0,-1))
    overlapPartial = ccw(v2(2,-1), v2(5,0), v2(2,2))
    containAInsideB = ccw(v2(-1,-1), v2(6,-1), v2(-1,6))
    edgeTouch = ccw(v2(0,4), v2(2,2), v2(4,0))
    lineDegenerate = ccw(v2(1,1), v2(2,2), v2(3,3))
    pointTouch = ccw(v2(4,0), v2(4,0.000001), v2(4.000001,0))

    it "identical triangles", ->

        assertBool "identical", true, -> callCCW(baseA, baseA)

    it "containment small inside large", ->

        assertBool "containment small", true, -> callCCW(baseA, smallInside)

    it "reverse containment (A inside B)", ->

        assertBool "reverse containment", true, -> callCCW(baseA, containAInsideB)

    it "separated triangles", ->

        assertBool "separated", false, -> callCCW(baseA, shifted)

    it "partial overlap", ->

        assertBool "partial overlap", true, -> callCCW(baseA, overlapPartial)

    it "shared edge", ->

        assertBool "shared edge", true, -> callCCW(baseA, edgeShare)

    it "shared vertex only", ->

        assertBool "shared vertex", true, -> callCCW(baseA, vertexShare)

    it "edge touch (hypotenuse)", ->

        assertBool "edge touch hypotenuse", true, -> callCCW(baseA, edgeTouch)

    it "degenerate line inside", ->

        assertBool "degenerate line", true, -> callCCW(baseA, lineDegenerate)

    it "point-like micro triangle at boundary", ->

        assertBool "micro point boundary", true, -> callCCW(baseA, pointTouch)

    it "random CCW pairs do not throw", ->

        for i in [0...20]

            aX = Math.random()*10; aY = Math.random()*10
            bX = aX + Math.random()*2 + 0.01; bY = aY + Math.random()*2 + 0.01
            cX = aX + Math.random()*2 + 0.01; cY = aY + Math.random()*2 + 0.01

            dX = Math.random()*10; dY = Math.random()*10
            eX = dX + Math.random()*2 + 0.01; eY = dY + Math.random()*2 + 0.01
            fX = dX + Math.random()*2 + 0.01; fY = dY + Math.random()*2 + 0.01

            A = ccw(v2(aX,aY), v2(bX,bY), v2(cX,cY))
            B = ccw(v2(dX,dY), v2(eX,eY), v2(fX,fY))

            _ = callCCW(A, B)

        expect(true).toBe true

describe "intersectionTestEdge2D (direct edge cases)", ->

    build = (pts) -> pts.map (p) -> v2(p[0], p[1])

    callEdge = (A, B) ->

        intersectionTestEdge2D(A[0], A[1], A[2], B[0], B[1], B[2])

    it "detects simple crossing (X shape)", ->

        A = build([[0,0],[3,0],[0,3]])
        B = build([[3,3],[0,3],[3,0]])

        expect(callEdge(A,B)).toBe true

    it "detects shared full edge", ->

        A = build([[0,0],[2,0],[0,2]])
        B = build([[2,0],[0,0],[2,2]])

        expect(callEdge(A,B)).toBe true

    it "detects endpoint touch only", ->

        A = build([[0,0],[2,0],[0,2]])
        B = build([[2,0],[4,0],[2,2]])

        expect(callEdge(A,B)).toBe true

    it "detects T-junction (edge hits midpoint)", ->

        A = build([[0,0],[4,0],[0,3]])
        B = build([[2,-1],[2,1],[3,2]])

        expect(callEdge(A,B)).toBe true

    it "detects collinear overlapping partial edge", ->

        A = build([[0,0],[5,0],[0,3]])
        B = build([[2,0],[7,0],[2,2]])

        expect(callEdge(A,B)).toBe true

    it "rejects collinear but disjoint edge", ->

        A = build([[0,0],[2,0],[0,2]])
        B = build([[3,0],[5,0],[3,2]])

        expect(callEdge(A,B)).toBe false

    it "detects edge containment (small inside large sharing edge)", ->

        A = build([[0,0],[5,0],[0,5]])
        B = build([[1,0],[3,0],[1,2]])

        expect(callEdge(A,B)).toBe true

describe "intersectionTestVertex2D (vertex containment / touch)", ->

    build = (pts) -> pts.map (p) -> v2(p[0], p[1])

    callVertex = (A, B) ->

        intersectionTestVertex2D(A[0], A[1], A[2], B[0], B[1], B[2])

    it "vertex of B strictly inside A", ->

        A = build([[0,0],[5,0],[0,5]])
        B = build([[1,1],[2,1],[1,2]])

        expect(callVertex(A,B)).toBe true

    it "vertex of A strictly inside B (reverse containment)", ->

        A = build([[0,0],[1,0],[0,1]])
        B = build([[-1,-1],[4,-1],[-1,4]])

        expect(callVertex(A,B)).toBe true

    it "shared single vertex only", ->

        A = build([[0,0],[2,0],[0,2]])
        B = build([[0,0],[-1,0],[0,-1]])

        expect(callVertex(A,B)).toBe true

    it "vertex on edge of A (boundary inclusivity)", ->

        A = build([[0,0],[5,0],[0,5]])
        B = build([[2,0],[3,0],[2,1]])

        expect(callVertex(A,B)).toBe true

    it "vertex on edge of B (opposite direction)", ->

        A = build([[2,0],[3,0],[2,1]])
        B = build([[0,0],[5,0],[0,5]])

        expect(callVertex(A,B)).toBe true

    it "no vertices inside (disjoint triangles)", ->

        A = build([[0,0],[2,0],[0,2]])
        B = build([[5,5],[7,5],[5,7]])

        expect(callVertex(A,B)).toBe false

    it "degenerate point triangle inside other", ->

        A = build([[0,0],[4,0],[0,4]])
        B = build([[1,1],[1,1],[1,1]]) # Point

        expect(callVertex(A,B)).toBe true

    it "degenerate point triangle outside other", ->

        A = build([[0,0],[4,0],[0,4]])
        B = build([[5,5],[5,5],[5,5]])

        expect(callVertex(A,B)).toBe false

    it "degenerate line triangle with endpoint inside A", ->

        A = build([[0,0],[4,0],[0,4]])
        B = build([[1,1],[3,3],[1,1]]) # Line segment along diagonal region

        expect(callVertex(A,B)).toBe true

    it "degenerate line triangle entirely outside A", ->

        A = build([[0,0],[2,0],[0,2]])
        B = build([[3,3],[5,5],[3,3]])

        expect(callVertex(A,B)).toBe false

    it "identical triangles (all vertices inside)", ->

        A = build([[0,0],[3,0],[0,3]])
        B = build([[0,0],[3,0],[0,3]])

        expect(callVertex(A,B)).toBe true

    it "shared edge only counts via boundary vertices", ->

        A = build([[0,0],[2,0],[0,2]])
        B = build([[2,0],[0,0],[2,2]])

        expect(callVertex(A,B)).toBe true

describe "constructIntersection (direct invocation)", ->

    v = (x, y, z) -> new Vector3(x, y, z)

    makeNormals = (a1, a2, a3, b1, b2, b3) ->

        n1 = new Vector3().copy(a2).sub(a1).cross(new Vector3().copy(a3).sub(a1))
        n2 = new Vector3().copy(b1).sub(b3).cross(new Vector3().copy(b2).sub(b3))

        return { n1, n2 }

    samePoint = (p, q, eps = 1e-9) ->

        return Math.abs(p.x - q.x) < eps and Math.abs(p.y - q.y) < eps and Math.abs(p.z - q.z) < eps

    unorderedSegmentEquals = (s1a, s1b, s2a, s2b, eps = 1e-9) ->

        return (samePoint(s1a, s2a, eps) and samePoint(s1b, s2b, eps)) or (samePoint(s1a, s2b, eps) and samePoint(s1b, s2a, eps))

    it "computes expected segment for a simple skew intersection (ordering via resolveTriangleIntersection)", ->

        a1 = v(0,0,0); a2 = v(4,0,0); a3 = v(0,4,0)
        bBelow = v(1,1,-1); bUp1 = v(1,1,1); bUp2 = v(3,0,1)

        expected1 = v(1,1,0)
        expected2 = v(2,0.5,0)

        { n1, n2 } = makeNormals(a1, a2, a3, bBelow, bUp1, bUp2)

        # Distances of B vertices to plane of A (z=0 plane normal n1)
        d1 = bBelow.clone().sub(a1).dot(n1)
        d2 = bUp1.clone().sub(a1).dot(n1)
        d3 = bUp2.clone().sub(a1).dot(n1)

        additions = normal1: n1, normal2: n2, source: new Vector3(), target: new Vector3(), coplanar: false

        # This call performs the necessary reordering then invokes constructIntersection internally.
        ok = resolveTriangleIntersection(a1, a2, a3, bBelow, bUp1, bUp2, d1, d2, d3, additions)

        expect(ok).toBe true
        expect(unorderedSegmentEquals(additions.source, additions.target, expected1, expected2)).toBe true

    it "computes same segment with alternate B ordering input (resolveTriangleIntersection handles reordering)", ->

        a1 = v(0,0,0); a2 = v(4,0,0); a3 = v(0,4,0)
        bBelow = v(1,1,-1); bUp1 = v(3,0,1); bUp2 = v(1,1,1)

        expected1 = v(1,1,0)
        expected2 = v(2,0.5,0)

        { n1, n2 } = makeNormals(a1, a2, a3, bBelow, bUp1, bUp2)

        d1 = bBelow.clone().sub(a1).dot(n1)
        d2 = bUp1.clone().sub(a1).dot(n1)
        d3 = bUp2.clone().sub(a1).dot(n1)

        additions = normal1: n1, normal2: n2, source: new Vector3(), target: new Vector3(), coplanar: false

        ok = resolveTriangleIntersection(a1, a2, a3, bBelow, bUp1, bUp2, d1, d2, d3, additions)

        expect(ok).toBe true
        expect(unorderedSegmentEquals(additions.source, additions.target, expected1, expected2)).toBe true

    it "returns false for separated triangles (no segment)", ->

        a1 = v(0,0,0); a2 = v(4,0,0); a3 = v(0,4,0)
        b1 = v(1,1,1); b2 = v(2,1,1); b3 = v(1,2,1) # Entirely above

        { n1, n2 } = makeNormals(a1, a2, a3, b1, b2, b3)
        additions = normal1: n1, normal2: n2, source: new Vector3(), target: new Vector3(), coplanar: false

        ok = constructIntersection(a1, a2, a3, b1, b2, b3, additions)

        expect(ok).toBe false

    it "guards against zero denominator producing NaN (returns false)", ->

        # Craft a degenerate scenario where an edge direction is parallel to the other plane normal.
        # Use coincident points so tempVector2 becomes zero leading to 0 denominator.
        a1 = v(0,0,0); a2 = v(1,0,0); a3 = v(0,1,0)
        b1 = v(0,0,0); b2 = v(0,0,0); b3 = v(0,0,1) # Degenerate edge for B

        { n1, n2 } = makeNormals(a1, a2, a3, b1, b2, b3)
        additions = normal1: n1, normal2: n2, source: new Vector3(), target: new Vector3(), coplanar: false

        ok = constructIntersection(a1, a2, a3, b1, b2, b3, additions)

        expect(ok).toBe false
