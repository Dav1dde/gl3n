module gl3n.plane;

private {
    import gl3n.linalg : Vector, dot;

    version(unittest) {
        import gl3n.linalg : vec3;
        import gl3n.math : almost_equal;
    }
}


struct PlaneT(T) {
    alias Vector!(T, 3) vec3;

    union {
        struct {
            T a;
            T b;
            T c;
        }

        vec3 normal;
    }

    T d;

    @safe pure nothrow:

    this(T a, T b, T c, T d) {
        this.a = a;
        this.b = b;
        this.c = c;
        this.d = d;
    }

    this(vec3 normal, T d) {
        this.normal = normal;
        this.d = d;
    }

    void normalize() {
        T det = 1.0 / normal.length;
        normal *= det;
        d *= det;
    }

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

    T distance(vec3 point) const {
        return dot(point, normal) + d;
    }

    T ndistance(vec3 point) const {
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