# Comprehensive Mesh Conversion Tests

{ Vector3, Vector2, Box3, BoxGeometry, SphereGeometry, PlaneGeometry, BufferGeometry, BufferAttribute, Mesh, MeshBasicMaterial } = require "three"

{ Polytree, Polygon, Vertex } = require "../../polytree.bundle.js"

# Helper factories for creating test objects.
v3 = (x, y, z) -> new Vector3(x, y, z)
v2 = (x, y) -> new Vector2(x, y)

# Create a vertex with position and normal.
createVertex = (pos, normal, uv = null, color = null) -> new Vertex(pos, normal, uv, color)

# Create a simple triangle polygon.
tri = (vertices, shared = 0) -> new Polygon(vertices, shared)

# Tolerance for floating point comparisons.
EPS = 1e-6

# Helper function to create a simple box mesh.
createBox = (width = 2, height = 2, depth = 2, x = 0, y = 0, z = 0) ->

    geometry = new BoxGeometry(width, height, depth)
    material = new MeshBasicMaterial({ color: 0x00ff00 })

    mesh = new Mesh(geometry, material)
    mesh.position.set(x, y, z)
    mesh.updateMatrixWorld()

    return mesh

# Helper function to create a simple sphere mesh.
createSphere = (radius = 1, x = 0, y = 0, z = 0) ->

    geometry = new SphereGeometry(radius, 8, 6)
    material = new MeshBasicMaterial({ color: 0x0000ff })

    mesh = new Mesh(geometry, material)
    mesh.position.set(x, y, z)
    mesh.updateMatrixWorld()

    return mesh

# Helper function to create a simple polytree.
createSimplePolytree = () ->

    polytree = new Polytree()

    # Create a simple triangle.
    vertices = [
        createVertex(v3(0, 0, 0), v3(0, 0, 1))
        createVertex(v3(1, 0, 0), v3(0, 0, 1))
        createVertex(v3(0, 1, 0), v3(0, 0, 1))
    ]

    polygon = tri(vertices, 0)
    polytree.addPolygon(polygon)

    return polytree

# Helper function to validate mesh properties.
validateMesh = (mesh, expectedMinTriangles = 0) ->

    expect(mesh).toBeDefined()
    expect(mesh.isMesh).toBe(true)
    expect(mesh.geometry).toBeDefined()
    expect(mesh.material).toBeDefined()

    # Check that geometry has vertices and faces.
    positions = mesh.geometry.attributes.position
    expect(positions).toBeDefined()
    expect(positions.array.length).toBeGreaterThanOrEqual(expectedMinTriangles * 9) # 3 vertices * 3 components

# Helper function to validate geometry properties.
validateGeometry = (geometry, expectedMinTriangles = 0) ->

    expect(geometry).toBeDefined()
    expect(geometry.isBufferGeometry).toBe(true)

    # Check required attributes.
    expect(geometry.attributes.position).toBeDefined()
    expect(geometry.attributes.normal).toBeDefined()

    positions = geometry.attributes.position
    normals = geometry.attributes.normal

    expect(positions.array.length).toBeGreaterThanOrEqual(expectedMinTriangles * 9)
    expect(normals.array.length).toBeGreaterThanOrEqual(expectedMinTriangles * 9)
    expect(positions.array.length).toBe(normals.array.length)

