{ Vector2, Vector3, Box3, DoubleSide, Matrix3, Ray, Triangle, BufferGeometry, BufferAttribute, Mesh, Raycaster } = require "three"
{ triangleIntersectsTriangle } = require "./app/triangle.intersection.js"

_v1 = new Vector3()
_v2 = new Vector3()

_box3$1 = new Box3()

tv0 = new Vector3()
tv1 = new Vector3()

_raycaster1 = new Raycaster()
_ray = new Ray()
_rayDirection = new Vector3(0, 0, 1)

EPSILON = 1e-5
COPLANAR = 0
FRONT = 1
BACK = 2
SPANNING = 3
_polygonID = 0

class OctreeCSG

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
        # @isOctree = true
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

        this

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
        this

    calcBox: ->

        unless @bounds
            @bounds = new Box3()
        @box = @bounds.clone()

        # offset small ammount to account for regular grid
        @box.min.x -= 0.01
        @box.min.y -= 0.01
        @box.min.z -= 0.01

        this

    newOctree: (box, parent) ->

        new @constructor(box, parent)

    split: (level) ->

        return unless @box

        subTrees = []
        halfsize = _v2.copy(@box.max).sub(@box.min).multiplyScalar(0.5)
        for x in [0..1]
            for y in [0..1]
                for z in [0..1]
                    box = new Box3()
                    v = _v1.set(x, y, z)

                    box.min.copy(@box.min).add(v.multiply(halfsize))
                    box.max.copy(box.min).add(halfsize)
                    box.expandByScalar(EPSILON)
                    subTrees.push(@newOctree(box, this))

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
            if len > OctreeCSG.polygonsPerTree and level < OctreeCSG.maxLevel
                subTrees[i].split(level + 1)

            @subTrees.push(subTrees[i])
            # }
        this

    buildTree: ->

        @calcBox()
        @split(0)
        @processTree()
        this

    processTree: ->

        unless @isEmpty()
            _box3$1.copy(@box)
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
            if OctreeCSG.rayIntersectTriangleType is "regular"
                result = ray.intersectTriangle(polygons[i].triangle.a, polygons[i].triangle.b, polygons[i].triangle.c, false, _v1)
                if result
                    _v1.applyMatrix4(matrixWorld)
                    distance = _v1.distanceTo(ray.origin)
                    if distance < 0 or distance > Infinity
                        console.warn("[rayIntersect] Failed ray distance check", ray)
                    else
                        intersects.push({ distance: distance, polygon: polygons[i], position: _v1.clone() })
            else
                result = rayIntersectsTriangle(ray, polygons[i].triangle, _v1)
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

    # if (@polygons.length)
    #     for i in [0...@polygons.length]
    #         if @polygons[i].valid and @polygons[i].intersects
    #             polygons.push(@polygons[i])
    # for i in [0...@subTrees.length]
    #     @subTrees[i].getIntersectingPolygons(polygons)

        return polygons

    getPolygons: (polygons = []) ->
        @polygonArrays.forEach (polygonsArray) ->
            if polygonsArray.length
                for i in [0...polygonsArray.length]
                    if polygonsArray[i].valid
                        if polygons.indexOf(polygonsArray[i]) is -1
                            polygons.push(polygonsArray[i])

    # if @polygons.length > 0
    #     for i in [0...@polygons.length]
    #         if @polygons[i].valid
    #             if polygons.indexOf(@polygons[i]) is -1
    #                 polygons.push(@polygons[i])
    # for i in [0...@subTrees.length]
    #     @subTrees[i].getPolygons(polygons)

        return polygons

    invert: ->

        @polygonArrays.forEach (polygonsArray) ->
            if polygonsArray.length
                polygonsArray.forEach (p) -> p.flip()

    # if @polygons.length > 0
    #     @polygons.forEach (p) -> p.flip()
    # for i in [0...@subTrees.length]
    #     @subTrees[i].invert()

    getMesh: ->

        if @parent
            @parent.getMesh()
        else
            @mesh

    replacePolygon: (polygon, newPolygons) ->

        unless Array.isArray(newPolygons)
            newPolygons = [newPolygons]

        # if @polygons.length > 0
        #     polygonIndex = @polygons.indexOf(polygon)
        #     if polygonIndex > -1
        #         if polygon.originalValid is true
        #             @replacedPolygons.push(polygon)
        #         else
        #             polygon.setInvalid()
        #         @polygons.splice(polygonIndex, 1, ...newPolygons)
        # for i in [0...@subTrees.length]
        #     @subTrees[i].replacePolygon(polygon, newPolygons)

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

        # if @polygons.length > 0
        #     polygonArr = @polygons.filter (polygon) -> (polygon.valid == true) and (polygon.intersects == true)
        #     polygonArr.forEach (polygon) ->
        #         found = false
        #         for j in [0...rulesArr.length]
        #             if rulesArr[j].array
        #                 states = rulesArr[j].rule
        #                 if (states.includes(polygon.state)) and (((polygon.previousState isnt "undecided") and (states.includes(polygon.previousState))) or (polygon.previousState is "undecided"))
        #                     found = true
        #                     statesObj = {}
        #                     mainStatesObj = {}
        #                     states.forEach (state) -> statesObj[state] = false
        #                     states.forEach (state) -> mainStatesObj[state] = false
        #                     statesObj[polygon.state] = true
        #                     for i in [0...polygon.previousStates.length]
        #                         unless states.includes(polygon.previousStates[i])
        #                             found = false
        #                             break
        #                         else
        #                             statesObj[polygon.previousStates[i]] = true
        #                     if found
        #                         for state of statesObj
        #                             if statesObj[state] is false
        #                                 found = false
        #                                 break
        #                         if found
        #                             break
        #             else
        #                 if polygon.checkAllStates(rulesArr[j].rule)
        #                     found = true
        #                     break
        #         if found
        #             polygonIndex = @polygons.indexOf(polygon)
        #             if polygonIndex > -1
        #                 polygon.setInvalid()
        #                 @polygons.splice(polygonIndex, 1)
        #             if firstRun
        #                 polygon.delete()
        # for i in [0...@subTrees.length]
        #     @subTrees[i].deletePolygonsByStateRules(rulesArr, false)

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

        # if @polygons.length > 0
        #     polygonArr = @polygons.slice()
        #     polygonArr.forEach (polygon) ->
        #         if polygon.valid
        #             if polygon.intersects == intersects
        #                 polygonIndex = @polygons.indexOf(polygon)
        #                 if polygonIndex > -1
        #                     polygon.setInvalid()
        #                     @polygons.splice(polygonIndex, 1)
        #                 if firstRun
        #                     polygon.delete()
        # for i in [0...@subTrees.length]
        #     @subTrees[i].deletePolygonsByIntersection(intersects, false)

    isPolygonIntersecting: (polygon) ->

        unless @box.intersectsTriangle(polygon.triangle)
            return false
        return true

    markIntesectingPolygons: (targetOctree) ->

        @polygonArrays.forEach (polygonsArray) ->
            if polygonsArray.length
                polygonsArray.forEach (polygon) ->
                    polygon.intersects = targetOctree.isPolygonIntersecting(polygon)

        # if @polygons.length > 0
        #     @polygons.forEach (polygon) ->
        #         polygon.intersects = targetOctree.isPolygonIntersecting(polygon)
        # for i in [0...@subTrees.length]
        #     @subTrees[i].markIntesectingPolygons(targetOctree)

    resetPolygons: (resetOriginal = true) ->

        @polygonArrays.forEach (polygonsArray) ->
            if polygonsArray.length
                polygonsArray.forEach (polygon) ->
                    polygon.reset(resetOriginal)

        # if @polygons.length > 0
        #     @polygons.forEach (polygon) ->
        #         polygon.reset(resetOriginal)
        # for i in [0...@subTrees.length]
        #     @subTrees[i].resetPolygons(resetOriginal)

    handleIntersectingPolygons: (targetOctree, targetOctreeBuffer) ->

        # if @polygons.length > 0
        #     polygonStack = @polygons.filter (polygon) -> (polygon.valid == true) and (polygon.intersects == true) and (polygon.state == "undecided")
        #     currentPolygon = polygonStack.pop()
        #     while currentPolygon
        #         if currentPolygon.state isnt "undecided"
        #             continue
        #         unless currentPolygon.valid
        #             continue
        #         targetPolygons = targetOctree.getPolygonsIntersectingPolygon(currentPolygon)
        #         if targetPolygons.length > 0
        #             for j in [0...targetPolygons.length]
        #                 target = targetPolygons[j]
        #                 splitResults = splitPolygonByPlane(currentPolygon, target.plane)
        #                 if splitResults.length > 1
        #                     for i in [0...splitResults.length]
        #                         polygon = splitResults[i].polygon
        #                         polygon.intersects = currentPolygon.intersects
        #                         polygon.newPolygon = true
        #                         polygonStack.push(polygon)
        #                     @replacePolygon(currentPolygon, splitResults.map((result) -> result.polygon))
        #                     break
        #                 else
        #                     if currentPolygon.id isnt splitResults[0].polygon.id
        #                         splitResults[0].polygon.intersects = currentPolygon.intersects
        #                         splitResults[0].polygon.newPolygon = true
        #                         polygonStack.push(splitResults[0].polygon)
        #                         @replacePolygon(currentPolygon, splitResults[0].polygon)
        #                         break
        #                     else
        #                         if (splitResults[0].type == "coplanar-front") or (splitResults[0].type == "coplanar-back")
        #                             currentPolygon.setState(splitResults[0].type)
        #                             currentPolygon.coplanar = true
        #         currentPolygon = polygonStack.pop()
        #     polygonStack = @polygons.filter (polygon) -> (polygon.valid == true) and (polygon.intersects == true)
        #     currentPolygon = polygonStack.pop()
        #     inside = false
        #     while currentPolygon
        #         unless currentPolygon.valid
        #             continue
        #         inside = false
        #         if targetOctree.box.containsPoint(currentPolygon.getMidpoint())
        #             if OctreeCSG.useWindingNumber is true
        #                 inside = polyInside_WindingNumber_buffer(targetOctreeBuffer, currentPolygon.getMidpoint(), currentPolygon.coplanar)
        #             else
        #                 point = pointRounding(_v2.copy(currentPolygon.getMidpoint()))
        #                 if OctreeCSG.useOctreeRay isnt true and targetOctree.mesh
        #                     _rayDirection.copy(currentPolygon.plane.normal)
        #                     _raycaster1.set(point, _rayDirection)
        #                     intersects = _raycaster1.intersectObject(targetOctree.mesh)
        #                     if intersects.length
        #                         if _rayDirection.dot(intersects[0].face.normal) > 0
        #                             inside = true
        #                     unless inside or not currentPolygon.coplanar
        #                         for j in [0..._wP_EPS_ARR_COUNT]
        #                             _raycaster1.ray.origin.copy(point).add(_wP_EPS_ARR[j])
        #                             intersects = _raycaster1.intersectObject(targetOctree.mesh)
        #                             if intersects.length
        #                                 if _rayDirection.dot(intersects[0].face.normal) > 0
        #                                     inside = true
        #                                     break
        #                 else
        #                     _ray.origin.copy(point)
        #                     _rayDirection.copy(currentPolygon.plane.normal)
        #                     _ray.direction.copy(currentPolygon.plane.normal)
        #                     intersects = targetOctree.rayIntersect(_ray, targetOctree.originalMatrixWorld)
        #                     if intersects.length
        #                         if _rayDirection.dot(intersects[0].polygon.plane.normal) > 0
        #                             inside = true
        #                     unless inside or not currentPolygon.coplanar
        #                         for j in [0..._wP_EPS_ARR_COUNT]
        #                             _ray.origin.copy(point).add(_wP_EPS_ARR[j])
        #                             _rayDirection.copy(currentPolygon.plane.normal)
        #                             _ray.direction.copy(currentPolygon.plane.normal)
        #                             intersects = targetOctree.rayIntersect(_ray, targetOctree.originalMatrixWorld)
        #                             if intersects.length
        #                                 if _rayDirection.dot(intersects[0].polygon.plane.normal) > 0
        #                                     inside = true
        #                                     break
        #         if inside is true
        #             currentPolygon.setState("inside")
        #         else
        #             currentPolygon.setState("outside")
        #         currentPolygon = polygonStack.pop()
        # for i in [0...@subTrees.length]
        #     @subTrees[i].handleIntersectingPolygons(targetOctree, targetOctreeBuffer)

        if @polygons.length > 0
            polygonStack = @polygons.filter (polygon) -> (polygon.valid == true) and (polygon.intersects == true) and (polygon.state == "undecided")
            currentPolygon = polygonStack.pop()
            while currentPolygon
                if currentPolygon.state isnt "undecided"
                    continue
                unless currentPolygon.valid
                    continue
                targetPolygons = targetOctree.getPolygonsIntersectingPolygon(currentPolygon)
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
                if targetOctree.box.containsPoint(currentPolygon.getMidpoint())
                    if OctreeCSG.useWindingNumber is true
                        inside = polyInside_WindingNumber_buffer(targetOctreeBuffer, currentPolygon.getMidpoint(), currentPolygon.coplanar)
                    else
                        point = pointRounding(_v2.copy(currentPolygon.getMidpoint()))
                        if OctreeCSG.useOctreeRay isnt true and targetOctree.mesh
                            _rayDirection.copy(currentPolygon.plane.normal)
                            _raycaster1.set(point, _rayDirection)
                            intersects = _raycaster1.intersectObject(targetOctree.mesh)
                            if intersects.length
                                if _rayDirection.dot(intersects[0].face.normal) > 0
                                    inside = true
                            unless inside or not currentPolygon.coplanar
                                for j in [0..._wP_EPS_ARR_COUNT]
                                    _raycaster1.ray.origin.copy(point).add(_wP_EPS_ARR[j])
                                    intersects = _raycaster1.intersectObject(targetOctree.mesh)
                                    if intersects.length
                                        if _rayDirection.dot(intersects[0].face.normal) > 0
                                            inside = true
                                            break
                        else
                            _ray.origin.copy(point)
                            _rayDirection.copy(currentPolygon.plane.normal)
                            _ray.direction.copy(currentPolygon.plane.normal)
                            intersects = targetOctree.rayIntersect(_ray, targetOctree.originalMatrixWorld)
                            if intersects.length
                                if _rayDirection.dot(intersects[0].polygon.plane.normal) > 0
                                    inside = true
                            unless inside or not currentPolygon.coplanar
                                for j in [0..._wP_EPS_ARR_COUNT]
                                    _ray.origin.copy(point).add(_wP_EPS_ARR[j])
                                    _rayDirection.copy(currentPolygon.plane.normal)
                                    _ray.direction.copy(currentPolygon.plane.normal)
                                    intersects = targetOctree.rayIntersect(_ray, targetOctree.originalMatrixWorld)
                                    if intersects.length
                                        if _rayDirection.dot(intersects[0].polygon.plane.normal) > 0
                                            inside = true
                                            break
                if inside is true
                    currentPolygon.setState("inside")
                else
                    currentPolygon.setState("outside")
                currentPolygon = polygonStack.pop()
        for i in [0...@subTrees.length]
            @subTrees[i].handleIntersectingPolygons(targetOctree, targetOctreeBuffer)

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

    # if @polygons.length > 0
    #     for i in [0...@polygons.length]
    #         if @polygons[i].valid
    #             cbFunc(@polygons[i].clone(), trianglesSet)
    # for i in [0...@subTrees.length]
    #     @subTrees[i].getPolygonCloneCallback(cbFunc, trianglesSet)

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

    # if @polygons.length > 0
    #     @polygons.forEach (p) -> p.originalValid = true
    # for i in [0...@subTrees.length]
    #     @subTrees[i].markPolygonsAsOriginal()

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

        # if @polygons.length > 0
        #     @polygons.forEach (p) -> p.shared = index
        # for i in [0...@subTrees.length]
        #     @subTrees[i].setPolygonIndex(index)

