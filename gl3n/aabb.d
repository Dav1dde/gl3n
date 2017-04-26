module gl3n.aabb;

private {
    import gl3n.linalg : Vector, vec3;
    import gl3n.math : almost_equal;
}


/// Base template for all AABB-types.
/// Params:
/// type = all values get stored as this type
struct AABBT(type) {
    alias type at; /// Holds the internal type of the AABB.
    alias Vector!(at, 3) vec3; /// Convenience alias to the corresponding vector type.

    vec3 min = vec3(cast(at)0.0, cast(at)0.0, cast(at)0.0); /// The minimum of the AABB (e.g. vec3(0, 0, 0)).
    vec3 max = vec3(cast(at)0.0, cast(at)0.0, cast(at)0.0); /// The maximum of the AABB (e.g. vec3(1, 1, 1)).

    @safe pure nothrow:

    /// Constructs the AABB.
    /// Params:
    /// min = minimum of the AABB
    /// max = maximum of the AABB
    this(vec3 min, vec3 max) {
        this.min = min;
        this.max = max;
    }

    /// Constructs the AABB around N points (all points will be part of the AABB).
    static AABBT from_points(vec3[] points) {
        AABBT res;

        if(points.length == 0) {
            return res;
        }

        res.min = points[0];
        res.max = points[0];
        foreach(v; points[1..$]) {
            res.expand(v);
        }
        
        return res;
    }

    unittest {
        AABBT!at a = AABBT!at(vec3(cast(at)0.0, cast(at)1.0, cast(at)2.0), vec3(cast(at)1.0, cast(at)2.0, cast(at)3.0));
        assert(a.min == vec3(cast(at)0.0, cast(at)1.0, cast(at)2.0));
        assert(a.max == vec3(cast(at)1.0, cast(at)2.0, cast(at)3.0));

        a = AABBT!at.from_points([vec3(cast(at)1.0, cast(at)0.0, cast(at)1.0), vec3(cast(at)0.0, cast(at)2.0, cast(at)3.0), vec3(cast(at)1.0, cast(at)0.0, cast(at)4.0)]);
        assert(a.min == vec3(cast(at)0.0, cast(at)0.0, cast(at)1.0));
        assert(a.max == vec3(cast(at)1.0,  cast(at)2.0, cast(at)4.0));
        
        a = AABBT!at.from_points([vec3(cast(at)1.0, cast(at)1.0, cast(at)1.0), vec3(cast(at)2.0, cast(at)2.0, cast(at)2.0)]);
        assert(a.min == vec3(cast(at)1.0, cast(at)1.0, cast(at)1.0));
        assert(a.max == vec3(cast(at)2.0, cast(at)2.0, cast(at)2.0));
    }

    /// Expands the AABB by another AABB. 
    void expand(AABBT b) {
        if (min.x > b.min.x) min.x = b.min.x;
        if (min.y > b.min.y) min.y = b.min.y;
        if (min.z > b.min.z) min.z = b.min.z;
        if (max.x < b.max.x) max.x = b.max.x;
        if (max.y < b.max.y) max.y = b.max.y;
        if (max.z < b.max.z) max.z = b.max.z;
    }

    /// Expands the AABB, so that $(I v) is part of the AABB.
    void expand(vec3 v) {
        if (v.x > max.x) max.x = v.x;
        if (v.y > max.y) max.y = v.y;
        if (v.z > max.z) max.z = v.z;
        if (v.x < min.x) min.x = v.x;
        if (v.y < min.y) min.y = v.y;
        if (v.z < min.z) min.z = v.z;
    }

    unittest {
        alias AABBT!at AABB;
        AABB a = AABB(vec3(cast(at)1.0, cast(at)1.0, cast(at)1.0), vec3(cast(at)2.0, cast(at)4.0, cast(at)2.0));
        AABB b = AABB(vec3(cast(at)2.0, cast(at)1.0, cast(at)2.0), vec3(cast(at)3.0, cast(at)3.0, cast(at)3.0));

        AABB c;
        c.expand(a);
        c.expand(b);
        assert(c.min == vec3(cast(at)0.0, cast(at)0.0, cast(at)0.0));
        assert(c.max == vec3(cast(at)3.0, cast(at)4.0, cast(at)3.0));

        c.expand(vec3(cast(at)12.0, cast(at)2.0, cast(at)0.0));
        assert(c.min == vec3(cast(at)0.0,  cast(at)0.0, cast(at)0.0));
        assert(c.max == vec3(cast(at)12.0, cast(at)4.0,  cast(at)3.0));
    }

    /// Returns true if the AABBs intersect.
    /// This also returns true if one AABB lies inside another.
    bool intersects(AABBT box) const {
        return (min.x < box.max.x && max.x > box.min.x) &&
               (min.y < box.max.y && max.y > box.min.y) &&
               (min.z < box.max.z && max.z > box.min.z);
    }

