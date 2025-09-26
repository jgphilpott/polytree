# Spatial query utilities for enhanced Polytree functionality.
# These methods provide advanced spatial querying capabilities useful for 3D printing,
# CAD operations, and general-purpose geometric analysis beyond basic CSG.
#
# Inspired by three-mesh-bvh spatial query capabilities.

# Helper function to convert various input types to polytree.
# @param input - Three.js Mesh, BufferGeometry, or Polytree instance.
# @return Object with polytree and shouldCleanup flag, or null if invalid input.
convertToPolytree = (input) ->
    
    return null unless input

    if input.isPolytree
        
        return { polytree: input, shouldCleanup: false }
        
    else if input.isMesh
        
        return { polytree: Polytree.fromMesh(input), shouldCleanup: true }
        
    else if input.isBufferGeometry
        
        # Create a temporary mesh from BufferGeometry
        tempMesh = new Mesh(input, new MeshBasicMaterial())
        return { polytree: Polytree.fromMesh(tempMesh), shouldCleanup: true }
        
    else
        
        return null

# Find the closest point on any triangle surface to the given point.
# This is essential for collision detection, mesh repair, and support structure generation.
#
# @param input - Three.js Mesh, BufferGeometry, or Polytree instance to query.
# @param targetPoint - Vector3 point to find closest point to.
# @param target - Optional object to store result data.
# @param maxDistance - Maximum search distance (Infinity by default).
#
# @return Object with point, distance, and triangle properties or null if none found.
Polytree.closestPointToPoint = (input, targetPoint, target = {}, maxDistance = Infinity) ->

    return null unless input and targetPoint

    # Handle different input types - convert to polytree if needed.
    result = convertToPolytree(input)
    return null unless result
    
    { polytree, shouldCleanup } = result

    closestDistance = maxDistance
    closestPoint = null
    closestTriangle = null

    triangles = polytree.getTriangles()

    for triangle in triangles

        # Create temporary triangle for calculations.
        testTriangle = new Triangle(triangle.a, triangle.b, triangle.c)
        
        # Calculate closest point on triangle to target point.
        trianglePoint = new Vector3()
        testTriangle.closestPointToPoint(targetPoint, trianglePoint)

        # Calculate distance to this point.
        currentDistance = trianglePoint.distanceTo(targetPoint)

        if currentDistance < closestDistance

            closestDistance = currentDistance
            closestPoint = trianglePoint.clone()
            closestTriangle = triangle

    if closestPoint

        target.point = closestPoint
        target.distance = closestDistance
        target.triangle = closestTriangle

        # Clean up temporary polytree if created
        shouldCleanup and polytree.delete()

        return target

    # Clean up temporary polytree if created
    shouldCleanup and polytree.delete()

    return null

# Calculate the shortest distance from a point to any surface in the geometry.
# Useful for distance field generation and proximity analysis.
#
# @param input - Three.js Mesh, BufferGeometry, or Polytree instance to query.
# @param targetPoint - Vector3 point to calculate distance to.
#
# @return Distance value as number, or Infinity if no surfaces found.
Polytree.distanceToPoint = (input, targetPoint) ->

    result = Polytree.closestPointToPoint(input, targetPoint)

    return result?.distance or Infinity

# Test if a sphere intersects with the geometry.
# Useful for collision detection and proximity testing.
#
# @param input - Three.js Mesh, BufferGeometry, or Polytree instance to test against.
# @param sphere - Sphere object with center and radius properties.
#
# @return Boolean indicating intersection.
Polytree.intersectsSphere = (input, sphere) ->

    return false unless input and sphere

    # Handle different input types - convert to polytree if needed.
    result = convertToPolytree(input)
    return false unless result
    
    { polytree, shouldCleanup } = result

    triangles = polytree.getTriangles()

    for triangle in triangles

        testTriangle = new Triangle(triangle.a, triangle.b, triangle.c)

        # Simple sphere-triangle intersection: check if sphere center is close to triangle
        closestPoint = new Vector3()
        testTriangle.closestPointToPoint(sphere.center, closestPoint)
        distance = closestPoint.distanceTo(sphere.center)

        if distance <= sphere.radius

            # Clean up temporary polytree if created
            shouldCleanup and polytree.delete()
            return true

    # Clean up temporary polytree if created
    shouldCleanup and polytree.delete()

    return false

