{ Vector3 } = require "three"

{ Plane } = require "../../polytree.bundle.js"

# Helper factory for creating test vectors.
createVector3 = (x, y, z) -> new Vector3(x, y, z)

# Helper factory for creating test planes.
createPlane = (normalX, normalY, normalZ, distanceFromOriginValue) -> new Plane(createVector3(normalX, normalY, normalZ), distanceFromOriginValue)

# Tolerance for floating point comparisons.
EPSILON = 1e-6

describe "Plane", ->

    describe "Constructor", ->

        it "should create plane with normal and distance from origin value", ->

            normalVector = createVector3(0, 1, 0)
            distanceFromOriginValue = 5.0
            testPlane = new Plane(normalVector, distanceFromOriginValue)

            expect(testPlane.normal).toEqual(normalVector)
            expect(testPlane.distanceFromOrigin).toBe(distanceFromOriginValue)

        it "should create plane with normalized normal", ->

            normalVector = createVector3(0, 2, 0) # Will be normalized in practice
            distanceFromOriginValue = 3.0
            testPlane = new Plane(normalVector, distanceFromOriginValue)

            expect(testPlane.normal).toEqual(normalVector)
            expect(testPlane.distanceFromOrigin).toBe(distanceFromOriginValue)

        it "should handle zero distance value", ->

            normalVector = createVector3(1, 0, 0)
            distanceFromOriginValue = 0.0
            testPlane = new Plane(normalVector, distanceFromOriginValue)

            expect(testPlane.normal).toEqual(normalVector)
            expect(testPlane.distanceFromOrigin).toBe(distanceFromOriginValue)

        it "should handle negative w value", ->

            normalVector = createVector3(0, 0, 1)
            distanceFromOriginValue = -2.5
            testPlane = new Plane(normalVector, distanceFromOriginValue)

            expect(testPlane.normal).toEqual(normalVector)
            expect(testPlane.distanceFromOrigin).toBe(distanceFromOriginValue)

    describe "Clone Method", ->

        it "should create deep copy of plane", ->

            originalPlane = createPlane(0, 1, 0, 5.0)
            clonedPlane = originalPlane.clone()

            expect(clonedPlane.normal).toEqual(originalPlane.normal)
            expect(clonedPlane.distanceFromOrigin).toBe(originalPlane.distanceFromOrigin)

            # Verify it's a deep copy
            expect(clonedPlane.normal).not.toBe(originalPlane.normal)
            expect(clonedPlane).not.toBe(originalPlane)

        it "should preserve all plane properties in clone", ->

            originalPlane = createPlane(1, 2, 3, 7.5)
            clonedPlane = originalPlane.clone()

            expect(clonedPlane.normal.x).toBe(originalPlane.normal.x)
            expect(clonedPlane.normal.y).toBe(originalPlane.normal.y)
            expect(clonedPlane.normal.z).toBe(originalPlane.normal.z)
            expect(clonedPlane.distanceFromOrigin).toBe(originalPlane.distanceFromOrigin)

        it "should create independent copy that can be modified", ->

            originalPlane = createPlane(1, 0, 0, 3.0)
            clonedPlane = originalPlane.clone()

            clonedPlane.flip()

            expect(originalPlane.normal.x).toBe(1)
            expect(clonedPlane.normal.x).toBe(-1)
            expect(originalPlane.distanceFromOrigin).toBe(3.0)
            expect(clonedPlane.distanceFromOrigin).toBe(-3.0)

    describe "Flip Method", ->

        it "should negate normal vector", ->

            testPlane = createPlane(0, 1, 0, 5.0)
            testPlane.flip()

            expect(testPlane.normal.x).toBeCloseTo(0, 5)
            expect(testPlane.normal.y).toBe(-1)
            expect(testPlane.normal.z).toBeCloseTo(0, 5)

        it "should negate w value", ->

            testPlane = createPlane(1, 0, 0, 3.0)
            testPlane.flip()

            expect(testPlane.distanceFromOrigin).toBe(-3.0)

        it "should work with negative distance values", ->

            testPlane = createPlane(0, 0, 1, -2.5)
            testPlane.flip()

            expect(testPlane.normal.z).toBe(-1)
            expect(testPlane.distanceFromOrigin).toBe(2.5)

        it "should work with non-unit normals", ->

            testPlane = new Plane(createVector3(2, 0, 0), 4.0)
            testPlane.flip()

            expect(testPlane.normal.x).toBe(-2)
            expect(testPlane.normal.y).toBeCloseTo(0, 5)
            expect(testPlane.normal.z).toBeCloseTo(0, 5)
            expect(testPlane.distanceFromOrigin).toBe(-4.0)

        it "should handle zero distance value", ->

            testPlane = createPlane(0, 1, 0, 0.0)
            testPlane.flip()

            expect(testPlane.normal.y).toBe(-1)
            expect(testPlane.distanceFromOrigin).toBeCloseTo(0.0, 5)

    describe "Delete Method", ->

        it "should set normal to undefined", ->

            testPlane = createPlane(1, 0, 0, 2.0)
            testPlane.delete()

            expect(testPlane.normal).toBeUndefined()

        it "should set w to undefined", ->

            testPlane = createPlane(0, 1, 0, 3.0)
            testPlane.delete()

            expect(testPlane.distanceFromOrigin).toBeUndefined()

        it "should clean up all properties", ->

            testPlane = createPlane(0, 0, 1, 1.5)
            testPlane.delete()

            expect(testPlane.normal).toBeUndefined()
            expect(testPlane.distanceFromOrigin).toBeUndefined()

    describe "Equals Method", ->

        it "should return true for identical planes", ->

            firstPlane = createPlane(0, 1, 0, 5.0)
            secondPlane = createPlane(0, 1, 0, 5.0)

            expect(firstPlane.equals(secondPlane)).toBe(true)

        it "should return false for different normals", ->

            firstPlane = createPlane(0, 1, 0, 5.0)
            secondPlane = createPlane(1, 0, 0, 5.0)

            expect(firstPlane.equals(secondPlane)).toBe(false)

        it "should return false for different distance values", ->

            firstPlane = createPlane(0, 1, 0, 5.0)
            secondPlane = createPlane(0, 1, 0, 3.0)

            expect(firstPlane.equals(secondPlane)).toBe(false)

        it "should return false for both different normal and w", ->

            firstPlane = createPlane(0, 1, 0, 5.0)
            secondPlane = createPlane(1, 0, 0, 3.0)

            expect(firstPlane.equals(secondPlane)).toBe(false)

        it "should handle negative values correctly", ->

            firstPlane = createPlane(-1, 0, 0, -2.5)
            secondPlane = createPlane(-1, 0, 0, -2.5)

            expect(firstPlane.equals(secondPlane)).toBe(true)

        it "should work with cloned planes", ->

            originalPlane = createPlane(1, 2, 3, 4.5)
            clonedPlane = originalPlane.clone()

            expect(originalPlane.equals(clonedPlane)).toBe(true)

    describe "Static fromPoints Method", ->

        it "should create plane from three points", ->

            firstPoint = createVector3(0, 0, 0)
            secondPoint = createVector3(1, 0, 0)
            thirdPoint = createVector3(0, 1, 0)

            testPlane = Plane.fromPoints(firstPoint, secondPoint, thirdPoint)

            expect(testPlane).toBeInstanceOf(Plane)
            expect(testPlane.normal).toBeInstanceOf(Vector3)
            expect(typeof testPlane.distanceFromOrigin).toBe("number")

        it "should create correct plane for XY plane", ->

            firstPoint = createVector3(0, 0, 0)
            secondPoint = createVector3(1, 0, 0)
            thirdPoint = createVector3(0, 1, 0)

            testPlane = Plane.fromPoints(firstPoint, secondPoint, thirdPoint)

            # Should create plane with normal pointing in +Z direction
            expect(testPlane.normal.x).toBeCloseTo(0, 5)
            expect(testPlane.normal.y).toBeCloseTo(0, 5)
            expect(testPlane.normal.z).toBeCloseTo(1, 5)
            expect(testPlane.distanceFromOrigin).toBeCloseTo(0, 5)

        it "should create correct plane for offset XY plane", ->

            firstPoint = createVector3(0, 0, 2)
            secondPoint = createVector3(1, 0, 2)
            thirdPoint = createVector3(0, 1, 2)

            testPlane = Plane.fromPoints(firstPoint, secondPoint, thirdPoint)

            # Should create plane with normal pointing in +Z direction
            expect(testPlane.normal.x).toBeCloseTo(0, 5)
            expect(testPlane.normal.y).toBeCloseTo(0, 5)
            expect(testPlane.normal.z).toBeCloseTo(1, 5)
            expect(testPlane.distanceFromOrigin).toBeCloseTo(2, 5)

        it "should create correct plane for YZ plane", ->

            firstPoint = createVector3(3, 0, 0)
            secondPoint = createVector3(3, 1, 0)
            thirdPoint = createVector3(3, 0, 1)

            testPlane = Plane.fromPoints(firstPoint, secondPoint, thirdPoint)

            # Should create plane with normal pointing in +X direction
            expect(testPlane.normal.x).toBeCloseTo(1, 5)
            expect(testPlane.normal.y).toBeCloseTo(0, 5)
            expect(testPlane.normal.z).toBeCloseTo(0, 5)
            expect(testPlane.distanceFromOrigin).toBeCloseTo(3, 5)

        it "should create correct plane for arbitrary triangle", ->

            firstPoint = createVector3(1, 2, 3)
            secondPoint = createVector3(4, 2, 3)
            thirdPoint = createVector3(1, 5, 3)

            testPlane = Plane.fromPoints(firstPoint, secondPoint, thirdPoint)

            # Points should lie on the plane
            expect(testPlane.normal.dot(firstPoint)).toBeCloseTo(testPlane.distanceFromOrigin, 5)
            expect(testPlane.normal.dot(secondPoint)).toBeCloseTo(testPlane.distanceFromOrigin, 5)
            expect(testPlane.normal.dot(thirdPoint)).toBeCloseTo(testPlane.distanceFromOrigin, 5)

        it "should handle different point orderings", ->

            firstPoint = createVector3(0, 0, 0)
            secondPoint = createVector3(1, 0, 0)
            thirdPoint = createVector3(0, 1, 0)

            firstPlane = Plane.fromPoints(firstPoint, secondPoint, thirdPoint)
            secondPlane = Plane.fromPoints(firstPoint, thirdPoint, secondPoint) # Different order

            # Normals should be opposite due to winding
            expect(firstPlane.normal.x).toBeCloseTo(-secondPlane.normal.x, 5)
            expect(firstPlane.normal.y).toBeCloseTo(-secondPlane.normal.y, 5)
            expect(firstPlane.normal.z).toBeCloseTo(-secondPlane.normal.z, 5)

    describe "Edge Cases and Error Handling", ->

        it "should handle zero normal vectors", ->

            testPlane = new Plane(createVector3(0, 0, 0), 1.0)

            expect(() -> testPlane.clone()).not.toThrow()
            expect(() -> testPlane.flip()).not.toThrow()
            expect(() -> testPlane.delete()).not.toThrow()

        it "should handle very large coordinates", ->

            bigValue = 1e10
            testPlane = createPlane(bigValue, 0, 0, bigValue)

            clonedPlane = testPlane.clone()
            expect(clonedPlane.normal.x).toBe(bigValue)
            expect(clonedPlane.distanceFromOrigin).toBe(bigValue)

        it "should handle very small coordinates", ->

            smallValue = 1e-10
            testPlane = createPlane(smallValue, 0, 0, smallValue)

            clonedPlane = testPlane.clone()
            expect(clonedPlane.normal.x).toBe(smallValue)
            expect(clonedPlane.distanceFromOrigin).toBe(smallValue)

        it "should handle fromPoints with collinear points gracefully", ->

            firstPoint = createVector3(0, 0, 0)
            secondPoint = createVector3(1, 0, 0)
            thirdPoint = createVector3(2, 0, 0) # Collinear

            # Should still create a plane object, though normal may be zero
            expect(() -> Plane.fromPoints(firstPoint, secondPoint, thirdPoint)).not.toThrow()

        it "should handle fromPoints with identical points", ->

            firstPoint = createVector3(1, 1, 1)
            secondPoint = createVector3(1, 1, 1)
            thirdPoint = createVector3(1, 1, 1)

            # Should still create a plane object
            expect(() -> Plane.fromPoints(firstPoint, secondPoint, thirdPoint)).not.toThrow()

    describe "Integration with Vector3 Methods", ->

        it "should work with Vector3 operations", ->

            testPlane = createPlane(1, 0, 0, 5.0)

            # Test normal vector operations
            expect(testPlane.normal.length()).toBeCloseTo(1, 5)

            # Test that normal is a proper Vector3
            expect(testPlane.normal.clone).toBeDefined()
            expect(testPlane.normal.normalize).toBeDefined()

        it "should preserve normal vector type after operations", ->

            testPlane = createPlane(0, 1, 0, 2.0)
            testPlane.flip()

            expect(testPlane.normal).toBeInstanceOf(Vector3)
            expect(testPlane.normal.y).toBe(-1)