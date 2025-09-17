# Main operation handler
_handleOperation = (obj, returnPolytrees, buildTargetPolytree, options, firstRun, async) ->

    if async

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

                    promise = handleObjectForOp(obj.objA, returnPolytrees, buildTargetPolytree, options, 0, async)
                    promises.push(promise)

                if obj.objB

                    promise = handleObjectForOp(obj.objB, returnPolytrees, buildTargetPolytree, options, 1, async)
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

    else

        polytreeA = undefined
        polytreeB = undefined
        resultPolytree = undefined
        material = undefined

        if obj.material

            material = obj.material

        if obj.objA

            polytreeA = handleObjectForOp(obj.objA, returnPolytrees, buildTargetPolytree, options, undefined, async)

            if returnPolytrees == true

                obj.objA = polytreeA.original
                polytreeA = polytreeA.result

        if obj.objB

            polytreeB = handleObjectForOp(obj.objB, returnPolytrees, buildTargetPolytree, options, undefined, async)

            if returnPolytrees == true

                obj.objB = polytreeB.original
                polytreeB = polytreeB.result

        switch obj.op

            when 'unite'

                resultPolytree = Polytree.unite(polytreeA, polytreeB, buildTargetPolytree)

            when 'subtract'

                resultPolytree = Polytree.subtract(polytreeA, polytreeB, buildTargetPolytree)

            when 'intersect'

                resultPolytree = Polytree.intersect(polytreeA, polytreeB, buildTargetPolytree)

        unless returnPolytrees

            disposePolytree(polytreeA, polytreeB)

        if firstRun and material

            mesh = Polytree.toMesh(resultPolytree, material)
            disposePolytree(resultPolytree)

            return if returnPolytrees then { result: mesh, operationTree: obj } else mesh

        if firstRun and returnPolytrees

            return { result: resultPolytree, operationTree: obj }

        return resultPolytree

# Handle object for operation
handleObjectForOp = (obj, returnPolytrees, buildTargetPolytree, options, objIndex, async = true) ->

    if async

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

                    Polytree.operation(obj, returnPolytrees, buildTargetPolytree, options, false, async).then (returnObj) ->

                        if returnPolytrees

                            returnObj = { result: returnObj, original: obj }

                        returnObj.objIndex = objIndex
                        resolve(returnObj)

            catch e

                reject(e)

    else

        returnObj = undefined

        if obj.isMesh

            returnObj = Polytree.fromMesh(obj, options.objCounter++)

            if returnPolytrees

                returnObj = { result: returnObj, original: returnObj.clone() }

        else if obj.isPolytree

            returnObj = obj

            if returnPolytrees

                returnObj = { result: obj, original: obj.clone() }

        else if obj.op

            returnObj = Polytree.operation(obj, returnPolytrees, buildTargetPolytree, options, false, async)

            if returnPolytrees

                returnObj = { result: returnObj, original: obj }

        return returnObj
