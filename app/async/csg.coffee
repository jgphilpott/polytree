# Async CSG operations for Polytree.
# This module provides asynchronous versions of core CSG operations (unite, subtract, intersect)
# and array processing functions for handling multiple objects efficiently.

# === ARRAY OPERATION HELPERS ===

# Convert an array of meshes/polytrees to an array of polytrees with proper indexing.
# @param objectArray - Array of meshes or polytrees to convert.
# @param materialIndexMax - Maximum material index to apply (Infinity for no limit).
# @return Array of polytrees with polytreeIndex and material settings applied.
convertObjectArrayToPolytrees = (objectArray, materialIndexMax) ->

    polytreesArray = []

    for index in [0...objectArray.length]

        materialIndex = if index > materialIndexMax then materialIndexMax else index
        temporaryPolytree = undefined

        if objectArray[index].isMesh

            temporaryPolytree = Polytree.fromMesh(objectArray[index], if materialIndexMax > -1 then materialIndex else undefined)

        else

            temporaryPolytree = objectArray[index]

            if materialIndexMax > -1

                temporaryPolytree.setPolygonIndex(materialIndex)

        temporaryPolytree.polytreeIndex = index
        polytreesArray.push(temporaryPolytree)

    return polytreesArray

# Create batches from an object array for parallel processing.
# @param objectArray - Array to batch.
# @param batchSize - Size of each batch.
# @return Array of batches.
createBatchesFromArray = (objectArray, batchSize) ->

    batches = []
    currentIndex = 0

    while currentIndex < objectArray.length

        batches.push objectArray.slice(currentIndex, currentIndex + batchSize)
        currentIndex += batchSize

    return batches

# Process pairs of polytrees using the specified async operation.
# @param polytreesArray - Array of polytrees to process in pairs.
# @param operationFunction - Async function to apply to pairs (e.g., Polytree.async.unite).
# @return Object containing promises array and leftover polytree if any.
createPairwiseOperationPromises = (polytreesArray, operationFunction) ->

    promises = []
    leftoverPolytree = undefined
    hasLeftover = false

    for index in [0...polytreesArray.length] by 2

        if index + 1 >= polytreesArray.length

            leftoverPolytree = polytreesArray[index]
            hasLeftover = true
            break

        promise = operationFunction(polytreesArray[index], polytreesArray[index + 1])
        promises.push(promise)

    return { promises, leftoverPolytree, hasLeftover }

# Process the results of pairwise operations and handle recursive cases.
# @param promises - Array of operation promises.
# @param mainPolytree - Main polytree to use if needed.
# @param mainPolytreeUsed - Whether the main polytree was already used.
# @param leftoverPolytree - Leftover polytree from pairwise processing.
# @param operationFunction - Operation function for recursive calls.
# @param arrayOperationFunction - Array operation function for recursive calls.
# @param usingBatches - Whether batch processing is being used.
# @param resolve - Promise resolve function.
# @param reject - Promise reject function.
processOperationResults = (promises, mainPolytree, mainPolytreeUsed, leftoverPolytree, operationFunction, arrayOperationFunction, usingBatches, resolve, reject) ->

    Promise.allSettled(promises).then (results) ->

        polytrees = []

        results.forEach (result) ->

            if result.status is "fulfilled"

                polytrees.push(result.value)

        unless mainPolytreeUsed

            polytrees.unshift(mainPolytree)

        if polytrees.length > 0

            if polytrees.length is 1

                resolve(polytrees[0])

            else if polytrees.length > 3

                arrayOperationFunction(polytrees, if usingBatches then 0 else -1).then (result) ->

                    resolve(result)

                .catch (error) -> reject(error)

            else

                operationFunction(polytrees[0], polytrees[1]).then (result) ->

                    if polytrees.length is 3

                        operationFunction(result, polytrees[2]).then (finalResult) ->

                            resolve(finalResult)

                        .catch (error) -> reject(error)

                    else

                        resolve(result)

                .catch (error) -> reject(error)

        else

            reject('Unable to find any result polytree')

