 #version 330

uniform vec4 ourColor;
layout(location = 0) out vec4 FragColor;

void main()
{
    FragColor = ourColor;
}
