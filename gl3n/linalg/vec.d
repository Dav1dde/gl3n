/**
gl3n.linalg.vec

Special thanks to:
$(UL
  $(LI Tomasz Stachowiak (h3r3tic): allowed me to use parts of $(LINK2 https://bitbucket.org/h3r3tic/boxen/src/default/src/xf/omg, omg).)
  $(LI Jakob Øvrum (jA_cOp): improved the code a lot!)
  $(LI Florian Boesch (___doc__): helps me to understand opengl/complex maths better, see: $(LINK http://codeflow.org/).)
  $(LI #D on freenode: answered general questions about D.)
)

Authors: David Herberth, Stephan Dilly
License: MIT

Note: All methods marked with pure are weakly pure since, they all access an instance member.
All static methods are strongly pure.
*/

module gl3n.linalg.vec;

import gl3n.linalg.matrix;
import gl3n.util : is_vector, is_matrix, is_quaternion, TupleRange;
import gl3n.math : sqrt, max, almost_equal;

import std.math : isNaN, isInfinity;
import std.string : format;
import std.conv : to;
import std.traits : isArray, isDynamicArray, isStaticArray, isIntegral;

/// Base template for all vector-types.
/// Params:
/// type = all values get stored as this type
/// dimension = specifies the dimension of the vector, can be 1, 2, 3 or 4
/// Examples:
/// ---
/// alias Vector!(int, 3) vec3i;
/// alias Vector!(float, 4) vec4;
/// alias Vector!(real, 2) vec2r;
/// ---
struct Vector(type, int dimension_) {
    static assert(dimension > 0, "0 dimensional vectors don't exist.");
    
    alias type vt; /// Holds the internal type of the vector.
    static const int dimension = dimension_; ///Holds the dimension of the vector.
    
    vt[dimension] vector; /// Holds all coordinates, length conforms dimension.
    
    /// Returns a pointer to the coordinates.
    @property auto value_ptr() const { return vector.ptr; }
    
    /// Returns the current vector formatted as string, useful for printing the vector.
    @property string as_string() {
        return format("%s", vector);
    }
    alias as_string toString; /// ditto
    
    @safe pure nothrow:
    ///
    private @property ref inout(vt) get_(char coord)() inout {
        return vector[coord_to_index!coord];
    }
    
    alias get_!'x' x; /// static properties to access the values.
    alias x u; /// ditto
    alias x s; /// ditto
    alias x r; /// ditto
    static if(dimension >= 2) {
        alias get_!'y' y; /// ditto
        alias y v; /// ditto
        alias y t; /// ditto
        alias y g; /// ditto
    }
    static if(dimension >= 3) {
        alias get_!'z' z; /// ditto
        alias z b; /// ditto
        alias z p; /// ditto
    }
    static if(dimension >= 4) {
        alias get_!'w' w; /// ditto
        alias w a; /// ditto
        alias w q; /// ditto
    }
    
    static if(dimension == 2) {
        enum Vector e1 = Vector(1.to!vt, 0.to!vt); /// canonical basis for Euclidian space
        enum Vector e2 = Vector(0.to!vt, 1.to!vt); /// ditto
    } else static if(dimension == 3) {
        enum Vector e1 = Vector(1.to!vt, 0.to!vt, 0.to!vt); /// canonical basis for Euclidian space
        enum Vector e2 = Vector(0.to!vt, 1.to!vt, 0.to!vt); /// ditto
        enum Vector e3 = Vector(0.to!vt, 0.to!vt, 1.to!vt); /// ditto
    } else static if(dimension == 4) {
        enum Vector e1 = Vector(1.to!vt, 0.to!vt, 0.to!vt, 0.to!vt); /// canonical basis for Euclidian space
        enum Vector e2 = Vector(0.to!vt, 1.to!vt, 0.to!vt, 0.to!vt); /// ditto
        enum Vector e3 = Vector(0.to!vt, 0.to!vt, 1.to!vt, 0.to!vt); /// ditto
        enum Vector e4 = Vector(0.to!vt, 0.to!vt, 0.to!vt, 1.to!vt); /// ditto
    }
    
