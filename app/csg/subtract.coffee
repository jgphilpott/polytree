# ============================================================================
# Subtract CSG Operation for Polytree
# ============================================================================
#
# This module implements the subtraction (difference) boolean operation for
# Constructive Solid Geometry (CSG). The subtract operation removes the volume
# of the second object from the first object, creating a carved-out result.
#
# Algorithm Overview:
#
# The subtract operation preserves polygons that define the external surface
# of object A minus the volume of object B. It processes:
#
# - Polygons from A that are outside B or coplanar-front with B
# - Polygons from B that are inside A, inverted to form internal surfaces
#
# The operation supports both mesh-to-mesh and polytree-to-polytree inputs
# for backward compatibility and provides optimized processing paths.

# === POLYGON CLASSIFICATION RULES FOR SUBTRACT OPERATION ===

# Define which polygons to remove during subtract operation.
# Rules specify polygon states that should be deleted from each object.
subtractRules =

    # Rules for object A: Remove polygons that are inside B.
    a: [
        { array: true, rule: ["inside", "coplanar-back"] }
        { array: true, rule: ["inside", "coplanar-front"] }
        { array: false, rule: "inside" }
    ]

    # Rules for object B: Remove polygons that are outside A.
    b: [
        { array: true, rule: ["outside", "coplanar-back"] }
        { array: true, rule: ["outside", "coplanar-front"] }
        { array: true, rule: ["inside", "coplanar-front"] }
        { array: false, rule: "outside" }
    ]

# === PUBLIC CSG OPERATIONS ===

# Perform subtract (difference) operation between two 3D objects.
# This removes the volume of mesh2 from mesh1, creating a carved result.
#
# @param mesh1 - Primary 3D object to subtract from (Three.js Mesh or Polytree instance).
# @param mesh2 - 3D object to subtract away (Three.js Mesh or Polytree instance).
# @param async - Whether to perform operation asynchronously (default: false).
#
# @return Three.js Mesh with subtracted geometry, Polytree instance, or Promise.
Polytree.subtract = (mesh1, mesh2, async = false) ->

    # Handle async request - delegate to async module.
    if async

        # Convert meshes to polytrees if needed for async processing.
        if mesh1.isPolytree and mesh2.isPolytree

            return Polytree.async.subtract(mesh1, mesh2, true)

        else

            # Convert meshes to polytrees and return Promise that resolves to mesh.
            polytreeA = Polytree.fromMesh(mesh1)
            polytreeB = Polytree.fromMesh(mesh2)

            # Get material from first mesh for final result.
            targetMaterial = if Array.isArray(mesh1.material) then mesh1.material[0] else mesh1.material
            targetMaterial = targetMaterial.clone()

            return Polytree.async.subtract(polytreeA, polytreeB, false).then (resultPolytree) ->

                resultMesh = Polytree.toMesh(resultPolytree, targetMaterial)
                disposePolytreeResources(polytreeA, polytreeB, resultPolytree)

                return resultMesh

    # Handle both mesh and polytree inputs for backward compatibility.
    if mesh1.isPolytree and mesh2.isPolytree

        # Direct polytree-to-polytree operation - most efficient path.
        polytreeA = mesh1
        polytreeB = mesh2

        return this.subtractCore(polytreeA, polytreeB, true)

    else

        # Mesh-to-mesh operation (default behavior) - converts to polytrees internally.
        polytreeA = Polytree.fromMesh(mesh1)
        polytreeB = Polytree.fromMesh(mesh2)

        # Always use material from first mesh (cloned for safety).
        targetMaterial = if Array.isArray(mesh1.material) then mesh1.material[0] else mesh1.material
        targetMaterial = targetMaterial.clone()

        # Perform subtract operation and convert result back to mesh.
        resultPolytree = this.subtractCore(polytreeA, polytreeB, false)
        resultMesh = Polytree.toMesh(resultPolytree, targetMaterial)

        disposePolytreeResources(polytreeA, polytreeB, resultPolytree)

        return resultMesh

# === CORE CSG IMPLEMENTATION ===

# Core subtract operation implementation working with polytree objects.
# This method performs the actual CSG boolean logic for difference operations.
#
# @param polytreeA - Primary polytree object to subtract from.
# @param polytreeB - Polytree object to subtract away from A.
# @param buildTargetPolytree - Whether to build spatial tree structure in result.
#
# @return Polytree containing the subtracted geometry.
Polytree.subtractCore = (polytreeA, polytreeB, buildTargetPolytree = true) ->

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

        # Step 5: Apply subtract-specific rules to remove unwanted polygons.
        polytreeA.deletePolygonsByStateRules(subtractRules.a)
        polytreeB.deletePolygonsByStateRules(subtractRules.b)

        # Step 6: Special processing for subtract operation.
        # Remove intersecting polygons from B and invert B's normals for cavity formation.
        polytreeB.deletePolygonsByIntersection(false)
        polytreeB.invert()

        # Step 7: Copy remaining polygons to result polytree.
        polytreeA.getPolygonCloneCallback(polytree.addPolygon.bind(polytree), trianglesSet)
        polytreeB.getPolygonCloneCallback(polytree.addPolygon.bind(polytree), trianglesSet)

        # Restore original material sides.
        if polytreeA.mesh and polytreeA.mesh.material.side isnt currentMeshSideA

            polytreeA.mesh.material.side = currentMeshSideA

        if polytreeB.mesh and polytreeB.mesh.material.side isnt currentMeshSideB

            polytreeB.mesh.material.side = currentMeshSideB

    else

        # No intersection detected - return only object A since B doesn't affect it.
        polytreeA.getPolygonCloneCallback(polytree.addPolygon.bind(polytree), trianglesSet)

    # === FINALIZATION ===

    # Clean up temporary triangle tracking.
    trianglesSet.clear()
    trianglesSet = undefined

    # Mark polygons as original (not generated by CSG operations).
    polytree.markPolygonsAsOriginal()

    # Build spatial tree structure if requested for optimization.
    buildTargetPolytree and polytree.buildTree()

    return polytree
