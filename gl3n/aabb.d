module gl3n.aabb;

private {
    import gl3n.linalg : Vector;
    import gl3n.math : almost_equal;
    import gl3n.util : TupleRange;

    static import std.compiler;
}


/// Base template for all AABB-types.
/// Params:
/// type = all values get stored as this type
struct AABBT(type, uint dimension_ = 3) {
    alias type at; /// Holds the internal type of the AABB.
    alias Vector!(at, dimension_) vec; /// Convenience alias to the corresponding vector type.
    alias dimension = dimension_;
    static assert(dimension > 0, "0 dimensional AABB don't exist.");

    vec min = vec(cast(at)0.0); /// The minimum of the AABB (e.g. vec(0, 0, 0)).
    vec max = vec(cast(at)0.0); /// The maximum of the AABB (e.g. vec(1, 1, 1)).

    @safe pure nothrow:

    /// Constructs the AABB.
    /// Params:
    /// min = minimum of the AABB
    /// max = maximum of the AABB
    this(vec min, vec max) {
        this.min = min;
        this.max = max;
    }

    /// Constructs the AABB around N points (all points will be part of the AABB).
    static AABBT from_points(vec[] points) {
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

    // Convenience function to get a dimension sized vector for unittests
    version(unittest)
    private static vec sizedVec(T)(T[] values){
        at[] ret;
        foreach(i; 0..dimension)
            ret ~= cast(at)values[i];
        return vec(ret);
    }

    unittest {
        alias AABB = AABBT!(at, dimension);

        AABB a = AABB(sizedVec([0.0, 1.0, 2.0, 3.0]), sizedVec([1.0, 2.0, 3.0, 4.0]));
        assert(a.min == sizedVec([0.0, 1.0, 2.0, 3.0]));
        assert(a.max == sizedVec([1.0, 2.0, 3.0, 4.0]));

        a = AABB.from_points([
            sizedVec([1.0, 0.0, 1.0, 5.0]),
            sizedVec([0.0, 2.0, 3.0, 3.0]),
            sizedVec([1.0, 0.0, 4.0, 4.0])]);
        assert(a.min == sizedVec([0.0, 0.0, 1.0, 3.0]));
        assert(a.max == sizedVec([1.0, 2.0, 4.0, 5.0]));

        a = AABB.from_points([sizedVec([1.0, 1.0, 1.0, 1.0]), sizedVec([2.0, 2.0, 2.0, 2.0])]);
        assert(a.min == sizedVec([1.0, 1.0, 1.0, 1.0]));
        assert(a.max == sizedVec([2.0, 2.0, 2.0, 2.0]));
    }

    /// Expands the AABB by another AABB.
    void expand(AABBT b) {
        foreach(i; TupleRange!(0, dimension)) {
            if(min.vector[i] > b.min.vector[i]) min.vector[i] = b.min.vector[i];
            if(max.vector[i] < b.max.vector[i]) max.vector[i] = b.max.vector[i];
        }
    }

    /// Expands the AABB, so that $(I v) is part of the AABB.
    void expand(vec v) {
        foreach(i; TupleRange!(0, dimension)) {
            if(min.vector[i] > v.vector[i]) min.vector[i] = v.vector[i];
            if(max.vector[i] < v.vector[i]) max.vector[i] = v.vector[i];
        }
    }

    unittest {
        alias AABB = AABBT!(at, dimension);

        AABB a = AABB(sizedVec([1.0, 1.0, 1.0, 1.0]), sizedVec([2.0, 4.0, 2.0, 4.0]));
        AABB b = AABB(sizedVec([2.0, 1.0, 2.0, 1.0]), sizedVec([3.0, 3.0, 3.0, 3.0]));

        AABB c;
        c.expand(a);
        c.expand(b);
        assert(c.min == sizedVec([0.0, 0.0, 0.0, 0.0]));
        assert(c.max == sizedVec([3.0, 4.0, 3.0, 4.0]));

        c.expand(sizedVec([12.0, 2.0, 0.0, 1.0]));
        assert(c.min == sizedVec([0.0,  0.0, 0.0, 0.0]));
        assert(c.max == sizedVec([12.0, 4.0,  3.0, 4.0]));
    }

    /// Returns true if the AABBs intersect.
    /// This also returns true if one AABB lies inside another.
    bool intersects(AABBT box) const {
        foreach(i; TupleRange!(0, dimension)) {
            if(min.vector[i] >= box.max.vector[i] || max.vector[i] <= box.min.vector[i])
                return false;
        }
        return true;
    }

    unittest {
        alias AABB = AABBT!(at, dimension);

        assert(AABB(sizedVec([0.0, 0.0, 0.0, 0.0]), sizedVec([1.0, 1.0, 1.0, 1.0])).intersects(
               AABB(sizedVec([0.5, 0.5, 0.5, 0.5]), sizedVec([3.0, 3.0, 3.0, 3.0]))));

        assert(AABB(sizedVec([0.0, 0.0, 0.0, 0.0]), sizedVec([1.0, 1.0, 1.0, 1.0])).intersects(
               AABB(sizedVec([0.5, 0.5, 0.5, 0.5]), sizedVec([1.7, 1.7, 1.7, 1.7]))));

        assert(!AABB(sizedVec([0.0, 0.0, 0.0, 0.0]), sizedVec([1.0, 1.0, 1.0, 1.0])).intersects(
                AABB(sizedVec([2.5, 2.5, 2.5, 2.5]), sizedVec([3.0, 3.0, 3.0, 3.0]))));
    }

    /// Returns the extent of the AABB (also sometimes called size).
    @property vec extent() const {
        return max - min;
    }

    /// Returns the half extent.
    @property vec half_extent() const {
        return (max - min) / 2;
    }

    unittest {
        alias AABB = AABBT!(at, dimension);

        AABB a = AABB(sizedVec([0.0, 0.0, 0.0, 0.0]), sizedVec([10.0, 10.0, 10.0, 10.0]));
        assert(a.extent == sizedVec([10.0, 10.0, 10.0, 10.0]));
        assert(a.half_extent == a.extent / 2);

        AABB b = AABB(sizedVec([2.0, 2.0, 2.0, 2.0]), sizedVec([10.0, 10.0, 10.0, 10.0]));
        assert(b.extent == sizedVec([8.0, 8.0, 8.0, 8.0]));
        assert(b.half_extent == b.extent / 2);
    }

    /// Returns the area of the AABB.
    static if(dimension <= 3) {
        @property real area() const {
            vec e = extent;

            static if(dimension == 1) {
                return 0;
            } else static if(dimension == 2) {
                return e.x * e.y;
            } else static if(dimension == 3) {
                return 2.0 * (e.x * e.y + e.x * e.z + e.y * e.z);
            } else {
                static assert(dimension <= 3, "area() not supported for aabb of dimension > 3");
            }
        }

        unittest {
            alias AABB = AABBT!(at, dimension);
            AABB a = AABB(sizedVec([0.0, 0.0, 0.0, 0.0]), sizedVec([1.0, 1.0, 1.0, 1.0]));
            switch (dimension) {
                case 1: assert(a.area == 0); break;
                case 2: assert(a.area == 1); break;
                case 3: assert(a.area == 6); break;
                default: assert(0);
            }


            AABB b = AABB(sizedVec([2.0, 2.0, 2.0, 2.0]), sizedVec([10.0, 10.0, 10.0, 10.0]));
            switch (dimension) {
                case 1: assert(b.area == 0); break;
                case 2: assert(b.area == 64); break;
                case 3: assert(b.area == 384); break;
                default: assert(0);
            }

            AABB c = AABB(sizedVec([2.0, 4.0, 6.0, 6.0]), sizedVec([10.0, 10.0, 10.0, 10.0]));
            switch (dimension) {
                case 1: assert(c.area == 0); break;
                case 2: assert(almost_equal(c.area, 48.0)); break;
                case 3: assert(almost_equal(c.area, 208.0)); break;
                default: assert(0);
            }
        }

    }

    /// Returns the center of the AABB.
    @property vec center() const {
        return (max + min) / 2;
    }

    unittest {
        alias AABB = AABBT!(at, dimension);

        AABB a = AABB(sizedVec([4.0, 4.0, 4.0, 4.0]), sizedVec([10.0, 10.0, 10.0, 10.0]));
        assert(a.center == sizedVec([7.0, 7.0, 7.0, 7.0]));
    }

    /// Returns all vertices of the AABB, basically one vec per corner.
    @property vec[] vertices() const {
        vec[] res;
        res.length = 2 ^^ dimension;
        foreach(i; TupleRange!(0, 2^^dimension)) {
            foreach(dim ; TupleRange!(0, dimension)) {
                res[i].vector[dim] = (i & (1 << dim)) ? max.vector[dim] : min.vector[dim];
            }
        }
        return res;
    }

    static if(std.compiler.version_major > 2 || std.compiler.version_minor >= 69) unittest {
        import std.algorithm.comparison : isPermutation;
        alias AABB = AABBT!(at, dimension);

        AABB a = AABB(sizedVec([1.0, 1.0, 1.0, 1.0]), sizedVec([2.0, 2.0, 2.0, 2.0]));
        switch (dimension) {
            case 1: assert(isPermutation(a.vertices, [
                    sizedVec([1.0]),
                    sizedVec([2.0]),
                ]));
                break;
            case 2: assert(isPermutation(a.vertices, [
                    sizedVec([1.0, 1.0]),
                    sizedVec([1.0, 2.0]),
                    sizedVec([2.0, 1.0]),
                    sizedVec([2.0, 2.0]),
                ]));
                break;
            case 3: assert(isPermutation(a.vertices, [
                    sizedVec([1.0, 1.0, 1.0]),
                    sizedVec([1.0, 2.0, 1.0]),
                    sizedVec([2.0, 1.0, 1.0]),
                    sizedVec([2.0, 2.0, 1.0]),
                    sizedVec([1.0, 1.0, 2.0]),
                    sizedVec([1.0, 2.0, 2.0]),
                    sizedVec([2.0, 1.0, 2.0]),
                    sizedVec([2.0, 2.0, 2.0]),
                ]));
                break;
            case 4: assert(isPermutation(a.vertices, [
                    sizedVec([1.0, 1.0, 1.0, 1.0]),
                    sizedVec([1.0, 2.0, 1.0, 1.0]),
                    sizedVec([2.0, 1.0, 1.0, 1.0]),
                    sizedVec([2.0, 2.0, 1.0, 1.0]),
                    sizedVec([1.0, 1.0, 2.0, 1.0]),
                    sizedVec([1.0, 2.0, 2.0, 1.0]),
                    sizedVec([2.0, 1.0, 2.0, 1.0]),
                    sizedVec([2.0, 2.0, 2.0, 1.0]),
                    sizedVec([1.0, 1.0, 1.0, 2.0]),
                    sizedVec([1.0, 2.0, 1.0, 2.0]),
                    sizedVec([2.0, 1.0, 1.0, 2.0]),
                    sizedVec([2.0, 2.0, 1.0, 2.0]),
                    sizedVec([1.0, 1.0, 2.0, 2.0]),
                    sizedVec([1.0, 2.0, 2.0, 2.0]),
                    sizedVec([2.0, 1.0, 2.0, 2.0]),
                    sizedVec([2.0, 2.0, 2.0, 2.0]),
                ]));
                break;
            default: assert(0);
        }
    }

    bool opEquals(AABBT other) const {
        return other.min == min && other.max == max;
    }

    unittest {
        alias AABB = AABBT!(at, dimension);
        assert(AABB(sizedVec([1.0, 12.0, 14.0, 16.0]), sizedVec([33.0, 222.0, 342.0, 1231.0])) ==
               AABB(sizedVec([1.0, 12.0, 14.0, 16.0]), sizedVec([33.0, 222.0, 342.0, 1231.0])));
    }
}

alias AABBT!(float, 3) AABB3;
alias AABBT!(float, 2) AABB2;

alias AABB3 AABB;


unittest {
    import gl3n.util : TypeTuple;
    alias TypeTuple!(ubyte, byte, short, ushort, int, uint, float, double) Types;
    foreach(type; Types)
    {
        foreach(dim; TupleRange!(1, 5))
        {
            {
                alias AABBT!(type,dim) aabbTestType;
                auto instance = AABBT!(type,dim)();
            }
        }
    }
}
