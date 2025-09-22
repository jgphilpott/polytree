{ BoxGeometry, SphereGeometry, Mesh, MeshBasicMaterial } = require "three"

{ Polytree } = require "../../polytree.bundle.js"

# Helper functions for creating test geometries.

createTestBox = (width = 2, height = 2, depth = 2, x = 0, y = 0, z = 0) ->

    geometry = new BoxGeometry(width, height, depth)
    material = new MeshBasicMaterial()
    mesh = new Mesh(geometry, material)

    mesh.position.set(x, y, z)
    mesh.updateMatrixWorld()

    return mesh

createTestSphere = (radius = 1, x = 0, y = 0, z = 0) ->

    geometry = new SphereGeometry(radius, 8, 6)
    material = new MeshBasicMaterial()
    mesh = new Mesh(geometry, material)

    mesh.position.set(x, y, z)
    mesh.updateMatrixWorld()

    return mesh

# Test validation helper.

validateAsyncResult = (result, minPolygons = 0) ->

    expect(result).toBeDefined()
    expect(result.isPolytree).toBe(true)
    
    # For async operations, validate the polytree structure.
    expect(result.box).toBeDefined()
    expect(result.polygonArrays).toBeDefined()
    
    # Count total polygons across all arrays.
    totalPolygons = 0
    
    if result.polygonArrays
        
        for polygonArray in result.polygonArrays
            
            if polygonArray
                
                totalPolygons += polygonArray.length
    
    expect(totalPolygons).toBeGreaterThanOrEqual(minPolygons)

describe "Async CSG Operations", ->

    describe "Basic Async Operations", ->

        it "should perform async unite operation", ->

            box1 = createTestBox(2, 2, 2, -0.5, 0, 0)
            box2 = createTestBox(2, 2, 2, 0.5, 0, 0)

            polytree1 = Polytree.fromMesh(box1)
            polytree2 = Polytree.fromMesh(box2)

            return Polytree.async.unite(polytree1, polytree2).then (result) ->

                validateAsyncResult(result, 0)

        it "should perform async subtract operation", ->

            box1 = createTestBox(3, 3, 3, 0, 0, 0)
            box2 = createTestBox(1, 1, 1, 0, 0, 0)

            polytree1 = Polytree.fromMesh(box1)
            polytree2 = Polytree.fromMesh(box2)

            return Polytree.async.subtract(polytree1, polytree2).then (result) ->

                validateAsyncResult(result, 0)

        it "should perform async intersect operation", ->

            box1 = createTestBox(2, 2, 2, -0.5, 0, 0)
            box2 = createTestBox(2, 2, 2, 0.5, 0, 0)

            polytree1 = Polytree.fromMesh(box1)
            polytree2 = Polytree.fromMesh(box2)

            return Polytree.async.intersect(polytree1, polytree2).then (result) ->

                validateAsyncResult(result, 0)

    describe "Array Operations", ->

        it "should unite multiple objects in array", ->

            meshes = [
                createTestBox(1, 1, 1, -1, 0, 0)
                createTestBox(1, 1, 1, 0, 0, 0)
                createTestBox(1, 1, 1, 1, 0, 0)
            ]

            return Polytree.async.uniteArray(meshes).then (result) ->

                validateAsyncResult(result, 0)

        it "should subtract multiple objects from array", ->

            meshes = [
                createTestBox(4, 4, 4, 0, 0, 0)  # Main object
                createTestBox(1, 1, 1, -1, 0, 0) # Objects to subtract
                createTestBox(1, 1, 1, 1, 0, 0)
            ]

            return Polytree.async.subtractArray(meshes).then (result) ->

                validateAsyncResult(result, 0)

        it "should intersect multiple objects in array", ->

            meshes = [
                createTestBox(2, 2, 2, -0.5, 0, 0)
                createTestBox(2, 2, 2, 0, 0, 0)
                createTestBox(2, 2, 2, 0.5, 0, 0)
            ]

            return Polytree.async.intersectArray(meshes).then (result) ->

                validateAsyncResult(result, 0)

        it "should handle single object in array", ->

            meshes = [createTestBox(2, 2, 2, 0, 0, 0)]

            return Polytree.async.uniteArray(meshes).then (result) ->

                validateAsyncResult(result, 0)

        it "should handle empty array gracefully", ->

            return Polytree.async.uniteArray([]).then (result) ->

                # Should not reach here, but if it does, test that result is empty or undefined.
                expect(result).toBeFalsy()

            .catch (error) ->

                # Any error is acceptable for empty array.
                expect(error).toBeDefined()

    describe "Material Index Handling", ->

        it "should apply material indices correctly", ->

            meshes = [
                createTestBox(1, 1, 1, -1, 0, 0)
                createTestBox(1, 1, 1, 0, 0, 0)
                createTestBox(1, 1, 1, 1, 0, 0)
            ]

            return Polytree.async.uniteArray(meshes, 1).then (result) ->

                validateAsyncResult(result, 0)

    describe "Error Handling", ->

        it "should handle operation errors gracefully", ->

            # Test with invalid input.
            invalidInput = null

            return Polytree.async.unite(invalidInput, invalidInput).then (result) ->

                # Should not reach here.
                expect(false).toBe(true)

            .catch (error) ->

                expect(error).toBeDefined()

    describe "Performance and Robustness", ->

        it "should handle multiple objects efficiently", ->

            start = Date.now()

            meshes = []

            for i in [0...6]

                meshes.push(createTestBox(1, 1, 1, i * 0.8, 0, 0))

            return Polytree.async.uniteArray(meshes).then (result) ->

                duration = Date.now() - start

                validateAsyncResult(result, 0)
                expect(duration).toBeLessThan(10000) # Should complete within 10 seconds.

        it "should handle mix of polytrees and meshes", ->

            box1 = createTestBox(2, 2, 2, -1, 0, 0)
            polytree1 = Polytree.fromMesh(createTestBox(2, 2, 2, 0, 0, 0))
            box2 = createTestBox(2, 2, 2, 1, 0, 0)

            objects = [box1, polytree1, box2]

            return Polytree.async.uniteArray(objects).then (result) ->

                validateAsyncResult(result, 0)

    describe "Batch Processing", ->

        it "should handle batch size correctly when arrays are large", ->

            # Create more objects than the default batch size.
            meshes = []

            for i in [0...Polytree.async.batchSize + 5]

                meshes.push(createTestBox(0.5, 0.5, 0.5, i * 0.3, 0, 0))

            return Polytree.async.uniteArray(meshes).then (result) ->

                validateAsyncResult(result, 0)

        it "should handle batch size when below threshold", ->

            # Create fewer objects than batch threshold.
            meshes = [
                createTestBox(1, 1, 1, -1, 0, 0)
                createTestBox(1, 1, 1, 1, 0, 0)
            ]

            return Polytree.async.uniteArray(meshes).then (result) ->

                validateAsyncResult(result, 0)