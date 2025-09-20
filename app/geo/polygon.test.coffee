{ Vector2, Vector3, Matrix4, Matrix3, Triangle } = require "three"

{ Polygon, Vertex, Plane } = require "../../polytree.bundle.js"

# Helper factories for creating test objects.
v3 = (x, y, z) -> new Vector3(x, y, z)
v2 = (x, y) -> new Vector2(x, y)

# Create a vertex with position and normal.
vertex = (pos, normal, uv = null, color = null) -> new Vertex(pos, normal, uv, color)

# Create a simple triangle polygon.
tri = (vertices, shared = 0) -> new Polygon(vertices, shared)

# Tolerance for floating point comparisons.
EPS = 1e-6

describe "Polygon", ->

    describe "Constructor", ->

        it "should create polygon with basic triangle vertices", ->

            vertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(1, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 1, 0), v3(0, 0, 1))
            ]
            polygon = new Polygon(vertices, 0)

            expect(polygon.vertices.length).toBe(3)
            expect(polygon.shared).toBe(0)
            expect(polygon.intersects).toBe(false)
            expect(polygon.state).toBe("undecided")
            expect(polygon.valid).toBe(true)
            expect(polygon.coplanar).toBe(false)
            expect(polygon.originalValid).toBe(false)
            expect(polygon.newPolygon).toBe(false)

        it "should assign unique ID to each polygon", ->

            vertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(1, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 1, 0), v3(0, 0, 1))
            ]

            polygon1 = new Polygon(vertices, 0)
            polygon2 = new Polygon(vertices, 0)

            expect(polygon1.id).not.toBe(polygon2.id)
            expect(polygon2.id).toBe(polygon1.id + 1)

        it "should create independent copies of input vertices", ->

            originalVertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(1, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 1, 0), v3(0, 0, 1))
            ]
            polygon = new Polygon(originalVertices, 0)

            # Modify original vertices.
            originalVertices[0].pos.x = 999

            # Polygon should be unaffected.
            expect(polygon.vertices[0].pos.x).toBe(0)

        it "should create plane and triangle from vertices", ->

            vertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(1, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 1, 0), v3(0, 0, 1))
            ]
            polygon = new Polygon(vertices, 0)

            expect(polygon.plane).toBeDefined()
            expect(polygon.triangle).toBeDefined()
            expect(polygon.plane.normal).toBeDefined()
            expect(polygon.triangle.a).toEqual(vertices[0].pos)
            expect(polygon.triangle.b).toEqual(vertices[1].pos)
            expect(polygon.triangle.c).toEqual(vertices[2].pos)

        it "should initialize state arrays correctly", ->

            vertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(1, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 1, 0), v3(0, 0, 1))
            ]
            polygon = new Polygon(vertices, 0)

            expect(polygon.previousStates).toEqual([])
            expect(polygon.previousState).toBe("undecided")

    describe "getMidpoint Method", ->

        it "should calculate and cache triangle midpoint", ->

            vertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(3, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 3, 0), v3(0, 0, 1))
            ]
            polygon = new Polygon(vertices, 0)

            midpoint = polygon.getMidpoint()

            expect(midpoint.x).toBeCloseTo(1, 5)
            expect(midpoint.y).toBeCloseTo(1, 5)
            expect(midpoint.z).toBeCloseTo(0, 5)

        it "should return cached midpoint on subsequent calls", ->

            vertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(1, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 1, 0), v3(0, 0, 1))
            ]
            polygon = new Polygon(vertices, 0)

            midpoint1 = polygon.getMidpoint()
            midpoint2 = polygon.getMidpoint()

            expect(midpoint1).toBe(midpoint2) # Same object reference

    describe "applyMatrix Method", ->

        it "should transform vertex positions and normals", ->

            vertices = [
                vertex(v3(1, 0, 0), v3(0, 1, 0))
                vertex(v3(0, 1, 0), v3(0, 1, 0))
                vertex(v3(0, 0, 1), v3(0, 1, 0))
            ]
            polygon = new Polygon(vertices, 0)

            # Translation matrix.
            matrix = new Matrix4().makeTranslation(1, 1, 1)
            polygon.applyMatrix(matrix)

            expect(polygon.vertices[0].pos.x).toBeCloseTo(2, 5)
            expect(polygon.vertices[0].pos.y).toBeCloseTo(1, 5)
            expect(polygon.vertices[0].pos.z).toBeCloseTo(1, 5)

        it "should update plane and triangle after transformation", ->

            vertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(1, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 1, 0), v3(0, 0, 1))
            ]
            polygon = new Polygon(vertices, 0)

            originalPlane = polygon.plane
            matrix = new Matrix4().makeTranslation(1, 1, 1)
            polygon.applyMatrix(matrix)

            # Plane should be updated.
            expect(polygon.plane).not.toBe(originalPlane)
            expect(polygon.triangle.a.x).toBeCloseTo(1, 5)
            expect(polygon.triangle.b.x).toBeCloseTo(2, 5)
            expect(polygon.triangle.c.x).toBeCloseTo(1, 5)

        it "should handle custom normal matrix", ->

            vertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(1, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 1, 0), v3(0, 0, 1))
            ]
            polygon = new Polygon(vertices, 0)

            matrix = new Matrix4().makeTranslation(1, 1, 1)
            normalMatrix = new Matrix3().setFromMatrix4(matrix)
            polygon.applyMatrix(matrix, normalMatrix)

            expect(polygon.vertices[0].pos.x).toBeCloseTo(1, 5)

    describe "reset Method", ->

        it "should reset all state properties to defaults", ->

            vertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(1, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 1, 0), v3(0, 0, 1))
            ]
            polygon = new Polygon(vertices, 0)

            # Modify state.
            polygon.intersects = true
            polygon.state = "inside"
            polygon.previousState = "outside"
            polygon.previousStates.push("coplanar")
            polygon.valid = false
            polygon.coplanar = true
            polygon.originalValid = true
            polygon.newPolygon = true

            polygon.reset()

            expect(polygon.intersects).toBe(false)
            expect(polygon.state).toBe("undecided")
            expect(polygon.previousState).toBe("undecided")
            expect(polygon.previousStates.length).toBe(0)
            expect(polygon.valid).toBe(true)
            expect(polygon.coplanar).toBe(false)
            expect(polygon.originalValid).toBe(false)
            expect(polygon.newPolygon).toBe(false)

        it "should optionally preserve originalValid flag", ->

            vertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(1, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 1, 0), v3(0, 0, 1))
            ]
            polygon = new Polygon(vertices, 0)

            polygon.originalValid = true
            polygon.reset(false) # Don't reset originalValid

            expect(polygon.originalValid).toBe(true)

    describe "setState Method", ->

        it "should update state and maintain history", ->

            vertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(1, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 1, 0), v3(0, 0, 1))
            ]
            polygon = new Polygon(vertices, 0)

            polygon.setState("inside")

            expect(polygon.state).toBe("inside")
            expect(polygon.previousState).toBe("undecided")

            polygon.setState("outside")

            expect(polygon.state).toBe("outside")
            expect(polygon.previousState).toBe("inside")
            expect(polygon.previousStates).toContain("inside")

        it "should not change state if keepState matches current state", ->

            vertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(1, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 1, 0), v3(0, 0, 1))
            ]
            polygon = new Polygon(vertices, 0)

            polygon.setState("inside")
            polygon.setState("outside", "inside") # Should not change

            expect(polygon.state).toBe("inside")

    describe "checkAllStates Method", ->

        it "should return true when all states match", ->

            vertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(1, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 1, 0), v3(0, 0, 1))
            ]
            polygon = new Polygon(vertices, 0)

            polygon.setState("inside")
            polygon.setState("inside")
            polygon.setState("inside")

            expect(polygon.checkAllStates("inside")).toBe(true)

        it "should return false when states don't match", ->

            vertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(1, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 1, 0), v3(0, 0, 1))
            ]
            polygon = new Polygon(vertices, 0)

            polygon.setState("inside")
            polygon.setState("outside")

            expect(polygon.checkAllStates("inside")).toBe(false)

    describe "setInvalid and setValid Methods", ->

        it "should control validity flag", ->

            vertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(1, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 1, 0), v3(0, 0, 1))
            ]
            polygon = new Polygon(vertices, 0)

            expect(polygon.valid).toBe(true)

            polygon.setInvalid()
            expect(polygon.valid).toBe(false)

            polygon.setValid()
            expect(polygon.valid).toBe(true)

    describe "clone Method", ->

        it "should create exact copy with all properties", ->

            vertices = [
                vertex(v3(1, 2, 3), v3(0, 0, 1))
                vertex(v3(4, 5, 6), v3(0, 0, 1))
                vertex(v3(7, 8, 9), v3(0, 0, 1))
            ]
            original = new Polygon(vertices, 5)

            # Set some state.
            original.intersects = true
            original.state = "inside"
            original.previousState = "outside"
            original.previousStates.push("coplanar")
            original.valid = false
            original.coplanar = true
            original.originalValid = true
            original.newPolygon = true

            clone = original.clone()

            expect(clone.vertices.length).toBe(3)
            expect(clone.shared).toBe(5)
            expect(clone.intersects).toBe(true)
            expect(clone.state).toBe("inside")
            expect(clone.previousState).toBe("outside")
            expect(clone.previousStates).toEqual(["coplanar"])
            expect(clone.valid).toBe(false)
            expect(clone.coplanar).toBe(true)
            expect(clone.originalValid).toBe(true)
            expect(clone.newPolygon).toBe(true)

        it "should create independent copies", ->

            vertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(1, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 1, 0), v3(0, 0, 1))
            ]
            original = new Polygon(vertices, 0)
            clone = original.clone()

            # Modify original.
            original.vertices[0].pos.x = 999
            original.intersects = true
            original.previousStates.push("test")

            # Clone should be unaffected.
            expect(clone.vertices[0].pos.x).toBe(0)
            expect(clone.intersects).toBe(false)
            expect(clone.previousStates.length).toBe(0)

        it "should handle midpoint cloning correctly", ->

            vertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(1, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 1, 0), v3(0, 0, 1))
            ]
            original = new Polygon(vertices, 0)

            # Force midpoint calculation.
            original.getMidpoint()
            clone = original.clone()

            expect(clone.triangle.midPoint).toBeDefined()
            expect(clone.triangle.midPoint).toEqual(original.triangle.midPoint)
            expect(clone.triangle.midPoint).not.toBe(original.triangle.midPoint) # Different objects

    describe "flip Method", ->

        it "should reverse vertex order and flip normals", ->

            vertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(1, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 1, 0), v3(0, 0, 1))
            ]
            polygon = new Polygon(vertices, 0)

            originalTriangleA = polygon.triangle.a.clone()
            originalTriangleC = polygon.triangle.c.clone()
            originalNormal = polygon.vertices[0].normal.clone()

            polygon.flip()

            # Vertices should be reversed.
            expect(polygon.vertices[0].pos).toEqual(v3(0, 1, 0))
            expect(polygon.vertices[1].pos).toEqual(v3(1, 0, 0))
            expect(polygon.vertices[2].pos).toEqual(v3(0, 0, 0))

            # Triangle vertices should be swapped.
            expect(polygon.triangle.a).toEqual(originalTriangleC)
            expect(polygon.triangle.c).toEqual(originalTriangleA)

            # Normals should be flipped.
            expect(polygon.vertices[0].normal.z).toBe(-1)

    describe "delete Method", ->

        it "should clean up all resources and mark invalid", ->

            vertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(1, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 1, 0), v3(0, 0, 1))
            ]
            polygon = new Polygon(vertices, 0)

            polygon.delete()

            expect(polygon.vertices.length).toBe(0)
            expect(polygon.plane).toBeUndefined()
            expect(polygon.triangle).toBeUndefined()
            expect(polygon.shared).toBeUndefined()
            expect(polygon.valid).toBe(false)

        it "should call delete on all vertices", ->

            vertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(1, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 1, 0), v3(0, 0, 1))
            ]

            polygon = new Polygon(vertices, 0)

            # Mock delete method on the polygon's vertices (not the original ones).
            polygon.vertices.forEach (v) ->
                v.delete = jest.fn()

            polygon.delete()

            polygon.vertices.forEach (v) ->
                expect(v.delete).toHaveBeenCalled()

    describe "Edge Cases and Error Handling", ->

        it "should handle degenerate triangles gracefully", ->

            # All vertices at same position.
            vertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 0, 0), v3(0, 0, 1))
            ]

            expect(() -> new Polygon(vertices, 0)).not.toThrow()

        it "should handle large coordinate values", ->

            bigValue = 1e10
            vertices = [
                vertex(v3(bigValue, 0, 0), v3(0, 0, 1))
                vertex(v3(0, bigValue, 0), v3(0, 0, 1))
                vertex(v3(0, 0, bigValue), v3(0, 0, 1))
            ]

            polygon = new Polygon(vertices, 0)
            clone = polygon.clone()

            expect(clone.vertices[0].pos.x).toBe(bigValue)

        it "should handle empty shared data", ->

            vertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(1, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 1, 0), v3(0, 0, 1))
            ]

            polygon1 = new Polygon(vertices, null)
            polygon2 = new Polygon(vertices, undefined)

            expect(polygon1.shared).toBeNull()
            expect(polygon2.shared).toBeUndefined()

        it "should handle complex state transitions", ->

            vertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(1, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 1, 0), v3(0, 0, 1))
            ]
            polygon = new Polygon(vertices, 0)

            # Multiple state changes.
            polygon.setState("inside")
            polygon.setState("coplanar-front")
            polygon.setState("outside")
            polygon.setState("inside")

            expect(polygon.previousStates.length).toBe(3)
            expect(polygon.previousStates).toContain("inside")
            expect(polygon.previousStates).toContain("coplanar-front")
            expect(polygon.previousStates).toContain("outside")

        it "should handle matrix transformations without breaking", ->

            vertices = [
                vertex(v3(0, 0, 0), v3(0, 0, 1))
                vertex(v3(1, 0, 0), v3(0, 0, 1))
                vertex(v3(0, 1, 0), v3(0, 0, 1))
            ]
            polygon = new Polygon(vertices, 0)

            # Apply multiple transformations.
            matrix1 = new Matrix4().makeRotationZ(Math.PI / 4)
            matrix2 = new Matrix4().makeScale(2, 2, 2)
            matrix3 = new Matrix4().makeTranslation(10, 10, 10)

            expect(() -> polygon.applyMatrix(matrix1)).not.toThrow()
            expect(() -> polygon.applyMatrix(matrix2)).not.toThrow()
            expect(() -> polygon.applyMatrix(matrix3)).not.toThrow()

            expect(polygon.plane).toBeDefined()
            expect(polygon.triangle).toBeDefined()

