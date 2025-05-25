extends CharacterBody2D

const SPEED = 400.0
const RAYCAST_POSITION_IZQUIERDA = 0
const RAYCAST_POSITION_DERECHA = 0
var appeared: bool = true
var is_farting: bool = false
var peo_pendiente: bool = false

@onready var fart_timer = Timer.new()
@onready var fart_sound = $FartSound

func _ready():
	$animaciones.play("appear")
	add_child(fart_timer)
	fart_timer.wait_time = 10.0
	fart_timer.one_shot = false
	fart_timer.connect("timeout", Callable(self, "_on_fart_timer_timeout"))
	fart_timer.start()

func _physics_process(delta):
	# Movimiento libre en 2D (sin gravedad ni saltos)
	var dir_x = Input.get_axis("ui_left", "ui_right")
	var dir_y = Input.get_axis("ui_up", "ui_down")
	var direction = Vector2(dir_x, dir_y).normalized()

	velocity = direction * SPEED
	move_and_slide()

	if peo_pendiente and puede_hacer_peo():
		print("💨 [PENDIENTE] Ejecutando peo pendiente")
		peo_pendiente = false
		await reproducir_peo()

	if is_farting and direction.length() > 0:
		print("❌ [CANCELADO] Movimiento detectado durante peo. Cancelando...")
		cancelar_peo()

	decide_animation(direction)

	if Input.is_action_just_pressed("forzar_peo"):
		print("🔥 [DEBUG] Forzando peo manualmente desde tecla P")
		await forzar_peo_manual()

func decide_animation(direction := Vector2.ZERO):
	if not appeared or is_farting:
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

func puede_hacer_peo() -> bool:
	return $animaciones.animation == "idle" and velocity.length() == 0

func forzar_peo_manual() -> void:
	if puede_hacer_peo() and not is_farting:
		await reproducir_peo()

func cancelar_peo():
	if is_farting:
		is_farting = false
		$animaciones.stop()
		decide_animation()

func reproducir_peo() -> void:
	is_farting = true
	print("💨 [PEO] Reproduciendo animación 'peo'")
	$animaciones.play("peo")
	fart_sound.play()
	await $animaciones.animation_finished
	is_farting = false
	print("✅ [PEO] Animación 'peo' terminada")
	decide_animation()

func _on_animaciones_animation_finished():
	appeared = true

func _on_fart_timer_timeout() -> void:
	if not is_farting:
		if puede_hacer_peo():
			await reproducir_peo()
		else:
			print("⏳ [ESPERA] Peo pospuesto hasta estar en idle.")
			peo_pendiente = true
