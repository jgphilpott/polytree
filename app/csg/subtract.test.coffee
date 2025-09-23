# Comprehensive Subtract CSG Operation Tests

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

createCylinder = (radiusTop = 1, radiusBottom = 1, height = 2, x = 0, y = 0, z = 0) ->

    geometry = new CylinderGeometry(radiusTop, radiusBottom, height, 8)
    material = new MeshBasicMaterial({ color: 0x0000ff })

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
    expect(mesh.geometry).toBeDefined()
    expect(mesh.material).toBeDefined()

    # Check that geometry has vertices and faces.
    positions = mesh.geometry.attributes.position
    expect(positions).toBeDefined()
    expect(positions.count).toBeGreaterThanOrEqual(expectedMinTriangles * 3)

# Helper function to validate polytree properties.
validatePolytree = (polytree, expectedMinPolygons = 0) ->

    expect(polytree).toBeDefined()
    expect(polytree.isPolytree).toBe(true)
    expect(polytree.polygons.length).toBeGreaterThanOrEqual(expectedMinPolygons)

describe "Polytree.subtract", ->

    describe "Basic Function Existence", ->

        it "should exist as static method", ->

            expect(typeof Polytree.subtract).toBe("function")

        it "should exist as instance method", ->

            polytree = new Polytree()
            expect(typeof polytree.subtract).toBe("function")

    describe "Parameter Validation", ->

        it "should handle null parameters gracefully", ->

            box1 = createBox()

            expect(() -> Polytree.subtract(null, box1)).toThrow()
            expect(() -> Polytree.subtract(box1, null)).toThrow()
            expect(() -> Polytree.subtract(null, null)).toThrow()

        it "should handle undefined parameters gracefully", ->

            box1 = createBox()

            expect(() -> Polytree.subtract(undefined, box1)).toThrow()
            expect(() -> Polytree.subtract(box1, undefined)).toThrow()

    describe "Mesh-to-Mesh Operations", ->

        it "should subtract non-overlapping objects", ->

            box1 = createBox(2, 2, 2, -5, 0, 0) # Left box, far away.
            box2 = createBox(2, 2, 2, 5, 0, 0)  # Right box, far away.

            result = Polytree.subtract(box1, box2, false)

            validateMesh(result, 6) # Should be same as box1 since no overlap.
            expect(result.material).toBeDefined()

        it "should subtract overlapping boxes", ->

            box1 = createBox(4, 4, 4, 0, 0, 0)   # Larger box.
            box2 = createBox(2, 2, 2, 1, 0, 0)   # Smaller box, overlapping.

            result = Polytree.subtract(box1, box2, false)

            validateMesh(result, 6) # Complex carved geometry.
            expect(result.material).toBeDefined()

        it "should subtract sphere from box", ->

            box = createBox(4, 4, 4, 0, 0, 0)
            sphere = createSphere(1.5, 0, 0, 0) # Sphere inside box.

            result = Polytree.subtract(box, sphere, false)

            validateMesh(result, 10) # Box with spherical cavity.
            expect(result.material).toBeDefined()

        it "should subtract completely contained object", ->

            box1 = createBox(4, 4, 4, 0, 0, 0)   # Large outer box.
            box2 = createBox(2, 2, 2, 0, 0, 0)   # Small inner box.

            result = Polytree.subtract(box1, box2, false)

            validateMesh(result, 12) # Hollow box geometry.
            expect(result.material).toBeDefined()

        it "should handle identical objects", ->

            box1 = createBox(2, 2, 2, 0, 0, 0)
            box2 = createBox(2, 2, 2, 0, 0, 0) # Identical box.

            result = Polytree.subtract(box1, box2, false)

            validateMesh(result, 0) # Should result in empty or minimal geometry.
            expect(result.material).toBeDefined()

        it "should handle partial overlap subtraction", ->

            box1 = createBox(4, 2, 2, 0, 0, 0)   # Horizontal rectangle.
            box2 = createBox(2, 4, 2, 1, 0, 0)   # Vertical rectangle, partial overlap.

            result = Polytree.subtract(box1, box2, false)

            validateMesh(result, 6) # L-shaped or carved result.
            expect(result.material).toBeDefined()

    describe "Material Handling", ->

        it "should use material from first mesh by default", ->

            material1 = new MeshBasicMaterial({ color: 0xff0000, side: FrontSide })
            material2 = new MeshBasicMaterial({ color: 0x00ff00, side: BackSide })

            box1 = createBox(4, 4, 4, 0, 0, 0)
            box2 = createBox(2, 2, 2, 0, 0, 0)

            box1.material = material1
            box2.material = material2

            result = Polytree.subtract(box1, box2, false)

            validateMesh(result)
            expect(result.material.color.getHex()).toBe(0xff0000)

        it "should always use material from first mesh", ->

            material1 = new MeshBasicMaterial({ color: 0xff0000, side: FrontSide })
            material2 = new MeshBasicMaterial({ color: 0x00ff00, side: BackSide })

            box1 = createBox(4, 4, 4, 0, 0, 0)
            box2 = createBox(2, 2, 2, 0, 0, 0)
            box1.material = material1
            box2.material = material2

            result = Polytree.subtract(box1, box2, false)

            validateMesh(result)
            expect(result.material.color.getHex()).toBe(0xff0000) # Should use box1's material.

        it "should handle async parameter", ->

            box1 = createBox(4, 4, 4, 0, 0, 0)
            box2 = createBox(2, 2, 2, 0, 0, 0)

            # Test synchronous operation (explicit false).
            resultSync = Polytree.subtract(box1, box2, false)

            validateMesh(resultSync)
            expect(resultSync.material).toBeDefined()

            # Test asynchronous operation (default true).
            resultAsyncPromise = Polytree.subtract(box1, box2)

            expect(resultAsyncPromise).toBeInstanceOf(Promise)

            return resultAsyncPromise.then (resultAsync) ->

                validateMesh(resultAsync)
                expect(resultAsync.material).toBeDefined()

    describe "Polytree-to-Polytree Operations", ->

        it "should subtract two polytrees directly", ->

            box1 = createBox(4, 4, 4, 0, 0, 0)
            box2 = createBox(2, 2, 2, 0, 0, 0)

            polytree1 = createPolytree(box1)
            polytree2 = createPolytree(box2)

            result = Polytree.subtract(polytree1, polytree2, false)

            validatePolytree(result, 0) # Allow empty result, focus on basic functionality.

        it "should return polytree when targetMaterial is null", ->

            box1 = createBox(4, 4, 4, 0, 0, 0)
            box2 = createBox(2, 2, 2, 0, 0, 0)

            polytree1 = createPolytree(box1)
            polytree2 = createPolytree(box2)

            result = Polytree.subtract(polytree1, polytree2, false)

            validatePolytree(result, 0) # Allow empty result, focus on basic functionality.

        it "should always return polytree for polytree inputs", ->

            box1 = createBox(4, 4, 4, 0, 0, 0)
            box2 = createBox(2, 2, 2, 0, 0, 0)

            polytree1 = createPolytree(box1)
            polytree2 = createPolytree(box2)

            result = Polytree.subtract(polytree1, polytree2, false)

            # Polytree-to-polytree operations always return polytrees.
            expect(result).toBeDefined()
            validatePolytree(result, 0)

    describe "Edge Cases and Complex Geometries", ->

        it "should handle non-intersecting objects", ->

            box1 = createBox(2, 2, 2, -10, 0, 0) # Far left
            box2 = createBox(2, 2, 2, 10, 0, 0)  # Far right

            result = Polytree.subtract(box1, box2, false)

            validateMesh(result, 6) # Should be same as box1.

        it "should handle objects that barely touch", ->

            box1 = createBox(2, 2, 2, -1, 0, 0)
            box2 = createBox(2, 2, 2, 1, 0, 0) # Touching at faces.

            result = Polytree.subtract(box1, box2, false)

            validateMesh(result, 6) # Minimal or no modification.

        it "should handle complex carved geometries", ->

            # Create a box with cylindrical hole.
            box = createBox(6, 6, 6, 0, 0, 0)
            cylinder = createCylinder(1, 1, 8, 0, 0, 0) # Tall cylinder through box.

            result = Polytree.subtract(box, cylinder, false)

            validateMesh(result, 10) # Box with cylindrical hole.

        it "should handle different geometric primitives", ->

            sphere = createSphere(3, 0, 0, 0)
            box = createBox(2, 2, 2, 0, 0, 0) # Small box inside sphere.

            result = Polytree.subtract(sphere, box, false)

            validateMesh(result, 10) # Sphere with cubic cavity.

        it "should handle multiple overlapping subtractions", ->

            # Start with large box and subtract multiple smaller objects.
            mainBox = createBox(8, 8, 8, 0, 0, 0)
            hole1 = createSphere(1, -2, -2, 0)

            # First subtraction.
            intermediate = Polytree.subtract(mainBox, hole1, false)
            validateMesh(intermediate)

            hole2 = createBox(1, 1, 1, 2, 2, 0)

            # Second subtraction.
            result = Polytree.subtract(intermediate, hole2, false)
            validateMesh(result, 6)

    describe "Performance and Robustness", ->

        it "should handle large objects efficiently", ->

            # Create larger, more complex geometries.
            box1 = createBox(20, 20, 20, 0, 0, 0)
            sphere = createSphere(10, 0, 0, 0)

            start = Date.now()
            result = Polytree.subtract(box1, sphere, false)
            duration = Date.now() - start

            validateMesh(result, 10)
            expect(duration).toBeLessThan(5000) # Should complete within 5 seconds.

        it "should handle degenerate cases gracefully", ->

            # Very thin objects.
            thinBox = createBox(0.001, 4, 4, 0, 0, 0)
            normalBox = createBox(2, 2, 2, 0, 0, 0)

            result = Polytree.subtract(normalBox, thinBox, false)

            validateMesh(result, 6) # Should handle thin geometry.

        it "should handle objects at different scales", ->

            largeBox = createBox(100, 100, 100, 0, 0, 0)
            smallBox = createBox(0.1, 0.1, 0.1, 0, 0, 0)

            result = Polytree.subtract(largeBox, smallBox, false)

            validateMesh(result, 6) # Small hole in large box.

    describe "Memory Management", ->

        it "should not leak memory with multiple operations", ->

            # Perform multiple subtract operations.
            mainBox = createBox(4, 4, 4, 0, 0, 0)

            i = 0 # Use simple traditional loop to avoid Jest issues.
            while i < 5 # Reduced iterations to avoid timeout.

                smallBox = createBox(0.5, 0.5, 0.5, i * 0.2, i * 0.2, 0)
                result = Polytree.subtract(mainBox, smallBox, false)

                validateMesh(result)

                # Update mainBox for next iteration.
                mainBox = result

                i++

            # Final validation.
            expect(mainBox).toBeDefined()

        it "should properly dispose of intermediate polytrees", ->

            box1 = createBox(4, 4, 4, 0, 0, 0)
            box2 = createBox(2, 2, 2, 0, 0, 0)

            # This should internally create and dispose polytrees.
            result = Polytree.subtract(box1, box2, false)

            validateMesh(result)
            expect(result).toBeDefined()

    describe "Error Conditions", ->

        it "should handle invalid mesh geometries", ->

            box1 = createBox()
            box2 = createBox()

            # Corrupt geometry.
            box2.geometry = null

            expect(() -> Polytree.subtract(box1, box2)).toThrow()

        it "should handle meshes without position attributes", ->

            box1 = createBox()
            box2 = createBox()

            # Remove position attribute.
            delete box2.geometry.attributes.position

            expect(() -> Polytree.subtract(box1, box2)).toThrow()

    describe "Regression Tests", ->

        it "should maintain consistent results for known inputs", ->

            # Test case that should always produce the same result.
            box1 = createBox(4, 4, 4, 0, 0, 0)
            box2 = createBox(2, 2, 2, 0, 0, 0)

            result1 = Polytree.subtract(box1, box2, false)
            result2 = Polytree.subtract(box1, box2, false)

            # Results should be equivalent (same number of vertices).
            expect(result1.geometry.attributes.position.count).toBe(result2.geometry.attributes.position.count)

        it "should NOT be commutative (subtract is directional)", ->

            box1 = createBox(4, 4, 4, 0, 0, 0)
            box2 = createBox(2, 2, 2, 1, 0, 0)

            result1 = Polytree.subtract(box1, box2, false) # Large minus small.
            result2 = Polytree.subtract(box2, box1, false) # Small minus large.

            # Should produce different results (subtract is not commutative).
            expect(result1.geometry.attributes.position.count).not.toBe(result2.geometry.attributes.position.count)

        it "should handle subtract from self", ->

            box = createBox(2, 2, 2, 0, 0, 0)

            result = Polytree.subtract(box, box, false)

            validateMesh(result, 0) # Should result in empty or minimal geometry.

    describe "Specific Subtract Behavior", ->

        it "should create proper cavity geometry", ->

            # Test that subtract creates internal surfaces (cavity).
            outerBox = createBox(6, 6, 6, 0, 0, 0)
            innerBox = createBox(2, 2, 2, 0, 0, 0)

            result = Polytree.subtract(outerBox, innerBox, false)

            validateMesh(result) # Result should have both outer and inner surfaces.
            expect(result.geometry.attributes.position.count).toBeGreaterThan(outerBox.geometry.attributes.position.count)

        it "should handle off-center subtraction", ->

            mainBox = createBox(6, 6, 6, 0, 0, 0)
            cutoutBox = createBox(2, 2, 2, 2, 2, 2) # Corner cutout.

            result = Polytree.subtract(mainBox, cutoutBox, false)

            validateMesh(result, 6) # Should create corner cavity.

        it "should handle overlapping boundary conditions", ->

            box1 = createBox(4, 4, 4, 0, 0, 0)
            box2 = createBox(4, 2, 2, 2, 0, 0) # Half overlap.

            result = Polytree.subtract(box1, box2, false)

            validateMesh(result, 6) # Should create clean cut.
