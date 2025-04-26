extends Control

# Nodos existentes
@onready var history = $Background/MarginContainer/Rows/GameInfo/History
@onready var nano_panel = $NanoPanel
@onready var editor = $NanoPanel/Editor
@onready var save_button = $NanoPanel/GuardarBoton
@onready var mision2_popup = $Mision2Popup

# Nodos nuevos para el diálogo
@onready var container_dialogo = $ContainerDialogo  # Nodo padre para el diálogo
@onready var dialog_box = $ContainerDialogo/DialogBox  # Panel para el cuadro de diálogo
@onready var dialog_content = $ContainerDialogo/DialogBox/DialogContent  # Texto del diálogo
@onready var dialog_arrow = $ContainerDialogo/DialogBox/DialogArrow  # Indicador gráfico (opcional)

# Variables principales
var current_command = ""
var current_path = "/"  # Ruta relativa dentro de ubuntu_sim
const BASE_PATH = "user://ubuntu_sim"  # Ruta real base
var current_file_being_edited = ""
var mision2_completada = false
const USER_COLOR = "[color=green]usuario@usuario[/color]"
const PROMPT_BASE = "$"
var prompt_text = ""
var history_text = ""  # Variable para almacenar todo el texto de la consola

# Variables para el sistema de diálogo
var dialog_active = false
var current_dialog_index = 0

# Diálogos de la misión
var mission2_dialogs = [
	"Excelente, ya te encuentras en el directorio donde está el archivo.\n" +
	"Ahora falta listarlo para asegurarnos que se encuentra ahí.\n" +
	"Para ello usaremos el comando `ls`. Solo tienes que escribir `ls` y pulsar la tecla intro."
]

var mission2_dialogs2 = [
	"¡Perfecto! Has encontrado el archivo `IPS_El_Bohío.txt`.\n" +
	"Ahora falta un paso más: ver el contenido de dicho fichero.\n" +
	"Para ello vas a usar el comando `cat` seguido del nombre del fichero,\n" +
	"por ejemplo: `cat IPS_El_Bohío.txt`. ¡Vamos, usa a ese gatito!"
]

var mission2_dialogs3 = [
	"Puedes ver que la IP del departamento de ventas es 192.168.10.10 y su puerta de enlace es 192.168.10.1.\n" +
	"Su puerta de enlace es el router desde donde le llega la conexión a internet.\n" +
	"Usa el comando `ping 192.168.10.10` del ordenador del departamento de ventas para ver si funciona.\n" +
	"Recuerda si quieres que el comando se detenga pulsa las teclas Ctrl + C"
]

var mission2_dialogs4 = [
	"El ping ha sido un éxito eso quiere decir que el problema no está con su equipo,\n" +
	"prueba hacer ping a la puerta de enlace."
]
var mission2_dialogs5 = [
	"Intentalo con el ping 192.168.10.10"
]

# Variables para controlar el flujo de la misión
var esperando_ls = false  # Esperando que el jugador use `ls`
var archivo_listado = false  # Indica si el jugador ha listado los archivos
var archivo_leido = false  # Indica si el jugador ha usado `cat` en el archivo
var ping_completado = false  # Indica si el jugador ha completado el primer ping
var ping_error = false # Indica si el jugador no puso el ping correcto.

#Variables para saber en que misión está
var mision_actual = 1 

# Variables para el comando ping
var ping_timer: Timer = null
var ping_active = false
var ping_host = ""
var ping_seq = 1
var rtt_times = []

func _ready():
	history.bbcode_enabled = true
	nano_panel.visible = false
	mision2_popup.visible = false
	dialog_box.visible = false  # Inicializar el diálogo oculto
	init_structure()
	show_prompt()
	save_button.pressed.connect(_on_save_button_pressed)

# Actualiza el prompt para no perder la visualización
func show_prompt():
	var path_color = "[color=skyblue]" + current_path + "[/color]"
	prompt_text = "\n" + USER_COLOR + ":" + path_color + PROMPT_BASE + " "
	if not ping_active:
		history_text += prompt_text  # Agrega el prompt al historial de texto solo si no estamos en un ping activo
	history.text = history_text  # Actualiza el texto de la consola

func init_structure():
	if not DirAccess.dir_exists_absolute(BASE_PATH):
		var dir = DirAccess.open("user://")
		if dir:
			dir.make_dir("ubuntu_sim")
			dir.change_dir("ubuntu_sim")
			for folder in ["home", "etc", "var", "secret", "bin"]:
				dir.make_dir(folder)
			dir.make_dir("home/usuario1")
			dir.make_dir("home/usuario1/Documents")
			dir.make_dir("home/usuario1/Descargas")
			dir.make_dir("home/usuario1/Escritorio")
			
			

