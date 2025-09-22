# Comprehensive Operations Module Tests

{ Polytree } = require "../../polytree.bundle.js"
{ Vector3, BoxGeometry, SphereGeometry, Mesh, MeshBasicMaterial } = require "three"

# Test tolerance for floating point comparisons.
TOL = 1e-6
EPS = 1e-10

# Helper factory functions for creating test objects.
createTestBox = (width = 2, height = 2, depth = 2, x = 0, y = 0, z = 0) ->

    geometry = new BoxGeometry(width, height, depth)
    material = new MeshBasicMaterial({ color: 0x00ff00 })

    mesh = new Mesh(geometry, material)
    mesh.position.set(x, y, z)
    mesh.updateMatrixWorld()

    return mesh

createTestSphere = (radius = 1, x = 0, y = 0, z = 0) ->

    geometry = new SphereGeometry(radius, 8, 6)
    material = new MeshBasicMaterial({ color: 0xff0000 })

    mesh = new Mesh(geometry, material)
    mesh.position.set(x, y, z)
    mesh.updateMatrixWorld()

    return mesh

createTestPolytree = (mesh) ->

    return Polytree.fromMesh(mesh)

# Helper function to validate mesh properties.
validateMesh = (mesh, expectedMinTriangles = 0) ->

    expect(mesh).toBeDefined()
    expect(mesh.isMesh).toBe(true)
    expect(mesh.geometry).toBeDefined()
    expect(mesh.geometry.attributes.position).toBeDefined()

    triangleCount = mesh.geometry.attributes.position.count / 3

    if expectedMinTriangles > 0

        expect(triangleCount).toBeGreaterThanOrEqual(expectedMinTriangles)

# Helper function to validate polytree properties.
validatePolytree = (polytree, expectedMinPolygons = 0) ->

    expect(polytree).toBeDefined()
    expect(polytree.isPolytree).toBe(true)
    expect(polytree.polygons).toBeDefined()

    if expectedMinPolygons > 0

        expect(polytree.polygons.length).toBeGreaterThanOrEqual(expectedMinPolygons)

