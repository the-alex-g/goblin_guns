class_name Main
extends Node2D

@export var apply_shadow := true
@export var spawn_ammo_dumps := true
@export var dump_spawn_chance := 0.8

var player_ids : Array[int] = [0]
var _rooms : Array[Array] = []
var _stairs : Array[Array] = []
var _spawns : Array[Vector2i] = []
var _decorations : Array[Array] = []
var _decor_groups := {}
var _decor_group_index := 0
var _players : Array[Player] = []
var _dead_players := 0

@onready var _player_container := $PlayerContainer
@onready var _darkness_layer := $CanvasModulate
@onready var _tile_layer : TileMapLayer = $TileMapLayer
@onready var _temp_container := $TempContainer


func _ready() -> void:
	_darkness_layer.visible = apply_shadow
	_load_features_from_dir("rooms", _rooms)
	_load_features_from_dir("stairs", _stairs)
	_load_features_from_dir("decorations", _decorations, 3)
	_build_complex()
	_initialize_players()
	_place_ammo_dumps()


func _initialize_players() -> void:
	var color_index := 0
	for id in player_ids:
		var player : Player = preload("res://player/player.tscn").instantiate()
		player.id = id
		player.position = _get_spawn_point()
		_player_container.add_child(player)
		player.color = Player.COLORS[color_index]
		color_index += 1
		player.died.connect(_on_player_died)
		player.weapon_fired.connect(
			func(weapon: Node2D):
				_temp_container.add_child(weapon)
				if weapon is ExplosiveGrenade:
					weapon.exploded.connect(_on_grenade_exploded)
		)
		player.infinite_ammo = not spawn_ammo_dumps
		_players.append(player)


func _restart_game() -> void:
	_dead_players = 0
	_spawns.clear()
	_decor_groups.clear()
	_decor_group_index = 0
	_build_complex()
	for player in _players:
		player.respawn(_get_spawn_point())
	for tmp in _temp_container.get_children():
		tmp.queue_free()
	_place_ammo_dumps()


func _place_ammo_dumps() -> void:
	if spawn_ammo_dumps:
		for pos in _spawns:
			if randf() < dump_spawn_chance:
				var dump := preload("res://ammo_drop/ammo_drop.tscn").instantiate()
				dump.position = pos * 8
				_temp_container.add_child(dump)


func _get_spawn_point() -> Vector2:
	var index := randi() % _spawns.size()
	var point := _spawns[index]
	_spawns.remove_at(index)
	return point * 8


func _on_player_died() -> void:
	_dead_players += 1
	if _dead_players == _players.size() - 1 or _players.size() == 1:
		await get_tree().create_timer(3.0).timeout
		_restart_game()


func _load_features_from_dir(dirname: String, destination: Array[Array], size := 16) -> void:
	for filename in DirAccess.get_files_at("res://main/%s/" % dirname):
		destination.append(_load_room("%s/%s" % [dirname, filename], size))


func _build_outer_walls() -> void:
	for x in range(-2, 83):
		_add_cell(Vector2i(x, -2))
		_add_cell(Vector2i(x, 0))
		_add_cell(Vector2i(x, 49))
		_add_cell(Vector2i(x, 51))
	for y in range(-2, 51):
		_add_cell(Vector2i(-2, y))
		_add_cell(Vector2i(0, y))
		_add_cell(Vector2i(81, y))
		_add_cell(Vector2i(83, y))


func _build_complex() -> void:
	_tile_layer.clear()
	_build_outer_walls()
	for row in 3:
		var stair_location_1 := randi_range(0, 4)
		var stair_location_2 := randi_range(0, 4)
		while stair_location_1 == stair_location_2:
			stair_location_2 = randi_range(0, 4)
		for column in 5:
			var offset := Vector2i(column * 16 + 1, row * 16 + 1)
			if column == stair_location_1 or randf() < 0.1 or column == stair_location_2:
				_build_room(_stairs.pick_random(), offset)
			else:
				_build_room(_rooms.pick_random(), offset)
	_build_decor()


