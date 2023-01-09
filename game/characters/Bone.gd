extends AnimatedSprite

signal arrived

var end_pos := Vector2()
var speed := 500

onready var dir := position.direction_to(end_pos)


func _physics_process(delta: float) -> void:
	var move := speed * delta
	if position.distance_to(end_pos) <= move:
		emit_signal("arrived")
		queue_free()
	position += dir * move
	
