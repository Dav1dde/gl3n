module gl3n.util;

private {
    import gl3n.linalg : Vector, Matrix, Quaternion;
    
    version(unittest) {
        import gl3n.linalg : vec2, vec3, vec3d, vec4i, mat2, mat34, mat4, quat;
    }
}


private void is_vector_impl(T, int d)(Vector!(T, d) vec) {}

template is_vector(T) {
    enum is_vector = is(typeof(is_vector_impl(T.init)));
}

private void is_matrix_impl(T, int r, int c)(Matrix!(T, r, c) mat) {}

template is_matrix(T) {
    enum is_matrix = is(typeof(is_matrix_impl(T.init)));
}

private void is_quaternion_impl(T)(Quaternion!(T) qu) {}

template is_quaternion(T) {
    enum is_quaternion = is(typeof(is_quaternion_impl(T.init)));
}

unittest {
    assert(is_vector!vec2);
    assert(is_vector!vec3);
    assert(is_vector!vec3d);
    assert(is_vector!vec4i);
    assert(!is_vector!int);
    assert(!is_vector!mat34);
    assert(!is_vector!quat);
    
    assert(is_matrix!mat2);
    assert(is_matrix!mat34);
    assert(is_matrix!mat4);
    assert(!is_matrix!float);
    assert(!is_matrix!vec3);
    assert(!is_matrix!quat);
    
    assert(is_quaternion!quat);
    assert(!is_quaternion!vec2);
    assert(!is_quaternion!vec4i);
    assert(!is_quaternion!mat2);
    assert(!is_quaternion!mat34);
    assert(!is_quaternion!float);
}