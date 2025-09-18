# Temporary variables for mesh operations
_normal1 = new Vector3()
ttvv0 = new Vector3()

# Convert a Polytree to a THREE.js BufferGeometry
Polytree.toGeometry = (polytree) ->

    polygons = polytree.getPolygons()
    triangleCount = polygons.length
    # let validPolygons = [];
    # let trianglesSet = new Set();
    # let duplicateCount = 0;

    # let triangleCount = 0;
    # polygons.forEach(polygon => {
    #     if (isUniqueTriangle(polygon.triangle, trianglesSet)) {
    #         triangleCount += (polygon.vertices.length - 2);
    #         validPolygons.push(polygon);
    #     }
    # });

    # trianglesSet.clear();
    # trianglesSet = undefined;

    positions = nbuf3(triangleCount * 3 * 3)
    normals = nbuf3(triangleCount * 3 * 3)
    uvs = undefined
    colors = undefined
    groups = []
    defaultGroup = []

    for polygon in polygons

        vertices = polygon.vertices
        verticesLen = vertices.length

        if polygon.shared isnt undefined

            unless groups[polygon.shared]

                groups[polygon.shared] = []

        if verticesLen > 0

            if vertices[0].uv isnt undefined

                uvs or= nbuf2(triangleCount * 2 * 3)

            if vertices[0].color isnt undefined

                colors or= nbuf3(triangleCount * 3 * 3)

        for i in [3..verticesLen]

            (if polygon.shared is undefined then defaultGroup else groups[polygon.shared]).push(positions.top / 3, (positions.top / 3) + 1, (positions.top / 3) + 2)
            positions.write(vertices[0].pos)
            positions.write(vertices[i - 2].pos)
            positions.write(vertices[i - 1].pos)
            normals.write(vertices[0].normal)
            normals.write(vertices[i - 2].normal)
            normals.write(vertices[i - 1].normal)

            if uvs?

                uvs.write(vertices[0].uv)
                uvs.write(vertices[i - 2].uv)
                uvs.write(vertices[i - 1].uv)

            if colors?

                colors.write(vertices[0].color)
                colors.write(vertices[i - 2].color)
                colors.write(vertices[i - 1].color)

    geometry = new BufferGeometry()
    geometry.setAttribute('position', new BufferAttribute(positions.array, 3))
    geometry.setAttribute('normal', new BufferAttribute(normals.array, 3))
    uvs and geometry.setAttribute('uv', new BufferAttribute(uvs.array, 2))
    colors and geometry.setAttribute('color', new BufferAttribute(colors.array, 3))

    if groups.length > 0

        index = []
        groupBase = 0

        for i in [0...groups.length]

            groups[i] = groups[i] or []
            geometry.addGroup(groupBase, groups[i].length, i)
            groupBase += groups[i].length
            index = index.concat(groups[i])

        if defaultGroup.length

            geometry.addGroup(groupBase, defaultGroup.length, groups.length)
            index = index.concat(defaultGroup)

        geometry.setIndex(index)

    return geometry

# Convert a Polytree to a THREE.js Mesh
Polytree.toMesh = (polytree, toMaterial) ->

    geometry = Polytree.toGeometry(polytree)
    return new Mesh(geometry, toMaterial)

# Convert a THREE.js Mesh to a Polytree
Polytree.fromMesh = (obj, objectIndex, polytree = new Polytree(), buildTargetPolytree = true) ->

    return obj if obj.isPolytree

    if Polytree.rayIntersectTriangleType is "regular"

        polytree.originalMatrixWorld = obj.matrixWorld.clone()

    obj.updateWorldMatrix(true, true)
    geometry = obj.geometry
    tmpm3.getNormalMatrix(obj.matrix)
    posattr = geometry.attributes.position
    normalattr = geometry.attributes.normal
    uvattr = geometry.attributes.uv
    colorattr = geometry.attributes.color
    groups = geometry.groups
    index = if geometry.index then geometry.index.array else (Array((posattr.array.length / posattr.itemSize) | 0).fill().map((_, i) -> i))
    polys = []

    for i in [0...index.length] by 3

        vertices = []

        for j in [0...3]

            vertexIndex = index[i + j]
            positionIndex = vertexIndex * 3
            uvIndex = vertexIndex * 2

            pos = new Vector3(posattr.array[positionIndex], posattr.array[positionIndex + 1], posattr.array[positionIndex + 2])
            normal = new Vector3(normalattr.array[positionIndex], normalattr.array[positionIndex + 1], normalattr.array[positionIndex + 2])

            pos.applyMatrix4(obj.matrix)
            normal.applyMatrix3(tmpm3)

            uvCoords =
                if uvattr
                    { x: uvattr.array[uvIndex], y: uvattr.array[uvIndex + 1] }
                else
                    undefined

            color =
                if colorattr
                    { x: colorattr.array[uvIndex], y: colorattr.array[uvIndex + 1], z: colorattr.array[uvIndex + 2] }
                else
                    undefined

            vertices.push(new Vertex(pos, normal, uvCoords, color))

        if (objectIndex is undefined) and groups and groups.length > 0

            polygon = undefined

            for group in groups

                if (index[i] >= group.start) and (index[i] < (group.start + group.count))

                    polygon = new Polygon(vertices, group.materialIndex)
                    polygon.originalValid = true

            polys.push(polygon) if polygon

        else

            polygon = new Polygon(vertices, objectIndex)
            polygon.originalValid = true
            polys.push(polygon)

    for i in [0...polys.length]

        if isValidTriangle(polys[i].triangle)

            polytree.addPolygon(polys[i])

        else

            polys[i].delete()

    buildTargetPolytree and polytree.buildTree()

    if Polytree.usePolytreeRay isnt true

        polytree.mesh = obj

    return polytree
