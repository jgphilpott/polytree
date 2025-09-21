module.exports.Polytree = Polytree

module.exports.Plane = Plane
module.exports.Vertex = Vertex
module.exports.Polygon = Polygon

module.exports.isValidTriangle = isValidTriangle
module.exports.isUniqueTriangle = isUniqueTriangle
module.exports.rayIntersectsTriangle = rayIntersectsTriangle
module.exports.triangleIntersectsTriangle = triangleIntersectsTriangle

module.exports.resolveTriangleIntersection = resolveTriangleIntersection
module.exports.resolveCoplanarTriangleIntersection = resolveCoplanarTriangleIntersection

module.exports.trianglesOverlap2D = trianglesOverlap2D
module.exports.triangleOrientation2D = triangleOrientation2D
module.exports.triangleIntersectionCCW2D = triangleIntersectionCCW2D

module.exports.intersectionTestEdge2D = intersectionTestEdge2D
module.exports.intersectionTestVertex2D = intersectionTestVertex2D

module.exports.constructIntersection = constructIntersection

# Helper functions - new descriptive names
module.exports.createVector2Buffer = createVector2Buffer
module.exports.createVector3Buffer = createVector3Buffer
module.exports.sortRaycastIntersectionsByDistance = sortRaycastIntersectionsByDistance
module.exports.roundPointCoordinates = roundPointCoordinates
module.exports.extractCoordinatesFromArray = extractCoordinatesFromArray
module.exports.splitPolygonByPlane = splitPolygonByPlane
module.exports.splitPolygonVertexArray = splitPolygonVertexArray
module.exports.calculateWindingNumberFromBuffer = calculateWindingNumberFromBuffer
module.exports.testPolygonInsideUsingWindingNumber = testPolygonInsideUsingWindingNumber
module.exports.prepareTriangleBufferFromPolygons = prepareTriangleBufferFromPolygons
module.exports.testRayTriangleIntersection = testRayTriangleIntersection
module.exports.handleIntersectingPolytrees = handleIntersectingPolytrees
module.exports.disposePolytreeResources = disposePolytreeResources

# Helper functions - backward compatibility aliases
module.exports.nbuf2 = nbuf2
module.exports.nbuf3 = nbuf3
module.exports.raycastIntersectAscSort = raycastIntersectAscSort
module.exports.pointRounding = pointRounding
module.exports.returnXYZ = returnXYZ
module.exports.calcWindingNumber_buffer = calcWindingNumber_buffer
module.exports.polyInside_WindingNumber_buffer = polyInside_WindingNumber_buffer
module.exports.prepareTriangleBuffer = prepareTriangleBuffer
module.exports.disposePolytree = disposePolytree
module.exports.splitPolygonArr = splitPolygonArr
