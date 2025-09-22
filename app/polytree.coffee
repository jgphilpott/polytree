class Polytree

    # ----- Prototype Properties -----

    @::isPolytree = true

    # ----- Static Properties -----

    @maxLevel = 16
    @polygonsPerTree = 100

    @usePolytreeRay = true
    @disposePolytree = true
    @useWindingNumber = false

    @rayIntersectTriangleType = "MollerTrumbore"

    # ----- Static Methods -----

    @operation = operationHandler
    @rayIntersectsTriangle = testRayTriangleIntersection

    # Main constructor for creating Polytree nodes.
    # Initializes core properties and sets up polygon array management.

    # @param box - Optional bounding box for this tree node (used internally for octree subdivision).
    # @param parent - Optional parent Polytree node (used internally, null for root).
    constructor: (box = null, parent = null) ->

        # Core geometric data.
        @box = box                                # Bounding box for spatial partitioning.
        @polygons = []                            # Primary polygon storage for this node.
        @replacedPolygons = []                    # Temporary storage for replaced polygons during operations.

        # Tree structure properties.
        @parent = parent                          # Reference to parent node (null for root).
        @subTrees = []                            # Child Polytree nodes for octree subdivision.
        @level = 0                                # Depth level in octree hierarchy.

        # Mesh and Matrix transformation data.
        @originalMatrixWorld                      # Original world transformation matrix.
        @mesh                                     # Reference to Three.js mesh object.

        # Polygon array management for root node.
        @polygonArrays = undefined                # Collection of all polygon arrays (root node only).
        @addPolygonsArrayToRoot(@polygons)

    # === SMALL HELPERS AND GETTERS/SETTERS ===

    isEmpty: -> # Check if this tree node contains any polygons.

        @polygons.length is 0

    getMesh: -> # Get the Three.js mesh associated with this Polytree (traverses to root).

        visited = new Set()
        current = this

        while current and not visited.has(current)

            visited.add(current)

            if not current.parent

                return current.mesh ? null

            current = current.parent

        return null # Circular reference or no mesh found.

    newPolytree: (box, parent) -> # Create a new Polytree node with given parameters.

        new @constructor(box, parent)

    setPolygonIndex: (index) -> # Set polygon material index for all polygons in this tree.

        return if index is undefined

        if @polygonArrays

            @polygonArrays.forEach (polygonsArray) ->

                if polygonsArray?.length

                    polygonsArray.forEach (polygon) -> polygon.shared = index

    # === OBJECT CREATION AND COPYING ===

    clone: -> # Creates a deep copy of this Polytree.

        (new @constructor()).copy(this)

    copy: (source) -> # Copy data from another Polytree instance.

        return this unless source

        @deletePolygonsArrayFromRoot(@polygons)
        @polygons = if source.polygons then source.polygons.map((polygon) -> polygon.clone()) else []
        @addPolygonsArrayToRoot(@polygons)
        @replacedPolygons = if source.replacedPolygons then source.replacedPolygons.map((polygon) -> polygon.clone()) else []

        if source.mesh

            @mesh = source.mesh

        if source.originalMatrixWorld

            @originalMatrixWorld = source.originalMatrixWorld.clone()

        @box = if source.box then source.box.clone() else null
        @level = source.level ? 0

        if source.subTrees

            for i in [0...source.subTrees.length]

                subTree = new @constructor(undefined, this).copy(source.subTrees[i])
                @subTrees.push(subTree)

        return this

    # === CSG OPERATIONS (INSTANCE METHODS) ===

    # Perform union operation (combines both meshes).
    unite: (mesh1, mesh2, targetMaterial = null) ->

        Polytree.unite(mesh1, mesh2, targetMaterial)

    # Perform subtraction operation (mesh1 minus mesh2).
    subtract: (mesh1, mesh2, targetMaterial = null) ->

        Polytree.subtract(mesh1, mesh2, targetMaterial)

    # Perform intersection operation (keep only overlapping volume).
    intersect: (mesh1, mesh2, targetMaterial = null) ->

        Polytree.intersect(mesh1, mesh2, targetMaterial)

    # === POLYGON ARRAY MANAGEMENT ===

    # Add polygon array to root node's collection (internal helper).
    addPolygonsArrayToRoot: (array) ->

        if @parent

            @parent.addPolygonsArrayToRoot(array)

        else

            if @polygonArrays is undefined

                @polygonArrays = []

            @polygonArrays.push(array)

    # Remove polygon array from root node's collection (internal helper).
    deletePolygonsArrayFromRoot: (array) ->

        if @parent

            @parent.deletePolygonsArrayFromRoot(array)

        else

            index = @polygonArrays.indexOf(array)

            if index > -1

                @polygonArrays.splice(index, 1)

    # === CORE POLYGON OPERATIONS ===

    # Add a polygon to this tree node with spatial bounds calculation.
    addPolygon: (polygon, trianglesSet) ->

        unless @bounds

            @bounds = new Box3()

        triangle = polygon.triangle

        if trianglesSet and not isUniqueTriangle(triangle, trianglesSet)

            return this

        # Expand bounds to include all triangle vertices.
        @bounds.expandByPoint(triangle.a)
        @bounds.expandByPoint(triangle.b)
        @bounds.expandByPoint(triangle.c)

        @polygons.push(polygon)

        return this

    calcBox: -> # Calculate and set bounding box from polygon bounds.

        unless @bounds

            @bounds = new Box3()

        @box = @bounds.clone()

        offset = 0.001 # Offset small amount to guarantee that all polygons (even those with vertices exactly on the box boundary) are included in queries.

        @box.min.x -= offset
        @box.min.y -= offset
        @box.min.z -= offset

        @box.max.x += offset
        @box.max.y += offset
        @box.max.z += offset

        return this

    # === TREE CONSTRUCTION AND SPATIAL PARTITIONING ===

    # Split this node into 8 octree children based on spatial subdivision.
    # This creates an octree by recursively subdividing space until polygon density is acceptable.
    split: (level) ->

        subTrees = []

        return this unless @box

        halfSize = temporaryVector3Secondary.copy(@box.max).sub(@box.min).multiplyScalar(0.5)

        # Create 8 child boxes in a 2x2x2 grid.
        for x in [0..1]

            for y in [0..1]

                for z in [0..1]

                    box = new Box3()

                    vectorPosition = temporaryVector3Primary.set(x, y, z)

                    box.min.copy(@box.min).add(vectorPosition.multiply(halfSize))
                    box.max.copy(box.min).add(halfSize)
                    box.expandByScalar(GEOMETRIC_EPSILON)
                    subTrees.push(@newPolytree(box, this))

        # Redistribute polygons to appropriate child nodes based on midpoint.
        polygon = undefined

        while polygon = @polygons.pop()

            found = false

            for i in [0...subTrees.length]

                if subTrees[i].box.containsPoint(polygon.getMidpoint())

                    subTrees[i].polygons.push(polygon)

                    found = true

            unless found

                throw new Error("Unable to find subtree for triangle at level #{level}.")

        # Recursively split child nodes if they exceed polygon threshold.
        for i in [0...subTrees.length]

            subTrees[i].level = level + 1
            len = subTrees[i].polygons.length

            # Continue subdivision if polygon count exceeds threshold and max depth not reached.
            if len > Polytree.polygonsPerTree and level < Polytree.maxLevel

                subTrees[i].split(level + 1)

            @subTrees.push(subTrees[i])

        return this

    buildTree: -> # Build complete octree structure from polygon data.

        @calcBox()
        @split(0)
        @processTree()

        return this

    # Process tree nodes to update bounding boxes after polygon distribution.
    processTree: ->

        unless @isEmpty()

            temporaryBoundingBox.copy(@box)

            for i in [0...@polygons.length]

                @box.expandByPoint(@polygons[i].triangle.a)
                @box.expandByPoint(@polygons[i].triangle.b)
                @box.expandByPoint(@polygons[i].triangle.c)

            @expandParentBox()

        for i in [0...@subTrees.length]

            @subTrees[i].processTree()

    # Recursively expand parent bounding boxes up the tree hierarchy.
    expandParentBox: (visited = new Set()) ->

        if @parent and not visited.has(@parent)

            visited.add(@parent)
            @parent.box.expandByPoint(@box.min)
            @parent.box.expandByPoint(@box.max)
            @parent.expandParentBox(visited)

    # === POLYGON QUERIES AND INTERSECTION TESTING ===

    # Find all polygons that intersect with a target polygon using spatial partitioning.
    getPolygonsIntersectingPolygon: (targetPolygon, polygons = []) ->

        if @box.intersectsTriangle(targetPolygon.triangle)

            if @polygons.length > 0

                allPolygons = @polygons.slice()

                if @replacedPolygons.length > 0

                    for i in [0...@replacedPolygons.length]

                        allPolygons.push(@replacedPolygons[i])

                for i in [0...allPolygons.length]

                    polygon = allPolygons[i]

                    unless polygon.originalValid and polygon.valid and polygon.intersects

                        continue

                    if triangleIntersectsTriangle(targetPolygon.triangle, polygon.triangle)

                        polygons.push(polygon)

        for i in [0...@subTrees.length]

            @subTrees[i].getPolygonsIntersectingPolygon(targetPolygon, polygons)

        return polygons

    # Collect polygons that intersect with a ray for raycasting operations.
    getRayPolygons: (ray, polygons = []) ->

        if @polygons.length > 0

            for i in [0...@polygons.length]

                if @polygons[i].valid and @polygons[i].originalValid

                    if polygons.indexOf(@polygons[i]) is -1

                        polygons.push(@polygons[i])

        if @replacedPolygons.length > 0

            polygons.push(...@replacedPolygons)

        for i in [0...@subTrees.length]

            if ray.intersectsBox(@subTrees[i].box)

                @subTrees[i].getRayPolygons(ray, polygons)

        return polygons

    # Perform ray intersection testing against all polygons in the tree.
    # Returns array of intersection results sorted by distance.
    rayIntersect: (ray, matrixWorld, intersects = []) ->

        return [] if ray.direction.length() is 0

        distance = 1e100
        polygons = @getRayPolygons(ray)

        for i in [0...polygons.length]

            result = undefined

            if Polytree.rayIntersectTriangleType is "regular"

                result = ray.intersectTriangle(polygons[i].triangle.a, polygons[i].triangle.b, polygons[i].triangle.c, false, temporaryVector3Primary)

                if result

                    temporaryVector3Primary.applyMatrix4(matrixWorld)
                    distance = temporaryVector3Primary.distanceTo(ray.origin)

                    if distance < 0 or distance > Infinity

                        console.warn("[rayIntersect] Failed ray distance check.", ray)

                    else

                        intersects.push({ distance: distance, polygon: polygons[i], position: temporaryVector3Primary.clone() })

            else

                result = testRayTriangleIntersection(ray, polygons[i].triangle, temporaryVector3Primary)

                if result

                    newDistance = result.clone().sub(ray.origin).length()

                    if distance > newDistance

                        distance = newDistance

                    if distance < 1e100

                        intersects.push({ distance: distance, polygon: polygons[i], position: result.clone().add(ray.origin) })

        intersects.length and intersects.sort(sortRaycastIntersectionsByDistance)

        return intersects

    # Get all polygons marked as intersecting from polygon arrays.
    getIntersectingPolygons: (polygons = []) ->

        @polygonArrays.forEach (polygonsArray) ->

            if polygonsArray.length

                for i in [0...polygonsArray.length]

                    if polygonsArray[i].valid and polygonsArray[i].intersects

                        polygons.push(polygonsArray[i])

        return polygons

    # Get all valid polygons from all polygon arrays in this tree.
    getPolygons: (polygons = []) ->

        @polygonArrays.forEach (polygonsArray) ->

            if polygonsArray.length

                for i in [0...polygonsArray.length]

                    if polygonsArray[i].valid

                        if polygons.indexOf(polygonsArray[i]) is -1

                            polygons.push(polygonsArray[i])

        return polygons

    # Extract triangles from all valid polygons in the tree.
    # This provides triangle data format as complement to getPolygons().
    getTriangles: (triangles = []) ->

        polygons = @getPolygons()
        polygons.forEach (polygon) -> triangles.push(polygon.triangle)

        return triangles

    # Extract triangles from polygons that intersect with a ray.
    # This provides triangle data format as complement to getRayPolygons().
    getRayTriangles: (ray, triangles = []) ->

        polygons = @getRayPolygons(ray)
        polygons.forEach (polygon) -> triangles.push(polygon.triangle)

        return triangles

    # Invert all polygons by flipping their face normals.
    invert: ->

        @polygonArrays.forEach (polygonsArray) ->

            if polygonsArray.length

                polygonsArray.forEach (polygon) -> polygon.flip()

    # === POLYGON MODIFICATION AND STATE MANAGEMENT ===

    # Replace a polygon with one or more new polygons during CSG operations.
    replacePolygon: (polygon, newPolygons) ->

        unless Array.isArray(newPolygons)

            newPolygons = [newPolygons]

        if @polygons.length > 0

            polygonIndex = @polygons.indexOf(polygon)

            if polygonIndex > -1

                if polygon.originalValid is true

                    @replacedPolygons.push(polygon)

                else

                    polygon.setInvalid()

                @polygons.splice(polygonIndex, 1, ...newPolygons)

        for i in [0...@subTrees.length]

            @subTrees[i].replacePolygon(polygon, newPolygons)

    # === COMPLEX CSG OPERATIONS AND STATE MANAGEMENT ===

    # Delete polygons based on complex state rules for CSG operations.
    # This implements the polygon classification logic for boolean operations.
    deletePolygonsByStateRules: (rulesArr, firstRun = true) ->

        @polygonArrays.forEach (polygonsArray) ->

            if polygonsArray.length

                polygonArr = polygonsArray.filter (polygon) -> (polygon.valid == true) and (polygon.intersects == true)

                polygonArr.forEach (polygon) ->

                    found = false

                    for j in [0...rulesArr.length]

                        if rulesArr[j].array

                            states = rulesArr[j].rule

                            if (states.includes(polygon.state)) and (((polygon.previousState isnt "undecided") and (states.includes(polygon.previousState))) or (polygon.previousState is "undecided"))

                                found = true

                                statesObj = {}
                                mainStatesObj = {}

                                states.forEach (state) -> statesObj[state] = false
                                states.forEach (state) -> mainStatesObj[state] = false

                                statesObj[polygon.state] = true

                                for i in [0...polygon.previousStates.length]

                                    unless states.includes(polygon.previousStates[i])

                                        found = false

                                        break

                                    else

                                        statesObj[polygon.previousStates[i]] = true

                                if found

                                    for state of statesObj

                                        if statesObj[state] is false

                                            found = false

                                            break

                                    if found

                                        break

                        else

                            if polygon.checkAllStates(rulesArr[j].rule)

                                found = true

                                break

                    if found

                        polygonIndex = polygonsArray.indexOf(polygon)

                        if polygonIndex > -1

                            polygon.setInvalid()
                            polygonsArray.splice(polygonIndex, 1)

                        if firstRun

                            polygon.delete()

    # Delete polygons based on their intersection status (simpler filtering).
    deletePolygonsByIntersection: (intersects, firstRun = true) ->

        return if intersects == undefined

        @polygonArrays.forEach (polygonsArray) ->

            if polygonsArray.length

                polygonArr = polygonsArray.slice()

                polygonArr.forEach (polygon) ->

                    if polygon.valid

                        if polygon.intersects == intersects

                            polygonIndex = polygonsArray.indexOf(polygon)

                            if polygonIndex > -1

                                polygon.setInvalid()
                                polygonsArray.splice(polygonIndex, 1)

                            if firstRun

                                polygon.delete()

    # Check if a polygon intersects with this tree's bounding box.
    isPolygonIntersecting: (polygon) ->

        unless @box.intersectsTriangle(polygon.triangle)

            return false

        return true

    # Mark polygons as intersecting with target polytree.
    markIntesectingPolygons: (targetPolytree) ->

        @polygonArrays.forEach (polygonsArray) ->

            if polygonsArray.length

                polygonsArray.forEach (polygon) ->

                    polygon.intersects = targetPolytree.isPolygonIntersecting(polygon)

    # Reset polygon states for CSG operation preparation.
    resetPolygons: (resetOriginal = true) ->

        @polygonArrays.forEach (polygonsArray) ->

            if polygonsArray.length

                polygonsArray.forEach (polygon) ->

                    polygon.reset(resetOriginal)

    # Complex CSG intersection handling - splits and classifies polygons.
    # This is the core method for polygon classification in boolean operations.
    handleIntersectingPolygons: (targetPolytree, targetPolytreeBuffer) ->

        if @polygons.length > 0

            polygonStack = @polygons.filter (polygon) -> (polygon.valid == true) and (polygon.intersects == true) and (polygon.state == "undecided")
            currentPolygon = polygonStack.pop()

            while currentPolygon

                if currentPolygon.state isnt "undecided"

                    continue

                unless currentPolygon.valid

                    continue

                targetPolygons = targetPolytree.getPolygonsIntersectingPolygon(currentPolygon)

                if targetPolygons.length > 0

                    for j in [0...targetPolygons.length]

                        target = targetPolygons[j]
                        splitResults = splitPolygonByPlane(currentPolygon, target.plane)

                        if splitResults.length > 1

                            for i in [0...splitResults.length]

                                polygon = splitResults[i].polygon
                                polygon.intersects = currentPolygon.intersects
                                polygon.newPolygon = true
                                polygonStack.push(polygon)

                            @replacePolygon(currentPolygon, splitResults.map((result) -> result.polygon))

                            break

                        else

                            if currentPolygon.id isnt splitResults[0].polygon.id

                                splitResults[0].polygon.intersects = currentPolygon.intersects
                                splitResults[0].polygon.newPolygon = true
                                polygonStack.push(splitResults[0].polygon)
                                @replacePolygon(currentPolygon, splitResults[0].polygon)

                                break

                            else

                                if (splitResults[0].type == "coplanar-front") or (splitResults[0].type == "coplanar-back")

                                    currentPolygon.setState(splitResults[0].type)
                                    currentPolygon.coplanar = true

                currentPolygon = polygonStack.pop()

            polygonStack = @polygons.filter (polygon) -> (polygon.valid == true) and (polygon.intersects == true)
            currentPolygon = polygonStack.pop()
            inside = false

            while currentPolygon

                unless currentPolygon.valid

                    continue

                inside = false

                if targetPolytree.box.containsPoint(currentPolygon.getMidpoint())

                    if Polytree.useWindingNumber is true

                        inside = testPolygonInsideUsingWindingNumber(targetPolytreeBuffer, currentPolygon.getMidpoint(), currentPolygon.coplanar)

                    else

                        point = roundPointCoordinates(temporaryVector3Secondary.copy(currentPolygon.getMidpoint()))

                        if Polytree.usePolytreeRay isnt true and targetPolytree.mesh

                            defaultRayDirection.copy(currentPolygon.plane.normal)
                            temporaryRaycaster.set(point, defaultRayDirection)
                            intersects = temporaryRaycaster.intersectObject(targetPolytree.mesh)

                            if intersects.length

                                if defaultRayDirection.dot(intersects[0].face.normal) > 0

                                    inside = true

                            unless inside or not currentPolygon.coplanar

                                for j in [0...windingNumberEpsilonOffsetsCount]

                                    temporaryRaycaster.ray.origin.copy(point).add(windingNumberEpsilonOffsets[j])
                                    intersects = temporaryRaycaster.intersectObject(targetPolytree.mesh)

                                    if intersects.length

                                        if defaultRayDirection.dot(intersects[0].face.normal) > 0

                                            inside = true

                                            break

                        else

                            temporaryRay.origin.copy(point)
                            defaultRayDirection.copy(currentPolygon.plane.normal)
                            temporaryRay.direction.copy(currentPolygon.plane.normal)
                            intersects = targetPolytree.rayIntersect(temporaryRay, targetPolytree.originalMatrixWorld)

                            if intersects.length

                                if defaultRayDirection.dot(intersects[0].polygon.plane.normal) > 0

                                    inside = true

                            unless inside or not currentPolygon.coplanar

                                for j in [0...windingNumberEpsilonOffsetsCount]

                                    temporaryRay.origin.copy(point).add(windingNumberEpsilonOffsets[j])
                                    defaultRayDirection.copy(currentPolygon.plane.normal)
                                    temporaryRay.direction.copy(currentPolygon.plane.normal)
                                    intersects = targetPolytree.rayIntersect(temporaryRay, targetPolytree.originalMatrixWorld)

                                    if intersects.length

                                        if defaultRayDirection.dot(intersects[0].polygon.plane.normal) > 0

                                            inside = true

                                            break

                if inside is true

                    currentPolygon.setState("inside")

                else

                    currentPolygon.setState("outside")

                currentPolygon = polygonStack.pop()

        for i in [0...@subTrees.length]

            @subTrees[i].handleIntersectingPolygons(targetPolytree, targetPolytreeBuffer)

    # Apply transformation matrix to all polygons in this tree.
    applyMatrix: (matrix, normalMatrix, firstRun = true) ->

        if matrix.isMesh

            matrix.updateMatrix()
            matrix = matrix.matrix

        if @box

            @box.makeEmpty()

        normalMatrix = normalMatrix or temporaryMatrixWithNormalCalc.getNormalMatrix(matrix)

        if @polygons.length > 0

            for i in [0...@polygons.length]

                if @polygons[i].valid

                    @polygons[i].applyMatrix(matrix, normalMatrix)

        for i in [0...@subTrees.length]

            @subTrees[i].applyMatrix(matrix, normalMatrix, false)

        if firstRun

            @processTree()

    # === CLEANUP AND DISPOSAL METHODS ===

    # Clean up replaced polygons from CSG operations.
    deleteReplacedPolygons: ->

        if @replacedPolygons.length > 0

            @replacedPolygons.forEach (polygon) -> polygon.delete()
            @replacedPolygons.length = 0

        for i in [0...@subTrees.length]

            @subTrees[i].deleteReplacedPolygons()

    # Mark all polygons as original (not generated by CSG operations).
    markPolygonsAsOriginal: ->

        @polygonArrays.forEach (polygonsArray) ->

            if polygonsArray.length

                polygonsArray.forEach (polygon) -> polygon.originalValid = true

    # Get polygon clones via callback for CSG operations.
    getPolygonCloneCallback: (cbFunc, trianglesSet) ->

        @polygonArrays.forEach (polygonsArray) ->

            if polygonsArray.length

                for i in [0...polygonsArray.length]

                    if polygonsArray[i].valid

                        cbFunc(polygonsArray[i].clone(), trianglesSet)

    # === ADVANCED COLLISION DETECTION ===

    # Test intersection between a sphere and a triangle.
    # Returns intersection data or false if no intersection.
    #
    # @param sphere - Sphere object with center and radius properties.
    # @param triangle - Triangle object with a, b, c vertex properties.
    #
    # @return Object with normal, point, depth properties or false if no intersection.
    triangleSphereIntersect: (sphere, triangle) ->

        # Create temporary objects for calculations.
        temporaryVector1 = new Vector3()
        temporaryVector2 = new Vector3()
        temporaryLine = new Line3()
        trianglePlane = new ThreePlane()

        triangle.getPlane(trianglePlane)

        return false unless sphere.intersectsPlane(trianglePlane)

        intersectionDepth = Math.abs(trianglePlane.distanceToSphere(sphere))
        radiusSquared = sphere.radius * sphere.radius - intersectionDepth * intersectionDepth

        planePoint = trianglePlane.projectPoint(sphere.center, temporaryVector1)

        if triangle.containsPoint(sphere.center)

            return

                depth: Math.abs(trianglePlane.distanceToSphere(sphere))
                normal: trianglePlane.normal.clone()
                point: planePoint.clone()

        triangleEdges = [
            [triangle.a, triangle.b]
            [triangle.b, triangle.c]
            [triangle.c, triangle.a]
        ]

        for i in [0...triangleEdges.length]

            temporaryLine.set(triangleEdges[i][0], triangleEdges[i][1])
            temporaryLine.closestPointToPoint(planePoint, true, temporaryVector2)

            distanceSquared = temporaryVector2.distanceToSquared(sphere.center)

            if distanceSquared < radiusSquared

                return

                    depth: sphere.radius - Math.sqrt(distanceSquared)
                    normal: sphere.center.clone().sub(temporaryVector2).normalize()
                    point: temporaryVector2.clone()

        return false

    # Collect triangles that intersect with a sphere using spatial partitioning.
    # This method recursively traverses the octree to find relevant triangles.
    #
    # @param sphere - Sphere object to test intersection against.
    # @param triangles - Array to collect intersecting triangles.
    getSphereTriangles: (sphere, triangles) ->

        for subTreeIndex in [0...@subTrees.length]

            currentSubTree = @subTrees[subTreeIndex]

            continue unless sphere.intersectsBox(currentSubTree.box)

            if currentSubTree.polygons.length > 0

                for polygonIndex in [0...currentSubTree.polygons.length]

                    currentPolygon = currentSubTree.polygons[polygonIndex]

                    continue unless currentPolygon.valid

                    if triangles.indexOf(currentPolygon.triangle) is -1

                        triangles.push(currentPolygon.triangle)

            else

                currentSubTree.getSphereTriangles(sphere, triangles)

    # Perform high-level sphere intersection testing against the entire polytree.
    # Returns collision data with adjusted position and penetration depth.
    #
    # @param sphere - Sphere object to test collision against.
    #
    # @return Object with normal and depth properties or false if no collision.
    sphereIntersect: (sphere) ->

        collisionDetected = false
        intersectionResult = undefined
        intersectingTriangles = []
        
        adjustedSphere = new Sphere()
        adjustedSphere.copy(sphere)

        @getSphereTriangles(sphere, intersectingTriangles)

        for triangleIndex in [0...intersectingTriangles.length]

            currentTriangle = intersectingTriangles[triangleIndex]

            if intersectionResult = @triangleSphereIntersect(adjustedSphere, currentTriangle)

                collisionDetected = true
                adjustedSphere.center.add(intersectionResult.normal.multiplyScalar(intersectionResult.depth))

        if collisionDetected

            collisionVector = adjustedSphere.center.clone().sub(sphere.center)
            penetrationDepth = collisionVector.length()

            return

                normal: collisionVector.normalize()
                depth: penetrationDepth

        return false

    # Build polytree from Three.js scene graph (Group or Object3D).
    # This method traverses the scene graph and converts all meshes to polytree data.
    #
    # @param group - Three.js Group or Object3D to traverse.
    fromGraphNode: (sceneGraphNode) ->

        sceneGraphNode.updateWorldMatrix(true, true)

        targetPolytreeInstance = this

        sceneGraphNode.traverse (sceneObject) ->

            if sceneObject.isMesh is true

                Polytree.fromMesh(sceneObject, undefined, targetPolytreeInstance, false)

        @buildTree()

    # === CLEANUP AND DISPOSAL METHODS ===

    # Delete this tree and all its data (primary cleanup method).
    delete: (deletePolygons = true) ->

        if @polygons.length > 0 and deletePolygons

            @polygons.forEach (polygon) -> polygon.delete()
            @polygons.length = 0

        if @replacedPolygons.length > 0 and deletePolygons

            @replacedPolygons.forEach (polygon) -> polygon.delete()
            @replacedPolygons.length = 0

        if @polygonArrays

            @polygonArrays.length = 0

        if @subTrees.length

            for i in [0...@subTrees.length]

                @subTrees[i].delete(deletePolygons)

            @subTrees.length = 0

        @mesh = undefined
        @originalMatrixWorld = undefined
        @box = undefined
        @parent = undefined
        @level = undefined

    # Dispose of this tree (alias for delete).
    dispose: (deletePolygons = true) ->

        @delete(deletePolygons)
