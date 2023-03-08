extends KinematicBody2D

var gravity := 1000.0
var velocity := Vector2()


func _ready() -> void:
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	var collision := move_and_collide(velocity * delta)
	if collision:
		if collision.collider.is_in_group("player"):
			var hurt_dir := sign(collision.collider.position.x - position.x)
			collision.collider.hit(hurt_dir)
		set_physics_process(false)
		queue_free()


func fall() -> void:
	set_physics_process(true)


func _apply_gravity(delta: float) -> void:
	velocity.y += gravity * delta
