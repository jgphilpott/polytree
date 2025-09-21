# Main class for representing geometric planes in 3D space.
# Planes are defined by a normal vector and a distance from the origin.
# Used extensively in CSG operations for polygon classification and splitting.
class Plane

    # Main constructor for creating plane instances.
    # Creates a plane defined by the equation: normal·point = distanceFromOrigin
    #
    # @param normal - Three.js Vector3 representing the plane's normal direction.
    # @param distanceFromOrigin - Distance from origin along the normal direction.
    constructor: (normal, distanceFromOrigin) ->

        # Core geometric properties.
        @normal = normal                         # Normal vector defining plane orientation.
        @distanceFromOrigin = distanceFromOrigin # Distance parameter in plane equation.

    # === OBJECT CREATION AND COPYING ===

    clone: -> # Create a deep copy of this plane with all properties.

        new Plane(@normal.clone(), @distanceFromOrigin)

    # === GEOMETRIC TRANSFORMATIONS ===

    flip: -> # Flip the plane orientation (reverse normal and negate distance).

        @normal.negate()

        @distanceFromOrigin = -@distanceFromOrigin

    # === COMPARISON OPERATIONS ===

    # Test if this plane is identical to another plane.
    # Compares both normal vector and distance parameter for equality.
    #
    # @param otherPlane - The other plane to compare against.
    #
    # @return Boolean indicating whether planes are identical.
    equals: (otherPlane) ->

        @normal.equals(otherPlane.normal) and @distanceFromOrigin is otherPlane.distanceFromOrigin

    # === CLEANUP AND DISPOSAL METHODS ===

    # Clean up plane data by setting all properties to undefined.
    # Used for memory management during intensive operations.
    delete: ->

        @normal = undefined

        @distanceFromOrigin = undefined

    # === STATIC FACTORY METHODS ===

    # Create a plane from three points in 3D space.
    # Uses cross product to compute normal and dot product for distance.
    # Points should be ordered counter-clockwise when viewed from the front face.
    #
    # @param firstPoint - First point (Three.js Vector3).
    # @param secondPoint - Second point (Three.js Vector3).
    # @param thirdPoint - Third point (Three.js Vector3).
    #
    # @return New Plane instance passing through the three points.
    @fromPoints: (firstPoint, secondPoint, thirdPoint) ->

        planeNormal = temporaryTriangleVertex.copy(secondPoint).sub(firstPoint).cross(temporaryTriangleVertexSecondary.copy(thirdPoint).sub(firstPoint)).normalize().clone()

        new Plane(planeNormal, planeNormal.dot(firstPoint))
