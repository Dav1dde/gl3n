/**
gl3n.util

Authors: David Herberth
License: MIT
*/

module gl3n.util;

private {
    import gl3n.linalg : Vector, Matrix, Quaternion;
}

private void is_vector_impl(T, int d)(Vector!(T, d) vec) {}

/// If T is a vector, this evaluates to true, otherwise false.
template is_vector(T) {
    enum is_vector = is(typeof(is_vector_impl(T.init)));
}

private void is_matrix_impl(T, int r, int c)(Matrix!(T, r, c) mat) {}

/// If T is a matrix, this evaluates to true, otherwise false.
template is_matrix(T) {
    enum is_matrix = is(typeof(is_matrix_impl(T.init)));
}

private void is_quaternion_impl(T)(Quaternion!(T) qu) {}

/// If T is a quaternion, this evaluates to true, otherwise false.
template is_quaternion(T) {
    enum is_quaternion = is(typeof(is_quaternion_impl(T.init)));
}

unittest {
    // I need to import it here like this, otherwise you'll get a compiler
    // or a linker error depending where gl3n.util gets imported
    import gl3n.linalg;
    
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