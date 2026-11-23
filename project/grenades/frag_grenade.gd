extends RigidBody2D

@export var fragment_speed := 100
@export var fragment_count := 12


func _on_timer_timeout() -> void:
	var offset := PI * randf()
	for i : int in fragment_count:
		var angle := offset + TAU * i / fragment_count
		var fragment : Fragment = preload("res://projectiles/fragment.tscn").instantiate()
		fragment.velocity = Vector2.from_angle(angle) * fragment_speed
		fragment.global_position = global_position
		get_parent().add_child(fragment)
	queue_free()
