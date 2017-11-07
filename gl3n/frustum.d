/// Note: this module is not completly tested!
/// Use with special care, results might be wrong.

module gl3n.frustum;

private {
    import gl3n.linalg : vec3, mat4, dot;
    import gl3n.math : abs, cradians;
    import gl3n.aabb : AABB;
    import gl3n.plane : Plane;
}

enum {
    OUTSIDE = 0, /// Used as flag to indicate if the object intersects with the frustum.
    INSIDE, /// ditto
    INTERSECT /// ditto
}

///
struct Frustum {
    enum {
        LEFT, /// Used to access the planes array.
        RIGHT, /// ditto
        BOTTOM, /// ditto
        TOP, /// ditto
        NEAR, /// ditto
        FAR /// ditto
    }

    Plane[6] planes; /// Holds all 6 planes of the frustum.

    @safe pure nothrow:

    @property ref inout(Plane) left() inout { return planes[LEFT]; }
    @property ref inout(Plane) right() inout { return planes[RIGHT]; }
    @property ref inout(Plane) bottom() inout { return planes[BOTTOM]; }
    @property ref inout(Plane) top() inout { return planes[TOP]; }
    @property ref inout(Plane) near() inout { return planes[NEAR]; }
    @property ref inout(Plane) far() inout { return planes[FAR]; }

    /// Constructs the frustum from a model-view-projection matrix.
    /// Params:
    /// mvp = a model-view-projection matrix
    this(mat4 mvp) {
        mvp.transpose(); // we store the matrix row-major
        
        planes = [
            // left
            Plane(mvp[0][3] + mvp[0][0],
                  mvp[1][3] + mvp[1][0],
                  mvp[2][3] + mvp[2][0],
                  mvp[3][3] + mvp[3][0]),

            // right
            Plane(mvp[0][3] - mvp[0][0],
                  mvp[1][3] - mvp[1][0],
                  mvp[2][3] - mvp[2][0],
                  mvp[3][3] - mvp[3][0]),

            // bottom
            Plane(mvp[0][3] + mvp[0][1],
                  mvp[1][3] + mvp[1][1],
                  mvp[2][3] + mvp[2][1],
                  mvp[3][3] + mvp[3][1]),
            // top
            Plane(mvp[0][3] - mvp[0][1],
                  mvp[1][3] - mvp[1][1],
                  mvp[2][3] - mvp[2][1],
                  mvp[3][3] - mvp[3][1]),
            // near
            Plane(mvp[0][3] + mvp[0][2],
                  mvp[1][3] + mvp[1][2],
                  mvp[2][3] + mvp[2][2],
                  mvp[3][3] + mvp[3][2]),
            // far
            Plane(mvp[0][3] - mvp[0][2],
                  mvp[1][3] - mvp[1][2],
                  mvp[2][3] - mvp[2][2],
                  mvp[3][3] - mvp[3][2])
        ];

        normalize();
    }

    /// Constructs the frustum from 6 planes.
    /// Params:
    /// planes = the 6 frustum planes in the order: left, right, bottom, top, near, far.
    this(Plane[6] planes) {
        this.planes = planes;
        normalize();
    }

    private void normalize() {
        foreach(ref e; planes) {
            e.normalize();
        }
    }

    /// Checks if the $(I aabb) intersects with the frustum.
    /// Returns OUTSIDE (= 0), INSIDE (= 1) or INTERSECT (= 2).
    int intersects(AABB aabb) const {
        vec3 hextent = aabb.half_extent;
        vec3 center = aabb.center;

        int result = INSIDE;
        foreach(plane; planes) {
            float d = dot(center, plane.normal);
            float r = dot(hextent, abs(plane.normal));

            if(d + r < -plane.d) {
                // outside
                return OUTSIDE;
            }
            if(d - r < -plane.d) {
               result = INTERSECT;
            }
        }

        return result;
    }

    unittest {
        mat4 view = mat4.look_at(vec3(0), vec3(0, 0, 1), vec3(0, 1, 0));
        enum aspect = 4.0/3.0;
        enum fov = 60;
        enum near = 1;
        enum far = 100;
        mat4 proj = mat4.perspective(aspect, 1.0, fov, near, far);
        auto f = Frustum(proj * view);
        assert(f.intersects(AABB(vec3(0, 0, 1), vec3(0, 0, 1))) == INSIDE);
        assert(f.intersects(AABB(vec3(-1), vec3(1))) == INTERSECT);
        assert(f.intersects(AABB(vec3(-1), vec3(0.99))) == OUTSIDE);
        assert(f.intersects(AABB(vec3(-1000), vec3(1000))) == INTERSECT);
        assert(f.intersects(AABB(vec3(0, 0, -1000), vec3(1, 1, 1000))) == INTERSECT);
        assert(f.intersects(AABB(vec3(-1000, 0, 0), vec3(1000, 0.1, 0.1))) == OUTSIDE);
        for(int i = near; i < far; i += 10) {
            assert(f.intersects(AABB(vec3(0, 0,  i), vec3(0.1, 0.1,   i + 1))) == INSIDE);
            assert(f.intersects(AABB(vec3(0, 0, -i), vec3(0.1, 0.1, -(i + 1)))) == OUTSIDE);
        }
        import std.math : tan;
        float c = aspect * far / tan(cradians!fov);
        assert(f.intersects(AABB(vec3(c, 0, 99), vec3(c + 1, 1, 101))) == INTERSECT);
        assert(f.intersects(AABB(vec3(c - 4, 0, 98), vec3(c - 2, 1, 99.99))) == INSIDE);
        assert(f.intersects(AABB(vec3(c, 0, 100), vec3(c + 1, 0, 101))) == OUTSIDE);

        proj = mat4.orthographic(-aspect, aspect, -1.0, 1.0, 0, far);
        f = Frustum(proj * view);
        assert(f.intersects(AABB(vec3(0, 0, 1), vec3(0, 0, 1))) == INSIDE);
        assert(f.intersects(AABB(vec3(-1), vec3(1))) == INTERSECT);
        assert(f.intersects(AABB(vec3(-1), vec3(0.01))) == INTERSECT);
        assert(f.intersects(AABB(vec3(0, 0, far - 5), vec3(1, 1, far))) == INSIDE);
        assert(f.intersects(AABB(vec3(0, 0, far - 5), vec3(1, 1, far + 5))) == INTERSECT);
        assert(f.intersects(AABB(vec3(-1000, 0, -0.01), vec3(1000, 1, 0))) == INTERSECT);
        assert(f.intersects(AABB(vec3(-1000, 0, -0.02), vec3(1000, 1, -0.01))) == OUTSIDE);
    }

    /// Returns true if the $(I aabb) intersects with the frustum or is inside it.
    bool opBinaryRight(string s : "in")(AABB aabb) const {
        return intersects(aabb) > 0;
    }
}
