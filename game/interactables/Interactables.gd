extends TileMap

const VinePlatform := preload("res://interactables/VinePlatform.tscn")

var interactables := [
	[preload("res://interactables/Vine.tscn"), 1],
	[preload("res://interactables/ThickVine.tscn"), 3],
]


func _ready() -> void:
	var added_cells = {}
	for i in get_used_cells():
		var type := get_cellv(i)
		if type == 2:
			continue
		if i in added_cells:
			continue
		var vine_cells := get_vine_cells(i, type)
		var vine: Node = interactables[type][0].instance()
		vine.height = interactables[type][1] * vine_cells.size() * cell_size.y
		vine.position = i * cell_size
		var platform_cell_pos: Vector2 = i + \
				Vector2.DOWN * interactables[type][1] * vine_cells.size()
		if type == 0 and get_cellv(platform_cell_pos) == 2:
			var vine_platform := VinePlatform.instance()
			vine_platform.position = (platform_cell_pos) * \
					cell_size + cell_size / 2
			add_child(vine_platform)
			vine.platform = vine_platform
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
