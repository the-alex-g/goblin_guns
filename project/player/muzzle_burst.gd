class_name MuzzleBurst
extends Node2D

var anim_name : String = ""

@onready var _sprite := $Sprite


func _ready() -> void:
	if anim_name != "":
		_sprite.play(anim_name)
	else:
		queue_free()


func _on_sprite_animation_finished() -> void:
	queue_free()
