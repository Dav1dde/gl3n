module gl3n.plane;

private {
    import gl3n.linalg : Vector, dot, vec3;
    import gl3n.math : almost_equal;

    import std.traits : isFloatingPoint;
}


/// Base template for all plane-types.
/// Params:
/// type = all values get stored as this type (must be floating point)
struct PlaneT(type = float) if(isFloatingPoint!type) {
    alias type pt; /// Holds the internal type of the plane.
    alias Vector!(pt, 3) vec3; /// Convenience alias to the corresponding vector type.

    union {
        struct {
            pt a; /// normal.x
            pt b; /// normal.y
            pt c; /// normal.z
        }

        vec3 normal; /// Holds the planes normal.
    }

    pt d; /// Holds the planes "constant" (HNF).

    @safe pure nothrow:

    /// Constructs the plane, from either four scalars of type $(I pt)
    /// or from a 3-dimensional vector (= normal) and a scalar.
    this(pt a, pt b, pt c, pt d) {
        this.a = a;
        this.b = b;
        this.c = c;
        this.d = d;
    }

    /// ditto
    this(vec3 normal, pt d) {
        this.normal = normal;
        this.d = d;
    }

    unittest {
        Plane p = Plane(0.0f, 1.0f, 2.0f, 3.0f);
        assert(p.normal == vec3(0.0f, 1.0f, 2.0f));
        assert(p.d == 3.0f);

        p.normal.x = 4.0f;
        assert(p.normal == vec3(4.0f, 1.0f, 2.0f));
        assert(p.a == 4.0f);
        assert(p.b == 1.0f);
        assert(p.c == 2.0f);
        assert(p.d == 3.0f);
    }

    /// Normalizes the plane inplace.
    void normalize() {
        pt det = 1.0 / normal.length;
        normal *= det;
        d *= det;
    }

    /// Returns a normalized copy of the plane.
    @property PlaneT normalized() const {
        PlaneT ret = PlaneT(a, b, c, d);
        ret.normalize();
        return ret;
    }

    unittest {
        Plane p = Plane(0.0f, 1.0f, 2.0f, 3.0f);
        Plane pn = p.normalized();
        assert(pn.normal == vec3(0.0f, 1.0f, 2.0f).normalized);
        assert(almost_equal(pn.d, 3.0f/vec3(0.0f, 1.0f, 2.0f).length));
        p.normalize();
        assert(p == pn);
    }

    /// Returns the distance from a point to the plane.
    /// Note: the plane $(RED must) be normalized, the result can be negative.
    pt distance(vec3 point) const {
        return dot(point, normal) + d;
    }

    /// Returns the distance from a point to the plane.
    /// Note: the plane does not have to be normalized, the result can be negative.
    pt ndistance(vec3 point) const {
        return (dot(point, normal) + d) / normal.length;
    }

    unittest {
        Plane p = Plane(-1.0f, 4.0f, 19.0f, -10.0f);
        assert(almost_equal(p.ndistance(vec3(5.0f, -2.0f, 0.0f)), -1.182992));
        assert(almost_equal(p.ndistance(vec3(5.0f, -2.0f, 0.0f)),
                            p.normalized.distance(vec3(5.0f, -2.0f, 0.0f))));
    }

    bool opEquals(PlaneT other) const {
        return other.normal == normal && other.d == d;
    }

}

alias PlaneT!(float) Plane;