class_name Entity
extends CharacterBody2D

enum EntityType {
	None,
	Player,
	Arms,
	Feet,
	Enemy,
}

enum EnemyType {
	None,
	Halo,
	Devil,
}

enum ActState {
	None = 1 << 0,
	Jump = 1 << 1,
	Held = 1 << 2,
}

enum ArmActionType {
	None,
	Grab,
	Throw,
}

enum HoldState {
	None,
	Empty,
	Holding,
}

func _ready() -> void:
	assert(despawn_blink <= despawn_timer)
	add_to_group("Entity")
	
	if area_collider:
		area_collider.connect("area_entered", 
		func(area: Area2D): 
			if area.get_parent() is Entity: 
				colliders.append(area.get_parent()))
	
	var vnode := VisibleOnScreenNotifier2D.new()
	vnode.connect("screen_entered", func(): on_screen = true)
	vnode.connect("screen_exited", func(): on_screen = false)
	add_child(vnode)

@export var type := EntityType.None
@export var move_speed := 0.0
@export var grabbable := false
@export var area_collider: Area2D
@export var animation_player: AnimationPlayer
var state: int = ActState.None
var hold_state: HoldState = HoldState.Empty
var arm_action: ArmActionType = ArmActionType.None

@onready var hp := max_hp
var is_falling := false
var colliders: Array[Entity] = []
var held := false
var hold_lock := false
var on_screen := true
var hold_index := -1
var slot_index := -1
var previously_grabbed := false
var frames_in_air := 0
var can_jump := true

@onready var jump_velocity := ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity := ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity := ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0

@export_subgroup("Arms")
@export var arms_act_length: float = 0.0
@export var arms_curve: Curve
var arms_active_timer: float = 0

@export_subgroup("Jump")
@export var coyote_frames := 0.0
@export var jump_height := 0.0:
	set(value):
		jump_height = value
		jump_velocity = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
		jump_gravity  = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
		fall_gravity  = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0

@export var jump_time_to_peak := 0.0:
	set(value):
		jump_time_to_peak = value
		jump_velocity = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
		jump_gravity  = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
		fall_gravity  = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0

@export var jump_time_to_descent := 0.0:
	set(value):
		jump_time_to_descent = value
		jump_velocity = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
		jump_gravity  = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
		fall_gravity  = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0

@export_subgroup("Enemy")
@export var enemy_type: EnemyType = EnemyType.None
@export var max_hp := 3
@export var movement_speed := 0.0
@export var head_bounce_velocity := 0.0
@export var despawn_timer := 0.0
@export var despawn_blink := 0.0
@export var vertical_velocity_curve: Curve
@export var enemy_oscillation_length := 0.0
var enemy_timer := 0.0
