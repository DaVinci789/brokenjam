extends TextureRect

@export var the_text := ""
var hovered := false

func _ready() -> void:
	$Panel/Label.text = the_text


func _on_mouse_entered() -> void:
	hovered = true
	pass # Replace with function body.


func _on_mouse_exited() -> void:
	hovered = false
	pass # Replace with function body.