describe "Mesh Conversion", ->

    describe "Polytree.toGeometry", ->

        it "should convert simple polytree to BufferGeometry", ->

            polytree = createSimplePolytree()
            geometry = Polytree.toGeometry(polytree)

            validateGeometry(geometry, 1)

        it "should handle empty polytree", ->

            polytree = new Polytree()
            geometry = Polytree.toGeometry(polytree)

            expect(geometry).toBeDefined()
            expect(geometry.isBufferGeometry).toBe(true)
            expect(geometry.attributes.position.array.length).toBe(0)

        it "should preserve UV coordinates when present", ->

            polytree = new Polytree()

            # Create triangle with UV coordinates.
            vertices = [
                createVertex(v3(0, 0, 0), v3(0, 0, 1), v2(0, 0))
                createVertex(v3(1, 0, 0), v3(0, 0, 1), v2(1, 0))
                createVertex(v3(0, 1, 0), v3(0, 0, 1), v2(0, 1))
            ]

            polygon = tri(vertices, 0)
            polytree.addPolygon(polygon)

            geometry = Polytree.toGeometry(polytree)

            expect(geometry.attributes.uv).toBeDefined()
            expect(geometry.attributes.uv.array.length).toBe(6) # 3 vertices * 2 components

        it "should preserve vertex colors when present", ->

            polytree = new Polytree()

            # Create triangle with colors.
            vertices = [
                createVertex(v3(0, 0, 0), v3(0, 0, 1), null, { x: 1, y: 0, z: 0 })
                createVertex(v3(1, 0, 0), v3(0, 0, 1), null, { x: 0, y: 1, z: 0 })
                createVertex(v3(0, 1, 0), v3(0, 0, 1), null, { x: 0, y: 0, z: 1 })
            ]

            polygon = tri(vertices, 0)
            polytree.addPolygon(polygon)

            geometry = Polytree.toGeometry(polytree)

            expect(geometry.attributes.color).toBeDefined()
            expect(geometry.attributes.color.array.length).toBe(9) # 3 vertices * 3 components

        it "should handle material groups correctly", ->

            polytree = new Polytree()

            # Create triangles with different materials.
            vertices1 = [
                createVertex(v3(0, 0, 0), v3(0, 0, 1))
                createVertex(v3(1, 0, 0), v3(0, 0, 1))
                createVertex(v3(0, 1, 0), v3(0, 0, 1))
            ]

            vertices2 = [
                createVertex(v3(1, 0, 0), v3(0, 0, 1))
                createVertex(v3(2, 0, 0), v3(0, 0, 1))
                createVertex(v3(1, 1, 0), v3(0, 0, 1))
            ]

            polygon1 = tri(vertices1, 0)
            polygon2 = tri(vertices2, 1)

            polytree.addPolygon(polygon1)
            polytree.addPolygon(polygon2)

            geometry = Polytree.toGeometry(polytree)

            expect(geometry.groups).toBeDefined()
            expect(geometry.groups.length).toBeGreaterThan(0)
            expect(geometry.index).toBeDefined()

    describe "Polytree.toMesh", ->

        it "should convert polytree to complete mesh", ->

            polytree = createSimplePolytree()
            material = new MeshBasicMaterial({ color: 0xff0000 })
            mesh = Polytree.toMesh(polytree, material)

            validateMesh(mesh, 1)
            expect(mesh.material).toBe(material)

        it "should handle complex polytree with multiple polygons", ->

            polytree = new Polytree()
            material = new MeshBasicMaterial({ color: 0x00ff00 })

            # Add multiple triangles.
            for i in [0...5]

                vertices = [
                    createVertex(v3(i, 0, 0), v3(0, 0, 1))
                    createVertex(v3(i + 1, 0, 0), v3(0, 0, 1))
                    createVertex(v3(i, 1, 0), v3(0, 0, 1))
                ]

                polygon = tri(vertices, 0)
                polytree.addPolygon(polygon)

            mesh = Polytree.toMesh(polytree, material)

            validateMesh(mesh, 5)

    describe "Polytree.fromMesh", ->

        it "should convert simple box mesh to polytree", ->

            box = createBox()
            polytree = Polytree.fromMesh(box)

            expect(polytree).toBeDefined()
            expect(polytree.isPolytree).toBe(true)

            polygons = polytree.getPolygons()
            expect(polygons.length).toBeGreaterThan(0)

            # Box should have 12 triangles (6 faces * 2 triangles per face).
            expect(polygons.length).toBe(12)

        it "should convert sphere mesh to polytree", ->

            sphere = createSphere()
            polytree = Polytree.fromMesh(sphere)

            expect(polytree).toBeDefined()
            polygons = polytree.getPolygons()
            expect(polygons.length).toBeGreaterThan(0)

        it "should handle transformed meshes correctly", ->

            box = createBox(2, 2, 2, 5, 10, 15)
            polytree = Polytree.fromMesh(box)

            polygons = polytree.getPolygons()
            expect(polygons.length).toBe(12)

            # Check that transformations were applied.
            hasTransformedVertex = false

            for polygon in polygons

                for vertex in polygon.vertices

                    if vertex.pos.x > 4 or vertex.pos.y > 9 or vertex.pos.z > 14

                        hasTransformedVertex = true
                        break

                break if hasTransformedVertex

            expect(hasTransformedVertex).toBe(true)

        it "should return unchanged if object is already a polytree", ->

            existingPolytree = createSimplePolytree()
            existingPolytree.isPolytree = true

            result = Polytree.fromMesh(existingPolytree)

            expect(result).toBe(existingPolytree)

        it "should handle mesh with no geometry gracefully", ->

            mesh = new Mesh()

            expect(() -> Polytree.fromMesh(mesh)).toThrow()

        it "should preserve material indices from geometry groups", ->

            # Create geometry with multiple groups.
            geometry = new BoxGeometry(2, 2, 2)
            materials = [
                new MeshBasicMaterial({ color: 0xff0000 })
                new MeshBasicMaterial({ color: 0x00ff00 })
            ]

            # Add material groups.
            geometry.clearGroups()
            geometry.addGroup(0, 18, 0)  # First 6 triangles.
            geometry.addGroup(18, 18, 1) # Last 6 triangles.

            mesh = new Mesh(geometry, materials)
            mesh.updateMatrixWorld()

            polytree = Polytree.fromMesh(mesh)
            polygons = polytree.getPolygons()

            # Check that material indices were preserved.
            materialIndices = polygons.map((p) -> p.shared)
            expect(materialIndices).toContain(0)
            expect(materialIndices).toContain(1)

        it "should handle buildTargetPolytree parameter", ->

            box = createBox()

            # Test with buildTargetPolytree = false.
            polytree1 = Polytree.fromMesh(box, 0, new Polytree(), false)
            expect(polytree1).toBeDefined()

            # Test with buildTargetPolytree = true (default).
            polytree2 = Polytree.fromMesh(box, 0, new Polytree(), true)
            expect(polytree2).toBeDefined()

    describe "Round-trip Conversion", ->

        it "should handle polytree -> mesh -> polytree conversion", ->

            originalPolytree = createSimplePolytree()
            material = new MeshBasicMaterial({ color: 0xff0000 })

            # Convert to mesh and back.
            mesh = Polytree.toMesh(originalPolytree, material)
            newPolytree = Polytree.fromMesh(mesh)

            originalPolygons = originalPolytree.getPolygons()
            newPolygons = newPolytree.getPolygons()

            expect(newPolygons.length).toBe(originalPolygons.length)

        it "should handle mesh -> polytree -> mesh conversion", ->

            originalMesh = createBox()

            # Convert to polytree and back.
            polytree = Polytree.fromMesh(originalMesh)
            newMesh = Polytree.toMesh(polytree, originalMesh.material)

            validateMesh(newMesh, 12)

            # Check that the mesh has reasonable number of vertices (may differ due to triangulation).
            originalPositions = originalMesh.geometry.attributes.position
            newPositions = newMesh.geometry.attributes.position

            # The new mesh should have at least as many positions as triangles require.
            expect(newPositions.array.length).toBeGreaterThanOrEqual(36) # 12 triangles * 3 vertices
            expect(newPositions.array.length % 3).toBe(0) # Should be divisible by 3

    describe "Error Handling", ->

        it "should handle null or undefined inputs gracefully", ->

            expect(() -> Polytree.toGeometry(null)).toThrow()
            expect(() -> Polytree.toMesh(null, null)).toThrow()
            expect(() -> Polytree.fromMesh(null)).toThrow()

        it "should handle corrupted geometry data", ->

            mesh = createBox()

            # Corrupt the position attribute.
            mesh.geometry.attributes.position = null

            expect(() -> Polytree.fromMesh(mesh)).toThrow()

        it "should handle empty geometry", ->

            geometry = new BufferGeometry() # Create empty position and normal attributes.
            geometry.setAttribute('position', new BufferAttribute(new Float32Array(0), 3))
            geometry.setAttribute('normal', new BufferAttribute(new Float32Array(0), 3))
            material = new MeshBasicMaterial()
            mesh = new Mesh(geometry, material)

            result = Polytree.fromMesh(mesh)
            polygons = result.getPolygons()

            expect(polygons.length).toBe(0)

    describe "Performance and Edge Cases", ->

        it "should handle large polytrees efficiently", ->

            polytree = new Polytree()
            material = new MeshBasicMaterial({ color: 0x888888 })

            # Create a larger number of triangles.
            for i in [0...100]

                vertices = [
                    createVertex(v3(Math.random() * 10, Math.random() * 10, 0), v3(0, 0, 1))
                    createVertex(v3(Math.random() * 10, Math.random() * 10, 0), v3(0, 0, 1))
                    createVertex(v3(Math.random() * 10, Math.random() * 10, 0), v3(0, 0, 1))
                ]

                polygon = tri(vertices, 0)
                polytree.addPolygon(polygon)

            # This should not hang or crash.
            start = Date.now()
            mesh = Polytree.toMesh(polytree, material)
            duration = Date.now() - start

            expect(duration).toBeLessThan(5000) # Should complete within 5 seconds.
            validateMesh(mesh, 100)

        it "should handle degenerate triangles appropriately", ->

            polytree = new Polytree()

            # Create a degenerate triangle (all points collinear).
            vertices = [
                createVertex(v3(0, 0, 0), v3(0, 0, 1))
                createVertex(v3(1, 0, 0), v3(0, 0, 1))
                createVertex(v3(2, 0, 0), v3(0, 0, 1))
            ]

            polygon = tri(vertices, 0)
            polytree.addPolygon(polygon)

            # Should handle gracefully without crashing.
            expect(() -> Polytree.toGeometry(polytree)).not.toThrow()

        it "should handle meshes with very small triangles", ->

            # Create a mesh with tiny triangles.
            box = createBox(0.001, 0.001, 0.001)

            expect(() -> Polytree.fromMesh(box)).not.toThrow()

            polytree = Polytree.fromMesh(box)
            polygons = polytree.getPolygons()

            expect(polygons.length).toBe(12)

    describe "Volume Calculation", ->

        it "should calculate volume of a simple box mesh", ->

            box = createBox(2, 2, 2, 0, 0, 0)

            volume = Polytree.getVolume(box)

            # Box volume should be 2 * 2 * 2 = 8.
            expect(volume).toBe(8)

        it "should calculate volume of a box geometry directly", ->

            geometry = new BoxGeometry(4, 2, 1)

            volume = Polytree.getVolume(geometry)

            # Box volume should be 4 * 2 * 1 = 8.
            expect(volume).toBe(8)

        it "should calculate volume of a sphere mesh", ->

            sphere = createSphere(1, 0, 0, 0)

            volume = Polytree.getVolume(sphere)

            # Sphere volume should be approximately (4/3) * π * r³ = (4/3) * π * 1³ ≈ 4.189.
            # Due to sphere tessellation, we expect some deviation from the theoretical value.
            expectedVolume = (4 / 3) * Math.PI * (1 * 1 * 1)

            expect(volume).toBeGreaterThan(expectedVolume * 0.8) # At least 80% of theoretical volume.
            expect(volume).toBeLessThan(expectedVolume * 1.2)    # At most 120% of theoretical volume.

        it "should handle empty geometry", ->

            emptyGeometry = new BufferGeometry()

            volume = Polytree.getVolume(emptyGeometry)

            expect(volume).toBe(0)

        it "should handle geometry with no position attribute", ->

            geometry = new BufferGeometry()
            geometry.setAttribute("normal", new BufferAttribute(new Float32Array([0, 0, 1, 0, 0, 1, 0, 0, 1]), 3))

            volume = Polytree.getVolume(geometry)

            expect(volume).toBe(0)

        it "should throw error for invalid input", ->

            expect(() -> Polytree.getVolume(null)).toThrow()
            expect(() -> Polytree.getVolume({})).toThrow()
            expect(() -> Polytree.getVolume("invalid")).toThrow()

        it "should handle indexed geometry", ->

            # Create a simple indexed triangle.
            positions = new Float32Array([
                0, 0, 0,  # vertex 0
                1, 0, 0,  # vertex 1
                0, 1, 0   # vertex 2
            ])

            indices = new Uint16Array([0, 1, 2])

            geometry = new BufferGeometry()
            geometry.setAttribute("position", new BufferAttribute(positions, 3))
            geometry.setIndex(new BufferAttribute(indices, 1))

            volume = Polytree.getVolume(geometry)

            # This triangle forms a tetrahedron with the origin with volume = |1/6 * dot(v0, cross(v1, v2))|
            # v0 = (0,0,0), v1 = (1,0,0), v2 = (0,1,0)
            # Volume should be small but positive.
            expect(volume).toBeGreaterThanOrEqual(0)
            expect(volume).toBeLessThan(1)

        it "should handle non-indexed geometry", ->

            # Create a simple triangle without indices.
            positions = new Float32Array([
                0, 0, 0,  # vertex 0
                1, 0, 0,  # vertex 1
                0, 1, 0   # vertex 2
            ])

            geometry = new BufferGeometry()
            geometry.setAttribute("position", new BufferAttribute(positions, 3))

            volume = Polytree.getVolume(geometry)

            # Same as indexed case - volume should be small but positive.
            expect(volume).toBeGreaterThanOrEqual(0)
            expect(volume).toBeLessThan(1)
