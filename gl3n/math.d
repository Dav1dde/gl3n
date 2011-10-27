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
    import std.math : PI;
    import std.conv : to;
}

public enum real PI_180 = PI / 180;
public enum real _180_PI = 180 / PI;


T radians(T)(T degrees) {
    return to!(T)(PI_180 * degrees);
}

T degrees(T)(T radians) {
    return to!(T)(_180_PI * radians);
}

T clamp(T)(T x, T min_val, T max_val) {
    return min(max(x, min_val), max_val);
}

float step(T)(T edge, T x) {
    return x < edge ? 0.0f:1.0f;
}

T smoothstep(T)(T edge0, T edge1, T x) {
    T t = clamp((x - edge0) / (edge1 - edge0), 0, 1);
    return t * t * (3 - 2 * t);
}