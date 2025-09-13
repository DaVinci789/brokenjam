class_name Entity
extends CharacterBody2D

enum EntityType {
	None,
	Player
}

enum ActState {
	None,
	Grab,
	Jump,
}

@export var type := EntityType.None
@export var move_speed := 0.0
var state: ActState = ActState.None
var is_falling := false

@onready var jump_velocity := ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity := ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity := ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0

@export_subgroup("Arms")
@export var arms_act_length: float = 0.0
@export var arms_curve: Curve
var arms_active_timer: float = 0

@export_subgroup("Jump")
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