    unittest {
        assert(vec2.e1.vector == [1.0, 0.0]);
        assert(vec2.e2.vector == [0.0, 1.0]);
        
        assert(vec3.e1.vector == [1.0, 0.0, 0.0]);
        assert(vec3.e2.vector == [0.0, 1.0, 0.0]);
        assert(vec3.e3.vector == [0.0, 0.0, 1.0]);
        
        assert(vec4.e1.vector == [1.0, 0.0, 0.0, 0.0]);
        assert(vec4.e2.vector == [0.0, 1.0, 0.0, 0.0]);
        assert(vec4.e3.vector == [0.0, 0.0, 1.0, 0.0]);
        assert(vec4.e4.vector == [0.0, 0.0, 0.0, 1.0]);
    }
    
    static void isCompatibleVectorImpl(int d)(Vector!(vt, d) vec) if(d <= dimension) {
    }
    
    template isCompatibleVector(T) {
        enum isCompatibleVector = is(typeof(isCompatibleVectorImpl(T.init)));
    }
    
    static void isCompatibleMatrixImpl(int r, int c)(Matrix!(vt, r, c) m) {
    }
    
    template isCompatibleMatrix(T) {
        enum isCompatibleMatrix = is(typeof(isCompatibleMatrixImpl(T.init)));
    }
    
    private void construct(int i, T, Tail...)(T head, Tail tail) {
        static if(i >= dimension) {
            static assert(false, "Too many arguments passed to constructor");
        } else static if(is(T : vt)) {
            vector[i] = head;
            construct!(i + 1)(tail);
        } else static if(isDynamicArray!T) {
            static assert((Tail.length == 0) && (i == 0), "dynamic array can not be passed together with other arguments");
            vector[] = head[];
        } else static if(isStaticArray!T) {
            vector[i .. i + T.length] = head[];
            construct!(i + T.length)(tail);
        } else static if(isCompatibleVector!T) {
            vector[i .. i + T.dimension] = head.vector[];
            construct!(i + T.dimension)(tail);
        } else {
            static assert(false, "Vector constructor argument must be of type " ~ vt.stringof ~ " or Vector, not " ~ T.stringof);
        }
    }
    
    private void construct(int i)() { // terminate
        static assert(i == dimension, "Not enough arguments passed to constructor");
    }
    
    /// Constructs the vector.
    /// If a single value is passed the vector, the vector will be cleared with this value.
    /// If a vector with a higher dimension is passed the vector will hold the first values up to its dimension.
    /// If mixed types are passed they will be joined together (allowed types: vector, static array, $(I vt)).
    /// Examples:
    /// ---
    /// vec4 v4 = vec4(1.0f, vec2(2.0f, 3.0f), 4.0f);
    /// vec3 v3 = vec3(v4); // v3 = vec3(1.0f, 2.0f, 3.0f);
    /// vec2 v2 = v3.xy; // swizzling returns a static array.
    /// vec3 v3_2 = vec3(1.0f); // vec3 v3_2 = vec3(1.0f, 1.0f, 1.0f);
    /// ---
    this(Args...)(Args args) {
        construct!(0)(args);
    }
    
    /// ditto
    this(T)(T vec) if(is_vector!T && is(T.vt : vt) && (T.dimension >= dimension)) {
        foreach(i; TupleRange!(0, dimension)) {
            vector[i] = vec.vector[i];
        }
    }
    
    /// ditto
    this()(vt value) {
        clear(value);
    }
    
    /// Returns true if all values are not nan and finite, otherwise false.
    @property bool isFinite() const {
        static if(isIntegral!type) {
            return true;
        }
        else {
            foreach(v; vector) {
                if(isNaN(v) || isInfinity(v)) {
                    return false;
                }
            }
            return true;
        }
    }
    deprecated("Use isFinite instead of ok") alias ok = isFinite;
    
    /// Sets all values of the vector to value.
    void clear(vt value) {
        foreach(i; TupleRange!(0, dimension)) {
            vector[i] = value;
        }
    }
    
