extends Control


var _joined_players : Array[int] = []


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.is_pressed():
		if _has_player(event.device):
			if event.button_index == JoyButton.JOY_BUTTON_B:
				_remove_player(event.device)
			elif event.button_index == JoyButton.JOY_BUTTON_START:
				_start_game()
		else:
			_add_player(event.device)


func _has_player(id: int) -> bool:
	return _joined_players.has(id)


func _add_player(id: int) -> void:
	_joined_players.append(id)


func _remove_player(id: int) -> void:
	_joined_players.erase(id)


func _start_game() -> void:
	var game := preload("res://main/main.tscn").instantiate()
	if _joined_players.size() > 0:
		game.players = _joined_players
	get_tree().change_scene_to_node(game)
