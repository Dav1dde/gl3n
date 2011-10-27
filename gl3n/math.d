/**
Authors: David Herberth
*/

module gl3n.math;

public {
    //import std.math : PI, floor, ceil, sin, cos, tan, atan, atan2,
    //                  pow, abs, exp, sqrt, cbrt;
    //import core.stdc.math : fmodf;
    import std.algorithm : min, max;
}

private {
    import std.math : PI, abs;
    import std.conv : to;
}

public enum real PI_180 = PI / 180;
public enum real _180_PI = 180 / PI;

bool almost_equal(T, S)(T a, S b, float epsilon = 0.000001f) if(is(T : S)) {
    if(abs(a-b) <= epsilon) {
        return true;
    }
    return abs(a-b) <= epsilon * abs(b);
}

unittest {
    assert(almost_equal(0, 0));
    assert(almost_equal(1, 1));
    assert(almost_equal(-1, -1));    
    assert(almost_equal(0f, 0.000001f, 0.000001f));
    assert(almost_equal(1f, 1.1f, 0.1f));
    assert(!almost_equal(1f, 1.1f, 0.01f));
}

T radians(T)(T degrees) {
    return to!(T)(PI_180 * degrees);
}

T degrees(T)(T radians) {
    return to!(T)(_180_PI * radians);
}

unittest {
    assert(radians(to!(real)(0)) == 0);
    assert(radians(to!(real)(90)) == PI/2);
    assert(radians(to!(real)(180)) == PI);
    assert(radians(to!(real)(360)) == 2*PI);
    
    assert(degrees(to!(real)(0)) == 0);
    assert(degrees(to!(real)(PI/2)) == 90);
    assert(degrees(to!(real)(PI)) == 180);
    assert(degrees(to!(real)(2*PI)) == 360);    

    assert(degrees(radians(to!(real)(12))) == 12);
    assert(degrees(radians(to!(real)(100))) == 100);
    assert(degrees(radians(to!(real)(213))) == 213);
    assert(degrees(radians(to!(real)(399))) == 399);
}

T clamp(T)(T x, T min_val, T max_val) {
    return min(max(x, min_val), max_val);
}

unittest {
    assert(clamp(-1, 0, 2) == 0);
    assert(clamp(0, 0, 2) == 0);
    assert(clamp(1, 0, 2) == 1);
    assert(clamp(2, 0, 2) == 2);
    assert(clamp(3, 0, 2) == 2);
}

float step(T)(T edge, T x) {
    return x < edge ? 0.0f:1.0f;
}

T smoothstep(T)(T edge0, T edge1, T x) {
    T t = clamp((x - edge0) / (edge1 - edge0), to!(T)(0), to!(T)(1));
    return t * t * (3 - 2 * t);
}

unittest {
    assert(step(0, 1) == 1.0f);
    assert(step(0, 10) == 1.0f);
    assert(step(1, 0) == 0.0f);
    assert(step(10, 0) == 0.0f);
    assert(step(1, 1) == 1.0f);
    
    assert(smoothstep(1, 0, 2) == 0);
    assert(smoothstep(1.0, 0.0, 2.0) == 0);
    assert(smoothstep(1.0, 0.0, 0.5) == 0.5);
    assert(almost_equal(smoothstep(0.0, 2.0, 0.5), 0.15625, 0.00001));
}