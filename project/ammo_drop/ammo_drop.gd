extends Area2D

@export var ammo := 10
@export var grenades := 2


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.ammo += ammo
		body.grenades += grenades
		queue_free()
