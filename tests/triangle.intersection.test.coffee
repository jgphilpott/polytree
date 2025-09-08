{ Vector3 } = require "three"
{ triangleIntersectsTriangle } = require "../src/triangle.intersection.js"

tri = (ax, ay, az, bx, bY, bz, cx, cy, cz) -> # Helper to build a triangle object matching the function’s expected shape.

    a: new Vector3(ax, ay, az)
    b: new Vector3(bx, bY, bz)
    c: new Vector3(cx, cy, cz)

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

describe 'triangleIntersectsTriangle', ->

    it 'separated triangles (parallel planes)', ->

        tA = tri(0,0,0, 1,0,0, 0,1,0)
        tB = tri(0,0,2, 1,0,2, 0,1,2)

        assertIntersection tA, tB, false,

            coplanar: false
            label: 'separated parallel planes'

    it 'separated triangles (skew planes)', ->

        tA = tri(0,0,0, 2,0,0, 0,2,0)
        tB = tri(3,3,1, 4,3,2, 3,4,1.5)

        assertIntersection tA, tB, false,

            coplanar: false
            label: 'skew planes no overlap'

    it 'segment intersection (non-coplanar)', ->

        tA = tri(0,0,0, 2,0,0, 1,1,0)
        tB = tri(1,-1,0, 1,2,0, 1,0,1)

        assertIntersection tA, tB, true,

            coplanar: false
            intersection: true
            label: 'non-coplanar segment'

    it 'shared edge (coplanar)', ->

        tA = tri(0,0,0, 1,0,0, 0,1,0)
        tB = tri(1,0,0, 0,0,0, 1,1,0)

        assertIntersection tA, tB, true,

            coplanar: true
            label: 'coplanar shared edge'

    it 'vertex pierce (B through A)', ->

        tA = tri(0,0,0, 2,0,0, 0,2,0)
        tB = tri(1,0.5,0, 1,0.5,1, 1,0.5,-1)

        assertIntersection tA, tB, true,

            coplanar: true
            intersection: false
            label: 'vertex pierce (degenerate vertical line)'

    it 'coplanar separated', ->

        tA = tri(0,0,0, 1,0,0, 0,1,0)
        tB = tri(2,2,0, 3,2,0, 2,3,0)

        assertIntersection tA, tB, false,

            coplanar: true
            label: 'coplanar separated'

    it 'coplanar partial overlap', ->

        tA = tri(0,0,0, 3,0,0, 0,3,0)
        tB = tri(1,0,0, 2,0,0, 1,2,0)

        assertIntersection tA, tB, true,

            coplanar: true
            label: 'coplanar overlap'

    it 'coplanar containment', ->

        tA = tri(0,0,0, 5,0,0, 0,5,0)
        tB = tri(1,1,0, 2,1,0, 1,2,0)

        assertIntersection tA, tB, true,

            coplanar: true
            label: 'coplanar containment'

    it 'near coplanar (epsilon offsets)', ->

        eps = 1e-8
        tA = tri(0,0,0, 2,0,0, 0,2,0)
        tB = tri(0.5,0.5,eps, 1.5,0.5,-eps, 0.5,1.5,eps)

        assertIntersection tA, tB, true,

            coplanar: false
            label: 'near coplanar small epsilon'

    it 'shared vertex only (treated as intersect)', ->

        tA = tri(0,0,0, 1,0,0, 0,1,0)
        tB = tri(0,0,0, -1,0,0, 0,-1,0)

        assertIntersection tA, tB, true,

            coplanar: true
            label: 'shared vertex'

    it 'degenerate A (no area) vs valid triangle', ->

        tA = tri(0,0,0, 0,0,0, 0,0,0)
        tB = tri(0,1,0, 1,0,0, 0,0,1)

        assertIntersection tA, tB, false,

            coplanar: false
            label: 'degenerate A'

    it 'degenerate point inside other (coplanar)', ->

        tA = tri(0.2,0.2,0, 0.2,0.2,0, 0.2,0.2,0)
        tB = tri(0,0,0, 2,0,0, 0,2,0)

        assertIntersection tA, tB, true,

            coplanar: true
            label: 'degenerate point inside'

    it 'skew oblique intersection', ->

        tA = tri(0,0,0, 2,0,0, 0,2,1)
        tB = tri(0,0,0.5, 1,1,0.5, 0,1,2)

        assertIntersection tA, tB, true,

            coplanar: false
            label: 'skew oblique'

    it 'skew disjoint', ->

        tA = tri(0,0,0, 2,0,0, 0,2,1)
        tB = tri(3,0,0.5, 4,1,0.5, 3,1,2)

        assertIntersection tA, tB, false,

            coplanar: false
            label: 'skew disjoint'