# === ASYNC CSG CORE OPERATIONS ===

Polytree.async =

    batchSize: 100

    # Basic async wrapper for unite operation.
    # @param polytreeA - First polytree operand.
    # @param polytreeB - Second polytree operand.
    # @param buildTargetPolytree - Whether to build the target polytree structure.
    # @return Promise resolving to the union result.
    unite: (polytreeA, polytreeB, buildTargetPolytree = true) ->

        new Promise (resolve, reject) ->

            try

                result = Polytree.uniteCore(polytreeA, polytreeB, buildTargetPolytree)
                resolve(result)
                disposePolytreeResources(polytreeA, polytreeB)

            catch e

                reject(e)

    # Basic async wrapper for subtract operation.
    # @param polytreeA - First polytree operand (object to subtract from).
    # @param polytreeB - Second polytree operand (object to subtract).
    # @param buildTargetPolytree - Whether to build the target polytree structure.
    # @return Promise resolving to the subtraction result.
    subtract: (polytreeA, polytreeB, buildTargetPolytree = true) ->

        new Promise (resolve, reject) ->

            try

                result = Polytree.subtractCore(polytreeA, polytreeB, buildTargetPolytree)
                resolve(result)
                disposePolytreeResources(polytreeA, polytreeB)

            catch e

                reject(e)

    # Basic async wrapper for intersect operation.
    # @param polytreeA - First polytree operand.
    # @param polytreeB - Second polytree operand.
    # @param buildTargetPolytree - Whether to build the target polytree structure.
    # @return Promise resolving to the intersection result.
    intersect: (polytreeA, polytreeB, buildTargetPolytree = true) ->

        new Promise (resolve, reject) ->

            try

                result = Polytree.intersectCore(polytreeA, polytreeB, buildTargetPolytree)
                resolve(result)
                disposePolytreeResources(polytreeA, polytreeB)

            catch e

                reject(e)

    # Async unite operation for arrays of objects.
    # Efficiently processes multiple objects using batching and pairwise operations.
    # @param objectArray - Array of meshes or polytrees to unite.
    # @param materialIndexMax - Maximum material index to apply (Infinity for no limit).
    # @return Promise resolving to the united result.
    uniteArray: (objectArray, materialIndexMax = Infinity) ->

        new Promise (resolve, reject) ->

            try

                usingBatches = Polytree.async.batchSize > 4 and Polytree.async.batchSize < objectArray.length
                mainPolytree = undefined
                mainPolytreeUsed = false
                promises = []

                if usingBatches

                    batches = createBatchesFromArray(objectArray, Polytree.async.batchSize)

                    batch = batches.shift()

                    while batch

                        promise = Polytree.async.uniteArray(batch, 0)
                        promises.push(promise)
                        batch = batches.shift()

                    usingBatches = true
                    mainPolytreeUsed = true
                    objectArray.length = 0

                else

                    polytreesArray = convertObjectArrayToPolytrees(objectArray, materialIndexMax)
                    mainPolytree = polytreesArray.shift()

                    pairwiseResult = createPairwiseOperationPromises(polytreesArray, Polytree.async.unite)
                    promises = pairwiseResult.promises

                    if pairwiseResult.leftoverPolytree

                        promise = Polytree.async.unite(mainPolytree, pairwiseResult.leftoverPolytree)
                        promises.push(promise)
                        mainPolytreeUsed = true

                processOperationResults(promises, mainPolytree, mainPolytreeUsed, undefined, Polytree.async.unite, Polytree.async.uniteArray, usingBatches, resolve, reject)

            catch e

                reject(e)

    # Async subtract operation for arrays of objects.
    # Efficiently processes multiple objects using batching and pairwise operations.
    # @param objectArray - Array of meshes or polytrees to subtract.
    # @param materialIndexMax - Maximum material index to apply (Infinity for no limit).
    # @return Promise resolving to the subtraction result.
    subtractArray: (objectArray, materialIndexMax = Infinity) ->

        new Promise (resolve, reject) ->

            try

                usingBatches = Polytree.async.batchSize > 4 and Polytree.async.batchSize < objectArray.length
                mainPolytree = undefined
                mainPolytreeUsed = false
                promises = []

                if usingBatches

                    batches = createBatchesFromArray(objectArray, Polytree.async.batchSize)

                    batch = batches.shift()

                    while batch

                        promise = Polytree.async.subtractArray(batch, 0)
                        promises.push(promise)
                        batch = batches.shift()

                    usingBatches = true
                    mainPolytreeUsed = true
                    objectArray.length = 0

                else

                    polytreesArray = convertObjectArrayToPolytrees(objectArray, materialIndexMax)
                    mainPolytree = polytreesArray.shift()

                    pairwiseResult = createPairwiseOperationPromises(polytreesArray, Polytree.async.subtract)
                    promises = pairwiseResult.promises

                    if pairwiseResult.leftoverPolytree

                        promise = Polytree.async.subtract(mainPolytree, pairwiseResult.leftoverPolytree)
                        promises.push(promise)
                        mainPolytreeUsed = true

                processOperationResults(promises, mainPolytree, mainPolytreeUsed, undefined, Polytree.async.subtract, Polytree.async.subtractArray, usingBatches, resolve, reject)

            catch e

                reject(e)

    # Async intersect operation for arrays of objects.
    # Efficiently processes multiple objects using batching and pairwise operations.
    # @param objectArray - Array of meshes or polytrees to intersect.
    # @param materialIndexMax - Maximum material index to apply (Infinity for no limit).
    # @return Promise resolving to the intersection result.
    intersectArray: (objectArray, materialIndexMax = Infinity) ->

        new Promise (resolve, reject) ->

            try

                usingBatches = Polytree.async.batchSize > 4 and Polytree.async.batchSize < objectArray.length
                mainPolytree = undefined
                mainPolytreeUsed = false
                promises = []

                if usingBatches

                    batches = createBatchesFromArray(objectArray, Polytree.async.batchSize)

                    batch = batches.shift()

                    while batch

                        promise = Polytree.async.intersectArray(batch, 0)
                        promises.push(promise)
                        batch = batches.shift()

                    usingBatches = true
                    mainPolytreeUsed = true
                    objectArray.length = 0

                else

                    polytreesArray = convertObjectArrayToPolytrees(objectArray, materialIndexMax)
                    mainPolytree = polytreesArray.shift()

                    pairwiseResult = createPairwiseOperationPromises(polytreesArray, Polytree.async.intersect)
                    promises = pairwiseResult.promises

                    if pairwiseResult.leftoverPolytree

                        promise = Polytree.async.intersect(mainPolytree, pairwiseResult.leftoverPolytree)
                        promises.push(promise)
                        mainPolytreeUsed = true

                processOperationResults(promises, mainPolytree, mainPolytreeUsed, undefined, Polytree.async.intersect, Polytree.async.intersectArray, usingBatches, resolve, reject)

            catch e

                reject(e)

    # Async operation wrapper for complex operation trees.
    # @param operationObject - Object containing operation definition.
    # @param returnPolytrees - Whether to return polytree objects instead of meshes.
    # @param buildTargetPolytree - Whether to build the target polytree structure.
    # @param options - Configuration options including objCounter for unique IDs.
    # @param firstRun - Whether this is the top-level operation call.
    # @return Promise resolving to the operation result.
    operation: (operationObject, returnPolytrees = false, buildTargetPolytree = true, options = { objCounter: 0 }, firstRun = true) ->

        Polytree.operation(operationObject, returnPolytrees, buildTargetPolytree, options, firstRun, true)