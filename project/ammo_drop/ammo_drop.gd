extends Area2D

@export var ammo := 10
@export var grenades := 2
@export var min_time := 10
@export var max_time := 30


func _on_body_entered(body: Node2D) -> void:
	if body is Player and visible:
		body.ammo += ammo
		body.grenades += grenades
		hide()
		await get_tree().create_timer(randi_range(min_time, max_time)).timeout
		show()
