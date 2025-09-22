# Comprehensive Async CSG Operation Tests
# This test suite validates all asynchronous CSG operations including
# unite, subtract, intersect and their array variants.

{ Polytree } = require "../../polytree.bundle.js"
{ Vector3, Box3, BoxGeometry, SphereGeometry, CylinderGeometry, PlaneGeometry, Mesh, MeshBasicMaterial, DoubleSide, FrontSide, BackSide } = require "three"

# Test tolerance for floating point comparisons.
TOL = 1e-6
EPS = 1e-10

# Helper factory functions for creating test geometries.
createBox = (width = 2, height = 2, depth = 2, x = 0, y = 0, z = 0) ->

    geometry = new BoxGeometry(width, height, depth)
    material = new MeshBasicMaterial({ color: 0x00ff00 })

    mesh = new Mesh(geometry, material)
    mesh.position.set(x, y, z)
    mesh.updateMatrixWorld()

    return mesh

createSphere = (radius = 1, x = 0, y = 0, z = 0) ->

    geometry = new SphereGeometry(radius, 8, 6)
    material = new MeshBasicMaterial({ color: 0xff0000 })

    mesh = new Mesh(geometry, material)
    mesh.position.set(x, y, z)
    mesh.updateMatrixWorld()

    return mesh

createPolytree = (mesh) ->

    return Polytree.fromMesh(mesh)

# Helper function to validate mesh properties.
validateMesh = (mesh, expectedMinTriangles = 0) ->

    expect(mesh).toBeDefined()
    expect(mesh.isMesh).toBe(true)

    if mesh.geometry

        expect(mesh.geometry.attributes.position).toBeDefined()

        if expectedMinTriangles > 0

            triangleCount = mesh.geometry.attributes.position.count / 3
            expect(triangleCount).toBeGreaterThanOrEqual(expectedMinTriangles)

# Helper function to validate polytree properties and convert to mesh.
validatePolytreeAndMesh = (polytree, expectedMinTriangles = 0) ->

    validatePolytree(polytree)
    mesh = Polytree.toMesh(polytree)
    validateMesh(mesh, expectedMinTriangles)

    return mesh

# Helper function to validate polytree properties.
validatePolytree = (polytree) ->

    expect(polytree).toBeDefined()
    expect(polytree.getPolygons).toBeDefined()

    polygons = polytree.getPolygons()
    expect(polygons).toBeDefined()
    expect(Array.isArray(polygons)).toBe(true)

describe "Async CSG Operations", ->

    # === BASIC ASYNC OPERATIONS ===

    describe "Basic Async Operations", ->

        it "should perform async unite operation", ->

            box1 = createBox(2, 2, 2, -0.5, 0, 0)
            box2 = createBox(2, 2, 2, 0.5, 0, 0)

            polytree1 = createPolytree(box1)
            polytree2 = createPolytree(box2)

            return Polytree.async.unite(polytree1, polytree2).then (result) ->

                validatePolytreeAndMesh(result, 8)

        it "should perform async subtract operation", ->

            box1 = createBox(4, 4, 4, 0, 0, 0)
            box2 = createBox(2, 2, 2, 0, 0, 0)

            polytree1 = createPolytree(box1)
            polytree2 = createPolytree(box2)

            return Polytree.async.subtract(polytree1, polytree2).then (result) ->

                validatePolytreeAndMesh(result, 8)

        it "should perform async intersect operation", ->

            box1 = createBox(4, 4, 4, -1, 0, 0)
            box2 = createBox(4, 4, 4, 1, 0, 0)

            polytree1 = createPolytree(box1)
            polytree2 = createPolytree(box2)

            return Polytree.async.intersect(polytree1, polytree2).then (result) ->

                validatePolytreeAndMesh(result, 6)

        it "should handle errors gracefully", ->

            # Test with null polytrees to trigger error.
            return expect(Polytree.async.unite(null, null)).rejects.toBeDefined()

    # === ARRAY OPERATIONS ===

    describe "Array Operations", ->

        it "should perform async uniteArray operation", ->

            boxes = [
                createBox(2, 2, 2, -2, 0, 0)
                createBox(2, 2, 2, 0, 0, 0)
                createBox(2, 2, 2, 2, 0, 0)
            ]

            return Polytree.async.uniteArray(boxes).then (result) ->

                validatePolytreeAndMesh(result, 12)

        it "should perform async subtractArray operation", ->

            # Create base box and smaller boxes to subtract.
            baseBox = createBox(6, 6, 6, 0, 0, 0)
            subtractBoxes = [
                createBox(1, 1, 1, -1, -1, 0)
                createBox(1, 1, 1, 1, 1, 0)
            ]

            objects = [baseBox].concat(subtractBoxes)

            return Polytree.async.subtractArray(objects).then (result) ->

                validatePolytreeAndMesh(result, 8)

        it "should perform async intersectArray operation", ->

            # Create overlapping spheres.
            spheres = [
                createSphere(2, -0.5, 0, 0)
                createSphere(2, 0.5, 0, 0)
                createSphere(2, 0, 0, 0.5)
            ]

            return Polytree.async.intersectArray(spheres).then (result) ->

                validatePolytreeAndMesh(result, 4)

        it "should handle single element arrays", ->

            singleBox = [createBox(2, 2, 2, 0, 0, 0)]

            return Polytree.async.uniteArray(singleBox).then (result) ->

                validatePolytreeAndMesh(result, 6)

    # === OPERATION METHOD ===

    describe "Operation Method", ->

        it "should delegate to synchronous operation method", ->

            operationObject = {
                op: 'unite'
                objA: createBox(2, 2, 2, -0.5, 0, 0)
                objB: createBox(2, 2, 2, 0.5, 0, 0)
            }

            # The operation method should be a simple delegation.
            result = Polytree.async.operation(operationObject)

            # Result should be defined (either mesh or polytree depending on sync operation).
            expect(result).toBeDefined()
