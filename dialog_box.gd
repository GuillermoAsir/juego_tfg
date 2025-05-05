extends Popup

@onready var label_text = $DialogContent
var dialog_lines: Array = []
var current_index := 0

func start_dialog(lines: Array):
	dialog_lines = lines
	current_index = 0
	label_text.text = dialog_lines[current_index]
	show()
	
func _input(event):
	if event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE):
		current_index += 1
		if current_index < dialog_lines.size():
			label_text.text = dialog_lines[current_index]
		else:
			hide()