func _input(event):
	if event is InputEventKey and event.pressed:
		# Ignorar eventos si el panel nano está visible y el editor tiene el foco
		if nano_panel.visible and editor.has_focus():
			return

		# Si el popup de misión 2 está visible, lo ocultamos al presionar Enter
		if mision2_popup.visible and event.keycode == KEY_ENTER:
			mision2_popup.visible = false
			return

		# Si el sistema de diálogo está activo, avanzamos con Enter
		if dialog_active:
			if event.keycode == KEY_ENTER:
				advance_dialog()
				return

		# Autocompletado con Tab
		if event.keycode == KEY_TAB:
			autocomplete_command()
			return

		# Procesar comandos normales
		if event.keycode == KEY_ENTER:
			process_command(current_command.strip_edges())
			current_command = ""
		elif event.keycode == KEY_BACKSPACE:
			if current_command.length() > 0:
				current_command = current_command.left(current_command.length() - 1)
				history.text = history_text + current_command
		elif event.unicode > 0:
			var char_input = char(event.unicode)
			current_command += char_input
			history.text = history_text + current_command
func autocomplete_command():
	# Dividir el comando actual en partes (por ejemplo, "cd Documents")
	var parts = current_command.strip_edges().split(" ")
	var last_part = parts[-1]  # Última parte del comando (lo que se está escribiendo)

	# Obtener el directorio actual
	var full_path = get_full_path()
	var dir = DirAccess.open(full_path)
	if not dir:
		return

	# Obtener archivos y carpetas en el directorio actual
	var dirs = dir.get_directories()
	var files = dir.get_files()
	var all_items = dirs + files

	# Filtrar coincidencias basadas en la última parte del comando
	var matches = []
	for item in all_items:
		if item.begins_with(last_part):
			matches.append(item)

	# Manejar las coincidencias
	if matches.size() == 1:
		# Si hay una única coincidencia, autocompletar
		var completed = matches[0]
		current_command = " ".join(parts.slice(0, -1)) + " " + completed
		history.text = history_text + current_command
	elif matches.size() > 1:
		# Si hay múltiples coincidencias, mostrar sugerencias
		var suggestions = "\nSugerencias: " + ", ".join(matches)
		history_text += suggestions
		history.text = history_text

func get_full_path():
	var normalized = current_path
	if normalized != "/" and normalized.ends_with("/"):
		normalized = normalized.substr(0, normalized.length() - 1)
	return BASE_PATH + normalized