OctreeCSG::isOctree = true

raycastIntersectAscSort = (a, b) -> a.distance - b.distance

pointRounding = (point, num = 15) ->
    point.x = +point.x.toFixed(num)
    point.y = +point.y.toFixed(num)
    point.z = +point.z.toFixed(num)
    point

splitPolygonByPlane = (polygon, plane, result = []) ->
    returnPolygon =
        polygon: polygon
        type: "undecided"
    polygonType = 0
    types = []
    for i in [0...polygon.vertices.length]
        t = plane.normal.dot(polygon.vertices[i].pos) - plane.w
        type = if t < -EPSILON then BACK else if t > EPSILON then FRONT else COPLANAR
        polygonType |= type
        types.push(type)
    switch polygonType
        when COPLANAR
            returnPolygon.type = if plane.normal.dot(polygon.plane.normal) > 0 then "coplanar-front" else "coplanar-back"
            result.push(returnPolygon)
        when FRONT
            returnPolygon.type = "front"
            result.push(returnPolygon)
        when BACK
            returnPolygon.type = "back"
            result.push(returnPolygon)
        when SPANNING
            f = []
            b = []
            for i in [0...polygon.vertices.length]
                j = (i + 1) % polygon.vertices.length
                ti = types[i]
                tj = types[j]
                vi = polygon.vertices[i]
                vj = polygon.vertices[j]
                if ti != BACK
                    f.push(vi)
                if ti != FRONT
                    b.push(if ti != BACK then vi.clone() else vi)
                if (ti | tj) == SPANNING
                    t = (plane.w - plane.normal.dot(vi.pos)) / plane.normal.dot(tv0.copy(vj.pos).sub(vi.pos))
                    v = vi.interpolate(vj, t)
                    f.push(v)
                    b.push(v.clone())
            if f.length >= 3
                if f.length > 3
                    newPolys = splitPolygonArr(f)
                    for npI in [0...newPolys.length]
                        result.push(
                            polygon: new Polygon(newPolys[npI], polygon.shared)
                            type: "front"
                        )
                else
                    result.push(
                        polygon: new Polygon(f, polygon.shared)
                        type: "front"
                    )
            if b.length >= 3
                if b.length > 3
                    newPolys = splitPolygonArr(b)
                    for npI in [0...newPolys.length]
                        result.push(
                            polygon: new Polygon(newPolys[npI], polygon.shared)
                            type: "back"
                        )
                else
                    result.push(
                        polygon: new Polygon(b, polygon.shared)
                        type: "back"
                    )
    if result.length == 0
        result.push(returnPolygon)
    return result

