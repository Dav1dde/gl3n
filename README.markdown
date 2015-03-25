Gl3n
====


[![Build Status](https://travis-ci.org/Dav1dde/gl3n.svg?branch=master)](https://travis-ci.org/Dav1dde/gl3n)


gl3n provides all the math you need to work with OpenGL. Currently gl3n supports:

* linear algebra
  * vectors
  * matrices
  * quaternions
* geometry
  * axis aligned bounding boxes
  * planes
  * frustum (use it with care, not a 100% tested)
* interpolation
  * linear interpolation (lerp)
  * spherical linear interpolation (slerp)
  * hermite interpolation
  * catmull rom interpolation
* colors - hsv to rgb and rgb to hsv conversion
* nearly all GLSL defined functions (according to spec 4.1)
* the power of D, e.g. dynamic swizzling, templated types (vectors, matrices, quaternions), impressive constructors and more!

License
=======

gl3n is MIT licensed, which allows you to use it everywhere you want it.

     Copyright (c) 2011-2013, David Herberth.

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

Documentation
=============

gl3n uses ddoc for documentation. You can build it easily with the Makefile:

    make ddoc

But there is of course also an [online documentation](http://dav1dde.github.com/gl3n/) available.

Installation
============

On Linux you can build gl3n for yourself with:

    make
    make install

    # archlinux structure:
    make PREFIX=/usr
    make install PREFIX=/usr

Or for debian based systems you can use the .deb packages provided by the
[d-apt repository](http://code.google.com/p/d-apt/wiki/APT_Repository).
If you want to use gl3n on Fedora, you can use your
[package manager](https://apps.fedoraproject.org/packages/gl3n-devel) to install it!


On Windows you can also use the Makefile, but you need e.g. [cygwin](http://www.cygwin.com/) to run it.
Otherwise you can use the raw .d files and include them into your project (-I flag).


If you want to use gl3n in your project, simply include the sources or use git submodules!



Examples
========

```D
vec4 v4 = vec4(1.0f, vec3(2.0f, 3.0f, 4.0f));
vec4 v4_2 = vec4(1.0f, vec4(1.0f, 2.0f, 3.0f, 4.0f).xyz); // "dynamic" swizzling with opDispatch
vec4 v4_3 = v4_2.xxyz; // opDispatch returns a static array which you can pass directly to the ctor of a vector!

vec3 v3 = my_3dvec.rgb;
vec3 foo = v4.xyzzzwzyyxw.xyz // not useful but possible!

mat4 m4fv = mat4.translation(-0.5f, -0.54f, 0.42f).rotatex(PI).rotatez(PI/2);
glUniformMatrix4fv(location, 1, GL_TRUE, m4fv.value_ptr); // yes they are row major!

alias Matrix!(double, 4, 4) mat4d;
mat4d projection;
glGetDoublev(GL_PROJECTION_MATRIX, projection.value_ptr);

mat3 inv_view = view.rotation;
mat3 inv_view = mat3(view);

mat4 m4 = mat4(vec4(1.0f, 2.0f, 3.0f, 4.0f), 5.0f, 6.0f, 7.0f, 8.0f, vec4(...) ...); 
```

```D
    void strafe_left(float delta) { // A
        vec3 vcross = cross(up, forward).normalized;
        _position = _position + (vcross*delta);
    }

    void strafe_right(float delta) { // D
        vec3 vcross = cross(up, forward).normalized;
        _position = _position - (vcross*delta);
    }
```