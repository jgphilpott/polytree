# Spatial query utilities for enhanced Polytree functionality.
# These methods provide advanced spatial querying capabilities useful for 3D printing,
# CAD operations, and general-purpose geometric analysis beyond basic CSG.
#
# Inspired by three-mesh-bvh spatial query capabilities.

# Find the closest point on any triangle in the polytree to the given point.
# This is essential for collision detection, mesh repair, and support structure generation.
#
# @param polytree - The Polytree instance to query.
# @param targetPoint - Vector3 point to find closest point to.
# @param target - Optional object to store result data.
# @param maxDistance - Maximum search distance (Infinity by default).
#
# @return Object with point, distance, and triangle properties or null if none found.
Polytree.closestPointToPoint = (polytree, targetPoint, target = {}, maxDistance = Infinity) ->

    return null unless polytree and targetPoint

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

        return target

    return null

# Calculate the shortest distance from a point to any surface in the polytree.
# Useful for distance field generation and proximity analysis.
#
# @param polytree - The Polytree instance to query.
# @param targetPoint - Vector3 point to calculate distance to.
#
# @return Distance value as number, or Infinity if no surfaces found.
Polytree.distanceToPoint = (polytree, targetPoint) ->

    result = Polytree.closestPointToPoint(polytree, targetPoint)

    return result?.distance or Infinity

# Test if a sphere intersects with the polytree geometry.
# Useful for collision detection and proximity testing.
#
# @param polytree - The Polytree instance to test against.
# @param sphere - Sphere object with center and radius properties.
#
# @return Boolean indicating intersection.
Polytree.intersectsSphere = (polytree, sphere) ->

    return false unless polytree and sphere

    triangles = polytree.getTriangles()

    for triangle in triangles

        testTriangle = new Triangle(triangle.a, triangle.b, triangle.c)

        if testTriangle.intersectsSphere(sphere)

            return true

    return false

# Test if a bounding box intersects with the polytree geometry.
# Useful for broad-phase collision detection and spatial partitioning.
#
# @param polytree - The Polytree instance to test against.
# @param boundingBox - Box3 object defining the bounding volume.
#
# @return Boolean indicating intersection.
Polytree.intersectsBox = (polytree, boundingBox) ->

    return false unless polytree and boundingBox

    triangles = polytree.getTriangles()

    for triangle in triangles

        testTriangle = new Triangle(triangle.a, triangle.b, triangle.c)

        if boundingBox.intersectsTriangle(testTriangle)

            return true

    return false

# Find all intersection points between a plane and the polytree mesh.
# This is the core functionality needed for 3D printing slicing operations.
#
# @param polytree - The Polytree instance to slice.
# @param plane - Plane object defining the slicing plane.
# @param target - Optional array to store intersection line segments.
#
# @return Array of Line3 objects representing intersection segments.
Polytree.intersectPlane = (polytree, plane, target = []) ->

    return target unless polytree and plane

    triangles = polytree.getTriangles()

    for triangle in triangles

        testTriangle = new Triangle(triangle.a, triangle.b, triangle.c)
        intersectionPoints = []

        # Test each edge of the triangle against the plane.
        triangleEdges = [
            new Line3(triangle.a, triangle.b)
            new Line3(triangle.b, triangle.c)
            new Line3(triangle.c, triangle.a)
        ]

        for edge in triangleEdges

            intersectionPoint = new Vector3()
            
            if plane.intersectLine(edge, intersectionPoint)

                # Check if intersection point is actually on the edge segment.
                edgeLength = edge.distance()
                startDistance = intersectionPoint.distanceTo(edge.start)
                endDistance = intersectionPoint.distanceTo(edge.end)

                # Point is on edge if sum of distances equals edge length (within tolerance).
                if Math.abs((startDistance + endDistance) - edgeLength) < 1e-10

                    intersectionPoints.push(intersectionPoint.clone())

        # If we have exactly 2 intersection points, create a line segment.
        if intersectionPoints.length is 2

            target.push(new Line3(intersectionPoints[0], intersectionPoints[1]))

    return target

# Create a series of parallel plane intersections for layer-by-layer slicing.
# Essential for 3D printing applications where the model needs to be sliced
# into horizontal layers at regular intervals.
#
# @param polytree - The Polytree instance to slice.
# @param layerHeight - Height between each slice layer.
# @param minZ - Starting Z coordinate for slicing.
# @param maxZ - Ending Z coordinate for slicing.
# @param normal - Optional plane normal vector (defaults to Z-up).
#
# @return Array of arrays, each containing Line3 segments for that layer.
Polytree.sliceIntoLayers = (polytree, layerHeight, minZ, maxZ, normal = new Vector3(0, 0, 1)) ->

    return [] unless polytree and layerHeight > 0 and minZ < maxZ

    layers = []
    currentZ = minZ

    while currentZ <= maxZ

        # Create plane at current height.
        slicePlane = new Plane(normal.clone(), -currentZ)
        
        # Get intersection segments for this layer.
        layerSegments = Polytree.intersectPlane(polytree, slicePlane)
        
        layers.push(layerSegments)
        currentZ += layerHeight

    return layers

# Perform a generic spatial query using a custom callback function.
# This provides flexibility for implementing custom spatial operations.
#
# @param polytree - The Polytree instance to query.
# @param queryCallback - Function that tests each triangle and returns boolean.
# @param collectCallback - Optional function to collect/process matching triangles.
#
# @return Array of results from collectCallback, or array of matching triangles.
Polytree.shapecast = (polytree, queryCallback, collectCallback = null) ->

    return [] unless polytree and queryCallback

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

    return results

# Find all triangles within a specified distance of a target point.
# Useful for local mesh operations and region-based analysis.
#
# @param polytree - The Polytree instance to search.
# @param targetPoint - Vector3 center point for the search.
# @param searchRadius - Maximum distance from point to include triangles.
#
# @return Array of triangles within the search radius.
Polytree.getTrianglesNearPoint = (polytree, targetPoint, searchRadius) ->

    return [] unless polytree and targetPoint and searchRadius > 0

    searchSphere = new Sphere(targetPoint, searchRadius)

    return Polytree.shapecast polytree, (testTriangle) ->
        
        testTriangle.intersectsSphere(searchSphere)

# Calculate approximate volume using monte carlo sampling.
# Useful for complex geometries where analytical volume calculation is difficult.
#
# @param polytree - The Polytree instance to analyze.
# @param sampleCount - Number of random samples to use (default 10000).
# @param boundingBox - Optional bounding box for sampling region.
#
# @return Estimated volume as number.
Polytree.estimateVolumeViaSampling = (polytree, sampleCount = 10000, boundingBox = null) ->

    return 0 unless polytree

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
        intersections = polytree.rayIntersect(testRay, new Matrix4())

        # Point is inside if odd number of intersections.
        insideCount++ if intersections.length % 2 is 1

    # Calculate volume ratio and scale by bounding box volume.
    volumeRatio = insideCount / sampleCount
    
    return volumeRatio * boxVolume