splitPolygonArr = (arr) ->
    resultArr = []
    if arr.length > 4
        console.warn("[splitPolygonArr] arr.length > 4", arr.length)
        for j in [3..arr.length]
            result = []
            result.push(arr[0].clone())
            result.push(arr[j - 2].clone())
            result.push(arr[j - 1].clone())
            resultArr.push(result)
    else
        if arr[0].pos.distanceTo(arr[2].pos) <= arr[1].pos.distanceTo(arr[3].pos)
            resultArr.push([arr[0].clone(), arr[1].clone(), arr[2].clone()],
                [arr[0].clone(), arr[2].clone(), arr[3].clone()])
        else
            resultArr.push([arr[0].clone(), arr[1].clone(), arr[3].clone()],
                [arr[1].clone(), arr[2].clone(), arr[3].clone()])
        return resultArr
    return resultArr

CSG_Rules =

  union:

    a: [
      { array: true, rule: ["inside", "coplanar-back"] }
      { array: false, rule: "inside" }
    ]

    b: [
      { array: true, rule: ["inside", "coplanar-back"] }
      { array: true, rule: ["inside", "coplanar-front"] }
      { array: false, rule: "inside" }
    ]

  subtract:

    a: [
      { array: true, rule: ["inside", "coplanar-back"] }
      { array: true, rule: ["inside", "coplanar-front"] }
      { array: false, rule: "inside" }
    ]

    b: [
      { array: true, rule: ["outside", "coplanar-back"] }
      { array: true, rule: ["outside", "coplanar-front"] }
      { array: true, rule: ["inside", "coplanar-front"] }
      { array: false, rule: "outside" }
    ]

  intersect:

    a: [
      { array: true, rule: ["inside", "coplanar-back"] }
      { array: true, rule: ["outside", "coplanar-front"] }
      { array: true, rule: ["outside", "coplanar-back"] }
      { array: false, rule: "outside" }
    ]

    b: [
      { array: true, rule: ["inside", "coplanar-front"] }
      { array: true, rule: ["inside", "coplanar-back"] }
      { array: true, rule: ["outside", "coplanar-front"] }
      { array: true, rule: ["outside", "coplanar-back"] }
      { array: false, rule: "outside" }
    ]

# class OctreeCSG { };

###
Union:
- Combine all polygons from A and B, except:
    - Polygons in A that are inside B or coplanar-back with B
    - Polygons in B that are inside A or coplanar-back/front with A
###

###
Subtract:
- Keep polygons from A that are outside B or coplanar-front with B
- Keep polygons from B that are inside A and coplanar-front with A
###

###
Intersect:
1. Delete all polygons in A that are:
    a. inside and coplanar-back
    b. outside and coplanar-front
    c. outside and coplanar-back
    d. outside
2. Delete all polygons in B that are:
    a. inside and coplanar-front
    b. inside and coplanar-back
    c. outside and coplanar-front
    d. outside and coplanar-back
    e. outside
###

OctreeCSG.union = (octreeA, octreeB, buildTargetOctree = true) ->
  octree = new OctreeCSG()
  trianglesSet = new Set()
  if octreeA.box.intersectsBox(octreeB.box)
    currentMeshSideA = undefined
    currentMeshSideB = undefined
    if octreeA.mesh
      currentMeshSideA = octreeA.mesh.material.side
      octreeA.mesh.material.side = DoubleSide
    if octreeB.mesh
      currentMeshSideB = octreeB.mesh.material.side
      octreeB.mesh.material.side = DoubleSide

    octreeA.resetPolygons(false)
    octreeB.resetPolygons(false)

    octreeA.markIntesectingPolygons(octreeB)
    octreeB.markIntesectingPolygons(octreeA)

    handleIntersectingOctrees(octreeA, octreeB)
    octreeA.deleteReplacedPolygons()
    octreeB.deleteReplacedPolygons()

    octreeA.deletePolygonsByStateRules(CSG_Rules.union.a)
    octreeB.deletePolygonsByStateRules(CSG_Rules.union.b)

    octreeA.getPolygonCloneCallback(octree.addPolygon.bind(octree), trianglesSet)
    octreeB.getPolygonCloneCallback(octree.addPolygon.bind(octree), trianglesSet)

    if octreeA.mesh and octreeA.mesh.material.side isnt currentMeshSideA
      octreeA.mesh.material.side = currentMeshSideA
    if octreeB.mesh and octreeB.mesh.material.side isnt currentMeshSideB
      octreeB.mesh.material.side = currentMeshSideB
  else
    octreeA.getPolygonCloneCallback(octree.addPolygon.bind(octree), trianglesSet)
    octreeB.getPolygonCloneCallback(octree.addPolygon.bind(octree), trianglesSet)

  trianglesSet.clear()
  trianglesSet = undefined

  octree.markPolygonsAsOriginal()
  buildTargetOctree and octree.buildTree()
  octree

OctreeCSG.subtract = (octreeA, octreeB, buildTargetOctree = true) ->
  octree = new OctreeCSG()
  trianglesSet = new Set()
  if octreeA.box.intersectsBox(octreeB.box)
    currentMeshSideA = undefined
    currentMeshSideB = undefined
    if octreeA.mesh
      currentMeshSideA = octreeA.mesh.material.side
      octreeA.mesh.material.side = DoubleSide
    if octreeB.mesh
      currentMeshSideB = octreeB.mesh.material.side
      octreeB.mesh.material.side = DoubleSide

    octreeA.resetPolygons(false)
    octreeB.resetPolygons(false)
    octreeA.markIntesectingPolygons(octreeB)
    octreeB.markIntesectingPolygons(octreeA)

    handleIntersectingOctrees(octreeA, octreeB)
    octreeA.deleteReplacedPolygons()
    octreeB.deleteReplacedPolygons()

    octreeA.deletePolygonsByStateRules(CSG_Rules.subtract.a)
    octreeB.deletePolygonsByStateRules(CSG_Rules.subtract.b)

    octreeB.deletePolygonsByIntersection(false)
    octreeB.invert()

    octreeA.getPolygonCloneCallback(octree.addPolygon.bind(octree), trianglesSet)
    octreeB.getPolygonCloneCallback(octree.addPolygon.bind(octree), trianglesSet)

    if octreeA.mesh and octreeA.mesh.material.side isnt currentMeshSideA
      octreeA.mesh.material.side = currentMeshSideA
    if octreeB.mesh and octreeB.mesh.material.side isnt currentMeshSideB
      octreeB.mesh.material.side = currentMeshSideB
  else
    octreeA.getPolygonCloneCallback(octree.addPolygon.bind(octree), trianglesSet)

  trianglesSet.clear()
  trianglesSet = undefined

  octree.markPolygonsAsOriginal()
  buildTargetOctree and octree.buildTree()
  # octree.invert()
  octree

