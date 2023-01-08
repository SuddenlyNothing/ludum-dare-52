extends StateMachine
# warnings-disable

func _ready() -> void:
	add_state("idle")
	add_state("walk")
	add_state("jump")
	add_state("fall")
	add_state("wall_cling")
	call_deferred("set_state", "fall")


func _state_logic(delta: float) -> void:
	match state:
		states.idle:
			parent.move(delta, true, true)
		states.walk:
			parent.set_facing()
			parent.move(delta, true, true)
		states.jump:
			parent.set_facing()
			parent.move(delta, false, false)
			if Input.is_action_just_released("jump"):
				parent.stop_jump()
		states.fall:
			parent.set_facing()
			parent.move(delta, false, true)
		states.wall_cling:
			parent.wall_move(delta)


func _get_transition(delta: float):
	match state:
		states.idle:
			if parent.can_jump(true):
				return states.jump
			if parent.x_input != 0:
				return states.walk
			if not parent.is_on_floor():
				return states.fall
		states.walk:
			if parent.can_jump(true):
				return states.jump
			if parent.velocity.x == 0 and parent.x_input == 0:
				return states.idle
			if not parent.is_on_floor():
				return states.fall
			if parent.is_on_wall() and parent.y_input < 0:
				return states.wall_cling
		states.jump:
			if parent.velocity.y > 0:
				return states.fall
			if parent.is_on_wall():
				return states.wall_cling
		states.fall:
			if parent.can_jump(false):
				return states.jump
			if parent.is_on_floor():
				if parent.velocity.x != 0:
					return states.walk
				else:
					return states.idle
			if parent.can_cling():
				return states.wall_cling
		states.wall_cling:
			if parent.can_jump(true):
				return states.jump
			if not parent.is_on_floor():
				return states.fall
			if parent.can_stop_cling():
				return states.fall
	return null


func _enter_state(new_state: String, old_state) -> void:
	match new_state:
		states.idle:
			parent.play_anim("idle")
		states.walk:
			parent.play_anim("walk")
		states.jump:
			parent.play_anim("jump")
			parent.jump()
		states.fall:
			parent.play_anim("fall")
			if old_state == states.walk or old_state == states.idle:
				parent.coyote_timer.start()
		states.wall_cling:
			parent.play_anim("idle")
			parent.set_wall_dir()
			parent.wall_jump_timer.stop()
			parent.wall_cling_stay_timer.start()


func _exit_state(old_state, new_state: String) -> void:
	match old_state:
		states.idle:
			pass
		states.walk:
			pass
		states.jump:
			if new_state != states.fall:
				parent.reset_air_jumps()
		states.fall:
			if new_state != states.jump:
				parent.reset_air_jumps()
			if new_state == states.idle or new_state == states.walk:
				parent.play_anim("land")
		states.wall_cling:
			if new_state == states.fall:
				if parent.velocity.y < 0:
					parent.climb_ledge()
			elif new_state == states.jump:
				parent.wall_jump()
