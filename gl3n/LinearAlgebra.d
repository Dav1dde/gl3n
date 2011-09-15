import std.stdio : writefln;
import std.string : inPattern;
import std.math : isNaN;



struct Vector(type, int dimension_) {
    alias type t;
    static const int dimension = dimension_;
    
    static assert((dimension >= 2) && (dimension <= 4));
    
    static t[dimension] vector;

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
    
    
    this(t value) {
        clear(value);
    }
    
    this(t x, t y) {
        set('x', x);
        set('y', y);
    }
    
    this(t x, t y, t z) {
        set('x', x);
        set('y', y);
        set('z', z);
    }
    
    this(t x, t y, t z, t w) {
        set('x', x);
        set('y', y);
        set('z', z);
        set('w', w);
    }
    
    @property bool ok() {
        foreach(v; vector) {
            if(isNaN(v)) {
                return false;
            }
        }
        return true;
    }
        
    /*@property t[dimension] vector() {
        t[dimension] ret;
        
        static if(dimension == 2) { ret = [x, y]; }
        static if(dimension == 3) { ret = [x, y, z]; }
        static if(dimension == 4) { ret = [x, y, z, w]; }
        
        return ret;
    }*/
    
    void clear(t value) {
        for(int i = 0; i < dimension; i++) {
            vector[i] = value;
        }
    }

    template get() {
        t get(char coord) {
            static if(dimension >= 4) {
                assert(inPattern(coord, "xyzw"));
            
                if(coord == 'w') {
                    return vector[3];
                }
            }
            static if(dimension >= 3) {
                assert(inPattern(coord, "xyz"));
                
                if(coord == 'z') {
                    return vector[2];
                }
            }
            static if(dimension >= 2) {
                assert(inPattern(coord, "xy"));
                
                if(coord == 'y') { 
                    return vector[1];
                }
                return vector[0];
            }
        }
    }

    template set() {
        void set(char coord, t value) {
            static if(dimension >= 2) { if(coord == 'x') { vector[0] = value; }
                                        else if(coord == 'y') { vector[1] = value; } }
            static if(dimension >= 3) { if(coord == 'z') { vector[2] = value; } }
            static if(dimension == 4) { if(coord == 'w') { vector[3] = value; } }
         }
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
    //vec2 f = vec2(1.0f);
    //vec4 b = vec4(12345,2,3,4,5);
    vec4 v = vec4(1.0f, 2.0f, 3.0f, 4.0f);
    writefln("%s", v.x);
    writefln("%s", v.y);
    writefln("%s", v.z);
    writefln("%s", v.w);
    writefln("%s", v.xwwz);
    writefln("%s", v.xyzwyxxzwwwz);
    writefln("%s", v.vector.ptr);
}