OctreeCSG.intersect = (octreeA, octreeB, buildTargetOctree = true) ->

  octree = new OctreeCSG()
  trianglesSet = new Set()

  if octreeA.box.intersectsBox(octreeB.box)

    currentMeshSideA = undefined
    currentMeshSideB = undefined

    if octreeA.mesh

      currentMeshSideA = octreeA.mesh.material.side
      octreeA.mesh.material.side = DoubleSide

    if octreeB.mesh

      currentMeshSideB = octreeB.mesh.material.side
      octreeB.mesh.material.side = DoubleSide

    octreeA.resetPolygons(false)
    octreeB.resetPolygons(false)

    octreeA.markIntesectingPolygons(octreeB)
    octreeB.markIntesectingPolygons(octreeA)

    handleIntersectingOctrees(octreeA, octreeB)

    octreeA.deleteReplacedPolygons()
    octreeB.deleteReplacedPolygons()

    octreeA.deletePolygonsByStateRules(CSG_Rules.intersect.a)
    octreeB.deletePolygonsByStateRules(CSG_Rules.intersect.b)

    octreeA.deletePolygonsByIntersection(false)
    octreeB.deletePolygonsByIntersection(false)

    octreeA.getPolygonCloneCallback(octree.addPolygon.bind(octree), trianglesSet)
    octreeB.getPolygonCloneCallback(octree.addPolygon.bind(octree), trianglesSet)

    if octreeA.mesh and octreeA.mesh.material.side isnt currentMeshSideA

      octreeA.mesh.material.side = currentMeshSideA

    if octreeB.mesh and octreeB.mesh.material.side isnt currentMeshSideB

      octreeB.mesh.material.side = currentMeshSideB

  trianglesSet.clear()
  trianglesSet = undefined

  octree.markPolygons

CSG_Rules =
  union:
    a: [
      { array: true, rule: ["inside", "coplanar-back"] }
      { array: false, rule: "inside" }
    ]
    b: [
      { array: true, rule: ["inside", "coplanar-back"] }
      { array: true, rule: ["inside", "coplanar-front"] }
      { array: false, rule: "inside" }
    ]
  subtract:
    a: [
      { array: true, rule: ["inside", "coplanar-back"] }
      { array: true, rule: ["inside", "coplanar-front"] }
      { array: false, rule: "inside" }
    ]
    b: [
      { array: true, rule: ["outside", "coplanar-back"] }
      { array: true, rule: ["outside", "coplanar-front"] }
      { array: true, rule: ["inside", "coplanar-front"] }
      { array: false, rule: "outside" }
    ]
  intersect:
    a: [
      { array: true, rule: ["inside", "coplanar-back"] }
      { array: true, rule: ["outside", "coplanar-front"] }
      { array: true, rule: ["outside", "coplanar-back"] }
      { array: false, rule: "outside" }
    ]
    b: [
      { array: true, rule: ["inside", "coplanar-front"] }
      { array: true, rule: ["inside", "coplanar-back"] }
      { array: true, rule: ["outside", "coplanar-front"] }
      { array: true, rule: ["outside", "coplanar-back"] }
      { array: false, rule: "outside" }
    ]

# class OctreeCSG { };

###
Union:
- Combine all polygons from A and B, except:
    - Polygons in A that are inside B or coplanar-back with B
    - Polygons in B that are inside A or coplanar-back/front with A
###

###
Subtract:
- Keep polygons from A that are outside B or coplanar-front with B
- Keep polygons from B that are inside A and coplanar-front with A
###

###
Intersect:
1. Delete all polygons in A that are:
    a. inside and coplanar-back
    b. outside and coplanar-front
    c. outside and coplanar-back
    d. outside
2. Delete all polygons in B that are:
    a. inside and coplanar-front
    b. inside and coplanar-back
    c. outside and coplanar-front
    d. outside and coplanar-back
    e. outside
###

OctreeCSG.union = (octreeA, octreeB, buildTargetOctree = true) ->
  octree = new OctreeCSG()
  trianglesSet = new Set()
  if octreeA.box.intersectsBox(octreeB.box)
    currentMeshSideA = undefined
    currentMeshSideB = undefined
    if octreeA.mesh
      currentMeshSideA = octreeA.mesh.material.side
      octreeA.mesh.material.side = DoubleSide
    if octreeB.mesh
      currentMeshSideB = octreeB.mesh.material.side
      octreeB.mesh.material.side = DoubleSide

    octreeA.resetPolygons(false)
    octreeB.resetPolygons(false)

    octreeA.markIntesectingPolygons(octreeB)
    octreeB.markIntesectingPolygons(octreeA)

    handleIntersectingOctrees(octreeA, octreeB)
    octreeA.deleteReplacedPolygons()
    octreeB.deleteReplacedPolygons()

    octreeA.deletePolygonsByStateRules(CSG_Rules.union.a)
    octreeB.deletePolygonsByStateRules(CSG_Rules.union.b)

    octreeA.getPolygonCloneCallback(octree.addPolygon.bind(octree), trianglesSet)
    octreeB.getPolygonCloneCallback(octree.addPolygon.bind(octree), trianglesSet)

    if octreeA.mesh and octreeA.mesh.material.side isnt currentMeshSideA
      octreeA.mesh.material.side = currentMeshSideA
    if octreeB.mesh and octreeB.mesh.material.side isnt currentMeshSideB
      octreeB.mesh.material.side = currentMeshSideB
  else
    octreeA.getPolygonCloneCallback(octree.addPolygon.bind(octree), trianglesSet)
    octreeB.getPolygonCloneCallback(octree.addPolygon.bind(octree), trianglesSet)

  trianglesSet.clear()
  trianglesSet = undefined

  octree.markPolygonsAsOriginal()
  buildTargetOctree and octree.buildTree()
  octree

OctreeCSG.subtract = (octreeA, octreeB, buildTargetOctree = true) ->
  octree = new OctreeCSG()
  trianglesSet = new Set()
  if octreeA.box.intersectsBox(octreeB.box)
    currentMeshSideA = undefined
    currentMeshSideB = undefined
    if octreeA.mesh
      currentMeshSideA = octreeA.mesh.material.side
      octreeA.mesh.material.side = DoubleSide
    if octreeB.mesh
      currentMeshSideB = octreeB.mesh.material.side
      octreeB.mesh.material.side = DoubleSide

    octreeA.resetPolygons(false)
    octreeB.resetPolygons(false)
    octreeA.markIntesectingPolygons(octreeB)
    octreeB.markIntesectingPolygons(octreeA)

    handleIntersectingOctrees(octreeA, octreeB)
    octreeA.deleteReplacedPolygons()
    octreeB.deleteReplacedPolygons()

    octreeA.deletePolygonsByStateRules(CSG_Rules.subtract.a)
    octreeB.deletePolygonsByStateRules(CSG_Rules.subtract.b)

    octreeB.deletePolygonsByIntersection(false)
    octreeB.invert()

    octreeA.getPolygonCloneCallback(octree.addPolygon.bind(octree), trianglesSet)
    octreeB.getPolygonCloneCallback(octree.addPolygon.bind(octree), trianglesSet)

    if octreeA.mesh and octreeA.mesh.material.side isnt currentMeshSideA
      octreeA.mesh.material.side = currentMeshSideA
    if octreeB.mesh and octreeB.mesh.material.side isnt currentMeshSideB
      octreeB.mesh.material.side = currentMeshSideB
  else
    octreeA.getPolygonCloneCallback(octree.addPolygon.bind(octree), trianglesSet)

  trianglesSet.clear()
  trianglesSet = undefined

  octree.markPolygonsAsOriginal()
  buildTargetOctree and octree.buildTree()
  # octree.invert()
  octree

###
Intersect:
1. Delete all polygons in A that are:
    a. inside and coplanar-back
    b. outside and coplanar-front
    c. outside and coplanar-back
    d. outside
2. Delete all polygons in B that are:
    a. inside and coplanar-front
    b. inside and coplanar-back
    c. outside and coplanar-front
    d. outside and coplanar-back
    e. outside