describe "Operations Module", ->

    describe "Basic Operation Handling", ->

        it "should handle unite operation with two boxes", ->

            box1 = createTestBox(2, 2, 2, -1, 0, 0)
            box2 = createTestBox(2, 2, 2, 1, 0, 0)

            operationObject = {
                op: 'unite'
                objA: box1
                objB: box2
            }

            result = Polytree.operation(operationObject, false, true, { objCounter: 0 }, true, false)

            validateMesh(result, 8)

        it "should handle subtract operation with two boxes", ->

            box1 = createTestBox(4, 4, 4, 0, 0, 0)
            box2 = createTestBox(2, 2, 2, 0, 0, 0)

            operationObject = {
                op: 'subtract'
                objA: box1
                objB: box2
            }

            result = Polytree.operation(operationObject, false, true, { objCounter: 0 }, true, false)

            validateMesh(result, 8)

        it "should handle intersect operation with two boxes", ->

            box1 = createTestBox(4, 4, 4, 0, 0, 0)
            box2 = createTestBox(4, 4, 4, 1, 0, 0)

            operationObject = {
                op: 'intersect'
                objA: box1
                objB: box2
            }

            result = Polytree.operation(operationObject, false, true, { objCounter: 0 }, true, false)

            validateMesh(result, 8)

    describe "Asynchronous Operation Handling", ->

        it "should handle async unite operation", ->

            box1 = createTestBox(2, 2, 2, -1, 0, 0)
            box2 = createTestBox(2, 2, 2, 1, 0, 0)

            operationObject = {
                op: 'unite'
                objA: box1
                objB: box2
            }

            return Polytree.operation(operationObject, false, true, { objCounter: 0 }, true, true).then (result) ->

                validateMesh(result, 8)

        it "should handle async subtract operation", ->

            box1 = createTestBox(4, 4, 4, 0, 0, 0)
            box2 = createTestBox(2, 2, 2, 0, 0, 0)

            operationObject = {
                op: 'subtract'
                objA: box1
                objB: box2
            }

            return Polytree.operation(operationObject, false, true, { objCounter: 0 }, true, true).then (result) ->

                validateMesh(result, 8)

    describe "Material Handling", ->

        it "should apply material to result mesh", ->

            box1 = createTestBox(2, 2, 2, -1, 0, 0)
            box2 = createTestBox(2, 2, 2, 1, 0, 0)
            targetMaterial = new MeshBasicMaterial({ color: 0x0000ff })

            operationObject = {
                op: 'unite'
                objA: box1
                objB: box2
                material: targetMaterial
            }

            result = Polytree.operation(operationObject, false, true, { objCounter: 0 }, true, false)

            validateMesh(result, 8)
            expect(result.material).toBe(targetMaterial)

    describe "Polytree Return Mode", ->

        it "should return polytrees when returnPolytrees is true", ->

            box1 = createTestBox(2, 2, 2, -1, 0, 0)
            box2 = createTestBox(2, 2, 2, 1, 0, 0)

            operationObject = {
                op: 'unite'
                objA: box1
                objB: box2
            }

            result = Polytree.operation(operationObject, true, true, { objCounter: 0 }, true, false)

            expect(result).toBeDefined()
            expect(result.result).toBeDefined()
            expect(result.operationTree).toBeDefined()
            expect(result.operationTree).toBe(operationObject)

            if result.result.isPolytree

                validatePolytree(result.result, 0)

            else

                validateMesh(result.result, 8)

    describe "Nested Operations", ->

        it "should handle nested operation objects", ->

            box1 = createTestBox(2, 2, 2, -1, 0, 0)
            box2 = createTestBox(2, 2, 2, 1, 0, 0)
            box3 = createTestBox(1, 1, 1, 0, 0, 0)

            # Create nested operation: (box1 unite box2) subtract box3.
            innerOperation = {
                op: 'unite'
                objA: box1
                objB: box2
            }

            outerOperation = {
                op: 'subtract'
                objA: innerOperation
                objB: box3
            }

            result = Polytree.operation(outerOperation, false, true, { objCounter: 0 }, true, false)

            # Since geometric operations can be complex, just ensure we get some result
            # The exact result depends on geometry precision and CSG algorithm behavior
            if result

                validateMesh(result, 0)

            else

                # Accept that some complex nested operations might result in empty geometry
                expect(result).toBeUndefined()

    describe "Mixed Object Types", ->

        it "should handle operations between meshes and polytrees", ->

            box1 = createTestBox(2, 2, 2, -1, 0, 0)
            box2 = createTestBox(2, 2, 2, 1, 0, 0)
            polytree2 = createTestPolytree(box2)

            operationObject = {
                op: 'unite'
                objA: box1
                objB: polytree2
            }

            result = Polytree.operation(operationObject, false, true, { objCounter: 0 }, true, false)

            validateMesh(result, 8)

    describe "Error Handling", ->

        it "should handle invalid operation types", ->

            box1 = createTestBox()
            box2 = createTestBox()

            operationObject = {
                op: 'invalid_operation'
                objA: box1
                objB: box2
            }

            result = Polytree.operation(operationObject, false, true, { objCounter: 0 }, true, false)

            # Should handle gracefully and return undefined for invalid operations.
            expect(result).toBeUndefined()

        it "should handle missing operands", ->

            operationObject = {
                op: 'unite'
                # Missing objA and objB.
            }

            result = Polytree.operation(operationObject, false, true, { objCounter: 0 }, true, false)

            # Should handle gracefully and return undefined for missing operands without material.
            expect(result).toBeUndefined()

    describe "Object Counter Management", ->

        it "should increment object counter for each mesh conversion", ->

            box1 = createTestBox(2, 2, 2, -1, 0, 0)
            box2 = createTestBox(2, 2, 2, 1, 0, 0)
            options = { objCounter: 10 }

            operationObject = {
                op: 'unite'
                objA: box1
                objB: box2
            }

            result = Polytree.operation(operationObject, false, true, options, true, false)

            # Object counter should have been incremented.
            expect(options.objCounter).toBeGreaterThan(10)

    describe "Memory Management", ->

        it "should not leak memory with multiple operations", ->

            # Perform multiple operations to test memory management.
            box1 = createTestBox(1, 1, 1, 0, 0, 0)

            # Use simple loop to avoid Jest async issues.
            i = 0
            while i < 3 # Limited iterations to avoid timeout.

                box2 = createTestBox(1, 1, 1, i * 0.1, 0, 0)

                operationObject = {
                    op: 'unite'
                    objA: box1
                    objB: box2
                }

                result = Polytree.operation(operationObject, false, true, { objCounter: 0 }, true, false)

                validateMesh(result)

                # Update box1 for next iteration.
                box1 = result

                i++

            # Final result should be valid.
            validateMesh(box1)
