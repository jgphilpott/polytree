# Main class for representing polygons (triangular faces) in 3D space for CSG operations.
# Polygons are fundamental building blocks for geometric operations and mesh generation.
class Polygon

    # Main constructor for creating polygon instances.
    # Initializes all geometric and state properties for CSG processing.
    #
    # @param vertices - Array of Vertex instances representing the polygon corners.
    # @param shared - Material or shared data index for grouping polygons.
    constructor: (vertices, shared) ->

        # Core geometric properties.
        @id = _polygonID++                    # Unique identifier for this polygon.
        @vertices = vertices.map((v) -> v.clone()) # Deep copy of vertex array.
        @shared = shared                      # Material index or shared data.

        # Geometric calculations.
        @plane = Plane.fromPoints(@vertices[0].pos, @vertices[1].pos, @vertices[2].pos)
        @triangle = new Triangle(@vertices[0].pos, @vertices[1].pos, @vertices[2].pos)

        # CSG operation state properties.
        @intersects = false                   # Whether polygon intersects with other geometry.
        @state = "undecided"                  # Current classification state.
        @previousState = "undecided"          # Previous classification state.
        @previousStates = []                  # History of all previous states.

        # Validity and processing flags.
        @valid = true                         # Whether polygon is valid for processing.
        @coplanar = false                     # Whether polygon is coplanar with splitting plane.
        @originalValid = false                # Whether polygon was part of original input.
        @newPolygon = false                   # Whether polygon was created during processing.

    # === SMALL HELPERS AND GETTERS ===

    # Get the midpoint of the polygon triangle.
    # Caches the result for performance optimization.
    #
    # @return Three.js Vector3 representing the triangle midpoint.
    getMidpoint: ->

        if @triangle.midPoint then @triangle.midPoint else @triangle.midPoint = @triangle.getMidpoint(new Vector3())

    # === GEOMETRIC TRANSFORMATIONS ===

    # Apply a transformation matrix to the polygon vertices and update derived geometry.
    # Updates vertex positions, normals, and recalculates plane and triangle data.
    #
    # @param matrix - Three.js Matrix4 transformation to apply to vertices.
    # @param normalMatrix - Three.js Matrix3 for transforming normals (auto-calculated if not provided).
    applyMatrix: (matrix, normalMatrix) ->

        normalMatrix = normalMatrix or temporaryMatrixWithNormalCalc.getNormalMatrix(matrix)

        @vertices.forEach (v) ->
            v.pos.applyMatrix4(matrix)
            v.normal.applyMatrix3(normalMatrix)

        @plane.delete()
        @plane = Plane.fromPoints(@vertices[0].pos, @vertices[1].pos, @vertices[2].pos)
        @triangle.set(@vertices[0].pos, @vertices[1].pos, @vertices[2].pos)

        if @triangle.midPoint
            @triangle.getMidpoint(@triangle.midPoint)

    # Flip the polygon orientation by reversing vertex order and flipping normals.
    # Used for changing polygon winding and surface normal direction.
    flip: ->

        @vertices.reverse().forEach((v) -> v.flip())
        tmp = @triangle.a
        @triangle.a = @triangle.c
        @triangle.c = tmp
        @plane.flip()

    # === CSG STATE MANAGEMENT ===

    # Reset polygon state to initial values for fresh CSG operations.
    # Clears intersection flags and classification states.
    #
    # @param resetOriginal - Whether to reset the originalValid flag (default: true).
    reset: (resetOriginal = true) ->

        @intersects = false
        @state = "undecided"
        @previousState = "undecided"
        @previousStates.length = 0
        @valid = true
        @coplanar = false
        resetOriginal and (@originalValid = false)
        @newPolygon = false

    # Set the classification state of the polygon during CSG operations.
    # Maintains state history for complex CSG rule evaluation.
    #
    # @param state - New state to assign ("inside", "outside", "coplanar-front", etc.).
    # @param keepState - State to preserve (won't change if current state matches this).
    setState: (state, keepState) ->

        return if @state is keepState
        @previousState = @state
        @state isnt "undecided" and @previousStates.push(@state)
        @state = state

    # Check if polygon has consistently been in the specified state.
    # Used for CSG rule evaluation requiring state consistency.
    #
    # @param state - State to check for consistency.
    # @return Boolean indicating if all states match the specified state.
    checkAllStates: (state) ->

        return false if (@state isnt state) or ((@previousState isnt state) and (@previousState isnt "undecided"))
        for s in @previousStates
            return false if s isnt state
        return true

    # === VALIDITY MANAGEMENT ===

    # Mark polygon as invalid (will be excluded from processing).
    setInvalid: -> @valid = false

    # Mark polygon as valid (will be included in processing).
    setValid: -> @valid = true

    # === OBJECT CREATION AND COPYING ===

    # Create a deep copy of this polygon with all properties.
    # Preserves all state information and geometric data.
    #
    # @return New Polygon instance with copied data.
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

    # === CLEANUP AND DISPOSAL METHODS ===

    # Clean up polygon data and free memory.
    # Deletes vertices, geometric objects, and marks polygon as invalid.
    delete: ->

        @vertices.forEach((v) -> v.delete())
        @vertices.length = 0

        if @plane
            @plane.delete()
            @plane = undefined

        @triangle = undefined
        @shared = undefined
        @setInvalid()
