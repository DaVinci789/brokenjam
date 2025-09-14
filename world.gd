extends Node2D

@onready var node_player: Entity = %player
@onready var arms := %player.get_node("arms")
@onready var starting_arms_position: Vector2 = arms.global_position
@onready var fantasy_ui := %fantasy_ui
@onready var enemy_halo_scene := preload("res://enemy_halo.tscn")
@onready var enemy_halo_tex   := preload("res://enemy_halo_tex.tres")
@onready var enemy_devil_scene := preload("res://enemy_devil.tscn")
@onready var enemy_devil_tex   := preload("res://enemy_devil_tex.tres")

var fantasy_ui_offset := Vector2.ZERO
var caught_enemy := false

var active_objects: Array[Entity] = [
	null,
	null,
	null,
	null,
	null,
	null,
	null,
	null,
	null,
	null,
]

class CollisionPair:
	var a: Entity
	var b: Entity
	var data: KinematicCollision2D

func get_gravity(entity: Entity) -> float:
	return entity.jump_gravity if entity.velocity.y < 0.0 else entity.fall_gravity

func throw_arm(player: Entity) -> void:
	if player.arm_action == Entity.ArmActionType.None:
		if player.hold_state == Entity.HoldState.Empty:
			player.arm_action = Entity.ArmActionType.Grab
		elif player.hold_state == Entity.HoldState.Holding:
			player.arm_action = Entity.ArmActionType.Throw

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

func adjust_tex(entity: Entity, tex: TextureRect):
	if entity.enemy_type == Entity.EnemyType.Halo:
		tex.texture = enemy_halo_tex
		tex.visible = true
	elif entity.enemy_type == Entity.EnemyType.Devil:
		tex.texture = enemy_devil_tex
		tex.visible = true
	else:
		assert(false)

func draw_fantasy_ui(objects: Array[Entity], highlight_index: int):
	for tex: TextureRect in fantasy_ui.object_view_textures:
		tex.texture = null
		tex.visible = false
		tex.get_parent().modulate = Color.WHITE
	
	for i in len(objects):
		var entity := objects[i]
		if entity:
			if entity.type == Entity.EntityType.Enemy:
				adjust_tex(entity, fantasy_ui.object_view_textures[i])
		else:
			fantasy_ui.object_view_textures[i].texture = null
	
	if highlight_index > -1:
		fantasy_ui.object_view_textures[highlight_index].get_parent().modulate = Color.RED

func register_object(entity: Entity) -> int:
	var result := -1
	for i in len(active_objects):
		var select := active_objects[i]
		if not select:
			active_objects[i] = entity
			result = i
			entity.slot_index = i
			break
	return result

func blink(entity: Entity, startstop := true) -> void:
	if entity.animation_player:
		if startstop == true:
			entity.animation_player.play("blink")
		else:
			entity.animation_player.stop()

func disable_collision(entity: Entity) -> void:
	var collision: CollisionShape2D =  entity.find_child("collision")
	if collision:
		collision.disabled = true
	pass

func _ready() -> void:
	for entity in get_entities():
		if entity.type == Entity.EntityType.Enemy:
			entity.velocity.x = -100

