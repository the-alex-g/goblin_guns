class_name Main
extends Node2D

var players : Array[int] = [0]

@onready var _player_container := $PlayerContainer
@onready var _darkness_layer := $CanvasModulate


func _ready() -> void:
	for id in players:
		var player := preload("res://player/player.tscn").instantiate()
		player.id = id
		player.position = Vector2(16 * (id + 1), 16)
		_player_container.add_child(player)
	_darkness_layer.show()
