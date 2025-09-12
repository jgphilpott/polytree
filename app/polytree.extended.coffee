import Polytree from './polytree.js'
import { Vector3, Plane, Line3, Sphere } from 'three'
import { Capsule } from '../examples/js/Capsule.min.js'

_v1 = new Vector3()
_v2 = new Vector3()

_plane = new Plane()

_line1 = new Line3()
_line2 = new Line3()

_sphere = new Sphere()

_capsule = new Capsule()

class PolytreeExtended extends Polytree

    constructor: (box, parent) ->
        super(box, parent)

    getTriangles: (triangles = []) ->
        polygons = @getPolygons()
        polygons.forEach (p) -> triangles.push(p.triangle)
        triangles

    getRayTriangles: (ray, triangles = []) ->
        polygons = @getRayPolygons(ray)
        polygons.forEach (p) -> triangles.push(p.triangle)
        triangles

    triangleCapsuleIntersect: (capsule, triangle) ->
        triangle.getPlane(_plane)

        d1 = _plane.distanceToPoint(capsule.start) - capsule.radius
        d2 = _plane.distanceToPoint(capsule.end) - capsule.radius

        if (d1 > 0 and d2 > 0) or (d1 < -capsule.radius and d2 < -capsule.radius)
            return false

        delta = Math.abs(d1 / (Math.abs(d1) + Math.abs(d2)))
        intersectPoint = _v1.copy(capsule.start).lerp(capsule.end, delta)

        if triangle.containsPoint(intersectPoint)
            return
                normal: _plane.normal.clone()
                point: intersectPoint.clone()
                depth: Math.abs(Math.min(d1, d2))

        r2 = capsule.radius * capsule.radius

        line1 = _line1.set(capsule.start, capsule.end)

        lines = [
            [triangle.a, triangle.b]
            [triangle.b, triangle.c]
            [triangle.c, triangle.a]
        ]

        for i in [0...lines.length]
            line2 = _line2.set(lines[i][0], lines[i][1])
            [point1, point2] = capsule.lineLineMinimumPoints(line1, line2)
            if point1.distanceToSquared(point2) < r2
                return
                    normal: point1.clone().sub(point2).normalize()
                    point: point2.clone()
                    depth: capsule.radius - point1.distanceTo(point2)

        false

    triangleSphereIntersect: (sphere, triangle) ->
        triangle.getPlane(_plane)

        return false unless sphere.intersectsPlane(_plane)

        depth = Math.abs(_plane.distanceToSphere(sphere))
        r2 = sphere.radius * sphere.radius - depth * depth

        plainPoint = _plane.projectPoint(sphere.center, _v1)

        if triangle.containsPoint(sphere.center)
            return
                normal: _plane.normal.clone()
                point: plainPoint.clone()
                depth: Math.abs(_plane.distanceToSphere(sphere))

        lines = [
            [triangle.a, triangle.b]
            [triangle.b, triangle.c]
            [triangle.c, triangle.a]
        ]

        for i in [0...lines.length]
            _line1.set(lines[i][0], lines[i][1])
            _line1.closestPointToPoint(plainPoint, true, _v2)
            d = _v2.distanceToSquared(sphere.center)
            if d < r2
                return
                    normal: sphere.center.clone().sub(_v2).normalize()
                    point: _v2.clone()
                    depth: sphere.radius - Math.sqrt(d)

        false

    getSphereTriangles: (sphere, triangles) ->
        for i in [0...@subTrees.length]
            subTree = @subTrees[i]
            continue unless sphere.intersectsBox(subTree.box)
            if subTree.polygons.length > 0
                for j in [0...subTree.polygons.length]
                    continue unless subTree.polygons[j].valid
                    if triangles.indexOf(subTree.polygons[j].triangle) is -1
                        triangles.push(subTree.polygons[j].triangle)
            else
                subTree.getSphereTriangles(sphere, triangles)

    getCapsuleTriangles: (capsule, triangles) ->
        for i in [0...@subTrees.length]
            subTree = @subTrees[i]
            continue unless capsule.intersectsBox(subTree.box)
            if subTree.polygons.length > 0
                for j in [0...subTree.polygons.length]
                    continue unless subTree.polygons[j].valid
                    if triangles.indexOf(subTree.polygons[j].triangle) is -1
                        triangles.push(subTree.polygons[j].triangle)
            else
                subTree.getCapsuleTriangles(capsule, triangles)

    sphereIntersect: (sphere) ->
        _sphere.copy(sphere)
        triangles = []
        result = undefined
        hit = false

        @getSphereTriangles(sphere, triangles)
        for i in [0...triangles.length]
            if result = @triangleSphereIntersect(_sphere, triangles[i])
                hit = true
                _sphere.center.add(result.normal.multiplyScalar(result.depth))

        if hit
            collisionVector = _sphere.center.clone().sub(sphere.center)
            depth = collisionVector.length()
            return
                normal: collisionVector.normalize()
                depth: depth

        false

    capsuleIntersect: (capsule) ->
        _capsule.copy(capsule)
        triangles = []
        result = undefined
        hit = false

        @getCapsuleTriangles(_capsule, triangles)

        for i in [0...triangles.length]
            if result = @triangleCapsuleIntersect(_capsule, triangles[i])
                hit = true
                _capsule.translate(result.normal.multiplyScalar(result.depth))

        if hit
            collisionVector = _capsule.getCenter(new Vector3()).sub(capsule.getCenter(_v1))
            depth = collisionVector.length()
            return
                normal: collisionVector.normalize()
                depth: depth

        false

    fromGraphNode: (group) ->
        group.updateWorldMatrix(true, true)
        group.traverse (obj) ->
            if obj.isMesh is true
                Polytree.fromMesh(obj, undefined, this, false)
        @buildTree()
        @

export { PolytreeExtended, Polytree }
