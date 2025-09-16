# Temporary vectors and objects for calculations
tempVector1 = new Vector3()
tempVector2 = new Vector3()
tempBox3 = new Box3()
tempRaycaster = new Raycaster()
tempRay = new Ray()
tempRayDirection = new Vector3(0, 0, 1)

# Constants for polygon classification
EPSILON = 1e-5
COPLANAR = 0
FRONT = 1
BACK = 2
SPANNING = 3

# Winding Number algorithm variables
_wV1 = new Vector3()
_wV2 = new Vector3()
_wV3 = new Vector3()
_wP = new Vector3()
_wP_EPS_ARR = [
    new Vector3(EPSILON, 0, 0)
    new Vector3(0, EPSILON, 0)
    new Vector3(0, 0, EPSILON)
    new Vector3(-EPSILON, 0, 0)
    new Vector3(0, -EPSILON, 0)
    new Vector3(0, 0, -EPSILON)
]
_wP_EPS_ARR_COUNT = _wP_EPS_ARR.length
_matrix3 = new Matrix3()
wNPI = 4 * Math.PI

# Ray-Triangle intersection variables
edge1 = new Vector3()
edge2 = new Vector3()
h = new Vector3()
s = new Vector3()
q = new Vector3()
RAY_EPSILON = 0.0000001

# Temporary variables for matrix operations
triangleVertex0 = new Vector3()
tmpm3 = new Matrix3()
tmpm3.getNormalMatrix = (matrix) ->
    @setFromMatrix4(matrix).invert().transpose()