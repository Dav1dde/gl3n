import std.stdio : writefln;
import std.string : inPattern;
import std.math : isNaN



struct Vector(type, int dimension_) {
    alias type t;
    static const int dimension = dimension_;
    
    static assert((dimension >= 2) && (dimension <= 4));
    
    static if(dimension >= 1) { t x; };
    static if(dimension >= 2) { t y; };
    static if(dimension >= 3) { t z; };
    static if(dimension >= 4) { t w; };

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
        static if (dim >= 1) if (isNaN(x)) return false;
        static if (dim >= 2) if (isNaN(y)) return false;
        static if (dim >= 3) if (isNaN(z)) return false;
        static if (dim >= 4) if (isNaN(w)) return false;
        return true;
    }
        
    @property t[dimension] vector() {
        t[dimension] ret;
        
        static if(dimension == 2) { ret = [x, y]; }
        static if(dimension == 3) { ret = [x, y, z]; }
        static if(dimension == 4) { ret = [x, y, z, w]; }
        
        return ret;
    }
    
    void clear(t value) {
        static if(dimension >= 1) { x = value; }
        static if(dimension >= 2) { y = value; }
        static if(dimension >= 3) { z = value; }
        static if(dimension >= 4) { w = value; }
    }
             
    t get(char coord) {
        static if(dimension >= 4) {
            assert(inPattern(coord, "xyzw"));
        
            if(coord == 'w') {
                return w;
            }
        }
        static if(dimension >= 3) {
            assert(inPattern(coord, "xyz"));
            
            if(coord == 'z') {
                return z;
            }
        }
        static if(dimension >= 2) {
            assert(inPattern(coord, "xy"));
            
            if(coord == 'y') { 
                return y;
            }
            return x;
         }
     }
 
    void set(char coord, t value) {
        static if(dimension >= 2) { if(coord == 'x') { x = value; }
                                    else if(coord == 'y') { y = value; } }
        static if(dimension >= 3) { if(coord == 'z') { z = value; } }
        static if(dimension == 4) { if(coord == 'w') { w = value; } }
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
    vec4 v = vec4(1.0f, 2.0f, 3.0f, 4.0f);
    writefln("%s", v.x);
    writefln("%s", v.y);
    writefln("%s", v.z);
    writefln("%s", v.w);
    writefln("%s", v.xwwz);
    writefln("%s", v.xyzwyxxzwwwz);
    writefln("%s", v.vector.ptr);
}