###
OctreeCSG.intersect = (octreeA, octreeB, buildTargetOctree = true) ->
    octree = new OctreeCSG()
    trianglesSet = new Set()

    if octreeA.box.intersectsBox(octreeB.box)
        currentMeshSideA = undefined
        currentMeshSideB = undefined
        if octreeA.mesh
            currentMeshSideA = octreeA.mesh.material.side
            octreeA.mesh.material.side = DoubleSide
        if octreeB.mesh
            currentMeshSideB = octreeB.mesh.material.side
            octreeB.mesh.material.side = DoubleSide

        octreeA.resetPolygons(false)
        octreeB.resetPolygons(false)

        octreeA.markIntesectingPolygons(octreeB)
        octreeB.markIntesectingPolygons(octreeA)

        handleIntersectingOctrees(octreeA, octreeB)
        octreeA.deleteReplacedPolygons()
        octreeB.deleteReplacedPolygons()

        octreeA.deletePolygonsByStateRules(CSG_Rules.intersect.a)
        octreeB.deletePolygonsByStateRules(CSG_Rules.intersect.b)

        octreeA.deletePolygonsByIntersection(false)
        octreeB.deletePolygonsByIntersection(false)

        octreeA.getPolygonCloneCallback(octree.addPolygon.bind(octree), trianglesSet)
        octreeB.getPolygonCloneCallback(octree.addPolygon.bind(octree), trianglesSet)

        if octreeA.mesh
            if octreeA.mesh.material.side isnt currentMeshSideA
                octreeA.mesh.material.side = currentMeshSideA
        if octreeB.mesh
            if octreeB.mesh.material.side isnt currentMeshSideB
                octreeB.mesh.material.side = currentMeshSideB

    trianglesSet.clear()
    trianglesSet = undefined

    octree.markPolygonsAsOriginal()
    buildTargetOctree and octree.buildTree()

    return octree

OctreeCSG.meshUnion = (mesh1, mesh2, targetMaterial) ->
    octreeA = undefined
    octreeB = undefined
    if targetMaterial and Array.isArray(targetMaterial)
        octreeA = OctreeCSG.fromMesh(mesh1, 0)
        octreeB = OctreeCSG.fromMesh(mesh2, 1)
    else
        octreeA = OctreeCSG.fromMesh(mesh1)
        octreeB = OctreeCSG.fromMesh(mesh2)
        targetMaterial = if targetMaterial isnt undefined then targetMaterial else (if Array.isArray(mesh1.material) then mesh1.material[0] else mesh1.material).clone()
    resultOctree = OctreeCSG.union(octreeA, octreeB, false)
    resultMesh = OctreeCSG.toMesh(resultOctree, targetMaterial)
    disposeOctree(octreeA, octreeB, resultOctree)
    return resultMesh

OctreeCSG.meshSubtract = (mesh1, mesh2, targetMaterial) ->
    octreeA = undefined
    octreeB = undefined
    if targetMaterial and Array.isArray(targetMaterial)
        octreeA = OctreeCSG.fromMesh(mesh1, 0)
        octreeB = OctreeCSG.fromMesh(mesh2, 1)
    else
        octreeA = OctreeCSG.fromMesh(mesh1)
        octreeB = OctreeCSG.fromMesh(mesh2)
        targetMaterial = if targetMaterial isnt undefined then targetMaterial else (if Array.isArray(mesh1.material) then mesh1.material[0] else mesh1.material).clone()
    resultOctree = OctreeCSG.subtract(octreeA, octreeB, false)
    resultMesh = OctreeCSG.toMesh(resultOctree, targetMaterial)
    disposeOctree(octreeA, octreeB, resultOctree)
    return resultMesh

OctreeCSG.meshIntersect = (mesh1, mesh2, targetMaterial) ->
    octreeA = undefined
    octreeB = undefined
    if targetMaterial and Array.isArray(targetMaterial)
        octreeA = OctreeCSG.fromMesh(mesh1, 0)
        octreeB = OctreeCSG.fromMesh(mesh2, 1)
    else
        octreeA = OctreeCSG.fromMesh(mesh1)
        octreeB = OctreeCSG.fromMesh(mesh2)
        targetMaterial = if targetMaterial isnt undefined then targetMaterial else (if Array.isArray(mesh1.material) then mesh1.material[0] else mesh1.material).clone()
    resultOctree = OctreeCSG.intersect(octreeA, octreeB, false)
    resultMesh = OctreeCSG.toMesh(resultOctree, targetMaterial)
    disposeOctree(octreeA, octreeB, resultOctree)
    return resultMesh

_asyncUnionID = 0
_asyncUnionArrayID = 0
OctreeCSG.disposeOctree = true

