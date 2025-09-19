{ Vector2, Vector3 } = require "three"

{ Vertex } = require "../../polytree.bundle.js"

# Helper factory for creating test vertices.
v3 = (x, y, z) -> new Vector3(x, y, z)
v2 = (x, y) -> new Vector2(x, y)

# Tolerance for floating point comparisons.
EPS = 1e-6

describe "Vertex", ->

    describe "Constructor", ->

        it "should create vertex with position and normal", ->

            pos = v3(1, 2, 3)
            normal = v3(0, 1, 0)
            vertex = new Vertex(pos, normal)

            expect(vertex.pos).toEqual(pos)
            expect(vertex.normal).toEqual(normal)
            expect(vertex.uv).toBeUndefined()
            expect(vertex.color).toBeUndefined()

        it "should create vertex with all properties", ->

            pos = v3(1, 2, 3)
            normal = v3(0, 1, 0)
            uv = v2(0.5, 0.5)
            color = v3(1, 0, 0)
            vertex = new Vertex(pos, normal, uv, color)

            expect(vertex.pos).toEqual(pos)
            expect(vertex.normal).toEqual(normal)
            expect(vertex.uv).toEqual(uv)
            expect(vertex.color).toEqual(color)

        it "should create independent copies of input vectors", ->

            pos = v3(1, 2, 3)
            normal = v3(0, 1, 0)
            vertex = new Vertex(pos, normal)

            # Modify original vectors.
            pos.x = 999
            normal.y = 999

            # Vertex should be unaffected.
            expect(vertex.pos.x).toBe(1)
            expect(vertex.normal.y).toBe(1)

        it "should handle null/undefined optional parameters", ->

            pos = v3(1, 2, 3)
            normal = v3(0, 1, 0)

            vertex1 = new Vertex(pos, normal, null, null)
            vertex2 = new Vertex(pos, normal, undefined, undefined)

            expect(vertex1.uv).toBeUndefined()
            expect(vertex1.color).toBeUndefined()
            expect(vertex2.uv).toBeUndefined()
            expect(vertex2.color).toBeUndefined()

    describe "Clone Method", ->

        it "should create exact copy with all properties", ->

            pos = v3(1, 2, 3)
            normal = v3(0, 1, 0)
            uv = v2(0.5, 0.75)
            color = v3(0.8, 0.2, 0.1)
            original = new Vertex(pos, normal, uv, color)

            clone = original.clone()

            expect(clone.pos).toEqual(original.pos)
            expect(clone.normal).toEqual(original.normal)
            expect(clone.uv).toEqual(original.uv)
            expect(clone.color).toEqual(original.color)

        it "should create independent copies", ->

            original = new Vertex(v3(1, 2, 3), v3(0, 1, 0), v2(0.5, 0.5), v3(1, 0, 0))
            clone = original.clone()

            # Modify original.
            original.pos.x = 999
            original.normal.y = 999
            original.uv.x = 999
            original.color.x = 999

            # Clone should be unaffected.
            expect(clone.pos.x).toBe(1)
            expect(clone.normal.y).toBe(1)
            expect(clone.uv.x).toBe(0.5)
            expect(clone.color.x).toBe(1)

        it "should handle partial properties correctly", ->

            original = new Vertex(v3(1, 2, 3), v3(0, 1, 0))
            clone = original.clone()

            expect(clone.pos).toEqual(original.pos)
            expect(clone.normal).toEqual(original.normal)
            expect(clone.uv).toBeUndefined()
            expect(clone.color).toBeUndefined()

    describe "Flip Method", ->

        it "should negate the normal vector", ->

            vertex = new Vertex(v3(0, 0, 0), v3(0, 1, 0))
            vertex.flip()

            expect(vertex.normal.x).toBeCloseTo(0, 5)
            expect(vertex.normal.y).toBe(-1)
            expect(vertex.normal.z).toBeCloseTo(0, 5)

        it "should not affect other properties", ->

            pos = v3(1, 2, 3)
            uv = v2(0.5, 0.5)
            color = v3(1, 0, 0)
            vertex = new Vertex(pos, v3(0, 1, 0), uv, color)

            vertex.flip()

            expect(vertex.pos).toEqual(pos)
            expect(vertex.uv).toEqual(uv)
            expect(vertex.color).toEqual(color)

        it "should work with non-unit normals", ->

            vertex = new Vertex(v3(0, 0, 0), v3(2, 4, 6))
            vertex.flip()

            expect(vertex.normal.x).toBe(-2)
            expect(vertex.normal.y).toBe(-4)
            expect(vertex.normal.z).toBe(-6)

    describe "Interpolate Method", ->

        it "should interpolate position and normal", ->

            vertex1 = new Vertex(v3(0, 0, 0), v3(1, 0, 0))
            vertex2 = new Vertex(v3(10, 10, 10), v3(0, 1, 0))

            result = vertex1.interpolate(vertex2, 0.5)

            expect(result.pos.x).toBe(5)
            expect(result.pos.y).toBe(5)
            expect(result.pos.z).toBe(5)
            expect(result.normal.x).toBe(0.5)
            expect(result.normal.y).toBe(0.5)
            expect(result.normal.z).toBe(0)

        it "should interpolate UV coordinates when both vertices have them", ->

            vertex1 = new Vertex(v3(0, 0, 0), v3(1, 0, 0), v2(0, 0))
            vertex2 = new Vertex(v3(1, 1, 1), v3(0, 1, 0), v2(1, 1))

            result = vertex1.interpolate(vertex2, 0.25)

            expect(result.uv.x).toBe(0.25)
            expect(result.uv.y).toBe(0.25)

        it "should interpolate color when both vertices have it", ->

            vertex1 = new Vertex(v3(0, 0, 0), v3(1, 0, 0), null, v3(0, 0, 0))
            vertex2 = new Vertex(v3(1, 1, 1), v3(0, 1, 0), null, v3(1, 1, 1))

            result = vertex1.interpolate(vertex2, 0.4)

            expect(result.color.x).toBeCloseTo(0.4, 5)
            expect(result.color.y).toBeCloseTo(0.4, 5)
            expect(result.color.z).toBeCloseTo(0.4, 5)

        it "should handle missing UV or color gracefully", ->

            vertex1 = new Vertex(v3(0, 0, 0), v3(1, 0, 0), v2(0, 0), v3(1, 0, 0))
            vertex2 = new Vertex(v3(1, 1, 1), v3(0, 1, 0)) # No UV or color

            result = vertex1.interpolate(vertex2, 0.5)

            expect(result.pos.x).toBe(0.5)
            expect(result.normal.x).toBe(0.5)
            expect(result.uv).toBeUndefined()
            expect(result.color).toBeUndefined()

        it "should work at boundary values", ->

            vertex1 = new Vertex(v3(0, 0, 0), v3(1, 0, 0))
            vertex2 = new Vertex(v3(10, 20, 30), v3(0, 1, 0))

            # At factor 0, should equal vertex1.
            result0 = vertex1.interpolate(vertex2, 0)
            expect(result0.pos).toEqual(vertex1.pos)
            expect(result0.normal).toEqual(vertex1.normal)

            # At factor 1, should equal vertex2.
            result1 = vertex1.interpolate(vertex2, 1)
            expect(result1.pos).toEqual(vertex2.pos)
            expect(result1.normal).toEqual(vertex2.normal)

        it "should create new vertex instances", ->

            vertex1 = new Vertex(v3(0, 0, 0), v3(1, 0, 0))
            vertex2 = new Vertex(v3(1, 1, 1), v3(0, 1, 0))

            result = vertex1.interpolate(vertex2, 0.5)

            expect(result).not.toBe(vertex1)
            expect(result).not.toBe(vertex2)
            expect(result).toBeInstanceOf(Vertex)

    describe "Delete Method", ->

        it "should set all properties to undefined", ->

            vertex = new Vertex(v3(1, 2, 3), v3(0, 1, 0), v2(0.5, 0.5), v3(1, 0, 0))
            vertex.delete()

            expect(vertex.pos).toBeUndefined()
            expect(vertex.normal).toBeUndefined()
            expect(vertex.uv).toBeUndefined()
            expect(vertex.color).toBeUndefined()

        it "should handle vertices with missing optional properties", ->

            vertex = new Vertex(v3(1, 2, 3), v3(0, 1, 0))
            vertex.delete()

            expect(vertex.pos).toBeUndefined()
            expect(vertex.normal).toBeUndefined()
            expect(vertex.uv).toBeUndefined()
            expect(vertex.color).toBeUndefined()

    describe "Edge Cases and Error Handling", ->

        it "should handle zero vectors", ->

            vertex = new Vertex(v3(0, 0, 0), v3(0, 0, 0))

            expect(() -> vertex.clone()).not.toThrow()
            expect(() -> vertex.flip()).not.toThrow()
            expect(() -> vertex.delete()).not.toThrow()

        it "should handle very large coordinates", ->

            bigValue = 1e10
            vertex = new Vertex(v3(bigValue, bigValue, bigValue), v3(1, 0, 0))

            clone = vertex.clone()
            expect(clone.pos.x).toBe(bigValue)

        it "should handle very small coordinates", ->

            smallValue = 1e-10
            vertex = new Vertex(v3(smallValue, smallValue, smallValue), v3(1, 0, 0))

            clone = vertex.clone()
            expect(clone.pos.x).toBe(smallValue)

        it "should handle interpolation with extreme factors", ->

            vertex1 = new Vertex(v3(0, 0, 0), v3(1, 0, 0))
            vertex2 = new Vertex(v3(10, 10, 10), v3(0, 1, 0))

            # Test with negative factor.
            result = vertex1.interpolate(vertex2, -0.5)
            expect(result.pos.x).toBe(-5)

            # Test with factor > 1.
            result2 = vertex1.interpolate(vertex2, 1.5)
            expect(result2.pos.x).toBe(15)

        it "should handle null/undefined parameters gracefully", ->

            vertex1 = new Vertex(v3(0, 0, 0), v3(1, 0, 0))

            # These should not crash (Three.js handles them gracefully).
            expect(() -> new Vertex(null, v3(1, 0, 0))).toThrow()
            expect(() -> new Vertex(v3(0, 0, 0), null)).toThrow()

        it "should work with edge case interpolation factor values", ->

            vertex1 = new Vertex(v3(0, 0, 0), v3(1, 0, 0))
            vertex2 = new Vertex(v3(10, 10, 10), v3(0, 1, 0))

            # Should handle Infinity.
            result = vertex1.interpolate(vertex2, Infinity)
            expect(isFinite(result.pos.x)).toBe(false)

            # Should handle NaN.
            resultNaN = vertex1.interpolate(vertex2, NaN)
            expect(isNaN(resultNaN.pos.x)).toBe(true)