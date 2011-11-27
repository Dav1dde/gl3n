/**
Authors: David Herberth
*/


module gl3n.interpolate;

private {
    import gl3n.linalg : Vector;
    import gl3n.util : is_vector, is_quaternion;
    import gl3n.math : almost_equal, acos, sin, sqrt, clamp, PI;
    import std.conv : to;
    
    version(unittest) {
        import gl3n.linalg : vec2, vec3, vec4, quat;
    }
}



T interp(T)(T x, T y, float t) /*if(!is_vector!T) */{
    return x * (1 - t) + y * t;
}
alias interp interp_linear;
alias interp lerp;
alias interp mix;


T interp_spherical(T)(T x, T y, float t) if(is_vector!T) {
    real angle = acos(T.dot(x, y));
    
    if(almost_equal(angle, 0)) {
        return x;
    } else if(almost_equal(angle, PI)) { // 180°?
        return interp(x, y, t);
    } else { // slerp
        return (sin((1.0-t)*angle)/sin(angle))*x + (sin(t*angle)/sin(angle))*y;
    }
}

T interp_spherical(T)(T q1, T q2, float t) if(is_quaternion!T) {
    // see: http://www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/slerp/
    T ret;

    real costheta = q1.w * q2.w + q1.x * q2.x + q1.y * q2.y + q1.z * q2.z;
    
    if(costheta < 0) {
        q1.w = -q1.w;
        q1.x = -q1.x;
        q1.y = -q1.y;
        q1.z = -q1.z;
        costheta = -costheta;
    }
    
    costheta = clamp(costheta, -1, 1);

    real theta = acos(costheta);
    real sintheta = sqrt(1.0 - costheta * costheta);
    if(almost_equal(theta, 0)) { // if q1 = q2 or q1 = -q2 then theta = 0 => return one of the quats
        ret.w = q2.w;
        ret.x = q2.x;
        ret.y = q2.y;
        ret.z = q2.z;
    } else if(almost_equal(sintheta, 0)) { // theta = 180°? if so => undefined result, handle this
        ret = (q1 + q2) * 0.5f;
    } else { // slerp
        T.qt ratio1 = to!(T.qt)(sin((1 - t) * theta) / sintheta);
        T.qt ratio2 = to!(T.qt)(sin(t * theta) / sintheta);

        ret.w = q1.w * ratio1 + q2.w * ratio2;
        ret.x = q1.x * ratio1 + q2.x * ratio2;
        ret.y = q1.y * ratio1 + q2.y * ratio2;
        ret.z = q1.z * ratio1 + q2.z * ratio2;
    }
    
    return ret; 
}

alias interp_spherical slerp; 


unittest {
    vec2 v2_1 = vec2(1.0f);
    vec2 v2_2 = vec2(0.0f);
    vec3 v3_1 = vec3(1.0f);
    vec3 v3_2 = vec3(0.0f);
    vec4 v4_1 = vec4(1.0f);
    vec4 v4_2 = vec4(0.0f);
    
    assert(interp(v2_1, v2_2, 0.5f).vector == [0.5f, 0.5f]);
    assert(interp(v2_1, v2_2, 0.0f) == v2_1);
    assert(interp(v2_1, v2_2, 1.0f) == v2_2);
    assert(interp(v3_1, v3_2, 0.5f).vector == [0.5f, 0.5f, 0.5f]);
    assert(interp(v3_1, v3_2, 0.0f) == v3_1);
    assert(interp(v3_1, v3_2, 1.0f) == v3_2);
    assert(interp(v4_1, v4_2, 0.5f).vector == [0.5f, 0.5f, 0.5f, 0.5f]);
    assert(interp(v4_1, v4_2, 0.0f) == v4_1);
    assert(interp(v4_1, v4_2, 1.0f) == v4_2);

    real r1 = 0.0;
    real r2 = 1.0;
    assert(interp(r1, r2, 0.5f) == 0.5);
    assert(interp(r1, r2, 0.0f) == r1);
    assert(interp(r1, r2, 1.0f) == r2);
    
    assert(interp(0.0, 1.0, 0.5f) == 0.5);
    assert(interp(0.0, 1.0, 0.0f) == 0.0);
    assert(interp(0.0, 1.0, 1.0f) == 1.0);
    
    assert(interp(0.0f, 1.0f, 0.5f) == 0.5f);
    assert(interp(0.0f, 1.0f, 0.0f) == 0.0f);
    assert(interp(0.0f, 1.0f, 1.0f) == 1.0f);
    
    quat q1 = quat(1.0f, 1.0f, 1.0f, 1.0f);
    quat q2 = quat(0.0f, 0.0f, 0.0f, 0.0f);
    
    assert(interp(q1, q2, 0.0f).quaternion == q1.quaternion);
    assert(interp(q1, q2, 0.5f).quaternion == [0.5f, 0.5f, 0.5f, 0.5f]);
    assert(interp(q1, q2, 1.0f).quaternion == q2.quaternion);
    
    assert(interp_spherical(v2_1, v2_2, 0.0).vector == v2_1.vector);
    assert(interp_spherical(v2_1, v2_2, 1.0).vector == v2_2.vector);
    assert(interp_spherical(v3_1, v3_2, 0.0).vector == v3_1.vector);
    assert(interp_spherical(v3_1, v3_2, 1.0).vector == v3_2.vector);
    assert(interp_spherical(v4_1, v4_2, 0.0).vector == v4_1.vector);
    assert(interp_spherical(v4_1, v4_2, 1.0).vector == v4_2.vector);
    
    assert(interp_spherical(q1, q2, 0.0f).quaternion == q1.quaternion);
    assert(interp_spherical(q1, q2, 1.0f).quaternion == q2.quaternion);
}

T interp_nearest(T)(T x, T y, float t) {
    if(t < 0.5f) { return x; }
    else { return y; } 
}

unittest {
    assert(interp_nearest(0.0, 1.0, 0.5f) == 1.0);
    assert(interp_nearest(0.0, 1.0, 0.4f) == 0.0);
    assert(interp_nearest(0.0, 1.0, 0.6f) == 1.0);
}

T interp_catmullrom(T)(T p0, T p1, T p2, T p3, float t) {
    return 0.5f * ((2 * p1) + 
                   (-p0 + p2) * t +
                   (2 * p0 - 5 * p1 + 4 * p2 - p3) * t^^2 +
                   (-p0 + 3 * p1 - 3 * p2 + p3) * t^^3);
}

T catmullrom_derivative(T)(T p0, T p1, T p2, T p3, float t) {
    return 0.5f * ((2 * p1) +
                   (-p0 + p2) +
                   2 * (2 * p0 - 5 * p1 + 4 * p2 - p3) * t +
                   3 * (-p0 + 3 * p1 - 3 * p2 + p3) * t^^2);
}

T interp_hermite(T)(T x, T tx, T y, T ty, float t) {
    float h1 = 2 * t^^3 - 3 * t^^2 + 1;
    float h2 = -2* t^^3 + 3 * t^^2;
    float h3 = t^^3 - 2 * t^^2 + t;
    float h4 = t^^3 - t^^2;
    return h1 * x + h3 * tx + h2 * y + h4 * ty;
}