OctreeCSG.async =
    batchSize: 100

    union: (octreeA, octreeB, buildTargetOctree = true) ->
        new Promise (resolve, reject) ->
            # const id = _asyncUnionID++
            # console.log("Promise Union ##{id} started")
            try
                result = OctreeCSG.union(octreeA, octreeB, buildTargetOctree)
                resolve(result)
                disposeOctree(octreeA, octreeB)
            catch e
                reject(e)

    subtract: (octreeA, octreeB, buildTargetOctree = true) ->
        new Promise (resolve, reject) ->
            try
                result = OctreeCSG.subtract(octreeA, octreeB, buildTargetOctree)
                resolve(result)
                disposeOctree(octreeA, octreeB)
            catch e
                reject(e)

    intersect: (octreeA, octreeB, buildTargetOctree = true) ->
        new Promise (resolve, reject) ->
            try
                result = OctreeCSG.intersect(octreeA, octreeB, buildTargetOctree)
                resolve(result)
                disposeOctree(octreeA, octreeB)
            catch e
                reject(e)

    unionArray: (objArr, materialIndexMax = Infinity) ->
        new Promise (resolve, reject) ->
            try
                usingBatches = OctreeCSG.async.batchSize > 4 and OctreeCSG.async.batchSize < objArr.length
                # const id = _asyncUnionArrayID++
                # console.log("Promise Union Array ##{id}", usingBatches)
                mainOctree = undefined
                mainOctreeUsed = false
                promises = []
                if usingBatches
                    batches = []
                    currentIndex = 0
                    while currentIndex < objArr.length
                        batches.push objArr.slice(currentIndex, currentIndex + OctreeCSG.async.batchSize)
                        currentIndex += OctreeCSG.async.batchSize

                    batch = batches.shift()
                    while batch
                        promise = OctreeCSG.async.unionArray(batch, 0)
                        promises.push(promise)
                        batch = batches.shift()
                    usingBatches = true
                    mainOctreeUsed = true
                    objArr.length = 0
                else
                    octreesArray = []
                    for i in [0...objArr.length]
                        materialIndex = if i > materialIndexMax then materialIndexMax else i
                        tempOctree = undefined
                        if objArr[i].isMesh
                            tempOctree = OctreeCSG.fromMesh(objArr[i], if materialIndexMax > -1 then materialIndex else undefined)
                        else
                            tempOctree = objArr[i]
                            if materialIndexMax > -1
                                tempOctree.setPolygonIndex(materialIndex)
                        tempOctree.octreeIndex = i
                        octreesArray.push(tempOctree)
                    mainOctree = octreesArray.shift()
                    result = undefined
                    hasLeftOver = false
                    leftOverOctree = undefined
                    for i in [0...octreesArray.length] by 2
                        if i + 1 >= octreesArray.length
                            leftOverOctree = octreesArray[i]
                            hasLeftOver = true
                            break
                        promise = OctreeCSG.async.union(octreesArray[i], octreesArray[i + 1])
                        promises.push(promise)
                    if leftOverOctree
                        promise = OctreeCSG.async.union(mainOctree, leftOverOctree)
                        promises.push(promise)
                        mainOctreeUsed = true

                Promise.allSettled(promises).then (results) ->
                    octrees = []
                    results.forEach (r) ->
                        if r.status is "fulfilled"
                            octrees.push(r.value)
                    unless mainOctreeUsed
                        octrees.unshift(mainOctree)
                    if octrees.length > 0
                        if octrees.length is 1
                            resolve(octrees[0])
                        else if octrees.length > 3
                            OctreeCSG.async.unionArray(octrees, if usingBatches then 0 else -1).then (result) ->
                                resolve(result)
                            .catch (e) -> reject(e)
                        else
                            OctreeCSG.async.union(octrees[0], octrees[1]).then (result) ->
                                if octrees.length is 3
                                    OctreeCSG.async.union(result, octrees[2]).then (result) ->
                                        resolve(result)
                                    .catch (e) -> reject(e)
                                else
                                    resolve(result)
                            .catch (e) -> reject(e)
                    else
                        reject('Unable to find any result octree')
            catch e
                reject(e)

    subtractArray: (objArr, materialIndexMax = Infinity) ->
        new Promise (resolve, reject) ->
            try
                usingBatches = OctreeCSG.async.batchSize > 4 and OctreeCSG.async.batchSize < objArr.length
                mainOctree = undefined
                mainOctreeUsed = false
                promises = []
                if usingBatches
                    batches = []
                    currentIndex = 0
                    while currentIndex < objArr.length
                        batches.push objArr.slice(currentIndex, currentIndex + OctreeCSG.async.batchSize)
                        currentIndex += OctreeCSG.async.batchSize

                    batch = batches.shift()
                    while batch
                        promise = OctreeCSG.async.subtractArray(batch, 0)
                        promises.push(promise)
                        batch = batches.shift()
                    usingBatches = true
                    mainOctreeUsed = true
                    objArr.length = 0
                else
                    octreesArray = []
                    for i in [0...objArr.length]
                        materialIndex = if i > materialIndexMax then materialIndexMax else i
                        tempOctree = undefined
                        if objArr[i].isMesh
                            tempOctree = OctreeCSG.fromMesh(objArr[i], if materialIndexMax > -1 then materialIndex else undefined)
                        else
                            tempOctree = objArr[i]
                            if materialIndexMax > -1
                                tempOctree.setPolygonIndex(materialIndex)
                        tempOctree.octreeIndex = i
                        octreesArray.push(tempOctree)
                    mainOctree = octreesArray.shift()
                    result = undefined
                    hasLeftOver = false
                    leftOverOctree = undefined
                    for i in [0...octreesArray.length] by 2
                        if i + 1 >= octreesArray.length
                            leftOverOctree = octreesArray[i]
                            hasLeftOver = true
                            break
                        promise = OctreeCSG.async.subtract(octreesArray[i], octreesArray[i + 1])
                        promises.push(promise)
                    if leftOverOctree
                        promise = OctreeCSG.async.subtract(mainOctree, leftOverOctree)
                        promises.push(promise)
                        mainOctreeUsed = true

                Promise.allSettled(promises).then (results) ->
                    octrees = []
                    results.forEach (r) ->
                        if r.status is "fulfilled"
                            octrees.push(r.value)
                    unless mainOctreeUsed
                        octrees.unshift(mainOctree)
                    if octrees.length > 0
                        if octrees.length is 1
                            resolve(octrees[0])
                        else if octrees.length > 3
                            OctreeCSG.async.subtractArray(octrees, if usingBatches then 0 else -1).then (result) ->
                                resolve(result)
                            .catch (e) -> reject(e)
                        else
                            OctreeCSG.async.subtract(octrees[0], octrees[1]).then (result) ->
                                if octrees.length is 3
                                    OctreeCSG.async.subtract(result, octrees[2]).then (result) ->
                                        resolve(result)
                                    .catch (e) -> reject(e)
                                else
                                    resolve(result)
                            .catch (e) -> reject(e)
                    else
                        reject('Unable to find any result octree')
            catch e
                reject(e)

    intersectArray: (objArr, materialIndexMax = Infinity) ->
        new Promise (resolve, reject) ->
            try
                usingBatches = OctreeCSG.async.batchSize > 4 and OctreeCSG.async.batchSize < objArr.length
                mainOctree = undefined
                mainOctreeUsed = false
                promises = []
                if usingBatches
                    batches = []
                    currentIndex = 0
                    while currentIndex < objArr.length
                        batches.push objArr.slice(currentIndex, currentIndex + OctreeCSG.async.batchSize)
                        currentIndex += OctreeCSG.async.batchSize

                    batch = batches.shift()
                    while batch
                        promise = OctreeCSG.async.intersectArray(batch, 0)
                        promises.push(promise)
                        batch = batches.shift()
                    usingBatches = true
                    mainOctreeUsed = true
                    objArr.length = 0
                else
                    octreesArray = []
                    for i in [0...objArr.length]
                        materialIndex = if i > materialIndexMax then materialIndexMax else i
                        tempOctree = undefined
                        if objArr[i].isMesh
                            tempOctree = OctreeCSG.fromMesh(objArr[i], if materialIndexMax > -1 then materialIndex else undefined)
                        else
                            tempOctree = objArr[i]
                            if materialIndexMax > -1
                                tempOctree.setPolygonIndex(materialIndex)
                        tempOctree.octreeIndex = i
                        octreesArray.push(tempOctree)
                    mainOctree = octreesArray.shift()
                    result = undefined
                    hasLeftOver = false
                    leftOverOctree = undefined
                    for i in [0...octreesArray.length] by 2
                        if i + 1 >= octreesArray.length
                            leftOverOctree = octreesArray[i]
                            hasLeftOver = true
                            break
                        promise = OctreeCSG.async.intersect(octreesArray[i], octreesArray[i + 1])
                        promises.push(promise)
                    if leftOverOctree
                        promise = OctreeCSG.async.intersect(mainOctree, leftOverOctree)
                        promises.push(promise)
                        mainOctreeUsed = true

                Promise.allSettled(promises).then (results) ->
                    octrees = []
                    results.forEach (r) ->
                        if r.status is "fulfilled"
                            octrees.push(r.value)
                    unless mainOctreeUsed
                        octrees.unshift(mainOctree)
                    if octrees.length > 0
                        if octrees.length is 1
                            resolve(octrees[0])
                        else if octrees.length > 3
                            OctreeCSG.async.intersectArray(octrees, if usingBatches then 0 else -1).then (result) ->
                                resolve(result)
                            .catch (e) -> reject(e)
                        else
                            OctreeCSG.async.intersect(octrees[0], octrees[1]).then (result) ->
                                if octrees.length is 3
                                    OctreeCSG.async.intersect(result, octrees[2]).then (result) ->
                                        resolve(result)
                                    .catch (e) -> reject(e)
                                else
                                    resolve(result)
                            .catch (e) -> reject(e)
                    else
                        reject('Unable to find any result octree')
            catch e
                reject(e)

    operation: (obj, returnOctrees = false, buildTargetOctree = true, options = { objCounter: 0 }, firstRun = true) ->
        new Promise (resolve, reject) ->
            try
                octreeA = undefined
                octreeB = undefined
                resultOctree = undefined
                material = undefined
                if obj.material
                    material = obj.material
                promises = []
                if obj.objA
                    promise = handleObjectForOp_async(obj.objA, returnOctrees, buildTargetOctree, options, 0)
                    promises.push(promise)
                if obj.objB
                    promise = handleObjectForOp_async(obj.objB, returnOctrees, buildTargetOctree, options, 1)
                    promises.push(promise)
                Promise.allSettled(promises).then (results) ->
                    octrees = []
                    results.forEach (r) ->
                        if r.status is "fulfilled"
                            if r.value.objIndex is 0
                                octreeA = r.value
                            else if r.value.objIndex is 1
                                octreeB = r.value
                    if returnOctrees is true
                        obj.objA = octreeA.original
                        octreeA = octreeA.result
                        obj.objB = octreeB.original
                        octreeB = octreeB.result
                    resultPromise = undefined
                    switch obj.op
                        when 'union'
                            resultPromise = OctreeCSG.async.union(octreeA, octreeB, buildTargetOctree)
                        when 'subtract'
                            resultPromise = OctreeCSG.async.subtract(octreeA, octreeB, buildTargetOctree)
                        when 'intersect'
                            resultPromise = OctreeCSG.async.intersect(octreeA, octreeB, buildTargetOctree)
                    resultPromise.then (resultOctree) ->
                        if firstRun and material
                            mesh = OctreeCSG.toMesh(resultOctree, material)
                            unless returnOctrees
                                disposeOctree(resultOctree)
                            resolve(if returnOctrees then { result: mesh, operationTree: obj } else mesh)
                        else if firstRun and returnOctrees
                            resolve({ result: resultOctree, operationTree: obj })
                        else
                            resolve(resultOctree)
                        unless returnOctrees
                            disposeOctree(octreeA, octreeB)
                    .catch (e) -> reject(e)
            catch e
                reject(e)

OctreeCSG.unionArray = (objArr, materialIndexMax = Infinity) ->
    octreesArray = []
    for i in [0...objArr.length]
        materialIndex = if i > materialIndexMax then materialIndexMax else i
        tempOctree = undefined
        if objArr[i].isMesh
            tempOctree = OctreeCSG.fromMesh(objArr[i], materialIndex)
        else
            tempOctree = objArr[i]
            tempOctree.setPolygonIndex(materialIndex)
        tempOctree.octreeIndex = i
        octreesArray.push(tempOctree)
    octreeA = octreesArray.shift()
    octreeB = octreesArray.shift()
    while octreeA and octreeB
        resultOctree = OctreeCSG.union(octreeA, octreeB)
        disposeOctree(octreeA, octreeB)
        octreeA = resultOctree
        octreeB = octreesArray.shift()
    octreeA

