import * as THREE from '../threejs/three.module.js'

# console.log("GOT HERE");

onmessage = (e) ->

    # let randLimit = Math.round(Math.random() * 1000000000);
    # console.log("[WORKER]", randLimit, e);
    # let worker_data = {
    #     type: 'windingNumber',
    #     point: point,
    #     triangles: buffer
    # }
    { type, point, coplanar, polygonID, triangles } = e.data
    trianglesArr = new Float32Array(triangles)
    # console.log("[WORKER] Checking Polygon ID:", polygonID, point);

    if type is 'windingNumber'

        postMessage
            type: type
            result: polyInside_WindingNumber_buffer(trianglesArr, point, coplanar)

    else

        a = 0
        # for (let i = 0; i < randLimit; i++) {
        #     a++;
        # }
        postMessage "[From Worker] Aloha #{a}"

# Winding Number algorithm adapted from https://github.com/grame-cncm/faust/blob/master-dev/tools/physicalModeling/mesh2faust/vega/libraries/windingNumber/windingNumber.cpp

EPSILON = 1e-5

_wV1 = new THREE.Vector3()
_wV2 = new THREE.Vector3()
_wV3 = new THREE.Vector3()
_wP = new THREE.Vector3()

_wP_EPS_ARR = [
    new THREE.Vector3(EPSILON, 0, 0)
    new THREE.Vector3(0, EPSILON, 0)
    new THREE.Vector3(0, 0, EPSILON)
    new THREE.Vector3(-EPSILON, 0, 0)
    new THREE.Vector3(0, -EPSILON, 0)
    new THREE.Vector3(0, 0, -EPSILON)
]

_wP_EPS_ARR_COUNT = _wP_EPS_ARR.length
_matrix3 = new THREE.Matrix3()
wNPI = 4 * Math.PI

# function calcDet(a, b, c) {
#     return (-a.z * b.y * c.x +
#              a.y * b.z * c.x +
#              a.z * b.x * c.y +
#              a.x * b.z * c.y +
#              a.y * b.x * c.z +
#              a.x * b.y * c.z );
# }

returnXYZ = (arr, index) ->

    x: arr[index]
    y: arr[index + 1]
    z: arr[index + 2]

calcWindingNumber_buffer = (trianglesArr, point) ->

    wN = 0

    for i in [0...trianglesArr.length] by 9

        _wV1.subVectors(returnXYZ(trianglesArr, i), point)
        _wV2.subVectors(returnXYZ(trianglesArr, i + 3), point)
        _wV3.subVectors(returnXYZ(trianglesArr, i + 6), point)
        lenA = _wV1.length()
        lenB = _wV2.length()
        lenC = _wV3.length()
        _matrix3.set(_wV1.x, _wV1.y, _wV1.z, _wV2.x, _wV2.y, _wV2.z, _wV3.x, _wV3.y, _wV3.z)
        omega = 2 * Math.atan2(_matrix3.determinant(), (lenA * lenB * lenC + _wV1.dot(_wV2) * lenC + _wV2.dot(_wV3) * lenA + _wV3.dot(_wV1) * lenB))
        wN += omega

    wN = Math.round(wN / wNPI)
    return wN

polyInside_WindingNumber_buffer = (trianglesArr, point, coplanar) ->

    result = false
    _wP.copy(point)
    wN = calcWindingNumber_buffer(trianglesArr, _wP)
    coplanarFound = false

    if wN is 0

        if coplanar

            # console.log("POLYGON IS COPLANAR");
            for j in [0..._wP_EPS_ARR_COUNT]

                # console.warn("DOES IT GET HERE?");
                _wP.copy(point).add(_wP_EPS_ARR[j])
                wN = calcWindingNumber_buffer(trianglesArr, _wP)

                if wN isnt 0

                    # console.warn("GOT HERE");
                    result = true
                    coplanarFound = true
                    break

    else

        result = true

    # if (result && polygon.coplanar) {
    #     console.log(`[polyInside_WindingNumber] coplanar polygon found ${coplanarFound ? "IN" : "NOT IN"} coplanar test`);
    # }
    return result

# export {}
