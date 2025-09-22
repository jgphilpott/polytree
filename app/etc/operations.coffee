# Main operation handler for processing CSG operations on Polytree objects.
# This function handles both synchronous and asynchronous CSG operations (unite, subtract, intersect)
# and manages the conversion between meshes and polytrees as needed.
#
# @param operationObject - Object containing the operation definition with properties:
#   - op: Operation type ('unite', 'subtract', 'intersect')
#   - objA: First operand (mesh, polytree, or nested operation)
#   - objB: Second operand (mesh, polytree, or nested operation)
#   - material: Optional material for final mesh output
# @param returnPolytrees - Whether to return polytree objects instead of meshes.
# @param buildTargetPolytree - Whether to build the target polytree structure.
# @param options - Configuration options including objCounter for unique IDs.
# @param firstRun - Whether this is the top-level operation call.
# @param async - Whether to execute asynchronously using promises.
# @return Result mesh, polytree, or operation tree depending on parameters.
operationHandler = (operationObject, returnPolytrees = false, buildTargetPolytree = true, options = { objCounter: 0 }, firstRun = true, async = true) ->

    if async

        new Promise (resolve, reject) ->

            try

                # Initialize variables for the two operands and result.
                firstOperand = undefined
                secondOperand = undefined
                resultPolytree = undefined
                materialForMesh = undefined

                # Capture original material for default use before processing operands.
                originalMaterialA = operationObject.objA?.material
                originalMaterialB = operationObject.objB?.material

                if operationObject.material

                    materialForMesh = operationObject.material

                # Process operands in parallel for async operations.
                operandPromises = []

                if operationObject.objA

                    operandPromise = handleObjectForOperation(operationObject.objA, returnPolytrees, buildTargetPolytree, options, 0, async)
                    operandPromises.push(operandPromise)

                if operationObject.objB

                    operandPromise = handleObjectForOperation(operationObject.objB, returnPolytrees, buildTargetPolytree, options, 1, async)
                    operandPromises.push(operandPromise)

                Promise.allSettled(operandPromises).then (promiseResults) ->

                    # Extract operands from promise results.
                    promiseResults.forEach (promiseResult) ->

                        if promiseResult.status is "fulfilled"

                            if promiseResult.value.objIndex is 0

                                firstOperand = promiseResult.value

                            else if promiseResult.value.objIndex is 1

                                secondOperand = promiseResult.value

                    # Handle polytree return mode by updating operation object references.
                    if returnPolytrees is true

                        # Extract polytrees from wrapper objects when in polytree return mode.
                        if firstOperand

                            operationObject.objA = firstOperand.original
                            firstOperand = firstOperand.result

                        if secondOperand

                            operationObject.objB = secondOperand.original
                            secondOperand = secondOperand.result

                    # Execute the appropriate CSG operation based on operation type.
                    operationPromise = undefined

                    switch operationObject.op

                        when 'unite'

                            if firstOperand and secondOperand

                                operationPromise = Polytree.async.unite(firstOperand, secondOperand, buildTargetPolytree)

                            else

                                # Handle missing operands gracefully.
                                operationPromise = Promise.resolve(firstOperand or secondOperand or new Polytree())

                        when 'subtract'

                            if firstOperand and secondOperand

                                operationPromise = Polytree.async.subtract(firstOperand, secondOperand, buildTargetPolytree)

                            else

                                # For subtract, return first operand or empty polytree.
                                operationPromise = Promise.resolve(firstOperand or new Polytree())

                        when 'intersect'

                            if firstOperand and secondOperand

                                operationPromise = Polytree.async.intersect(firstOperand, secondOperand, buildTargetPolytree)

                            else

                                # For intersect, missing operand means no result.
                                operationPromise = Promise.resolve(new Polytree())

                        else

                            # Handle invalid operation types gracefully.
                            operationPromise = Promise.resolve(new Polytree())

                    # Handle the operation result and determine final output format.
                    operationPromise.then (resultPolytree) ->

                        # Ensure result polytree has proper bounding box for subsequent operations.
                        if resultPolytree and not resultPolytree.box and resultPolytree.bounds

                            resultPolytree.buildTree()

                        # Convert to mesh for first run operations unless returning polytrees.
                        if firstRun and not returnPolytrees

                            # Skip mesh conversion if result polytree has no valid polygons.
                            allPolygons = resultPolytree.getPolygons()

                            if not resultPolytree or allPolygons.length is 0

                                resolve(undefined)
                                return

                            if materialForMesh

                                finalMesh = Polytree.toMesh(resultPolytree, materialForMesh)

                            else

                                # Use default material from original operands if no material specified.
                                defaultMaterial = undefined

                                if originalMaterialA

                                    defaultMaterial = if Array.isArray(originalMaterialA) then originalMaterialA[0] else originalMaterialA
                                    defaultMaterial = defaultMaterial.clone()

                                else if originalMaterialB

                                    defaultMaterial = if Array.isArray(originalMaterialB) then originalMaterialB[0] else originalMaterialB
                                    defaultMaterial = defaultMaterial.clone()

                                else

                                    # No material available - resolve with undefined.
                                    resolve(undefined)
                                    return

                                finalMesh = Polytree.toMesh(resultPolytree, defaultMaterial)

                            disposePolytreeResources(resultPolytree)
                            resolve(finalMesh)

                        else if firstRun and returnPolytrees

                            if materialForMesh

                                finalMesh = Polytree.toMesh(resultPolytree, materialForMesh)
                                disposePolytreeResources(resultPolytree)
                                resolve({ result: finalMesh, operationTree: operationObject })

                            else

                                resolve({ result: resultPolytree, operationTree: operationObject })

                        else

                            resolve(resultPolytree)

                        # Clean up intermediate polytrees unless returning them.
                        unless returnPolytrees

                            if firstOperand or secondOperand

                                disposePolytreeResources(firstOperand, secondOperand)

                    .catch (operationError) -> reject(operationError)

            catch asyncError

                reject(asyncError)

    else

        # Synchronous operation handling.
        firstOperand = undefined
        secondOperand = undefined
        resultPolytree = undefined
        materialForMesh = undefined

        if operationObject.material

            materialForMesh = operationObject.material

        # Process first operand.
        if operationObject.objA

            firstOperand = handleObjectForOperation(operationObject.objA, returnPolytrees, buildTargetPolytree, options, undefined, async)

            if returnPolytrees == true

                operationObject.objA = firstOperand.original
                firstOperand = firstOperand.result

        # Process second operand.
        if operationObject.objB

            secondOperand = handleObjectForOperation(operationObject.objB, returnPolytrees, buildTargetPolytree, options, undefined, async)

            if returnPolytrees == true

                operationObject.objB = secondOperand.original
                secondOperand = secondOperand.result

        # Execute the appropriate CSG operation.
        switch operationObject.op

            when 'unite'

                if firstOperand and secondOperand

                    resultPolytree = Polytree.unite(firstOperand, secondOperand, buildTargetPolytree)

                else

                    # Handle missing operands - return the available operand or empty polytree.
                    resultPolytree = firstOperand or secondOperand or new Polytree()

            when 'subtract'

                if firstOperand and secondOperand

                    resultPolytree = Polytree.subtract(firstOperand, secondOperand, buildTargetPolytree)

                else

                    # For subtract, if missing second operand, return first; if missing first, return empty.
                    resultPolytree = firstOperand or new Polytree()

            when 'intersect'

                if firstOperand and secondOperand

                    resultPolytree = Polytree.intersect(firstOperand, secondOperand, buildTargetPolytree)

                else

                    # For intersect, missing either operand means no intersection - return empty polytree.
                    resultPolytree = new Polytree()

            else

                # Handle invalid operation types gracefully - return empty polytree.
                resultPolytree = new Polytree()

        # Ensure result polytree has proper bounding box for subsequent operations.
        if resultPolytree and not resultPolytree.box and resultPolytree.bounds

            resultPolytree.buildTree()

        # Clean up intermediate polytrees unless returning them.
        unless returnPolytrees

            if firstOperand or secondOperand

                disposePolytreeResources(firstOperand, secondOperand)

        # Handle final output format for synchronous operations.
        if firstRun and not returnPolytrees

            # Skip mesh conversion if result polytree has no valid polygons.
            allPolygons = resultPolytree.getPolygons()

            if not resultPolytree or allPolygons.length is 0

                return undefined

            # Convert polytree result to mesh for top-level operations.
            if materialForMesh

                finalMesh = Polytree.toMesh(resultPolytree, materialForMesh)

            else

                # Use default material from first operand if no material specified.
                defaultMaterial = undefined

                if operationObject.objA?.material

                    defaultMaterial = if Array.isArray(operationObject.objA.material) then operationObject.objA.material[0] else operationObject.objA.material
                    defaultMaterial = defaultMaterial.clone()

                else

                    # No material available - return undefined instead of creating empty mesh.
                    return undefined

                finalMesh = Polytree.toMesh(resultPolytree, defaultMaterial)

            disposePolytreeResources(resultPolytree)

            return finalMesh

        if firstRun and returnPolytrees

            return { result: resultPolytree, operationTree: operationObject }

        return resultPolytree

