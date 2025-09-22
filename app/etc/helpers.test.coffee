{ Vector2, Vector3, Triangle, Ray } = require "three"

{

    createVector2Buffer
    createVector3Buffer
    sortRaycastIntersectionsByDistance
    roundPointCoordinates
    extractCoordinatesFromArray
    splitPolygonByPlane
    splitPolygonVertexArray
    calculateWindingNumberFromBuffer
    testPolygonInsideUsingWindingNumber
    prepareTriangleBufferFromPolygons
    testRayTriangleIntersection
    handleIntersectingPolytrees
    disposePolytreeResources

} = require "../../polytree.bundle.js"

# Test constants.
EPS = 1e-6
TOL = 1e-10

# Helper function to create a test vector.
vec2 = (x, y) -> new Vector2(x, y)
vec3 = (x, y, z) -> new Vector3(x, y, z)

# Helper function to create a test triangle.
triangle = (aX, aY, aZ, bX, bY, bZ, cX, cY, cZ) ->

    new Triangle(
        new Vector3(aX, aY, aZ),
        new Vector3(bX, bY, bZ),
        new Vector3(cX, cY, cZ)
    )

describe "Helper Functions", ->

    describe "Buffer Utilities", ->

        it "createVector2Buffer should create and write 2D vectors", ->

            buffer = createVector2Buffer(3)

            expect(buffer.top).toBe(0)
            expect(buffer.array.length).toBe(6) # 3 vectors × 2 components.

            buffer.write(vec2(1, 2))
            buffer.write(vec2(3, 4))

            expect(buffer.top).toBe(4)
            expect(buffer.array[0]).toBe(1)
            expect(buffer.array[1]).toBe(2)
            expect(buffer.array[2]).toBe(3)
            expect(buffer.array[3]).toBe(4)

        it "createVector3Buffer should create and write 3D vectors", ->

            buffer = createVector3Buffer(2)

            expect(buffer.top).toBe(0)
            expect(buffer.array.length).toBe(6) # 2 vectors × 3 components.

            buffer.write(vec3(1, 2, 3))
            buffer.write(vec3(4, 5, 6))

            expect(buffer.top).toBe(6)
            expect(buffer.array[0]).toBe(1)
            expect(buffer.array[1]).toBe(2)
            expect(buffer.array[2]).toBe(3)
            expect(buffer.array[3]).toBe(4)
            expect(buffer.array[4]).toBe(5)
            expect(buffer.array[5]).toBe(6)

    describe "Point and Geometric Utilities", ->

        it "sortRaycastIntersectionsByDistance should sort by distance", ->

            intersections = [
                { distance: 5.0 }
                { distance: 1.0 }
                { distance: 3.0 }
                { distance: 2.0 }
            ]

            intersections.sort(sortRaycastIntersectionsByDistance)

            expect(intersections[0].distance).toBe(1.0)
            expect(intersections[1].distance).toBe(2.0)
            expect(intersections[2].distance).toBe(3.0)
            expect(intersections[3].distance).toBe(5.0)

        it "roundPointCoordinates should round to specified precision", ->

            point = vec3(1.123456789, 2.987654321, 3.555555555)
            roundedPoint = roundPointCoordinates(point, 3)

            expect(roundedPoint.x).toBe(1.123)
            expect(roundedPoint.y).toBe(2.988)
            expect(roundedPoint.z).toBe(3.556)

        it "roundPointCoordinates should use default precision", ->

            point = vec3(1.123456789012345678, 2.0, 3.0)
            roundedPoint = roundPointCoordinates(point)

            expect(typeof roundedPoint.x).toBe("number")
            expect(roundedPoint).toBe(point) # Should modify in place.

        it "extractCoordinatesFromArray should extract XYZ coordinates", ->

            coordinatesArray = new Float32Array([1, 2, 3, 4, 5, 6, 7, 8, 9])
            coordinates = extractCoordinatesFromArray(coordinatesArray, 3)

            expect(coordinates.x).toBe(4)
            expect(coordinates.y).toBe(5)
            expect(coordinates.z).toBe(6)

    describe "Ray-Triangle Intersection", ->

        it "testRayTriangleIntersection should detect intersection", ->

            testTriangle = triangle(0, 0, 0, 1, 0, 0, 0, 1, 0)
            ray = new Ray(vec3(0.25, 0.25, 1), vec3(0, 0, -1))

            intersection = testRayTriangleIntersection(ray, testTriangle)

            expect(intersection).not.toBeNull()
            expect(intersection.x).toBeCloseTo(0.25, EPS)
            expect(intersection.y).toBeCloseTo(0.25, EPS)
            expect(intersection.z).toBeCloseTo(0, EPS)

        it "testRayTriangleIntersection should return null for miss", ->

            testTriangle = triangle(0, 0, 0, 1, 0, 0, 0, 1, 0)
            ray = new Ray(vec3(2, 2, 1), vec3(0, 0, -1)) # Ray misses triangle.

            intersection = testRayTriangleIntersection(ray, testTriangle)

            expect(intersection).toBeNull()

        it "testRayTriangleIntersection should return null for parallel ray", ->

            testTriangle = triangle(0, 0, 0, 1, 0, 0, 0, 1, 0)
            ray = new Ray(vec3(0, 0, 1), vec3(1, 0, 0)) # Ray parallel to triangle.

            intersection = testRayTriangleIntersection(ray, testTriangle)

            expect(intersection).toBeNull()

        it "testRayTriangleIntersection should handle edge cases", ->

            testTriangle = triangle(0, 0, 0, 1, 0, 0, 0, 1, 0)
            ray = new Ray(vec3(0, 0, 1), vec3(0, 0, -1)) # Ray hits vertex.

            intersection = testRayTriangleIntersection(ray, testTriangle)

            expect(intersection).not.toBeNull()

    describe "Triangle Buffer Operations", ->

        it "prepareTriangleBufferFromPolygons should create proper buffer", ->

            # Mock polygon objects with triangle property.
            mockPolygons = [
                {
                    triangle: triangle(0, 0, 0, 1, 0, 0, 0, 1, 0)
                }
                {
                    triangle: triangle(1, 1, 1, 2, 1, 1, 1, 2, 1)
                }
            ]

            buffer = prepareTriangleBufferFromPolygons(mockPolygons)

            expect(buffer.length).toBe(18) # 2 triangles × 3 vertices × 3 coordinates.

            expect(buffer[0]).toBe(0) # First triangle, first vertex, x coordinate.
            expect(buffer[1]).toBe(0) # First triangle, first vertex, y coordinate.
            expect(buffer[2]).toBe(0) # First triangle, first vertex, z coordinate.

    describe "Error Handling and Edge Cases", ->

        it "should handle empty arrays gracefully", ->

            emptyBuffer = prepareTriangleBufferFromPolygons([])

            expect(emptyBuffer.length).toBe(0)

        it "should handle null/undefined inputs safely", ->

            expect(() -> roundPointCoordinates(null)).toThrow()
            expect(() -> extractCoordinatesFromArray(null, 0)).toThrow()

        it "should handle invalid buffer indices", ->

            array = new Float32Array([1, 2, 3])

            expect(() -> extractCoordinatesFromArray(array, 10)).not.toThrow()

            result = extractCoordinatesFromArray(array, 10)

            expect(result.x).toBeUndefined()

    describe "Performance and Stress Tests", ->

        it "should handle large buffers efficiently", ->

            # Create a large number of vectors for buffer test.
            largeBuffer = createVector3Buffer(1000)

            for i in [0...1000]

                largeBuffer.write(vec3(i, i + 1, i + 2))

            expect(largeBuffer.top).toBe(3000)

        it "should handle many intersections efficiently", ->

            # Test with many intersection objects.
            manyIntersections = []

            for i in [0...100]

                manyIntersections.push({ distance: Math.random() * 100 })

            startTime = Date.now()
            manyIntersections.sort(sortRaycastIntersectionsByDistance)
            endTime = Date.now()

            expect(endTime - startTime).toBeLessThan(100) # Should be fast.
            expect(manyIntersections[0].distance).toBeLessThanOrEqual(manyIntersections[1].distance)
