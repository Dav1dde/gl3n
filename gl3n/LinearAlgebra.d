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
*/


module gl3n.LinearAlgebra;

private {
    import std.string : inPattern;
    import std.math : isNaN, sqrt;
}

version(unittest) {
    private {
        import core.exception : AssertError;
    }
}


struct Vector(type, int dimension_) if((dimension_ >= 2) && (dimension_ <= 4)) {
    alias type t;
    static const int dimension = dimension_;
    
    t[dimension] vector;

    private @property t get_(char coord)() {
        return vector[coord_to_index!coord];
    }
    private @property void set_(char coord)(t value) {
        vector[coord_to_index!coord] = value;
    }
    
    alias get_!'x' x;
    alias set_!'x' x;
    alias get_!'y' y;
    alias set_!'y' y;
    static if(dimension >= 3) {
        alias get_!'z' z;
        alias set_!'z' z;
    }
    static if(dimension >= 4) {
        alias get_!'w' w;
        alias set_!'w' w;
    }
   
    static void isCompatibleVectorImpl(int d)(Vector!(type, d) vec) if(d <= dimension) {
    }

    template isCompatibleVector(T) {
        enum isCompatibleVector = is(typeof(isCompatibleVectorImpl(T.init)));
    }

    private void construct(int i, T, Tail...)(T head, Tail tail) {
        static if(i >= dimension) {
            static assert(false, "constructor has too many arguments");
        } else static if(is(T : t)) {
            vector[i] = head;
            construct!(i + 1)(tail);
        } else static if(isCompatibleVector!T) {   
            vector[i .. i + T.dimension] = head.vector;
            construct!(i + T.dimension)(tail);
        } else {
            static assert(false, "Vector constructor argument must be of type " ~ type.stringof ~ " or Vector, not " ~ T.stringof);
        }
    }
    
    private void construct(int i)() { // terminate
    }

    this(Args...)(Args args) {
        construct!(0)(args);
    }
    
