module gl3n.aabb;

private {
    import gl3n.linalg : Vector;
}


struct AABBT(type) {
    alias type at;
    alias Vector!(at, 3) vec3;

    vec3 min;
    vec3 max;

    @safe pure nothrow:

    this(vec3 min, vec3 max) {
        this.min = min;
        this.max = max;
    }

    static AABBT from_points(vec3[] points) {
        AABBT res;

        foreach(v; points) {
            res.expand(v);
        }

        return res;
    }

    void expand(AABBT b) {
        if (min.x > b.min.x) min.x = b.min.x;
        if (min.y > b.min.y) min.y = b.min.y;
        if (min.z > b.min.z) min.z = b.min.z;
        if (max.x < b.max.x) max.x = b.max.x;
        if (max.y < b.max.y) max.y = b.max.y;
        if (max.z < b.max.z) max.z = b.max.z;
    }

    void expand(vec3 v) {
        if (v.x > max.x) max.x = v.x;
        if (v.y > max.y) max.y = v.y;
        if (v.z > max.z) max.z = v.z;
        if (v.x < min.x) min.x = v.x;
        if (v.y < min.y) min.y = v.y;
        if (v.z < min.z) min.z = v.z;
    }

    bool intersect(AABBT box) const {
        return (min.x < box.max.x && max.x > box.min.x) &&
               (min.y < box.max.y && max.y > box.min.y) &&
               (min.z < box.max.z && max.z > box.min.z);
    }

    @property vec3 extent() const {
        return max - min;
    }

    @property vec3 half_extent() const {
        return 0.5 * (max - min);
    }

    @property at area() const {
        vec3 e = extent;
        return 2.0 * (e.x * e.y + e.x * e.z + e.y * e.z);
    }

    @property center() const {
        return (max + min) * 0.5;
    }

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
}

alias AABBT!(float) AABB;