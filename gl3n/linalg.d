/**
Copyright: David Herberth, 2011

License: MIT
 
 Copyright (c) 2011, David Herberth.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.

Authors: David Herberth

Special thanks to: 
 - Tomasz Stachowiak (h3r3tic)
 - Jakob Øvrum (jA_cOp)
 - #D on freenode

*/


module gl3n.linalg;

private {
    import std.math : isNaN, PI, abs, sqrt, sin, cos, acos, tan, asin, atan2;
    import std.conv : to;
    import std.traits : isFloatingPoint;
    import std.string : format, rightJustify;
    import std.array : join;
    import std.algorithm : max, min, reduce;
}


struct Vector(type, int dimension_) if((dimension_ >= 2) && (dimension_ <= 4)) {
    alias type vt;
    static const int dimension = dimension_;
    
    vt[dimension] vector;
    
    @property auto value_ptr() { return vector.ptr; }

    private @property vt get_(char coord)() {
        return vector[coord_to_index!coord];
    }
    private @property void set_(char coord)(vt value) {
        vector[coord_to_index!coord] = value;
    }
    
    alias get_!'x' x;
    alias set_!'x' x;
    alias get_!'y' y;
    alias set_!'y' y;
    alias x s;
    alias y t;
    alias x r;
    alias y g;
    static if(dimension >= 3) {
        alias get_!'z' z;
        alias set_!'z' z;
        alias z b;
    }
    static if(dimension >= 4) {
        alias get_!'w' w;
        alias set_!'w' w;
        alias w a;
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
            static assert(false, "constructor has too many arguments");
        } else static if(is(T : vt)) {
            vector[i] = head;
            construct!(i + 1)(tail);
        } else static if(isCompatibleVector!T) {   
            vector[i .. i + T.dimension] = head.vector;
            construct!(i + T.dimension)(tail);
        } else {
            static assert(false, "Vector constructor argument must be of type " ~ vt.stringof ~ " or Vector, not " ~ T.stringof);
        }
    }
    
    private void construct(int i)() { // terminate
    }

    this(Args...)(Args args) {
        construct!(0)(args);
    }
    
    this()(vt value) {
        clear(value);
    }
          
    @property bool ok() {
        foreach(v; vector) {
            if(isNaN(v)) {
                return false;
            }
        }
        return true;
    }
               
    void clear(vt value) {
        foreach(ref v; vector) {
            v = value;
        }
    }

    unittest {
        vec3 vec_clear;
        assert(!vec_clear.ok);
        vec_clear.clear(1.0f);
        assert(vec_clear.vector == [1.0f, 1.0f, 1.0f]);
        assert(vec_clear.vector == vec3(1.0f).vector);
        
        vec4 b = vec4(1.0f, vec_clear);
        assert(b.ok);
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
        
        vec4 v4_2 = vec4(vec2(1.0f, 2.0f), vec2(3.0f, 4.0f));
        assert(v4_1.vector == [1.0f, 2.0f, 3.0f, 4.0f]);
    }

    template coord_to_index(char c) {   
        static if((c == 'x') || (c == 'r') || (c == 's')) {
            enum coord_to_index = 0;
        } else static if((c == 'y') || (c == 'g') || (c == 't')) {
            enum coord_to_index = 1;
        } else static if((c == 'z') || (c == 'b')) {
            static assert(dimension >= 3, "the " ~ c ~ " property is only available on vectors with a third dimension.");
            enum coord_to_index = 2;
        } else static if((c == 'w') || (c == 'a')) {
            static assert(dimension >= 4, "the " ~ c ~ " property is only available on vectors with a fourth dimension.");
            enum coord_to_index = 3;
        } else {
            static assert(false, "accepted coordinates are x, s, r, y, g, t, z, b, w and a not " ~ c ~ ".");
        }
    }
    
    static if(dimension == 2) { void set(vt x, vt y) { vector[0] = x; vector[1] = y; } }
    static if(dimension == 3) { void set(vt x, vt y, vt z) { vector[0] = x; vector[1] = y; vector[2] = z; } }
    static if(dimension == 4) { void set(vt x, vt y, vt z, vt w) { vector[0] = x; vector[1] = y; vector[2] = z; vector[3] = w; } }

    void update(Vector!(vt, dimension) other) {
        vector = other.vector;
    }

    unittest {
        vec2 v2 = vec2(1.0f, 2.0f);
        assert(v2.x == 1.0f);
        assert(v2.y == 2.0f);
        v2.x = 3.0f;
        assert(v2.vector == [3.0f, 2.0f]);
        v2.y = 4.0f;
        assert(v2.vector == [3.0f, 4.0f]);
        assert((v2.x == 3.0f) && (v2.x == v2.s));
        assert(v2.y == 4.0f);
        assert((v2.y == 4.0f) && (v2.y == v2.t));
        v2.set(0.0f, 1.0f);
        assert(v2.vector == [0.0f, 1.0f]);
        v2.update(vec2(3.0f, 4.0f));
        assert(v2.vector == [3.0f, 4.0f]);
        
        vec3 v3 = vec3(1.0f, 2.0f, 3.0f);
        assert(v3.x == 1.0f);
        assert(v3.y == 2.0f);
        assert(v3.z == 3.0f);
        v3.x = 3.0f;
        assert(v3.vector == [3.0f, 2.0f, 3.0f]);
        v3.y = 4.0f;
        assert(v3.vector == [3.0f, 4.0f, 3.0f]);
        v3.z = 5.0f;
        assert(v3.vector == [3.0f, 4.0f, 5.0f]);
        assert((v3.x == 3.0f) && (v3.x == v3.r));
        assert((v3.y == 4.0f) && (v3.y == v3.g));
        assert((v3.z == 5.0f) && (v3.z == v3.b));
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
        assert(v4.vector == [3.0f, 2.0f, 3.0f, 4.0f]);
        v4.y = 4.0f;
        assert(v4.vector == [3.0f, 4.0f, 3.0f, 4.0f]);
        v4.z = 5.0f;
        assert(v4.vector == [3.0f, 4.0f, 5.0f, 4.0f]);
        v4.w = 6.0f;
        assert(v4.vector == [3.0f, 4.0f, 5.0f, 6.0f]);
        assert((v4.x == 3.0f) && (v4.x == v4.r));
        assert((v4.y == 4.0f) && (v4.y == v4.g));
        assert((v4.z == 5.0f) && (v4.z == v4.b));
        assert((v4.w == 6.0f) && (v4.w == v4.a));
        v4.set(0.0f, 1.0f, 2.0f, 3.0f);
        assert(v4.vector == [0.0f, 1.0f, 2.0f, 3.0f]);
        v4.update(vec4(3.0f, 4.0f, 5.0f, 6.0f));
        assert(v4.vector == [3.0f, 4.0f, 5.0f, 6.0f]);
    }
    
    @property string as_string() {
        return format(isFloatingPoint!(vt) ? "%f":"%s", vector);
    }
    alias as_string toString;
    
    void dispatchImpl(int i, string s, int size)(ref vt[size] result) {
        static if(s.length > 0) {
            result[i] = vector[coord_to_index!(s[0])];
            dispatchImpl!(i + 1, s[1..$])(result);
        }
    }

    vt[s.length] opDispatch(string s)() {
        vt[s.length] ret;
        dispatchImpl!(0, s)(ret);
        return ret;
    }
    
    unittest {
        vec2 v2 = vec2(1.0f, 2.0f);
        assert(v2.xytsy == [1.0f, 2.0f, 2.0f, 1.0f, 2.0f]);

        assert(vec3(1.0f, 2.0f, 3.0f).xybzyr == [1.0f, 2.0f, 3.0f, 3.0f, 2.0f, 1.0f]);
        
        assert(vec4(v2, 3.0f, 4.0f).wgyzax == [4.0f, 2.0f, 2.0f, 3.0f, 4.0f, 1.0f]);
    }

    Vector opUnary(string op : "-")() {
        Vector ret;
        
        ret.vector[0] = -vector[0];
        ret.vector[1] = -vector[1];
        static if(dimension >= 3) { ret.vector[2] = -vector[2]; }
        static if(dimension >= 4) { ret.vector[3] = -vector[3]; }
        
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
    Vector opBinary(string op : "*", T : vt)(T r) {
        Vector ret;
        
        ret.vector[0] = vector[0] * r;
        ret.vector[1] = vector[1] * r;
        static if(dimension >= 3) { ret.vector[2] = vector[2] * r; }
        static if(dimension >= 4) { ret.vector[3] = vector[3] * r; }
        
        return ret;
    }

    Vector opBinary(string op, T : Vector)(T r) if((op == "+") || (op == "-")) {
        Vector ret;
        
        ret.vector[0] = mixin("vector[0]" ~ op ~ "r.vector[0]");
        ret.vector[1] = mixin("vector[1]" ~ op ~ "r.vector[1]");
        static if(dimension >= 3) { ret.vector[2] = mixin("vector[2]" ~ op ~ "r.vector[2]"); }
        static if(dimension >= 4) { ret.vector[3] = mixin("vector[3]" ~ op ~ "r.vector[3]"); }
        
        return ret;
    }
    
    vt opBinary(string op : "*", T : Vector)(T r) {
        vt temp = 0;
        
        temp += vector[0] * r.vector[0];
        temp += vector[1] * r.vector[1];
        static if(dimension >= 3) { temp += vector[2] * r.vector[2]; }
        static if(dimension >= 4) { temp += vector[3] * r.vector[3]; }
                
        return temp;
    }

    Vector!(vt, T.rows) opBinary(string op : "*", T)(T inp) if(isCompatibleMatrix!T && (T.cols == dimension)) {
        Vector!(vt, T.rows) ret;
        ret.clear(0);
        
        for(int r = 0; r < inp.rows; r++) {
            for(int c = 0; c < inp.cols; c++) {
                ret.vector[r] += vector[c] * inp.matrix[r][c];
            }
        }
        
        return ret;
    }

    unittest {
        vec2 v2 = vec2(1.0f, 3.0f);
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
        assert((v2_2*m2).vector == [6.0f, 14.0f]);

        mat3 m3 = mat3(1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f, 7.0f, 8.0f, 9.0f);
        vec3 v3_2 = vec3(2.0f, 2.0f, 2.0f);
        assert((v3_2*m3).vector == [12.0f, 30.0f, 48.0f]);
    }
    
    void opOpAssign(string op : "*", T : vt)(T r) {
        vector[0] *= r;
        vector[1] *= r;
        static if(dimension >= 3) { vector[2] *= r; }
        static if(dimension >= 4) { vector[3] *= r; }
    }

    void opOpAssign(string op, T : Vector)(T r) if((op == "+") || (op == "-")) {
        mixin("vector[0]" ~ op ~ "= r.vector[0];");
        mixin("vector[1]" ~ op ~ "= r.vector[1];");
        static if(dimension >= 3) { mixin("vector[2]" ~ op ~ "= r.vector[2];"); }
        static if(dimension >= 4) { mixin("vector[3]" ~ op ~ "= r.vector[3];"); }
    }
    
    @property real magnitude_squared() {
        real temp = 0;
        
        foreach(v; vector) {
            temp += v^^2;
        }
        
        return temp;
    }
    
    @property real magnitude() {
        return sqrt(magnitude_squared);
    }
    
    alias magnitude_squared length_squared;
    alias magnitude length;
    
    void normalize() {
        real len = length;
        
        if(len != 0) {
            vector[0] /= len;
            vector[1] /= len;
            static if(dimension >= 3) { vector[2] /= len; }
            static if(dimension >= 4) { vector[3] /= len; }
        }
    }
    
    @property Vector normalized() {
        Vector ret;
        ret.update(this);
        ret.normalize();
        return ret;
    }
    
    static vt dot(Vector veca, Vector vecb) {
        return veca * vecb;
    }
    
    static if(dimension == 3) {
        static Vector cross(Vector veca, Vector vecb) {
            return Vector(veca.y * vecb.z - vecb.y * veca.z,
                          veca.z * vecb.x - vecb.z * veca.x,
                          veca.x * vecb.y - vecb.x * veca.y);
        }
    }

    static real distance(Vector veca, Vector vecb) {
        return (veca - vecb).length;
    }
    
    static Vector mix(Vector x, Vector y, vt a) {
        Vector ret;
        
        for(int i = 0; i < ret.vector.length; i++) {
            ret.vector[i] = x.vector[i] + a*(y.vector[i] - x.vector[i]);
        }
        
        return ret;
    }

    unittest {
        // dot is already tested in opBinary, so no need for testing with more vectors
        vec3 v1 = vec3(1.0f, 2.0f, -3.0f);
        vec3 v2 = vec3(1.0f, 3.0f, 2.0f);
        
        assert(vec3.dot(v1, v2) == 1.0f);
        assert(vec3.dot(v1, v2) == (v1 * v2));
        assert(vec3.dot(v1, v2) == vec3.dot(v2, v1));
        assert((v1 * v2) == (v1 * v2));
        
        assert(vec3.cross(v1, v2).vector == [13.0f, -5.0f, 1.0f]);
        assert(vec3.cross(v2, v1).vector == [-13.0f, 5.0f, -1.0f]);
        
        assert(vec2.distance(vec2(0.0f, 0.0f), vec2(0.0f, 10.0f)) == 10.0);
        
        assert(vec3.mix(v1, v2, 0.0f).vector == v1.vector);
        assert(vec3.mix(v1, v2, 1.0f).vector == v2.vector);
        
    }   
    
    unittest {
        vec2 v2 = vec2(1.0f, 3.0f);
        v2 *= 2.5f;
        assert(v2.vector == [2.5f, 7.5f]);
        v2 -= vec2(2.5f, 7.5f);
        assert(v2.vector == [0.0f, 0.0f]);
        v2 += vec2(1.0f, 3.0f);
        assert(v2.vector == [1.0f, 3.0f]);
        assert(v2.length == sqrt(10));
        assert(v2.length_squared == 10);
        assert((v2.magnitude == v2.length) && (v2.magnitude_squared == v2.length_squared));
        assert(v2.normalized == vec2(1.0f/sqrt(10), 3.0f/sqrt(10)));

        vec3 v3 = vec3(1.0f, 3.0f, 5.0f);
        v3 *= 2.5f;
        assert(v3.vector == [2.5f, 7.5f, 12.5f]);
        v3 -= vec3(2.5f, 7.5f, 12.5f);
        assert(v3.vector == [0.0f, 0.0f, 0.0f]);
        v3 += vec3(1.0f, 3.0f, 5.0f);
        assert(v3.vector == [1.0f, 3.0f, 5.0f]);
        assert(v3.length == sqrt(35));
        assert(v3.length_squared == 35);
        assert((v3.magnitude == v3.length) && (v3.magnitude_squared == v3.length_squared));
        assert(v3.normalized == vec3(1.0f/sqrt(35), 3.0f/sqrt(35), 5.0f/sqrt(35)));
            
        vec4 v4 = vec4(1.0f, 3.0f, 5.0f, 7.0f);
        v4 *= 2.5f;
        assert(v4.vector == [2.5f, 7.5f, 12.5f, 17.5]);
        v4 -= vec4(2.5f, 7.5f, 12.5f, 17.5f);
        assert(v4.vector == [0.0f, 0.0f, 0.0f, 0.0f]);
        v4 += vec4(1.0f, 3.0f, 5.0f, 7.0f);
        assert(v4.vector == [1.0f, 3.0f, 5.0f, 7.0f]);
        assert(v4.length == sqrt(84));
        assert(v4.length_squared == 84);
        assert((v4.magnitude == v4.length) && (v4.magnitude_squared == v4.length_squared));
        assert(v4.normalized == vec4(1.0f/sqrt(84), 3.0f/sqrt(84), 5.0f/sqrt(84), 7.0f/sqrt(84)));
    }
       
    const bool opEquals(T)(T vec) if(T.dimension == dimension) {
        return vector == vec.vector;
    }
    
    bool opCast(T : bool)() {
        return ok;
    }
    
    unittest {
        assert(vec2(1.0f, 2.0f) == vec2(1.0f, 2.0f));
        assert(vec2(1.0f, 2.0f) != vec2(1.0f, 1.0f));
        assert(vec2(1.0f, 2.0f) == vec2d(1.0, 2.0));
        assert(vec2(1.0f, 2.0f) != vec2d(1.0, 1.0));
                
        assert(vec3(1.0f, 2.0f, 3.0f) == vec3(1.0f, 2.0f, 3.0f));
        assert(vec3(1.0f, 2.0f, 3.0f) != vec3(1.0f, 2.0f, 2.0f));
        assert(vec3(1.0f, 2.0f, 3.0f) == vec3d(1.0, 2.0, 3.0));
        assert(vec3(1.0f, 2.0f, 3.0f) != vec3d(1.0, 2.0, 2.0));
                
        assert(vec4(1.0f, 2.0f, 3.0f, 4.0f) == vec4(1.0f, 2.0f, 3.0f, 4.0f));
        assert(vec4(1.0f, 2.0f, 3.0f, 4.0f) != vec4(1.0f, 2.0f, 3.0f, 3.0f));
        assert(vec4(1.0f, 2.0f, 3.0f, 4.0f) == vec4d(1.0, 2.0, 3.0, 4.0));
        assert(vec4(1.0f, 2.0f, 3.0f, 4.0f) != vec4d(1.0, 2.0, 3.0, 3.0));
    
        assert(!(vec4(float.nan)));
        if(vec4(1.0f)) { }
        else { assert(false); }
    }
        
}
    
