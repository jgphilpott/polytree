# Convert a Polytree instance to a THREE.js BufferGeometry.
# This method extracts polygon data from the polytree and creates a proper
# THREE.js geometry with positions, normals, UVs, colors, and material groups.
#
# @param polytree - The Polytree instance to convert.
#
# @return THREE.js BufferGeometry ready for rendering.
Polytree.toGeometry = (polytree) ->

    groups = []
    defaultGroup = []

    uvs = undefined
    colors = undefined

    polygons = polytree.getPolygons()
    
    # Calculate the total number of triangles that will be generated.
    totalTriangles = 0
    for polygon in polygons
        totalTriangles += Math.max(0, polygon.vertices.length - 2)

    positions = createVector3Buffer(totalTriangles * 3)
    normals = createVector3Buffer(totalTriangles * 3)

    for polygon in polygons

        vertices = polygon.vertices
        verticesLen = vertices.length

        # Initialize material group array if polygon has a shared material index.
        if polygon.shared isnt undefined

            unless groups[polygon.shared]

                groups[polygon.shared] = []

        # Initialize UV and color buffers if vertices contain this data.
        if verticesLen > 0

            if vertices[0].uv isnt undefined

                uvs or= createVector2Buffer(totalTriangles * 3)

            if vertices[0].color isnt undefined

                colors or= createVector3Buffer(totalTriangles * 3)

        # Triangulate polygon by creating triangles from vertex fan.
        # Each triangle uses vertices[0] as the common vertex.
        for i in [3..verticesLen]

            # Add triangle indices to appropriate group (material-based or default).
            (if polygon.shared is undefined then defaultGroup else groups[polygon.shared]).push(positions.top / 3, (positions.top / 3) + 1, (positions.top / 3) + 2)

            # Write vertex positions for the triangle.
            positions.write(vertices[0].pos)
            positions.write(vertices[i - 2].pos)
            positions.write(vertices[i - 1].pos)

            # Write vertex normals for the triangle.
            normals.write(vertices[0].normal)
            normals.write(vertices[i - 2].normal)
            normals.write(vertices[i - 1].normal)

            # Write UV coordinates if available.
            if uvs?

                uvs.write(vertices[0].uv)
                uvs.write(vertices[i - 2].uv)
                uvs.write(vertices[i - 1].uv)

            # Write vertex colors if available.
            if colors?

                colors.write(vertices[0].color)
                colors.write(vertices[i - 2].color)
                colors.write(vertices[i - 1].color)

    geometry = new BufferGeometry() # Create THREE.js BufferGeometry and set attributes.
    geometry.setAttribute('position', new BufferAttribute(positions.array, 3))
    geometry.setAttribute('normal', new BufferAttribute(normals.array, 3))
    uvs and geometry.setAttribute('uv', new BufferAttribute(uvs.array, 2))
    colors and geometry.setAttribute('color', new BufferAttribute(colors.array, 3))

    # Set up material groups and indices for multi-material support.
    if groups.length > 0

        index = []
        groupBase = 0

        # Process each material group.
        for i in [0...groups.length]

            groups[i] = groups[i] or []
            geometry.addGroup(groupBase, groups[i].length, i)
            groupBase += groups[i].length
            index = index.concat(groups[i])

        # Add default group if it has triangles.
        if defaultGroup.length

            geometry.addGroup(groupBase, defaultGroup.length, groups.length)
            index = index.concat(defaultGroup)

        geometry.setIndex(index)

    return geometry

# Convert a Polytree instance to a complete THREE.js Mesh.
# This is a convenience method that combines geometry creation with material assignment.
#
# @param polytree - The Polytree instance to convert.
# @param toMaterial - The THREE.js material to apply to the mesh.
#
# @return THREE.js Mesh ready for scene addition.
Polytree.toMesh = (polytree, toMaterial) ->

    geometry = Polytree.toGeometry(polytree)

    return new Mesh(geometry, toMaterial)

# Convert a THREE.js Mesh to a Polytree instance.
# This method extracts geometry data from a THREE.js mesh and creates polygon objects
# for use in CSG operations. Handles material groups, transformations, and validation.
#
# @param obj - The THREE.js Mesh object to convert.
# @param objectIndex - Material index to assign to all polygons (optional).
# @param polytree - Existing Polytree to add polygons to (optional, creates new if not provided).
# @param buildTargetPolytree - Whether to build the spatial tree structure (default: true).
#
# @return Polytree instance containing the mesh data as polygons.
Polytree.fromMesh = (obj, objectIndex, polytree = new Polytree(), buildTargetPolytree = true) ->

    # Return early if object is already a Polytree.
    return obj if obj.isPolytree

    # Store original matrix world for ray intersection calculations.
    if Polytree.rayIntersectTriangleType is "regular"

        polytree.originalMatrixWorld = obj.matrixWorld.clone()

    # Update transformation matrices and extract geometry attributes.
    obj.updateWorldMatrix(true, true); geometry = obj.geometry
    temporaryMatrixWithNormalCalc.getNormalMatrix(obj.matrix)

    groups = geometry.groups
    uvattr = geometry.attributes.uv
    colorattr = geometry.attributes.color
    posattr = geometry.attributes.position
    normalattr = geometry.attributes.normal

    # Generate index array (explicit or implicit).
    index = if geometry.index then geometry.index.array else (Array((posattr.array.length / posattr.itemSize) | 0).fill().map((_, i) -> i))

    polys = [] # Process each triangle in the geometry.
    for i in [0...index.length] by 3

        vertices = []

        for j in [0...3] # Create vertices for each triangle corner.

            vertexIndex = index[i + j]
            positionIndex = vertexIndex * 3
            uvIndex = vertexIndex * 2

            # Extract and transform vertex position.
            pos = new Vector3(posattr.array[positionIndex], posattr.array[positionIndex + 1], posattr.array[positionIndex + 2])
            normal = new Vector3(normalattr.array[positionIndex], normalattr.array[positionIndex + 1], normalattr.array[positionIndex + 2])

            pos.applyMatrix4(obj.matrix)
            normal.applyMatrix3(temporaryMatrixWithNormalCalc)

            # Extract UV coordinates if available.
            uvCoords =

                if uvattr

                    { x: uvattr.array[uvIndex], y: uvattr.array[uvIndex + 1] }

                else

                    undefined

            # Extract vertex color if available.
            color =

                if colorattr

                    { x: colorattr.array[uvIndex], y: colorattr.array[uvIndex + 1], z: colorattr.array[uvIndex + 2] }

                else

                    undefined

            vertices.push(new Vertex(pos, normal, uvCoords, color))

        # Determine material index from geometry groups or use provided objectIndex.
        if (objectIndex is undefined) and groups and groups.length > 0

            polygon = undefined

            # Find which material group this triangle belongs to.
            for group in groups

                if (index[i] >= group.start) and (index[i] < (group.start + group.count))

                    polygon = new Polygon(vertices, group.materialIndex)
                    polygon.originalValid = true

            polys.push(polygon) if polygon

        else

            # Use provided objectIndex for all polygons.
            polygon = new Polygon(vertices, objectIndex)
            polygon.originalValid = true
            polys.push(polygon)

    # Add valid triangles to the polytree and clean up invalid ones.
    for i in [0...polys.length]

        if isValidTriangle(polys[i].triangle)

            polytree.addPolygon(polys[i])

        else

            polys[i].delete()

    # Build spatial tree structure if requested.
    buildTargetPolytree and polytree.buildTree()

    # Store reference to original mesh for non-ray operations.
    if Polytree.usePolytreeRay isnt true

        polytree.mesh = obj

    return polytree