    unittest {
        vec3 vec_clear;
        assert(!vec_clear.isFinite);
        vec_clear.clear(1.0f);
        assert(vec_clear.isFinite);
        assert(vec_clear.vector == [1.0f, 1.0f, 1.0f]);
        assert(vec_clear.vector == vec3(1.0f).vector);
        vec_clear.clear(float.infinity);
        assert(!vec_clear.isFinite);
        vec_clear.clear(float.nan);
        assert(!vec_clear.isFinite);
        vec_clear.clear(1.0f);
        assert(vec_clear.isFinite);
        
        vec4 b = vec4(1.0f, vec_clear);
        assert(b.isFinite);
        assert(b.vector == [1.0f, 1.0f, 1.0f, 1.0f]);
        assert(b.vector == vec4(1.0f).vector);
        
        vec2 v2_1 = vec2(vec2(0.0f, 1.0f));
        assert(v2_1.vector == [0.0f, 1.0f]);
        
        vec2 v2_2 = vec2(1.0f, 1.0f);
        assert(v2_2.vector == [1.0f, 1.0f]);
        
        vec3 v3 = vec3(v2_1, 2.0f);
        assert(v3.vector == [0.0f, 1.0f, 2.0f]);
        
        vec4 v4_1 = vec4(1.0f, vec2(2.0f, 3.0f), 4.0f);
        assert(v4_1.vector == [1.0f, 2.0f, 3.0f, 4.0f]);
        assert(vec3(v4_1).vector == [1.0f, 2.0f, 3.0f]);
        assert(vec2(vec3(v4_1)).vector == [1.0f, 2.0f]);
        assert(vec2(vec3(v4_1)).vector == vec2(v4_1).vector);
        assert(v4_1.vector == vec4([1.0f, 2.0f, 3.0f, 4.0f]).vector);
        
        vec4 v4_2 = vec4(vec2(1.0f, 2.0f), vec2(3.0f, 4.0f));
        assert(v4_2.vector == [1.0f, 2.0f, 3.0f, 4.0f]);
        assert(vec3(v4_2).vector == [1.0f, 2.0f, 3.0f]);
        assert(vec2(vec3(v4_2)).vector == [1.0f, 2.0f]);
        assert(vec2(vec3(v4_2)).vector == vec2(v4_2).vector);
        assert(v4_2.vector == vec4([1.0f, 2.0f, 3.0f, 4.0f]).vector);
        
        float[2] f2 = [1.0f, 2.0f];
        float[3] f3 = [1.0f, 2.0f, 3.0f];
        float[4] f4 = [1.0f, 2.0f, 3.0f, 4.0f];
        assert(vec2(1.0f, 2.0f).vector == vec2(f2).vector);
        assert(vec3(1.0f, 2.0f, 3.0f).vector == vec3(f3).vector);
        assert(vec3(1.0f, 2.0f, 3.0f).vector == vec3(f2, 3.0f).vector);
        assert(vec4(1.0f, 2.0f, 3.0f, 4.0f).vector == vec4(f4).vector);
        assert(vec4(1.0f, 2.0f, 3.0f, 4.0f).vector == vec4(f3, 4.0f).vector);
        assert(vec4(1.0f, 2.0f, 3.0f, 4.0f).vector == vec4(f2, 3.0f, 4.0f).vector);
        // useful for: "vec4 v4 = […]" or "vec4 v4 = other_vector.rgba"
        
        assert(vec3(vec3i(1, 2, 3)) == vec3(1.0, 2.0, 3.0));
        assert(vec3d(vec3(1.0, 2.0, 3.0)) == vec3d(1.0, 2.0, 3.0));
        
        static assert(!__traits(compiles, vec3(0.0f, 0.0f)));
        static assert(!__traits(compiles, vec4(0.0f, 0.0f, 0.0f)));
        static assert(!__traits(compiles, vec4(0.0f, vec2(0.0f, 0.0f))));
        static assert(!__traits(compiles, vec4(vec3(0.0f, 0.0f, 0.0f))));
    }
    
    template coord_to_index(char c) {
        static if((c == 'x') || (c == 'r') || (c == 'u') || (c == 's')) {
            enum coord_to_index = 0;
        } else static if((c == 'y') || (c == 'g') || (c == 'v') || (c == 't')) {
            enum coord_to_index = 1;
        } else static if((c == 'z') || (c == 'b') || (c == 'p')) {
            static assert(dimension >= 3, "the " ~ c ~ " property is only available on vectors with a third dimension.");
            enum coord_to_index = 2;
        } else static if((c == 'w') || (c == 'a') || (c == 'q')) {
            static assert(dimension >= 4, "the " ~ c ~ " property is only available on vectors with a fourth dimension.");
            enum coord_to_index = 3;
        } else {
            static assert(false, "accepted coordinates are x, s, r, u, y, g, t, v, z, p, b, w, q and a not " ~ c ~ ".");
        }
    }
    