alias Vector!(float, 2) vec2;
alias Vector!(float, 3) vec3;
alias Vector!(float, 4) vec4;

alias Vector!(double, 2) vec2d;
alias Vector!(double, 3) vec3d;
alias Vector!(double, 4) vec4d;

alias Vector!(int, 2) vec2i;
alias Vector!(int, 3) vec3i;
alias Vector!(int, 4) vec4i;

/*alias Vector!(ubyte, 2) vec2ub;
alias Vector!(ubyte, 3) vec3ub;
alias Vector!(ubyte, 4) vec4ub;*/


// The matrix has you...
struct Matrix(type, int rows_, int cols_) if((rows_ > 0) && (cols_ > 0)) {
    alias type mt;
    static const int rows = rows_;
    static const int cols = cols_;
    
    // row-major layout, in memory
    mt[cols][rows] matrix; // In C it would be mt[rows][cols], D does it like this: (mt[foo])[bar]
    alias matrix this;
    
    unittest {
        mat2 m2 = mat2(0.0f, 1.0f, 2.0f, 3.0f);
        assert(m2[0][0] == 0.0f);
        assert(m2[0][1] == 1.0f);
        assert(m2[1][0] == 2.0f);
        assert(m2[1][1] == 3.0f);
        m2[0..1] = [2.0f, 2.0f];
        assert(m2 == [[2.0f, 2.0f], [2.0f, 3.0f]]);
        
        mat3 m3 = mat3(0.0f, 0.1f, 0.2f, 1.0f, 1.1f, 1.2f, 2.0f, 2.1f, 2.2f);
        assert(m3[0][1] == 0.1f);
        assert(m3[2][0] == 2.0f);
        assert(m3[1][2] == 1.2f);
        m3[0][0..$] = 0.0f;
        assert(m3 == [[0.0f, 0.0f, 0.0f],
                      [1.0f, 1.1f, 1.2f],
                      [2.0f, 2.1f, 2.2f]]);
        
        mat4 m4 = mat4(0.0f, 0.1f, 0.2f, 0.3f,
                       1.0f, 1.1f, 1.2f, 1.3f,
                       2.0f, 2.1f, 2.2f, 2.3f,
                       3.0f, 3.1f, 3.2f, 3.3f);
       assert(m4[0][3] == 0.3f);
       assert(m4[1][1] == 1.1f);
       assert(m4[2][0] == 2.0f);
       assert(m4[3][2] == 3.2f);
       m4[2][1..3] = [1.0f, 2.0f];
       assert(m4 == [[0.0f, 0.1f, 0.2f, 0.3f],
                     [1.0f, 1.1f, 1.2f, 1.3f],
                     [2.0f, 1.0f, 2.0f, 2.3f],
                     [3.0f, 3.1f, 3.2f, 3.3f]]);
       
    }

