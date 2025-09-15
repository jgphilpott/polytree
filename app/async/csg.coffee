# Async CSG operations for Polytree
# This module contains all async operations that were moved from polytree.coffee

handleObjectForOp_async = (obj, returnPolytrees, buildTargetPolytree, options, objIndex) ->

    new Promise (resolve, reject) ->

        try

            returnObj = undefined

            if obj.isMesh

                returnObj = Polytree.fromMesh(obj, options.objCounter++)

                if returnPolytrees

                    returnObj = { result: returnObj, original: returnObj.clone() }

                returnObj.objIndex = objIndex
                resolve(returnObj)

            else if obj.isPolytree

                returnObj = obj

                if returnPolytrees

                    returnObj = { result: obj, original: obj.clone() }

                returnObj.objIndex = objIndex
                resolve(returnObj)

            else if obj.op

                Polytree.async.operation(obj, returnPolytrees, buildTargetPolytree, options, false).then (returnObj) ->

                    if returnPolytrees

                        returnObj = { result: returnObj, original: obj }

                    returnObj.objIndex = objIndex
                    resolve(returnObj)

        catch e

            reject(e)

Polytree.async =

    batchSize: 100

    unite: (polytreeA, polytreeB, buildTargetPolytree = true) ->

        new Promise (resolve, reject) ->

            try

                result = Polytree.uniteCore(polytreeA, polytreeB, buildTargetPolytree)
                resolve(result)
                disposePolytree(polytreeA, polytreeB)

            catch e

                reject(e)

    subtract: (polytreeA, polytreeB, buildTargetPolytree = true) ->

        new Promise (resolve, reject) ->

            try

                result = Polytree.subtractCore(polytreeA, polytreeB, buildTargetPolytree)
                resolve(result)
                disposePolytree(polytreeA, polytreeB)

            catch e

                reject(e)

    intersect: (polytreeA, polytreeB, buildTargetPolytree = true) ->

        new Promise (resolve, reject) ->

            try

                result = Polytree.intersectCore(polytreeA, polytreeB, buildTargetPolytree)
                resolve(result)
                disposePolytree(polytreeA, polytreeB)

            catch e

                reject(e)

    uniteArray: (objArr, materialIndexMax = Infinity) ->

        new Promise (resolve, reject) ->

            try

                usingBatches = Polytree.async.batchSize > 4 and Polytree.async.batchSize < objArr.length
                mainPolytree = undefined
                mainPolytreeUsed = false
                promises = []

                if usingBatches

                    batches = []
                    currentIndex = 0

                    while currentIndex < objArr.length

                        batches.push objArr.slice(currentIndex, currentIndex + Polytree.async.batchSize)
                        currentIndex += Polytree.async.batchSize

                    batch = batches.shift()

                    while batch

                        promise = Polytree.async.uniteArray(batch, 0)
                        promises.push(promise)
                        batch = batches.shift()

                    usingBatches = true
                    mainPolytreeUsed = true
                    objArr.length = 0

                else

                    polytreesArray = []

                    for i in [0...objArr.length]

                        materialIndex = if i > materialIndexMax then materialIndexMax else i
                        tempPolytree = undefined

                        if objArr[i].isMesh

                            tempPolytree = Polytree.fromMesh(objArr[i], if materialIndexMax > -1 then materialIndex else undefined)

                        else

                            tempPolytree = objArr[i]

                            if materialIndexMax > -1

                                tempPolytree.setPolygonIndex(materialIndex)

                        tempPolytree.polytreeIndex = i
                        polytreesArray.push(tempPolytree)

                    mainPolytree = polytreesArray.shift()
                    result = undefined
                    hasLeftOver = false
                    leftOverPolytree = undefined

                    for i in [0...polytreesArray.length] by 2

                        if i + 1 >= polytreesArray.length

                            leftOverPolytree = polytreesArray[i]
                            hasLeftOver = true
                            break

                        promise = Polytree.async.unite(polytreesArray[i], polytreesArray[i + 1])
                        promises.push(promise)

                    if leftOverPolytree

                        promise = Polytree.async.unite(mainPolytree, leftOverPolytree)
                        promises.push(promise)
                        mainPolytreeUsed = true

                Promise.allSettled(promises).then (results) ->

                    polytrees = []

                    results.forEach (r) ->

                        if r.status is "fulfilled"

                            polytrees.push(r.value)

                    unless mainPolytreeUsed

                        polytrees.unshift(mainPolytree)

                    if polytrees.length > 0

                        if polytrees.length is 1

                            resolve(polytrees[0])

                        else if polytrees.length > 3

                            Polytree.async.uniteArray(polytrees, if usingBatches then 0 else -1).then (result) ->

                                resolve(result)

                            .catch (e) -> reject(e)

                        else

                            Polytree.async.unite(polytrees[0], polytrees[1]).then (result) ->

                                if polytrees.length is 3

                                    Polytree.async.unite(result, polytrees[2]).then (result) ->

                                        resolve(result)

                                    .catch (e) -> reject(e)

                                else

                                    resolve(result)

                            .catch (e) -> reject(e)

                    else

                        reject('Unable to find any result polytree')

            catch e

                reject(e)

    subtractArray: (objArr, materialIndexMax = Infinity) ->

        new Promise (resolve, reject) ->

            try

                usingBatches = Polytree.async.batchSize > 4 and Polytree.async.batchSize < objArr.length
                mainPolytree = undefined
                mainPolytreeUsed = false
                promises = []

                if usingBatches

                    batches = []
                    currentIndex = 0

                    while currentIndex < objArr.length

                        batches.push objArr.slice(currentIndex, currentIndex + Polytree.async.batchSize)
                        currentIndex += Polytree.async.batchSize

                    batch = batches.shift()

                    while batch

                        promise = Polytree.async.subtractArray(batch, 0)
                        promises.push(promise)
                        batch = batches.shift()

                    usingBatches = true
                    mainPolytreeUsed = true
                    objArr.length = 0

                else

                    polytreesArray = []

                    for i in [0...objArr.length]

                        materialIndex = if i > materialIndexMax then materialIndexMax else i
                        tempPolytree = undefined

                        if objArr[i].isMesh

                            tempPolytree = Polytree.fromMesh(objArr[i], if materialIndexMax > -1 then materialIndex else undefined)

                        else

                            tempPolytree = objArr[i]

                            if materialIndexMax > -1

                                tempPolytree.setPolygonIndex(materialIndex)

                        tempPolytree.polytreeIndex = i
                        polytreesArray.push(tempPolytree)

                    mainPolytree = polytreesArray.shift()
                    result = undefined
                    hasLeftOver = false
                    leftOverPolytree = undefined

                    for i in [0...polytreesArray.length] by 2

                        if i + 1 >= polytreesArray.length

                            leftOverPolytree = polytreesArray[i]
                            hasLeftOver = true
                            break

                        promise = Polytree.async.subtract(polytreesArray[i], polytreesArray[i + 1])
                        promises.push(promise)

                    if leftOverPolytree

                        promise = Polytree.async.subtract(mainPolytree, leftOverPolytree)
                        promises.push(promise)
                        mainPolytreeUsed = true

                Promise.allSettled(promises).then (results) ->

                    polytrees = []

                    results.forEach (r) ->

                        if r.status is "fulfilled"

                            polytrees.push(r.value)

                    unless mainPolytreeUsed

                        polytrees.unshift(mainPolytree)

                    if polytrees.length > 0

                        if polytrees.length is 1

                            resolve(polytrees[0])

                        else if polytrees.length > 3

                            Polytree.async.subtractArray(polytrees, if usingBatches then 0 else -1).then (result) ->

                                resolve(result)

                            .catch (e) -> reject(e)

                        else

                            Polytree.async.subtract(polytrees[0], polytrees[1]).then (result) ->

                                if polytrees.length is 3

                                    Polytree.async.subtract(result, polytrees[2]).then (result) ->

                                        resolve(result)

                                    .catch (e) -> reject(e)

                                else

                                    resolve(result)

                            .catch (e) -> reject(e)

                    else

                        reject('Unable to find any result polytree')

            catch e

                reject(e)

    intersectArray: (objArr, materialIndexMax = Infinity) ->

        new Promise (resolve, reject) ->

            try

                usingBatches = Polytree.async.batchSize > 4 and Polytree.async.batchSize < objArr.length
                mainPolytree = undefined
                mainPolytreeUsed = false
                promises = []

                if usingBatches

                    batches = []
                    currentIndex = 0

                    while currentIndex < objArr.length

                        batches.push objArr.slice(currentIndex, currentIndex + Polytree.async.batchSize)
                        currentIndex += Polytree.async.batchSize

                    batch = batches.shift()

                    while batch

                        promise = Polytree.async.intersectArray(batch, 0)
                        promises.push(promise)
                        batch = batches.shift()

                    usingBatches = true
                    mainPolytreeUsed = true
                    objArr.length = 0

                else

                    polytreesArray = []

                    for i in [0...objArr.length]

                        materialIndex = if i > materialIndexMax then materialIndexMax else i
                        tempPolytree = undefined

                        if objArr[i].isMesh

                            tempPolytree = Polytree.fromMesh(objArr[i], if materialIndexMax > -1 then materialIndex else undefined)

                        else

                            tempPolytree = objArr[i]

                            if materialIndexMax > -1

                                tempPolytree.setPolygonIndex(materialIndex)

                        tempPolytree.polytreeIndex = i
                        polytreesArray.push(tempPolytree)

                    mainPolytree = polytreesArray.shift()
                    result = undefined
                    hasLeftOver = false
                    leftOverPolytree = undefined

                    for i in [0...polytreesArray.length] by 2

                        if i + 1 >= polytreesArray.length

                            leftOverPolytree = polytreesArray[i]
                            hasLeftOver = true
                            break

                        promise = Polytree.async.intersect(polytreesArray[i], polytreesArray[i + 1])
                        promises.push(promise)

                    if leftOverPolytree

                        promise = Polytree.async.intersect(mainPolytree, leftOverPolytree)
                        promises.push(promise)
                        mainPolytreeUsed = true

                Promise.allSettled(promises).then (results) ->

                    polytrees = []

                    results.forEach (r) ->

                        if r.status is "fulfilled"

                            polytrees.push(r.value)

                    unless mainPolytreeUsed

                        polytrees.unshift(mainPolytree)

                    if polytrees.length > 0

                        if polytrees.length is 1

                            resolve(polytrees[0])

                        else if polytrees.length > 3

                            Polytree.async.intersectArray(polytrees, if usingBatches then 0 else -1).then (result) ->

                                resolve(result)

                            .catch (e) -> reject(e)

                        else

                            Polytree.async.intersect(polytrees[0], polytrees[1]).then (result) ->

                                if polytrees.length is 3

                                    Polytree.async.intersect(result, polytrees[2]).then (result) ->

                                        resolve(result)

                                    .catch (e) -> reject(e)

                                else

                                    resolve(result)

                            .catch (e) -> reject(e)

                    else

                        reject('Unable to find any result polytree')

            catch e

                reject(e)

    operation: (obj, returnPolytrees = false, buildTargetPolytree = true, options = { objCounter: 0 }, firstRun = true) ->

        new Promise (resolve, reject) ->

            try

                polytreeA = undefined
                polytreeB = undefined
                resultPolytree = undefined
                material = undefined

                if obj.material

                    material = obj.material

                promises = []

                if obj.objA

                    promise = handleObjectForOp_async(obj.objA, returnPolytrees, buildTargetPolytree, options, 0)
                    promises.push(promise)

                if obj.objB

                    promise = handleObjectForOp_async(obj.objB, returnPolytrees, buildTargetPolytree, options, 1)
                    promises.push(promise)

                Promise.allSettled(promises).then (results) ->

                    polytrees = []

                    results.forEach (r) ->

                        if r.status is "fulfilled"

                            if r.value.objIndex is 0

                                polytreeA = r.value

                            else if r.value.objIndex is 1

                                polytreeB = r.value

                    if returnPolytrees is true

                        obj.objA = polytreeA.original
                        polytreeA = polytreeA.result
                        obj.objB = polytreeB.original
                        polytreeB = polytreeB.result

                    resultPromise = undefined

                    switch obj.op

                        when 'unite'

                            resultPromise = Polytree.async.unite(polytreeA, polytreeB, buildTargetPolytree)

                        when 'subtract'

                            resultPromise = Polytree.async.subtract(polytreeA, polytreeB, buildTargetPolytree)

                        when 'intersect'

                            resultPromise = Polytree.async.intersect(polytreeA, polytreeB, buildTargetPolytree)

                    resultPromise.then (resultPolytree) ->

                        if firstRun and material

                            mesh = Polytree.toMesh(resultPolytree, material)

                            unless returnPolytrees

                                disposePolytree(resultPolytree)

                            resolve(if returnPolytrees then { result: mesh, operationTree: obj } else mesh)

                        else if firstRun and returnPolytrees

                            resolve({ result: resultPolytree, operationTree: obj })

                        else

                            resolve(resultPolytree)

                        unless returnPolytrees

                            disposePolytree(polytreeA, polytreeB)

                    .catch (e) -> reject(e)

            catch e

                reject(e)