# === ASYNC CSG OPERATIONS FOR POLYTREE ===

# This module provides asynchronous implementations of Constructive Solid Geometry (CSG) operations.
# All operations are Promise-based and include proper resource management and error handling.
# The async operations allow for better performance in web environments by preventing UI blocking.

Polytree.async =

    # Default batch size for processing large arrays of objects.
    # Objects arrays larger than this size will be processed in batches to prevent memory issues.
    batchSize: DEFAULT_BUFFER_SIZE

    # Perform asynchronous union operation between two polytree objects.
    # Creates a new polytree containing the combined volume of both input polytrees.
    #
    # @param polytreeA - First polytree operand for the union operation.
    # @param polytreeB - Second polytree operand for the union operation.
    # @param buildTargetPolytree - Whether to build the target polytree structure (default: true).
    #
    # @return Promise that resolves to the resulting polytree from the union operation.
    unite: (polytreeA, polytreeB, buildTargetPolytree = true) ->

        new Promise (resolve, reject) ->

            # Set up operation timeout only if not infinite.
            timeoutId = null
            if ASYNC_OPERATION_TIMEOUT isnt Infinity
                timeoutId = setTimeout ->
                    reject(new Error("Union operation timed out after #{ASYNC_OPERATION_TIMEOUT}ms"))
                , ASYNC_OPERATION_TIMEOUT

            try

                result = Polytree.uniteCore(polytreeA, polytreeB, buildTargetPolytree)
                disposePolytreeResources(polytreeA, polytreeB)
                if timeoutId then clearTimeout(timeoutId)
                resolve(result)

            catch error

                if timeoutId then clearTimeout(timeoutId)
                disposePolytreeResources(polytreeA, polytreeB)
                reject(error)

    # Perform asynchronous subtraction operation between two polytree objects.
    # Creates a new polytree by removing the volume of polytreeB from polytreeA.
    #
    # @param polytreeA - The polytree to subtract from (minuend).
    # @param polytreeB - The polytree to subtract (subtrahend).
    # @param buildTargetPolytree - Whether to build the target polytree structure (default: true).
    #
    # @return Promise that resolves to the resulting polytree from the subtraction operation.
    subtract: (polytreeA, polytreeB, buildTargetPolytree = true) ->

        new Promise (resolve, reject) ->

            # Set up operation timeout only if not infinite.
            timeoutId = null
            if ASYNC_OPERATION_TIMEOUT isnt Infinity
                timeoutId = setTimeout ->
                    reject(new Error("Subtract operation timed out after #{ASYNC_OPERATION_TIMEOUT}ms"))
                , ASYNC_OPERATION_TIMEOUT

            try

                result = Polytree.subtractCore(polytreeA, polytreeB, buildTargetPolytree)
                disposePolytreeResources(polytreeA, polytreeB)
                if timeoutId then clearTimeout(timeoutId)
                resolve(result)

            catch error

                if timeoutId then clearTimeout(timeoutId)
                disposePolytreeResources(polytreeA, polytreeB)
                reject(error)

    # Perform asynchronous intersection operation between two polytree objects.
    # Creates a new polytree containing only the overlapping volume of both input polytrees.
    #
    # @param polytreeA - First polytree operand for the intersection operation.
    # @param polytreeB - Second polytree operand for the intersection operation.
    # @param buildTargetPolytree - Whether to build the target polytree structure (default: true).
    #
    # @return Promise that resolves to the resulting polytree from the intersection operation.
    intersect: (polytreeA, polytreeB, buildTargetPolytree = true) ->

        new Promise (resolve, reject) ->

            # Set up operation timeout only if not infinite.
            timeoutId = null
            if ASYNC_OPERATION_TIMEOUT isnt Infinity
                timeoutId = setTimeout ->
                    reject(new Error("Intersect operation timed out after #{ASYNC_OPERATION_TIMEOUT}ms"))
                , ASYNC_OPERATION_TIMEOUT

            try

                result = Polytree.intersectCore(polytreeA, polytreeB, buildTargetPolytree)
                disposePolytreeResources(polytreeA, polytreeB)
                if timeoutId then clearTimeout(timeoutId)
                resolve(result)

            catch error

                if timeoutId then clearTimeout(timeoutId)
                disposePolytreeResources(polytreeA, polytreeB)
                reject(error)

    # Perform asynchronous union operation on an array of objects.
    # Efficiently processes large arrays using batching and parallel execution.
    # This method can handle arrays of meshes or polytrees and will convert them as needed.
    #
    # @param objectArray - Array of meshes or polytrees to unite.
    # @param materialIndexMax - Maximum material index for assignment (default: Infinity).
    #
    # @return Promise that resolves to a single polytree containing the union of all objects.
    uniteArray: (objectArray, materialIndexMax = Infinity) ->

        Polytree.async.processArrayWithOperation(
            objectArray,
            materialIndexMax,
            Polytree.async.unite,
            Polytree.async.uniteArray,
            'union'
        )

    # Perform asynchronous subtraction operation on an array of objects.
    # Efficiently processes large arrays using batching and parallel execution.
    # This method subtracts all subsequent objects from the first object in the array.
    #
    # @param objectArray - Array of meshes or polytrees to process with subtraction.
    # @param materialIndexMax - Maximum material index for assignment (default: Infinity).
    #
    # @return Promise that resolves to a single polytree with all subtractions applied.
    subtractArray: (objectArray, materialIndexMax = Infinity) ->

        Polytree.async.processArrayWithOperation(
            objectArray,
            materialIndexMax,
            Polytree.async.subtract,
            Polytree.async.subtractArray,
            'subtraction'
        )

    # Perform asynchronous intersection operation on an array of objects.
    # Efficiently processes large arrays using batching and parallel execution.
    # This method finds the overlapping volume common to all objects in the array.
    #
    # @param objectArray - Array of meshes or polytrees to intersect.
    # @param materialIndexMax - Maximum material index for assignment (default: Infinity).
    #
    # @return Promise that resolves to a single polytree containing the intersection of all objects.
    intersectArray: (objectArray, materialIndexMax = Infinity) ->

        Polytree.async.processArrayWithOperation(
            objectArray,
            materialIndexMax,
            Polytree.async.intersect,
            Polytree.async.intersectArray,
            'intersection'
        )

    # Main operation handler that delegates to the synchronous operation method.
    # This provides a unified interface for complex CSG operations with async support.
    #
    # @param operationObject - Object containing the operation definition.
    # @param returnPolytrees - Whether to return polytree objects instead of meshes.
    # @param buildTargetPolytree - Whether to build the target polytree structure.
    # @param options - Configuration options including objCounter for unique IDs.
    # @param firstRun - Whether this is the top-level operation call.
    #
    # @return Result of the operation (mesh, polytree, or operation tree).
    operation: (operationObject, returnPolytrees = false, buildTargetPolytree = true, options = { objCounter: 0 }, firstRun = true) ->

        Polytree.operation(operationObject, returnPolytrees, buildTargetPolytree, options, firstRun, true)

    # Generic helper method for processing array operations with any CSG operation.
    # This reduces code duplication between uniteArray, subtractArray, and intersectArray.
    #
    # @param objectArray - Array of meshes or polytrees to process.
    # @param materialIndexMax - Maximum material index for assignment.
    # @param operationMethod - The async CSG method to use (unite, subtract, or intersect).
    # @param arrayOperationMethod - The corresponding array method for recursive calls.
    # @param operationName - Name of the operation for error messages.
    #
    # @return Promise that resolves to the final result polytree.
    processArrayWithOperation: (objectArray, materialIndexMax, operationMethod, arrayOperationMethod, operationName) ->

        new Promise (resolve, reject) ->

            try

                # Determine if we should use batching based on array size and batch configuration.
                shouldUseBatching = Polytree.async.batchSize > 4 and Polytree.async.batchSize < objectArray.length
                mainPolytree = undefined
                isMainPolytreeUsed = false
                operationPromises = []

                if shouldUseBatching

                    # Process large arrays in batches to prevent memory issues.
                    batchArray = []
                    currentBatchIndex = 0

                    while currentBatchIndex < objectArray.length

                        batchArray.push objectArray.slice(currentBatchIndex, currentBatchIndex + Polytree.async.batchSize)
                        currentBatchIndex += Polytree.async.batchSize

                    currentBatch = batchArray.shift()

                    while currentBatch

                        batchPromise = arrayOperationMethod(currentBatch, 0)
                        operationPromises.push(batchPromise)
                        currentBatch = batchArray.shift()

                    # Mark that we're using batching and clear the original array.
                    shouldUseBatching = true
                    isMainPolytreeUsed = true
                    objectArray.length = 0

                else

                    # Process smaller arrays directly without batching.
                    polytreesArray = []

                    for objectIndex in [0...objectArray.length]

                        materialIndex = if objectIndex > materialIndexMax then materialIndexMax else objectIndex
                        convertedPolytree = undefined

                        # Convert mesh to polytree if necessary.
                        if objectArray[objectIndex].isMesh

                            convertedPolytree = Polytree.fromMesh(objectArray[objectIndex], if materialIndexMax > -1 then materialIndex else undefined)

                        else

                            convertedPolytree = objectArray[objectIndex]

                            if materialIndexMax > -1

                                convertedPolytree.setPolygonIndex(materialIndex)

                        # Set tracking index for debugging and traceability.
                        convertedPolytree.polytreeIndex = objectIndex
                        polytreesArray.push(convertedPolytree)

                    # Extract the first polytree as the main polytree.
                    mainPolytree = polytreesArray.shift()
                    leftOverPolytree = undefined

                    # Process polytrees in pairs for parallel execution.
                    for pairStartIndex in [0...polytreesArray.length] by 2

                        if pairStartIndex + 1 >= polytreesArray.length

                            # Handle odd number of polytrees - save the leftover.
                            leftOverPolytree = polytreesArray[pairStartIndex]
                            break

                        pairPromise = operationMethod(polytreesArray[pairStartIndex], polytreesArray[pairStartIndex + 1])
                        operationPromises.push(pairPromise)

                    # If there's a leftover polytree, apply operation with the main polytree.
                    if leftOverPolytree

                        leftOverPromise = operationMethod(mainPolytree, leftOverPolytree)
                        operationPromises.push(leftOverPromise)
                        isMainPolytreeUsed = true

                # Wait for all parallel operations to complete and process results.
                Promise.allSettled(operationPromises).then (promiseResults) ->

                    successfulPolytrees = []

                    # Extract successful results from the promise results.
                    promiseResults.forEach (promiseResult) ->

                        if promiseResult.status is "fulfilled"

                            successfulPolytrees.push(promiseResult.value)

                    # Add the main polytree if it wasn't used in operations.
                    unless isMainPolytreeUsed

                        successfulPolytrees.unshift(mainPolytree)

                    # Process the final results based on count.
                    if successfulPolytrees.length > 0

                        if successfulPolytrees.length is 1

                            resolve(successfulPolytrees[0])

                        else if successfulPolytrees.length > 3

                            # Use recursive processing for large result sets.
                            arrayOperationMethod(successfulPolytrees, if shouldUseBatching then 0 else -1).then (finalResult) ->

                                resolve(finalResult)

                            .catch (error) -> reject(error)

                        else

                            # Handle 2-3 results directly for efficiency.
                            operationMethod(successfulPolytrees[0], successfulPolytrees[1]).then (intermediateResult) ->

                                if successfulPolytrees.length is 3

                                    operationMethod(intermediateResult, successfulPolytrees[2]).then (finalResult) ->

                                        resolve(finalResult)

                                    .catch (error) -> reject(error)

                                else

                                    resolve(intermediateResult)

                            .catch (error) -> reject(error)

                    else

                        reject("Unable to find any result polytree after #{operationName} operation.")

            catch error

                reject(error)
