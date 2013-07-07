Ddoc

$(LINK2 https://github.com/Dav1dde/gl3n, gl3n) provides all the math you need to work with OpenGL.
Currently gl3n supports:
$(UL
  $(LI linear algebra)
  $(UL
    $(LI vectors)
    $(LI matrices)
    $(LI quaternions)
  )
  $(LI geometry)
  $(UL
    $(LI axis aligned bounding boxes)
    $(LI planes)
    $(LI frustum)
  )
  $(LI interpolation)
  $(UL
    $(LI linear interpolation (lerp))
    $(LI spherical linear interpolation (slerp))
    $(LI hermite interpolation)
    $(LI catmull rom interpolation)
  )
  $(LI nearly all GLSL defined functions (according to spec 4.1))
  $(LI the power of D, e.g. dynamic swizzling, templated types (vectors, matrices, quaternions), impressive constructors and more!)
)
$(BR)
Furthermore $(LINK2 https://github.com/Dav1dde/gl3n, gl3n) is MIT licensed,
which allows you to use it everywhere you want it.
$(BR)$(BR)
A little example of gl3n's power:
---
vec4 v4 = vec4(1.0f, vec3(2.0f, 3.0f, 4.0f)); 
vec4 v4_2 = vec4(1.0f, vec4(1.0f, 2.0f, 3.0f, 4.0f).xyz); // "dynamic" swizzling with opDispatch
vec4 v4_3 = v4_2.xxyz; // opDispatch returns a vector!

vec3 v3 = my_3dvec.rgb;
vec3 foo = v4.xyzzzwzyyxw.xyz // not useful but possible!

mat4 m4fv = mat4.translation(-0.5f, -0.54f, 0.42f).rotatex(PI).rotatez(PI/2);
glUniformMatrix4fv(location, 1, GL_TRUE, m4fv.value_ptr); // yes they are row major!

alias Matrix!(double, 4, 4) mat4d;
mat4d projection;
glGetDoublev(GL_PROJECTION_MATRIX, projection.value_ptr);

mat4 m4fv = mat4.translation(-0.5f, -0.54f, 0.42f).rotatex(PI).rotatez(PI/2);
glUniformMatrix4fv(location, 1, GL_TRUE, m4fv.value_ptr); // yes they are row major! 

mat3 inv_view = view.rotation; 
mat3 inv_view = mat3(view); 

mat4 m4 = mat4(vec4(1.0f, 2.0f, 3.0f, 4.0f), 5.0f, 6.0f, 7.0f, 8.0f, vec4(...) ...); 
---

---
alias Vector!(real, 3) vec3r;

struct Camera {
    vec3 position = vec3(0.0f, 0.0f, 0.0f);
    vec3r rot = vec3r(0.0f, 0.0f, 0.0f);
    
    Camera rotatex(real alpha) {
        rot.x = rot.x + alpha;
        return this;
    }
    
    Camera rotatey(real alpha) {
        // do degrees radians conversion at compiletime!
        rot.y = clamp(rot.y + alpha, cradians!(-70.0f), cradians!(70.0f));
        return this;
    }
    
    Camera rotatez(real alpha) {
        rot.z = rot.z + alpha;
        return this;
    }
    
    Camera move(float x, float y, float z) {
        position += vec3(x, y, z);
        return this;
    }
    Camera move(vec3 s) {
        position += s;
        return this;
    }
    
    @property camera() {
        // gl3n allows chaining of matrix (also quaternion) operations 
        return mat4.identity.translate(-position.x, -position.y, -position.z)
                            .rotatex(rot.x)
                            .rotatey(rot.y);
    }
}

        // somwhere later in the code
        glUniformMatrix4fv(programs.main.view, 1, GL_TRUE, cam.camera.value_ptr);
        // or use a quaternion camera!


---