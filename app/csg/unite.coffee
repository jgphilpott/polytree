# ============================================================================
# Unite CSG Operation for Polytree
# ============================================================================
#
# This module implements the union (unite) boolean operation for Constructive
# Solid Geometry (CSG). The unite operation combines two 3D objects by merging
# all their surfaces while removing internal/overlapping geometry.
#
# Algorithm Overview:
# The unite operation preserves polygons from both objects that contribute to
# the external surface of the combined result. It removes:
# - Polygons from A that are inside B or coplanar-back with B
# - Polygons from B that are inside A or coplanar-back/front with A
#
# The operation supports both mesh-to-mesh and polytree-to-polytree inputs
# for backward compatibility and provides optimized processing paths.

# === POLYGON CLASSIFICATION RULES FOR UNITE OPERATION ===

# Define which polygons to remove during unite operation.
# Rules specify polygon states that should be deleted from each object.
uniteRules =

    # Rules for object A: Remove polygons that are inside B or coplanar-back with B.
    a: [
        { array: true, rule: ["inside", "coplanar-back"] }
        { array: false, rule: "inside" }
    ]

    # Rules for object B: Remove polygons inside A or coplanar with A.
    b: [
        { array: true, rule: ["inside", "coplanar-back"] }
        { array: true, rule: ["inside", "coplanar-front"] }
        { array: false, rule: "inside" }
    ]

# === PUBLIC CSG OPERATIONS ===

# Perform unite (union) operation between two 3D objects.
# This is the main entry point that handles both mesh and polytree inputs.
# @param mesh1 - First 3D object (Three.js Mesh or Polytree instance).
# @param mesh2 - Second 3D object (Three.js Mesh or Polytree instance).
# @param targetMaterial - Optional material for result mesh. If null and polytree input, returns polytree.
# @return Three.js Mesh with united geometry or Polytree instance.
Polytree.unite = (mesh1, mesh2, targetMaterial = null) ->

    # Handle both mesh and polytree inputs for backward compatibility.
    if mesh1.isPolytree and mesh2.isPolytree

        # Direct polytree-to-polytree operation - most efficient path.
        polytreeA = mesh1
        polytreeB = mesh2
        buildTargetPolytree = if targetMaterial is null then true else false

        return this.uniteCore(polytreeA, polytreeB, buildTargetPolytree)

    else

        # Mesh-to-mesh operation (default behavior) - converts to polytrees internally.
        polytreeA = undefined
        polytreeB = undefined

        # Handle material array input for multi-material support.
        if targetMaterial and Array.isArray(targetMaterial)

            polytreeA = Polytree.fromMesh(mesh1, 0)
            polytreeB = Polytree.fromMesh(mesh2, 1)

        else

            polytreeA = Polytree.fromMesh(mesh1)
            polytreeB = Polytree.fromMesh(mesh2)

            # Use specified material or default to first material from mesh1.
            if targetMaterial isnt null

                targetMaterial = targetMaterial

            else

                targetMaterial = if Array.isArray(mesh1.material) then mesh1.material[0] else mesh1.material
                targetMaterial = targetMaterial.clone()

        # Perform unite operation and convert result back to mesh.
        resultPolytree = this.uniteCore(polytreeA, polytreeB, false)
        resultMesh = Polytree.toMesh(resultPolytree, targetMaterial)

        disposePolytree(polytreeA, polytreeB, resultPolytree)

        return resultMesh

# === CORE CSG IMPLEMENTATION ===

# Core unite operation implementation working with polytree objects.
# This method performs the actual CSG boolean logic for union operations.
# @param polytreeA - First polytree object to unite.
# @param polytreeB - Second polytree object to unite.
# @param buildTargetPolytree - Whether to build spatial tree structure in result.
# @return Polytree containing the united geometry.
Polytree.uniteCore = (polytreeA, polytreeB, buildTargetPolytree = true) ->

    # Initialize result polytree and triangle tracking set.
    polytree = new Polytree()
    trianglesSet = new Set()

    # Only process intersection if bounding boxes overlap.
    if polytreeA.box.intersectsBox(polytreeB.box)

        # Store original material sides for restoration later.
        currentMeshSideA = undefined
        currentMeshSideB = undefined

        # Temporarily set materials to DoubleSide for accurate intersection detection.
        if polytreeA.mesh

            currentMeshSideA = polytreeA.mesh.material.side
            polytreeA.mesh.material.side = DoubleSide

        if polytreeB.mesh

            currentMeshSideB = polytreeB.mesh.material.side
            polytreeB.mesh.material.side = DoubleSide

        # === CSG PROCESSING PIPELINE ===

        # Step 1: Reset polygon states for fresh classification.
        polytreeA.resetPolygons(false)
        polytreeB.resetPolygons(false)

        # Step 2: Mark polygons that intersect between the two objects.
        # Note: Method name has typo but is consistently used throughout codebase.
        polytreeA.markIntesectingPolygons(polytreeB)
        polytreeB.markIntesectingPolygons(polytreeA)

        # Step 3: Handle intersecting polygons by splitting and classifying them.
        handleIntersectingPolytrees(polytreeA, polytreeB)

        # Step 4: Clean up replaced polygons from splitting operations.
        polytreeA.deleteReplacedPolygons()
        polytreeB.deleteReplacedPolygons()

        # Step 5: Apply unite-specific rules to remove unwanted polygons.
        polytreeA.deletePolygonsByStateRules(uniteRules.a)
        polytreeB.deletePolygonsByStateRules(uniteRules.b)

        # Step 6: Copy remaining polygons to result polytree.
        polytreeA.getPolygonCloneCallback(polytree.addPolygon.bind(polytree), trianglesSet)
        polytreeB.getPolygonCloneCallback(polytree.addPolygon.bind(polytree), trianglesSet)

        # Restore original material sides.
        if polytreeA.mesh and polytreeA.mesh.material.side isnt currentMeshSideA

            polytreeA.mesh.material.side = currentMeshSideA

        if polytreeB.mesh and polytreeB.mesh.material.side isnt currentMeshSideB

            polytreeB.mesh.material.side = currentMeshSideB

    else

        # No intersection detected - simply combine all polygons from both objects.
        polytreeA.getPolygonCloneCallback(polytree.addPolygon.bind(polytree), trianglesSet)
        polytreeB.getPolygonCloneCallback(polytree.addPolygon.bind(polytree), trianglesSet)

    # === FINALIZATION ===

    # Clean up temporary triangle tracking.
    trianglesSet.clear()
    trianglesSet = undefined

    # Mark polygons as original (not generated by CSG operations).
    polytree.markPolygonsAsOriginal()

    # Build spatial tree structure if requested for optimization.
    buildTargetPolytree and polytree.buildTree()

    return polytree
