extends Control

var play_pressed := false
var ready_to_move_on := false

func _process(_d) -> void:
	if $ImmediateButton.just_pressed:
		play_pressed = true
		$AnimationTree.play("fade")
		$ColorRect.visible = true

func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name == "fade":
		ready_to_move_on = true
	pass # Replace with function body.
