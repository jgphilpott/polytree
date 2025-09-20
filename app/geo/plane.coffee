# Main class for representing geometric planes in 3D space.
# Planes are defined by a normal vector and a distance (w) from the origin.
# Used extensively in CSG operations for polygon classification and splitting.
class Plane

    # Main constructor for creating plane instances.
    # Creates a plane defined by the equation: normal·point = w
    #
    # @param normal - Three.js Vector3 representing the plane's normal direction.
    # @param w - Distance from origin along the normal direction.
    constructor: (normal, w) ->

        # Core geometric properties.
        @normal = normal    # Normal vector defining plane orientation.
        @w = w              # Distance parameter in plane equation.

    # === OBJECT CREATION AND COPYING ===

    clone: -> # Create a deep copy of this plane with all properties.

        new Plane(@normal.clone(), @w)

    # === GEOMETRIC TRANSFORMATIONS ===

    flip: -> # Flip the plane orientation (reverse normal and negate distance).

        @normal.negate()
        @w = -@w

    # === COMPARISON OPERATIONS ===

    # Test if this plane is identical to another plane.
    # Compares both normal vector and distance parameter for equality.
    #
    # @param p - The other plane to compare against.
    #
    # @return Boolean indicating whether planes are identical.
    equals: (p) ->

        @normal.equals(p.normal) and @w is p.w

    # === CLEANUP AND DISPOSAL METHODS ===

    # Clean up plane data by setting all properties to undefined.
    # Used for memory management during intensive operations.
    delete: ->

        @normal = undefined
        @w = undefined

# === STATIC FACTORY METHODS ===

# Create a plane from three points in 3D space.
# Uses cross product to compute normal and dot product for distance.
# Points should be ordered counter-clockwise when viewed from the front face.
#
# @param a - First point (Three.js Vector3).
# @param b - Second point (Three.js Vector3).
# @param c - Third point (Three.js Vector3).
#
# @return New Plane instance passing through the three points.
Plane.fromPoints = (a, b, c) ->

    planeNormal = temporaryTriangleVertex.copy(b).sub(a).cross(temporaryTriangleVertexSecondary.copy(c).sub(a)).normalize().clone()
    new Plane(planeNormal, planeNormal.dot(a))
