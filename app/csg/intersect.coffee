# ============================================================================
# Intersect CSG Operation for Polytree
# ============================================================================
#
# This module implements the intersection boolean operation for Constructive
# Solid Geometry (CSG). The intersect operation keeps only the overlapping
# volume that is common to both input objects.
#
# Algorithm Overview:
# The intersect operation preserves only polygons that contribute to the
# volume where both objects overlap. It removes extensive sets of polygons:
# - From A: inside+coplanar-back, outside+coplanar-front/back, and outside
# - From B: inside+coplanar-front/back, outside+coplanar-front/back, and outside
#
# The operation supports both mesh-to-mesh and polytree-to-polytree inputs
# for backward compatibility and provides optimized processing paths.
#
# @author Jacob Philpott
# @since 0.0.1

# === POLYGON CLASSIFICATION RULES FOR INTERSECT OPERATION ===

# Define which polygons to remove during intersect operation.
# Rules specify polygon states that should be deleted from each object.
# Intersect keeps only the overlapping volume, so most polygons are removed.
intersectRules =

    # Rules for object A: Remove inside+coplanar-back, outside+coplanar-front/back, and outside.
    a: [
        { array: true, rule: ["inside", "coplanar-back"] }
        { array: true, rule: ["outside", "coplanar-front"] }
        { array: true, rule: ["outside", "coplanar-back"] }
        { array: false, rule: "outside" }
    ]

    # Rules for object B: Remove inside+coplanar-front/back, outside+coplanar-front/back, and outside.
    b: [
        { array: true, rule: ["inside", "coplanar-front"] }
        { array: true, rule: ["inside", "coplanar-back"] }
        { array: true, rule: ["outside", "coplanar-front"] }
        { array: true, rule: ["outside", "coplanar-back"] }
        { array: false, rule: "outside" }
    ]

# === PUBLIC CSG OPERATIONS ===

# Perform intersect operation between two 3D objects.
# This keeps only the overlapping volume common to both objects.
# @param mesh1 - First 3D object to intersect (Three.js Mesh or Polytree instance).
# @param mesh2 - Second 3D object to intersect (Three.js Mesh or Polytree instance).
# @param targetMaterial - Optional material for result mesh. If null and polytree input, returns polytree.
# @return Three.js Mesh with intersected geometry or Polytree instance.
Polytree.intersect = (mesh1, mesh2, targetMaterial = null) ->

    # Handle both mesh and polytree inputs for backward compatibility.
    if mesh1.isPolytree and mesh2.isPolytree

        # Direct polytree-to-polytree operation - most efficient path.
        polytreeA = mesh1
        polytreeB = mesh2
        buildTargetPolytree = if targetMaterial is null then true else false

        return this.intersectCore(polytreeA, polytreeB, buildTargetPolytree)

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

        # Perform intersect operation and convert result back to mesh.
        resultPolytree = this.intersectCore(polytreeA, polytreeB, false)
        resultMesh = Polytree.toMesh(resultPolytree, targetMaterial)
        disposePolytree(polytreeA, polytreeB, resultPolytree)

        return resultMesh

# === CORE CSG IMPLEMENTATION ===

# Core intersect operation implementation working with polytree objects.
# This method performs the actual CSG boolean logic for intersection operations.
# @param polytreeA - First polytree object to intersect.
# @param polytreeB - Second polytree object to intersect.
# @param buildTargetPolytree - Whether to build spatial tree structure in result.
# @return Polytree containing the intersected geometry.
Polytree.intersectCore = (polytreeA, polytreeB, buildTargetPolytree = true) ->

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

        # Step 5: Apply intersect-specific rules to remove unwanted polygons.
        polytreeA.deletePolygonsByStateRules(intersectRules.a)
        polytreeB.deletePolygonsByStateRules(intersectRules.b)

        # Step 6: Special processing for intersect operation.
        # Remove intersecting polygons from both objects to clean up overlapping geometry.
        polytreeA.deletePolygonsByIntersection(false)
        polytreeB.deletePolygonsByIntersection(false)

        # Step 7: Copy remaining polygons to result polytree.
        polytreeA.getPolygonCloneCallback(polytree.addPolygon.bind(polytree), trianglesSet)
        polytreeB.getPolygonCloneCallback(polytree.addPolygon.bind(polytree), trianglesSet)

        # Restore original material sides.
        if polytreeA.mesh and polytreeA.mesh.material.side isnt currentMeshSideA

            polytreeA.mesh.material.side = currentMeshSideA

        if polytreeB.mesh and polytreeB.mesh.material.side isnt currentMeshSideB

            polytreeB.mesh.material.side = currentMeshSideB

    # Note: If no intersection, result is empty (no polygons added).

    # === FINALIZATION ===

    # Clean up temporary triangle tracking.
    trianglesSet.clear()
    trianglesSet = undefined

    # Mark polygons as original (not generated by CSG operations).
    polytree.markPolygonsAsOriginal()
    
    # Build spatial tree structure if requested for optimization.
    buildTargetPolytree and polytree.buildTree()

    return polytree
