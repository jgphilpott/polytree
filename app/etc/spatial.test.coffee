# Test spatial query utilities for enhanced Polytree functionality.

{Vector3, Plane, Box3, Sphere, Triangle, Ray, Line3, SphereGeometry, BoxGeometry, PlaneGeometry, Matrix4, Mesh, MeshBasicMaterial, BufferGeometry, BufferAttribute} = require('three')
{Polytree} = require('../../polytree.bundle.js')

# Test tolerance for floating point comparisons.
EPS = 1e-6

# Helper function to create a simple test cube mesh.
createTestCube = (size = 1) ->

    geometry = new BoxGeometry(size, size, size)
    material = new MeshBasicMaterial()
    mesh = new Mesh(geometry, material)

    return mesh

# Helper function to create a test sphere mesh.
createTestSphere = (radius = 1, segments = 8) ->

    geometry = new SphereGeometry(radius, segments, segments)
    material = new MeshBasicMaterial()
    mesh = new Mesh(geometry, material)

    return mesh

describe 'Spatial Query Utilities', ->

    describe 'closestPointToPoint', ->

        it 'should find closest point on cube surface', ->

            cube = createTestCube(2)
            targetPoint = new Vector3(3, 0, 0) # Point outside cube.

            result = Polytree.closestPointToPoint(cube, targetPoint)

            expect(result).toBeTruthy()
            expect(result.distance).toBeCloseTo(2, 5) # Distance should be ~2.
            expect(result.point.x).toBeCloseTo(1, 5) # Should be at cube face.

        it 'should work with BufferGeometry input', ->

            geometry = new BoxGeometry(2, 2, 2)
            targetPoint = new Vector3(3, 0, 0)

            result = Polytree.closestPointToPoint(geometry, targetPoint)

            expect(result).toBeTruthy()
            expect(result.distance).toBeCloseTo(2, 5)

        it 'should work with Polytree input', ->

            cube = createTestCube(2)
            polytree = Polytree.fromMesh(cube)
            targetPoint = new Vector3(3, 0, 0)

            result = Polytree.closestPointToPoint(polytree, targetPoint)

            expect(result).toBeTruthy()
            expect(result.distance).toBeCloseTo(2, 5)
            polytree.delete()

        it 'should return null for invalid inputs', ->

            result1 = Polytree.closestPointToPoint(null, new Vector3())
            result2 = Polytree.closestPointToPoint(createTestCube(), null)

            expect(result1).toBeNull()
            expect(result2).toBeNull()

        it 'should respect maximum distance constraint', ->

            cube = createTestCube(1)
            farPoint = new Vector3(10, 0, 0)

            result = Polytree.closestPointToPoint(cube, farPoint, {}, 15) # Max distance of 15 (actual distance ~9.5).

            expect(result).toBeTruthy() # Should find point within distance.

            resultTooFar = Polytree.closestPointToPoint(cube, farPoint, {}, 5) # Max distance of 5 (less than actual ~9.5).

            expect(resultTooFar).toBeNull() # Should not find point.

    describe 'distanceToPoint', ->

        it 'should calculate distance to cube surface', ->

            cube = createTestCube(2)
            testPoint = new Vector3(3, 0, 0)

            distance = Polytree.distanceToPoint(cube, testPoint)

            expect(distance).toBeCloseTo(2, 5)

        it 'should return Infinity for empty polytree', ->

            emptyPolytree = new Polytree()
            testPoint = new Vector3(1, 1, 1)

            distance = Polytree.distanceToPoint(emptyPolytree, testPoint)

            expect(distance).toBe(Infinity)
            emptyPolytree.delete()

    describe 'intersectsSphere', ->

        it 'should detect sphere intersection with cube', ->

            cube = createTestCube(2) # 2x2x2 cube centered at origin.
            intersectingSphere = new Sphere(new Vector3(1.5, 0, 0), 1) # Overlaps cube.
            missingSphere = new Sphere(new Vector3(5, 0, 0), 1) # Too far away.

            expect(Polytree.intersectsSphere(cube, intersectingSphere)).toBe(true)
            expect(Polytree.intersectsSphere(cube, missingSphere)).toBe(false)

        it 'should handle invalid inputs gracefully', ->

            cube = createTestCube()

            expect(Polytree.intersectsSphere(null, new Sphere())).toBe(false)
            expect(Polytree.intersectsSphere(cube, null)).toBe(false)

    describe 'intersectsBox', ->

        it 'should detect box intersection with cube', ->

            cube = createTestCube(2)
            intersectingBox = new Box3(new Vector3(-0.5, -0.5, -0.5), new Vector3(1.5, 1.5, 1.5))
            missingSBox = new Box3(new Vector3(5, 5, 5), new Vector3(6, 6, 6))

            expect(Polytree.intersectsBox(cube, intersectingBox)).toBe(true)
            expect(Polytree.intersectsBox(cube, missingSBox)).toBe(false)

        it 'should handle edge cases', ->

            expect(Polytree.intersectsBox(null, new Box3())).toBe(false)
            expect(Polytree.intersectsBox(createTestCube(), null)).toBe(false)

    describe 'intersectPlane', ->

        it 'should find plane intersections with cube', ->

            cube = createTestCube(2) # 2x2x2 cube.
            horizontalPlane = new Plane(new Vector3(0, 0, 1), 0) # Z=0 plane through center.

            intersections = Polytree.intersectPlane(cube, horizontalPlane)

            expect(intersections.length).toBeGreaterThan(0)

            # All intersection points should be at Z=0.
            for segment in intersections
                expect(segment.start.z).toBeCloseTo(0, 5)
                expect(segment.end.z).toBeCloseTo(0, 5)

            return

        it 'should return empty array when plane misses geometry', ->

            cube = createTestCube(1)
            farPlane = new Plane(new Vector3(1, 0, 0), -10) # Plane far from cube.

            intersections = Polytree.intersectPlane(cube, farPlane)

            expect(intersections.length).toBe(0)

        it 'should handle invalid inputs', ->

            result1 = Polytree.intersectPlane(null, new Plane())
            result2 = Polytree.intersectPlane(createTestCube(), null)

            expect(result1.length).toBe(0)
            expect(result2.length).toBe(0)

        it 'should handle vertices exactly on the plane', ->

            # Create geometry with vertices exactly on a plane.
            vertexArray = new Float32Array([
                # Triangle with one edge on Z=0 plane.
                -0.5, -0.5, 0.0,   # On plane.
                0.5, -0.5, 0.0,    # On plane.
                0.0, 0.5, -0.5,    # Below plane.
            ])

            normalArray = new Float32Array([
                0, 0, 1,  0, 0, 1,  0, 0, 1,
            ])

            geometry = new BufferGeometry()
            geometry.setAttribute('position', new BufferAttribute(vertexArray, 3))
            geometry.setAttribute('normal', new BufferAttribute(normalArray, 3))
            geometry.setIndex([0, 1, 2])
            
            mesh = new Mesh(geometry, new MeshBasicMaterial())
            plane = new Plane(new Vector3(0, 0, 1), 0) # Z=0 plane.

            intersections = Polytree.intersectPlane(mesh, plane)

            expect(intersections.length).toBe(1) # Should find one segment.
            
            # The segment should be on the Z=0 plane.
            segment = intersections[0]
            expect(segment.start.z).toBeCloseTo(0, 5)
            expect(segment.end.z).toBeCloseTo(0, 5)

            return

    describe 'sliceIntoLayers', ->

        it 'should create multiple layer slices', ->

            cube = createTestCube(2) # Height from -1 to +1
            layerHeight = 0.5

            layers = Polytree.sliceIntoLayers(cube, layerHeight, -1, 1)

            expect(layers.length).toBe(5) # Should have 5 layers: -1, -0.5, 0, 0.5, 1

            # Each layer should have intersection segments (except possibly the boundary layers).
            middleLayer = layers[2] # Z=0 layer
            expect(middleLayer.length).toBeGreaterThan(0)

        it 'should handle invalid parameters', ->

            cube = createTestCube()

            expect(Polytree.sliceIntoLayers(null, 1, 0, 1).length).toBe(0)
            expect(Polytree.sliceIntoLayers(cube, 0, 0, 1).length).toBe(0) # Zero layer height
            expect(Polytree.sliceIntoLayers(cube, 1, 1, 0).length).toBe(0) # Min > Max

        it 'should use custom normal direction', ->

            cube = createTestCube(2)
            layerHeight = 1
            customNormal = new Vector3(1, 0, 0) # Slice along X axis.

            layers = Polytree.sliceIntoLayers(cube, layerHeight, -1, 1, customNormal)

            expect(layers.length).toBe(3) # Should have 3 layers.

        it 'should handle vertices exactly on the slicing plane', ->

            # Create geometry with vertices exactly on a plane.
            vertexArray = new Float32Array([
                # Triangle 1: one edge on Z=0 plane, third vertex below.
                -0.5, -0.5, 0.0,   # Vertex on plane.
                0.5, -0.5, 0.0,    # Vertex on plane.
                0.0, 0.5, -0.5,    # Vertex below plane.
                
                # Triangle 2: one vertex on Z=0, others above and below.
                -0.5, 0.5, -0.5,   # Below plane.
                0.5, 0.5, 0.0,     # On plane.
                0.0, -0.5, 0.5,    # Above plane.
            ])

            normalArray = new Float32Array([
                0, 0, 1,  0, 0, 1,  0, 0, 1,
                0, 0, 1,  0, 0, 1,  0, 0, 1,
            ])

            geometry = new BufferGeometry()
            geometry.setAttribute('position', new BufferAttribute(vertexArray, 3))
            geometry.setAttribute('normal', new BufferAttribute(normalArray, 3))
            geometry.setIndex([0, 1, 2, 3, 4, 5])
            
            mesh = new Mesh(geometry, new MeshBasicMaterial())

            # Slice at Z=0 where vertices are exactly on the plane.
            layers = Polytree.sliceIntoLayers(mesh, 1, -0.5, 0.5)

            expect(layers.length).toBe(2) # Two layers: Z=-0.5 and Z=0.5.
            
            # The first layer at Z=-0.5 should have segments.
            expect(layers[0].length).toBeGreaterThan(0)
            
            # The second layer at Z=0.5 should have segments.
            expect(layers[1].length).toBeGreaterThan(0)

            return

    describe 'shapecast', ->

        it 'should find triangles matching custom query', ->

            cube = createTestCube(2)

            # Find triangles with at least one vertex at positive X.
            positiveXTriangles = Polytree.shapecast cube, (triangle) ->
                triangle.a.x > 0 or triangle.b.x > 0 or triangle.c.x > 0

            expect(positiveXTriangles.length).toBeGreaterThan(0)

        it 'should use collect callback when provided', ->

            cube = createTestCube(1)

            # Collect triangle centers.
            triangleCenters = Polytree.shapecast cube,
                (triangle) -> true # Accept all triangles.
                (triangle) ->
                    center = new Vector3()
                    center.add(triangle.a)
                    center.add(triangle.b)
                    center.add(triangle.c)
                    center.multiplyScalar(1/3)
                    return center

            expect(triangleCenters.length).toBeGreaterThan(0)
            expect(triangleCenters[0]).toBeInstanceOf(Vector3)

    describe 'getTrianglesNearPoint', ->

        it 'should find triangles within search radius', ->

            cube = createTestCube(2)
            centerPoint = new Vector3(0, 0, 0)

            nearTriangles = Polytree.getTrianglesNearPoint(cube, centerPoint, 2)

            expect(nearTriangles.length).toBeGreaterThan(0)

        it 'should return empty array when no triangles in range', ->

            cube = createTestCube(1)
            farPoint = new Vector3(10, 10, 10)

            nearTriangles = Polytree.getTrianglesNearPoint(cube, farPoint, 1)

            expect(nearTriangles.length).toBe(0)

        it 'should handle invalid inputs', ->

            result1 = Polytree.getTrianglesNearPoint(null, new Vector3(), 1)
            result2 = Polytree.getTrianglesNearPoint(createTestCube(), null, 1)
            result3 = Polytree.getTrianglesNearPoint(createTestCube(), new Vector3(), 0)

            expect(result1.length).toBe(0)
            expect(result2.length).toBe(0)
            expect(result3.length).toBe(0)

    describe 'estimateVolumeViaSampling', ->

        it 'should estimate cube volume approximately', ->

            cube = createTestCube(2) # Should have volume of 8.

            estimatedVolume = Polytree.estimateVolumeViaSampling(cube, 50000) # Use many samples for accuracy.

            expect(estimatedVolume).toBeGreaterThan(6) # Should be reasonably close to 8.
            expect(estimatedVolume).toBeLessThan(10)

        it 'should return zero for empty polytree', ->

            emptyPolytree = new Polytree()

            volume = Polytree.estimateVolumeViaSampling(emptyPolytree)

            expect(volume).toBe(0)
            emptyPolytree.delete()

        it 'should use provided bounding box', ->

            cube = createTestCube(1)
            customBounds = new Box3(new Vector3(-2, -2, -2), new Vector3(2, 2, 2))

            volume = Polytree.estimateVolumeViaSampling(cube, 10000, customBounds)

            # Volume should be positive but smaller due to cube being smaller than bounding box.
            expect(volume).toBeGreaterThan(0)
            expect(volume).toBeLessThan(64) # Bounding box volume.
