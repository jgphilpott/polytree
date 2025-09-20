{ Vector3 } = require "three"

{ Plane } = require "../../polytree.bundle.js"

# Helper factory for creating test vectors.
v3 = (x, y, z) -> new Vector3(x, y, z)

# Helper factory for creating test planes.
plane = (normalX, normalY, normalZ, w) -> new Plane(v3(normalX, normalY, normalZ), w)

# Tolerance for floating point comparisons.
EPS = 1e-6

describe "Plane", ->

    describe "Constructor", ->

        it "should create plane with normal and w value", ->

            normal = v3(0, 1, 0)
            w = 5.0
            p = new Plane(normal, w)

            expect(p.normal).toEqual(normal)
            expect(p.w).toBe(w)

        it "should create plane with normalized normal", ->

            normal = v3(0, 2, 0) # Will be normalized in practice
            w = 3.0
            p = new Plane(normal, w)

            expect(p.normal).toEqual(normal)
            expect(p.w).toBe(w)

        it "should handle zero w value", ->

            normal = v3(1, 0, 0)
            w = 0.0
            p = new Plane(normal, w)

            expect(p.normal).toEqual(normal)
            expect(p.w).toBe(w)

        it "should handle negative w value", ->

            normal = v3(0, 0, 1)
            w = -2.5
            p = new Plane(normal, w)

            expect(p.normal).toEqual(normal)
            expect(p.w).toBe(w)

    describe "Clone Method", ->

        it "should create deep copy of plane", ->

            original = plane(0, 1, 0, 5.0)
            cloned = original.clone()

            expect(cloned.normal).toEqual(original.normal)
            expect(cloned.w).toBe(original.w)

            # Verify it's a deep copy
            expect(cloned.normal).not.toBe(original.normal)
            expect(cloned).not.toBe(original)

        it "should preserve all plane properties in clone", ->

            original = plane(1, 2, 3, 7.5)
            cloned = original.clone()

            expect(cloned.normal.x).toBe(original.normal.x)
            expect(cloned.normal.y).toBe(original.normal.y)
            expect(cloned.normal.z).toBe(original.normal.z)
            expect(cloned.w).toBe(original.w)

        it "should create independent copy that can be modified", ->

            original = plane(1, 0, 0, 3.0)
            cloned = original.clone()

            cloned.flip()

            expect(original.normal.x).toBe(1)
            expect(cloned.normal.x).toBe(-1)
            expect(original.w).toBe(3.0)
            expect(cloned.w).toBe(-3.0)

    describe "Flip Method", ->

        it "should negate normal vector", ->

            p = plane(0, 1, 0, 5.0)
            p.flip()

            expect(p.normal.x).toBeCloseTo(0, 5)
            expect(p.normal.y).toBe(-1)
            expect(p.normal.z).toBeCloseTo(0, 5)

        it "should negate w value", ->

            p = plane(1, 0, 0, 3.0)
            p.flip()

            expect(p.w).toBe(-3.0)

        it "should work with negative w values", ->

            p = plane(0, 0, 1, -2.5)
            p.flip()

            expect(p.normal.z).toBe(-1)
            expect(p.w).toBe(2.5)

        it "should work with non-unit normals", ->

            p = new Plane(v3(2, 0, 0), 4.0)
            p.flip()

            expect(p.normal.x).toBe(-2)
            expect(p.normal.y).toBeCloseTo(0, 5)
            expect(p.normal.z).toBeCloseTo(0, 5)
            expect(p.w).toBe(-4.0)

        it "should handle zero w value", ->

            p = plane(0, 1, 0, 0.0)
            p.flip()

            expect(p.normal.y).toBe(-1)
            expect(p.w).toBeCloseTo(0.0, 5)

    describe "Delete Method", ->

        it "should set normal to undefined", ->

            p = plane(1, 0, 0, 2.0)
            p.delete()

            expect(p.normal).toBeUndefined()

        it "should set w to undefined", ->

            p = plane(0, 1, 0, 3.0)
            p.delete()

            expect(p.w).toBeUndefined()

        it "should clean up all properties", ->

            p = plane(0, 0, 1, 1.5)
            p.delete()

            expect(p.normal).toBeUndefined()
            expect(p.w).toBeUndefined()

    describe "Equals Method", ->

        it "should return true for identical planes", ->

            p1 = plane(0, 1, 0, 5.0)
            p2 = plane(0, 1, 0, 5.0)

            expect(p1.equals(p2)).toBe(true)

        it "should return false for different normals", ->

            p1 = plane(0, 1, 0, 5.0)
            p2 = plane(1, 0, 0, 5.0)

            expect(p1.equals(p2)).toBe(false)

        it "should return false for different w values", ->

            p1 = plane(0, 1, 0, 5.0)
            p2 = plane(0, 1, 0, 3.0)

            expect(p1.equals(p2)).toBe(false)

        it "should return false for both different normal and w", ->

            p1 = plane(0, 1, 0, 5.0)
            p2 = plane(1, 0, 0, 3.0)

            expect(p1.equals(p2)).toBe(false)

        it "should handle negative values correctly", ->

            p1 = plane(-1, 0, 0, -2.5)
            p2 = plane(-1, 0, 0, -2.5)

            expect(p1.equals(p2)).toBe(true)

        it "should work with cloned planes", ->

            original = plane(1, 2, 3, 4.5)
            cloned = original.clone()

            expect(original.equals(cloned)).toBe(true)

    describe "Static fromPoints Method", ->

        it "should create plane from three points", ->

            a = v3(0, 0, 0)
            b = v3(1, 0, 0)
            c = v3(0, 1, 0)

            p = Plane.fromPoints(a, b, c)

            expect(p).toBeInstanceOf(Plane)
            expect(p.normal).toBeInstanceOf(Vector3)
            expect(typeof p.w).toBe("number")

        it "should create correct plane for XY plane", ->

            a = v3(0, 0, 0)
            b = v3(1, 0, 0)
            c = v3(0, 1, 0)

            p = Plane.fromPoints(a, b, c)

            # Should create plane with normal pointing in +Z direction
            expect(p.normal.x).toBeCloseTo(0, 5)
            expect(p.normal.y).toBeCloseTo(0, 5)
            expect(p.normal.z).toBeCloseTo(1, 5)
            expect(p.w).toBeCloseTo(0, 5)

        it "should create correct plane for offset XY plane", ->

            a = v3(0, 0, 2)
            b = v3(1, 0, 2)
            c = v3(0, 1, 2)

            p = Plane.fromPoints(a, b, c)

            # Should create plane with normal pointing in +Z direction
            expect(p.normal.x).toBeCloseTo(0, 5)
            expect(p.normal.y).toBeCloseTo(0, 5)
            expect(p.normal.z).toBeCloseTo(1, 5)
            expect(p.w).toBeCloseTo(2, 5)

        it "should create correct plane for YZ plane", ->

            a = v3(3, 0, 0)
            b = v3(3, 1, 0)
            c = v3(3, 0, 1)

            p = Plane.fromPoints(a, b, c)

            # Should create plane with normal pointing in +X direction
            expect(p.normal.x).toBeCloseTo(1, 5)
            expect(p.normal.y).toBeCloseTo(0, 5)
            expect(p.normal.z).toBeCloseTo(0, 5)
            expect(p.w).toBeCloseTo(3, 5)

        it "should create correct plane for arbitrary triangle", ->

            a = v3(1, 2, 3)
            b = v3(4, 2, 3)
            c = v3(1, 5, 3)

            p = Plane.fromPoints(a, b, c)

            # Points should lie on the plane
            expect(p.normal.dot(a)).toBeCloseTo(p.w, 5)
            expect(p.normal.dot(b)).toBeCloseTo(p.w, 5)
            expect(p.normal.dot(c)).toBeCloseTo(p.w, 5)

        it "should handle different point orderings", ->

            a = v3(0, 0, 0)
            b = v3(1, 0, 0)
            c = v3(0, 1, 0)

            p1 = Plane.fromPoints(a, b, c)
            p2 = Plane.fromPoints(a, c, b) # Different order

            # Normals should be opposite due to winding
            expect(p1.normal.x).toBeCloseTo(-p2.normal.x, 5)
            expect(p1.normal.y).toBeCloseTo(-p2.normal.y, 5)
            expect(p1.normal.z).toBeCloseTo(-p2.normal.z, 5)

    describe "Edge Cases and Error Handling", ->

        it "should handle zero normal vectors", ->

            p = new Plane(v3(0, 0, 0), 1.0)

            expect(() -> p.clone()).not.toThrow()
            expect(() -> p.flip()).not.toThrow()
            expect(() -> p.delete()).not.toThrow()

        it "should handle very large coordinates", ->

            bigValue = 1e10
            p = plane(bigValue, 0, 0, bigValue)

            clone = p.clone()
            expect(clone.normal.x).toBe(bigValue)
            expect(clone.w).toBe(bigValue)

        it "should handle very small coordinates", ->

            smallValue = 1e-10
            p = plane(smallValue, 0, 0, smallValue)

            clone = p.clone()
            expect(clone.normal.x).toBe(smallValue)
            expect(clone.w).toBe(smallValue)

        it "should handle fromPoints with collinear points gracefully", ->

            a = v3(0, 0, 0)
            b = v3(1, 0, 0)
            c = v3(2, 0, 0) # Collinear

            # Should still create a plane object, though normal may be zero
            expect(() -> Plane.fromPoints(a, b, c)).not.toThrow()

        it "should handle fromPoints with identical points", ->

            a = v3(1, 1, 1)
            b = v3(1, 1, 1)
            c = v3(1, 1, 1)

            # Should still create a plane object
            expect(() -> Plane.fromPoints(a, b, c)).not.toThrow()

    describe "Integration with Vector3 Methods", ->

        it "should work with Vector3 operations", ->

            p = plane(1, 0, 0, 5.0)

            # Test normal vector operations
            expect(p.normal.length()).toBeCloseTo(1, 5)

            # Test that normal is a proper Vector3
            expect(p.normal.clone).toBeDefined()
            expect(p.normal.normalize).toBeDefined()

        it "should preserve normal vector type after operations", ->

            p = plane(0, 1, 0, 2.0)
            p.flip()

            expect(p.normal).toBeInstanceOf(Vector3)
            expect(p.normal.y).toBe(-1)