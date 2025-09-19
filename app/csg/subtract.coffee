# Subtraction CSG operation for Polytree
# Keep polygons from A that are outside B or coplanar-front with B
# Keep polygons from B that are inside A and coplanar-front with A

subtractRules =

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

Polytree.subtract = (mesh1, mesh2, targetMaterial = null) ->

    # Handle both mesh and polytree inputs for backward compatibility
    if mesh1.isPolytree and mesh2.isPolytree

        # Original polytree-to-polytree operation
        polytreeA = mesh1
        polytreeB = mesh2

        buildTargetPolytree = if targetMaterial is null then true else false

        return this.subtractCore(polytreeA, polytreeB, buildTargetPolytree)

    else

        # New mesh-to-mesh operation (default behavior)
        polytreeA = undefined
        polytreeB = undefined

        if targetMaterial and Array.isArray(targetMaterial)

            polytreeA = Polytree.fromMesh(mesh1, 0)
            polytreeB = Polytree.fromMesh(mesh2, 1)

        else

            polytreeA = Polytree.fromMesh(mesh1)
            polytreeB = Polytree.fromMesh(mesh2)
            targetMaterial = if targetMaterial isnt null then targetMaterial else (if Array.isArray(mesh1.material) then mesh1.material[0] else mesh1.material).clone()

        resultPolytree = this.subtractCore(polytreeA, polytreeB, false)
        resultMesh = Polytree.toMesh(resultPolytree, targetMaterial)

        disposePolytree(polytreeA, polytreeB, resultPolytree)

        return resultMesh

Polytree.subtractCore = (polytreeA, polytreeB, buildTargetPolytree = true) ->

    polytree = new Polytree()
    trianglesSet = new Set()

    if polytreeA.box.intersectsBox(polytreeB.box)

        currentMeshSideA = undefined
        currentMeshSideB = undefined

        if polytreeA.mesh

            currentMeshSideA = polytreeA.mesh.material.side
            polytreeA.mesh.material.side = DoubleSide

        if polytreeB.mesh

            currentMeshSideB = polytreeB.mesh.material.side
            polytreeB.mesh.material.side = DoubleSide

        polytreeA.resetPolygons(false)
        polytreeB.resetPolygons(false)

        polytreeA.markIntesectingPolygons(polytreeB)
        polytreeB.markIntesectingPolygons(polytreeA)

        handleIntersectingPolytrees(polytreeA, polytreeB)

        polytreeA.deleteReplacedPolygons()
        polytreeB.deleteReplacedPolygons()

        polytreeA.deletePolygonsByStateRules(subtractRules.a)
        polytreeB.deletePolygonsByStateRules(subtractRules.b)

        polytreeB.deletePolygonsByIntersection(false)
        polytreeB.invert()

        polytreeA.getPolygonCloneCallback(polytree.addPolygon.bind(polytree), trianglesSet)
        polytreeB.getPolygonCloneCallback(polytree.addPolygon.bind(polytree), trianglesSet)

        if polytreeA.mesh and polytreeA.mesh.material.side isnt currentMeshSideA

            polytreeA.mesh.material.side = currentMeshSideA

        if polytreeB.mesh and polytreeB.mesh.material.side isnt currentMeshSideB

            polytreeB.mesh.material.side = currentMeshSideB

    else

        polytreeA.getPolygonCloneCallback(polytree.addPolygon.bind(polytree), trianglesSet)

    trianglesSet.clear()
    trianglesSet = undefined

    polytree.markPolygonsAsOriginal()
    buildTargetPolytree and polytree.buildTree()

    return polytree