    static if(dimension == 2) { void set(vt x, vt y) { vector[0] = x; vector[1] = y; } }
    static if(dimension == 3) { void set(vt x, vt y, vt z) { vector[0] = x; vector[1] = y; vector[2] = z; } }
    static if(dimension == 4) { void set(vt x, vt y, vt z, vt w) { vector[0] = x; vector[1] = y; vector[2] = z; vector[3] = w; } }
    
    /// Updates the vector with the values from other.
    void update(Vector!(vt, dimension) other) {
        vector = other.vector;
    }
    
    unittest {
        vec2 v2 = vec2(1.0f, 2.0f);
        assert(v2.x == 1.0f);
        assert(v2.y == 2.0f);
        v2.x = 3.0f;
        v2.x += 1;
        v2.x -= 1;
        assert(v2.vector == [3.0f, 2.0f]);
        v2.y = 4.0f;
        v2.y += 1;
        v2.y -= 1;
        assert(v2.vector == [3.0f, 4.0f]);
        assert((v2.x == 3.0f) && (v2.x == v2.u) && (v2.x == v2.s) && (v2.x == v2.r));
        assert(v2.y == 4.0f);
        assert((v2.y == 4.0f) && (v2.y == v2.v) && (v2.y == v2.t) && (v2.y == v2.g));
        v2.set(0.0f, 1.0f);
        assert(v2.vector == [0.0f, 1.0f]);
        v2.update(vec2(3.0f, 4.0f));
        assert(v2.vector == [3.0f, 4.0f]);
        
        vec3 v3 = vec3(1.0f, 2.0f, 3.0f);
        assert(v3.x == 1.0f);
        assert(v3.y == 2.0f);
        assert(v3.z == 3.0f);
        v3.x = 3.0f;
        v3.x += 1;
        v3.x -= 1;
        assert(v3.vector == [3.0f, 2.0f, 3.0f]);
        v3.y = 4.0f;
        v3.y += 1;
        v3.y -= 1;
        assert(v3.vector == [3.0f, 4.0f, 3.0f]);
        v3.z = 5.0f;
        v3.z += 1;
        v3.z -= 1;
        assert(v3.vector == [3.0f, 4.0f, 5.0f]);
        assert((v3.x == 3.0f) && (v3.x == v3.s) && (v3.x == v3.r));
        assert((v3.y == 4.0f) && (v3.y == v3.t) && (v3.y == v3.g));
        assert((v3.z == 5.0f) && (v3.z == v3.p) && (v3.z == v3.b));
        v3.set(0.0f, 1.0f, 2.0f);
        assert(v3.vector == [0.0f, 1.0f, 2.0f]);
        v3.update(vec3(3.0f, 4.0f, 5.0f));
        assert(v3.vector == [3.0f, 4.0f, 5.0f]);
        
        vec4 v4 = vec4(1.0f, 2.0f, vec2(3.0f, 4.0f));
        assert(v4.x == 1.0f);
        assert(v4.y == 2.0f);
        assert(v4.z == 3.0f);
        assert(v4.w == 4.0f);
        v4.x = 3.0f;
        v4.x += 1;
        v4.x -= 1;
        assert(v4.vector == [3.0f, 2.0f, 3.0f, 4.0f]);
        v4.y = 4.0f;
        v4.y += 1;
        v4.y -= 1;
        assert(v4.vector == [3.0f, 4.0f, 3.0f, 4.0f]);
        v4.z = 5.0f;
        v4.z += 1;
        v4.z -= 1;
        assert(v4.vector == [3.0f, 4.0f, 5.0f, 4.0f]);
        v4.w = 6.0f;
        v4.w += 1;
        v4.w -= 1;
        assert(v4.vector == [3.0f, 4.0f, 5.0f, 6.0f]);
        assert((v4.x == 3.0f) && (v4.x == v4.s) && (v4.x == v4.r));
        assert((v4.y == 4.0f) && (v4.y == v4.t) && (v4.y == v4.g));
        assert((v4.z == 5.0f) && (v4.z == v4.p) && (v4.z == v4.b));
        assert((v4.w == 6.0f) && (v4.w == v4.q) && (v4.w == v4.a));
        v4.set(0.0f, 1.0f, 2.0f, 3.0f);
        assert(v4.vector == [0.0f, 1.0f, 2.0f, 3.0f]);
        v4.update(vec4(3.0f, 4.0f, 5.0f, 6.0f));
        assert(v4.vector == [3.0f, 4.0f, 5.0f, 6.0f]);
    }
    