    @property auto value_ptr() { return matrix[0].ptr; }
    
    static void isCompatibleMatrixImpl(int r, int c)(Matrix!(mt, r, c) m) {
    }

    template isCompatibleMatrix(T) {
        enum isCompatibleMatrix = is(typeof(isCompatibleMatrixImpl(T.init)));
    }
    
    static void isCompatibleVectorImpl(int d)(Vector!(mt, d) vec) {
    }

    template isCompatibleVector(T) {
        enum isCompatibleVector = is(typeof(isCompatibleVectorImpl(T.init)));
    }
        
    private void construct(int i, T, Tail...)(T head, Tail tail) {
        static if(i >= rows*cols) {
            static assert(false, "constructor has too many arguments");
        } else static if(is(T : mt)) {
            matrix[i / cols][i % cols] = head;
            construct!(i + 1)(tail);
        } else static if(is(T == Vector!(mt, cols))) {
            static if(i % cols == 0) {
                matrix[i / cols] = head.vector;
                construct!(i + T.dimension)(tail);
            } else {
                static assert(false, "Can't convert Vector into the matrix. Maybe it doesn't align to the columns correctly or dimension doesn't fit");
            }
        } else {
            static assert(false, "Matrix constructor argument must be of type " ~ mt.stringof ~ " or Vector, not " ~ T.stringof);
        }
    }
    
    private void construct(int i)() { // terminate
    }
    
    this(Args...)(Args args) {
        static if((args.length == 1) && is(Args[0] : mt)) {
            clear(args[0]);
        } else {
            construct!(0)(args);
        }
    }
    
    @property bool ok() {
        foreach(row; matrix) {
            foreach(col; row) {
                if(isNaN(col)) {
                    return false;
                }
            }
        }
        return true;
    }
    
    void clear(mt value) {
        for(int r = 0; r < rows; r++) {
            for(int c = 0; c < cols; c++) {
                matrix[r][c] = value;
            }
        }
    }
    
    unittest {
        mat2 m2 = mat2(1.0f, 1.0f, vec2(2.0f, 2.0f));
        assert(m2.matrix == [[1.0f, 1.0f], [2.0f, 2.0f]]);
        m2.clear(3.0f);
        assert(m2.matrix == [[3.0f, 3.0f], [3.0f, 3.0f]]);
        assert(m2.ok);
        m2.clear(float.nan);
        assert(!m2.ok);
        
        mat3 m3 = mat3(1.0f);
        assert(m3.matrix == [[1.0f, 1.0f, 1.0f],
                             [1.0f, 1.0f, 1.0f],
                             [1.0f, 1.0f, 1.0f]]);
        
        mat4 m4 = mat4(vec4(1.0f, 1.0f, 1.0f, 1.0f),
                            2.0f, 2.0f, 2.0f, 2.0f,
                            3.0f, 3.0f, 3.0f, 3.0f,
                       vec4(4.0f, 4.0f, 4.0f, 4.0f));
        assert(m4.matrix == [[1.0f, 1.0f, 1.0f, 1.0f],
                             [2.0f, 2.0f, 2.0f, 2.0f],
                             [3.0f, 3.0f, 3.0f, 3.0f],
                             [4.0f, 4.0f, 4.0f, 4.0f]]);

        Matrix!(float, 2, 3) mt1 = Matrix!(float, 2, 3)(1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f);
        Matrix!(float, 3, 2) mt2 = Matrix!(float, 3, 2)(6.0f, -1.0f, 3.0f, 2.0f, 0.0f, -3.0f);
        
        assert(mt1.matrix == [[1.0f, 2.0f, 3.0f], [4.0f, 5.0f, 6.0f]]);
        assert(mt2.matrix == [[6.0f, -1.0f], [3.0f, 2.0f], [0.0f, -3.0f]]);
    }
    
    @property string as_string() {
        return format(isFloatingPoint!(mt) ? "%f":"%s", matrix);
    }
    alias as_string toString;
    
    @property string as_pretty_string() {
        string fmtr = isFloatingPoint!(mt) ? "%f":"%s";
        
        size_t rjust = max(format(fmtr, reduce!(max)(matrix[])).length,
                           format(fmtr, reduce!(min)(matrix[])).length) - 1;
        
        string[] outer_parts;
        foreach(mt[] row; matrix) {
            string[] inner_parts;
            foreach(mt col; row) {
                inner_parts ~= rightJustify(format(fmtr, col), rjust);
            }
            outer_parts ~= " [" ~ join(inner_parts, ", ") ~ "]";
        }
        
        return "[" ~ join(outer_parts, "\n")[1..$] ~ "]";
    }
    
    static if(rows == cols) {
        void make_identity() {
            clear(0);
            for(int r = 0; r < rows; r++) {
                matrix[r][r] = 1;
            }
        }
        
        static @property Matrix identity() {
            Matrix ret;
            ret.clear(0);
            
            for(int r = 0; r < rows; r++) {
                ret.matrix[r][r] = 1;
            }
            
            return ret;
        }
        
        void transpose() {
            matrix = transposed().matrix;
        }
        
        unittest {
            mat2 m2 = mat2(1.0f);
            m2.transpose();
            assert(m2.matrix == mat2(1.0f).matrix);
            m2.make_identity();
            assert(m2.matrix == [[1.0f, 0.0f],
                                 [0.0f, 1.0f]]);
            m2.transpose();
            assert(m2.matrix == [[1.0f, 0.0f],
                                 [0.0f, 1.0f]]);
            assert(m2.matrix == m2.identity.matrix);
            
            mat3 m3 = mat3(1.1f, 1.2f, 1.3f,
                           2.1f, 2.2f, 2.3f,
                           3.1f, 3.2f, 3.3f);
            m3.transpose();
            assert(m3.matrix == [[1.1f, 2.1f, 3.1f],
                                 [1.2f, 2.2f, 3.2f],
                                 [1.3f, 2.3f, 3.3f]]);
            
            mat4 m4 = mat4(2.0f);
            m4.transpose();
            assert(m4.matrix == mat4(2.0f).matrix);
            m4.make_identity();
            assert(m4.matrix == [[1.0f, 0.0f, 0.0f, 0.0f],
                                 [0.0f, 1.0f, 0.0f, 0.0f],
                                 [0.0f, 0.0f, 1.0f, 0.0f],
                                 [0.0f, 0.0f, 0.0f, 1.0f]]);
            assert(m4.matrix == m4.identity.matrix);
        }
        
    }
       
    @property Matrix transposed() {
        Matrix ret;
        
        for(int r = 0; r < rows; r++) {
            for(int c = 0; c < cols; c++) {
                ret.matrix[c][r] = matrix[r][c];
            }
        }
        
        return ret;
    }
    
    // transposed already tested in last unittest
    
