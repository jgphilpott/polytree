# Helper buffer for 2D vectors.
nbuf2 = (ct) ->

    top: 0
    array: new Float32Array(ct)

    write: (v) ->

        @array[@top++] = v.x
        @array[@top++] = v.y

# Helper buffer for 3D vectors.
nbuf3 = (ct) ->

    top: 0
    array: new Float32Array(ct)

    write: (v) ->

        @array[@top++] = v.x
        @array[@top++] = v.y
        @array[@top++] = v.z