# Test if a bounding box intersects with the geometry.
# Useful for broad-phase collision detection and spatial partitioning.
#
# @param input - Three.js Mesh, BufferGeometry, or Polytree instance to test against.
# @param boundingBox - Box3 object defining the bounding volume.
#
# @return Boolean indicating intersection.
Polytree.intersectsBox = (input, boundingBox) ->

    return false unless input and boundingBox

    # Handle different input types - convert to polytree if needed.
    result = convertToPolytree(input)
    return false unless result
    
    { polytree, shouldCleanup } = result

    triangles = polytree.getTriangles()

    for triangle in triangles

        testTriangle = new Triangle(triangle.a, triangle.b, triangle.c)

        if boundingBox.intersectsTriangle(testTriangle)

            # Clean up temporary polytree if created
            shouldCleanup and polytree.delete()
            return true

    # Clean up temporary polytree if created
    shouldCleanup and polytree.delete()

    return false

# Find all intersection points between a plane and the mesh surface.
# This is the core functionality needed for 3D printing slicing operations.
#
# @param input - Three.js Mesh, BufferGeometry, or Polytree instance to slice.
# @param plane - Plane object defining the slicing plane.
# @param target - Optional array to store intersection line segments.
#
# @return Array of Line3 objects representing intersection segments.
Polytree.intersectPlane = (input, plane, target = []) ->

    return target unless input and plane

    # Handle different input types - convert to polytree if needed.
    result = convertToPolytree(input)
    return target unless result
    
    { polytree, shouldCleanup } = result

    triangles = polytree.getTriangles()

    for triangle in triangles

        testTriangle = new Triangle(triangle.a, triangle.b, triangle.c)
        intersectionPoints = []

        # Test each edge of the triangle against the plane.
        triangleEdges = [
            [triangle.a, triangle.b]
            [triangle.b, triangle.c]
            [triangle.c, triangle.a]
        ]

        for edge in triangleEdges
            
            startPoint = edge[0]
            endPoint = edge[1]

            # Calculate distances to plane manually (since bundle context may not have plane methods)
            # Distance = normal.dot(point) + constant
            startDist = plane.normal.dot(startPoint) + plane.constant
            endDist = plane.normal.dot(endPoint) + plane.constant

            # Check if edge crosses the plane (different signs)
            if (startDist * endDist) < 0

                # Calculate intersection point using linear interpolation
                t = startDist / (startDist - endDist)
                intersectionPoint = new Vector3()
                intersectionPoint.lerpVectors(startPoint, endPoint, t)
                intersectionPoints.push(intersectionPoint)

        # If we have exactly 2 intersection points, create a line segment.
        if intersectionPoints.length is 2

            target.push(new Line3(intersectionPoints[0], intersectionPoints[1]))

    # Clean up temporary polytree if created
    shouldCleanup and polytree.delete()

    return target

# Create a series of parallel plane intersections for layer-by-layer slicing.
# Essential for 3D printing applications where the model needs to be sliced
# into horizontal layers at regular intervals.
#
# @param input - Three.js Mesh, BufferGeometry, or Polytree instance to slice.
# @param layerHeight - Height between each slice layer.
# @param minZ - Starting Z coordinate for slicing.
# @param maxZ - Ending Z coordinate for slicing.
# @param normal - Optional plane normal vector (defaults to Z-up).
#
# @return Array of arrays, each containing Line3 segments for that layer.
Polytree.sliceIntoLayers = (input, layerHeight, minZ, maxZ, normal = new Vector3(0, 0, 1)) ->

    return [] unless input and layerHeight > 0 and minZ < maxZ

    # Convert input to polytree once at the beginning
    result = convertToPolytree(input)
    return [] unless result
    
    { polytree, shouldCleanup } = result

    layers = []
    currentZ = minZ

    while currentZ <= maxZ

        # Create plane at current height using manual plane equation
        # Since bundle context may not have proper Plane constructor access
        planeNormal = normal.clone()
        planeConstant = -currentZ
        
        # Use manual plane-triangle intersection instead of Plane object
        layerSegments = []
        triangles = polytree.getTriangles()
        
        for triangle in triangles

            intersectionPoints = []

            # Test each edge of the triangle against the plane.
            triangleEdges = [
                [triangle.a, triangle.b]
                [triangle.b, triangle.c]
                [triangle.c, triangle.a]
            ]

            for edge in triangleEdges
                
                startPoint = edge[0]
                endPoint = edge[1]

                # Calculate distances to plane manually
                startDist = planeNormal.dot(startPoint) + planeConstant
                endDist = planeNormal.dot(endPoint) + planeConstant

                # Check if edge crosses the plane (different signs)
                if (startDist * endDist) < 0

                    # Calculate intersection point using linear interpolation
                    t = startDist / (startDist - endDist)
                    intersectionPoint = new Vector3()
                    intersectionPoint.lerpVectors(startPoint, endPoint, t)
                    intersectionPoints.push(intersectionPoint)

            # If we have exactly 2 intersection points, create a line segment.
            if intersectionPoints.length is 2

                layerSegments.push(new Line3(intersectionPoints[0], intersectionPoints[1]))
        
        layers.push(layerSegments)
        currentZ += layerHeight

    # Clean up temporary polytree if created
    shouldCleanup and polytree.delete()

    return layers

