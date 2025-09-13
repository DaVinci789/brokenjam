extends Node2D

@onready var node_player := %player
@onready var arms := %player.get_node("arms")
@onready var starting_arms_position: Vector2 = arms.global_position
@onready var fantasy_ui := %fantasy_ui

var fantasy_ui_offset := Vector2.ZERO
var caught_enemy := false

class CollisionPair:
	var a: Entity
	var b: Entity
	var data: KinematicCollision2D

func get_gravity(entity: Entity) -> float:
	return entity.jump_gravity if entity.velocity.y < 0.0 else entity.fall_gravity

func throw_arm(player: Entity) -> void:
	var target := player.position + Vector2(100, 0)
	var arms := player.get_node("arms")
	player.state = Entity.ActState.Grab
	pass

func get_entities() -> Array[Entity]:
	var array: Array[Entity]
	array.assign(get_tree().get_nodes_in_group("Entity"))
	return array
	
func get_area_collisions(entities: Array[Entity]) -> Array[CollisionPair]:
	var pairs: Array[CollisionPair] = []

	for entity: Entity in entities:
		for other: Entity in entity.colliders:
			var already_added := false
			for p in pairs:
				if (p.a == entity and p.b == other) or (p.a == other and p.b == entity):
					already_added = true
					break
			if not already_added:
				_add_pair(pairs, entity, other)
		entity.colliders.clear()

	return pairs

func _add_pair(pairs: Array[CollisionPair], a: Entity, b: Entity, collider: KinematicCollision2D = null) -> void:
	# Avoid duplicates (A,B) vs (B,A)
	for p in pairs:
		if (p.a == a and p.b == b) or (p.a == b and p.b == a):
			return
	var pair := CollisionPair.new()
	if a.type < b.type:
		pair.a = a
		pair.b = b
	else:
		pair.a = b
		pair.b = a
	pair.data = collider
	pairs.append(pair)

# cartch state or throw state.
func _process(delta: float) -> void:
	var entities := get_entities()
	var collision_pairs := get_area_collisions(entities)
	
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()
	
	var input_horizontal := Input.get_axis("input_left", "input_right")
	node_player.velocity.x = input_horizontal * node_player.move_speed
	
	if Input.is_action_just_pressed("input_a"):
		node_player.velocity.y = node_player.jump_velocity
	if Input.is_action_just_pressed("input_b"):
		throw_arm(node_player)
	
	if not node_player.is_on_floor():
		node_player.velocity.y += get_gravity(node_player)
	node_player.is_falling = node_player.velocity.y > 0 and not node_player.is_on_floor()
	
	if node_player.state == Entity.ActState.Grab:
		node_player.arms_active_timer += delta
		node_player.arms_active_timer = clampf(node_player.arms_active_timer, 0.0, node_player.arms_act_length)
	else:
		starting_arms_position = arms.global_position
		arms.velocity = Vector2.ZERO

	for pair in collision_pairs:
		if pair.a.type == Entity.EntityType.Arms and pair.b.type == Entity.EntityType.Enemy:
			if node_player.hold_state == Entity.HoldState.Empty:
				pair.b.held = true
				caught_enemy = true
	
	for enemy in entities:
		if enemy.held:
			enemy.global_position = arms.global_position
			if node_player.hold_state == Entity.HoldState.Holding:
				if node_player.arms_curve.sample(node_player.arms_active_timer / node_player.arms_act_length) >= node_player.arms_curve.max_value:
					enemy.held = false
					node_player.hold_state = Entity.HoldState.Empty
			break
	
	if fantasy_ui.mouse_pressed:
		fantasy_ui_offset = get_global_mouse_position() - fantasy_ui.global_position
		fantasy_ui.start_size = fantasy_ui.size
	if fantasy_ui.header_active:
		fantasy_ui.global_position = get_global_mouse_position() - fantasy_ui_offset
	if fantasy_ui.corner_active:
		fantasy_ui.size = (get_global_mouse_position() - fantasy_ui.global_position)
	
	# reset/flushing zone
	if node_player.arms_active_timer / node_player.arms_act_length >= 1.0:
		node_player.state = Entity.ActState.None
		node_player.arms_active_timer = 0
	if caught_enemy:
		node_player.hold_state = Entity.HoldState.Holding
		caught_enemy = false

func _physics_process(delta: float) -> void:
	node_player.move_and_slide()
	
	# extend to anim curve
	var arms := node_player.get_node("arms")
	if node_player.state == Entity.ActState.Grab:
		var target_offset = node_player.arms_curve.sample(node_player.arms_active_timer / node_player.arms_act_length)
		var target_x = %arms_home.global_position.x + target_offset
		var arm_velocity = Vector2(target_x - arms.global_position.x, 0) / delta
		arms.velocity = arm_velocity
		arms.move_and_slide()

	# if we hit something. snap to peak of curve and start moving back.
	pass
