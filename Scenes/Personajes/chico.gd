extends CharacterBody2D

const SPEED = 400.0
var appeared: bool = true

func _physics_process(delta):
	var dir_x = Input.get_axis("ui_left", "ui_right")
	var dir_y = Input.get_axis("ui_up", "ui_down")
	var direction = Vector2(dir_x, dir_y).normalized()

	velocity = direction * SPEED
	move_and_slide()

	decide_animation(direction)

func decide_animation(direction := Vector2.ZERO):
	if not appeared:
		return

	if direction == Vector2.ZERO:
		$animaciones.play("idle")
	else:
		if abs(direction.y) > abs(direction.x):
			if direction.y < 0:
				$animaciones.play("up_run")
			else:
				$animaciones.play("down_run")
		else:
			$animaciones.flip_h = direction.x < 0
			$animaciones.play("run")

func _on_animaciones_animation_finished():
	appeared = true
