# Temporary vectors for computation (shared globals)
triangleVertex0 = new Vector3()
triangleVertex1 = new Vector3()

# class Plane
class Plane

    constructor: (normal, w) ->

        @normal = normal
        @w = w

    clone: ->

        new Plane(@normal.clone(), @w)

    flip: ->

        @normal.negate()
        @w = -@w

    delete: ->

        @normal = undefined
        @w = undefined

    equals: (p) ->

        @normal.equals(p.normal) and @w is p.w

Plane.fromPoints = (a, b, c) ->

    planeNormal = triangleVertex0.copy(b).sub(a).cross(triangleVertex1.copy(c).sub(a)).normalize().clone()
    new Plane(planeNormal, planeNormal.dot(a))