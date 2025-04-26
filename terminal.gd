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
	"Usa el comando `ping 192.168.10.10` del ordenador del departamento de ventas para ver si funciona."
]

# Variables para controlar el flujo de la misión
var esperando_ls = false  # Esperando que el jugador use `ls`
var archivo_listado = false  # Indica si el jugador ha listado los archivos
var archivo_leido = false  # Indica si el jugador ha usado `cat` en el archivo

# Variables para el comando ping
var ping_timer: Timer = null
var ping_active = false
var ping_host = ""
var ping_seq = 1
var rtt_times = []

# Variables para el servicio Apache
var apache_status = "failed"  # Estado inicial del servicio Apache
var sudo_password_entered = ""  # Almacena temporalmente la contraseña
var waiting_for_sudo_password = false  # Indica si estamos esperando la contraseña

func _on_save_button_pressed():
	var file = FileAccess.open(current_file_being_edited, FileAccess.WRITE)
	if file:
		file.store_string(editor.text)
		file.close()
	nano_panel.visible = false
	history_text += "\nArchivo guardado: " + current_file_being_edited
	history.text = history_text
	show_prompt()
	
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
	if not ping_active and not waiting_for_sudo_password:
		history_text += prompt_text  # Agrega el prompt al historial de texto
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
		# Si el panel nano está visible y el editor tiene el foco, ignoramos otros eventos
		if nano_panel.visible and editor.has_focus():
			return

		# Si el popup de misión 2 está visible, lo ocultamos al presionar Enter
		if mision2_popup.visible and event.keycode == KEY_ENTER:
			mision2_popup.visible = false
			return

		# Si el sistema de diálogo está activo, procesamos el avance del diálogo
		if dialog_active:
			if event.keycode == KEY_ENTER:
				advance_dialog()  # Avanzar al siguiente diálogo
				return

		# Manejo del comando Ctrl+C para detener el ping
		if event.keycode == KEY_C and event.ctrl_pressed and ping_active:
			ping_active = false
			if is_instance_valid(ping_timer):
				ping_timer.queue_free()
				ping_timer = null
			var summary = "^C\n--- " + ping_host + " ping statistics ---\n"
			summary += str(ping_seq - 1) + " packets transmitted, " + str(ping_seq - 1) + " received, 0% packet loss\n"
			var min_time = rtt_times.min() if rtt_times.size() > 0 else 0.0
			var max_time = rtt_times.max() if rtt_times.size() > 0 else 0.0
			var avg_func = func(a, b): return a + b
			var avg_time = rtt_times.reduce(avg_func) / rtt_times.size() if rtt_times.size() > 0 else 0.0
			var variance_func = func(a, b): return a + pow(b - avg_time, 2)
			var mdev = sqrt(rtt_times.reduce(variance_func, 0.0) / rtt_times.size()) if rtt_times.size() > 0 else 0.0
			summary += "rtt min/avg/max/mdev=%.3f/%.3f/%.3f/%.3f ms\n" % [min_time, avg_time, max_time, mdev]
			history_text += summary
			history.text = history_text
			show_prompt()
			return

		# Procesar entrada para la contraseña de sudo
		if waiting_for_sudo_password:
			if event.keycode == KEY_ENTER:
				if sudo_password_entered == "1234":  # Contraseña válida
					waiting_for_sudo_password = false
					process_sudo_command(current_command.strip_edges())
					current_command = ""
				else:
					sudo_password_entered = ""
					history_text += "\nsudo: contraseña incorrecta\n"
					history.text = history_text
					show_prompt()
			elif event.keycode == KEY_BACKSPACE:
				if sudo_password_entered.length() > 0:
					sudo_password_entered = sudo_password_entered.left(sudo_password_entered.length() - 1)
			elif event.unicode > 0:
				sudo_password_entered += char(event.unicode)
			return

		# Procesar comandos normales
		if event.keycode == KEY_ENTER:
			process_command(current_command.strip_edges())
			current_command = ""  # Limpiamos el comando actual después de procesarlo
		elif event.keycode == KEY_BACKSPACE:
			if current_command.length() > 0:
				# Borramos un carácter de current_command
				current_command = current_command.left(current_command.length() - 1)
				# También eliminamos el último carácter del comando sin afectar el prompt
				history.text = history_text + current_command
		elif event.unicode > 0:
			var char_input = char(event.unicode)
			current_command += char_input
			history.text = history_text + current_command

