module gl3n.ext.hsv;

private {
    import std.conv : to;
    
    import gl3n.linalg : vec3, vec4;
    import gl3n.math : min, max, floor;

    version(unittest) {
        import gl3n.math : almost_equal;
    }
}

/// Converts a 3 dimensional color-vector from the RGB to the HSV colorspace.
/// The function assumes that each component is in the range [0, 1].
@safe pure nothrow vec3 rgb2hsv(vec3 inp) {
    vec3 ret = vec3(0.0f, 0.0f, 0.0f);
    
    float h_max = max(inp.r, inp.g, inp.b);
    float h_min = min(inp.r, inp.g, inp.b);
    float delta = h_max - h_min;

   
    // h
    if(delta == 0.0f) {
        ret.x = 0.0f;
    } else if(inp.r == h_max) {
        ret.x = (inp.g - inp.b) / delta; // h
    } else if(inp.g == h_max) {
        ret.x = 2 + (inp.b - inp.r) / delta; // h
    } else {
        ret.x = 4 + (inp.r - inp.g) / delta; // h
    }

    ret.x = ret.x * 60;
    if(ret.x < 0) {
        ret.x = ret.x + 360;
    }

    // s
    if(h_max == 0.0f) {
        ret.y = 0.0f;
    } else {
        ret.y = delta / h_max;
    }

    // v
    ret.z = h_max;

    return ret;
}

/// Converts a 4 dimensional color-vector from the RGB to the HSV colorspace.
/// The alpha value is not touched. This function also assumes that each component is in the range [0, 1].
@safe pure nothrow vec4 rgb2hsv(vec4 inp) {
    return vec4(rgb2hsv(vec3(inp.rgb)), inp.a);
}

unittest {
    assert(rgb2hsv(vec3(0.0f, 0.0f, 0.0f)) == vec3(0.0f, 0.0f, 0.0f));
    assert(rgb2hsv(vec3(1.0f, 1.0f, 1.0f)) == vec3(0.0f, 0.0f, 1.0f));

    vec3 hsv = rgb2hsv(vec3(100.0f/255.0f, 100.0f/255.0f, 100.0f/255.0f));    
    assert(hsv.x == 0.0f && hsv.y == 0.0f && almost_equal(hsv.z, 0.392157, 0.000001));
    
    assert(rgb2hsv(vec3(0.0f, 0.0f, 1.0f)) == vec3(240.0f, 1.0f, 1.0f));
}

/// Converts a 3 dimensional color-vector from the HSV to the RGB colorspace.
/// RGB colors will be in the range [0, 1].
/// This function is not marked es pure, since it depends on std.math.floor, which
/// is also not pure.
@safe nothrow vec3 hsv2rgb(vec3 inp) {
    if(inp.y == 0.0f) { // s
        return vec3(inp.zzz); // v
    } else {
        float var_h = inp.x * 6;
        float var_i = to!float(floor(var_h));
        float var_1 = inp.z * (1 - inp.y);
        float var_2 = inp.z * (1 - inp.y * (var_h - var_i));
        float var_3 = inp.z * (1 - inp.y * (1 - (var_h - var_i)));

        if(var_i == 0.0f)      return vec3(inp.z, var_3, var_1);
        else if(var_i == 1.0f) return vec3(var_2, inp.z, var_1);
        else if(var_i == 2.0f) return vec3(var_1, inp.z, var_3);
        else if(var_i == 3.0f) return vec3(var_1, var_2, inp.z);
        else if(var_i == 4.0f) return vec3(var_3, var_1, inp.z);
        else                   return vec3(inp.z, var_1, var_2);
    }
}

/// Converts a 4 dimensional color-vector from the HSV to the RGB colorspace.
/// The alpha value is not touched and the resulting RGB colors will be in the range [0, 1].
@safe nothrow vec4 hsv2rgb(vec4 inp) {
    return vec4(hsv2rgb(vec3(inp.xyz)), inp.w);
}

unittest {
    assert(hsv2rgb(vec3(0.0f, 0.0f, 0.0f)) == vec3(0.0f, 0.0f, 0.0f));
    assert(hsv2rgb(vec3(0.0f, 0.0f, 1.0f)) == vec3(1.0f, 1.0f, 1.0f));

    vec3 rgb = hsv2rgb(vec3(0.0f, 0.0f, 0.392157f));
    assert(rgb == vec3(0.392157f, 0.392157f, 0.392157f));

    assert(hsv2rgb(vec3(300.0f, 1.0f, 1.0f)) == vec3(1.0f, 0.0f, 1.0f));
}