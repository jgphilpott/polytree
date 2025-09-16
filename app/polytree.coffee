class Polytree

    constructor: (box, parent) ->

        @polygons = []
        @replacedPolygons = []
        @mesh
        @originalMatrixWorld
        @box = box
        @subTrees = []
        @parent = parent
        @level = 0
        @polygonArrays = undefined
        # @isPolytree = true
        @addPolygonsArrayToRoot(@polygons)

    clone: ->

        (new @constructor()).copy(this)

    copy: (source) ->

        @deletePolygonsArrayFromRoot(@polygons)
        @polygons = source.polygons.map (p) -> p.clone()
        @addPolygonsArrayToRoot(@polygons)

        @replacedPolygons = source.replacedPolygons.map (p) -> p.clone()

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

    addPolygonsArrayToRoot: (array) ->

        if @parent

            @parent.addPolygonsArrayToRoot(array)

        else

            if @polygonArrays is undefined

                @polygonArrays = []

            @polygonArrays.push(array)

    deletePolygonsArrayFromRoot: (array) ->

        if @parent

            @parent.deletePolygonsArrayFromRoot(array)

        else

            index = @polygonArrays.indexOf(array)

            if index > -1

                @polygonArrays.splice(index, 1)

    isEmpty: ->

        @polygons.length is 0

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

    calcBox: ->

        unless @bounds

            @bounds = new Box3()

        @box = @bounds.clone()

        # offset small ammount to account for regular grid
        @box.min.x -= 0.01
        @box.min.y -= 0.01
        @box.min.z -= 0.01

        return this

    newPolytree: (box, parent) ->

        new @constructor(box, parent)

    split: (level) ->

        return unless @box

        subTrees = []
        halfsize = tempVector2.copy(@box.max).sub(@box.min).multiplyScalar(0.5)

        for x in [0..1]

            for y in [0..1]

                for z in [0..1]

                    box = new Box3()
                    vectorPosition = tempVector1.set(x, y, z)

                    box.min.copy(@box.min).add(vectorPosition.multiply(halfsize))
                    box.max.copy(box.min).add(halfsize)
                    box.expandByScalar(EPSILON)
                    subTrees.push(@newPolytree(box, this))

        polygon = undefined

        while polygon = @polygons.pop()

            found = false

            for i in [0...subTrees.length]

                if subTrees[i].box.containsPoint(polygon.getMidpoint())

                    subTrees[i].polygons.push(polygon)
                    found = true

            unless found

                console.error("ERROR: unable to find subtree for:", polygon.triangle)
                throw new Error("Unable to find subtree for triangle at level #{level}")

        for i in [0...subTrees.length]

            subTrees[i].level = level + 1
            len = subTrees[i].polygons.length

            # if (len !== 0) {
            if len > Polytree.polygonsPerTree and level < Polytree.maxLevel

                subTrees[i].split(level + 1)

            @subTrees.push(subTrees[i])
            # }

        return this

    buildTree: ->

        @calcBox()
        @split(0)
        @processTree()
        return this

    processTree: ->

        unless @isEmpty()

            tempBox3.copy(@box)

            for i in [0...@polygons.length]

                @box.expandByPoint(@polygons[i].triangle.a)
                @box.expandByPoint(@polygons[i].triangle.b)
                @box.expandByPoint(@polygons[i].triangle.c)

            @expandParentBox()

        for i in [0...@subTrees.length]

            @subTrees[i].processTree()

    expandParentBox: ->

        if @parent

            @parent.box.expandByPoint(@box.min)
            @parent.box.expandByPoint(@box.max)
            @parent.expandParentBox()

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

        polygons

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

    rayIntersect: (ray, matrixWorld, intersects = []) ->

        return [] if ray.direction.length() is 0

        distance = 1e100
        polygons = @getRayPolygons(ray)

        for i in [0...polygons.length]

            result = undefined

            if Polytree.rayIntersectTriangleType is "regular"

                result = ray.intersectTriangle(polygons[i].triangle.a, polygons[i].triangle.b, polygons[i].triangle.c, false, tempVector1)

                if result

                    tempVector1.applyMatrix4(matrixWorld)
                    distance = tempVector1.distanceTo(ray.origin)

                    if distance < 0 or distance > Infinity

                        console.warn("[rayIntersect] Failed ray distance check", ray)

                    else

                        intersects.push({ distance: distance, polygon: polygons[i], position: tempVector1.clone() })

            else

                result = rayIntersectsTriangle(ray, polygons[i].triangle, tempVector1)

                if result

                    newdistance = result.clone().sub(ray.origin).length()

                    if distance > newdistance

                        distance = newdistance

                    if distance < 1e100

                        intersects.push({ distance: distance, polygon: polygons[i], position: result.clone().add(ray.origin) })

        intersects.length and intersects.sort(raycastIntersectAscSort)

        return intersects

    getIntersectingPolygons: (polygons = []) ->

        @polygonArrays.forEach (polygonsArray) ->

            if polygonsArray.length

                for i in [0...polygonsArray.length]

                    if polygonsArray[i].valid and polygonsArray[i].intersects

                        polygons.push(polygonsArray[i])

        return polygons

    getPolygons: (polygons = []) ->
        @polygonArrays.forEach (polygonsArray) ->

            if polygonsArray.length

                for i in [0...polygonsArray.length]

                    if polygonsArray[i].valid

                        if polygons.indexOf(polygonsArray[i]) is -1

                            polygons.push(polygonsArray[i])

        return polygons

    invert: ->

        @polygonArrays.forEach (polygonsArray) ->

            if polygonsArray.length

                polygonsArray.forEach (p) -> p.flip()

    getMesh: ->

        if @parent

            @parent.getMesh()

        else

            @mesh

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

    isPolygonIntersecting: (polygon) ->

        unless @box.intersectsTriangle(polygon.triangle)

            return false

        return true

    markIntesectingPolygons: (targetPolytree) ->

        @polygonArrays.forEach (polygonsArray) ->

            if polygonsArray.length

                polygonsArray.forEach (polygon) ->

                    polygon.intersects = targetPolytree.isPolygonIntersecting(polygon)

    resetPolygons: (resetOriginal = true) ->

        @polygonArrays.forEach (polygonsArray) ->

            if polygonsArray.length

                polygonsArray.forEach (polygon) ->

                    polygon.reset(resetOriginal)

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

                        point = pointRounding(tempVector2.copy(currentPolygon.getMidpoint()))

                        if Polytree.usePolytreeRay isnt true and targetPolytree.mesh

                            tempRayDirection.copy(currentPolygon.plane.normal)
                            tempRaycaster.set(point, tempRayDirection)
                            intersects = tempRaycaster.intersectObject(targetPolytree.mesh)

                            if intersects.length

                                if tempRayDirection.dot(intersects[0].face.normal) > 0

                                    inside = true

                            unless inside or not currentPolygon.coplanar

                                for j in [0..._wP_EPS_ARR_COUNT]

                                    tempRaycaster.ray.origin.copy(point).add(_wP_EPS_ARR[j])
                                    intersects = tempRaycaster.intersectObject(targetPolytree.mesh)

                                    if intersects.length

                                        if tempRayDirection.dot(intersects[0].face.normal) > 0

                                            inside = true
                                            break

                        else

                            tempRay.origin.copy(point)
                            tempRayDirection.copy(currentPolygon.plane.normal)
                            tempRay.direction.copy(currentPolygon.plane.normal)
                            intersects = targetPolytree.rayIntersect(tempRay, targetPolytree.originalMatrixWorld)

                            if intersects.length

                                if tempRayDirection.dot(intersects[0].polygon.plane.normal) > 0

                                    inside = true

                            unless inside or not currentPolygon.coplanar

                                for j in [0..._wP_EPS_ARR_COUNT]

                                    tempRay.origin.copy(point).add(_wP_EPS_ARR[j])
                                    tempRayDirection.copy(currentPolygon.plane.normal)
                                    tempRay.direction.copy(currentPolygon.plane.normal)
                                    intersects = targetPolytree.rayIntersect(tempRay, targetPolytree.originalMatrixWorld)

                                    if intersects.length

                                        if tempRayDirection.dot(intersects[0].polygon.plane.normal) > 0

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

    applyMatrix: (matrix, normalMatrix, firstRun = true) ->

        if matrix.isMesh

            matrix.updateMatrix()
            matrix = matrix.matrix

        @box.makeEmpty()
        normalMatrix = normalMatrix or tmpm3.getNormalMatrix(matrix)

        if @polygons.length > 0

            for i in [0...@polygons.length]

                if @polygons[i].valid

                    @polygons[i].applyMatrix(matrix, normalMatrix)

        for i in [0...@subTrees.length]

            @subTrees[i].applyMatrix(matrix, normalMatrix, false)

        if firstRun

            @processTree()

    setPolygonIndex: (index) ->

        return if index is undefined

        @polygonArrays.forEach (polygonsArray) ->

            if polygonsArray.length

                polygonsArray.forEach (p) -> p.shared = index

# Set prototype property
Polytree::isPolytree = true

# Static properties
Polytree.disposePolytree = true
Polytree.usePolytreeRay = true
Polytree.useWindingNumber = false
Polytree.rayIntersectTriangleType = "MollerTrumbore" # "regular" (three.js' ray.intersectTriangle; "MollerTrumbore" (Moller Trumbore algorithm);
Polytree.maxLevel = 16
Polytree.polygonsPerTree = 100

# Static method
Polytree.rayIntersectsTriangle = rayIntersectsTriangle

# Main operation method
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