    static if((rows == 2) && (cols == 2)) {
        @property mt det() {
            return (matrix[0][0] * matrix[1][1] - matrix[0][1] * matrix[1][0]);
        }
        
        private Matrix invert(ref Matrix mat) {
            mt d = det;
            
            mat.matrix = [[matrix[1][1]/det, -matrix[0][1]/d],
                          [-matrix[1][0]/det, matrix[0][0]/d]];
            
            return mat;
        }
    } else static if((rows == 3) && (cols == 3)) {
        @property mt det() {
            return (matrix[0][0] * matrix[1][1] * matrix[2][2]
                  + matrix[0][1] * matrix[1][2] * matrix[2][0]
                  + matrix[0][2] * matrix[1][0] * matrix[2][1]
                  - matrix[0][2] * matrix[1][1] * matrix[2][0]
                  - matrix[0][1] * matrix[1][0] * matrix[2][2]
                  - matrix[0][0] * matrix[1][2] * matrix[2][1]);
        }
        
        private Matrix invert(ref Matrix mat) {
            mt d = det;
            
            mat.matrix = [[(matrix[1][1] * matrix[2][2] - matrix[1][2] * matrix[2][1])/d,
                           (matrix[0][2] * matrix[2][1] - matrix[0][1] * matrix[2][2])/d,
                           (matrix[0][1] * matrix[1][2] - matrix[0][2] * matrix[1][1])/d],
                          [(matrix[1][2] * matrix[2][0] - matrix[1][0] * matrix[2][2])/d,
                           (matrix[0][0] * matrix[2][2] - matrix[0][2] * matrix[2][0])/d,
                           (matrix[0][2] * matrix[1][0] - matrix[0][0] * matrix[1][2])/d],
                          [(matrix[1][0] * matrix[2][1] - matrix[1][1] * matrix[2][0])/d,
                           (matrix[0][1] * matrix[2][0] - matrix[0][0] * matrix[2][1])/d,
                           (matrix[0][0] * matrix[1][1] - matrix[0][1] * matrix[1][0])/d]];
            
            return mat;
        }

        static Matrix translate(mt x, mt y) {
           Matrix ret = Matrix.identity;
           
           ret.matrix[0][2] = x;
           ret.matrix[1][2] = y;
           
           return ret;            
        }
        
        static Matrix scale(mt x, mt y) {
            Matrix ret = Matrix.identity;
            
            ret.matrix[0][0] = x;
            ret.matrix[1][1] = y;
            
            return ret;
        }

    } else static if((rows == 4) && (cols == 4)) {
        @property mt det() {
            return (matrix[0][3] * matrix[1][2] * matrix[2][1] * matrix[3][0] - matrix[0][2] * matrix[1][3] * matrix[2][1] * matrix[3][0]
                  - matrix[0][3] * matrix[1][1] * matrix[2][2] * matrix[3][0] + matrix[0][1] * matrix[1][3] * matrix[2][2] * matrix[3][0]
                  + matrix[0][2] * matrix[1][1] * matrix[2][3] * matrix[3][0] - matrix[0][1] * matrix[1][2] * matrix[2][3] * matrix[3][0]
                  - matrix[0][3] * matrix[1][2] * matrix[2][0] * matrix[3][1] + matrix[0][2] * matrix[1][3] * matrix[2][0] * matrix[3][1]
                  + matrix[0][3] * matrix[1][0] * matrix[2][2] * matrix[3][1] - matrix[0][0] * matrix[1][3] * matrix[2][2] * matrix[3][1]
                  - matrix[0][2] * matrix[1][0] * matrix[2][3] * matrix[3][1] + matrix[0][0] * matrix[1][2] * matrix[2][3] * matrix[3][1]
                  + matrix[0][3] * matrix[1][1] * matrix[2][0] * matrix[3][2] - matrix[0][1] * matrix[1][3] * matrix[2][0] * matrix[3][2]
                  - matrix[0][3] * matrix[1][0] * matrix[2][1] * matrix[3][2] + matrix[0][0] * matrix[1][3] * matrix[2][1] * matrix[3][2]
                  + matrix[0][1] * matrix[1][0] * matrix[2][3] * matrix[3][2] - matrix[0][0] * matrix[1][1] * matrix[2][3] * matrix[3][2]
                  - matrix[0][2] * matrix[1][1] * matrix[2][0] * matrix[3][3] + matrix[0][1] * matrix[1][2] * matrix[2][0] * matrix[3][3]
                  + matrix[0][2] * matrix[1][0] * matrix[2][1] * matrix[3][3] - matrix[0][0] * matrix[1][2] * matrix[2][1] * matrix[3][3]
                  - matrix[0][1] * matrix[1][0] * matrix[2][2] * matrix[3][3] + matrix[0][0] * matrix[1][1] * matrix[2][2] * matrix[3][3]);
        }

        private Matrix invert(ref Matrix mat) {
            mt d = det;
            
            mat.matrix = [[(matrix[1][1] * matrix[2][2] * matrix[3][3] + matrix[1][2] * matrix[2][3] * matrix[3][1] + matrix[1][3] * matrix[2][1] * matrix[3][2]
                          - matrix[1][1] * matrix[2][3] * matrix[3][2] - matrix[1][2] * matrix[2][1] * matrix[3][3] - matrix[1][3] * matrix[2][2] * matrix[3][1])/d,
                           (matrix[0][1] * matrix[2][3] * matrix[3][2] + matrix[0][2] * matrix[2][1] * matrix[3][3] + matrix[0][3] * matrix[2][2] * matrix[3][1]
                          - matrix[0][1] * matrix[2][2] * matrix[3][3] - matrix[0][2] * matrix[2][3] * matrix[3][1] - matrix[0][3] * matrix[2][1] * matrix[3][2])/d,
                           (matrix[0][1] * matrix[1][2] * matrix[3][3] + matrix[0][2] * matrix[1][3] * matrix[3][1] + matrix[0][3] * matrix[1][1] * matrix[3][2]
                          - matrix[0][1] * matrix[1][3] * matrix[3][2] - matrix[0][2] * matrix[1][1] * matrix[3][3] - matrix[0][3] * matrix[1][2] * matrix[3][1])/d,
                           (matrix[0][1] * matrix[1][3] * matrix[2][2] + matrix[0][2] * matrix[1][1] * matrix[2][3] + matrix[0][3] * matrix[1][2] * matrix[2][1]
                          - matrix[0][1] * matrix[1][2] * matrix[2][3] - matrix[0][2] * matrix[1][3] * matrix[2][1] - matrix[0][3] * matrix[1][1] * matrix[2][2])/d],
                          [(matrix[1][0] * matrix[2][3] * matrix[3][2] + matrix[1][2] * matrix[2][0] * matrix[3][3] + matrix[1][3] * matrix[2][2] * matrix[3][0]
                          - matrix[1][0] * matrix[2][2] * matrix[3][3] - matrix[1][2] * matrix[2][3] * matrix[3][0] - matrix[1][3] * matrix[2][0] * matrix[3][2])/d,
                           (matrix[0][0] * matrix[2][2] * matrix[3][3] + matrix[0][2] * matrix[2][3] * matrix[3][0] + matrix[0][3] * matrix[2][0] * matrix[3][2]
                          - matrix[0][0] * matrix[2][3] * matrix[3][2] - matrix[0][2] * matrix[2][0] * matrix[3][3] - matrix[0][3] * matrix[2][2] * matrix[3][0])/d,
                           (matrix[0][0] * matrix[1][3] * matrix[3][2] + matrix[0][2] * matrix[1][0] * matrix[3][3] + matrix[0][3] * matrix[1][2] * matrix[3][0]
                          - matrix[0][0] * matrix[1][2] * matrix[3][3] - matrix[0][2] * matrix[1][3] * matrix[3][0] - matrix[0][3] * matrix[1][0] * matrix[3][2])/d,
                           (matrix[0][0] * matrix[1][2] * matrix[2][3] + matrix[0][2] * matrix[1][3] * matrix[2][0] + matrix[0][3] * matrix[1][0] * matrix[2][2]
                          - matrix[0][0] * matrix[1][3] * matrix[2][2] - matrix[0][2] * matrix[1][0] * matrix[2][3] - matrix[0][3] * matrix[1][2] * matrix[2][0])/d],
                          [(matrix[1][0] * matrix[2][1] * matrix[3][3] + matrix[1][1] * matrix[2][3] * matrix[3][0] + matrix[1][3] * matrix[2][0] * matrix[3][1]
                          - matrix[1][0] * matrix[2][3] * matrix[3][1] - matrix[1][1] * matrix[2][0] * matrix[3][3] - matrix[1][3] * matrix[2][1] * matrix[3][0])/d,
                           (matrix[0][0] * matrix[2][3] * matrix[3][1] + matrix[0][1] * matrix[2][0] * matrix[3][3] + matrix[0][3] * matrix[2][1] * matrix[3][0]
                          - matrix[0][0] * matrix[2][1] * matrix[3][3] - matrix[0][1] * matrix[2][3] * matrix[3][0] - matrix[0][3] * matrix[2][0] * matrix[3][1])/d,
                           (matrix[0][0] * matrix[1][1] * matrix[3][3] + matrix[0][1] * matrix[1][3] * matrix[3][0] + matrix[0][3] * matrix[1][0] * matrix[3][1]
                          - matrix[0][0] * matrix[1][3] * matrix[3][1] - matrix[0][1] * matrix[1][0] * matrix[3][3] - matrix[0][3] * matrix[1][1] * matrix[3][0])/d,
                           (matrix[0][0] * matrix[1][3] * matrix[2][1] + matrix[0][1] * matrix[1][0] * matrix[2][3] + matrix[0][3] * matrix[1][1] * matrix[2][0]
                          - matrix[0][0] * matrix[1][1] * matrix[2][3] - matrix[0][1] * matrix[1][3] * matrix[2][0] - matrix[0][3] * matrix[1][0] * matrix[2][1])/d],
                          [(matrix[1][0] * matrix[2][2] * matrix[3][1] + matrix[1][1] * matrix[2][0] * matrix[3][2] + matrix[1][2] * matrix[2][1] * matrix[3][0]
                          - matrix[1][0] * matrix[2][1] * matrix[3][2] - matrix[1][1] * matrix[2][2] * matrix[3][0] - matrix[1][2] * matrix[2][0] * matrix[3][1])/d,
                           (matrix[0][0] * matrix[2][1] * matrix[3][2] + matrix[0][1] * matrix[2][2] * matrix[3][0] + matrix[0][2] * matrix[2][0] * matrix[3][1]
                          - matrix[0][0] * matrix[2][2] * matrix[3][1] - matrix[0][1] * matrix[2][0] * matrix[3][2] - matrix[0][2] * matrix[2][1] * matrix[3][0])/d,
                           (matrix[0][0] * matrix[1][2] * matrix[3][1] + matrix[0][1] * matrix[1][0] * matrix[3][2] + matrix[0][2] * matrix[1][1] * matrix[3][0]
                          - matrix[0][0] * matrix[1][1] * matrix[3][2] - matrix[0][1] * matrix[1][2] * matrix[3][0] - matrix[0][2] * matrix[1][0] * matrix[3][1])/d,
                           (matrix[0][0] * matrix[1][1] * matrix[2][2] + matrix[0][1] * matrix[1][2] * matrix[2][0] + matrix[0][2] * matrix[1][0] * matrix[2][1]
                          - matrix[0][0] * matrix[1][2] * matrix[2][1] - matrix[0][1] * matrix[1][0] * matrix[2][2] - matrix[0][2] * matrix[1][1] * matrix[2][0])/d]];
                  
            return mat;
        }
        
        // some static fun ...
        // 4glprogramming.com/red/appendixf.html
        static Matrix translate(mt x, mt y, mt z) {
           Matrix ret = Matrix.identity;
           
           ret.matrix[0][3] = x;
           ret.matrix[1][3] = y;
           ret.matrix[2][3] = z;
           
           return ret;            
        }
        
        static Matrix scale(mt x, mt y, mt z) {
            Matrix ret = Matrix.identity;

            ret.matrix[0][0] = x;
            ret.matrix[1][1] = y;
            ret.matrix[2][2] = z;
            
            return ret;
        }
              
        unittest {
            mat4 m4 = mat4(1.0f);
            assert(m4.translate(1.0f, 2.0f, 3.0f).matrix == mat4.translate(1.0f, 2.0f, 3.0f).matrix);
            assert(mat4.translate(1.0f, 2.0f, 3.0f).matrix == [[1.0f, 0.0f, 0.0f, 1.0f],
                                                               [0.0f, 1.0f, 0.0f, 2.0f],
                                                               [0.0f, 0.0f, 1.0f, 3.0f],
                                                               [0.0f, 0.0f, 0.0f, 1.0f]]);
            
            assert(m4.scale(0.0f, 1.0f, 2.0f).matrix == mat4.scale(0.0f, 1.0f, 2.0f).matrix);
            assert(mat4.scale(0.0f, 1.0f, 2.0f).matrix == [[0.0f, 0.0f, 0.0f, 0.0f],
                                                           [0.0f, 1.0f, 0.0f, 0.0f],
                                                           [0.0f, 0.0f, 2.0f, 0.0f],
                                                           [0.0f, 0.0f, 0.0f, 1.0f]]);
        }
        
        static if(isFloatingPoint!mt) {
            static private mt[6] cperspective(mt width, mt height, mt fov, mt near, mt far) {
                mt aspect = width/height;
                mt top = near * tan(fov*(PI/360.0));
                mt bottom = -top;
                mt right = top * aspect;
                mt left = -right;
                
                return [left, right, bottom, top, near, far];
            }
            
            static Matrix perspective(mt width, mt height, mt fov = 60.0, mt near = 1.0, mt far = 100.0) {
                mt[6] cdata = cperspective(width, height, fov, near, far);
                return perspective(cdata[0], cdata[1], cdata[2], cdata[3], cdata[4], cdata[5]);
            }
            
            static Matrix perspective(mt left, mt right, mt bottom, mt top, mt near, mt far) {
                Matrix ret;
                ret.clear(0);
                
                ret.matrix[0][0] = (2*near)/(right-left);
                ret.matrix[0][2] = (right+left)/(right-left);
                ret.matrix[1][1] = (2*near)/(top-bottom);
                ret.matrix[1][2] = (top+bottom)/(top-bottom);
                ret.matrix[2][2] = -(far+near)/(far-near);
                ret.matrix[2][3] = -(2*far*near)/(far-near);
                ret.matrix[3][2] = -1;
                
                return ret;
            }
            
            static Matrix perspective_inverse(mt width, mt height, mt fov = 60.0, mt near = 1.0, mt far = 100.0) {
                mt[6] cdata = cperspective(width, height, fov, near, far);
                return perspective_inverse(cdata[0], cdata[1], cdata[2], cdata[3], cdata[4], cdata[5]);
            }
            
            static Matrix perspective_inverse(mt left, mt right, mt bottom, mt top, mt near, mt far) {
                Matrix ret;
                ret.clear(0);
                
                ret.matrix[0][0] = (right-left)/(2*near);
                ret.matrix[0][3] = (right+left)/(2*near);
                ret.matrix[1][1] = (top-bottom)/(2*near);
                ret.matrix[1][3] = (top+bottom)/(2*near);
                ret.matrix[2][3] = -1;
                ret.matrix[3][2] = -(far-near)/(2*far*near);
                ret.matrix[3][3] = (far+near)/(2*far*near);
                
                return ret;
            }
            
            static Matrix orthographic(mt left, mt right, mt bottom, mt top, mt near, mt far) {
                Matrix ret;
                ret.clear(0);
                
                ret.matrix[0][0] = 2/(right-left);
                ret.matrix[0][3] = (right+left)/(right-left);
                ret.matrix[1][1] = 2/(top-bottom);
                ret.matrix[1][3] = (top+bottom)/(top-bottom);
                ret.matrix[2][2] = -2/(far-near);
                ret.matrix[2][3] = (far+near)/(far-near);
                ret.matrix[3][3] = 1;
                
                return ret;
            }
            
            static Matrix orthographic_inverse(mt left, mt right, mt bottom, mt top, mt near, mt far) {
                Matrix ret;
                ret.clear(0);
                
                ret.matrix[0][0] = (right-left)/2;
                ret.matrix[0][3] = (right+left)/2;
                ret.matrix[1][1] = (top-bottom)/2;
                ret.matrix[1][3] = (top+bottom)/2;
                ret.matrix[2][2] = (far-near)/-2;
                ret.matrix[2][3] = (far+near)/2;
                ret.matrix[3][3] = 1;
                
                return ret;
            }
            
            static Matrix look_at(Vector!(mt, 3) eye, Vector!(mt, 3) target, Vector!(mt, 3) up) {
                alias Vector!(mt, 3) vec3mt;
                vec3mt look_dir = (target - eye).normalized;
                vec3mt up_dir = up.normalized;
                
                vec3mt right_dir = vec3mt.cross(look_dir, up_dir).normalized;
                vec3mt perp_up_dir = vec3mt.cross(right_dir, look_dir);
                
                Matrix rot = Matrix.identity;
                rot.matrix[0][0..3] = right_dir.vector;
                rot.matrix[1][0..3] = perp_up_dir.vector;
                rot.matrix[2][0..3] = (-look_dir).vector;
                
                Matrix trans = Matrix.translate(-eye.x, -eye.y, -eye.z);
                
                return rot * trans;
            }
        
            unittest {               
                mt[6] cp = cperspective(600f, 900f, 60f, 1f, 100f);
                assert(cp[4] == 1.0f);
                assert(cp[5] == 100.0f);
                assert(cp[0] == -cp[1]);
                assert((cp[0] < -0.38489f) && (cp[0] > -0.38491f));
                assert(cp[2] == -cp[3]);
                assert((cp[2] < -0.577349f) && (cp[2] > -0.577351f));
                
                assert(mat4.perspective(600f, 900f) == mat4.perspective(cp[0], cp[1], cp[2], cp[3], cp[4], cp[5]));
                float[4][4] m4p = mat4.perspective(600f, 900f).matrix;
                assert((m4p[0][0] < 2.598077f) && (m4p[0][0] > 2.598075f));
                assert(m4p[0][2] == 0.0f);
                assert((m4p[1][1] < 1.732052) && (m4p[1][1] > 1.732050));
                assert(m4p[1][2] == 0.0f);
                assert((m4p[2][2] < -1.020201) && (m4p[2][2] > -1.020203));
                assert((m4p[2][3] < -2.020201) && (m4p[2][3] > -2.020203));
                assert((m4p[3][2] < -0.9f) && (m4p[3][2] > -1.1f));
                
                float[4][4] m4pi = mat4.perspective_inverse(600f, 900f).matrix;
                assert((m4pi[0][0] < 0.384901) && (m4pi[0][0] > 0.384899));
                assert(m4pi[0][3] == 0.0f);
                assert((m4pi[1][1] < 0.577351) && (m4pi[1][1] > 0.577349));
                assert(m4pi[1][3] == 0.0f);
                assert(m4pi[2][3] == -1.0f);
                assert((m4pi[3][2] < -0.494999) && (m4pi[3][2] > -0.495001));
                assert((m4pi[3][3] < 0.505001) && (m4pi[3][3] > 0.504999));

                // maybe the next tests should be improved
                float[4][4] m4o = mat4.orthographic(-1.0f, 1.0f, -1.0f, 1.0f, -1.0f, 1.0f).matrix;
                assert(m4o == [[1.0f, 0.0f, 0.0f, 0.0f],
                               [0.0f, 1.0f, 0.0f, 0.0f],
                               [0.0f, 0.0f, -1.0f, 0.0f],
                               [0.0f, 0.0f, 0.0f, 1.0f]]);
               
                float[4][4] m4oi = mat4.orthographic_inverse(-1.0f, 1.0f, -1.0f, 1.0f, -1.0f, 1.0f).matrix;
                assert(m4oi == [[1.0f, 0.0f, 0.0f, 0.0f],
                                [0.0f, 1.0f, 0.0f, 0.0f],
                                [0.0f, 0.0f, -1.0f, 0.0f],
                                [0.0f, 0.0f, 0.0f, 1.0f]]);
                                
                //TODO: look_at tests
            }
        
        }
        
    }