    private void dispatchImpl(int i, string s, int size)(ref vt[size] result) const {
        static if(s.length > 0) {
            result[i] = vector[coord_to_index!(s[0])];
            dispatchImpl!(i + 1, s[1..$])(result);
        }
    }
    
    /// Implements dynamic swizzling.
    /// Returns: a Vector
    @property Vector!(vt, s.length) opDispatch(string s)() const {
        vt[s.length] ret;
        dispatchImpl!(0, s)(ret);
        Vector!(vt, s.length) ret_vec;
        ret_vec.vector = ret;
        return ret_vec;
    }
    
    unittest {
        vec2 v2 = vec2(1.0f, 2.0f);
        assert(v2.xytsy == [1.0f, 2.0f, 2.0f, 1.0f, 2.0f]);
        
        assert(vec3(1.0f, 2.0f, 3.0f).xybzyr == [1.0f, 2.0f, 3.0f, 3.0f, 2.0f, 1.0f]);
        assert(vec4(v2, 3.0f, 4.0f).xyzwrgbastpq == [1.0f, 2.0f, 3.0f, 4.0f,
                1.0f, 2.0f, 3.0f, 4.0f,
                1.0f, 2.0f, 3.0f, 4.0f]);
        assert(vec4(v2, 3.0f, 4.0f).wgyzax == [4.0f, 2.0f, 2.0f, 3.0f, 4.0f, 1.0f]);
        assert(vec4(v2.xyst).vector == [1.0f, 2.0f, 1.0f, 2.0f]);
    }
    
    /// Returns the squared magnitude of the vector.
    @property real magnitude_squared() const {
        real temp = 0;
        
        foreach(index; TupleRange!(0, dimension)) {
            temp += vector[index]^^2;
        }
        
        return temp;
    }
    
    /// Returns the magnitude of the vector.
    @property real magnitude() const {
        return sqrt(magnitude_squared);
    }
    
    alias magnitude_squared length_squared; /// ditto
    alias magnitude length; /// ditto
    
    /// Normalizes the vector.
    void normalize() {
        real len = length;
        
        if(len != 0) {
            foreach(index; TupleRange!(0, dimension)) {
                vector[index] = cast(type)(vector[index]/len);
            }
        }
    }
    
    /// Returns a normalized copy of the current vector.
    @property Vector normalized() const {
        Vector ret;
        ret.update(this);
        ret.normalize();
        return ret;
    }
    
    Vector opUnary(string op : "-")() const {
        Vector ret;
        
        foreach(index; TupleRange!(0, dimension)) {
            ret.vector[index] = -vector[index];
        }
        
        return ret;
    }
    
    unittest {
        assert(vec2(1.0f, 1.0f) == -vec2(-1.0f, -1.0f));
        assert(vec2(-1.0f, 1.0f) == -vec2(1.0f, -1.0f));
        
        assert(-vec3(1.0f, 1.0f, 1.0f) == vec3(-1.0f, -1.0f, -1.0f));
        assert(-vec3(-1.0f, 1.0f, -1.0f) == vec3(1.0f, -1.0f, 1.0f));
        
        assert(vec4(1.0f, 1.0f, 1.0f, 1.0f) == -vec4(-1.0f, -1.0f, -1.0f, -1.0f));
        assert(vec4(-1.0f, 1.0f, -1.0f, 1.0f) == -vec4(1.0f, -1.0f, 1.0f, -1.0f));
    }
    
    // let the math begin!
    Vector opBinary(string op : "*")(vt r) const {
        Vector ret;
        
        foreach(index; TupleRange!(0, dimension)) {
            ret.vector[index] = vector[index] * r;
        }
        
        return ret;
    }
    
    Vector opBinary(string op : "/")(vt r) const {
        Vector ret;
        
        foreach(index; TupleRange!(0, dimension)) {
            ret.vector[index] = vector[index] / r;
        }
        
        return ret;
    }
    
    Vector opBinary(string op)(Vector r) const if((op == "+") || (op == "-")) {
        Vector ret;
        
        foreach(index; TupleRange!(0, dimension)) {
            ret.vector[index] = mixin("vector[index]" ~ op ~ "r.vector[index]");
        }
        
        return ret;
    }
    
    vt opBinary(string op : "*")(Vector r) const {
        return dot(this, r);
    }
    