func get_full_path():
	var normalized = current_path
	if normalized != "/" and normalized.ends_with("/"):
		normalized = normalized.substr(0, normalized.length() - 1)
	return BASE_PATH + normalized

func process_command(command: String):
	if command.begins_with("sudo"):
		# Solicitar contraseña para comandos sudo
		waiting_for_sudo_password = true
		history_text += "[sudo] contraseña para usuario: "
		history.text = history_text
		return

	if command == "sudo systemctl status apache2":
		if apache_status == "failed":
			history_text += format_apache_error_message()
		else:
			history_text += format_apache_active_message()
	elif command == "sudo systemctl restart apache2":
		if apache_status == "failed":
			apache_status = "active"
			history_text += "Restarting apache2.service...\nApache restarted successfully.\n"
		else:
			history_text += "Apache service is already running.\n"
	elif command == "systemctl status apache2":
		history_text += "Failed to connect to bus: Permission denied\nUse 'sudo' to gain elevated privileges.\n"
	elif command.begins_with("cd"):
		var target = command.substr(3).strip_edges()
		var new_path = current_path
		if target == "..":
			if current_path != "/":
				var parts = []
				for p in current_path.split("/"):
					if p != "":
						parts.append(p)
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
				start_dialog(mission2_dialogs)  # Iniciar el primer diálogo
		else:
			history_text += "No existe el directorio: " + target + "\n"
	elif command == "ls":
		var full_path = get_full_path()
		var dir = DirAccess.open(full_path)
		if dir:
			var dirs = dir.get_directories()
			var files = dir.get_files()
			history_text += " ".join(dirs + files) + "\n"
			# Verificar si el jugador ha listado el archivo correcto
			if current_path == "/home/usuario1/Documents" and esperando_ls and not archivo_listado:
				if "IPS_El_Bohío.txt" in files:  # Verificar si el archivo está presente
					archivo_listado = true
					start_dialog(mission2_dialogs2)  # Iniciar el segundo diálogo
					esperando_ls = false
				else:
					history_text += "No se pudo abrir el directorio.\n"
		else:
			history_text += "No se pudo abrir el directorio.\n"
	elif command.begins_with("cat"):
		var filename = command.substr(4).strip_edges()
		if filename == "":
			history_text += "Error: Debes proporcionar el nombre de un archivo.\n"
		else:
			var file_path = get_full_path() + "/" + filename
			if FileAccess.file_exists(file_path):
				var file = FileAccess.open(file_path, FileAccess.READ)
				if file:
					history_text += file.get_as_text() + "\n"  # Leer el contenido del archivo
					file.close()
					# Mostrar el tercer diálogo si el jugador ha leído el archivo correcto
					if archivo_listado and filename == "IPS_El_Bohío.txt" and not archivo_leido:
						archivo_leido = true
						start_dialog(mission2_dialogs3)  # Iniciar el tercer diálogo
				else:
					history_text += "Error: No se pudo abrir el archivo.\n"
			else:
				history_text += "Error: El archivo '" + filename + "' no existe.\n"
	elif command.begins_with("ping"):
		var target = command.substr(5).strip_edges()
		if target == "":
			history_text += "Error: Debes proporcionar una dirección IP o nombre de host.\n"
		else:
			if is_valid_ip(target) or resolve_hostname(target):
				ping_host = target
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
				show_prompt()
			else:
				history_text += "ping: " + target + ": Temporary failure in name resolution\n"
	elif command == "clear":
		history_text = ""  # Limpiamos todo el historial de la consola
		show_prompt()  # Volvemos a mostrar el prompt inicial
		return
	elif command == "help":
		history_text += "Comandos disponibles:\ncd [ruta], ls, mkdir [nombre], touch [archivo], nano [archivo], rm [-r] [archivo/directorio], cat [archivo], clear, help\n"
	else:
		history_text += "{command}: Comando no encontrado.".format({"command": command.split(" ")[0]}) + "\n"

	# Agregar la salida del comando al historial **antes** de agregar el prompt para el siguiente comando
	history.text = history_text
	show_prompt()

