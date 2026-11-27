shader_type canvas_item;

instance uniform float percent = 1.0;

void fragment() {
	if (UV.x > percent) {
		COLOR.a = 0.0;
	}
}