extends StateMachine
# warnings-disable

func _ready() -> void:
	add_state("idle")
	add_state("walk")
	add_state("jump")
	add_state("fall")
	add_state("wall_cling")
	add_state("attack")
	add_state("hurt")
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
		states.attack:
			if parent.finished_attack():
				parent.play_anim("attack_finish")
			parent.attack_move(delta)
		states.hurt:
			parent.hurt_move(delta)


func _get_transition(delta: float):
	match state:
		states.idle:
			if parent.can_attack():
				return states.attack
			if parent.can_jump(true):
				return states.jump
			if parent.x_input != 0:
				return states.walk
			if not parent.is_on_floor():
				return states.fall
		states.walk:
			if parent.can_attack():
				return states.attack
			if parent.can_jump(true):
				return states.jump
			if parent.velocity.x == 0 and parent.x_input == 0:
				return states.idle
			if not parent.is_on_floor():
				return states.fall
			if parent.is_on_wall() and parent.y_input < 0:
				return states.wall_cling
		states.jump:
			if parent.can_attack():
				return states.attack
			if parent.velocity.y > 0:
				return states.fall
			if parent.is_on_wall() and parent.x_input != 0:
				return states.wall_cling
		states.fall:
			if parent.can_attack():
				return states.attack
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
			if parent.can_attack():
				return states.attack
			if parent.can_jump(true):
				return states.jump
			if not parent.is_on_floor():
				return states.fall
			if parent.can_stop_cling():
				return states.fall
		states.attack:
			if parent.attack_animation_follow_through_finished:
				if parent.is_on_wall() and \
						not parent.prevent_cling_cast.is_colliding():
					return states.wall_cling
				return states.fall
		states.hurt:
			if parent.hurt_timer.is_stopped():
				return states.fall
	return null


func _enter_state(new_state: String, old_state) -> void:
	match new_state:
		states.idle:
			parent.play_anim("idle")
			parent.attacked = false
		states.walk:
			parent.play_anim("walk")
			parent.attacked = false
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
			parent.attacked = false
		states.attack:
			parent.play_anim("attack")
			if old_state == states.wall_cling:
				parent.prev_x_input = sign(parent.wall_dir.x)
			parent.set_attack_velocity()
			parent.attacked = true
			parent.attack_animation_finished = false
			parent.attack_animation_follow_through_finished = false
			parent.passed_through_hittables = false
			parent.attacking = true
			parent.add_hittables()
		states.hurt:
			parent.play_anim("hurt")
			parent.set_hurt_velocity()
			parent.hurt_timer.start()


func _exit_state(old_state, new_state: String) -> void:
	match old_state:
		states.idle:
			pass
		states.walk:
			pass
		states.jump:
			if new_state != states.fall and new_state != states.attack:
				parent.reset_air_jumps()
		states.fall:
			if new_state != states.jump:
				parent.reset_air_jumps()
			if new_state == states.idle or new_state == states.walk:
				parent.play_anim("land")
		states.wall_cling:
			if new_state == states.fall:
				if parent.velocity.y < 0 and parent.y_input < 0:
					parent.climb_ledge()
			elif new_state == states.jump:
				parent.wall_jump()
		states.attack:
			if new_state != states.hurt:
				parent.attack_delay_timer.start()
				parent.attacking = false
				parent.attack()
		states.hurt:
			pass
