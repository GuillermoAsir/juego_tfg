extends Camera2D

@export var target: Node2D
@export var part_width := 1920
@export var total_parts := 4
@export var vertical_center := 540
@export var follow_speed := 5.0
@export var camera_y_offset := 0.0  # Puedes usar esto para centrar mejor la altura

func _enter_tree():
	if target == null:
		print("Error: No se ha asignado un objetivo a la cámara.")
		return
	global_position = Vector2(target.global_position.x, vertical_center)

func _ready():
	make_current()

func _process(delta):
	if target == null:
		return

	var player_pos = target.global_position
	var current_part = clamp(int(player_pos.x / part_width), 0, total_parts - 1)
	var transition_threshold = part_width * 0.2  # Umbral del 20%

	var target_pos := global_position

	var screen_half = get_viewport_rect().size.x / 2
	var part_start = current_part * part_width
	var part_end = (current_part + 1) * part_width
	var mid_x = player_pos.x

	match current_part:
		0:
			# Solo se mueve si el jugador está a la derecha del centro de la pantalla
			if mid_x > part_start + screen_half:
				target_pos.x = clamp(mid_x, part_start + screen_half, part_end - screen_half)
			else:
				target_pos.x = part_start + screen_half

		1, 2:
			# Se mueve siempre, centrado respecto al jugador, limitado a los bordes
			target_pos.x = clamp(mid_x, part_start + screen_half, part_end - screen_half)

		3:
			# Solo se mueve si el jugador está a la izquierda del centro de la pantalla
			if mid_x < part_end - screen_half:
				target_pos.x = clamp(mid_x, part_start + screen_half, part_end - screen_half)
			else:
				target_pos.x = part_end - screen_half


	# Ahora también seguimos al jugador en Y
	var target_y = clamp(player_pos.y + camera_y_offset, 0, 1080)
	target_pos.y = target_y

	# Suavizado con lerp
	global_position = global_position.lerp(target_pos, follow_speed * delta)
