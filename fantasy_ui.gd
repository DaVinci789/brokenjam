extends Panel
var mouse_down := false
var mouse_pressed := false
var hot := false
var active := false
var header_hot := false
var corner_hot := false
var header_active := false
var corner_active := false
var start_size := Vector2.ZERO
@onready var object_view_textures: Array[TextureRect] = [
	$ColorRect3/HFlowContainer/ColorRect/TextureRect,
	$ColorRect3/HFlowContainer/ColorRect2/TextureRect,
	$ColorRect3/HFlowContainer/ColorRect3/TextureRect,
	$ColorRect3/HFlowContainer/ColorRect4/TextureRect,
	$ColorRect3/HFlowContainer/ColorRect5/TextureRect,
	$ColorRect3/HFlowContainer/ColorRect6/TextureRect,
	$ColorRect3/HFlowContainer/ColorRect7/TextureRect,
	$ColorRect3/HFlowContainer/ColorRect8/TextureRect,
	$ColorRect3/HFlowContainer/ColorRect9/TextureRect,
	$ColorRect3/HFlowContainer/ColorRect10/TextureRect
]

func _process(delta) -> void:
	if mouse_pressed:
		mouse_pressed = false
	object_view_textures = [
		$ColorRect3/HFlowContainer/ColorRect/TextureRect,
		$ColorRect3/HFlowContainer/ColorRect2/TextureRect,
		$ColorRect3/HFlowContainer/ColorRect3/TextureRect,
		$ColorRect3/HFlowContainer/ColorRect4/TextureRect,
		$ColorRect3/HFlowContainer/ColorRect5/TextureRect,
		$ColorRect3/HFlowContainer/ColorRect6/TextureRect,
		$ColorRect3/HFlowContainer/ColorRect7/TextureRect,
		$ColorRect3/HFlowContainer/ColorRect8/TextureRect,
		$ColorRect3/HFlowContainer/ColorRect9/TextureRect,
		$ColorRect3/HFlowContainer/ColorRect10/TextureRect
	]
	pass

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			mouse_down = true
			mouse_pressed = true
			if header_hot:
				header_active = true
			if corner_hot:
				corner_active = true
		elif not event.pressed:
			mouse_down = false
			header_active = false
			corner_active = false
	pass # Replace with function body.


func _on_mouse_entered() -> void:
	hot = true
	pass # Replace with function body.


func _on_mouse_exited() -> void:
	hot = false
	pass # Replace with function body.


func _on_color_rect_mouse_entered() -> void:
	header_hot = true
	pass # Replace with function body.


func _on_color_rect_mouse_exited() -> void:
	header_hot = false
	pass # Replace with function body.


func _on_color_rect_2_mouse_entered() -> void:
	corner_hot = true
	pass # Replace with function body.


func _on_color_rect_2_mouse_exited() -> void:
	corner_hot = false
	pass # Replace with function body.
