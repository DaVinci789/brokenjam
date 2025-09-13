extends Node2D

@onready var node_player := $CharacterBody2D
@onready var starting_arms_position: Vector2 = $CharacterBody2D/arms.global_position

func get_gravity(entity: Entity) -> float:
	return entity.jump_gravity if entity.velocity.y < 0.0 else entity.fall_gravity

func throw_arm(player: Entity) -> void:
	var target := player.position + Vector2(100, 0)
	var arms := player.get_node("arms")
	player.state = Entity.ActState.Grab
	pass

func _process(delta: float) -> void:
	var arms := node_player.get_node("arms")
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()
	
	var input_horizontal := Input.get_axis("input_left", "input_right")
	node_player.velocity.x = input_horizontal * node_player.move_speed
	
	if Input.is_action_just_pressed("input_b"):
		throw_arm(node_player)
	if Input.is_action_just_pressed("input_a"):
		node_player.velocity.y = node_player.jump_velocity
	
	if not node_player.is_on_floor():
		node_player.velocity.y += get_gravity(node_player)
	node_player.is_falling = node_player.velocity.y > 0 and not node_player.is_on_floor()
	
	if node_player.state == Entity.ActState.Grab:
		node_player.arms_active_timer += delta
		node_player.arms_active_timer = clampf(node_player.arms_active_timer, 0.0, node_player.arms_act_length)
		if node_player.arms_active_timer / node_player.arms_act_length >= 1.0:
			node_player.state = Entity.ActState.None
			node_player.arms_active_timer = 0
	else:
		starting_arms_position = arms.global_position
		arms.velocity = Vector2.ZERO
	pass

func _physics_process(delta: float) -> void:
	node_player.move_and_slide()
	
	# extend to anim curve
	var arms := node_player.get_node("arms")
	if node_player.state == Entity.ActState.Grab:
		var target_offset = node_player.arms_curve.sample(node_player.arms_active_timer / node_player.arms_act_length)
		var target_x = node_player.get_node("arms_home").global_position.x + target_offset
		var arm_velocity = Vector2(target_x - arms.global_position.x, 0) / delta
		arms.velocity = arm_velocity
		arms.move_and_slide()

	# if we hit something. snap to peak of curve and start moving back.
	pass