    // vector * matrix (for matrix * vector -> struct Matrix)
    Vector!(vt, T.cols) opBinary(string op : "*", T)(T inp) const if(isCompatibleMatrix!T && (T.rows == dimension)) {
        Vector!(vt, T.cols) ret;
        ret.clear(0);
        
        foreach(c; TupleRange!(0, T.cols)) {
            foreach(r; TupleRange!(0, T.rows)) {
                ret.vector[c] += vector[r] * inp.matrix[r][c];
            }
        }
        
        return ret;
    }
    
    auto opBinaryRight(string op, T)(T inp) const if(!is_vector!T && !is_matrix!T && !is_quaternion!T) {
        return this.opBinary!(op)(inp);
    }
    
    unittest {
        import gl3n.linalg.matrix : mat2, mat3;

        vec2 v2 = vec2(1.0f, 3.0f);
        auto v2times2 = 2 * v2;
        assert((v2*2.5f).vector == [2.5f, 7.5f]);
        assert((v2+vec2(3.0f, 1.0f)).vector == [4.0f, 4.0f]);
        assert((v2-vec2(1.0f, 3.0f)).vector == [0.0f, 0.0f]);
        assert((v2*vec2(2.0f, 2.0f)) == 8.0f);
        
        vec3 v3 = vec3(1.0f, 3.0f, 5.0f);
        assert((v3*2.5f).vector == [2.5f, 7.5f, 12.5f]);
        assert((v3+vec3(3.0f, 1.0f, -1.0f)).vector == [4.0f, 4.0f, 4.0f]);
        assert((v3-vec3(1.0f, 3.0f, 5.0f)).vector == [0.0f, 0.0f, 0.0f]);
        assert((v3*vec3(2.0f, 2.0f, 2.0f)) == 18.0f);
        
        vec4 v4 = vec4(1.0f, 3.0f, 5.0f, 7.0f);
        assert((v4*2.5f).vector == [2.5f, 7.5f, 12.5f, 17.5]);
        assert((v4+vec4(3.0f, 1.0f, -1.0f, -3.0f)).vector == [4.0f, 4.0f, 4.0f, 4.0f]);
        assert((v4-vec4(1.0f, 3.0f, 5.0f, 7.0f)).vector == [0.0f, 0.0f, 0.0f, 0.0f]);
        assert((v4*vec4(2.0f, 2.0f, 2.0f, 2.0f)) == 32.0f);
        
        mat2 m2 = mat2(1.0f, 2.0f, 3.0f, 4.0f);
        vec2 v2_2 = vec2(2.0f, 2.0f);
        assert((v2_2*m2).vector == [8.0f, 12.0f]);
        
        mat3 m3 = mat3(1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f, 7.0f, 8.0f, 9.0f);
        vec3 v3_2 = vec3(2.0f, 2.0f, 2.0f);
        assert((v3_2*m3).vector == [24.0f, 30.0f, 36.0f]);
    }
    
    void opOpAssign(string op : "*")(vt r) {
        foreach(index; TupleRange!(0, dimension)) {
            vector[index] *= r;
        }
    }
    
    void opOpAssign(string op : "/")(vt r) {
        foreach(index; TupleRange!(0, dimension)) {
            vector[index] /= r;
        }
    }
    
    void opOpAssign(string op)(Vector r) if((op == "+") || (op == "-")) {
        foreach(index; TupleRange!(0, dimension)) {
            mixin("vector[index]" ~ op ~ "= r.vector[index];");
        }
    }
    
