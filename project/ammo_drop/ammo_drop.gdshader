shader_type canvas_item;

uniform vec3 background_color = vec3(0.7);


void fragment() {
	if (COLOR != vec4(1.0)) {
		COLOR.rgb = background_color;
	}
}