# Handle individual object processing for CSG operations.
# Converts meshes to polytrees and handles nested operations recursively.
#
# @param inputObject - Object to process (mesh, polytree, or nested operation).
# @param returnPolytrees - Whether to return polytree objects instead of meshes.
# @param buildTargetPolytree - Whether to build the target polytree structure.
# @param options - Configuration options including objCounter for unique IDs.
# @param objectIndex - Index identifier for tracking operand position (0 or 1).
# @param async - Whether to execute asynchronously using promises.
# @return Processed polytree object or promise resolving to one.
handleObjectForOperation = (inputObject, returnPolytrees, buildTargetPolytree, options, objectIndex, async = true) ->

    if async

        new Promise (resolve, reject) ->

            try

                processedObject = undefined

                # Convert Three.js mesh to polytree.
                if inputObject.isMesh

                    processedObject = Polytree.fromMesh(inputObject, options.objCounter++)

                    if returnPolytrees

                        processedObject = { result: processedObject, original: processedObject.clone() }

                    processedObject.objIndex = objectIndex
                    resolve(processedObject)

                # Handle existing polytree objects.
                else if inputObject.isPolytree

                    processedObject = inputObject

                    if returnPolytrees

                        processedObject = { result: inputObject, original: inputObject.clone() }

                    processedObject.objIndex = objectIndex
                    resolve(processedObject)

                # Handle nested operations recursively.
                else if inputObject.op

                    Polytree.operation(inputObject, returnPolytrees, buildTargetPolytree, options, false, async).then (nestedResult) ->

                        if returnPolytrees

                            nestedResult = { result: nestedResult, original: inputObject }

                        nestedResult.objIndex = objectIndex
                        resolve(nestedResult)

            catch processingError

                reject(processingError)

    else

        # Synchronous object processing.
        processedObject = undefined

        # Convert Three.js mesh to polytree.
        if inputObject.isMesh

            processedObject = Polytree.fromMesh(inputObject, options.objCounter++)

            if returnPolytrees

                processedObject = { result: processedObject, original: processedObject.clone() }

        # Handle existing polytree objects.
        else if inputObject.isPolytree

            processedObject = inputObject

            if returnPolytrees

                processedObject = { result: inputObject, original: inputObject.clone() }

        # Handle nested operations recursively.
        else if inputObject.op

            processedObject = Polytree.operation(inputObject, returnPolytrees, buildTargetPolytree, options, false, async)

            if returnPolytrees

                processedObject = { result: processedObject, original: inputObject }

        return processedObject