func process_sudo_command(command: String):
	if command == "sudo systemctl status apache2":
		if apache_status == "failed":
			history_text += format_apache_error_message()
		else:
			history_text += format_apache_active_message()
	elif command == "sudo systemctl restart apache2":
		if apache_status == "failed":
			apache_status = "active"
			history_text += "Restarting apache2.service...\nApache restarted successfully.\n"
		else:
			history_text += "Apache service is already running.\n"
	else:
		history_text += "{command}: Comando no encontrado.".format({"command": command.split(" ")[0]}) + "\n"
	history.text = history_text
	show_prompt()

func format_apache_error_message() -> String:
	var timestamp = get_formatted_datetime()
	return """
[%s] ● apache2.service - The Apache HTTP Server
   Loaded: loaded (/lib/systemd/system/apache2.service; enabled; vendor preset: enabled)
  Drop-In: /lib/systemd/system/apache2.service.d
		   └─apache2-systemd.conf
   Active: failed (Result: exit-code) since Wed 2019-11-20 22:07:23 +08; 10s ago
  Process: 21191 ExecStart=/usr/sbin/apachectl start (code=exited, status=1/FAILURE)

Nov 20 22:07:23 roy-UX430UNR apachectl[21191]: AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 127.0.1.1. Set the 'ServerName' directive globally to suppress this message
Nov 20 22:07:23 roy-UX430UNR apachectl[21191]: (98)Address already in use: AH00072: make_sock: could not bind to address [::]:80
Nov 20 22:07:23 roy-UX430UNR apachectl[21191]: (98)Address already in use: AH00072: make_sock: could not bind to address 0.0.0.0:80
Nov 20 22:07:23 roy-UX430UNR apachectl[21191]: no listening sockets available, shutting down
Nov 20 22:07:23 roy-UX430UNR apachectl[21191]: AH00015: Unable to open logs
Nov 20 22:07:23 roy-UX430UNR apachectl[21191]: Action 'start' failed.
Nov 20 22:07:23 roy-UX430UNR apachectl[21191]: The Apache error log may have more information.
Nov 20 22:07:23 roy-UX430UNR systemd[1]: apache2.service: Control process exited, code=exited status=1
Nov 20 22:07:23 roy-UX430UNR systemd[1]: apache2.service: Failed with result 'exit-code'.
Nov 20 22:07:23 roy-UX430UNR systemd[1]: Failed to start The Apache HTTP Server.
""" % timestamp

func format_apache_active_message() -> String:
	var timestamp = get_formatted_datetime()
	return """
[%s] ● apache2.service - The Apache HTTP Server
   Loaded: loaded (/lib/systemd/system/apache2.service; enabled; vendor preset: enabled)
   Active: active (running) since ...
""" % timestamp

# Función para obtener la fecha y hora formateadas
func get_formatted_datetime() -> String:
	var datetime = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d %02d:%02d:%02d" % [
		datetime["year"], datetime["month"], datetime["day"],
		datetime["hour"], datetime["minute"], datetime["second"]
	]
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

# Función auxiliar para validar IPs
func is_valid_ip(ip: String) -> bool:
	var parts = ip.split(".")
	if parts.size() != 4:
		return false
	for part in parts:
		if not part.is_digit() or int(part) < 0 or int(part) > 255:
			return false
	return true

# Función auxiliar para resolver nombres de host
func resolve_hostname(hostname: String) -> bool:
	# Implementa aquí la lógica para resolver nombres de host si es necesario
	return hostname == "localhost"  # Ejemplo básico

func _on_ping_timer_timeout():
	if not ping_active:
		return
	var time = randf_range(0.020, 0.030)  # Simulación de tiempo de respuesta
	rtt_times.append(time)
	history_text += "64 bytes from " + ping_host + ": icmp_seq=" + str(ping_seq) + " ttl=64 time=%.3f ms\n" % time
	history.text = history_text
	ping_seq += 1
