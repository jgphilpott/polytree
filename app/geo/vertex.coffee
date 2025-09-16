# class Vertex
class Vertex

    constructor: (pos, normal, uv, color) ->

        @pos = new Vector3().copy(pos)
        @normal = new Vector3().copy(normal)
        uv and (@uv = new Vector2().copy(uv))
        color and (@color = new Vector3().copy(color))

    clone: ->

        new Vertex(@pos.clone(), @normal.clone(), @uv and @uv.clone(), @color and @color.clone())

    flip: ->

        @normal.negate()

    delete: ->

        @pos = undefined
        @normal = undefined
        @uv and (@uv = undefined)
        @color and (@color = undefined)

    interpolate: (other, t) ->

        new Vertex(
            @pos.clone().lerp(other.pos, t),
            @normal.clone().lerp(other.normal, t),
            @uv and other.uv and @uv.clone().lerp(other.uv, t),
            @color and other.color and @color.clone().lerp(other.color, t)
        )