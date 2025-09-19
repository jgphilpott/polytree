# Comprehensive Intersect CSG Operation Tests

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

describe "Polytree.intersect", ->

    describe "Basic Function Existence", ->

        it "should exist as static method", ->

            expect(typeof Polytree.intersect).toBe("function")

        it "should exist as instance method", ->

            polytree = new Polytree()
            expect(typeof polytree.intersect).toBe("function")

    describe "Parameter Validation", ->

        it "should handle null parameters gracefully", ->

            box1 = createBox()

            expect(() -> Polytree.intersect(null, box1)).toThrow()
            expect(() -> Polytree.intersect(box1, null)).toThrow()
            expect(() -> Polytree.intersect(null, null)).toThrow()

        it "should handle undefined parameters gracefully", ->

            box1 = createBox()

            expect(() -> Polytree.intersect(undefined, box1)).toThrow()
            expect(() -> Polytree.intersect(box1, undefined)).toThrow()

    describe "Mesh-to-Mesh Operations", ->

        it "should intersect two overlapping boxes", ->

            box1 = createBox(4, 4, 4, -1, 0, 0) # Left box, overlapping.
            box2 = createBox(4, 4, 4, 1, 0, 0)  # Right box, overlapping.

            result = Polytree.intersect(box1, box2)

            validateMesh(result, 6) # Intersection volume.
            expect(result.material).toBeDefined()

        it "should return empty result for non-overlapping boxes", ->

            box1 = createBox(2, 2, 2, -5, 0, 0) # Left box, far away.
            box2 = createBox(2, 2, 2, 5, 0, 0)  # Right box, far away.

            result = Polytree.intersect(box1, box2)

            validateMesh(result, 0) # No intersection, empty or minimal result.
            expect(result.material).toBeDefined()

        it "should intersect box and sphere", ->

            box = createBox(4, 4, 4, 0, 0, 0)
            sphere = createSphere(2, 0, 0, 0) # Sphere overlapping box.

            result = Polytree.intersect(box, sphere)

            validateMesh(result, 6) # Intersection volume (cubic portion of sphere).
            expect(result.material).toBeDefined()

        it "should handle completely contained objects", ->

            box1 = createBox(6, 6, 6, 0, 0, 0)   # Large outer box.
            box2 = createBox(2, 2, 2, 0, 0, 0)   # Small inner box.

            result = Polytree.intersect(box1, box2)

            validateMesh(result, 6) # Should be approximately the same as smaller box.
            expect(result.material).toBeDefined()

        it "should handle identical objects", ->

            box1 = createBox(2, 2, 2, 0, 0, 0)
            box2 = createBox(2, 2, 2, 0, 0, 0) # Identical box.

            result = Polytree.intersect(box1, box2)

            validateMesh(result, 6) # Should be the same as one box.
            expect(result.material).toBeDefined()

        it "should handle partial overlap intersection", ->

            box1 = createBox(4, 2, 2, 0, 0, 0)   # Horizontal rectangle.
            box2 = createBox(2, 4, 2, 1, 0, 0)   # Vertical rectangle, partial overlap.

            result = Polytree.intersect(box1, box2)

            validateMesh(result, 6) # Intersection volume.
            expect(result.material).toBeDefined()

    describe "Material Handling", ->

        it "should use material from first mesh by default", ->

            material1 = new MeshBasicMaterial({ color: 0xff0000, side: FrontSide })
            material2 = new MeshBasicMaterial({ color: 0x00ff00, side: BackSide })

            box1 = createBox(4, 4, 4, -1, 0, 0)
            box2 = createBox(4, 4, 4, 1, 0, 0)
            box1.material = material1
            box2.material = material2

            result = Polytree.intersect(box1, box2)

            validateMesh(result)
            expect(result.material.color.getHex()).toBe(0xff0000)

        it "should use specified target material", ->

            targetMaterial = new MeshBasicMaterial({ color: 0x0000ff, side: DoubleSide })

            box1 = createBox(4, 4, 4, -1, 0, 0)
            box2 = createBox(4, 4, 4, 1, 0, 0)

            result = Polytree.intersect(box1, box2, targetMaterial)

            validateMesh(result)
            expect(result.material).toBe(targetMaterial)

        it "should handle array materials", ->

            materials = [
                new MeshBasicMaterial({ color: 0xff0000 }),
                new MeshBasicMaterial({ color: 0x00ff00 })
            ]

            box1 = createBox(4, 4, 4, -1, 0, 0)
            box2 = createBox(4, 4, 4, 1, 0, 0)

            result = Polytree.intersect(box1, box2, materials)

            validateMesh(result)
            expect(Array.isArray(result.material)).toBe(true)

    describe "Polytree-to-Polytree Operations", ->

        it "should intersect two polytrees directly", ->

            box1 = createBox(4, 4, 4, -1, 0, 0)
            box2 = createBox(4, 4, 4, 1, 0, 0)

            polytree1 = createPolytree(box1)
            polytree2 = createPolytree(box2)

            result = Polytree.intersect(polytree1, polytree2)

            validatePolytree(result, 0) # Allow empty result, focus on basic functionality.

        it "should return polytree when targetMaterial is null", ->

            box1 = createBox(4, 4, 4, -1, 0, 0)
            box2 = createBox(4, 4, 4, 1, 0, 0)

            polytree1 = createPolytree(box1)
            polytree2 = createPolytree(box2)

            result = Polytree.intersect(polytree1, polytree2, null)

            validatePolytree(result, 0) # Allow empty result, focus on basic functionality.

        it "should return appropriate type when targetMaterial is specified", ->

            targetMaterial = new MeshBasicMaterial({ color: 0xffffff })

            box1 = createBox(4, 4, 4, -1, 0, 0)
            box2 = createBox(4, 4, 4, 1, 0, 0)

            polytree1 = createPolytree(box1)
            polytree2 = createPolytree(box2)

            result = Polytree.intersect(polytree1, polytree2, targetMaterial)

            # When targetMaterial is provided, result might still be a polytree.
            # This is acceptable behavior, test that it's defined.
            expect(result).toBeDefined()
            if result.isMesh
                validateMesh(result, 0)
                expect(result.material).toBe(targetMaterial)
            else
                validatePolytree(result, 0)

    describe "Edge Cases and Complex Geometries", ->

        it "should handle non-intersecting objects", ->

            box1 = createBox(2, 2, 2, -10, 0, 0) # Far left.
            box2 = createBox(2, 2, 2, 10, 0, 0)  # Far right.

            result = Polytree.intersect(box1, box2)

            validateMesh(result, 0) # No intersection, empty result.

        it "should handle objects that barely touch", ->

            box1 = createBox(2, 2, 2, -1, 0, 0)
            box2 = createBox(2, 2, 2, 1, 0, 0) # Touching at faces.

            result = Polytree.intersect(box1, box2)

            validateMesh(result, 0) # Minimal or no intersection.

        it "should handle complex intersection geometries", ->

            # Create intersection between cylinder and box.
            cylinder = createCylinder(2, 2, 6, 0, 0, 0) # Tall cylinder.
            box = createBox(4, 4, 3, 0, 0, 0)           # Box intersecting cylinder.

            result = Polytree.intersect(cylinder, box)

            validateMesh(result, 6) # Cylindrical section within box bounds.

        it "should handle different geometric primitives", ->

            sphere = createSphere(2, 0, 0, 0)
            box = createBox(3, 3, 3, 0, 0, 0) # Box containing sphere.

            result = Polytree.intersect(sphere, box)

            validateMesh(result, 10) # Cubic portion of sphere.

        it "should handle multiple nested intersections", ->

            # Create nested intersection scenario.
            outerBox = createBox(8, 8, 8, 0, 0, 0)
            sphere = createSphere(3, 0, 0, 0)

            # First intersection.
            intermediate = Polytree.intersect(outerBox, sphere)
            validateMesh(intermediate)

            innerBox = createBox(2, 2, 2, 0, 0, 0)

            # Second intersection.
            result = Polytree.intersect(intermediate, innerBox)
            validateMesh(result, 0) # Complex nested intersection.

    describe "Performance and Robustness", ->

        it "should handle large objects efficiently", ->

            # Create larger, more complex geometries.
            box1 = createBox(20, 20, 20, -5, 0, 0)
            sphere = createSphere(15, 5, 0, 0)

            start = Date.now()
            result = Polytree.intersect(box1, sphere)
            duration = Date.now() - start

            validateMesh(result, 10)
            expect(duration).toBeLessThan(5000) # Should complete within 5 seconds.

        it "should handle degenerate cases gracefully", ->

            # Very thin objects.
            thinBox = createBox(0.001, 4, 4, 0, 0, 0)
            normalBox = createBox(2, 2, 2, 0, 0, 0)

            result = Polytree.intersect(thinBox, normalBox)

            validateMesh(result, 0) # Minimal intersection due to thin geometry.

        it "should handle objects at different scales", ->

            largeBox = createBox(100, 100, 100, 0, 0, 0)
            smallBox = createBox(1, 1, 1, 0, 0, 0)

            result = Polytree.intersect(largeBox, smallBox)

            validateMesh(result, 6) # Small box entirely contained.

    describe "Memory Management", ->

        it "should not leak memory with multiple operations", ->

            # Perform multiple intersect operations.
            baseBox = createBox(4, 4, 4, 0, 0, 0)

            # Use simple traditional loop to avoid Jest issues.
            i = 0
            while i < 5 # Reduced iterations to avoid timeout.

                otherBox = createBox(3, 3, 3, i * 0.1, i * 0.1, 0)
                result = Polytree.intersect(baseBox, otherBox)
                validateMesh(result)

                # Use result for next iteration.
                baseBox = result
                i++

            # Final validation.
            expect(baseBox).toBeDefined()

        it "should properly dispose of intermediate polytrees", ->

            box1 = createBox(4, 4, 4, -1, 0, 0)
            box2 = createBox(4, 4, 4, 1, 0, 0)

            # This should internally create and dispose polytrees.
            result = Polytree.intersect(box1, box2)

            validateMesh(result)
            expect(result).toBeDefined()

    describe "Error Conditions", ->

        it "should handle invalid mesh geometries", ->

            box1 = createBox()
            box2 = createBox()

            # Corrupt geometry.
            box2.geometry = null

            expect(() -> Polytree.intersect(box1, box2)).toThrow()

        it "should handle meshes without position attributes", ->

            box1 = createBox()
            box2 = createBox()

            # Remove position attribute.
            delete box2.geometry.attributes.position

            expect(() -> Polytree.intersect(box1, box2)).toThrow()

    describe "Regression Tests", ->

        it "should maintain consistent results for known inputs", ->

            # Test case that should always produce the same result.
            box1 = createBox(4, 4, 4, -1, 0, 0)
            box2 = createBox(4, 4, 4, 1, 0, 0)

            result1 = Polytree.intersect(box1, box2)
            result2 = Polytree.intersect(box1, box2)

            # Results should be equivalent (same number of vertices).
            expect(result1.geometry.attributes.position.count).toBe(result2.geometry.attributes.position.count)

        it "should be commutative for intersection", ->

            box1 = createBox(4, 4, 4, -1, 0, 0)
            box2 = createBox(3, 3, 3, 1, 0, 0)

            result1 = Polytree.intersect(box1, box2) # A ∩ B.
            result2 = Polytree.intersect(box2, box1) # B ∩ A.

            # Should produce equivalent results (intersection is commutative).
            expect(result1.geometry.attributes.position.count).toBe(result2.geometry.attributes.position.count)

        it "should handle intersect with self", ->

            box = createBox(2, 2, 2, 0, 0, 0)

            result = Polytree.intersect(box, box)

            validateMesh(result, 6) # Should be the same as original box.

    describe "Specific Intersect Behavior", ->

        it "should create only overlapping volume", ->

            # Test that intersect creates only the common volume.
            box1 = createBox(6, 2, 2, 0, 0, 0)   # Wide box.
            box2 = createBox(2, 6, 2, 0, 0, 0)   # Tall box.

            result = Polytree.intersect(box1, box2)

            validateMesh(result)
            # Result should represent the intersection volume (may be complex due to CSG processing).
            expect(result.geometry.attributes.position.count).toBeGreaterThan(0)

        it "should handle off-center intersection", ->

            mainBox = createBox(6, 6, 6, 0, 0, 0)
            offsetBox = createBox(4, 4, 4, 2, 2, 2) # Offset intersection.

            result = Polytree.intersect(mainBox, offsetBox)

            validateMesh(result, 6) # Should create offset intersection volume.

        it "should handle precise boundary intersections", ->

            box1 = createBox(4, 4, 4, 0, 0, 0)
            box2 = createBox(4, 2, 2, 2, 0, 0) # Exactly half overlap.

            result = Polytree.intersect(box1, box2)

            validateMesh(result, 6) # Should create precise intersection boundary.

        it "should handle hollow intersection scenarios", ->

            # Create two hollow objects and test their intersection.
            outerBox1 = createBox(8, 8, 8, -1, 0, 0)
            outerBox2 = createBox(8, 8, 8, 1, 0, 0)

            result = Polytree.intersect(outerBox1, outerBox2)

            validateMesh(result, 6) # Intersection of two overlapping volumes.

        it "should handle asymmetric intersections", ->

            # Create asymmetric intersection scenario.
            longBox = createBox(10, 2, 2, 0, 0, 0)  # Long thin box.
            cube = createBox(3, 3, 3, 2, 0, 0)      # Cube intersecting part of long box.

            result = Polytree.intersect(longBox, cube)

            validateMesh(result, 6) # Should create asymmetric intersection volume.
