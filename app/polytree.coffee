class Polytree

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

        if @parent

            @parent.getMesh()

        else

            @mesh

    newPolytree: (box, parent) -> # Create a new Polytree node with given parameters.

        new @constructor(box, parent)

    setPolygonIndex: (index) -> # Set polygon material index for all polygons in this tree.

        return if index is undefined

        @polygonArrays.forEach (polygonsArray) ->

            if polygonsArray.length

                polygonsArray.forEach (polygon) -> polygon.shared = index

    # === OBJECT CREATION AND COPYING ===

    clone: -> # Creates a deep copy of this Polytree.

        (new @constructor()).copy(this)

    copy: (source) -> # Copy data from another Polytree instance.

        @deletePolygonsArrayFromRoot(@polygons)
        @polygons = source.polygons.map (polygon) -> polygon.clone()
        @addPolygonsArrayToRoot(@polygons)
        @replacedPolygons = source.replacedPolygons.map (polygon) -> polygon.clone()

        if source.mesh

            @mesh = source.mesh

        if source.originalMatrixWorld

            @originalMatrixWorld = source.originalMatrixWorld.clone()

        @box = source.box.clone()
        @level = source.level

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

        @bounds.min.x = Math.min(@bounds.min.x, triangle.a.x, triangle.b.x, triangle.c.x)
        @bounds.min.y = Math.min(@bounds.min.y, triangle.a.y, triangle.b.y, triangle.c.y)
        @bounds.min.z = Math.min(@bounds.min.z, triangle.a.z, triangle.b.z, triangle.c.z)

        @bounds.max.x = Math.max(@bounds.max.x, triangle.a.x, triangle.b.x, triangle.c.x)
        @bounds.max.y = Math.max(@bounds.max.y, triangle.a.y, triangle.b.y, triangle.c.y)
        @bounds.max.z = Math.max(@bounds.max.z, triangle.a.z, triangle.b.z, triangle.c.z)

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

        return unless @box

        halfsize = temporaryVector3Secondary.copy(@box.max).sub(@box.min).multiplyScalar(0.5)

        # Create 8 child boxes in a 2x2x2 grid.
        for x in [0..1]

            for y in [0..1]

                for z in [0..1]

                    box = new Box3()

                    vectorPosition = temporaryVector3Primary.set(x, y, z)

                    box.min.copy(@box.min).add(vectorPosition.multiply(halfsize))
                    box.max.copy(box.min).add(halfsize)
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

                console.error("ERROR: unable to find subtree for:", polygon.triangle)
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
    expandParentBox: ->

        if @parent

            @parent.box.expandByPoint(@box.min)
            @parent.box.expandByPoint(@box.max)

            @parent.expandParentBox()

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

                result = rayIntersectsTriangle(ray, polygons[i].triangle, temporaryVector3Primary)

                if result

                    newdistance = result.clone().sub(ray.origin).length()

                    if distance > newdistance

                        distance = newdistance

                    if distance < 1e100

                        intersects.push({ distance: distance, polygon: polygons[i], position: result.clone().add(ray.origin) })

        intersects.length and intersects.sort(raycastIntersectAscSort)

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

    # Invert all polygons by flipping their face normals.
    invert: ->

        @polygonArrays.forEach (polygonsArray) ->

            if polygonsArray.length

                polygonsArray.forEach (p) -> p.flip()

    # === POLYGON MODIFICATION AND STATE MANAGEMENT ===

    # Replace a polygon with one or more new polygons during CSG operations
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

    # Delete polygons based on complex state rules for CSG operations
    # This implements the polygon classification logic for boolean operations
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

    # Delete polygons based on their intersection status (simpler filtering)
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

    # Check if a polygon intersects with this tree's bounding box
    isPolygonIntersecting: (polygon) ->

        unless @box.intersectsTriangle(polygon.triangle)

            return false

        return true

    # Mark polygons as intersecting with target polytree
    markIntesectingPolygons: (targetPolytree) ->

        @polygonArrays.forEach (polygonsArray) ->

            if polygonsArray.length

                polygonsArray.forEach (polygon) ->

                    polygon.intersects = targetPolytree.isPolygonIntersecting(polygon)

    # Reset polygon states for CSG operation preparation
    resetPolygons: (resetOriginal = true) ->

        @polygonArrays.forEach (polygonsArray) ->

            if polygonsArray.length

                polygonsArray.forEach (polygon) ->

                    polygon.reset(resetOriginal)

    # Complex CSG intersection handling - splits and classifies polygons
    # This is the core method for polygon classification in boolean operations
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

                        inside = polyInside_WindingNumber_buffer(targetPolytreeBuffer, currentPolygon.getMidpoint(), currentPolygon.coplanar)

                    else

                        point = pointRounding(temporaryVector3Secondary.copy(currentPolygon.getMidpoint()))

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

    delete: (deletePolygons = true) ->

        if @polygons.length > 0 and deletePolygons

            @polygons.forEach (p) -> p.delete()
            @polygons.length = 0

        if @replacedPolygons.length > 0 and deletePolygons

            @replacedPolygons.forEach (p) -> p.delete()
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

    dispose: (deletePolygons = true) ->

        @delete(deletePolygons)

    getPolygonCloneCallback: (cbFunc, trianglesSet) ->

        @polygonArrays.forEach (polygonsArray) ->

            if polygonsArray.length

                for i in [0...polygonsArray.length]

                    if polygonsArray[i].valid

                        cbFunc(polygonsArray[i].clone(), trianglesSet)

    deleteReplacedPolygons: ->

        if @replacedPolygons.length > 0

            @replacedPolygons.forEach (p) -> p.delete()
            @replacedPolygons.length = 0

        for i in [0...@subTrees.length]

            @subTrees[i].deleteReplacedPolygons()

    markPolygonsAsOriginal: ->

        @polygonArrays.forEach (polygonsArray) ->

            if polygonsArray.length

                polygonsArray.forEach (p) -> p.originalValid = true

    # Apply transformation matrix to all polygons in this tree
    applyMatrix: (matrix, normalMatrix, firstRun = true) ->

        if matrix.isMesh

            matrix.updateMatrix()
            matrix = matrix.matrix

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

    # Clean up replaced polygons from CSG operations
    deleteReplacedPolygons: ->

        if @replacedPolygons.length > 0

            @replacedPolygons.forEach (p) -> p.delete()
            @replacedPolygons.length = 0

        for i in [0...@subTrees.length]

            @subTrees[i].deleteReplacedPolygons()

    # Mark all polygons as original (not generated by CSG operations)
    markPolygonsAsOriginal: ->

        @polygonArrays.forEach (polygonsArray) ->

            if polygonsArray.length

                polygonsArray.forEach (p) -> p.originalValid = true

    # Get polygon clones via callback for CSG operations
    getPolygonCloneCallback: (cbFunc, trianglesSet) ->

        @polygonArrays.forEach (polygonsArray) ->

            if polygonsArray.length

                for i in [0...polygonsArray.length]

                    if polygonsArray[i].valid

                        cbFunc(polygonsArray[i].clone(), trianglesSet)

    # Delete this tree and all its data (primary cleanup method)
    delete: (deletePolygons = true) ->

        if @polygons.length > 0 and deletePolygons

            @polygons.forEach (p) -> p.delete()
            @polygons.length = 0

        if @replacedPolygons.length > 0 and deletePolygons

            @replacedPolygons.forEach (p) -> p.delete()
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

    # Dispose of this tree (alias for delete)
    dispose: (deletePolygons = true) ->

        @delete(deletePolygons)

# Set Prototype Properties.
Polytree::isPolytree = true

# Set Static Properties.
Polytree.disposePolytree = true
Polytree.usePolytreeRay = true
Polytree.useWindingNumber = false
Polytree.rayIntersectTriangleType = "MollerTrumbore" # "regular" (three.js' ray.intersectTriangle; "MollerTrumbore" (Moller Trumbore algorithm);
Polytree.maxLevel = 16
Polytree.polygonsPerTree = 100

# Set Static Methods.
Polytree.rayIntersectsTriangle = rayIntersectsTriangle

# Main Operation Method.
Polytree.operation = (obj, returnPolytrees = false, buildTargetPolytree = true, options = { objCounter: 0 }, firstRun = true, async = true) ->

    if async

        new Promise (resolve, reject) ->

            try

                _handleOperation(obj, returnPolytrees, buildTargetPolytree, options, firstRun, async).then (result) ->

                    resolve(result)

                .catch (e) -> reject(e)

            catch e

                reject(e)

    else

        _handleOperation(obj, returnPolytrees, buildTargetPolytree, options, firstRun, async)