func _process(delta: float) -> void:
	var entities := get_entities()
	var collision_pairs := get_area_collisions(entities)
	
	# Handle gravity & frames_in_air first
	if node_player.is_on_floor():
		node_player.frames_in_air = 0
		node_player.state &= ~Entity.ActState.Jump
	else:
		node_player.frames_in_air += 1
		node_player.velocity.y += get_gravity(node_player)

	# Update coyote check AFTER frames_in_air is correct
	node_player.can_jump = node_player.is_on_floor() or node_player.frames_in_air <= node_player.coyote_frames
	
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()
	
	var input_horizontal := Input.get_axis("input_left", "input_right")
	node_player.velocity.x = input_horizontal * node_player.move_speed
	
	if Input.is_action_just_pressed("input_a") and node_player.can_jump and not node_player.state & Entity.ActState.Jump:
		node_player.velocity.y = node_player.jump_velocity
		node_player.state |= Entity.ActState.Jump
	if Input.is_action_just_pressed("input_b"):
		throw_arm(node_player)
	
	if node_player.arm_action != Entity.ArmActionType.None:
		node_player.arms_active_timer += delta
		node_player.arms_active_timer = clampf(node_player.arms_active_timer, 0.0, node_player.arms_act_length)
	else:
		starting_arms_position = arms.global_position
		arms.velocity = Vector2.ZERO

	for pair in collision_pairs:
		if pair.a.type == Entity.EntityType.Arms and pair.b.type == Entity.EntityType.Enemy:
			if pair.b.grabbable and node_player.arm_action == Entity.ArmActionType.Grab:
				# held is true if slot_index == hold_index
				# usually you'd do that sort of thing here, but
				# it's done like this for game design reasons.
				caught_enemy = true
				node_player.hold_index = pair.b.slot_index
		if pair.a.type == Entity.EntityType.Feet and pair.b.type == Entity.EntityType.Enemy:
			if pair.b.enemy_type == Entity.EnemyType.Devil:
				node_player.velocity.y = pair.b.head_bounce_velocity
	
	for enemy: Entity in entities:
		if enemy.type == Entity.EntityType.Enemy:
			if enemy.slot_index == node_player.hold_index:
				enemy.held = true 
				disable_collision(enemy)
				enemy.velocity = Vector2.ZERO
	
	for enemy: Entity in entities:
		if enemy.type == Entity.EntityType.Enemy:
			if enemy.held:
				enemy.global_position = arms.global_position
				enemy.despawn_timer -= delta
				if enemy.despawn_timer <= enemy.despawn_blink:
					blink(enemy, true)
			else:
				enemy.enemy_timer += delta
				enemy.enemy_timer = clampf(enemy.enemy_timer, 0.0, enemy.enemy_oscillation_length)
				if enemy.enemy_type == Entity.EnemyType.Halo:
					enemy.velocity.y = enemy.vertical_velocity_curve.sample(enemy.enemy_timer / enemy.enemy_oscillation_length)
				elif enemy.enemy_type == Entity.EnemyType.Devil:
					enemy.velocity.x = enemy.movement_speed
	
	if node_player.arm_action == Entity.ArmActionType.Throw:
		if node_player.arms_curve.sample(node_player.arms_active_timer / node_player.arms_act_length) >= node_player.arms_curve.max_value:
			var enemy: Entity = active_objects[node_player.hold_index]
			if enemy:
				blink(enemy, false)
				enemy.held = false
			node_player.hold_state = Entity.HoldState.Empty
			node_player.hold_index = -1
	
	if fantasy_ui.mouse_pressed:
		fantasy_ui_offset = get_global_mouse_position() - fantasy_ui.global_position
		fantasy_ui.start_size = fantasy_ui.size
	if fantasy_ui.header_active:
		fantasy_ui.global_position = get_global_mouse_position() - fantasy_ui_offset
	if fantasy_ui.corner_active:
		fantasy_ui.size = get_global_mouse_position() - fantasy_ui.global_position
	
	if %Button.just_pressed:
		var new_enemy: Entity = enemy_halo_scene.instantiate()
		new_enemy.global_position = Vector2(199, 132)
		new_enemy.velocity.x = -100
		if register_object(new_enemy) > -1:
			%gameworld.add_child(new_enemy)
		else:
			new_enemy.queue_free()
	
	if %Button1.just_pressed:
		var new_enemy: Entity = enemy_devil_scene.instantiate()
		#new_enemy.global_position = Vector2(400, 980)
		new_enemy.global_position = Vector2(300, 132)
		new_enemy.velocity.y = 100
		if register_object(new_enemy) > -1:
			%gameworld.add_child(new_enemy)
		else:
			new_enemy.queue_free()
	
	# reset/flushing zone
	if caught_enemy:
		node_player.hold_state = Entity.HoldState.Holding
		caught_enemy = false
	if node_player.arms_active_timer / node_player.arms_act_length >= 1.0:
		node_player.arms_active_timer = 0
		node_player.arm_action = Entity.ArmActionType.None
	for enemy: Entity in entities:
		if enemy.type == Entity.EntityType.Enemy:
			if enemy.enemy_timer / enemy.enemy_oscillation_length >= 1.0:
				enemy.enemy_timer = 0
			if not enemy.on_screen or enemy.despawn_timer <= 0.0:
				active_objects[enemy.slot_index] = null
				enemy.queue_free()
	
	draw_fantasy_ui(active_objects, node_player.hold_index)

func _physics_process(delta: float) -> void:
	var entities := get_entities()
	node_player.move_and_slide()
	
	if node_player.arm_action != Entity.ArmActionType.None:
		var target_offset = node_player.arms_curve.sample(node_player.arms_active_timer / node_player.arms_act_length)
		var target_x = %arms_home.global_position.x + target_offset
		var target_y = %arms_home.global_position.y
		if node_player.hold_index > -1:
			target_x = %arms_home2.global_position.x + target_offset
			target_y = %arms_home2.global_position.y
		var arm_velocity = Vector2(target_x - arms.global_position.x, target_y - arms.global_position.y) / delta
		arms.velocity = arm_velocity
		arms.move_and_slide()
	
	for entity: Entity in entities:
		if entity.type == Entity.EntityType.Enemy:
			if not entity.held:
				entity.move_and_slide()
	pass
