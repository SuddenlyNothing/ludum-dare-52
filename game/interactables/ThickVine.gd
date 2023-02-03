extends Area2D

var height := 0

onready var sprite := $Sprite
onready var collision_shape := $CollisionShape2D


func _ready() -> void:
	sprite.region_rect.size.y = height
	collision_shape.position.y = height / 2
	collision_shape.shape.extents = sprite.region_rect.size / 2


func hit(dir: int) -> void:
	queue_free()