    this()(t value) {
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
               
    void clear(t value) {
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

    template coord_to_index(char c)
    {
        static if(c == 'x') {
            enum coord_to_index = 0;
        }else static if(c == 'y') {
            enum coord_to_index = 1;
        } else static if(c == 'z') {
            static assert(dimension >= 3, "the z property is only available on vectors with a third dimension.");
            enum coord_to_index = 2;
        } else static if(c == 'w') {
            static assert(dimension >= 4, "the w property is only available on vectors with a fourth dimension.");
            enum coord_to_index = 3;
        } else {
            static assert(false, "accepted coordinates are x, y, z and w, not " ~ c ~ ".");
        }
    }
    
    static if(dimension == 2) { void set(t x, t y) { vector[0] = x; vector[1] = y; } }
    static if(dimension == 3) { void set(t x, t y, t z) { vector[0] = x; vector[1] = y; vector[2] = z; } }
    static if(dimension == 4) { void set(t x, t y, t z, t w) { vector[0] = x; vector[1] = y; vector[2] = z; vector[3] = w; } }

    void update(Vector!(t, dimension) other) {
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
        assert(v2.x == 3.0f);
        assert(v2.y == 4.0f);
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
        assert(v3.x == 3.0f);
        assert(v3.y == 4.0f);
        assert(v3.z == 5.0f);
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
        assert(v4.x == 3.0f);
        assert(v4.y == 4.0f);
        assert(v4.z == 5.0f);
        assert(v4.w == 6.0f);
        v4.set(0.0f, 1.0f, 2.0f, 3.0f);
        assert(v4.vector == [0.0f, 1.0f, 2.0f, 3.0f]);
        v4.update(vec4(3.0f, 4.0f, 5.0f, 6.0f));
        assert(v4.vector == [3.0f, 4.0f, 5.0f, 6.0f]);
    }
    
    void dispatchImpl(size_t i, string s, size_t size)(ref t[size] result) {
        static if(s.length > 0) {
            result[i] = vector[coord_to_index!(s[0])];
            dispatchImpl!(i + 1, s[1..$])(result);
        }
    }

    t[s.length] opDispatch(string s)() {
        t[s.length] ret;
        dispatchImpl!(0, s)(ret);
        return ret;
    }
    
    unittest {
        vec2 v2 = vec2(1.0f, 2.0f);
        assert(v2.xyyxy == [1.0f, 2.0f, 2.0f, 1.0f, 2.0f]);

        assert(vec3(1.0f, 2.0f, 3.0f).xyzzyx == [1.0f, 2.0f, 3.0f, 3.0f, 2.0f, 1.0f]);
        
        assert(vec4(v2, 3.0f, 4.0f).wyyzwx == [4.0f, 2.0f, 2.0f, 3.0f, 4.0f, 1.0f]);
    }

    Vector opUnary(string op)() if(op == "-") {
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
    Vector opBinary(string op : "*", T : t)(T r) {
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
    
    t opBinary(string op : "*", T : Vector)(T r) {
        t temp = 0.0f;
        
        temp += vector[0] * r.vector[0];
        temp += vector[1] * r.vector[1];
        static if(dimension >= 3) { temp += vector[2] * r.vector[2]; }
        static if(dimension >= 4) { temp += vector[3] * r.vector[3]; }
                
        return temp;
    }

    //Vector!(t, dimension) opBinary(string op)(T r) if(isCompatibleMatrix!T) {
    //}

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
    }
    
    void opOpAssign(string op : "*", T : t)(T r) {
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

    //void opOpAssign(string op)(T r) if(isCompatibleMatrix!T) {
    //}
    
    @property real length() {
        real temp = 0.0f;
        
        foreach(v; vector) {
            temp += v^^2;
        }
        
        return sqrt(temp);
    }
    
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
    
    
    unittest {
        vec2 v2 = vec2(1.0f, 3.0f);
        v2 *= 2.5f;
        assert(v2.vector == [2.5f, 7.5f]);
        v2 -= vec2(2.5f, 7.5f);
        assert(v2.vector == [0.0f, 0.0f]);
        v2 += vec2(1.0f, 3.0f);
        assert(v2.vector == [1.0f, 3.0f]);
        assert(v2.length == sqrt(10));
        assert(v2.normalized == vec2(1.0f/sqrt(10), 3.0f/sqrt(10)));

        vec3 v3 = vec3(1.0f, 3.0f, 5.0f);
        v3 *= 2.5f;
        assert(v3.vector == [2.5f, 7.5f, 12.5f]);
        v3 -= vec3(2.5f, 7.5f, 12.5f);
        assert(v3.vector == [0.0f, 0.0f, 0.0f]);
        v3 += vec3(1.0f, 3.0f, 5.0f);
        assert(v3.vector == [1.0f, 3.0f, 5.0f]);
        assert(v3.length == sqrt(35));
        assert(v3.normalized == vec3(1.0f/sqrt(35), 3.0f/sqrt(35), 5.0f/sqrt(35)));
            
        vec4 v4 = vec4(1.0f, 3.0f, 5.0f, 7.0f);
        v4 *= 2.5f;
        assert(v4.vector == [2.5f, 7.5f, 12.5f, 17.5]);
        v4 -= vec4(2.5f, 7.5f, 12.5f, 17.5f);
        assert(v4.vector == [0.0f, 0.0f, 0.0f, 0.0f]);
        v4 += vec4(1.0f, 3.0f, 5.0f, 7.0f);
        assert(v4.vector == [1.0f, 3.0f, 5.0f, 7.0f]);
        assert(v4.length == sqrt(84));
        assert(v4.normalized == vec4(1.0f/sqrt(84), 3.0f/sqrt(84), 5.0f/sqrt(84), 7.0f/sqrt(84)));
    }
       
    const bool opEquals(T)(T vec) if(T.dimension == dimension) {
        return vector == vec.vector;
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
    }
        
}

T.t dot(T)(T veca, T vecb) {
    return veca * vecb;
}

T cross(T)(T veca, T vecb) if(T.dimension == 3) {
    return T(veca.y * vecb.z - vecb.y * veca.z,
             veca.z * vecb.x - vecb.z * veca.x,
             veca.x * vecb.y - vecb.x * veca.y);
}

real distance(T)(T veca, T vecb) {
    return (veca - vecb).length;
}

unittest {
    // dot is already tested in opBinary, so no need for testing with more vectors
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
    
alias Vector!(float, 2) vec2;
alias Vector!(float, 3) vec3;
alias Vector!(float, 4) vec4;

alias Vector!(double, 2) vec2d;
alias Vector!(double, 3) vec3d;
alias Vector!(double, 4) vec4d;

alias Vector!(int, 2) vec2i;
alias Vector!(int, 3) vec3i;
alias Vector!(int, 4) vec4i;

alias Vector!(ubyte, 2) vec2ub;
alias Vector!(ubyte, 3) vec3ub;
alias Vector!(ubyte, 4) vec4ub;


// The matrix has you...
struct Matrix(type, int rows_, int cols_) if((rows_ > 0) && (cols_ > 0)) {
    alias type t;
    static const int rows = rows_;
    static const int cols = cols_;
    
    // row-major layout, in memory
    t[rows][cols] matrix;

    private void construct(int i, T, Tail...)(T head, Tail tail) {
//         int row = i / rows;
//         int col = i % cols;
        static if(i >= rows*cols) {
            static assert(false, "constructor has too many arguments");
        } else static if(is(T : t)) {
            matrix[i / rows][i % cols] = head;
            construct!(i + 1)(tail);
        } else static if(is(T == Vector!(t, cols))) {
            static if(i % cols == 0) {
                matrix[i / rows] = head.vector;
                construct!(i + T.dimension)(tail);
            } else {
                static assert(false, "Can't convert Vector into the matrix. Maybe it doesn't align to the columns correctly or dimension doesn't fit");
            }
        } else {
            static assert(false, "Matrix constructor argument must be of type " ~ t.stringof ~ " or Vector, not " ~ T.stringof);
        }
    }
    
    private void construct(int i)() { // terminate
    }
    
    this(Args...)(Args args) {
        static if((args.length == 1) && is(Args[0] : t)) {
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
    
    void clear(t value) {
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
    }
    
    static if(rows == cols) {
        void make_identity() {
            clear(0);
            for(int r = 0; r < rows; r++) {
                matrix[r][r] = 1;
            }
        }
        
        @property Matrix!(t, cols, rows) identity() {
            Matrix!(t, cols, rows) ret;
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
    
    @property Matrix!(t, cols, rows) transposed() {
        Matrix!(t, cols, rows) ret;
        
        for(int r = 0; r < rows; r++) {
            for(int c = 0; c < cols; c++) {
                ret.matrix[c][r] = matrix[r][c];
            }
        }
        
        return ret;
    }
    
    // transposed already tested in last unittest
    
    static if((rows == 2) && (cols == 2)) {
        @property t det() {
            return (matrix[0][0] * matrix[1][1] - matrix[0][1] * matrix[1][0]);
        }
        
        private Matrix invert(ref Matrix mat) {
            t d = det;
            
            mat.matrix = [[matrix[1][1]/det, -matrix[0][1]/det],
                          [-matrix[1][0]/det, matrix[0][0]/det]];
            
            return mat;
        }
    } else static if((rows == 3) && (cols == 3)) {
        @property t det() {
            return (matrix[0][0] * matrix[1][1] * matrix[2][2]
                  + matrix[0][1] * matrix[1][2] * matrix[2][0]
                  + matrix[0][2] * matrix[1][0] * matrix[2][1]
                  - matrix[0][2] * matrix[1][1] * matrix[2][0]
                  - matrix[0][1] * matrix[1][0] * matrix[2][2]
                  - matrix[0][0] * matrix[1][2] * matrix[2][1]);
        }
        
        private Matrix invert(ref Matrix mat) {
            t d = det;
            
            mat.matrix = [[(matrix[1][1] * matrix[2][2] - matrix[1][2] * matrix[2][1])/det,
                           (matrix[0][2] * matrix[2][1] - matrix[0][1] * matrix[2][2])/det,
                           (matrix[0][1] * matrix[1][2] - matrix[0][2] * matrix[1][1])/det],
                          [(matrix[1][2] * matrix[2][0] - matrix[1][0] * matrix[2][2])/det,
                           (matrix[0][0] * matrix[2][2] - matrix[0][2] * matrix[2][0])/det,
                           (matrix[0][2] * matrix[1][0] - matrix[0][0] * matrix[1][2])/det],
                          [(matrix[1][0] * matrix[2][1] - matrix[1][1] * matrix[2][0])/det,
                           (matrix[0][1] * matrix[2][0] - matrix[0][0] * matrix[2][1])/det,
                           (matrix[0][0] * matrix[1][1] - matrix[0][1] * matrix[1][0])/det]];
            
            return mat;
        }
    } else static if((rows == 4) && (cols == 4)) {
        @property t det() {
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
            t d = det;
            
            mat.matrix = [[(matrix[1][1] * matrix[2][2] * matrix[3][3] + matrix[1][2] * matrix[2][3] * matrix[3][1] + matrix[1][3] * matrix[2][1] * matrix[3][2]
                          - matrix[1][1] * matrix[2][3] * matrix[3][2] - matrix[1][2] * matrix[2][1] * matrix[3][3] - matrix[1][3] * matrix[2][2] * matrix[3][1])/det,
                           (matrix[0][1] * matrix[2][3] * matrix[3][2] + matrix[0][2] * matrix[2][1] * matrix[3][3] + matrix[0][3] * matrix[2][2] * matrix[3][1]
                          - matrix[0][1] * matrix[2][2] * matrix[3][3] - matrix[0][2] * matrix[2][3] * matrix[3][1] - matrix[0][3] * matrix[2][1] * matrix[3][2])/det,
                           (matrix[0][1] * matrix[1][2] * matrix[3][3] + matrix[0][2] * matrix[1][3] * matrix[3][1] + matrix[0][3] * matrix[1][1] * matrix[3][2]
                          - matrix[0][1] * matrix[1][3] * matrix[3][2] - matrix[0][2] * matrix[1][1] * matrix[3][3] - matrix[0][3] * matrix[1][2] * matrix[3][1])/det,
                           (matrix[0][1] * matrix[1][3] * matrix[2][2] + matrix[0][2] * matrix[1][1] * matrix[2][3] + matrix[0][3] * matrix[1][2] * matrix[2][1]
                          - matrix[0][1] * matrix[1][2] * matrix[2][3] - matrix[0][2] * matrix[1][3] * matrix[2][1] - matrix[0][3] * matrix[1][1] * matrix[2][2])/det],
                          [(matrix[1][0] * matrix[2][3] * matrix[3][2] + matrix[1][2] * matrix[2][0] * matrix[3][3] + matrix[1][3] * matrix[2][2] * matrix[3][0]
                          - matrix[1][0] * matrix[2][2] * matrix[3][3] - matrix[1][2] * matrix[2][3] * matrix[3][0] - matrix[1][3] * matrix[2][0] * matrix[3][2])/det,
                           (matrix[0][0] * matrix[2][2] * matrix[3][3] + matrix[0][2] * matrix[2][3] * matrix[3][0] + matrix[0][3] * matrix[2][0] * matrix[3][2]
                          - matrix[0][0] * matrix[2][3] * matrix[3][2] - matrix[0][2] * matrix[2][0] * matrix[3][3] - matrix[0][3] * matrix[2][2] * matrix[3][0])/det,
                           (matrix[0][0] * matrix[1][3] * matrix[3][2] + matrix[0][2] * matrix[1][0] * matrix[3][3] + matrix[0][3] * matrix[1][2] * matrix[3][0]
                          - matrix[0][0] * matrix[1][2] * matrix[3][3] - matrix[0][2] * matrix[1][3] * matrix[3][0] - matrix[0][3] * matrix[1][0] * matrix[3][2])/det,
                           (matrix[0][0] * matrix[1][2] * matrix[2][3] + matrix[0][2] * matrix[1][3] * matrix[2][0] + matrix[0][3] * matrix[1][0] * matrix[2][2]
                          - matrix[0][0] * matrix[1][3] * matrix[2][2] - matrix[0][2] * matrix[1][0] * matrix[2][3] - matrix[0][3] * matrix[1][2] * matrix[2][0])/det],
                          [(matrix[1][0] * matrix[2][1] * matrix[3][3] + matrix[1][1] * matrix[2][3] * matrix[3][0] + matrix[1][3] * matrix[2][0] * matrix[3][1]
                          - matrix[1][0] * matrix[2][3] * matrix[3][1] - matrix[1][1] * matrix[2][0] * matrix[3][3] - matrix[1][3] * matrix[2][1] * matrix[3][0])/det,
                           (matrix[0][0] * matrix[2][3] * matrix[3][1] + matrix[0][1] * matrix[2][0] * matrix[3][3] + matrix[0][3] * matrix[2][1] * matrix[3][0]
                          - matrix[0][0] * matrix[2][1] * matrix[3][3] - matrix[0][1] * matrix[2][3] * matrix[3][0] - matrix[0][3] * matrix[2][0] * matrix[3][1])/det,
                           (matrix[0][0] * matrix[1][1] * matrix[3][3] + matrix[0][1] * matrix[1][3] * matrix[3][0] + matrix[0][3] * matrix[1][0] * matrix[3][1]
                          - matrix[0][0] * matrix[1][3] * matrix[3][1] - matrix[0][1] * matrix[1][0] * matrix[3][3] - matrix[0][3] * matrix[1][1] * matrix[3][0])/det,
                           (matrix[0][0] * matrix[1][3] * matrix[2][1] + matrix[0][1] * matrix[1][0] * matrix[2][3] + matrix[0][3] * matrix[1][1] * matrix[2][0]
                          - matrix[0][0] * matrix[1][1] * matrix[2][3] - matrix[0][1] * matrix[1][3] * matrix[2][0] - matrix[0][3] * matrix[1][0] * matrix[2][1])/det],
                          [(matrix[1][0] * matrix[2][2] * matrix[3][1] + matrix[1][1] * matrix[2][0] * matrix[3][2] + matrix[1][2] * matrix[2][1] * matrix[3][0]
                          - matrix[1][0] * matrix[2][1] * matrix[3][2] - matrix[1][1] * matrix[2][2] * matrix[3][0] - matrix[1][2] * matrix[2][0] * matrix[3][1])/det,
                           (matrix[0][0] * matrix[2][1] * matrix[3][2] + matrix[0][1] * matrix[2][2] * matrix[3][0] + matrix[0][2] * matrix[2][0] * matrix[3][1]
                          - matrix[0][0] * matrix[2][2] * matrix[3][1] - matrix[0][1] * matrix[2][0] * matrix[3][2] - matrix[0][2] * matrix[2][1] * matrix[3][0])/det,
                           (matrix[0][0] * matrix[1][2] * matrix[3][1] + matrix[0][1] * matrix[1][0] * matrix[3][2] + matrix[0][2] * matrix[1][1] * matrix[3][0]
                          - matrix[0][0] * matrix[1][1] * matrix[3][2] - matrix[0][1] * matrix[1][2] * matrix[3][0] - matrix[0][2] * matrix[1][0] * matrix[3][1])/det,
                           (matrix[0][0] * matrix[1][1] * matrix[2][2] + matrix[0][1] * matrix[1][2] * matrix[2][0] + matrix[0][2] * matrix[1][0] * matrix[2][1]
                          - matrix[0][0] * matrix[1][2] * matrix[2][1] - matrix[0][1] * matrix[1][0] * matrix[2][2] - matrix[0][2] * matrix[1][1] * matrix[2][0])/det]];
                  
            return mat;
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
    
}


alias Matrix!(float, 2, 2) mat2;
alias Matrix!(float, 3, 3) mat3;
alias Matrix!(float, 3, 4) mat34;
alias Matrix!(float, 4, 4) mat4;

void main() { 
    import std.stdio;
// 
    mat2 m2 = mat2(1.0f, 2.0f, vec2(3.0f, 4.0f));
    writefln("%s", m2.matrix);
    
    
    mat3 m3 = mat3(1.0f, -2.0f, 3.0f,
                   7.0f, -1.0f, 0.0f,
                   3.0f, 2.0f, -4.0f);
    writefln("%f", m3.det);
    
    mat4 m4 = mat4(1.0f, 2.0f, 3.0f, 4.0f,
                   -2.0f, 1.0f, 5.0f, -2.0f,
                   2.0f, -1.0f, 7.0f, 1.0f,
                   3.0f, -3.0f, 2.0f, 0.0f);
    writefln("%f", m4.det);
// 
//     mat2 m2_1 = mat2(1.0f);
//     writefln("%s: %s", m2_1.matrix, m2_1.ok);
//     
//     real x = 1;
//     int[2][2] r;
//     r[0][0] = 0;
//     r[0][1] = 1;
//     r[1][0] = 2;
//     r[1][1] = 3;
//     
//     int* ptr = r[0].ptr;
//     writefln("%s", *ptr);
//     ptr++;
//     writefln("%s", *ptr);
//     ptr++;
//     writefln("%s", *ptr);
//     ptr++;
//     writefln("%s", *ptr);
//     
//     int[] r2 = cast(int[4])r;
//     writefln("%s - %s", r2, r2.length);
//     r2[0] = 10;
//     writefln("%s", r);
}