    static if((rows == cols) && (rows >= 3)) {
        static Matrix rotatex(real alpha) {
            Matrix ret = Matrix.identity;
            
            mt cosamt = to!mt(cos(alpha));
            mt sinamt = to!mt(sin(alpha));
            
            ret.matrix[1][1] = cosamt;
            ret.matrix[1][2] = -sinamt;
            ret.matrix[2][1] = sinamt;
            ret.matrix[2][2] = cosamt;

            return ret;
        }

        static Matrix rotatey(real alpha) {
            Matrix ret = Matrix.identity;
            
            mt cosamt = to!mt(cos(alpha));
            mt sinamt = to!mt(sin(alpha));
            
            ret.matrix[0][0] = cosamt;
            ret.matrix[0][2] = sinamt;
            ret.matrix[2][0] = -sinamt;
            ret.matrix[0][2] = cosamt;

            return ret;
        }

        static Matrix rotatez(real alpha) {
            Matrix ret = Matrix.identity;
            
            mt cosamt = to!mt(cos(alpha));
            mt sinamt = to!mt(sin(alpha));
            
            ret.matrix[0][0] = cosamt;
            ret.matrix[0][1] = -sinamt;
            ret.matrix[1][0] = sinamt;
            ret.matrix[1][1] = cosamt;

            return ret;
        }
        
        unittest {
            assert(mat4.rotatex(0).matrix == [[1.0f, 0.0f, 0.0f, 0.0f],
                                              [0.0f, 1.0f, -0.0f, 0.0f],
                                              [0.0f, 0.0f, 1.0f, 0.0f],
                                              [0.0f, 0.0f, 0.0f, 1.0f]]);
            assert(mat4.rotatey(0).matrix == [[1.0f, 0.0f, 1.0f, 0.0f],
                                              [0.0f, 1.0f, 0.0f, 0.0f],
                                              [-0.0f, 0.0f, 1.0f, 0.0f],
                                              [0.0f, 0.0f, 0.0f, 1.0f]]);
            assert(mat4.rotatez(0).matrix == [[1.0f, -0.0f, 0.0f, 0.0f],
                                              [0.0f, 1.0f, 0.0f, 0.0f],
                                              [0.0f, 0.0f, 1.0f, 0.0f],
                                              [0.0f, 0.0f, 0.0f, 1.0f]]);
        }
        
        void scale(mt[] values...) {
            assert(values.length >= (rows-1));
            
            for(int r = 0; r < (rows-1); r++) {
                matrix[r][r] = values[r];
            }
        }
        
        /*@property*/ void scale(Matrix mat) { // dmd suckz!
            for(int r = 0; r < (rows-1); r++) {
                matrix[r][r] = mat.matrix[r][r];
            }
        }
        
        /*@property*/ Matrix scale() { 
            Matrix ret = Matrix.identity;
            
            for(int r = 0; r < (rows-1); r++) {
                ret.matrix[r][r] = matrix[r][r];
            }
            
            return ret;
        }
        
        unittest {
            mat3 m3 = mat3(0.0f, 1.0f, 2.0f,
                           3.0f, 4.0f, 5.0f,
                           6.0f, 7.0f, 1.0f);
            assert(m3.scale.matrix == [[0.0f, 0.0f, 0.0f], [0.0f, 4.0f, 0.0f], [0.0f, 0.0f, 1.0f]]);
            m3.scale = mat3.identity;
            assert(mat3.identity.matrix == m3.scale.matrix);
            m3.scale = [0.0f, 4.0f];
            assert(m3.scale.matrix == [[0.0f, 0.0f, 0.0f], [0.0f, 4.0f, 0.0f], [0.0f, 0.0f, 1.0f]]);
            assert(mat3.identity.matrix == mat3.identity.scale.matrix);

            mat4 m4 = mat4(0.0f, 1.0f, 2.0f, 3.0f,
                           4.0f, 5.0f, 6.0f, 7.0f,
                           8.0f, 9.0f, 10.0f, 11.0f,
                           12.0f, 13.0f, 14.0f, 1.0f);
            assert(m4.scale.matrix == [[0.0f, 0.0f, 0.0f, 0.0f],
                                       [0.0f, 5.0f, 0.0f, 0.0f],
                                       [0.0f, 0.0f, 10.0f, 0.0f],
                                       [0.0f, 0.0f, 0.0f, 1.0f]]);
            m4.scale = mat4.identity;
            assert(mat4.identity.matrix == m4.scale.matrix);
            m4.scale = [0.0f, 5.0f, 10.0f];
            assert(m4.scale.matrix == [[0.0f, 0.0f, 0.0f, 0.0f],
                                       [0.0f, 5.0f, 0.0f, 0.0f],
                                       [0.0f, 0.0f, 10.0f, 0.0f],
                                       [0.0f, 0.0f, 0.0f, 1.0f]]);
            assert(mat4.identity.matrix == mat4.identity.scale.matrix);
        }
        
    }
    
