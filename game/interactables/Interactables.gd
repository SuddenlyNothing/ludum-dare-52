extends TileMap

var interactables := [
	[preload("res://interactables/Vine.tscn"), 1],
	[preload("res://interactables/ThickVine.tscn"), 3],
]


func _ready() -> void:
	var added_cells = {}
	for i in get_used_cells():
		if i in added_cells:
			continue
		var type := get_cellv(i)
		var vine_cells := get_vine_cells(i, type)
		var vine: Node = interactables[type][0].instance()
		vine.height = interactables[type][1] * vine_cells.size() * cell_size.y
		vine.position = i * cell_size
		call_deferred("add_child", vine)
		added_cells.merge(vine_cells)
	clear()


func get_vine_cells(start: Vector2, type: int) -> Dictionary:
	var vine_cells := {start:0}
	var step := Vector2(0, interactables[type][1])
	var curr := start
	while get_cellv(curr + step) == type:
		curr += step
		vine_cells[curr] = 0
	return vine_cells
