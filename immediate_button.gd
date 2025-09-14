class_name ImmediateButton
extends Button

var just_pressed := false
var last_state := false

func _process(_d) -> void:
	if button_pressed and not last_state:
		just_pressed = true
	else:
		just_pressed = false
	last_state = button_pressed
	pass
