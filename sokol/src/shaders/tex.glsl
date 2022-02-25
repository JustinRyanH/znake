#pragma sokol @ctype mat4 @import("../math.zig").Mat4

#pragma sokol @vs vs
in vec2 pos;
in vec2 texcoord0;

out vec2 uv;

void main() {
    gl_Position = vec4(pos, 0.0, 1.0);
    uv = texcoord0;
}

#pragma sokol @end

#pragma sokol @fs fs
uniform sampler2D tex;

in vec2 uv;
out vec4 frag_color;

void main() {
    frag_color = texture(tex, uv);
}

#pragma sokol @end

#pragma sokol @program texcube vs fs
