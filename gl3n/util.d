module gl3n.util;

private {
    import gl3n.linalg : Vector;
}


private void is_vector_impl(T, int d)(Vector!(T, d) vec) {}

template is_vector(T) {
    enum is_vector = is(typeof(is_vector_impl(T.init)));
}