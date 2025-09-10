{ Vector2, Vector3 } = require "three"

{

    triangleIntersectsTriangle
    resolveTriangleIntersection
    resolveCoplanarTriangleIntersection
    trianglesOverlap2D
    triangleOrientation2D
    triangleIntersectionCCW2D
    intersectionTestEdge2D
    intersectionTestVertex2D
    constructIntersection

} = require "../src/triangle.intersection.js"

# Helper functions to keep tests DRY.

v2 = (x, y) -> new Vector2(x, y)
v3 = (x, y, z) -> new Vector3(x, y, z)
n = (x, y, z) -> new Vector3(x, y, z).normalize()

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
            label: "identical triangles"

    it "degenerate line across interior", ->

        tA = tri(0,0,0,  4,0,0,  0,4,0)
        tB = tri(1,1,0, 3,1,0, 1,1,0)

        assertIntersection tA, tB, true,

            coplanar: true
            label: "degenerate line inside"

describe "resolveTriangleIntersection", ->

    # Degenerate/no intersection: all positive distances (triangle B fully outside A).
    it "returns false for all-positive distances (should do nothing)", ->

        vA1 = v3(0,0,0)
        vA2 = v3(1,0,0)
        vA3 = v3(0,1,0)

        vB1 = v3(0,0,1)
        vB2 = v3(1,0,1)
        vB3 = v3(0,1,1)

        additions = { coplanar: false, source: new Vector3(), target: new Vector3(), normal1: v3(0,0,1), normal2: v3(0,0,1) }
        result = resolveTriangleIntersection(vA1, vA2, vA3, vB1, vB2, vB3, 1, 1, 1, additions)

        expect(result).toBe false

    # Crossing case: B first above, others below (ensures correct permutation and branch).
    it "handles one B vertex above and two below", ->

        vA1 = v3(0,0,0)
        vA2 = v3(2,0,0)
        vA3 = v3(0,2,0)

        vB1 = v3(1,1,1) # Above
        vB2 = v3(0.5,0.5,-1) # Below
        vB3 = v3(1.5,0.5,-1) # Below

        additions = { coplanar: false, source: new Vector3(), target: new Vector3(), normal1: v3(0,0,1), normal2: v3(0,0,1) }
        result = resolveTriangleIntersection(vA1, vA2, vA3, vB1, vB2, vB3, 1, -1, -1, additions)

        expect(result).toBe true

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