func process_command(command: String):
	var output := ""
	history_text += command

	if command.begins_with("cd "):
		var target = command.substr(3).strip_edges()
		var new_path = current_path
		if target == "..":
			if current_path != "/":
				var parts = current_path.split("/")
				parts = parts.filter(func(p): return p != "")
				if parts.size() > 0:
					parts.remove_at(parts.size() - 1)
					new_path = "/" + "/".join(parts) if parts.size() > 0 else "/"
		elif target == "/":
			new_path = "/"
		else:
			new_path = target if target.begins_with("/") else current_path.rstrip("/") + "/" + target
		var full_path = BASE_PATH + new_path
		if DirAccess.dir_exists_absolute(full_path):
			current_path = new_path
			# Activar el estado de espera si estamos en el directorio correcto
			if current_path == "/home/usuario1/Documents" and not archivo_listado:
				esperando_ls = true
				if mision_actual == 1:
					start_dialog(mission2_dialogs)  # Iniciar el primer diálogo
					mision_actual = 2
		else:
			output = "No existe el directorio: " + target

	elif command == "ls":
		var full_path = get_full_path()
		var dir = DirAccess.open(full_path)
		if dir:
			var dirs = dir.get_directories()
			var files = dir.get_files()
			output = " ".join(dirs + files)
			# Verificar si el jugador ha listado el archivo correcto
			if current_path == "/home/usuario1/Documents" and esperando_ls and not archivo_listado:
				if "IPS_El_Bohío.txt" in files:  # Verificar si el archivo está presente
					archivo_listado = true
					esperando_ls = false
					if mision_actual == 2:
						start_dialog(mission2_dialogs2)  # Iniciar el segundo diálogo
						mision_actual = 3
		else:
			output = "No se pudo abrir el directorio."

	elif command.begins_with("cat "):
		var filename = command.substr(4).strip_edges()
		if filename == "":
			output = "Error: Debes proporcionar el nombre de un archivo."
		else:
			var file_path = get_full_path() + "/" + filename
			if FileAccess.file_exists(file_path):
				var file = FileAccess.open(file_path, FileAccess.READ)
				if file:
					output = file.get_as_text()  # Leer el contenido del archivo
					file.close()
					# Mostrar el tercer diálogo si el jugador ha leído el archivo correcto
					if archivo_listado and filename == "IPS_El_Bohío.txt" and not archivo_leido:
						archivo_leido = true
						if mision_actual == 3:
							start_dialog(mission2_dialogs3)  # Iniciar el segundo diálogo
							mision_actual = 4
				else:
					output = "Error: No se pudo abrir el archivo."
			else:
				output = "Error: El archivo '" + filename + "' no existe."

	elif command.begins_with("ping"):
		var target = command.substr(5).strip_edges()
		if target == "":
			output = "Error: Debes proporcionar una dirección IP o nombre de host."
		else:
			ping_host = target
			if is_valid_ip(target) or resolve_hostname(target):
				if mision_actual == 4:
					if ping_host == "192.168.10.10":
						start_dialog(mission2_dialogs4)  # Iniciar el cuarto diálogo
						mision_actual = 5
					else:# Mensaje de
						start_dialog(mission2_dialogs5) 
				ping_active = true
				ping_seq = 1
				rtt_times.clear()
				ping_timer = Timer.new()
				ping_timer.wait_time = 1.0  # Intervalo de 1 segundo entre paquetes
				ping_timer.one_shot = false
				add_child(ping_timer)
				ping_timer.timeout.connect(_on_ping_timer_timeout)
				ping_timer.start()

				history_text += "\nPING " + ping_host + " (" + ping_host + ") 56(84) bytes of data.\n"
				history.text = history_text
				show_prompt()  # Mantener el prompt visible
				if not ping_active and ping_host == "192.168.10.10" and not ping_completado:
					ping_completado = true
					
				
			else:
				output = "ping: " + target + ": Temporary failure in name resolution"

	elif command == "clear":
		history_text = ""  # Limpiamos todo el historial de la consola
		show_prompt()  # Volvemos a mostrar el prompt inicial
		return

	elif command == "help":
		output = "Comandos disponibles:\ncd [ruta], ls, mkdir [nombre], touch [archivo], nano [archivo], rm [-r] [archivo/directorio], cat [archivo], clear, help"

	elif command == "":
		pass

	else:
		# Validar si estamos esperando el comando `ls`
		if esperando_ls:
			output = "Ese comando no es correcto. Prueba con ls."
		else:
			output = "{command}: Comando no encontrado.".format({"command": command.split(" ")[0]})

	# Agregar la salida del comando al historial **antes** de agregar el prompt para el siguiente comando
	if output != "":
		history_text += "\n" + output  # Agrega la salida del comando al historial
		history.text = history_text  # Actualiza el texto de la consola
	show_prompt()  # Muestra el prompt para el siguiente comando

func _on_ping_timer_timeout():
	if not ping_active:
		return

	var time = randf_range(0.020, 0.030)  # Simulación de tiempo de respuesta
	rtt_times.append(time)
	history_text += "64 bytes from " + ping_host + ": icmp_seq=" + str(ping_seq) + " ttl=64 time=%.3f ms\n" % time
	history.text = history_text
	ping_seq += 1
		 #Si el jugador detiene el ping con Ctrl+C, mostrar el cuarto diálogo
	if not ping_active:
		ping_completado = true

func _on_save_button_pressed():
	var file = FileAccess.open(current_file_being_edited, FileAccess.WRITE)
	if file:
		file.store_string(editor.text)
		file.close()
		nano_panel.visible = false
		history_text += "\nArchivo guardado: " + current_file_being_edited
		history.text = history_text
		show_prompt()

# Funciones para manejar el sistema de diálogo
func start_dialog(dialogs: Array):
	dialog_active = true
	current_dialog_index = 0
	mission2_dialogs = dialogs
	show_dialog()

func show_dialog():
	dialog_box.visible = true
	dialog_content.text = mission2_dialogs[current_dialog_index]

func advance_dialog():
	if dialog_active:
		current_dialog_index += 1
		if current_dialog_index < mission2_dialogs.size():
			show_dialog()
		else:
			close_dialog()

func close_dialog():
	dialog_active = false
	dialog_box.visible = false
	dialog_content.text = ""

# Funciones de validación para el comando ping
func is_valid_ip(ip: String) -> bool:
	var parts = ip.split(".")
	if parts.size() != 4:
		return false
	for part in parts:
		if not is_only_digits(part):
			return false
		var num = int(part)
		if num < 0 or num > 255:
			return false
	return true

func is_only_digits(s: String) -> bool:
	for c in s:
		if c < '0' or c > '9':
			return false
	return true

func resolve_hostname(hostname: String) -> bool:
	# Simulación simple de resolución de nombres
	return hostname == "localhost" or hostname.ends_with(".com")