    unittest {
        alias AABBT!at AABB;
        assert(AABB(vec3(cast(at)0.0, cast(at)0.0, cast(at)0.0), vec3(cast(at)1.0, cast(at)1.0, cast(at)1.0)).intersects(
               AABB(vec3(cast(at)0.5, cast(at)0.5, cast(at)0.5), vec3(cast(at)3.0, cast(at)3.0, cast(at)3.0))));

        assert(AABB(vec3(cast(at)0.0, cast(at)0.0, cast(at)0.0), vec3(cast(at)1.0, cast(at)1.0, cast(at)1.0)).intersects(
               AABB(vec3(cast(at)0.5, cast(at)0.5, cast(at)0.5), vec3(cast(at)1.7, cast(at)1.7, cast(at)1.7))));

        assert(!AABB(vec3(cast(at)0.0, cast(at)0.0, cast(at)0.0), vec3(cast(at)1.0, cast(at)1.0, cast(at)1.0)).intersects(
                AABB(vec3(cast(at)2.5, cast(at)2.5, cast(at)2.5), vec3(cast(at)3.0, cast(at)3.0, cast(at)3.0))));
    }

    /// Returns the extent of the AABB (also sometimes called size).
    @property vec3 extent() const {
        return max - min;
    }

    /// Returns the half extent.
    @property vec3 half_extent() const {
        return (max - min) / 2;
    }

    unittest {
        alias AABBT!at AABB;
        AABBT!at a = AABBT!at(vec3(cast(at)0.0, cast(at)0.0, cast(at)0.0), vec3(cast(at)10.0, cast(at)10.0, cast(at)10.0));
        assert(a.extent == vec3(cast(at)10.0, cast(at)10.0, cast(at)10.0));
        assert(a.half_extent == a.extent / 2);

        AABBT!at b = AABBT!at(vec3(cast(at)2.0, cast(at)2.0, cast(at)2.0), vec3(cast(at)10.0, cast(at)10.0, cast(at)10.0));
        assert(b.extent == vec3(cast(at)8.0, cast(at)8.0, cast(at)8.0));
        assert(b.half_extent == b.extent / 2);
        
    }

    /// Returns the area of the AABB.
    @property real area() const {
        vec3 e = extent;
        return 2.0 * (e.x * e.y + e.x * e.z + e.y * e.z);
    }

    unittest {
        alias AABBT!at AABB;
        AABB a = AABB(vec3(cast(at)0.0, cast(at)0.0, cast(at)0.0), vec3(cast(at)1.0, cast(at)1.0, cast(at)1.0));
        assert(a.area == 6);

        AABB b = AABB(vec3(cast(at)2.0, cast(at)2.0, cast(at)2.0), vec3(cast(at)10.0, cast(at)10.0, cast(at)10.0));
        assert(almost_equal(b.area, 384));

        AABB c = AABB(vec3(cast(at)2.0, cast(at)4.0, cast(at)6.0), vec3(cast(at)10.0, cast(at)10.0, cast(at)10.0));
        assert(almost_equal(c.area, 208.0));
    }

    /// Returns the center of the AABB.
    @property vec3 center() const {
        return (max + min) / 2;
    }

    unittest {
        alias AABBT!at AABB;
        AABB a = AABB(vec3(cast(at)4.0, cast(at)4.0, cast(at)4.0), vec3(cast(at)10.0, cast(at)10.0, cast(at)10.0));
        assert(a.center == vec3(cast(at)7.0, cast(at)7.0, cast(at)7.0));
    }

    /// Returns all vertices of the AABB, basically one vec3 per corner.
    @property vec3[] vertices() const {
        return [
            vec3(min.x, min.y, min.z),
            vec3(min.x, min.y, max.z),
            vec3(min.x, max.y, min.z),
            vec3(min.x, max.y, max.z),
            vec3(max.x, min.y, min.z),
            vec3(max.x, min.y, max.z),
            vec3(max.x, max.y, min.z),
            vec3(max.x, max.y, max.z),
        ];
    }

    bool opEquals(AABBT other) const {
        return other.min == min && other.max == max;
    }

    unittest {
        alias AABBT!at AABB;
        assert(AABB(vec3(cast(at)1.0, cast(at)12.0, cast(at)14.0), vec3(cast(at)33.0, cast(at)222.0, cast(at)342.0)) ==
               AABB(vec3(cast(at)1.0, cast(at)12.0, cast(at)14.0), vec3(cast(at)33.0, cast(at)222.0, cast(at)342.0)));
    }
}

alias AABBT!(float) AABB;


unittest {
    import std.typetuple;
    alias TypeTuple!(ubyte, byte, short, ushort, int, uint, float, double) Types;
    foreach(type ; Types)
    {
        alias AABBT!type aabbTestType;
        auto instance = aabbTestType();
    }
}