    static if((rows == cols) && (rows <= 4)) {
        @property Matrix inverse() {
            Matrix mat;
            invert(mat);
            return mat;
        }
        
        void invert() {
            invert(this);
        }
    }
    
    unittest {
        mat2 m2 = mat2(1.0f, 2.0f, vec2(3.0f, 4.0f));
        assert(m2.det == -2.0f);
        assert(m2.inverse.matrix == [[-2.0f, 1.0f], [1.5f, -0.5f]]);
        
        mat3 m3 = mat3(1.0f, -2.0f, 3.0f,
                       7.0f, -1.0f, 0.0f,
                       3.0f, 2.0f, -4.0f);
        assert(m3.det == -1.0f);
        assert(m3.inverse.matrix == [[-4.0f, 2.0f, -3.0f],
                                     [-28.0f, 13.0f, -21.0f],
                                     [-17.0f, 8.0f, -13.0f]]);

        mat4 m4 = mat4(1.0f, 2.0f, 3.0f, 4.0f,
                       -2.0f, 1.0f, 5.0f, -2.0f,
                       2.0f, -1.0f, 7.0f, 1.0f,
                       3.0f, -3.0f, 2.0f, 0.0f);
        assert(m4.det == -8.0f);
        assert(m4.inverse.matrix == [[6.875f, 7.875f, -11.75f, 11.125f],
                                     [6.625f, 7.625f, -11.25f, 10.375f],
                                     [-0.375f, -0.375f, 0.75f, -0.625f],
                                     [-4.5f, -5.5f, 8.0f, -7.5f]]);
    }

    private void mms(mt inp, ref Matrix mat) {
        for(int r = 0; r < rows; r++) {
            for(int c = 0; c < cols; c++) {
                mat.matrix[r][c] = matrix[r][c] * inp;
            }
        }
    }

    private void masm(string op)(Matrix inp, ref Matrix mat) {
        for(int r = 0; r < rows; r++) {
            for(int c = 0; c < cols; c++) {
                mat.matrix[r][c] = mixin("inp.matrix[r][c]" ~ op ~ "matrix[r][c]");
            }
        }
    }
    
    Matrix!(mt, rows, T.cols) opBinary(string op : "*", T)(T inp) if(isCompatibleMatrix!T && (T.rows == cols)) {
        Matrix!(mt, rows, T.cols) ret;
        
        for(int r = 0; r < rows; r++) { 
            for(int c = 0; c < T.cols; c++) {
                ret.matrix[r][c] = 0;
                for(int c2 = 0; c2 < cols; c2++) {
                    ret.matrix[r][c] += matrix[r][c2] * inp.matrix[c2][c];
                }
            }
        }
        
        return ret;
    }
    
    Vector!(mt, rows) opBinary(string op : "*", T : Vector!(mt, cols))(T inp) {
        Vector!(mt, rows) ret;
        ret.clear(0);
        
        for(int r = 0; r < rows; r++) {
            for(int c = 0; c < cols; c++) {
                ret.vector[r] += matrix[r][c] * inp.vector[c];
            }
        }
        
        return ret;
    }
    
    Matrix opBinary(string op : "*", T : mt)(T inp) {
        Matrix ret;
        mms(inp, ret);
        return ret;       
    }
    
    Matrix opBinary(string op, T : Matrix)(T inp) if((op == "+") || (op == "-")) {
        Matrix ret;
        masm!(op)(inp, ret);
        return ret;
    }
    
    void opOpAssign(string op : "*", T : mt)(T inp) {
        mms(inp, this);
    }

    void opOpAssign(string op, T : Matrix)(T inp) if((op == "+") || (op == "-")) {
        masm!(op)(inp, this);
    }
    
    unittest {
        mat2 m2 = mat2(1.0f, 2.0f, 3.0f, 4.0f);
        vec2 v2 = vec2(2.0f, 2.0f);
        assert((m2*2).matrix == [[2.0f, 4.0f], [6.0f, 8.0f]]);
        m2 *= 2;
        assert(m2.matrix == [[2.0f, 4.0f], [6.0f, 8.0f]]);
        assert((m2*v2).vector == [12.0f, 28.0f]);
        assert((m2*m2).matrix == [[28.0f, 40.0f], [60.0f, 88.0f]]);
        assert((m2-m2).matrix == [[0.0f, 0.0f], [0.0f, 0.0f]]);
        assert((m2+m2).matrix == [[4.0f, 8.0f], [12.0f, 16.0f]]);
        m2 += m2;
        assert(m2.matrix == [[4.0f, 8.0f], [12.0f, 16.0f]]);
        m2 -= m2;
        assert(m2.matrix == [[0.0f, 0.0f], [0.0f, 0.0f]]);

        mat3 m3 = mat3(1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f, 7.0f, 8.0f, 9.0f);
        vec3 v3 = vec3(2.0f, 2.0f, 2.0f);
        assert((m3*2).matrix == [[2.0f, 4.0f, 6.0f], [8.0f, 10.0f, 12.0f], [14.0f, 16.0f, 18.0f]]);
        m3 *= 2;
        assert(m3.matrix == [[2.0f, 4.0f, 6.0f], [8.0f, 10.0f, 12.0f], [14.0f, 16.0f, 18.0f]]);
        assert((m3*v3).vector == [24.0f, 60.0f, 96.0f]);
        assert((m3*m3).matrix == [[120.0f, 144.0f, 168.0f], [264.0f, 324.0f, 384.0f], [408.0f, 504.0f, 600.0f]]);
        assert((m3-m3).matrix == [[0.0f, 0.0f, 0.0f], [0.0f, 0.0f, 0.0f], [0.0f, 0.0f, 0.0f]]);
        assert((m3+m3).matrix == [[4.0f, 8.0f, 12.0f], [16.0f, 20.0f, 24.0f], [28.0f, 32.0f, 36.0f]]);
        m3 += m3;
        assert(m3.matrix == [[4.0f, 8.0f, 12.0f], [16.0f, 20.0f, 24.0f], [28.0f, 32.0f, 36.0f]]);
        m3 -= m3;
        assert(m3.matrix == [[0.0f, 0.0f, 0.0f], [0.0f, 0.0f, 0.0f], [0.0f, 0.0f, 0.0f]]);
        
        //TODO: tests for mat4, mat34
    }

    // opEqual => "alias matrix this;"
    
    bool opCast(T : bool)() {
        return ok;
    }
    
    unittest {
        assert(mat2(1.0f, 2.0f, 1.0f, 1.0f) == mat2(1.0f, 2.0f, 1.0f, 1.0f));
        assert(mat2(1.0f, 2.0f, 1.0f, 1.0f) != mat2(1.0f, 1.0f, 1.0f, 1.0f));
                
        assert(mat3(1.0f) == mat3(1.0f));
        assert(mat3(1.0f) != mat3(2.0f));
                
        assert(mat4(1.0f) == mat4(1.0f));
        assert(mat4(1.0f) != mat4(2.0f));
    
        assert(!(mat4(float.nan)));
        if(mat4(1.0f)) { }
        else { assert(false); }
    }
    
}


