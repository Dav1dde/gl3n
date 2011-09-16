module gl3n.LinearAlgebra;

private {
    import std.stdio : writefln;
    import std.string : inPattern;
    import std.math : isNaN;
}

version(unittest) { private import core.exception : AssertError; }


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

    static void isCompatibleVectorImpl(int d)(Vector!(type, d) vec) if(d <= dimension) {
    }

    template isCompatibleVector(T) {
        enum isCompatibleVector = is(typeof(isCompatibleVectorImpl(T.init)));
    }

    private void construct(int i, T, Tail...)(T head, Tail tail) {
        static if(i >= dimension)
            static assert(false, "constructor has too many arguments");
        else static if(is(T : t)) {
            vector[i] = head;
            construct!(i + 1)(tail);
        }
        else static if(isCompatibleVector!T) {   
            vector[i .. i + T.dimension] = head.vector;
            construct!(i + T.dimension)(tail);
        }
        else
            static assert(false, "Vector constructor argument must be of type " ~ type.stringof ~ " or Vector, not " ~ T.stringof);
    }
    
    void construct(int i)() { // terminate
    }

    this(Args...)(Args args) {
        construct!(0)(args);
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
        for(int i = 0; i < dimension; i++) {
            vector[i] = value;
        }
    }

    unittest {
        vec3 vec_clear;
        assert(!vec_clear.ok);
        vec_clear.clear(1.0f);
        assert(vec_clear.vector == [1.0f, 1.0f, 1.0f]);
        
        vec4 b = vec4(1.0f, vec_clear);
        assert(b.ok);
        assert(b.vector == [1.0f, 1.0f, 1.0f, 1.0f]);

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
            static if(dimension >= 2) {
                assert(inPattern(coord, "xy"), "coord " ~ coord ~ " does not exist in a 2 dimensional vector");
                
                if(coord == 'y') { 
                    return vector[1];
                }
                return vector[0];
            }
        }
    }

    void set(char coord, t value) {
        static if(dimension >= 2) { if(coord == 'x') { vector[0] = value; }
                                    else if(coord == 'y') { vector[1] = value; } }
        static if(dimension >= 3) { if(coord == 'z') { vector[2] = value; } }
        static if(dimension == 4) { if(coord == 'w') { vector[3] = value; } }
    }
    
    static if(dimension == 2) { void set(t x, t y) { vector[0] = x; vector[1] = y; } }
    static if(dimension == 3) { void set(t x, t y, t z) { vector[0] = x; vector[1] = y; vector[2] = z; } }
    static if(dimension == 4) { void set(t x, t y, t z, t w) { vector[0] = x; vector[1] = y; vector[2] = z; vector[3] = w; } }

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

void main() {  
    //auto vv = vec2(2.0f, 3.0f);
    //vv.w;
    
    vec4d v = vec4d(1.0, vec2d(2.0, 3.0), 4.0);
    writefln("%f", v.x);
    writefln("%f", v.y);
    writefln("%f", v.z);
    writefln("%f", v.w);
    writefln("%f", v.xwwz);
    writefln("%f", v.xyzwyxxzwwwz);
    writefln("%s", v.vector.ptr);
}