OctreeCSG.subtractArray = (objArr, materialIndexMax = Infinity) ->
    octreesArray = []
    for i in [0...objArr.length]
        materialIndex = if i > materialIndexMax then materialIndexMax else i
        tempOctree = undefined
        if objArr[i].isMesh
            tempOctree = OctreeCSG.fromMesh(objArr[i], materialIndex)
        else
            tempOctree = objArr[i]
            tempOctree.setPolygonIndex(materialIndex)
        tempOctree.octreeIndex = i
        octreesArray.push(tempOctree)
    octreeA = octreesArray.shift()
    octreeB = octreesArray.shift()
    while octreeA and octreeB
        resultOctree = OctreeCSG.subtract(octreeA, octreeB)
        disposeOctree(octreeA, octreeB)
        octreeA = resultOctree
        octreeB = octreesArray.shift()
    octreeA

OctreeCSG.intersectArray = (objArr, materialIndexMax = Infinity) ->
    octreesArray = []
    for i in [0...objArr.length]
        materialIndex = if i > materialIndexMax then materialIndexMax else i
        tempOctree = undefined
        if objArr[i].isMesh
            tempOctree = OctreeCSG.fromMesh(objArr[i], materialIndex)
        else
            tempOctree = objArr[i]
            tempOctree.setPolygonIndex(materialIndex)
        tempOctree.octreeIndex = i
        octreesArray.push(tempOctree)
    octreeA = octreesArray.shift()
    octreeB = octreesArray.shift()
    while octreeA and octreeB
        resultOctree = OctreeCSG.intersect(octreeA, octreeB)
        disposeOctree(octreeA, octreeB)
        octreeA = resultOctree
        octreeB = octreesArray.shift()
    octreeA

OctreeCSG.operation = (obj, returnOctrees = false, buildTargetOctree = true, options = { objCounter: 0 }, firstRun = true) ->
    octreeA = undefined
    octreeB = undefined
    resultOctree = undefined
    material = undefined
    if obj.material
        material = obj.material
    if obj.objA
        octreeA = handleObjectForOp(obj.objA, returnOctrees, buildTargetOctree, options)
        if returnOctrees == true
            obj.objA = octreeA.original
            octreeA = octreeA.result
    if obj.objB
        octreeB = handleObjectForOp(obj.objB, returnOctrees, buildTargetOctree, options)
        if returnOctrees == true
            obj.objB = octreeB.original
            octreeB = octreeB.result
    switch obj.op
        when 'union'
            resultOctree = OctreeCSG.union(octreeA, octreeB, buildTargetOctree)
        when 'subtract'
            resultOctree = OctreeCSG.subtract(octreeA, octreeB, buildTargetOctree)
        when 'intersect'
            resultOctree = OctreeCSG.intersect(octreeA, octreeB, buildTargetOctree)
    unless returnOctrees
        disposeOctree(octreeA, octreeB)
    if firstRun and material
        mesh = OctreeCSG.toMesh(resultOctree, material)
        disposeOctree(resultOctree)
        return if returnOctrees then { result: mesh, operationTree: obj } else mesh
    if firstRun and returnOctrees
        return { result: resultOctree, operationTree: obj }
    resultOctree

handleObjectForOp = (obj, returnOctrees, buildTargetOctree, options) ->
    returnObj = undefined
    if obj.isMesh
        returnObj = OctreeCSG.fromMesh(obj, options.objCounter++)
        if returnOctrees
            returnObj = { result: returnObj, original: returnObj.clone() }
    else if obj.isOctree
        returnObj = obj
        if returnOctrees
            returnObj = { result: obj, original: obj.clone() }
    else if obj.op
        returnObj = OctreeCSG.operation(obj, returnOctrees, buildTargetOctree, options, false)
        if returnOctrees
            returnObj = { result: returnObj, original: obj }
    return returnObj

handleObjectForOp_async = (obj, returnOctrees, buildTargetOctree, options, objIndex) ->
    new Promise (resolve, reject) ->
        try
            returnObj = undefined
            if obj.isMesh
                returnObj = OctreeCSG.fromMesh(obj, options.objCounter++)
                if returnOctrees
                    returnObj = { result: returnObj, original: returnObj.clone() }
                returnObj.objIndex = objIndex
                resolve(returnObj)
            else if obj.isOctree
                returnObj = obj
                if returnOctrees
                    returnObj = { result: obj, original: obj.clone() }
                returnObj.objIndex = objIndex
                resolve(returnObj)
            else if obj.op
                OctreeCSG.async.operation(obj, returnOctrees, buildTargetOctree, options, false).then (returnObj) ->
                    if returnOctrees
                        returnObj = { result: returnObj, original: obj }
                    returnObj.objIndex = objIndex
                    resolve(returnObj)
        catch e
            reject(e)

isUniqueTriangle = (triangle, set, map) ->
    hash1 = "{#{triangle.a.x},#{triangle.a.y},#{triangle.a.z}}-{#{triangle.b.x},#{triangle.b.y},#{triangle.b.z}}-{#{triangle.c.x},#{triangle.c.y},#{triangle.c.z}}"
    if set.has(hash1) is true
        false
    else
        set.add(hash1)
        if map
            map.set(triangle, triangle)
        true

nbuf3 = (ct) ->
    top: 0
    array: new Float32Array(ct)
    write: (v) ->
        @array[@top++] = v.x
        @array[@top++] = v.y
        @array[@top++] = v.z

nbuf2 = (ct) ->
    top: 0
    array: new Float32Array(ct)
    write: (v) ->
        @array[@top++] = v.x
        @array[@top++] = v.y

_normal1 = new Vector3()
tmpm3 = new Matrix3()
ttvv0 = new Vector3()

OctreeCSG.toGeometry = (octree) ->
    polygons = octree.getPolygons()
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

    geometry

OctreeCSG.toMesh = (octree, toMaterial) ->
    geometry = OctreeCSG.toGeometry(octree)
    new Mesh(geometry, toMaterial)

OctreeCSG.fromMesh = (obj, objectIndex, octree = new OctreeCSG(), buildTargetOctree = true) ->
    return obj if obj.isOctree
    if OctreeCSG.rayIntersectTriangleType is "regular"
        octree.originalMatrixWorld = obj.matrixWorld.clone()
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

            vi = index[i + j]
            vp = vi * 3
            vt = vi * 2

            pos = new Vector3(posattr.array[vp], posattr.array[vp + 1], posattr.array[vp + 2])
            normal = new Vector3(normalattr.array[vp], normalattr.array[vp + 1], normalattr.array[vp + 2])

            pos.applyMatrix4(obj.matrix)
            normal.applyMatrix3(tmpm3)

            uv =
                if uvattr
                    { x: uvattr.array[vt], y: uvattr.array[vt + 1] }
                else
                    undefined

            color =
                if colorattr
                    { x: colorattr.array[vt], y: colorattr.array[vt + 1], z: colorattr.array[vt + 2] }
                else
                    undefined

            vertices.push(new Vertex(pos, normal, uv, color))

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
            octree.addPolygon(polys[i])
        else
            polys[i].delete()
    buildTargetOctree and octree.buildTree()
    if OctreeCSG.useOctreeRay isnt true
        octree.mesh = obj
    return octree

isValidTriangle = (triangle) ->

    return false if triangle.a.equals(triangle.b)
    return false if triangle.a.equals(triangle.c)
    return false if triangle.b.equals(triangle.c)

    return true

# class Vertex
class Vertex

    constructor: (pos, normal, uv, color) ->

        @pos = new Vector3().copy(pos)
        @normal = new Vector3().copy(normal)
        uv and (@uv = new Vector2().copy(uv))
        color and (@color = new Vector3().copy(color))

    clone: ->

        new Vertex(@pos.clone(), @normal.clone(), @uv and @uv.clone(), @color and @color.clone())

    flip: ->

        @normal.negate()

    delete: ->

        @pos = undefined
        @normal = undefined
        @uv and (@uv = undefined)
        @color and (@color = undefined)

    interpolate: (other, t) ->

        new Vertex(
            @pos.clone().lerp(other.pos, t),
            @normal.clone().lerp(other.normal, t),
            @uv and other.uv and @uv.clone().lerp(other.uv, t),
            @color and other.color and @color.clone().lerp(other.color, t)
        )

# class Plane
class Plane

    constructor: (normal, w) ->

        @normal = normal
        @w = w

    clone: ->

        new Plane(@normal.clone(), @w)

    flip: ->

        @normal.negate()
        @w = -@w

    delete: ->

        @normal = undefined
        @w = undefined

    equals: (p) ->

        @normal.equals(p.normal) and @w is p.w

Plane.fromPoints = (a, b, c) ->

    n = tv0.copy(b).sub(a).cross(tv1.copy(c).sub(a)).normalize().clone()
    new Plane(n, n.dot(a))