alias Matrix!(float, 2, 2) mat2;
alias Matrix!(float, 3, 3) mat3;
alias Matrix!(float, 3, 4) mat34;
alias Matrix!(float, 4, 4) mat4;

struct Quaternion(type) {
    alias type qt;
    
    qt[4] quaternion;
    
    @property auto value_ptr() { return quaternion.ptr; }
    
    private @property qt get_(char coord)() {
        return quaternion[coord_to_index!coord];
    }
    private @property void set_(char coord)(qt value) {
        quaternion[coord_to_index!coord] = value;
    }
    
    alias get_!'x' x;
    alias set_!'x' x;
    alias get_!'y' y;
    alias set_!'y' y;
    alias get_!'z' z;
    alias set_!'z' z;
    alias get_!'w' w;
    alias set_!'w' w;

    this(qt x_, qt y_, qt z_, qt w_) {
        x = x_;
        y = y_;
        z = z_;
        w = w_;
    }
    
    this(Vector!(qt, 4) vec) {
        quaternion = vec.vector;
    }
    
    @property bool ok() {
        foreach(q; quaternion) {
            if(isNaN(q)) {
                return false;
            }
        }
        return true;
    }
       
    unittest {
        quat q1 = quat(0.0f, 0.0f, 0.0f, 1.0f);
        assert(q1.quaternion == [0.0f, 0.0f, 0.0f, 1.0f]);
        assert(q1.quaternion == quat(0.0f, 0.0f, 0.0f, 1.0f).quaternion);
        assert(q1.quaternion == quat(vec4(0.0f, 0.0f, 0.0f, 1.0f)).quaternion);
    }
    
    template coord_to_index(char c) {
        static if(c == 'x') {
            enum coord_to_index = 0;
        } else static if(c == 'y') {
            enum coord_to_index = 1;
        } else static if(c == 'z') {
            enum coord_to_index = 2;
        } else static if(c == 'w') {
            enum coord_to_index = 3;
        } else {
            static assert(false, "accepted coordinates are x, y, z and w not " ~ c ~ ".");
        }
    }
    
    @property real magnitude_squared() {
        return to!real(x^^2 + y^^2 + z^^2 + w^^2);
    }
    
    @property real magnitude() {
        return sqrt(magnitude_squared);
    }
    
    static @property Quaternion identity() {
        return Quaternion(0, 0, 0, 1);
    }
    
    void make_identity() {
        x = 0;
        y = 0;
        z = 0;
        w = 1;
    }
    
    void invert() {
        x = -x;
        y = -y;
        z = -z;
    }
    
    @property Quaternion inverse() {
        return Quaternion(-x, -y, -z, w);
    }
    
    unittest {
        quat q1 = quat(1.0f, 1.0f, 1.0f, 1.0f);
        
        assert(q1.magnitude == 2.0f);
        assert(q1.magnitude_squared == 4.0f);
        assert(q1.magnitude == quat(0.0f, 0.0f, 2.0f, 0.0f).magnitude);
        
        quat q2 = quat.identity;
        assert(q2.quaternion == [0.0f, 0.0f, 0.0f, 1.0f]);
        assert(q2.x == 0.0f);
        assert(q2.y == 0.0f);
        assert(q2.z == 0.0f);
        assert(q2.w == 1.0f);
        
        assert(q1.inverse.quaternion == [-1.0f, -1.0f, -1.0f, 1.0f]);
        q1.invert();
        assert(q1.quaternion == [-1.0f, -1.0f, -1.0f, 1.0f]);
        
        q1.make_identity();
        assert(q1.quaternion == q2.quaternion);
        
    }
    
    @property string as_string() {
        return format(isFloatingPoint!(qt) ? "%f":"%s", quaternion);
    }
    alias as_string toString;

    static Quaternion from_matrix(Matrix!(qt, 3, 3) matrix) {
        Quaternion ret;
        
        auto mat = matrix.matrix;
        qt trace = mat[0][0] + mat[1][1] + mat[2][2];
        
        if(trace > 0) {
            real s = 0.5 / sqrt(trace + 1.0);
            
            ret.w = to!qt(0.25 / s);
            ret.x = to!qt((mat[2][1] - mat[1][2]) * s);
            ret.y = to!qt((mat[0][2] - mat[2][0]) * s);
            ret.z = to!qt((mat[1][0] - mat[0][1]) * s);
        } else if((mat[0][0] > mat[1][2]) && (mat[0][0] > mat[2][2])) {
            real s = 2.0 * sqrt(1 + mat[0][0] - mat[1][1] - mat[2][2]);
            
            ret.w = to!qt((mat[2][1] - mat[1][2]) / s);
            ret.x = to!qt(0.25 * s);
            ret.y = to!qt((mat[0][1] - mat[1][0]) / s);
            ret.z = to!qt((mat[0][2] - mat[2][0]) / s);
        } else if(mat[1][1] > mat[2][2]) {
            real s = 2.0 * sqrt(1 + mat[1][1] - mat[0][0] - mat[2][2]);
            
            ret.w = to!qt((mat[0][2] - mat[2][0]) / s);
            ret.x = to!qt((mat[0][1] + mat[1][0]) / s);
            ret.y = to!qt(0.25f * s);
            ret.z = to!qt((mat[1][2] + mat[2][1]) / s);
        } else {
            real s = 2.0 * sqrt(1 + mat[2][2] - mat[0][0] - mat[1][1]);

            ret.w = to!qt((mat[1][0] - mat[0][1]) / s);
            ret.x = to!qt((mat[0][2] + mat[2][0]) / s);
            ret.y = to!qt((mat[1][2] + mat[2][1]) / s);
            ret.z = to!qt(0.25f * s);
        }
        
        return ret;
    }
    
    Matrix!(qt, rows, cols) to_matrix(int rows, int cols)() if((rows >= 3) && (cols >= 3)) {
        static if((rows == 3) && (cols == 3)) {
            Matrix!(qt, rows, cols) ret;
        } else {
            Matrix!(qt, rows, cols) ret = Matrix!(qt, rows, cols).identity;
        }
                
        qt xx = x^^2;
        qt xy = x * y;
        qt xz = x * z;
        qt xw = x * w;
        qt yy = y^^2;
        qt yz = y * z;
        qt yw = y * w;
        qt zz = z^^2;
        qt zw = z * w;
        
        ret.matrix[0][0..3] = [1 - 2 * (yy + zz), 2 * (xy - zw), 2 * (xz + yw)];
        ret.matrix[1][0..3] = [2 * (xy + zw), 1 - 2 * (xx + zz), 2 * (yz - xw)];
        ret.matrix[2][0..3] = [2 * (xz - yw), 2 * (yz + xw), 1 - 2 * (xx + yy)];
        
        return ret;
    }
    
    unittest {
        quat q1 = quat(1.0f, 2.0f, 3.0f, 4.0f);
        
        assert(q1.to_matrix!(3, 3).matrix == [[-25.0f, -20.0f, 22.0f], [28.0f, -19.0f, 4.0f], [-10.0f, 20.0f, -9.0f]]);
        assert(q1.to_matrix!(4, 4).matrix == [[-25.0f, -20.0f, 22.0f, 0.0f],
                                              [28.0f, -19.0f, 4.0f, 0.0f],
                                              [-10.0f, 20.0f, -9.0f, 0.0f],
                                              [0.0f, 0.0f, 0.0f, 1.0f]]);
        assert(quat.identity.to_matrix!(3, 3).matrix == Matrix!(qt, 3, 3).identity.matrix);
        assert(q1.quaternion == quat.from_matrix(q1.to_matrix!(3, 3)).quaternion);

        assert(quat(0.0f, 0.0f, 0.0f, 1.0f).quaternion == quat.from_matrix(mat3.identity).quaternion);
        
        quat q2 = quat.from_matrix(mat3(1.0f, 3.0f, 2.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f));
        assert(q2.x == 0.0f);
        assert((q2.y > 0.7071066f) && (q2.y < 7071068f));
        assert((q2.z > -1.060661f) && (q2.z < -1.060659));
        assert((q2.w > 0.7071066f) && (q2.w < 7071068f));
    }
    
    void normalize() {
        qt m = to!qt(magnitude);
        
        if(m != 0) {
            x = x / m;
            y = y / m;
            z = z / m;
            w = w / m;
        }
    }
    
    Quaternion normalized() {
        Quaternion ret;
        qt m = to!qt(magnitude);
        
        if(m != 0) {
            ret.x = x / m;
            ret.y = y / m;
            ret.z = z / m;
            ret.w = w / m;
        } else {
            ret = Quaternion(x, y, z, w);
        }
        
        return ret;
    }
    
    unittest {
        quat q1 = quat(1.0f, 2.0f, 3.0f, 4.0f);
        quat q2 = quat(1.0f, 2.0f, 3.0f, 4.0f);
        
        q1.normalize();
        assert(q1.quaternion == q2.normalized.quaternion);
        //assert(q1.quaternion == q1.normalized.quaternion);
        assert(q1.magnitude > 0.9999999);
        assert(q1.magnitude < 1.0000001);    
    }
    
    @property real yaw() {
        return atan2(to!real(2 * (w*y + x*z)), to!real(w^^2 - x^^2 - y^^2 + z^^2));
    }
    
    @property real pitch() {
        return asin(to!real(2 * (w*x - y*z)));
    }
    
    @property real roll() {
        return atan2(to!real(2 * (w*z + x*y)), to!real(w^^2 - x^^2 + y^^2 - z^^2));
    }
    
