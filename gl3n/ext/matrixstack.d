module gl3n.ext.matrixstack;

private {
    import gl3n.util : is_matrix;
}


/// A matrix stack similiar to OpenGLs glPushMatrix/glPopMatrix
struct MatrixStack(T) if(is_matrix!T) {
    alias T Matrix; /// Holds the internal matrix type

    Matrix top = Matrix.identity; /// The top matrix, the one you work with
    private Matrix[] stack;
    private size_t _top_pos = 0;

    alias top this;

    /// If the stack is too small to hold more items,
    /// space for $(B realloc_interval) more elements will be allocated
    size_t realloc_interval = 8;

    /// Sets the stacks initial size to $(B depth) elements
    this(size_t depth = 16) pure nothrow {
        stack.length = depth;
    }

    /// Sets the top matrix
    void set(Matrix matrix) pure nothrow {
        top = matrix;
    }

    /// Pushes the top matrix on the stack and keeps a copy as the new top matrix
    void push() pure nothrow {
        if(stack.length <= _top_pos) {
            stack.length += realloc_interval;
        }

        stack[_top_pos++] = top;
    }

    /// Pushes the top matrix on the stack and sets $(B matrix) as the new top matrix.
    void push(Matrix matrix) pure nothrow {
        push();
        top = matrix;
    }

    /// Pops a matrix from the stack and sets it as top matrix.
    /// Also returns a reference to the new top matrix.
    ref Matrix pop() pure nothrow
        in { assert(_top_pos >= 1, "popped too often from matrix stack"); }
        body {
            top = stack[--_top_pos];
            return top;
        }
}

unittest {
    import gl3n.linalg : mat4;

    auto ms = MatrixStack!mat4();

    // just a few tests to make sure it forwards correctly to Matrix
    static assert(__traits(hasMember, ms, "make_identity"));
    static assert(__traits(hasMember, ms, "transpose"));
    static assert(__traits(hasMember, ms, "invert"));
    static assert(__traits(hasMember, ms, "scale"));
    static assert(__traits(hasMember, ms, "rotate"));
    
    assert(ms.top == mat4.identity);
    assert(ms == ms.top); // make sure there is an proper alias this
    ms.push();

    auto m1 = mat4(1, 0, 0, 0,
                   0, 0, 0, 0,
                   0, 0, 1, 0,
                   0, 0, 0, 1);

    ms.set(m1);
    assert(ms.top == m1);
    assert(ms == ms.top);
    ms.push();
    
    assert(ms.top == m1);
    ms.top = ms.translate(0, 3, 2);
    ms.push(mat4.identity);
    
    assert(ms.top == mat4.identity);
    ms.push();

    ms.pop();
    assert(ms.top == mat4.identity);

    ms.pop();
    assert(ms.top == mat4(m1).translate(0, 3, 2));

    ms.pop();
    assert(ms.top == m1);

    ms.pop();
    assert(ms.top == mat4.identity);
}