# class Polygon
class Polygon

    constructor: (vertices, shared) ->

        @id = _polygonID++
        @vertices = vertices.map((v) -> v.clone())
        @shared = shared
        @plane = Plane.fromPoints(@vertices[0].pos, @vertices[1].pos, @vertices[2].pos)
        @triangle = new Triangle(@vertices[0].pos, @vertices[1].pos, @vertices[2].pos)
        @intersects = false
        @state = "undecided"
        @previousState = "undecided"
        @previousStates = []
        @valid = true
        @coplanar = false
        @originalValid = false
        @newPolygon = false

    getMidpoint: ->

        if @triangle.midPoint then @triangle.midPoint else @triangle.midPoint = @triangle.getMidpoint(new Vector3())

    applyMatrix: (matrix, normalMatrix) ->

        normalMatrix = normalMatrix or tmpm3.getNormalMatrix(matrix)
        @vertices.forEach (v) ->
            v.pos.applyMatrix4(matrix)
            v.normal.applyMatrix3(normalMatrix)
        @plane.delete()
        @plane = Plane.fromPoints(@vertices[0].pos, @vertices[1].pos, @vertices[2].pos)
        @triangle.set(@vertices[0].pos, @vertices[1].pos, @vertices[2].pos)
        if @triangle.midPoint
            @triangle.getMidpoint(@triangle.midPoint)

    reset: (resetOriginal = true) ->

        @intersects = false
        @state = "undecided"
        @previousState = "undecided"
        @previousStates.length = 0
        @valid = true
        @coplanar = false
        resetOriginal and (@originalValid = false)
        @newPolygon = false

    setState: (state, keepState) ->

        return if @state is keepState
        @previousState = @state
        @state isnt "undecided" and @previousStates.push(@state)
        @state = state

    checkAllStates: (state) ->

        return false if (@state isnt state) or ((@previousState isnt state) and (@previousState isnt "undecided"))
        for s in @previousStates
            return false if s isnt state
        true

    setInvalid: -> @valid = false

    setValid: -> @valid = true

    clone: ->

        polygon = new Polygon(@vertices.map((v) -> v.clone()), @shared)
        polygon.intersects = @intersects
        polygon.valid = @valid
        polygon.coplanar = @coplanar
        polygon.state = @state
        polygon.originalValid = @originalValid
        polygon.newPolygon = @newPolygon
        polygon.previousState = @previousState
        polygon.previousStates = @previousStates.slice()
        if @triangle.midPoint
            polygon.triangle.midPoint = @triangle.midPoint.clone()
        return polygon

    flip: ->

        @vertices.reverse().forEach((v) -> v.flip())
        tmp = @triangle.a
        @triangle.a = @triangle.c
        @triangle.c = tmp
        @plane.flip()

    delete: ->

        @vertices.forEach((v) -> v.delete())
        @vertices.length = 0
        if @plane
            @plane.delete()
            @plane = undefined
        @triangle = undefined
        @shared = undefined
        @setInvalid()

disposeOctree = (...octrees) ->

    if OctreeCSG.disposeOctree

        octrees.forEach((octree) -> octree.delete())

# Winding Number algorithm adapted from https://github.com/grame-cncm/faust/blob/master-dev/tools/physicalModeling/mesh2faust/vega/libraries/windingNumber/windingNumber.cpp
_wV1 = new Vector3()
_wV2 = new Vector3()
_wV3 = new Vector3()
_wP = new Vector3()
_wP_EPS_ARR = [
    new Vector3(EPSILON, 0, 0)
    new Vector3(0, EPSILON, 0)
    new Vector3(0, 0, EPSILON)
    new Vector3(-EPSILON, 0, 0)
    new Vector3(0, -EPSILON, 0)
    new Vector3(0, 0, -EPSILON)
]
_wP_EPS_ARR_COUNT = _wP_EPS_ARR.length
_matrix3 = new Matrix3()
wNPI = 4 * Math.PI

returnXYZ = (arr, index) ->
    x: arr[index]
    y: arr[index + 1]
    z: arr[index + 2]

calcWindingNumber_buffer = (trianglesArr, point) ->
    wN = 0
    for i in [0...trianglesArr.length] by 9
        _wV1.subVectors(returnXYZ(trianglesArr, i), point)
        _wV2.subVectors(returnXYZ(trianglesArr, i + 3), point)
        _wV3.subVectors(returnXYZ(trianglesArr, i + 6), point)
        lenA = _wV1.length()
        lenB = _wV2.length()
        lenC = _wV3.length()
        _matrix3.set(_wV1.x, _wV1.y, _wV1.z, _wV2.x, _wV2.y, _wV2.z, _wV3.x, _wV3.y, _wV3.z)
        omega = 2 * Math.atan2(_matrix3.determinant(), (lenA * lenB * lenC + _wV1.dot(_wV2) * lenC + _wV2.dot(_wV3) * lenA + _wV3.dot(_wV1) * lenB))
        wN += omega
    wN = Math.round(wN / wNPI)
    wN

polyInside_WindingNumber_buffer = (trianglesArr, point, coplanar) ->
    result = false
    _wP.copy(point)
    wN = calcWindingNumber_buffer(trianglesArr, _wP)
    if wN is 0
        if coplanar
            for j in [0..._wP_EPS_ARR_COUNT]
                _wP.copy(point).add(_wP_EPS_ARR[j])
                wN = calcWindingNumber_buffer(trianglesArr, _wP)
                if wN isnt 0
                    result = true
                    break
    else
        result = true
    result

# -----

handleIntersectingOctrees = (octreeA, octreeB, bothOctrees = true) ->
    octreeA_buffer = undefined
    octreeB_buffer = undefined
    if OctreeCSG.useWindingNumber is true
        if bothOctrees
            octreeA_buffer = prepareTriangleBuffer(octreeA.getPolygons())
        octreeB_buffer = prepareTriangleBuffer(octreeB.getPolygons())
    octreeA.handleIntersectingPolygons(octreeB, octreeB_buffer)
    if bothOctrees
        octreeB.handleIntersectingPolygons(octreeA, octreeA_buffer)
    if octreeA_buffer isnt undefined
        octreeA_buffer = undefined
        octreeB_buffer = undefined

prepareTriangleBuffer = (polygons) ->
    numOfTriangles = polygons.length
    array = new Float32Array(numOfTriangles * 3 * 3)
    bufferIndex = 0
    for i in [0...numOfTriangles]
        triangle = polygons[i].triangle
        array[bufferIndex++] = triangle.a.x
        array[bufferIndex++] = triangle.a.y
        array[bufferIndex++] = triangle.a.z
        array[bufferIndex++] = triangle.b.x
        array[bufferIndex++] = triangle.b.y
        array[bufferIndex++] = triangle.b.z
        array[bufferIndex++] = triangle.c.x
        array[bufferIndex++] = triangle.c.y
        array[bufferIndex++] = triangle.c.z
    array

# https://en.wikipedia.org/wiki/M%C3%B6ller%E2%80%93Trumbore_intersection_algorithm
edge1 = new Vector3()
edge2 = new Vector3()
h = new Vector3()
s = new Vector3()
q = new Vector3()
RAY_EPSILON = 0.0000001

rayIntersectsTriangle = (ray, triangle, target = new Vector3()) ->
    edge1.subVectors(triangle.b, triangle.a)
    edge2.subVectors(triangle.c, triangle.a)
    h.crossVectors(ray.direction, edge2)
    a = edge1.dot(h)
    if a > -RAY_EPSILON and a < RAY_EPSILON
        return null # Ray is parallel to the triangle
    f = 1 / a
    s.subVectors(ray.origin, triangle.a)
    u = f * s.dot(h)
    if u < 0 or u > 1
        return null
    q.crossVectors(s, edge1)
    v = f * ray.direction.dot(q)
    if v < 0 or u + v > 1
        return null
    t = f * edge2.dot(q)
    if t > RAY_EPSILON
        return target.copy(ray.direction).multiplyScalar(t).add(ray.origin)
    null

OctreeCSG.rayIntersectsTriangle = rayIntersectsTriangle

OctreeCSG.useOctreeRay = true
OctreeCSG.useWindingNumber = false
OctreeCSG.rayIntersectTriangleType = "MollerTrumbore" # "regular" (three.js' ray.intersectTriangle; "MollerTrumbore" (Moller Trumbore algorithm);
OctreeCSG.maxLevel = 16
OctreeCSG.polygonsPerTree = 100
# OctreeCSG.Octree = Octree

module.exports =

    default: OctreeCSG
    CSG: OctreeCSG
    OctreeCSG: OctreeCSG
    Polygon: Polygon
    Plane: Plane
    Vertex: Vertex
    rayIntersectsTriangle: rayIntersectsTriangle
