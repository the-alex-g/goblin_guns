class_name Main
extends Node2D

@export var apply_shadow := true

var players : Array[int] = [0]
var _rooms : Array[Array] = []
var _stairs : Array[Array] = []
var _spawns : Array[Vector2i] = []

@onready var _player_container := $PlayerContainer
@onready var _darkness_layer := $CanvasModulate
@onready var _tile_layer := $TileMapLayer


func _ready() -> void:
	_darkness_layer.visible = apply_shadow
	_load_rooms_from_dir("rooms", _rooms)
	_load_rooms_from_dir("stairs", _stairs)
	_build_complex()
	for id in players:
		var player := preload("res://player/player.tscn").instantiate()
		player.id = id
		player.position = _spawns.pick_random() * 8
		_player_container.add_child(player)


func _load_rooms_from_dir(dirname: String, destination: Array[Array]) -> void:
	for filename in DirAccess.get_files_at("res://main/%s/" % dirname):
		destination.append(_load_room("%s/%s" % [dirname, filename]))


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
			if column == stair_location_1 or randf() < 0.25 or column == stair_location_2:
				_build_room(_stairs.pick_random(), offset)
			else:
				_build_room(_rooms.pick_random(), offset)


func _false(_pos) -> bool:
	return false


func _true(_pos) -> bool:
	return true


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
			_spawns.append(pos)
			return true
	else:
		if c != " ":
			push_warning("unknown cell type %s" % c)
		return _false


func _load_room(file_name: String) -> Array[Callable]:
	var file := FileAccess.open("res://main/%s" % file_name, FileAccess.READ)
	var room := []
	var lines := 0
	while not file.eof_reached():
		lines += 1
		var line := file.get_line()
		if line == "":
			if lines == 17:
				file.close()
				return room
			else:
				for i in 16:
					room.append(_false)
		else:
			var i = 0;
			var chars = 0
			while i < line.length():
				chars += 1
				var c = line[i]
				if c == "?":
					i += 1
					if randf() < 0.5:
						room.append(_false)
					else:
						room.append(_get_type(line[i]))
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
			if chars != 16:
				push_warning("irregular line length %d in %s" % [chars, file_name])
				file.close()
				return []
	file.close()
	if lines != 16:
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


func _cell_full(cell: Vector2i) -> bool:
	return _tile_layer.get_cell_source_id(cell) >= 0


func _cell_empty(cell: Vector2i) -> bool:
	return not _cell_full(cell)
