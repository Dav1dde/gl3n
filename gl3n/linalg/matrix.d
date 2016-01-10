/**
gl3n.linalg.matrix

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

module gl3n.linalg.matrix;

import gl3n.linalg.vec;
import gl3n.math : PI, sin, cos, tan;

import std.math : isNaN, isInfinity;
import std.traits : isIntegral;
import std.string : format, rightJustify;
import std.array : join;
import std.algorithm : min, reduce;
import std.traits : isFloatingPoint;

version(NoReciprocalMul) {
    private enum rmul = false;
} else {
    private enum rmul = true;
}

/// Base template for all matrix-types.
/// Params:
///  type = all values get stored as this type
///  rows_ = rows of the matrix
///  cols_ = columns of the matrix
/// Examples:
/// ---
/// alias Matrix!(float, 4, 4) mat4;
/// alias Matrix!(double, 3, 4) mat34d;
/// alias Matrix!(real, 2, 2) mat2r;
/// ---
struct Matrix(type, int rows_, int cols_) if((rows_ > 0) && (cols_ > 0)) {
    alias type mt; /// Holds the internal type of the matrix;
    static const int rows = rows_; /// Holds the number of rows;
    static const int cols = cols_; /// Holds the number of columns;
    
    /// Holds the matrix $(RED row-major) in memory.
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
    
    /// Returns the pointer to the stored values as OpenGL requires it.
    /// Note this will return a pointer to a $(RED row-major) matrix,
    /// $(RED this means you've to set the transpose argument to GL_TRUE when passing it to OpenGL).
    /// Examples:
    /// ---
    /// // 3rd argument = GL_TRUE
    /// glUniformMatrix4fv(programs.main.model, 1, GL_TRUE, mat4.translation(-0.5f, -0.5f, 1.0f).value_ptr);
    /// ---
    @property auto value_ptr() const { return matrix[0].ptr; }
    
    /// Returns the current matrix formatted as flat string.
    @property string as_string() {
        return format("%s", matrix);
    }
    alias as_string toString; /// ditto
    
    /// Returns the current matrix as pretty formatted string.
    @property string as_pretty_string() {
        string fmtr = "%s";
        
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
    alias as_pretty_string toPrettyString; /// ditto
    
    @safe pure nothrow:
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
            static assert(false, "Too many arguments passed to constructor");
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
        } else static if(isDynamicArray!T) {
            foreach(j; 0..cols*rows)
                matrix[j / cols][j % cols] = head[j];
        } else {
            static assert(false, "Matrix constructor argument must be of type " ~ mt.stringof ~ " or Vector, not " ~ T.stringof);
        }
    }
    
    private void construct(int i)() { // terminate
        static assert(i == rows*cols, "Not enough arguments passed to constructor");
    }
    
    /// Constructs the matrix:
    /// If a single value is passed, the matrix will be cleared with this value (each column in each row will contain this value).
    /// If a matrix with more rows and columns is passed, the matrix will be the upper left nxm matrix.
    /// If a matrix with less rows and columns is passed, the passed matrix will be stored in the upper left of an identity matrix.
    /// It's also allowed to pass vectors and scalars at a time, but the vectors dimension must match the number of columns and align correctly.
    /// Examples:
    /// ---
    /// mat2 m2 = mat2(0.0f); // mat2 m2 = mat2(0.0f, 0.0f, 0.0f, 0.0f);
    /// mat3 m3 = mat3(m2); // mat3 m3 = mat3(0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f);
    /// mat3 m3_2 = mat3(vec3(1.0f, 2.0f, 3.0f), 4.0f, 5.0f, 6.0f, vec3(7.0f, 8.0f, 9.0f));
    /// mat4 m4 = mat4.identity; // just an identity matrix
    /// mat3 m3_3 = mat3(m4); // mat3 m3_3 = mat3.identity
    /// ---
    this(Args...)(Args args) {
        construct!(0)(args);
    }
    
    /// ditto
    this(T)(T mat) if(is_matrix!T && (T.cols >= cols) && (T.rows >= rows)) {
        foreach(r; TupleRange!(0, rows)) {
            foreach(c; TupleRange!(0, cols)) {
                matrix[r][c] = mat.matrix[r][c];
            }
        }
    }
    
    /// ditto
    this(T)(T mat) if(is_matrix!T && (T.cols < cols) && (T.rows < rows)) {
        make_identity();
        
        foreach(r; TupleRange!(0, T.rows)) {
            foreach(c; TupleRange!(0, T.cols)) {
                matrix[r][c] = mat.matrix[r][c];
            }
        }
    }
    
    /// ditto
    this()(mt value) {
        clear(value);
    }
    
    /// Returns true if all values are not nan and finite, otherwise false.
    @property bool isFinite() const {
        static if(isIntegral!type) {
            return true;
        }
        else {
            foreach(row; matrix) {
                foreach(col; row) {
                    if(isNaN(col) || isInfinity(col)) {
                        return false;
                    }
                }
            }
            return true;
        }
        
    }
    deprecated("Use isFinite instead of ok") alias ok = isFinite;
    
    /// Sets all values of the matrix to value (each column in each row will contain this value).
    void clear(mt value) {
        foreach(r; TupleRange!(0, rows)) {
            foreach(c; TupleRange!(0, cols)) {
                matrix[r][c] = value;
            }
        }
    }
    
    unittest {
        mat2 m2 = mat2(1.0f, 1.0f, vec2(2.0f, 2.0f));
        assert(m2.matrix == [[1.0f, 1.0f], [2.0f, 2.0f]]);
        m2.clear(3.0f);
        assert(m2.matrix == [[3.0f, 3.0f], [3.0f, 3.0f]]);
        assert(m2.isFinite);
        m2.clear(float.nan);
        assert(!m2.isFinite);
        m2.clear(float.infinity);
        assert(!m2.isFinite);
        m2.clear(0.0f);
        assert(m2.isFinite);
        
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
        assert(mat3(m4).matrix == [[1.0f, 1.0f, 1.0f],
                [2.0f, 2.0f, 2.0f],
                [3.0f, 3.0f, 3.0f]]);
        assert(mat2(mat3(m4)).matrix == [[1.0f, 1.0f], [2.0f, 2.0f]]);
        assert(mat2(m4).matrix == mat2(mat3(m4)).matrix);
        assert(mat4(mat3(m4)).matrix == [[1.0f, 1.0f, 1.0f, 0.0f],
                [2.0f, 2.0f, 2.0f, 0.0f],
                [3.0f, 3.0f, 3.0f, 0.0f],
                [0.0f, 0.0f, 0.0f, 1.0f]]);
        
        Matrix!(float, 2, 3) mt1 = Matrix!(float, 2, 3)(1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f);
        Matrix!(float, 3, 2) mt2 = Matrix!(float, 3, 2)(6.0f, -1.0f, 3.0f, 2.0f, 0.0f, -3.0f);
        
        assert(mt1.matrix == [[1.0f, 2.0f, 3.0f], [4.0f, 5.0f, 6.0f]]);
        assert(mt2.matrix == [[6.0f, -1.0f], [3.0f, 2.0f], [0.0f, -3.0f]]);
        
        static assert(!__traits(compiles, mat2(1, 2, 1)));
        static assert(!__traits(compiles, mat3(1, 2, 3, 1, 2, 3, 1, 2)));
        static assert(!__traits(compiles, mat4(1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3)));
        
        auto m5 = mat2([0.0f,1,2,3]);
        assert(m5.matrix == [[0.0f, 1.0f], [2.0f, 3.0f]]);
        
        auto m6 = Matrix!(int, 2, 3)([0,1,2,3,4,5]);
        assert(m6.matrix == [[0, 1, 2], [3, 4, 5]]);
    }
    
    static if(rows == cols) {
        /// Makes the current matrix an identity matrix.
        void make_identity() {
            clear(0);
            foreach(r; TupleRange!(0, rows)) {
                matrix[r][r] = 1;
            }
        }
        
        /// Returns a identity matrix.
        static @property Matrix identity() {
            Matrix ret;
            ret.clear(0);
            
            foreach(r; TupleRange!(0, rows)) {
                ret.matrix[r][r] = 1;
            }
            
            return ret;
        }
        
        /// Transposes the current matrix;
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
    
    /// Returns a transposed copy of the matrix.
    @property Matrix!(mt, cols, rows) transposed() const {
        typeof(return) ret;
        
        foreach(r; TupleRange!(0, rows)) {
            foreach(c; TupleRange!(0, cols)) {
                ret.matrix[c][r] = matrix[r][c];
            }
        }
        
        return ret;
    }
    
    // transposed already tested in last unittest
    
    
    static if((rows == 2) && (cols == 2)) {
        @property mt det() const {
            return (matrix[0][0] * matrix[1][1] - matrix[0][1] * matrix[1][0]);
        }
        
        private Matrix invert(ref Matrix mat) const {
            static if(isFloatingPoint!mt && rmul) {
                mt d = 1 / det;
                
                mat.matrix = [[matrix[1][1]*d, -matrix[0][1]*d],
                    [-matrix[1][0]*d, matrix[0][0]*d]];
            } else {
                mt d = det;
                
                mat.matrix = [[matrix[1][1]/d, -matrix[0][1]/d],
                    [-matrix[1][0]/d, matrix[0][0]/d]];
            }
            
            return mat;
        }
        
        static Matrix scaling(mt x, mt y) {
            Matrix ret = Matrix.identity;
            
            ret.matrix[0][0] = x;
            ret.matrix[1][1] = y;
            
            return ret;
        }
        
        Matrix scale(mt x, mt y) {
            this = Matrix.scaling(x, y) * this;
            return this;
        }
        
        unittest {
            assert(mat2.scaling(3, 3).matrix == mat2.identity.scale(3, 3).matrix);
            assert(mat2.scaling(3, 3).matrix == [[3.0f, 0.0f], [0.0f, 3.0f]]);
        }
        
    } else static if((rows == 3) && (cols == 3)) {
        @property mt det() const {
            return (matrix[0][0] * matrix[1][1] * matrix[2][2]
                + matrix[0][1] * matrix[1][2] * matrix[2][0]
                + matrix[0][2] * matrix[1][0] * matrix[2][1]
                - matrix[0][2] * matrix[1][1] * matrix[2][0]
                - matrix[0][1] * matrix[1][0] * matrix[2][2]
                - matrix[0][0] * matrix[1][2] * matrix[2][1]);
        }
        
        private Matrix invert(ref Matrix mat) const {
            static if(isFloatingPoint!mt && rmul) {
                mt d = 1 / det;
                enum op = "*";
            } else {
                mt d = det;
                enum op = "/";
            }
            
            mixin(`
            mat.matrix = [[(matrix[1][1] * matrix[2][2] - matrix[1][2] * matrix[2][1])`~op~`d,
                           (matrix[0][2] * matrix[2][1] - matrix[0][1] * matrix[2][2])`~op~`d,
                           (matrix[0][1] * matrix[1][2] - matrix[0][2] * matrix[1][1])`~op~`d],
                          [(matrix[1][2] * matrix[2][0] - matrix[1][0] * matrix[2][2])`~op~`d,
                           (matrix[0][0] * matrix[2][2] - matrix[0][2] * matrix[2][0])`~op~`d,
                           (matrix[0][2] * matrix[1][0] - matrix[0][0] * matrix[1][2])`~op~`d],
                          [(matrix[1][0] * matrix[2][1] - matrix[1][1] * matrix[2][0])`~op~`d,
                           (matrix[0][1] * matrix[2][0] - matrix[0][0] * matrix[2][1])`~op~`d,
                           (matrix[0][0] * matrix[1][1] - matrix[0][1] * matrix[1][0])`~op~`d]];
            `);
            
            return mat;
        }
    } else static if((rows == 4) && (cols == 4)) {
        /// Returns the determinant of the current matrix (2x2, 3x3 and 4x4 matrices).
        @property mt det() const {
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
        
        private Matrix invert(ref Matrix mat) const {
            static if(isFloatingPoint!mt && rmul) {
                mt d = 1 / det;
                enum op = "*";
            } else {
                mt d = det;
                enum op = "/";
            }
            
            mixin(`
            mat.matrix = [[(matrix[1][1] * matrix[2][2] * matrix[3][3] + matrix[1][2] * matrix[2][3] * matrix[3][1] + matrix[1][3] * matrix[2][1] * matrix[3][2]
                          - matrix[1][1] * matrix[2][3] * matrix[3][2] - matrix[1][2] * matrix[2][1] * matrix[3][3] - matrix[1][3] * matrix[2][2] * matrix[3][1])`~op~`d,
                           (matrix[0][1] * matrix[2][3] * matrix[3][2] + matrix[0][2] * matrix[2][1] * matrix[3][3] + matrix[0][3] * matrix[2][2] * matrix[3][1]
                          - matrix[0][1] * matrix[2][2] * matrix[3][3] - matrix[0][2] * matrix[2][3] * matrix[3][1] - matrix[0][3] * matrix[2][1] * matrix[3][2])`~op~`d,
                           (matrix[0][1] * matrix[1][2] * matrix[3][3] + matrix[0][2] * matrix[1][3] * matrix[3][1] + matrix[0][3] * matrix[1][1] * matrix[3][2]
                          - matrix[0][1] * matrix[1][3] * matrix[3][2] - matrix[0][2] * matrix[1][1] * matrix[3][3] - matrix[0][3] * matrix[1][2] * matrix[3][1])`~op~`d,
                           (matrix[0][1] * matrix[1][3] * matrix[2][2] + matrix[0][2] * matrix[1][1] * matrix[2][3] + matrix[0][3] * matrix[1][2] * matrix[2][1]
                          - matrix[0][1] * matrix[1][2] * matrix[2][3] - matrix[0][2] * matrix[1][3] * matrix[2][1] - matrix[0][3] * matrix[1][1] * matrix[2][2])`~op~`d],
                          [(matrix[1][0] * matrix[2][3] * matrix[3][2] + matrix[1][2] * matrix[2][0] * matrix[3][3] + matrix[1][3] * matrix[2][2] * matrix[3][0]
                          - matrix[1][0] * matrix[2][2] * matrix[3][3] - matrix[1][2] * matrix[2][3] * matrix[3][0] - matrix[1][3] * matrix[2][0] * matrix[3][2])`~op~`d,
                           (matrix[0][0] * matrix[2][2] * matrix[3][3] + matrix[0][2] * matrix[2][3] * matrix[3][0] + matrix[0][3] * matrix[2][0] * matrix[3][2]
                          - matrix[0][0] * matrix[2][3] * matrix[3][2] - matrix[0][2] * matrix[2][0] * matrix[3][3] - matrix[0][3] * matrix[2][2] * matrix[3][0])`~op~`d,
                           (matrix[0][0] * matrix[1][3] * matrix[3][2] + matrix[0][2] * matrix[1][0] * matrix[3][3] + matrix[0][3] * matrix[1][2] * matrix[3][0]
                          - matrix[0][0] * matrix[1][2] * matrix[3][3] - matrix[0][2] * matrix[1][3] * matrix[3][0] - matrix[0][3] * matrix[1][0] * matrix[3][2])`~op~`d,
                           (matrix[0][0] * matrix[1][2] * matrix[2][3] + matrix[0][2] * matrix[1][3] * matrix[2][0] + matrix[0][3] * matrix[1][0] * matrix[2][2]
                          - matrix[0][0] * matrix[1][3] * matrix[2][2] - matrix[0][2] * matrix[1][0] * matrix[2][3] - matrix[0][3] * matrix[1][2] * matrix[2][0])`~op~`d],
                          [(matrix[1][0] * matrix[2][1] * matrix[3][3] + matrix[1][1] * matrix[2][3] * matrix[3][0] + matrix[1][3] * matrix[2][0] * matrix[3][1]
                          - matrix[1][0] * matrix[2][3] * matrix[3][1] - matrix[1][1] * matrix[2][0] * matrix[3][3] - matrix[1][3] * matrix[2][1] * matrix[3][0])`~op~`d,
                           (matrix[0][0] * matrix[2][3] * matrix[3][1] + matrix[0][1] * matrix[2][0] * matrix[3][3] + matrix[0][3] * matrix[2][1] * matrix[3][0]
                          - matrix[0][0] * matrix[2][1] * matrix[3][3] - matrix[0][1] * matrix[2][3] * matrix[3][0] - matrix[0][3] * matrix[2][0] * matrix[3][1])`~op~`d,
                           (matrix[0][0] * matrix[1][1] * matrix[3][3] + matrix[0][1] * matrix[1][3] * matrix[3][0] + matrix[0][3] * matrix[1][0] * matrix[3][1]
                          - matrix[0][0] * matrix[1][3] * matrix[3][1] - matrix[0][1] * matrix[1][0] * matrix[3][3] - matrix[0][3] * matrix[1][1] * matrix[3][0])`~op~`d,
                           (matrix[0][0] * matrix[1][3] * matrix[2][1] + matrix[0][1] * matrix[1][0] * matrix[2][3] + matrix[0][3] * matrix[1][1] * matrix[2][0]
                          - matrix[0][0] * matrix[1][1] * matrix[2][3] - matrix[0][1] * matrix[1][3] * matrix[2][0] - matrix[0][3] * matrix[1][0] * matrix[2][1])`~op~`d],
                          [(matrix[1][0] * matrix[2][2] * matrix[3][1] + matrix[1][1] * matrix[2][0] * matrix[3][2] + matrix[1][2] * matrix[2][1] * matrix[3][0]
                          - matrix[1][0] * matrix[2][1] * matrix[3][2] - matrix[1][1] * matrix[2][2] * matrix[3][0] - matrix[1][2] * matrix[2][0] * matrix[3][1])`~op~`d,
                           (matrix[0][0] * matrix[2][1] * matrix[3][2] + matrix[0][1] * matrix[2][2] * matrix[3][0] + matrix[0][2] * matrix[2][0] * matrix[3][1]
                          - matrix[0][0] * matrix[2][2] * matrix[3][1] - matrix[0][1] * matrix[2][0] * matrix[3][2] - matrix[0][2] * matrix[2][1] * matrix[3][0])`~op~`d,
                           (matrix[0][0] * matrix[1][2] * matrix[3][1] + matrix[0][1] * matrix[1][0] * matrix[3][2] + matrix[0][2] * matrix[1][1] * matrix[3][0]
                          - matrix[0][0] * matrix[1][1] * matrix[3][2] - matrix[0][1] * matrix[1][2] * matrix[3][0] - matrix[0][2] * matrix[1][0] * matrix[3][1])`~op~`d,
                           (matrix[0][0] * matrix[1][1] * matrix[2][2] + matrix[0][1] * matrix[1][2] * matrix[2][0] + matrix[0][2] * matrix[1][0] * matrix[2][1]
                          - matrix[0][0] * matrix[1][2] * matrix[2][1] - matrix[0][1] * matrix[1][0] * matrix[2][2] - matrix[0][2] * matrix[1][1] * matrix[2][0])`~op~`d]];
            `);
            
            return mat;
        }
        
        // some static fun ...
        // (1) glprogramming.com/red/appendixf.html - ortographic is broken!
        // (2) http://fly.cc.fer.hr/~unreal/theredbook/appendixg.html
        // (3) http://en.wikipedia.org/wiki/Orthographic_projection_(geometry)
        
        static if(isFloatingPoint!mt) {
            static private mt[6] cperspective(mt width, mt height, mt fov, mt near, mt far)
            in { assert(height != 0); }
            body {
                mt aspect = width/height;
                mt top = near * tan(fov*(PI/360.0));
                mt bottom = -top;
                mt right = top * aspect;
                mt left = -right;
                
                return [left, right, bottom, top, near, far];
            }
            
            /// Returns a perspective matrix (4x4 and floating-point matrices only).
            static Matrix perspective(mt width, mt height, mt fov, mt near, mt far) {
                mt[6] cdata = cperspective(width, height, fov, near, far);
                return perspective(cdata[0], cdata[1], cdata[2], cdata[3], cdata[4], cdata[5]);
            }
            
            /// ditto
            static Matrix perspective(mt left, mt right, mt bottom, mt top, mt near, mt far)
            in {
                assert(right-left != 0);
                assert(top-bottom != 0);
                assert(far-near != 0);
            }
            body {
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
            
            /// Returns an inverse perspective matrix (4x4 and floating-point matrices only).
            static Matrix perspective_inverse(mt width, mt height, mt fov, mt near, mt far) {
                mt[6] cdata = cperspective(width, height, fov, near, far);
                return perspective_inverse(cdata[0], cdata[1], cdata[2], cdata[3], cdata[4], cdata[5]);
            }
            
            /// ditto
            static Matrix perspective_inverse(mt left, mt right, mt bottom, mt top, mt near, mt far)
            in {
                assert(near != 0);
                assert(far != 0);
            }
            body {
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
            
            // (2) and (3) say this one is correct
            /// Returns an orthographic matrix (4x4 and floating-point matrices only).
            static Matrix orthographic(mt left, mt right, mt bottom, mt top, mt near, mt far)
            in {
                assert(right-left != 0);
                assert(top-bottom != 0);
                assert(far-near != 0);
            }
            body {
                Matrix ret;
                ret.clear(0);
                
                ret.matrix[0][0] = 2/(right-left);
                ret.matrix[0][3] = -(right+left)/(right-left);
                ret.matrix[1][1] = 2/(top-bottom);
                ret.matrix[1][3] = -(top+bottom)/(top-bottom);
                ret.matrix[2][2] = -2/(far-near);
                ret.matrix[2][3] = -(far+near)/(far-near);
                ret.matrix[3][3] = 1;
                
                return ret;
            }
            
            // (1) and (2) say this one is correct
            /// Returns an inverse ortographic matrix (4x4 and floating-point matrices only).
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
            
            /// Returns a look at matrix (4x4 and floating-point matrices only).
            static Matrix look_at(Vector!(mt, 3) eye, Vector!(mt, 3) target, Vector!(mt, 3) up) {
                alias Vector!(mt, 3) vec3mt;
                vec3mt look_dir = (target - eye).normalized;
                vec3mt up_dir = up.normalized;
                
                vec3mt right_dir = cross(look_dir, up_dir).normalized;
                vec3mt perp_up_dir = cross(right_dir, look_dir);
                
                Matrix ret = Matrix.identity;
                ret.matrix[0][0..3] = right_dir.vector[];
                ret.matrix[1][0..3] = perp_up_dir.vector[];
                ret.matrix[2][0..3] = (-look_dir).vector[];
                
                ret.matrix[0][3] = -dot(eye, right_dir);
                ret.matrix[1][3] = -dot(eye, perp_up_dir);
                ret.matrix[2][3] = dot(eye, look_dir);
                
                return ret;
            }
            
            unittest {
                mt[6] cp = cperspective(600f, 900f, 60f, 1f, 100f);
                assert(cp[4] == 1.0f);
                assert(cp[5] == 100.0f);
                assert(cp[0] == -cp[1]);
                assert((cp[0] < -0.38489f) && (cp[0] > -0.38491f));
                assert(cp[2] == -cp[3]);
                assert((cp[2] < -0.577349f) && (cp[2] > -0.577351f));
                
                assert(mat4.perspective(600f, 900f, 60.0, 1.0, 100.0) == mat4.perspective(cp[0], cp[1], cp[2], cp[3], cp[4], cp[5]));
                float[4][4] m4p = mat4.perspective(600f, 900f, 60.0, 1.0, 100.0).matrix;
                assert((m4p[0][0] < 2.598077f) && (m4p[0][0] > 2.598075f));
                assert(m4p[0][2] == 0.0f);
                assert((m4p[1][1] < 1.732052) && (m4p[1][1] > 1.732050));
                assert(m4p[1][2] == 0.0f);
                assert((m4p[2][2] < -1.020201) && (m4p[2][2] > -1.020203));
                assert((m4p[2][3] < -2.020201) && (m4p[2][3] > -2.020203));
                assert((m4p[3][2] < -0.9f) && (m4p[3][2] > -1.1f));
                
                float[4][4] m4pi = mat4.perspective_inverse(600f, 900f, 60.0, 1.0, 100.0).matrix;
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
    
    static if((rows == cols) && (rows >= 3) && (rows <= 4)) {
        /// Returns a translation matrix (3x3 and 4x4 matrices).
        static Matrix translation(mt x, mt y, mt z) {
            Matrix ret = Matrix.identity;
            
            ret.matrix[0][cols-1] = x;
            ret.matrix[1][cols-1] = y;
            ret.matrix[2][cols-1] = z;
            
            return ret;
        }
        
        /// ditto
        static Matrix translation(Vector!(mt, 3) v) {
            Matrix ret = Matrix.identity;
            
            ret.matrix[0][cols-1] = v.x;
            ret.matrix[1][cols-1] = v.y;
            ret.matrix[2][cols-1] = v.z;
            
            return ret;
        }
        
        /// Applys a translation on the current matrix and returns $(I this) (3x3 and 4x4 matrices).
        Matrix translate(mt x, mt y, mt z) {
            this = Matrix.translation(x, y, z) * this;
            return this;
        }
        
        /// ditto
        Matrix translate(Vector!(mt, 3) v) {
            this = Matrix.translation(v) * this;
            return this;
        }
        
        /// Returns a scaling matrix (3x3 and 4x4 matrices);
        static Matrix scaling(mt x, mt y, mt z) {
            Matrix ret = Matrix.identity;
            
            ret.matrix[0][0] = x;
            ret.matrix[1][1] = y;
            ret.matrix[2][2] = z;
            
            return ret;
        }
        
        /// Applys a scale to the current matrix and returns $(I this) (3x3 and 4x4 matrices).
        Matrix scale(mt x, mt y, mt z) {
            this = Matrix.scaling(x, y, z) * this;
            return this;
        }
        
        unittest {
            mat3 m3 = mat3.identity;
            assert(m3.translate(1.0f, 2.0f, 3.0f).matrix == mat3.translation(1.0f, 2.0f, 3.0f).matrix);
            assert(mat3.translation(1.0f, 2.0f, 3.0f).matrix == [[1.0f, 0.0f, 1.0f],
                    [0.0f, 1.0f, 2.0f],
                    [0.0f, 0.0f, 3.0f]]);
            assert(mat3.identity.translate(0.0f, 1.0f, 2.0f).matrix == mat3.translation(0.0f, 1.0f, 2.0f).matrix);
            
            mat3 m31 = mat3.identity;
            assert(m31.translate(vec3(1.0f, 2.0f, 3.0f)).matrix == mat3.translation(vec3(1.0f, 2.0f, 3.0f)).matrix);
            assert(mat3.translation(vec3(1.0f, 2.0f, 3.0f)).matrix == [[1.0f, 0.0f, 1.0f],
                    [0.0f, 1.0f, 2.0f],
                    [0.0f, 0.0f, 3.0f]]);
            assert(mat3.identity.translate(vec3(0.0f, 1.0f, 2.0f)).matrix == mat3.translation(vec3(0.0f, 1.0f, 2.0f)).matrix);
            
            assert(m3.scaling(0.0f, 1.0f, 2.0f).matrix == mat3.scaling(0.0f, 1.0f, 2.0f).matrix);
            assert(mat3.scaling(0.0f, 1.0f, 2.0f).matrix == [[0.0f, 0.0f, 0.0f],
                    [0.0f, 1.0f, 0.0f],
                    [0.0f, 0.0f, 2.0f]]);
            assert(mat3.identity.scale(0.0f, 1.0f, 2.0f).matrix == mat3.scaling(0.0f, 1.0f, 2.0f).matrix);
            
            // same tests for 4x4
            
            mat4 m4 = mat4(1.0f);
            assert(m4.translation(1.0f, 2.0f, 3.0f).matrix == mat4.translation(1.0f, 2.0f, 3.0f).matrix);
            assert(mat4.translation(1.0f, 2.0f, 3.0f).matrix == [[1.0f, 0.0f, 0.0f, 1.0f],
                    [0.0f, 1.0f, 0.0f, 2.0f],
                    [0.0f, 0.0f, 1.0f, 3.0f],
                    [0.0f, 0.0f, 0.0f, 1.0f]]);
            assert(mat4.identity.translate(0.0f, 1.0f, 2.0f).matrix == mat4.translation(0.0f, 1.0f, 2.0f).matrix);
            
            assert(m4.scaling(0.0f, 1.0f, 2.0f).matrix == mat4.scaling(0.0f, 1.0f, 2.0f).matrix);
            assert(mat4.scaling(0.0f, 1.0f, 2.0f).matrix == [[0.0f, 0.0f, 0.0f, 0.0f],
                    [0.0f, 1.0f, 0.0f, 0.0f],
                    [0.0f, 0.0f, 2.0f, 0.0f],
                    [0.0f, 0.0f, 0.0f, 1.0f]]);
            assert(mat4.identity.scale(0.0f, 1.0f, 2.0f).matrix == mat4.scaling(0.0f, 1.0f, 2.0f).matrix);
        }
    }
    
    
    static if((rows == cols) && (rows >= 3)) {
        static if(isFloatingPoint!mt) {
            /// Returns an identity matrix with an applied rotate_axis around an arbitrary axis (nxn matrices, n >= 3).
            static Matrix rotation(real alpha, Vector!(mt, 3) axis) {
                Matrix mult = Matrix.identity;
                
                if(axis.length != 1) {
                    axis.normalize();
                }
                
                real cosa = cos(alpha);
                real sina = sin(alpha);
                
                Vector!(mt, 3) temp = (1 - cosa)*axis;
                
                mult.matrix[0][0] = to!mt(cosa + temp.x * axis.x);
                mult.matrix[0][1] = to!mt(       temp.x * axis.y + sina * axis.z);
                mult.matrix[0][2] = to!mt(       temp.x * axis.z - sina * axis.y);
                mult.matrix[1][0] = to!mt(       temp.y * axis.x - sina * axis.z);
                mult.matrix[1][1] = to!mt(cosa + temp.y * axis.y);
                mult.matrix[1][2] = to!mt(       temp.y * axis.z + sina * axis.x);
                mult.matrix[2][0] = to!mt(       temp.z * axis.x + sina * axis.y);
                mult.matrix[2][1] = to!mt(       temp.z * axis.y - sina * axis.x);
                mult.matrix[2][2] = to!mt(cosa + temp.z * axis.z);
                
                return mult;
            }
            
            /// ditto
            static Matrix rotation(real alpha, mt x, mt y, mt z) {
                return Matrix.rotation(alpha, Vector!(mt, 3)(x, y, z));
            }
            
            /// Returns an identity matrix with an applied rotation around the x-axis (nxn matrices, n >= 3).
            static Matrix xrotation(real alpha) {
                Matrix mult = Matrix.identity;
                
                mt cosamt = to!mt(cos(alpha));
                mt sinamt = to!mt(sin(alpha));
                
                mult.matrix[1][1] = cosamt;
                mult.matrix[1][2] = -sinamt;
                mult.matrix[2][1] = sinamt;
                mult.matrix[2][2] = cosamt;
                
                return mult;
            }
            
            /// Returns an identity matrix with an applied rotation around the y-axis (nxn matrices, n >= 3).
            static Matrix yrotation(real alpha) {
                Matrix mult = Matrix.identity;
                
                mt cosamt = to!mt(cos(alpha));
                mt sinamt = to!mt(sin(alpha));
                
                mult.matrix[0][0] = cosamt;
                mult.matrix[0][2] = sinamt;
                mult.matrix[2][0] = -sinamt;
                mult.matrix[2][2] = cosamt;
                
                return mult;
            }
            
            /// Returns an identity matrix with an applied rotation around the z-axis (nxn matrices, n >= 3).
            static Matrix zrotation(real alpha) {
                Matrix mult = Matrix.identity;
                
                mt cosamt = to!mt(cos(alpha));
                mt sinamt = to!mt(sin(alpha));
                
                mult.matrix[0][0] = cosamt;
                mult.matrix[0][1] = -sinamt;
                mult.matrix[1][0] = sinamt;
                mult.matrix[1][1] = cosamt;
                
                return mult;
            }
            
            Matrix rotate(real alpha, Vector!(mt, 3) axis) {
                this = rotation(alpha, axis) * this;
                return this;
            }
            
            /// Rotates the current matrix around the x-axis and returns $(I this) (nxn matrices, n >= 3).
            Matrix rotatex(real alpha) {
                this = xrotation(alpha) * this;
                return this;
            }
            
            /// Rotates the current matrix around the y-axis and returns $(I this) (nxn matrices, n >= 3).
            Matrix rotatey(real alpha) {
                this = yrotation(alpha) * this;
                return this;
            }
            
            /// Rotates the current matrix around the z-axis and returns $(I this) (nxn matrices, n >= 3).
            Matrix rotatez(real alpha) {
                this = zrotation(alpha) * this;
                return this;
            }
            
            unittest {
                assert(mat4.xrotation(0).matrix == [[1.0f, 0.0f, 0.0f, 0.0f],
                        [0.0f, 1.0f, -0.0f, 0.0f],
                        [0.0f, 0.0f, 1.0f, 0.0f],
                        [0.0f, 0.0f, 0.0f, 1.0f]]);
                assert(mat4.yrotation(0).matrix == [[1.0f, 0.0f, 0.0f, 0.0f],
                        [0.0f, 1.0f, 0.0f, 0.0f],
                        [0.0f, 0.0f, 1.0f, 0.0f],
                        [0.0f, 0.0f, 0.0f, 1.0f]]);
                assert(mat4.zrotation(0).matrix == [[1.0f, -0.0f, 0.0f, 0.0f],
                        [0.0f, 1.0f, 0.0f, 0.0f],
                        [0.0f, 0.0f, 1.0f, 0.0f],
                        [0.0f, 0.0f, 0.0f, 1.0f]]);
                mat4 xro = mat4.identity;
                xro.rotatex(0);
                assert(mat4.xrotation(0).matrix == xro.matrix);
                assert(xro.matrix == mat4.identity.rotatex(0).matrix);
                assert(xro.matrix == mat4.rotation(0, vec3(1.0f, 0.0f, 0.0f)).matrix);
                mat4 yro = mat4.identity;
                yro.rotatey(0);
                assert(mat4.yrotation(0).matrix == yro.matrix);
                assert(yro.matrix == mat4.identity.rotatey(0).matrix);
                assert(yro.matrix == mat4.rotation(0, vec3(0.0f, 1.0f, 0.0f)).matrix);
                mat4 zro = mat4.identity;
                xro.rotatez(0);
                assert(mat4.zrotation(0).matrix == zro.matrix);
                assert(zro.matrix == mat4.identity.rotatez(0).matrix);
                assert(zro.matrix == mat4.rotation(0, vec3(0.0f, 0.0f, 1.0f)).matrix);
            }
        } // isFloatingPoint
        
        
        /// Sets the translation of the matrix (nxn matrices, n >= 3).
        void set_translation(mt[] values...) // intended to be a property
        in { assert(values.length >= (rows-1)); }
        body {
            foreach(r; TupleRange!(0, rows-1)) {
                matrix[r][rows-1] = values[r];
            }
        }
        
        /// Copyies the translation from mat to the current matrix (nxn matrices, n >= 3).
        void set_translation(Matrix mat) {
            foreach(r; TupleRange!(0, rows-1)) {
                matrix[r][rows-1] = mat.matrix[r][rows-1];
            }
        }
        
        /// Returns an identity matrix with the current translation applied (nxn matrices, n >= 3)..
        Matrix get_translation() {
            Matrix ret = Matrix.identity;
            
            foreach(r; TupleRange!(0, rows-1)) {
                ret.matrix[r][rows-1] = matrix[r][rows-1];
            }
            
            return ret;
        }
        
        unittest {
            mat3 m3 = mat3(0.0f, 1.0f, 2.0f,
                3.0f, 4.0f, 5.0f,
                6.0f, 7.0f, 1.0f);
            assert(m3.get_translation().matrix == [[1.0f, 0.0f, 2.0f], [0.0f, 1.0f, 5.0f], [0.0f, 0.0f, 1.0f]]);
            m3.set_translation(mat3.identity);
            assert(mat3.identity.matrix == m3.get_translation().matrix);
            m3.set_translation([2.0f, 5.0f]);
            assert(m3.get_translation().matrix == [[1.0f, 0.0f, 2.0f], [0.0f, 1.0f, 5.0f], [0.0f, 0.0f, 1.0f]]);
            assert(mat3.identity.matrix == mat3.identity.get_translation().matrix);
            
            mat4 m4 = mat4(0.0f, 1.0f, 2.0f, 3.0f,
                4.0f, 5.0f, 6.0f, 7.0f,
                8.0f, 9.0f, 10.0f, 11.0f,
                12.0f, 13.0f, 14.0f, 1.0f);
            assert(m4.get_translation().matrix == [[1.0f, 0.0f, 0.0f, 3.0f],
                    [0.0f, 1.0f, 0.0f, 7.0f],
                    [0.0f, 0.0f, 1.0f, 11.0f],
                    [0.0f, 0.0f, 0.0f, 1.0f]]);
            m4.set_translation(mat4.identity);
            assert(mat4.identity.matrix == m4.get_translation().matrix);
            m4.set_translation([3.0f, 7.0f, 11.0f]);
            assert(m4.get_translation().matrix == [[1.0f, 0.0f, 0.0f, 3.0f],
                    [0.0f, 1.0f, 0.0f, 7.0f],
                    [0.0f, 0.0f, 1.0f, 11.0f],
                    [0.0f, 0.0f, 0.0f, 1.0f]]);
            assert(mat4.identity.matrix == mat4.identity.get_translation().matrix);
        }
        
        /// Sets the scale of the matrix (nxn matrices, n >= 3).
        void set_scale(mt[] values...)
        in { assert(values.length >= (rows-1)); }
        body {
            foreach(r; TupleRange!(0, rows-1)) {
                matrix[r][r] = values[r];
            }
        }
        
        /// Copyies the scale from mat to the current matrix (nxn matrices, n >= 3).
        void set_scale(Matrix mat) {
            foreach(r; TupleRange!(0, rows-1)) {
                matrix[r][r] = mat.matrix[r][r];
            }
        }
        
        /// Returns an identity matrix with the current scale applied (nxn matrices, n >= 3).
        Matrix get_scale() {
            Matrix ret = Matrix.identity;
            
            foreach(r; TupleRange!(0, rows-1)) {
                ret.matrix[r][r] = matrix[r][r];
            }
            
            return ret;
        }
        
        unittest {
            mat3 m3 = mat3(0.0f, 1.0f, 2.0f,
                3.0f, 4.0f, 5.0f,
                6.0f, 7.0f, 1.0f);
            assert(m3.get_scale().matrix == [[0.0f, 0.0f, 0.0f], [0.0f, 4.0f, 0.0f], [0.0f, 0.0f, 1.0f]]);
            m3.set_scale(mat3.identity);
            assert(mat3.identity.matrix == m3.get_scale().matrix);
            m3.set_scale([0.0f, 4.0f]);
            assert(m3.get_scale().matrix == [[0.0f, 0.0f, 0.0f], [0.0f, 4.0f, 0.0f], [0.0f, 0.0f, 1.0f]]);
            assert(mat3.identity.matrix == mat3.identity.get_scale().matrix);
            
            mat4 m4 = mat4(0.0f, 1.0f, 2.0f, 3.0f,
                4.0f, 5.0f, 6.0f, 7.0f,
                8.0f, 9.0f, 10.0f, 11.0f,
                12.0f, 13.0f, 14.0f, 1.0f);
            assert(m4.get_scale().matrix == [[0.0f, 0.0f, 0.0f, 0.0f],
                    [0.0f, 5.0f, 0.0f, 0.0f],
                    [0.0f, 0.0f, 10.0f, 0.0f],
                    [0.0f, 0.0f, 0.0f, 1.0f]]);
            m4.set_scale(mat4.identity);
            assert(mat4.identity.matrix == m4.get_scale().matrix);
            m4.set_scale([0.0f, 5.0f, 10.0f]);
            assert(m4.get_scale().matrix == [[0.0f, 0.0f, 0.0f, 0.0f],
                    [0.0f, 5.0f, 0.0f, 0.0f],
                    [0.0f, 0.0f, 10.0f, 0.0f],
                    [0.0f, 0.0f, 0.0f, 1.0f]]);
            assert(mat4.identity.matrix == mat4.identity.get_scale().matrix);
        }
        
        /// Copies rot into the upper left corner, the translation (nxn matrices, n >= 3).
        void set_rotation(Matrix!(mt, 3, 3) rot) {
            foreach(r; TupleRange!(0, 3)) {
                foreach(c; TupleRange!(0, 3)) {
                    matrix[r][c] = rot[r][c];
                }
            }
        }
        
        /// Returns an identity matrix with the current rotation applied (nxn matrices, n >= 3).
        Matrix!(mt, 3, 3) get_rotation() {
            Matrix!(mt, 3, 3) ret = Matrix!(mt, 3, 3).identity;
            
            foreach(r; TupleRange!(0, 3)) {
                foreach(c; TupleRange!(0, 3)) {
                    ret.matrix[r][c] = matrix[r][c];
                }
            }
            
            return ret;
        }
        
        unittest {
            mat3 m3 = mat3(0.0f, 1.0f, 2.0f,
                3.0f, 4.0f, 5.0f,
                6.0f, 7.0f, 1.0f);
            assert(m3.get_rotation().matrix == [[0.0f, 1.0f, 2.0f], [3.0f, 4.0f, 5.0f], [6.0f, 7.0f, 1.0f]]);
            m3.set_rotation(mat3.identity);
            assert(mat3.identity.matrix == m3.get_rotation().matrix);
            m3.set_rotation(mat3(0.0f, 1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f, 7.0f, 1.0f));
            assert(m3.get_rotation().matrix == [[0.0f, 1.0f, 2.0f], [3.0f, 4.0f, 5.0f], [6.0f, 7.0f, 1.0f]]);
            assert(mat3.identity.matrix == mat3.identity.get_rotation().matrix);
            
            mat4 m4 = mat4(0.0f, 1.0f, 2.0f, 3.0f,
                4.0f, 5.0f, 6.0f, 7.0f,
                8.0f, 9.0f, 10.0f, 11.0f,
                12.0f, 13.0f, 14.0f, 1.0f);
            assert(m4.get_rotation().matrix == [[0.0f, 1.0f, 2.0f], [4.0f, 5.0f, 6.0f], [8.0f, 9.0f, 10.0f]]);
            m4.set_rotation(mat3.identity);
            assert(mat3.identity.matrix == m4.get_rotation().matrix);
            m4.set_rotation(mat3(0.0f, 1.0f, 2.0f, 4.0f, 5.0f, 6.0f, 8.0f, 9.0f, 10.0f));
            assert(m4.get_rotation().matrix == [[0.0f, 1.0f, 2.0f], [4.0f, 5.0f, 6.0f], [8.0f, 9.0f, 10.0f]]);
            assert(mat3.identity.matrix == mat4.identity.get_rotation().matrix);
        }
        
    }
    
    static if((rows == cols) && (rows >= 2) && (rows <= 4)) {
        /// Returns an inverted copy of the current matrix (nxn matrices, 2 >= n <= 4).
        @property Matrix inverse() const {
            Matrix mat;
            invert(mat);
            return mat;
        }
        
        /// Inverts the current matrix (nxn matrices, 2 >= n <= 4).
        void invert() {
            // workaround Issue #11238
            // uses a temporary instead of invert(this)
            Matrix temp;
            invert(temp);
            this.matrix = temp.matrix;
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
    
    private void mms(mt inp, ref Matrix mat) const { // mat * scalar
        for(int r = 0; r < rows; r++) {
            for(int c = 0; c < cols; c++) {
                mat.matrix[r][c] = matrix[r][c] * inp;
            }
        }
    }
    
    private void masm(string op)(Matrix inp, ref Matrix mat) const { // mat + or - mat
        foreach(r; TupleRange!(0, rows)) {
            foreach(c; TupleRange!(0, cols)) {
                mat.matrix[r][c] = mixin("inp.matrix[r][c]" ~ op ~ "matrix[r][c]");
            }
        }
    }
    
    Matrix!(mt, rows, T.cols) opBinary(string op : "*", T)(T inp) const if(isCompatibleMatrix!T && (T.rows == cols)) {
        Matrix!(mt, rows, T.cols) ret;
        
        foreach(r; TupleRange!(0, rows)) {
            foreach(c; TupleRange!(0, T.cols)) {
                ret.matrix[r][c] = 0;
                
                foreach(c2; TupleRange!(0, cols)) {
                    ret.matrix[r][c] += matrix[r][c2] * inp.matrix[c2][c];
                }
            }
        }
        
        return ret;
    }
    
    Vector!(mt, rows) opBinary(string op : "*", T : Vector!(mt, cols))(T inp) const {
        Vector!(mt, rows) ret;
        ret.clear(0);
        
        foreach(c; TupleRange!(0, cols)) {
            foreach(r; TupleRange!(0, rows)) {
                ret.vector[r] += matrix[r][c] * inp.vector[c];
            }
        }
        
        return ret;
    }

    /+Vector!(mt, rows) opBinaryRight(string op : "*", T : Vector!(mt, cols))(T inp) const {
        return opBinary!(op,T)(inp);
    }+/
    
    Matrix opBinary(string op : "*")(mt inp) const {
        Matrix ret;
        mms(inp, ret);
        return ret;
    }
    
    Matrix opBinaryRight(string op : "*")(mt inp) const {
        return this.opBinary!(op)(inp);
    }
    
    Matrix opBinary(string op)(Matrix inp) const if((op == "+") || (op == "-")) {
        Matrix ret;
        masm!(op)(inp, ret);
        return ret;
    }
    
    void opOpAssign(string op : "*")(mt inp) {
        mms(inp, this);
    }
    
    void opOpAssign(string op)(Matrix inp) if((op == "+") || (op == "-")) {
        masm!(op)(inp, this);
    }
    
    void opOpAssign(string op)(Matrix inp) if(op == "*") {
        this = this * inp;
    }
    
    unittest {
        mat2 m2 = mat2(1.0f, 2.0f, 3.0f, 4.0f);
        vec2 v2 = vec2(2.0f, 2.0f);
        assert((m2*2).matrix == [[2.0f, 4.0f], [6.0f, 8.0f]]);
        assert((2*m2).matrix == (m2*2).matrix);
        m2 *= 2;
        assert(m2.matrix == [[2.0f, 4.0f], [6.0f, 8.0f]]);
        assert((m2*v2).vector == [12.0f, 28.0f]);
        assert((v2*m2).vector == [16.0f, 24.0f]);
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
        assert((2*m3).matrix == (m3*2).matrix);
        m3 *= 2;
        assert(m3.matrix == [[2.0f, 4.0f, 6.0f], [8.0f, 10.0f, 12.0f], [14.0f, 16.0f, 18.0f]]);
        assert((m3*v3).vector == [24.0f, 60.0f, 96.0f]);
        assert((v3*m3).vector == [48.0f, 60.0f, 72.0f]);
        assert((m3*m3).matrix == [[120.0f, 144.0f, 168.0f], [264.0f, 324.0f, 384.0f], [408.0f, 504.0f, 600.0f]]);
        assert((m3-m3).matrix == [[0.0f, 0.0f, 0.0f], [0.0f, 0.0f, 0.0f], [0.0f, 0.0f, 0.0f]]);
        assert((m3+m3).matrix == [[4.0f, 8.0f, 12.0f], [16.0f, 20.0f, 24.0f], [28.0f, 32.0f, 36.0f]]);
        m3 += m3;
        assert(m3.matrix == [[4.0f, 8.0f, 12.0f], [16.0f, 20.0f, 24.0f], [28.0f, 32.0f, 36.0f]]);
        m3 -= m3;
        assert(m3.matrix == [[0.0f, 0.0f, 0.0f], [0.0f, 0.0f, 0.0f], [0.0f, 0.0f, 0.0f]]);
        
        // test opOpAssign for matrix multiplication
        auto m4 = mat4.translation(0,1,2);
        m4 *= mat4.translation(0,-1,2);
        assert(m4 == mat4.translation(0,0,4));
        
        //TODO: tests for mat4, mat34
    }
    
    // opEqual => "alias matrix this;"
    
    bool opCast(T : bool)() const {
        return isFinite;
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

/// Pre-defined matrix types, the first number represents the number of rows
/// and the second the number of columns, if there's just one it's a nxn matrix.
/// All of these matrices are floating-point matrices.
alias Matrix!(float, 2, 2) mat2;
alias Matrix!(float, 3, 3) mat3;
alias Matrix!(float, 3, 4) mat34;
alias Matrix!(float, 4, 4) mat4;

private unittest {
    Matrix!(float,  1, 1) A = 1;
    Matrix!(double, 1, 1) B = 1;
    Matrix!(real,   1, 1) C = 1;
    Matrix!(int,    1, 1) D = 1;
    Matrix!(float,  5, 1) E = 1;
    Matrix!(double, 5, 1) F = 1;
    Matrix!(real,   5, 1) G = 1;
    Matrix!(int,    5, 1) H = 1;
    Matrix!(float,  1, 5) I = 1;
    Matrix!(double, 1, 5) J = 1;
    Matrix!(real,   1, 5) K = 1;
    Matrix!(int,    1, 5) L = 1;
}
