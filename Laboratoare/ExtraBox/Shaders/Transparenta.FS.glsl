#version 330
in vec3 frag_normal;
in vec3 frag_color;

uniform sampler2D u_texture_0;
uniform float alpha;
uniform vec3 color;

layout(location = 0) out vec4 out_color;

void main()
{
	out_color = vec4(abs(color), alpha);
}