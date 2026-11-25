class_name Main
extends Node2D

enum CellType {WALL, SPACE, N_LEFT, N_RIGHT, UP}

@export var apply_shadow := true

var players : Array[int] = [0]
var _n_left_cells : PackedVector2Array = []
var _n_right_cells : PackedVector2Array = []
var _up_cells : PackedVector2Array = []
var _rooms : Array[Array] = []
var _stairs : Array[Array] = []

@onready var _player_container := $PlayerContainer
@onready var _darkness_layer := $CanvasModulate
@onready var _player_spawn_locations := $PlayerSpawns
@onready var _tile_layer := $TileMapLayer


func _ready() -> void:
	for id in players:
		var player := preload("res://player/player.tscn").instantiate()
		player.id = id
		player.position = _player_spawn_locations.get_child(id).position
		_player_container.add_child(player)
	_darkness_layer.visible = apply_shadow
	_rooms.append(_load_room("rooms/stacked_corridors"))
	_rooms.append(_load_room("rooms/stacked_rooms"))
	_rooms.append(_load_room("rooms/large_room"))
	_stairs.append(_load_room("stairs/basic_staircase"))
	_build_complex()


func _build_outer_walls() -> void:
	for x in range(-3, 82):
		_add_cell(Vector2i(x, -3))
		_add_cell(Vector2i(x, -1))
		_add_cell(Vector2i(x, 40))
		_add_cell(Vector2i(x, 42))
	for y in range(-3, 42):
		_add_cell(Vector2i(-3, y))
		_add_cell(Vector2i(-1, y))
		_add_cell(Vector2i(80, y))
		_add_cell(Vector2i(82, y))


func _build_complex() -> void:
	_tile_layer.clear()
	_build_outer_walls()
	for row in 3:
		var stair_location := randi_range(0, 4)
		for column in 5:
			var offset := Vector2i(column * 16, row * 16)
			if column == stair_location:
				_build_room(_stairs.pick_random(), offset)
			else:
				_build_room(_rooms.pick_random(), offset)
	_resolve_conditional_cells()


func _get_type(c: String) -> CellType:
	if c == "#":
		return CellType.WALL
	elif c == "<":
		return CellType.N_LEFT
	elif c == ">":
		return CellType.N_RIGHT
	elif c == "^":
		return CellType.UP
	else:
		if c != " ":
			push_warning("unknown cell type %s" % c)
		return CellType.SPACE


func _load_room(file_name: String) -> Array:
	var file := FileAccess.open("res://main/%s.txt" % file_name, FileAccess.READ)
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
					room.append(CellType.SPACE)
		else:
			var i = 0;
			var chars = 0
			while i < line.length():
				chars += 1
				var c = line[i]
				if c == "?":
					i += 1
					if randf() < 0.5:
						room.append(CellType.SPACE)
					else:
						room.append(_get_type(line[i]))
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
		match room[i]:
			CellType.WALL:
				_add_cell(cell)
			CellType.SPACE:
				_tile_layer.erase_cell(cell)
			CellType.N_LEFT:
				_n_left_cells.append(cell)
			CellType.N_RIGHT:
				_n_right_cells.append(cell)
			CellType.UP:
				_up_cells.append(cell)


func _cell_full(cell: Vector2i) -> bool:
	return _tile_layer.get_cell_source_id(cell) >= 0


func _cell_empty(cell: Vector2i) -> bool:
	return not _cell_full(cell)


func _resolve_conditional_cells() -> void:
	for cell : Vector2i in _n_left_cells:
		if _cell_empty(cell + Vector2i.LEFT):
			_add_cell(cell)
	for cell : Vector2i in _n_right_cells:
		if _cell_empty(cell + Vector2i.RIGHT):
			_add_cell(cell)
	for cell : Vector2i in _up_cells:
		if _cell_full(cell + Vector2i.UP):
			_add_cell(cell)
