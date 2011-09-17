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

    @property t x() { return vector[0]; }
    @property void x(t value) { vector[0] = value; }
    @property t y() { return vector[1]; }
    @property void y(t value) { vector[1] = value; }
    static if(dimension >= 3) {
        @property t z() { return vector[2]; }
        @property void z(t value) { vector[2] = value; }
    }
    static if(dimension >= 4) {
        @property t w() { return vector[3]; }
        @property void w(t value) { vector[3] = value; }
    }

    static void isEqualVectorImpl(int d)(Vector!(type, d) vec) if(d == dimension) {
    }

    template isEqualVector(T) {
        enum isEqualVector = is(typeof(isEqualVectorImpl(T.init)));
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
        static if((args.length == 1) && is(Args[0] : t)) { clear(args[0]); }
        else { construct!(0)(args); }
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
        for(int i = 0; i < vector.length; i++) {
            vector[i] = value;
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
    
    template get() {
        t get(char coord) {
            static if(dimension >= 4) {
                assert(inPattern(coord, "xyzw"), "coord " ~ coord ~ " does not exist in a 4 dimensional vector");
            
                if(coord == 'w') {
                    return vector[3];
                }
            }
            static if(dimension >= 3) {
                assert(inPattern(coord, "xyz"), "coord " ~ coord ~ " does not exist in a 3 dimensional vector");
                
                if(coord == 'z') {
                    return vector[2];
                }
            }
            // dimension must be 2!
            assert(inPattern(coord, "xy"), "coord " ~ coord ~ " does not exist in a 2 dimensional vector");
            
            if(coord == 'y') { 
                return vector[1];
            }
            return vector[0];
        }
    }

    void set(char coord, t value) {
        if(coord == 'x') { vector[0] = value; }
        else if(coord == 'y') { vector[1] = value; }
        static if(dimension >= 3) { if(coord == 'z') { vector[2] = value; } }
        static if(dimension == 4) { if(coord == 'w') { vector[3] = value; } }
    }
    
    static if(dimension == 2) { void set(t x, t y) { vector[0] = x; vector[1] = y; } }
    static if(dimension == 3) { void set(t x, t y, t z) { vector[0] = x; vector[1] = y; vector[2] = z; } }
    static if(dimension == 4) { void set(t x, t y, t z, t w) { vector[0] = x; vector[1] = y; vector[2] = z; vector[3] = w; } }

    void update(Vector!(t, dimension) other) {
        vector = other.vector;
    }

    unittest {
        vec2 v2 = vec2(1.0f, 2.0f);
        assert(v2.get('x') == 1.0f);
        assert(v2.get('y') == 2.0f);
        v2.set('x', 3.0f);
        assert(v2.vector == [3.0f, 2.0f]);
        v2.set('y', 4.0f);
        assert(v2.vector == [3.0f, 4.0f]);
        assert((v2.get('x') == v2.x) && v2.x == 3.0f);
        assert((v2.get('y') == v2.y) && v2.y == 4.0f);
        v2.set(0.0f, 1.0f);
        assert(v2.vector == [0.0f, 1.0f]);
        v2.update(vec2(3.0f, 4.0f));
        assert(v2.vector == [3.0f, 4.0f]);
        
        vec3 v3 = vec3(1.0f, 2.0f, 3.0f);
        assert(v3.get('x') == 1.0f);
        assert(v3.get('y') == 2.0f);
        assert(v3.get('z') == 3.0f);
        v3.set('x', 3.0f);
        assert(v3.vector == [3.0f, 2.0f, 3.0f]);
        v3.set('y', 4.0f);
        assert(v3.vector == [3.0f, 4.0f, 3.0f]);
        v3.set('z', 5.0f);
        assert(v3.vector == [3.0f, 4.0f, 5.0f]);
        assert((v3.get('x') == v3.x) && v3.x == 3.0f);
        assert((v3.get('y') == v3.y) && v3.y == 4.0f);
        assert((v3.get('z') == v3.z) && v3.z == 5.0f);
        v3.set(0.0f, 1.0f, 2.0f);
        assert(v3.vector == [0.0f, 1.0f, 2.0f]);
        v3.update(vec3(3.0f, 4.0f, 5.0f));
        assert(v3.vector == [3.0f, 4.0f, 5.0f]);
                
        vec4 v4 = vec4(1.0f, 2.0f, vec2(3.0f, 4.0f));
        assert(v4.get('x') == 1.0f);
        assert(v4.get('y') == 2.0f);
        assert(v4.get('z') == 3.0f);
        assert(v4.get('w') == 4.0f);
        v4.set('x', 3.0f);
        assert(v4.vector == [3.0f, 2.0f, 3.0f, 4.0f]);
        v4.set('y', 4.0f);
        assert(v4.vector == [3.0f, 4.0f, 3.0f, 4.0f]);
        v4.set('z', 5.0f);
        assert(v4.vector == [3.0f, 4.0f, 5.0f, 4.0f]);
        v4.set('w', 6.0f);
        assert(v4.vector == [3.0f, 4.0f, 5.0f, 6.0f]);
        assert((v4.get('x') == v4.x) && v4.x == 3.0f);
        assert((v4.get('y') == v4.y) && v4.y == 4.0f);
        assert((v4.get('z') == v4.z) && v4.z == 5.0f);
        assert((v4.get('w') == v4.w) && v4.w == 6.0f);
        v4.set(0.0f, 1.0f, 2.0f, 3.0f);
        assert(v4.vector == [0.0f, 1.0f, 2.0f, 3.0f]);
        v4.update(vec4(3.0f, 4.0f, 5.0f, 6.0f));
        assert(v4.vector == [3.0f, 4.0f, 5.0f, 6.0f]);
    }
    
    template opDispatch(string s) {
        t[s.length] opDispatch() {
            t[s.length] ret;
            
            for(int i = 0; i < s.length; i++) {
                ret[i] = get(s[i]);
            }
            
            return ret;
        }
    }
    
    unittest {
        // no need for changing the vector data, because last unittest passed (which tested get)
        // there's no try..catch..else :(
        bool f1 = false, f2 = false, f3 = false;
        
        vec2 v2 = vec2(1.0f, 2.0f);
        assert(v2.xyyxy == [1.0f, 2.0f, 2.0f, 1.0f, 2.0f]);
        try {
            v2.xyzw; f1 = true;
        } catch (AssertError e) { }
        if(f1) { assert(false, "2 dimensional vector can't return a value for z or w coordinate"); }
        
        vec3 v3 = vec3(v2, 3.0f);
        assert(v3.xyzxyx == [1.0f, 2.0f, 3.0f, 1.0f, 2.0f, 1.0f]);
        try {
            v3.xyzw; f2 = true;
        } catch (AssertError e) { }
        if(f2) { assert(false, "2 dimensional vector can't return a value for z or w coordinate"); }
        
        vec4 v4 = vec4(v3, 4.0f);
        assert(v4.xywzzwwx == [1.0f, 2.0f, 4.0f, 3.0f, 3.0f, 4.0f, 4.0f, 1.0f]);
        try {
            v4.e; f3 = true;
        } catch (AssertError e) { }
        if(f3) { assert(false, "There is no coordinate e to return"); }

    }

    Vector!(t, dimension) opUnary(string op)() if(op == "-") {
        Vector!(t, dimension) ret;
        
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
    Vector!(t, dimension) opBinary(string op, T)(T r) if((op == "*") && is(T : t)) {
        Vector!(t, dimension) ret;
        
        ret.vector[0] = vector[0] * r;
        ret.vector[1] = vector[1] * r;
        static if(dimension >= 3) { ret.vector[2] = vector[2] * r; }
        static if(dimension >= 4) { ret.vector[3] = vector[3] * r; }
        
        return ret;
    }

    Vector!(t, dimension) opBinary(string op, T)(T r) if(((op == "+") || (op == "-")) && isEqualVector!T) {
        Vector!(t, dimension) ret;
        
        ret.vector[0] = mixin("vector[0]" ~ op ~ "r.vector[0]");
        ret.vector[1] = mixin("vector[1]" ~ op ~ "r.vector[1]");
        static if(dimension >= 3) { ret.vector[2] = mixin("vector[2]" ~ op ~ "r.vector[2]"); }
        static if(dimension >= 4) { ret.vector[3] = mixin("vector[3]" ~ op ~ "r.vector[3]"); }
        
        return ret;
    }
    
    t opBinary(string op, T)(T r) if((op == "*") && isEqualVector!T) {
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
    
    void opOpAssign(string op, T)(T r) if((op == "*") && is(T : t)) {
        vector[0] *= r;
        vector[1] *= r;
        static if(dimension >= 3) { vector[2] *= r; }
        static if(dimension >= 4) { vector[3] *= r; }
    }

    void opOpAssign(string op, T)(T r) if(((op == "+") || (op == "-")) && isEqualVector!T) {
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
    
    @property Vector!(t, dimension) normalized() {
        Vector!(t, dimension) ret;
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


    static void isCompatibleVectorImpl(int d)(Vector!(type, d) vec) if(d == cols) {
    }

    template isCompatibleVector(T) {
        enum isCompatibleVector = is(typeof(isCompatibleVectorImpl(T.init)));
    }    
    
    private void construct(int i, T, Tail...)(T head, Tail tail) {
//         int row = i / rows;
//         int col = i % cols;
        static if(i >= rows*cols) {
            static assert(false, "constructor has too many arguments");
        } else static if(is(T : t)) {
            matrix[i / rows][i % cols] = head;
            construct!(i + 1)(tail);
        } else static if(isCompatibleVector!T) {
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
    
    static if(rows == cols) {
        void make_identity() {
            clear(0);
            for(int r = 0; r < rows; r++) {
                matrix[r][r] = 1;
            }
        }
    }
    
    @property Matrix!(t, cols, rows) transposed() {
        Matrix!(t, cols, rows) ret;
        
        for(int r = 0; r < rows; r++) {
            for(int c = 0; r < cols; r++) {
                ret.matrix[c][r] = matrix[r][c];
            }
        }
    }
    
    
}

alias Matrix!(float, 2, 2) mat2;
alias Matrix!(float, 3, 3) mat3;
alias Matrix!(float, 3, 4) mat34;
alias Matrix!(float, 4, 4) mat4;

void main() { 
    import std.stdio;

    mat2 m2 = mat2(1.0f, 2.0f, vec2(3.0f, 4.0f));
    writefln("%s", m2.matrix);

    mat2 m2_1 = mat2(1.0f);
    writefln("%s: %s", m2_1.matrix, m2_1.ok);
    
    real x = 1;
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