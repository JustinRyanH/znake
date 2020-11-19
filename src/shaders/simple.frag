 #version 330

uniform vec4 fs_params[1];
layout(location = 0) out vec4 FragColor;

void main()
{
    FragColor = fs_params[0];
}