# Perform a generic spatial query using a custom callback function.
# This provides flexibility for implementing custom spatial operations.
#
# @param input - Three.js Mesh, BufferGeometry, or Polytree instance to query.
# @param queryCallback - Function that tests each triangle and returns boolean.
# @param collectCallback - Optional function to collect/process matching triangles.
#
# @return Array of results from collectCallback, or array of matching triangles.
Polytree.shapecast = (input, queryCallback, collectCallback = null) ->

    return [] unless input and queryCallback

    # Handle different input types - convert to polytree if needed.
    result = convertToPolytree(input)
    return [] unless result
    
    { polytree, shouldCleanup } = result

    results = []
    triangles = polytree.getTriangles()

    for triangle in triangles

        testTriangle = new Triangle(triangle.a, triangle.b, triangle.c)

        if queryCallback(testTriangle, triangle)

            if collectCallback

                result = collectCallback(testTriangle, triangle)
                results.push(result) if result?

            else

                results.push(triangle)

    # Clean up temporary polytree if created
    shouldCleanup and polytree.delete()

    return results

# Find all triangles within a specified distance of a target point.
# Useful for local mesh operations and region-based analysis.
#
# @param input - Three.js Mesh, BufferGeometry, or Polytree instance to search.
# @param targetPoint - Vector3 center point for the search.
# @param searchRadius - Maximum distance from point to include triangles.
#
# @return Array of triangles within the search radius.
Polytree.getTrianglesNearPoint = (input, targetPoint, searchRadius) ->

    return [] unless input and targetPoint and searchRadius > 0

    return Polytree.shapecast input, (testTriangle, originalTriangle) ->
        
        # Check if any vertex of the triangle is within the search radius
        return (testTriangle.a.distanceTo(targetPoint) <= searchRadius or
                testTriangle.b.distanceTo(targetPoint) <= searchRadius or
                testTriangle.c.distanceTo(targetPoint) <= searchRadius)

# Calculate approximate volume using monte carlo sampling.
# Useful for complex geometries where analytical volume calculation is difficult.
#
# @param input - Three.js Mesh, BufferGeometry, or Polytree instance to analyze.
# @param sampleCount - Number of random samples to use (default 10000).
# @param boundingBox - Optional bounding box for sampling region.
#
# @return Estimated volume as number.
Polytree.estimateVolumeViaSampling = (input, sampleCount = 10000, boundingBox = null) ->

    return 0 unless input

    # Handle different input types - convert to polytree if needed.
    result = convertToPolytree(input)
    return 0 unless result
    
    { polytree, shouldCleanup } = result

    # Use polytree bounding box if none provided.
    unless boundingBox

        boundingBox = new Box3()
        triangles = polytree.getTriangles()

        for triangle in triangles

            boundingBox.expandByPoint(triangle.a)
            boundingBox.expandByPoint(triangle.b) 
            boundingBox.expandByPoint(triangle.c)

    # Calculate bounding box volume for scaling.
    boxSize = new Vector3()
    boundingBox.getSize(boxSize)
    boxVolume = boxSize.x * boxSize.y * boxSize.z

    return 0 if boxVolume is 0

    insideCount = 0

    # Test random points inside bounding box.
    for i in [0...sampleCount]

        # Generate random point in bounding box.
        samplePoint = new Vector3(
            boundingBox.min.x + Math.random() * boxSize.x
            boundingBox.min.y + Math.random() * boxSize.y
            boundingBox.min.z + Math.random() * boxSize.z
        )

        # Test if point is inside the mesh using ray casting.
        testRay = new Ray(samplePoint, new Vector3(1, 0, 0))
        identityMatrix = new Matrix4() # Create identity matrix locally
        intersections = polytree.rayIntersect(testRay, identityMatrix)

        # Point is inside if odd number of intersections.
        insideCount++ if intersections.length % 2 is 1

    # Calculate volume ratio and scale by bounding box volume.
    volumeRatio = insideCount / sampleCount

    # Clean up temporary polytree if created
    shouldCleanup and polytree.delete()
    
    return volumeRatio * boxVolume