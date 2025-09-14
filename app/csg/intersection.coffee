# Intersection CSG operation for Polytree
# Delete all polygons in A that are:
#     a. inside and coplanar-back
#     b. outside and coplanar-front
#     c. outside and coplanar-back
#     d. outside
# Delete all polygons in B that are:
#     a. inside and coplanar-front
#     b. inside and coplanar-back
#     c. outside and coplanar-front
#     d. outside and coplanar-back
#     e. outside

intersectRules =

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

intersect = (polytreeA, polytreeB, buildTargetPolytree = true) ->

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

        polytreeA.deletePolygonsByStateRules(intersectRules.a)
        polytreeB.deletePolygonsByStateRules(intersectRules.b)

        polytreeA.deletePolygonsByIntersection(false)
        polytreeB.deletePolygonsByIntersection(false)

        polytreeA.getPolygonCloneCallback(polytree.addPolygon.bind(polytree), trianglesSet)
        polytreeB.getPolygonCloneCallback(polytree.addPolygon.bind(polytree), trianglesSet)

        if polytreeA.mesh and polytreeA.mesh.material.side isnt currentMeshSideA

            polytreeA.mesh.material.side = currentMeshSideA

        if polytreeB.mesh and polytreeB.mesh.material.side isnt currentMeshSideB

            polytreeB.mesh.material.side = currentMeshSideB

    trianglesSet.clear()
    trianglesSet = undefined

    polytree.markPolygonsAsOriginal()
    buildTargetPolytree and polytree.buildTree()
    polytree
