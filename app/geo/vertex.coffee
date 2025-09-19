# Main class for representing vertices in 3D space with optional texture and color data.
# Vertices are the fundamental building blocks for polygons and meshes in the geometry system.
class Vertex

    # Main constructor for creating vertex instances.
    # Initializes position, normal, and optional texture/color attributes.
    #
    # @param pos - Three.js Vector3 representing the vertex position in 3D space.
    # @param normal - Three.js Vector3 representing the surface normal at this vertex.
    # @param uv - Optional Three.js Vector2 for texture coordinates.
    # @param color - Optional Three.js Vector3 for vertex color information.
    constructor: (pos, normal, uv, color) ->

        # Core geometric properties.
        @pos = new Vector3().copy(pos)            # 3D position coordinates.
        @normal = new Vector3().copy(normal)      # Surface normal vector.

        # Optional texture and visual properties.
        uv and (@uv = new Vector2().copy(uv))     # Texture coordinates (UV mapping).
        color and (@color = new Vector3().copy(color))  # Vertex color data.

    # === OBJECT CREATION AND COPYING ===

    clone: -> # Create a deep copy of this vertex with all properties.

        new Vertex(@pos.clone(), @normal.clone(), @uv and @uv.clone(), @color and @color.clone())

    # === GEOMETRIC TRANSFORMATIONS ===

    flip: -> # Flip the normal vector direction (invert surface orientation).

        @normal.negate()

    interpolate: (other, interpolationFactor) -> # Linear interpolation between this vertex and another.
        # Creates a new vertex interpolated between this vertex and another.
        # All properties (position, normal, UV, color) are interpolated if present on both vertices.
        #
        # @param other - The target vertex to interpolate towards.
        # @param interpolationFactor - Factor from 0.0 (this vertex) to 1.0 (other vertex).
        # @return New interpolated Vertex instance.

        new Vertex(
            @pos.clone().lerp(other.pos, interpolationFactor),
            @normal.clone().lerp(other.normal, interpolationFactor),
            @uv and other.uv and @uv.clone().lerp(other.uv, interpolationFactor),
            @color and other.color and @color.clone().lerp(other.color, interpolationFactor)
        )

    # === CLEANUP AND DISPOSAL METHODS ===

    delete: -> # Clean up vertex data by setting all properties to undefined.
        # Used for memory management during intensive operations.

        @pos = undefined
        @normal = undefined
        @uv and (@uv = undefined)
        @color and (@color = undefined)