    unittest {
        vec2 v2 = vec2(1.0f, 3.0f);
        v2 *= 2.5f;
        assert(v2.vector == [2.5f, 7.5f]);
        v2 -= vec2(2.5f, 7.5f);
        assert(v2.vector == [0.0f, 0.0f]);
        v2 += vec2(1.0f, 3.0f);
        assert(v2.vector == [1.0f, 3.0f]);
        assert(almost_equal(v2.length, sqrt(10.0f)));
        assert(v2.length_squared == 10.0f);
        assert((v2.magnitude == v2.length) && (v2.magnitude_squared == v2.length_squared));
        v2 /= 2.0f;
        assert(v2.vector == [0.5f, 1.5f]);
        assert(almost_equal(v2.normalized, vec2(1.0f/sqrt(10.0f), 3.0f/sqrt(10.0f))));
        
        vec3 v3 = vec3(1.0f, 3.0f, 5.0f);
        v3 *= 2.5f;
        assert(v3.vector == [2.5f, 7.5f, 12.5f]);
        v3 -= vec3(2.5f, 7.5f, 12.5f);
        assert(v3.vector == [0.0f, 0.0f, 0.0f]);
        v3 += vec3(1.0f, 3.0f, 5.0f);
        assert(v3.vector == [1.0f, 3.0f, 5.0f]);
        assert(almost_equal(v3.length, sqrt(35.0f)));
        assert(v3.length_squared == 35.0f);
        assert((v3.magnitude == v3.length) && (v3.magnitude_squared == v3.length_squared));
        v3 /= 2.0f;
        assert(v3.vector == [0.5f, 1.5f, 2.5f]);
        assert(almost_equal(v3.normalized, vec3(1.0f/sqrt(35.0f), 3.0f/sqrt(35.0f), 5.0f/sqrt(35.0f))));
        
        vec4 v4 = vec4(1.0f, 3.0f, 5.0f, 7.0f);
        v4 *= 2.5f;
        assert(v4.vector == [2.5f, 7.5f, 12.5f, 17.5]);
        v4 -= vec4(2.5f, 7.5f, 12.5f, 17.5f);
        assert(v4.vector == [0.0f, 0.0f, 0.0f, 0.0f]);
        v4 += vec4(1.0f, 3.0f, 5.0f, 7.0f);
        assert(v4.vector == [1.0f, 3.0f, 5.0f, 7.0f]);
        assert(almost_equal(v4.length, sqrt(84.0f)));
        assert(v4.length_squared == 84.0f);
        assert((v4.magnitude == v4.length) && (v4.magnitude_squared == v4.length_squared));
        v4 /= 2.0f;
        assert(v4.vector == [0.5f, 1.5f, 2.5f, 3.5f]);
        assert(almost_equal(v4.normalized, vec4(1.0f/sqrt(84.0f), 3.0f/sqrt(84.0f), 5.0f/sqrt(84.0f), 7.0f/sqrt(84.0f))));
    }
    
    int opCmp(ref const Vector vec) const {
        foreach(i, a; vector) {
            if(a < vec.vector[i]) {
                return -1;
            } else if(a > vec.vector[i]) {
                return 1;
            }
        }
        
        // Vectors are the same
        return 0;
    }
    
    bool opEquals(T)(const T vec) const if(!isArray!T && T.dimension == dimension) {
        return vector == vec.vector;
    }
    
    bool opEquals(T)(const(T)[] array) const if(!isArray!T && !is_vector!T) {
        if(array.length != dimension) {
            return false;
        }
        
        foreach(index; TupleRange!(0, dimension)) {
            if(vector[index] != array[index]) {
                return false;
            }
        }
        
        return true;
    }
    
    bool opCast(T : bool)() const {
        return isFinite;
    }
    
    unittest {
        assert(vec2(1.0f, 2.0f) == vec2(1.0f, 2.0f));
        assert(vec2(1.0f, 2.0f) != vec2(1.0f, 1.0f));
        assert(vec2(1.0f, 2.0f) == vec2d(1.0, 2.0));
        assert(vec2(1.0f, 2.0f) != vec2d(1.0, 1.0));
        assert(vec2(1.0f, 2.0f) == vec2(1.0f, 2.0f).vector);
        assert(vec2(1.0f, 2.0f) != vec2(1.0f, 1.0f).vector);
        assert(vec2(1.0f, 2.0f) == vec2d(1.0, 2.0).vector);
        assert(vec2(1.0f, 2.0f) != vec2d(1.0, 1.0).vector);
        
        assert(vec3(1.0f, 2.0f, 3.0f) == vec3(1.0f, 2.0f, 3.0f));
        assert(vec3(1.0f, 2.0f, 3.0f) != vec3(1.0f, 2.0f, 2.0f));
        assert(vec3(1.0f, 2.0f, 3.0f) == vec3d(1.0, 2.0, 3.0));
        assert(vec3(1.0f, 2.0f, 3.0f) != vec3d(1.0, 2.0, 2.0));
        assert(vec3(1.0f, 2.0f, 3.0f) == vec3(1.0f, 2.0f, 3.0f).vector);
        assert(vec3(1.0f, 2.0f, 3.0f) != vec3(1.0f, 2.0f, 2.0f).vector);
        assert(vec3(1.0f, 2.0f, 3.0f) == vec3d(1.0, 2.0, 3.0).vector);
        assert(vec3(1.0f, 2.0f, 3.0f) != vec3d(1.0, 2.0, 2.0).vector);
        
        assert(vec4(1.0f, 2.0f, 3.0f, 4.0f) == vec4(1.0f, 2.0f, 3.0f, 4.0f));
        assert(vec4(1.0f, 2.0f, 3.0f, 4.0f) != vec4(1.0f, 2.0f, 3.0f, 3.0f));
        assert(vec4(1.0f, 2.0f, 3.0f, 4.0f) == vec4d(1.0, 2.0, 3.0, 4.0));
        assert(vec4(1.0f, 2.0f, 3.0f, 4.0f) != vec4d(1.0, 2.0, 3.0, 3.0));
        assert(vec4(1.0f, 2.0f, 3.0f, 4.0f) == vec4(1.0f, 2.0f, 3.0f, 4.0f).vector);
        assert(vec4(1.0f, 2.0f, 3.0f, 4.0f) != vec4(1.0f, 2.0f, 3.0f, 3.0f).vector);
        assert(vec4(1.0f, 2.0f, 3.0f, 4.0f) == vec4d(1.0, 2.0, 3.0, 4.0).vector);
        assert(vec4(1.0f, 2.0f, 3.0f, 4.0f) != vec4d(1.0, 2.0, 3.0, 3.0).vector);
        
        assert(!(vec4(float.nan)));
        if(vec4(1.0f)) { }
        else { assert(false); }
    }
    
}

