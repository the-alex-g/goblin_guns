shader_type canvas_item;

instance uniform vec3 color = vec3(1.0, 0.0, 0.0);
const float outline_size = 0.5;
const bool outline = true;


bool check_pixel(vec2 position, sampler2D txtr) {
	vec4 color_at_position = texture(txtr, position);
	return color_at_position.a > 0.99;
}


void fragment() {
	if (COLOR == vec4(0.0, 0.0, 0.0, 1.0)) {
		COLOR = vec4(color, 1.0);
	}
	vec2 pixel_x = vec2(TEXTURE_PIXEL_SIZE.x * outline_size, 0.0);
	vec2 pixel_y = vec2(0.0, TEXTURE_PIXEL_SIZE.y * outline_size);

	if (
		outline &&
		COLOR.a < 0.01 &&
		(check_pixel(UV + pixel_x, TEXTURE) ||
		check_pixel(UV + pixel_y, TEXTURE) ||
		check_pixel(UV - pixel_x, TEXTURE) ||
		check_pixel(UV - pixel_y, TEXTURE))
	) {
		COLOR = vec4(vec3(0.0), 1.0);
	}
}
