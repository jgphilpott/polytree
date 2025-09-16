{

    Vector3
    Triangle
    Matrix3

} = require "three"

# Global polygon ID counter
_polygonID = 0

# Temporary matrix for normal calculations
tmpm3 = new Matrix3()

# class Polygon
class Polygon

    constructor: (vertices, shared) ->

        @id = _polygonID++
        @vertices = vertices.map((v) -> v.clone())
        @shared = shared
        @plane = Plane.fromPoints(@vertices[0].pos, @vertices[1].pos, @vertices[2].pos)
        @triangle = new Triangle(@vertices[0].pos, @vertices[1].pos, @vertices[2].pos)
        @intersects = false
        @state = "undecided"
        @previousState = "undecided"
        @previousStates = []
        @valid = true
        @coplanar = false
        @originalValid = false
        @newPolygon = false

    getMidpoint: ->

        if @triangle.midPoint then @triangle.midPoint else @triangle.midPoint = @triangle.getMidpoint(new Vector3())

    applyMatrix: (matrix, normalMatrix) ->

        normalMatrix = normalMatrix or tmpm3.getNormalMatrix(matrix)
        @vertices.forEach (v) ->
            v.pos.applyMatrix4(matrix)
            v.normal.applyMatrix3(normalMatrix)
        @plane.delete()
        @plane = Plane.fromPoints(@vertices[0].pos, @vertices[1].pos, @vertices[2].pos)
        @triangle.set(@vertices[0].pos, @vertices[1].pos, @vertices[2].pos)
        if @triangle.midPoint
            @triangle.getMidpoint(@triangle.midPoint)

    reset: (resetOriginal = true) ->

        @intersects = false
        @state = "undecided"
        @previousState = "undecided"
        @previousStates.length = 0
        @valid = true
        @coplanar = false
        resetOriginal and (@originalValid = false)
        @newPolygon = false

    setState: (state, keepState) ->

        return if @state is keepState
        @previousState = @state
        @state isnt "undecided" and @previousStates.push(@state)
        @state = state

    checkAllStates: (state) ->

        return false if (@state isnt state) or ((@previousState isnt state) and (@previousState isnt "undecided"))
        for s in @previousStates
            return false if s isnt state
        return true

    setInvalid: -> @valid = false

    setValid: -> @valid = true

    clone: ->

        polygon = new Polygon(@vertices.map((v) -> v.clone()), @shared)
        polygon.intersects = @intersects
        polygon.valid = @valid
        polygon.coplanar = @coplanar
        polygon.state = @state
        polygon.originalValid = @originalValid
        polygon.newPolygon = @newPolygon
        polygon.previousState = @previousState
        polygon.previousStates = @previousStates.slice()
        if @triangle.midPoint
            polygon.triangle.midPoint = @triangle.midPoint.clone()
        return polygon

    flip: ->

        @vertices.reverse().forEach((v) -> v.flip())
        tmp = @triangle.a
        @triangle.a = @triangle.c
        @triangle.c = tmp
        @plane.flip()

    delete: ->

        @vertices.forEach((v) -> v.delete())
        @vertices.length = 0
        if @plane
            @plane.delete()
            @plane = undefined
        @triangle = undefined
        @shared = undefined
        @setInvalid()