func _build_decor() -> void:
	for group_id in _decor_groups:
		if randf() < 0.5:
			var decor : Array = _decorations.pick_random()
			for pos in _decor_groups[group_id]:
				_generate_decor(pos, decor)


func _generate_decor(pos: Vector2i, decor: Array) -> void:
	if _cell_full(pos + Vector2i.DOWN):
		for i in 9:
			var cell := pos + Vector2i(i % 3 - 1, floori(i / 3.0) - 2)
			if decor[i].call(cell):
				_add_cell(cell)
	else:
		for i in 9:
			var cell := pos + Vector2i(i % 3 - 1, floori(i / 3.0))
			if decor[8 - i].call(cell):
				_add_cell(cell)


func _false(_pos) -> bool:
	return false


func _true(_pos) -> bool:
	return true


func _track_decor(pos: Vector2i, offset: int) -> void:
	var index := _decor_group_index + offset
	if _decor_groups.has(index):
		_decor_groups[index].append(pos)
	else:
		_decor_groups[index] = [pos]


func _get_type(c: String) -> Callable:
	if c == "#":
		return _true
	elif c == "<":
		return func(pos: Vector2i): return _cell_full(pos + Vector2i.LEFT)
	elif c == ">":
		return func(pos: Vector2i): return _cell_full(pos + Vector2i.RIGHT)
	elif c == "^":
		return func(pos: Vector2i): return _cell_full(pos + Vector2i.UP)
	elif c == "$":
		return func(pos: Vector2i):
			if not _cell_full(pos + Vector2i.UP):
				_spawns.append(pos)
			return true
	elif c.is_valid_int():
		return func(pos: Vector2i):
			_track_decor(pos, int(c))
			return false
	else:
		if c != " ":
			push_warning("unknown cell type %s" % c)
		return _false


func _load_room(file_name: String, size: int) -> Array[Callable]:
	var file := FileAccess.open("res://main/%s" % file_name, FileAccess.READ)
	var room := []
	var lines := 0
	while not file.eof_reached():
		lines += 1
		var line := file.get_line()
		if line == "":
			if lines == size + 1:
				file.close()
				return room
			else:
				for i in size:
					room.append(_false)
		else:
			var i = 0;
			var chars = 0
			while i < line.length():
				chars += 1
				var c = line[i]
				if c == "?":
					i += 1
					var next := _get_type(line[i])
					room.append(
						func(pos: Vector2i):
							if randf() < 0.5:
								return false
							else:
								return next.call(pos)
					)
				elif c == "!":
					i += 1
					room.append(
						func(pos: Vector2i):
							return not _get_type(line[i]).call(pos)
					)
				elif c == "/":
					chars -= 1
				else:
					room.append(_get_type(line[i]))
				i += 1
			if chars != size:
				push_warning("irregular line length %d in %s line %d" % [chars, file_name, lines])
				file.close()
				return []
	file.close()
	if lines != size:
		push_warning("irregular line count %d in %s" % [(lines - 1), file_name])
		return []
	return room


func _add_cell(cell: Vector2i) -> void:
	_tile_layer.set_cell(cell, 0, Vector2i.ZERO)


func _build_room(room: Array, offset: Vector2i) -> void:
	for i in 256:
		var cell := offset + Vector2i(i % 16, floori(i / 16.0))
		if room[i].call(cell):
			_add_cell(cell)
		else:
			_tile_layer.erase_cell(cell)
	_decor_group_index += 10


func _cell_full(cell: Vector2i) -> bool:
	return _tile_layer.get_cell_source_id(cell) >= 0


func _on_grenade_exploded(pos: Vector2) -> void:
	var tile_pos := _tile_layer.local_to_map(pos)
	for x in 3:
		for y in 3:
			_tile_layer.erase_cell(tile_pos - Vector2i(x - 1, y - 1))
	for player in _players:
		var distance := player.position.distance_to(pos) / 8
		if distance < 4:
			player.hit(ceili(2 * (4 - distance)))