    unittest {
        quat q1 = quat.identity;
        assert(q1.pitch == 0.0f);
        assert(q1.yaw == 0.0f);
        assert(q1.roll == 0.0f);
        
        quat q2 = quat(1.0f, 1.0f, 1.0f, 1.0f);
        assert(q2.yaw == q2.roll);
        assert((q2.yaw > 1.5707f) && (q2.yaw < 1.5709f));
        assert(q2.pitch == 0.0f);
        
        quat q3 = quat(1.9f, 2.1f, 1.3f, 0.1f);
        assert((q3.yaw > 2.4381f) && (q3.yaw < 2.4383f));
        assert(isNaN(q3.pitch));
        assert((q3.roll > 1.67718f) && (q3.roll < 1.6772f));
    }
    
    static Quaternion rotatex(real alpha) {
        Quaternion ret;
        
        alpha /= 2;
        ret.x = to!qt(sin(alpha));
        ret.y = 0;
        ret.z = 0;
        ret.w = to!qt(cos(alpha));
        
        return ret;
    }
    
    static Quaternion rotatey(real alpha) {
        Quaternion ret;
        
        alpha /= 2;
        ret.x = 0;
        ret.y = to!qt(sin(alpha));
        ret.z = 0;
        ret.w = to!qt(cos(alpha));
        
        return ret;
    }
    
    static Quaternion rotatez(real alpha) {
        Quaternion ret;
        
        alpha /= 2;
        ret.x = 0;
        ret.y = 0;
        ret.z = to!qt(sin(alpha));
        ret.w = to!qt(cos(alpha));
        
        return ret;
    }
    
    static Quaternion rotate_axis(Vector!(qt, 3) axis, real alpha) {
        if(alpha == 0) {
            return Quaternion.identity;
        }
        Quaternion ret;
        
        alpha /= 2;
        qt sinaqt = to!qt(sin(alpha));
        
        ret.x = axis.x * sinaqt;
        ret.y = axis.y * sinaqt;
        ret.z = axis.z * sinaqt;
        ret.w = to!qt(cos(alpha));
        
        return ret;
    }
    
    static Quaternion rotate_euler(real heading, real attitude, real bank) {
        Quaternion ret;
        
        real c1 = cos(heading / 2);
        real s1 = sin(heading / 2);
        real c2 = cos(attitude / 2);
        real s2 = sin(attitude / 2);
        real c3 = cos(bank / 2);
        real s3 = sin(bank / 2);
        
        ret.x = to!qt(s1 * s2 * c3 + c1 * c2 * s3);
        ret.y = to!qt(s1 * c2 * c3 + c1 * s2 * s3);
        ret.z = to!qt(c1 * s2 * c3 - s1 * c2 * s3);
        ret.w = to!qt(c1 * c2 * c3 - s1 * s2 * s3);
        
        return ret;
    }

    unittest {      
        assert(quat.rotatex(PI).quaternion[0..3] == [1.0f, 0.0f, 0.0f]);
        assert(quat.rotatey(PI).quaternion[0..3] == [0.0f, 1.0f, 0.0f]);
        assert(quat.rotatez(PI).quaternion[0..3] == [0.0f, 0.0f, 1.0f]);
        assert((quat.rotatex(PI).w == quat.rotatey(PI).w) && (quat.rotatey(PI).w == quat.rotatez(PI).w));
        //assert(quat.rotatex(PI).w == to!(quat.qt)(cos(PI)));
        
        assert(quat.rotate_axis(vec3(1.0f, 1.0f, 1.0f), PI).quaternion[0..3] == [1.0f, 1.0f, 1.0f]);
        assert(quat.rotate_axis(vec3(1.0f, 1.0f, 1.0f), PI).w == quat.rotatex(PI).w);
        
        quat q1 = quat.rotate_euler(PI, PI, PI);
        assert((q1.x > -2.71052e-20) && (q1.x < -2.71050e-20));
        assert((q1.y > -2.71052e-20) && (q1.y < -2.71050e-20));
        assert((q1.z > 2.71050e-20) && (q1.z < 2.71052e-20));
        assert(q1.w == -1.0f);
    }
    
    static Quaternion interpolate(Quaternion q1, Quaternion q2, real t) {
        Quaternion ret;

        real costheta = to!real(q1.w * q2.w + q1.x * q2.x + q1.y * q2.y + q1.z * q2.z);
        
        if(costheta < 0) {
            costheta = -costheta;
            q1 = q1.inverse;
        } else if(costheta > 1) {
            costheta = 1;
        }

        real theta = acos(costheta);
        real sintheta = sqrt(1.0 - costheta * costheta);
        if(abs(theta) < 0.01) {
            ret.x = q2.x;
            ret.y = q2.y;
            ret.z = q2.z;
            ret.w = q2.w;
        } else if(abs(sintheta) < 0.01) {
            ret.x = (q1.x + q2.x) * 0.5;
            ret.y = (q1.y + q2.y) * 0.5;
            ret.z = (q1.z + q2.z) * 0.5;
            ret.w = (q1.w + q2.w) * 0.5;
        } else {
            real ratio1 = sin((1 - t) * theta) / sintheta;
            real ratio2 = sin(t * theta) / sintheta;

            ret.x = to!qt(q1.x * ratio1 + q2.x * ratio2);
            ret.y = to!qt(q1.y * ratio1 + q2.y * ratio2);
            ret.z = to!qt(q1.z * ratio1 + q2.z * ratio2);
            ret.w = to!qt(q1.w * ratio1 + q2.w * ratio2);
        }
        
        return ret;    
    }
    
    unittest {
        quat q1 = quat(0.0f, 0.0f, 0.0f, 0.0f);
        quat q2 = quat(1.0f, 1.0f, 1.0f, 1.0f);
        
        assert(quat.interpolate(q1, q2, 0.0).quaternion == q1.quaternion);
        assert(quat.interpolate(q1, q2, 1.0).quaternion == q2.quaternion);
        quat q3 = quat.interpolate(q1, q2, 0.324);
        assert((q3.x == q3.y) && (q3.y == q3.z) && (q3.z == q3.w));
    }
    
    Quaternion opBinary(string op : "*", T : Quaternion)(T inp) {
        Quaternion ret;
        
        ret.x = x * inp.w + y * inp.z - z * inp.y + w * inp.x;
        ret.y = -x * inp.z + y * inp.w + z * inp.x + w * inp.y;
        ret.z = x * inp.y - y * inp.x + z * inp.w + w * inp.z;
        ret.w = -x * inp.x - y * inp.y - z * inp.z + w * inp.w;
        
        return ret;
    }
    
    T opBinary(string op : "*", T : Vector!(qt, 3))(T inp) {
        T ret;
        
        qt ww = w^^2;
        qt w2 = w * 2;
        qt wx2 = w2 * x;
        qt wy2 = w2 * y;
        qt wz2 = w2 * z;
        qt xx = x^^2;
        qt x2 = x * 2;
        qt xy2 = x2 * y;
        qt xz2 = x2 * z;
        qt yy = y^^2;
        qt yz2 = 2 * y * z;
        qt zz = z * z;
        
        ret.vector =  [ww * inp.x + wy2 * inp.z - wz2 * inp.y + xx * inp.x +
                       xy2 * inp.y + xz2 * inp.z - zz * inp.x - yy * inp.x,
                       xy2 * inp.x + yy * inp.y + yz2 * inp.z + wz2 * inp.x -
                       zz * inp.y + ww * inp.y - wx2 * inp.z - xx * inp.y,
                       xz2 * inp.x + yz2 * inp.y + zz * inp.z - wy2 * inp.x -
                       yy * inp.z + wx2 * inp.y - xx * inp.z + ww * inp.z];
       
       return ret;        
    }
    
    void opOpAssign(string op : "*", T : Quaternion)(T inp) {
        qt x2 = x * inp.w + y * inp.z - z * inp.y + w * inp.x;
        qt y2 = -x * inp.z + y * inp.w + z * inp.x + w * inp.y;
        qt z2 = x * inp.y - y * inp.x + z * inp.w + w * inp.z;
        qt w2 = -x * inp.x - y * inp.y - z * inp.z + w * inp.w;
        x = x2; y = y2; z = z2; w = w2;
    }
    
    unittest {
        quat q1 = quat.identity;
        quat q2 = quat(0.0f, 1.0f, 2.0f, 3.0f);
        quat q3 = quat(0.1f, 1.2f, 2.3f, 3.4f);
        
        assert((q1 * q1).quaternion == q1.quaternion);
        assert((q1 * q2).quaternion == q2.quaternion);
        assert((q2 * q1).quaternion == q2.quaternion);
        quat q4 = q3 * q2;
        assert((q2 * q3).quaternion != q4.quaternion);
        q3 *= q2;
        assert(q4.quaternion == q3.quaternion);
        assert((q4.x > 0.399999f) && (q4.x < 0.400001f));
        assert((q4.y > 6.799999f) && (q4.y < 6.800001f));
        assert((q4.z > 13.799999f) && (q4.z < 13.800001f));
        assert((q4.w > 4.399999f) && (q4.w < 4.400001f));
        
        vec3 v1 = vec3(1.0f, 2.0f, 3.0f);
        assert((q1 * v1).vector == v1.vector);
        assert((q2 * v1).vector == [-2.0f, 36.0f, 38.0f]);
    }

    const bool opEquals(ref const Quaternion qu) {
        return quaternion == qu.quaternion;
    }
    
    bool opCast(T : bool)() {
        return ok;
    }
    
    unittest {
        assert(quat(1.0f, 2.0f, 3.0f, 4.0f) == quat(1.0f, 2.0f, 3.0f, 4.0f));
        assert(quat(1.0f, 2.0f, 3.0f, 4.0f) != quat(1.0f, 2.0f, 3.0f, 3.0f));
    
        assert(!(quat(float.nan, float.nan, float.nan, float.nan)));
        if(quat(1.0f, 1.0f, 1.0f, 1.0f)) { }
        else { assert(false); }
    }
    
}

alias Quaternion!(float) quat;