/// Calculates the product between two vectors.
T.vt dot(T)(const T veca, const T vecb) @safe pure nothrow if(is_vector!T) {
    T.vt temp = 0;
    
    foreach(index; TupleRange!(0, T.dimension)) {
        temp += veca.vector[index] * vecb.vector[index];
    }
    
    return temp;
}

/// Calculates the cross product of two 3-dimensional vectors.
T cross(T)(const T veca, const T vecb) @safe pure nothrow if(is_vector!T && (T.dimension == 3)) {
    return T(veca.y * vecb.z - vecb.y * veca.z,
        veca.z * vecb.x - vecb.z * veca.x,
        veca.x * vecb.y - vecb.x * veca.y);
}

/// Calculates the distance between two vectors.
T.vt distance(T)(const T veca, const T vecb) @safe pure nothrow if(is_vector!T) {
    return (veca - vecb).length;
}

unittest {
    // dot is already tested in Vector.opBinary, so no need for testing with more vectors
    vec3 v1 = vec3(1.0f, 2.0f, -3.0f);
    vec3 v2 = vec3(1.0f, 3.0f, 2.0f);
    
    assert(dot(v1, v2) == 1.0f);
    assert(dot(v1, v2) == (v1 * v2));
    assert(dot(v1, v2) == dot(v2, v1));
    assert((v1 * v2) == (v1 * v2));
    
    assert(cross(v1, v2).vector == [13.0f, -5.0f, 1.0f]);
    assert(cross(v2, v1).vector == [-13.0f, 5.0f, -1.0f]);
    
    assert(distance(vec2(0.0f, 0.0f), vec2(0.0f, 10.0f)) == 10.0);
}

/// reflect a vector using a surface normal
T reflect(T)(const T vec, const T norm) @safe pure nothrow if(is_vector!T) {
    return (2 * (vec * norm) * norm) - vec;
}

unittest
{
    assert(vec2(1,1).reflect(vec2(0,1)) == vec2(-1,1));
    assert(vec2(-1,1).reflect(vec2(0,1)) == vec2(1,1));
    assert(vec2(2,1).reflect(vec2(0,1)) == vec2(-2,1));
    
    assert(vec3(1,1,1).reflect(vec3(0,1,0)) == vec3(-1,1,-1));
}

/// Pre-defined vector types, the number represents the dimension and the last letter the type (none = float, d = double, i = int).
alias Vector!(float, 2) vec2;
alias Vector!(float, 3) vec3; /// ditto
alias Vector!(float, 4) vec4; /// ditto

alias Vector!(double, 2) vec2d; /// ditto
alias Vector!(double, 3) vec3d; /// ditto
alias Vector!(double, 4) vec4d; /// ditto

alias Vector!(int, 2) vec2i; /// ditto
alias Vector!(int, 3) vec3i; /// ditto
alias Vector!(int, 4) vec4i; /// ditto

/*alias Vector!(ubyte, 2) vec2ub;
alias Vector!(ubyte, 3) vec3ub;
alias Vector!(ubyte, 4) vec4ub;*/
