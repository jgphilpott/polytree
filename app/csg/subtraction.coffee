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

subtract = (polytreeA, polytreeB, buildTargetPolytree = true) ->

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
    polytree
