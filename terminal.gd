extends Control

# Nodos existentes
@onready var history = $Background/MarginContainer/Rows/GameInfo/History
@onready var nano_panel = $NanoPanel
@onready var editor = $NanoPanel/Editor
@onready var save_button = $NanoPanel/GuardarBoton
@onready var timer = $Background/MarginContainer/Rows/GameInfo/Timer


# Nodos nuevos para el diálogo
@onready var container_dialogo = $ContainerDialogo  # Nodo padre para el diálogo
@onready var dialog_box = $ContainerDialogo/DialogBox  # Panel para el cuadro de diálogo
@onready var dialog_content = $ContainerDialogo/DialogBox/DialogContent  # Texto del diálogo
@onready var dialog_arrow = $ContainerDialogo/DialogBox/DialogArrow  # Indicador gráfico (opcional)


#Variables para saber en que misión está
var mision_actual = MISION_INICIAL_1_CD_1

const MISION_INICIAL_1_CD_1 = 1
const MISION_INICIAL_2_LS_2 = 2
const MISION_INICIAL_3_CAT_3 = 3
const MISION_INICIAL_4_PING10_4 = 4
const MISION_INICIAL_5_PING1_FAIL_5 = 5
const MISION_INICIAL_6_PING1_OK_6 = 6

const MISION_APACHE_1_STATUS_FALLIDO_7 = 7
const MISION_APACHE_2_RESTART_8 = 8
const MISION_APACHE_3_STATUS_OK_9 = 9

const MISION_SSH_1_10 = 10
const MISION_SSH_2_CP_11 = 11
const MISION_SSH_3_LS_12 = 12
const MISION_SSH_4_EXIT_13 = 13

const MISION_CLEAN_1_SSH_14 = 14
const MISION_CLEAN_2_DF_15 = 15
const MISION_CLEAN_3_APT_CLEAN_16 = 16
const MISION_CLEAN_4_APT_AUTOCLEAN_17 = 17
const MISION_CLEAN_5_AUTOREMOVE_18 = 18
const MISION_CLEAN_6_RM_TMP_19 = 19
const MISION_CLEAN_7_RM_VAR_20 = 20
const MISION_CLEAN_8_RM_DESCARGAS_21 = 21
const MISION_CLEAN_9_RM_SHARE_FILES_22 = 22
const MISION_CLEAN_10_RM_SHARE_INFO_23 = 23
const MISION_CLEAN_11_DF_OK_24 = 24
const MISION_CLEAN_12_EXIT_25 = 25


# Variables principales
var current_command = ""
var previous_path = ""
var current_path = "/"  # Ruta relativa dentro de ubuntu_sim
const BASE_PATH = "user://ubuntu_sim"  # Ruta real base
const BASE_PATH_CONTABILIDAD = "user://contabilidad_sim"  # Ruta base para el usuario contabilidad
const BASE_PATH_VENTAS = "user://ventas_sim"  # Ruta base para el usuario ventas (futuro)
var ssh_user_base_path = "user://contabilidad_sim"  # Ruta base para el usuario remoto (por ejemplo, "user://contabilidad")
var current_file_being_edited = ""
var mision2_completada = false
const USER_COLOR = "[color=green]usuario@usuario[/color]"
const PROMPT_BASE = "$"
var prompt_text = ""
var history_text = ""  # Variable para almacenar todo el texto de la consola

# Variables para el cursor
var cursor_pos = 0
var cursor_visible = true
var cursor_timer: Timer # Nodo Timer

#Comando sudo
var sudo_password = "contraseña123"  # Contraseña predeterminada para sudo
var sudo_authenticated = false      # Indica si el jugador ya ha ingresado la contraseña

#Fichero mensaje para pam
var para_pam_file_path = BASE_PATH_CONTABILIDAD + "/home/contabilidad/Documentos/Privado/Para_Pam.txt"

# Variables para controlar lo que se ha introducido por consola
var comandos_introducidos: Array[String] = [
	#"cd home/usuario/Documentos",
	#"ls",
	#"ping 192.168.10.1",
	#"ping 192.168.10.10",
	#"cat IPS_Departamentos.txt",
	#"sudo systemctl status apache",
	#"sudo systemctl restart apache",
	"ssh contabilidad@192.168.10.100",
	#"rm -r /tmp/*",
	#"rm -r /var/tmp/*",
	#"rm -rf /contabilidad/Descargas/*",
	#"rm -r /contabilidad/.local/share/Trash/files/*",
	#"rm -r contabilidad/.local/share/Trash/info/*",
	"df -h /contabilidad"
	]
var comando_actual = null

# Variables para controlar el flujo de la misión Apache
var fecha_actual = Time.get_datetime_string_from_unix_time(Time.get_unix_time_from_system())

# Variables comandos chorras
var start_time = Time.get_unix_time_from_system()  # Esto lo deberías inicializar al arranque
#var command_history = []  # Lista para almacenar el historial

#Variables ssh
var ssh_active = false  # Indica si el jugador está conectado por SSH
var ssh_host = ""       # Guarda el nombre del host al que está conectado
var ssh_user = ""       # Guarda el nombre de usuario
#var entorno_actual = "local"  # Puede ser "local" o "remoto"

# Datos simulados para df -h
var disk_usage = [
	{ "filesystem": "/dev/sda1", "size": "50G", "used": "25G", "avail": "25G", "use%": "50%", "mounted": "/mnt" },
	{ "filesystem": "/dev/sdb1", "size": "250G", "used": "245G", "avail": "5G", "use%": "98%", "mounted": "/mnt" },
	{ "filesystem": "/tmpfs", "size": "4G", "used": "1G", "avail": "3G", "use%": "25%", "mounted": "/mnt" }
]

#var disk_mision_clean = { 
	#"filesystem": "/dev/sda1", 
	#"size": "100G", 
	#"used": "98G", 
	#"avail": "2.0G", 
	#"use%": "98%", 
	#"mounted": "/home/contabilidad",
#}


#Lista de IPs permitidas
var ssh_allowed_ips = ["192.168.10.100", "192.168.10.101", "192.168.10.102"]

#Lista de nombres de dominio permitidos
var ssh_allowed_domains = {
	"servidor.contabilidad.local": "192.168.1.100",
	"router.local": "192.168.1.1",
	"backup.servidor.local": "192.168.1.101"
}

# Variables para el comando ping
var ping_timer: Timer = null
var ping_active = false
var ping_host = ""
var ping_seq = 1
var rtt_times = []


func _ready():
	history.bbcode_enabled = true
	nano_panel.visible = false
	dialog_box.visible = false  # Inicializar el diálogo oculto
	show_prompt()
	save_button.pressed.connect(_on_save_button_pressed)

	if not cursor_timer: #Verifica si el timer está inicializado
		cursor_timer = Timer.new() #Crea una nueva instancia de Timer
		cursor_timer.wait_time = 0.5 # Tiempo de espera del temporizador
		cursor_timer.connect("timeout", Callable(self, "_on_cursor_timer_timeout"))
		add_child(cursor_timer)
	cursor_timer.start()

func update_command_display():
	var display_text = current_command
	if cursor_visible:
		display_text = display_text.insert(cursor_pos, "▌")
	history.text = history_text + display_text

func _on_cursor_timer_timeout():
	cursor_visible = not cursor_visible
	update_command_display()

func _on_inactivity_timeout():
	cursor_timer.start()  # Reactivar el parpadeo

#Se ejecuta cuando el nodo está a punto de ser eliminado de la escena
func _exit_tree():
	if cursor_timer:
		cursor_timer.stop()
		if cursor_timer.is_connected("timeout", Callable(self, "_on_cursor_timer_timeout")):
			cursor_timer.disconnect("timeout", Callable(self, "_on_cursor_timer_timeout"))
		cursor_timer.queue_free()

func show_prompt():
	var path_color = "[color=skyblue]" + current_path + "[/color]"
	var ssh_info = ""
	if ssh_active:
		# Si está conectado por SSH, muestra el prompt del servidor remoto
		ssh_info = "[color=green]" + ssh_user + "@" + ssh_host + "[/color]:"
		prompt_text = ssh_info + path_color + PROMPT_BASE + " "
	else:
		# Si no está conectado por SSH, muestra el prompt local
		prompt_text = USER_COLOR + ":" + path_color + PROMPT_BASE + " "

	history_text += "\n" + prompt_text  # Agrega el prompt al historial de texto
	history.text = history_text  # Actualiza el texto de la consola


func _input(event):
	if event is InputEventKey and event.pressed:
		# Si el panel nano está visible y el editor tiene el foco, ignoramos otros eventos
		if nano_panel.visible and editor.has_focus():
			return

		if event.keycode == KEY_UP:
			if comando_actual == null:
				if comandos_introducidos.size() > 0:
					comando_actual = 0
				else:
					return
			elif comando_actual < comandos_introducidos.size() - 1:
				comando_actual += 1
			else:
				return

			if comando_actual == null:
				history.text = history_text
			else:
				history.text = history_text + comandos_introducidos[comando_actual]
				current_command = comandos_introducidos[comando_actual]
				cursor_pos = current_command.length()  # Actualizamos cursor al final
			return

		if event.keycode == KEY_DOWN:
			if comando_actual != null:
				if comando_actual == 0:
					comando_actual = null
					history.text = history_text
				else:
					comando_actual -= 1
					history.text = history_text + comandos_introducidos[comando_actual]
					current_command = comandos_introducidos[comando_actual]
					cursor_pos = current_command.length()  # Actualizamos cursor al final
			else:
				return
			return

		# Manejo del movimiento del cursor
		if event.keycode == KEY_LEFT:
			if cursor_pos > 0:
				cursor_pos -= 1
				cursor_visible = true  # Mantener el cursor visible
				cursor_timer.stop()  # Detener el parpadeo mientras se mueve
				update_command_display()
				_on_inactivity_timeout()
			return


		if event.keycode == KEY_RIGHT:
			if cursor_pos < current_command.length():
				cursor_pos += 1
				cursor_visible = true  # Mantener el cursor visible
				cursor_timer.stop()  # Detiene el parpadeo mientras se mueve
				update_command_display()
				_on_inactivity_timeout()
			return

		# Manejo del comando Ctrl+C para detener el ping
		if event.keycode == KEY_C and event.ctrl_pressed and ping_active:
			ping_active = false
			if is_instance_valid(ping_timer):
				ping_timer.queue_free()
				ping_timer = null
			
			if mision_actual == MISION_INICIAL_5_PING1_FAIL_5 and ping_host == "192.168.10.1":
				var transmitted = ping_seq - 1
				var received = 0  # Ningún paquete recibido
				var lost_percent = 100

				var summary = "^C\n--- " + ping_host + " ping statistics ---\n"
				summary += str(transmitted) + " packets transmitted, " + str(received) + " received, " + str(lost_percent) + "% packet loss\n"

				if rtt_times.size() > 0:
					var min_time = rtt_times.min()
					var max_time = rtt_times.max()
					var avg_func = func(a, b): return a + b
					var avg_time = rtt_times.reduce(avg_func) / rtt_times.size()
					var variance_func = func(a, b): return a + pow(b - avg_time, 2)
					var mdev = sqrt(rtt_times.reduce(variance_func, 0.0) / rtt_times.size())
					summary += "rtt min/avg/max/mdev=%.3f/%.3f/%.3f/%.3f ms\n" % [min_time, avg_time, max_time, mdev]

				history_text += summary
				history.text = history_text
				show_prompt()
				mision_actual = MISION_INICIAL_6_PING1_OK_6
				start_dialog(Dialogos.mision_inicial_dialogs6)
			else:
				var summary = "^C\n---" + ping_host + " ping statistics---\n"
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
				
				if mision_actual == MISION_INICIAL_4_PING10_4:
					if ping_host == "192.168.10.10":
						mision_actual = MISION_INICIAL_5_PING1_FAIL_5
						start_dialog(Dialogos.mision_inicial_dialogs4)
					else:
						start_dialog(Dialogos.mision_inicial_dialogs5)
				elif mision_actual == MISION_INICIAL_6_PING1_OK_6 and ping_host == "192.168.10.1":
					mision_actual = MISION_APACHE_1_STATUS_FALLIDO_7
					start_dialog(Dialogos.mision_inicial_dialogs7)
			return

		# Procesar comandos normales
		if event.keycode == KEY_ENTER:
			if ping_active:
				return
			var comando = current_command.strip_edges()
			if comando != "":
				comandos_introducidos.insert(0, comando)
			comando_actual = null
			process_command(comando)
			current_command = ""
			cursor_pos = 0
			update_command_display()  
			return

		elif event.keycode == KEY_BACKSPACE:
			if cursor_pos > 0:
				current_command = current_command.substr(0, cursor_pos - 1) + current_command.substr(cursor_pos)
				cursor_pos -= 1
				update_command_display()
			return

		elif event.unicode > 0:
			var char_input = char(event.unicode)
			current_command = current_command.insert(cursor_pos, char_input)
			cursor_pos += 1
			update_command_display()
			return

		if event.keycode == KEY_TAB:
			autocomplete_command()
			return


func get_full_path() -> String:
	# Eliminar espacios en blanco al inicio y final de la ruta
	var normalized = current_path.strip_edges()

	# Eliminar barras diagonales adicionales al final de la ruta
	normalized = normalized.rstrip("/")

	# Asegurarse de que la ruta raíz ("/") no se convierta en una cadena vacía
	if normalized == "":
		normalized = "/"

	# Validar que la ruta comience con "/"
	if not normalized.begins_with("/"):
		normalized = "/" + normalized

	# Construir la ruta completa según el estado de SSH
	if ssh_active:
		return ssh_user_base_path + normalized  # Ruta para el usuario remoto
	else:
		return BASE_PATH + normalized  # Ruta para el sistema local


func process_command(command: String):
	var output := ""
	history_text += command

	if command.begins_with("cd "):
		var target = command.substr(3).strip_edges()
		var new_path = current_path

		print("Comando recibido: cd " + target)

		if target == ".":
			print("Directorio actual, no se cambia nada.")
		elif target == "..":
			print("Subiendo un nivel en el directorio.")
			if current_path != "/":
				var parts = current_path.split("/")
				if parts.size() > 0:
					parts.remove_at(parts.size() - 1)
					new_path = "/" + "/".join(parts) if parts.size() > 0 else "/"
					print("Nuevo directorio después de subir: " + new_path)
				else:
					new_path = "/"
					print("Nuevo directorio: /")
		elif target == "/":
			print("Directorio raíz seleccionado.")
			new_path = "/"
		else:
			new_path = target if target.begins_with("/") else current_path.rstrip("/") + "/" + target
			print("Nuevo directorio absoluto o relativo: " + new_path)

		# 🔁 Usamos la base correcta según el modo (SSH o local)
		var base_path_actual = ssh_user_base_path if ssh_active else BASE_PATH

		var full_path = base_path_actual + Funciones.normalize_path(new_path)

		print("Ruta completa normalizada: " + full_path)

		if DirAccess.dir_exists_absolute(full_path):
			print("El directorio existe.")
			current_path = Funciones.normalize_path(new_path)
			print("Ruta actualizada a: " + current_path)

			# Misión 2 (opcional, solo si ya usabas esta lógica)
			if current_path == "/home/usuario/Documentos" and mision_actual == MISION_INICIAL_1_CD_1:
				mision_actual = MISION_INICIAL_2_LS_2
				start_dialog(Dialogos.mision_inicial_dialogs1)
		else:
			print("DEBUG: No existe el directorio: ", full_path)
			output = "No existe el directorio: " + target

	elif command == "sudo apt-get clean":
			var password = await Funciones.prompt_password("Introduce la contraseña de sudo:")
			if password == "1234":
				output = "[color=white]Leyendo lista de paquetes...\n[/color]"
				await get_tree().create_timer(0.8).timeout
				output += "[color=white]Limpiando caché de paquetes descargados...\n[/color]"
				await get_tree().create_timer(1.2).timeout

				var archives_path = "user://ubuntu_sim/var/cache/apt/archives"
				var partial_path = "user://ubuntu_sim/var/cache/apt/archives/partial"

				var count = Funciones.delete_files_in(archives_path)
				count += Funciones.delete_files_in(partial_path)

				if count == 0:
					output += "[color=yellow]No hay archivos en caché que limpiar.[/color]\n"
				else:
					output += "[color=green]Caché limpiada correctamente. Archivos eliminados: " + str(count) + "[/color]\n"
				
				if mision_actual == MISION_CLEAN_3_APT_CLEAN_16:
					mision_actual = MISION_CLEAN_4_APT_AUTOCLEAN_17
					start_dialog(Dialogos.ssh_clean_dialogs3)
			else:
				output = "[color=red]Contraseña incorrecta. No tienes permisos para ejecutar este comando.[/color]"

	elif command == "sudo apt-get autoclean":
			var password = await Funciones.prompt_password("Introduce la contraseña de sudo:")
			if password == "1234":
				output = "[color=white]Limpiando archivos de caché obsoletos...\n[/color]"
				await get_tree().create_timer(1.0).timeout
				var count_autoclean = Funciones.delete_files_in("user://ubuntu_sim/var/cache/apt/archives")
				output += "[color=green]Archivos obsoletos eliminados: " + str(count_autoclean) + "[/color]\n"
				
				if mision_actual == MISION_CLEAN_4_APT_AUTOCLEAN_17:
					mision_actual = MISION_CLEAN_5_AUTOREMOVE_18
					start_dialog(Dialogos.ssh_clean_dialogs4)
			else:
				output = "[color=red]Contraseña incorrecta. No tienes permisos para ejecutar este comando.[/color]"

	elif command == "sudo apt-get autoremove":
			var password = await Funciones.prompt_password("Introduce la contraseña de sudo:")
			if password == "1234":
				output = "[color=white]Eliminando paquetes no necesarios...\n[/color]"
				await get_tree().create_timer(1.0).timeout
				var count_autoremove = Funciones.delete_files_in("user://ubuntu_sim/var/lib/apt/lists")
				output += "[color=green]Paquetes no necesarios eliminados: " + str(count_autoremove) + "[/color]\n"
				
				if mision_actual == MISION_CLEAN_5_AUTOREMOVE_18:
					mision_actual = MISION_CLEAN_6_RM_TMP_19
					start_dialog(Dialogos.ssh_clean_dialogs5)
			else:
				output = "[color=red]Contraseña incorrecta. No tienes permisos para ejecutar este comando.[/color]"

	elif command == "date":
		var fecha_actual = Time.get_datetime_string_from_unix_time(Time.get_unix_time_from_system())
		output = "[color=white]" + fecha_actual + "[/color]"

	elif command == "pwd":
		output = "[color=white]" + current_path + "[/color]"

	elif command == "uptime":
		var tiempo_actual = Time.get_unix_time_from_system()
		var tiempo_transcurrido = tiempo_actual - start_time
		output = "[color=white]Uptime: " + str(tiempo_transcurrido) + " segundos[/color]"

	elif command == "cal":
		var fecha_actual = Time.get_datetime_dict_from_unix_time(Time.get_unix_time_from_system())
		output = "[color=white]Calendario " + str(fecha_actual["month"]) + "/" + str(fecha_actual["year"]) + "[/color]"

	elif command.begins_with("echo "):
		var mensaje = command.substr(5)
		output = "[color=white]" + mensaje + "[/color]"

	elif command.begins_with("diff "):
		var args = command.substr(5).strip_edges().split(" ")
		if args.size() != 2:
			output = "[color=red]Error: Debes especificar dos archivos para comparar.[/color]"
		else:
			var file1 = FileAccess.open(BASE_PATH + "/" + args[0], FileAccess.READ)
			var file2 = FileAccess.open(BASE_PATH + "/" + args[1], FileAccess.READ)
			
			if file1 == null or file2 == null:
				output = "[color=red]Error: Uno o ambos archivos no existen.[/color]"
			else:
				var lines1 = file1.get_as_text().split("\n")
				var lines2 = file2.get_as_text().split("\n")
				var diff_result = ""

				var max_lines = max(lines1.size(), lines2.size())
				for i in range(max_lines):
					var line1 = lines1[i] if i < lines1.size() else "[color=red]No existe en archivo 1[/color]"
					var line2 = lines2[i] if i < lines2.size() else "[color=red]No existe en archivo 2[/color]"
					if line1 != line2:
						diff_result += "[color=yellow]Línea " + str(i+1) + ":\n" + args[0] + ": " + line1 + "\n" + args[1] + ": " + line2 + "[/color]\n"
				
				output = diff_result if diff_result != "" else "[color=green]Los archivos son idénticos.[/color]"

	elif command.begins_with("grep "):
		var args = command.substr(5).strip_edges().split(" ")
		if args.size() < 2:
			output = "[color=red]Uso: grep [opciones] patrón archivo[/color]"
		else:
			var options = []
			var pattern = ""
			var filename = ""

			for arg in args:
				if arg.begins_with("-"):
					options.append(arg)
				elif pattern == "":
					pattern = arg
				else:
					filename = arg
			
			if filename == "":
				output = "[color=red]Error: Debes especificar un archivo.[/color]"
			else:
				var file = FileAccess.open(BASE_PATH + "/" + filename, FileAccess.READ)
				if file == null:
					output = "[color=red]Error: Archivo no encontrado.[/color]"
				else:
					var lines = file.get_as_text().split("\n")
					var matched_lines = []
					
					for line in lines:
						var search_line = line
						if "-i" in options:
							search_line = search_line.to_lower()
							pattern = pattern.to_lower()
						
						var match_found = search_line.find(pattern) != -1
						if "-v" in options:
							match_found = !match_found

						if match_found:
							matched_lines.append(line)
					
					if "-c" in options:
						output = "[color=yellow]Número de coincidencias: " + str(matched_lines.size()) + "[/color]"
					elif "-l" in options:
						output = "[color=green]" + filename + "[/color]"
					else:
						output = "\n".join(matched_lines) if matched_lines.size() > 0 else "[color=red]No se encontraron coincidencias.[/color]"

	elif command.begins_with("head "):
		var args = command.substr(5).strip_edges().split(" ")
		var num_lines = 10  # Por defecto, muestra 10 líneas
		var filename = ""

		for arg in args:
			if arg.begins_with("-"):
				num_lines = int(arg.substr(1))
			else:
				filename = arg
		
		if filename == "":
			output = "[color=red]Error: Debes especificar un archivo.[/color]"
		else:
			var file = FileAccess.open(BASE_PATH + "/" + filename, FileAccess.READ)
			if file == null:
				output = "[color=red]Error: Archivo no encontrado.[/color]"
			else:
				var lines = file.get_as_text().split("\n")
				output = "\n".join(lines.slice(0, num_lines))

	elif command.begins_with("tail "):
		var args = command.substr(5).strip_edges().split(" ")
		var num_lines = 10  # Por defecto, muestra 10 líneas
		var filename = ""

		for arg in args:
			if arg.begins_with("-"):
				num_lines = int(arg.substr(1))
			else:
				filename = arg
		
		if filename == "":
			output = "[color=red]Error: Debes especificar un archivo.[/color]"
		else:
			var file = FileAccess.open(BASE_PATH + "/" + filename, FileAccess.READ)
			if file == null:
				output = "[color=red]Error: Archivo no encontrado.[/color]"
			else:
				var lines = file.get_as_text().split("\n")
				output = "\n".join(lines.slice(-num_lines, lines.size()))

	#elif command == "history":
		#output = "[color=white]Historial de comandos:\n[/color]"
		#for i in range(command_history.size()):
			#output += "[color=yellow]" + str(i + 1) + "  " + command_history[i] + "[/color]\n"

	elif command.begins_with("df -h"):
		var args = command.split(" ")
		var path = current_path  # Valor por defecto

		#if args.size() >= 2:
			#path = args[2].strip_edges()

		# Mostrar salida ficticia realista
		output = "[color=white]%-16s %-8s %-8s %-8s %-6s %s\n[/color]" % ["Filesystem", "Size", "Used", "Avail", "Use%", "Mounted on"]

		# Si estamos en la misión SSH_LIMPIAR y conectados por SSH
		if ssh_active :
				#output += "[color=yellow]%-16s[/color] %-8s %-8s %-8s %-6s %s\n" % [
					#disk_mision_clean["filesystem"], disk_mision_clean["size"], disk_mision_clean["used"], disk_mision_clean["avail"], disk_mision_clean["use%"], disk_mision_clean["mounted"]
				#]
			if mision_actual < MISION_CLEAN_11_DF_OK_24:
				output += "[color=#ff4d4d]/dev/sda1       100G   98G  2.0G  98% /contabilidad[/color]"
			else:
				output += "[color=#33cc33]/dev/sda1       100G   70G  30G  70% /home/contabilidad[/color]"
				
			if mision_actual == MISION_CLEAN_2_DF_15:
				mision_actual = MISION_CLEAN_3_APT_CLEAN_16
				start_dialog(Dialogos.ssh_clean_dialogs2)
			elif mision_actual == MISION_CLEAN_11_DF_OK_24:
				mision_actual = MISION_CLEAN_12_EXIT_25
				start_dialog(Dialogos.ssh_clean_dialogs10)
		else:
			for disk in disk_usage:
				output += "[color=yellow]%-16s[/color] %-8s %-8s %-8s %-6s %s\n" % [
					disk["filesystem"], disk["size"], disk["used"], disk["avail"], disk["use%"], disk["mounted"]
				]

	elif command == "apt update":
		output = "[color=white]Obteniendo lista de paquetes...\n[/color]"
		await get_tree().create_timer(0.8).timeout
		output += "[color=white]Descargando información de repositorios...\n[/color]"
		await get_tree().create_timer(1.0).timeout
		output += "[color=white]Repositorio: http://mirrors.kernel.org/ubuntu focal-updates\n[/color]"
		await get_tree().create_timer(1.5).timeout
		output += "[color=white]Repositorio: http://security.ubuntu.com/ubuntu focal-security\n[/color]"
		await get_tree().create_timer(1.8).timeout
		output += "[color=green]Se han actualizado 15 paquetes, 5 paquetes tienen nuevas versiones disponibles.\n[/color]"
		await get_tree().create_timer(2.0).timeout
		output += "[color=white]Ejecuta 'apt upgrade' para actualizar los paquetes disponibles.[/color]"

	elif command == "apt upgrade":
		output = "[color=white]Leyendo lista de paquetes...\n[/color]"
		await get_tree().create_timer(0.8).timeout
		output += "[color=white]Calculando actualización...\n[/color]"
		await get_tree().create_timer(1.0).timeout
		output += "[color=white]Los siguientes paquetes serán actualizados:\n - libc6\n - bash\n - openssh-server\n - python3\n - vim\n[/color]"
		await get_tree().create_timer(1.5).timeout
		output += "[color=white]Descargando paquetes...\n[/color]"
		await get_tree().create_timer(1.8).timeout
		
		# Simulación de error ocasional en instalación
		var error_chance = randi() % 10
		if error_chance < 2:
			output += "[color=red]Error: No se pudo instalar bash. Dependencias rotas.[/color]\n"
			output += "[color=white]Intentando reparar dependencias...\n[/color]"
			await get_tree().create_timer(1.2).timeout
			output += "[color=green]Dependencias corregidas. Continuando instalación.[/color]\n"
		
		await get_tree().create_timer(1.5).timeout
		output += "[color=green]Instalación completada. Se han actualizado 5 paquetes.[/color]"

	elif command == "ls":
		var full_path = get_full_path()
		var dir = DirAccess.open(full_path)

		if dir:
			var dirs = dir.get_directories()
			var files = dir.get_files()

			for dir_name in dirs:
				output += "[color=#8dc9e8]" + dir_name + "[/color] "
			for file_name in files:
				output += "[color=white]" + file_name + "[/color] "

			# Misión SSH + Copia
			if ssh_active and current_path == "/contabilidad/Documentos":
				if mision_actual == MISION_SSH_3_LS_12:
					mision_actual = MISION_SSH_4_EXIT_13

			# Misión anterior: Apache → IPS_Departamentos.txt
			elif mision_actual == MISION_INICIAL_2_LS_2 and current_path == "/home/usuario/Documentos" and "IPS_Departamentos.txt" in files:
				mision_actual = MISION_INICIAL_3_CAT_3
				start_dialog(Dialogos.mision_inicial_dialogs2)
		else:
			output = "No se pudo abrir el directorio."

	elif command.begins_with("mkdir "):
		var target = command.substr(6).strip_edges()
		var path = get_full_path() + "/" + target
		if not DirAccess.dir_exists_absolute(path):
			var dir = DirAccess.open(get_full_path())
			if dir:
				dir.make_dir(target)
				output = "Directorio creado: " + target
		else:
			output = "El directorio ya existe."

	elif command.begins_with("touch "):
		var filename = command.substr(6).strip_edges()
		var file_path = get_full_path() + "/" + filename
		var file = FileAccess.open(file_path, FileAccess.WRITE)
		if file:
			output = "Archivo creado: " + filename
			file.close()
		else:
			output = "No se pudo crear el archivo."

	elif command.begins_with("nano "):
		var filename = command.substr(5).strip_edges()
		var file_path = get_full_path() + "/" + filename
		current_file_being_edited = file_path
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			editor.text = file.get_as_text()
			file.close()
		else:
			editor.text = ""
		nano_panel.visible = true
		history.release_focus()
		editor.grab_focus()
		output = "Editando " + filename + " (usa el botón para guardar y salir)"

	elif command.begins_with("rm "):
			var args = command.substr(3).strip_edges().split(" ")
			var recursive = "-r" in args or "-rf" in args or "--recursive" in args
			var target = args[-1]  # último argumento (soporta: rm -r carpeta)
			var limpiar_contenido_carpeta = false
			
			if target.ends_with("/*"):
				limpiar_contenido_carpeta = true
				target = target.trim_suffix("*")
			
			var full_path = get_full_path() + "/" + target
			
			var directorio = DirAccess.dir_exists_absolute(full_path)
			if directorio:
				if recursive:
					if not limpiar_contenido_carpeta:
						Funciones.remove_directory_recursive(full_path)
						output = "Directorio eliminado: " + target
					else:
						Funciones.remove_directory_contents(full_path)
						output = "Eliminado el contenido del directorio: " + target
					
						if mision_actual == MISION_CLEAN_6_RM_TMP_19 and target == "/tmp/":
							mision_actual = MISION_CLEAN_7_RM_VAR_20
							start_dialog(Dialogos.ssh_clean_dialogs6)
							
						elif mision_actual == MISION_CLEAN_7_RM_VAR_20 and target.ends_with("var/tmp/"):
							mision_actual = MISION_CLEAN_8_RM_DESCARGAS_21
							start_dialog(Dialogos.ssh_clean_dialogs7)
							
						elif mision_actual == MISION_CLEAN_8_RM_DESCARGAS_21 and target.ends_with("contabilidad/Descargas/"):
							mision_actual = MISION_CLEAN_9_RM_SHARE_FILES_22
							start_dialog(Dialogos.ssh_clean_dialogs8)
							
						elif mision_actual == MISION_CLEAN_9_RM_SHARE_FILES_22 and target.ends_with("contabilidad/.local/share/Trash/files/"):
							mision_actual = MISION_CLEAN_10_RM_SHARE_INFO_23
							start_dialog(Dialogos.ssh_clean_dialogs12)
							
						elif mision_actual == MISION_CLEAN_10_RM_SHARE_INFO_23 and target.ends_with("contabilidad/.local/share/Trash/info/"):
							mision_actual = MISION_CLEAN_11_DF_OK_24
							start_dialog(Dialogos.ssh_clean_dialogs9)
						
				else:
					output = "No se pudo eliminar el directorio (no existe): " + target
			elif FileAccess.file_exists(full_path):
				if recursive:
					output = "'" + target + "' es un archivo. Usa solo 'rm' para eliminarlo, sin -r."
				else:
					var parent_dir = DirAccess.open(get_full_path())
					if parent_dir:
						var err = parent_dir.remove(target)
						if err == OK:
							output = "Archivo eliminado: " + target
						else:
							output = "No se pudo eliminar el archivo '" + target + "'."
					else:
						output = "No se pudo acceder al directorio padre para eliminar '" + target + "'."
			else:
				output = "rm: no se puede eliminar '" + target + "': no existe tal archivo o directorio."
				
			#disk_mision_clean["used"] = str(used_gb) + "G"
			#disk_mision_clean["avail"] = str(avail_gb) + "G"
			#disk_mision_clean["use%"] = str(use_percent) + "%"

	elif command.begins_with("cat "):
		var filename = command.substr(4).strip_edges()
		var file_path = get_full_path() + "/" + filename

		if filename == "":
			output = "Error: Debes proporcionar el nombre de un archivo."
		elif FileAccess.file_exists(file_path):
			var file = FileAccess.open(file_path, FileAccess.READ)
			if file:
				output = file.get_as_text()
				file.close()

				if mision_actual == MISION_INICIAL_3_CAT_3 and filename == "IPS_Departamentos.txt":
					mision_actual = MISION_INICIAL_4_PING10_4
					start_dialog(Dialogos.mision_inicial_dialogs3)

				# Detectar lectura del archivo Para_Pam.txt durante la misión SSH
				elif mision_actual >= MISION_SSH_1_10 and mision_actual <= MISION_SSH_4_EXIT_13 and filename == "Para_Pam.txt":
					start_dialog(Dialogos.ssh_cp_dialogs4)
					print("DEBUG: Archivo 'Para_Pam.txt' leído. Saltando diálogo de cotilla.")
			else:
				output = "Error: No se pudo abrir el archivo."
		else:
			output = "Error: El archivo '" + filename + "' no existe."

	elif command.begins_with("ping "):
		ping_host = command.substr(5).strip_edges()
		if ping_host == "":
			output = "Error: Debes proporcionar una dirección IP o nombre de host."
		else:
			if Funciones.is_valid_ip(ping_host) or Funciones.resolve_hostname(ping_host):
				if mision_actual == 5 and ping_host == "192.168.10.1":
					_ping_erroneo()
				else:
					_ping_satisfactorio()
			else:
				output = "ping: " + ping_host + ": Temporary failure in name resolution"
		return

	elif command.begins_with("sudo systemctl "):
		var parts = command.split(" ")
		if parts.size() < 3:
			output = "Comando incompleto. Usa sudo systemctl status apache o sudo systemctl restart apache."
		else:
			var action = parts[2].strip_edges()
			var comando = parts[3].strip_edges()
			if action == "status":
				if comando == "apache":
					if mision_actual <= MISION_APACHE_2_RESTART_8:
						output = "[color=white]● apache2.service - The Apache HTTP Server\n Loaded: loaded (/usr/lib/systemd/system/apache2.service; enabled; preset: enabled)\n Active: [color=red]failed[/color] (Result: exit-code) since " + fecha_actual + " CEST; 8s ago\n Duration: 47min 35.229s\n Process: 786f618a04744458eb65217e5851d59fe ExecStart=/usr/sbin/apachectl start (code=[color=red]exited[/color], status=[color=red]1/FAILURE[/color])\n Docs: https://httpd.apache.org/docs/2.4/\n Main PID: 5825 (apache2)\n Status: \"\" active (running) since " + fecha_actual + " CEST; 8s ago\n Docs: man:apache2(8)\n Tasks: 1 (limit: 4915)\n Memory: 1.6M\n CPU: 13ms[/color]"
						if mision_actual == MISION_APACHE_1_STATUS_FALLIDO_7:
							mision_actual = MISION_APACHE_2_RESTART_8
							start_dialog(Dialogos.apache_dialogs1)
					else:
						output = "[color=white]● apache2.service - The Apache HTTP Server\n Loaded: loaded (/lib/systemd/system/apache2.service; [color=green]enabled[/color]; vendor preset: [color=green]enabled[/color])\n Active: [color=green]active (running)[/color] since " + fecha_actual + " CEST; 23s ago\n Docs: https://httpd.apache.org/docs/2.4/\n Main PID: 1234 (apache2)\n Tasks: 8 (limit: 4915)\n Memory: 10.5M\n CGroup: /system.slice/apache2.service\n ├─1234 /usr/sbin/apache2 -k start\n ├─1235 /usr/sbin/apache2 -k start\n └─1236 /usr/sbin/apache2 -k start[/color]"
						if mision_actual == MISION_APACHE_3_STATUS_OK_9:
							mision_actual = MISION_SSH_1_10
							start_dialog(Dialogos.apache_dialogs3)
			elif action == "restart":
				if comando == "apache":
					output = "Restarting Apache service..."
					if mision_actual == MISION_APACHE_2_RESTART_8:
						mision_actual = MISION_APACHE_3_STATUS_OK_9
						start_dialog(Dialogos.apache_dialogs2)
					#else:
						#output = "No se puede reiniciar Apache sin verificar su estado primero."
				else:
					output = "Comando incorrecto. Usa sudo systemctl status apache o sudo systemctl restart apache."

	elif command.begins_with("sudo "):
		if not sudo_authenticated:
			output = "Contraseña: "
			# Esperar a que el jugador ingrese la contraseña
			return

	elif command == "authenticate":
		var password_input = command.substr(10).strip_edges()  # Obtener la contraseña ingresada
		if password_input == sudo_password:
			sudo_authenticated = true
			output = "[color=green]Autenticación exitosa.[/color]"
		else:
			output = "[color=red]Contraseña incorrecta. Inténtalo de nuevo.[/color]"
		return

	elif command.begins_with("ssh "):
		var parts = command.split(" ")
		if parts.size() < 2:
			output = "Uso: ssh usuario@equipo"
			show_prompt()
			return

		var target = parts[1]
		if not target.contains("@"):
			output = "Error: Formato incorrecto. Usa 'usuario@equipo'."
			return

		var user = target.split("@")[0]
		var host = target.split("@")[1]

		# Validar IP o nombre de dominio
		if ssh_allowed_ips.has(host) or ssh_allowed_domains.has(host):
			output = "Conectando a " + host + " como " + user + "..."
			await get_tree().create_timer(2.0).timeout  # Simular tiempo de conexión
			output += "\n¡Bienvenido, " + user + "! Ahora estás conectado al servidor."

			match user:
				"contabilidad":
					ssh_user_base_path = BASE_PATH_CONTABILIDAD
				"ventas":
					ssh_user_base_path = BASE_PATH_VENTAS
				_:
					output = "Acceso denegado. Usuario no válido."
					return

			# Crear la carpeta del usuario remoto si no existe
			var user_sim_path = user + "_sim"
			var dir = DirAccess.open("user://")
			if dir:
				if not dir.dir_exists(user_sim_path):
					dir.make_dir(user_sim_path)
					dir.change_dir(user_sim_path)

					# Crear carpetas base
					for folder in ["boot", "dev", "lib", "lib32", "lib64", "media", "mnt", "opt", "proc", "root", "run", "sbin", "srv", "sys", "tmp", "usr", "var"]:
						dir.make_dir(folder)

					# Estructura del usuario
					dir.make_dir(user)
					dir.make_dir(user + "/Documentos")
					dir.make_dir(user + "/Descargas")
					dir.make_dir(user + "/Escritorio")
					dir.make_dir(user + "/Documentos/Privado")
					# Directorios adicionales según el estándar FHS
					dir.make_dir(user + "/.local")
					dir.make_dir(user + "/.local/share")
					dir.make_dir(user + "/.local/share/Trash")
					dir.make_dir(user + "/.local/share/Trash/files")
					dir.make_dir(user + "/.local/share/Trash/info")

					dir.make_dir("etc/apt")
					dir.make_dir("etc/apt/sources.list.d")
					dir.make_dir("etc/systemd")
					dir.make_dir("etc/systemd/system")
					dir.make_dir("etc/NetworkManager")
					dir.make_dir("etc/NetworkManager/system-connections")

					dir.make_dir("var/log")
					dir.make_dir("var/tmp")
					dir.make_dir("var/cache/apt/archives")
					dir.make_dir("var/lib/apt/lists")
					dir.make_dir("var/spool")
					dir.make_dir("var/spool/mail")
					dir.make_dir("var/run")

					dir.change_dir("..")  # Volver a user://
					print("✅ Estructura de carpetas creada para:", user_sim_path)

					# Crear archivo solo para contabilidad
					if user == "contabilidad":
						var para_pam_file_path = BASE_PATH_CONTABILIDAD + "/" + user + "/Documentos/Privado/Para_Pam.txt"
						print("DEBUG: Archivo creado en: ", para_pam_file_path)

						if FileAccess.file_exists(para_pam_file_path):
							print("ℹ️ El archivo 'Para_Pam.txt' ya existe.")
						else:
							var file = FileAccess.open(para_pam_file_path, FileAccess.WRITE)
							if file:
								var content = (
									"Querida Pam,\n\n" +
									"Sé que dentro de poco te casarás con nuestro jefe. Sé que estoy siendo egoísta, pero no puedo olvidar lo que pasó entre nosotros aquella noche; nunca lo podré olvidar.\n\n" +
									"Marchémonos juntos y dejemos atrás estas oficinas. No me importa adónde vayamos, solo que sea a tu lado. No puedo dejar de pensar en ti, y sé que tú también piensas en mí.\n\n" +
									"Espero tu respuesta.\n\n" +
									"# Fin del archivo"
								)
								file.store_string(content)
								file.flush()
								file.close()
								print("✅ Archivo 'Para_Pam.txt' creado con éxito.")
							else:
								print("❌ Error: No se pudo crear el archivo 'Para_Pam.txt'")
								output += "\n⚠️ Error interno al crear el archivo de Pam."

				else:
					print("ℹ️ La estructura de carpetas ya existe para:", user_sim_path)

				# Actualizar estado global
				ssh_active = true
				ssh_user = user
				ssh_host = host
				current_path = "/"  # Empezamos desde raíz del sistema remoto

				# Si venimos de Apache, iniciamos esta nueva misión
				if mision_actual == MISION_SSH_1_10:
					mision_actual = MISION_SSH_2_CP_11
					start_dialog(Dialogos.ssh_cp_dialogs1)
				elif mision_actual == MISION_CLEAN_1_SSH_14:
					mision_actual = MISION_CLEAN_2_DF_15
					start_dialog(Dialogos.ssh_clean_dialogs1)

			else:
				output = "Error accediendo al sistema de archivos."
		else:
			output = "Acceso denegado. IP o dominio no permitido."

	elif command == "exit":
		if ssh_active:
			output = "Connection to " + ssh_host + " closed."

			if mision_actual == MISION_SSH_3_LS_12:
				start_dialog(Dialogos.ssh_cp_dialogs2)
				show_prompt()
				return
				
			if mision_actual == MISION_SSH_4_EXIT_13:
				mision_actual = MISION_CLEAN_1_SSH_14
				start_dialog(Dialogos.ssh_cp_dialogs5)
			elif mision_actual == MISION_CLEAN_12_EXIT_25:
				#mision_actual = FIN
				start_dialog(Dialogos.ssh_clean_dialogs11)
				

			# Limpiar estado SSH
			ssh_active = false
			ssh_user = ""
			ssh_host = ""
			ssh_user_base_path = ""
			current_path = "/"  # Volver al sistema local

			show_prompt()
		else:
			output = "Not connected to an SSH session."
		return

	elif command.begins_with("cp "):
		var args = command.substr(3).strip_edges().split(" ")
		var recursive = false

		# Detectar si se usó la opción -r
		if args.size() > 0 and args[0] == "-r":
			recursive = true
			args.remove_at(0)

		if args.size() < 2:
			output = "Uso: cp [-r] <origen> <destino>"
			return

		var source = args[0]
		var destination = args[1]
		var source_path = get_full_path() + "/" + source
		var dest_path = get_full_path() + "/" + destination

		var dir = DirAccess.open(get_full_path())
		if not dir:
			output = "No se pudo acceder al directorio actual"
			return

		if dir.dir_exists(source):
			if not recursive:
				output = "cp: omitiendo directorio '" + source + "'. Usa -r para copiar recursivamente."
			else:
				Funciones.copy_directory(source_path, dest_path, get_full_path())
				output = "Directorio copiado de " + source + " a " + destination

				# Misión SSH: Detectar si es la carpeta Privado
				if mision_actual == MISION_SSH_2_CP_11 and source == "Privado" and destination == "Privado.old":
					mision_actual = MISION_SSH_3_LS_12
					start_dialog(Dialogos.ssh_cp_dialogs3)
					print("DEBUG: Carpeta 'Privado' copiada como 'Privado.old'")
		
		elif FileAccess.file_exists(source_path):
			var source_file = FileAccess.open(source_path, FileAccess.READ)
			var content = source_file.get_as_text()
			source_file.close()

			var dest_file = FileAccess.open(dest_path, FileAccess.WRITE)
			if dest_file:
				dest_file.store_string(content)
				dest_file.close()
				output = "Archivo copiado de " + source + " a " + destination
			else:
				output = "cp: no se pudo escribir en el archivo de destino"
		else:
			output = "cp: archivo o directorio no encontrado: " + source

	elif command == "clear":
		history_text = ""
		show_prompt()
		return

	elif command.begins_with("help "):
		var cmd = command.substr(5).strip_edges()
		match cmd:
			"cd":
				output = "[color=green]Uso:[/color] cd [ruta]\n"
				output += "[color=green]Descripción:[/color] Cambia al directorio especificado.\n"
				output += "[color=green]Ejemplos:[/color]\n"
				output += "  - [color=cyan]cd /home/usuario[/color]: Navegar al directorio personal\n"
				output += "  - [color=cyan]cd ..[/color]: Subir un nivel en la jerarquía\n"
				output += "  - [color=cyan]cd /[/color]: Acceder al directorio raíz\n"
				output += "[color=green]Notas:[/color] Soporta rutas absolutas (ej: /etc) y relativas (ej: Documentos)."
			"ls":
				output = "[color=green]Uso:[/color] ls\n"
				output += "[color=green]Descripción:[/color] Lista los archivos y directorios en la ubicación actual.\n"
				output += "[color=green]Ejemplo:[/color] [color=cyan]ls[/color]\n"
				output += "[color=green]Notas:[/color] Muestra directorios en azul y archivos en blanco."
			"mkdir":
				output = "[color=green]Uso:[/color] mkdir [nombre]\n"
				output += "[color=green]Descripción:[/color] Crea un nuevo directorio.\n"
				output += "[color=green]Ejemplo:[/color] [color=cyan]mkdir nueva_carpeta[/color]"
			"touch":
				output = "[color=green]Uso:[/color] touch [archivo]\n"
				output += "[color=green]Descripción:[/color] Crea un archivo vacío.\n"
				output += "[color=green]Ejemplo:[/color] [color=cyan]touch archivo.txt[/color]"
			"rm":
				output = "[color=green]Uso:[/color] rm [-r] [archivo/directorio]\n"
				output += "[color=green]Descripción:[/color] Elimina archivos o directorios (con -r).\n"
				output += "[color=green]Ejemplo:[/color] [color=cyan]rm -r carpeta[/color]: Elimina recursivamente una carpeta."
			"cat":
				output = "[color=green]Uso:[/color] cat [archivo]\n"
				output += "[color=green]Descripción:[/color] Muestra el contenido de un archivo.\n"
				output += "[color=green]Ejemplo:[/color] [color=cyan]cat archivo.txt[/color]"
			"clear":
				output = "[color=green]Uso:[/color] clear\n"
				output += "[color=green]Descripción:[/color] Limpia la pantalla de la terminal."
			"ping":
				output = "[color=green]Uso:[/color] ping [host]\n"
				output += "[color=green]Descripción:[/color] Verifica conectividad con otro dispositivo.\n"
				output += "[color=green]Ejemplo:[/color] [color=cyan]ping google.com[/color]"
			"ssh":
				output = "[color=green]Uso:[/color] ssh [usuario@host]\n"
				output += "[color=green]Descripción:[/color] Conecta a un servidor remoto via SSH.\n"
				output += "[color=green]Ejemplo:[/color] [color=cyan]ssh usuario@192.168.10.1[/color]"
			"exit":
				output = "[color=green]Uso:[/color] exit\n"
				output += "[color=green]Descripción:[/color] Sale de una sesión SSH."
			"apt update":
				output = "[color=green]Uso:[/color] apt update\n"
				output += "[color=green]Descripción:[/color] Actualiza la lista de paquetes disponibles."
			"apt upgrade":
				output = "[color=green]Uso:[/color] apt upgrade\n"
				output += "[color=green]Descripción:[/color] Actualiza los paquetes instalados."
			"sudo apt-get clean":
				output = "[color=green]Uso:[/color] sudo apt-get clean\n"
				output += "[color=green]Descripción:[/color] Limpia la caché de paquetes descargados."
			"sudo apt-get autoclean":
				output = "[color=green]Uso:[/color] sudo apt-get autoclean\n"
				output += "[color=green]Descripción:[/color] Limpia caché obsoleta."
			"sudo apt-get autoremove":
				output = "[color=green]Uso:[/color] sudo apt-get autoremove\n"
				output += "[color=green]Descripción:[/color] Elimina paquetes no necesarios."
			"sudo systemctl status apache":
				output = "[color=green]Uso:[/color] sudo systemctl status apache\n"
				output += "[color=green]Descripción:[/color] Muestra el estado del servidor Apache."
			"sudo systemctl restart apache":
				output = "[color=green]Uso:[/color] sudo systemctl restart apache\n"
				output += "[color=green]Descripción:[/color] Reinicia el servidor Apache."
			"date":
				output = "[color=green]Uso:[/color] date\n"
				output += "[color=green]Descripción:[/color] Muestra la fecha y hora actual."
			"uptime":
				output = "[color=green]Uso:[/color] uptime\n"
				output += "[color=green]Descripción:[/color] Muestra el tiempo de ejecución del sistema."
			"cal":
				output = "[color=green]Uso:[/color] cal\n"
				output += "[color=green]Descripción:[/color] Muestra el calendario del mes actual."
			"df -h":
				output = "[color=green]Uso:[/color] df -h\n"
				output += "[color=green]Descripción:[/color] Muestra el espacio en disco de forma legible."
			"nano":
				output = "[color=green]Uso:[/color] nano [archivo]\n"
				output += "[color=green]Descripción:[/color] Edita un archivo de texto."
			"echo":
				output = "[color=green]Uso:[/color] echo [texto]\n"
				output += "[color=green]Descripción:[/color] Imprime texto en la terminal."
			"cp":
				output = "[color=green]Uso:[/color] cp [-r] [origen] [destino]\n"
				output += "[color=green]Descripción:[/color] Copia archivos o directorios (con -r).\n"
				output += "[color=green]Ejemplo:[/color] [color=cyan]cp archivo.txt copia.txt[/color]"
			"diff":
				output = "[color=green]Uso:[/color] diff [archivo1] [archivo2]\n"
				output += "[color=green]Descripción:[/color] Compara dos archivos línea por línea."
			"head":
				output = "[color=green]Uso:[/color] head [-n] [archivo]\n"
				output += "[color=green]Descripción:[/color] Muestra las primeras líneas de un archivo.\n"
				output += "[color=green]Ejemplo:[/color] [color=cyan]head -5 archivo.txt[/color]"
			"tail":
				output = "[color=green]Uso:[/color] tail [-n] [archivo]\n"
				output += "[color=green]Descripción:[/color] Muestra las últimas líneas de un archivo.\n"
				output += "[color=green]Ejemplo:[/color] [color=cyan]tail -10 archivo.txt[/color]"
			_:
				output = "[color=red]Comando desconocido: $cmd. Usa 'help' para ver comandos disponibles.[/color]"
	elif command == "help":
		output = "[color=green]Navegación y gestión de archivos:[/color]\n"
		output += "  - [color=yellow]cd[/color] [ruta]: Cambiar directorio actual\n"
		output += "  - [color=yellow]ls[/color]: Listar contenido del directorio\n"
		output += "  - [color=yellow]pwd[/color]: Mostrar ruta del directorio actual\n"
		output += "  - [color=yellow]mkdir[/color] [nombre]: Crear un directorio\n"
		output += "  - [color=yellow]touch[/color] [archivo]: Crear un archivo vacío\n"
		output += "  - [color=yellow]rm[/color] [-r] [archivo/directorio]: Eliminar archivos o directorios\n"
		output += "  - [color=yellow]cp[/color] [-r] [origen] [destino]: Copiar archivos o directorios\n"
		output += "  - [color=yellow]clear[/color]: Limpiar la pantalla\n\n"

		output += "[color=green]Edición de texto y visualización:[/color]\n"
		output += "  - [color=yellow]nano[/color] [archivo]: Editar un archivo\n"
		output += "  - [color=yellow]cat[/color] [archivo]: Mostrar contenido de un archivo\n"
		output += "  - [color=yellow]echo[/color] [texto]: Imprimir texto en pantalla\n"
		output += "  - [color=yellow]head[/color] [-n] [archivo]: Mostrar primeras líneas de un archivo\n"
		output += "  - [color=yellow]tail[/color] [-n] [archivo]: Mostrar últimas líneas de un archivo\n"
		output += "  - [color=yellow]diff[/color] [archivo1] [archivo2]: Comparar dos archivos\n\n"

		output += "[color=green]Redes y diagnóstico:[/color]\n"
		output += "  - [color=yellow]ping[/color] [host]: Verificar conectividad\n"
		output += "  - [color=yellow]ssh[/color] [usuario@host]: Conectar a un servidor remoto\n"
		output += "  - [color=yellow]exit[/color]: Salir de una sesión SSH\n\n"

		output += "[color=green]Gestión de paquetes y sistema:[/color]\n"
		output += "  - [color=yellow]apt update[/color]: Actualizar lista de paquetes\n"
		output += "  - [color=yellow]apt upgrade[/color]: Actualizar paquetes\n"
		output += "  - [color=yellow]sudo apt-get clean[/color]: Limpiar caché de paquetes descargados\n"
		output += "  - [color=yellow]sudo apt-get autoclean[/color]: Limpiar caché obsoleta\n"
		output += "  - [color=yellow]sudo apt-get autoremove[/color]: Eliminar paquetes no necesarios\n"
		output += "  - [color=yellow]sudo systemctl status apache[/color]: Ver estado de Apache\n"
		output += "  - [color=yellow]sudo systemctl restart apache[/color]: Reiniciar Apache\n\n"

		output += "[color=green]Información del sistema:[/color]\n"
		output += "  - [color=yellow]date[/color]: Mostrar fecha y hora\n"
		output += "  - [color=yellow]uptime[/color]: Mostrar tiempo de ejecución\n"
		output += "  - [color=yellow]cal[/color]: Mostrar calendario\n"
		output += "  - [color=yellow]df -h[/color]: Ver espacio en disco\n\n"

		output += "[color=blue]Consejo de misión:[/color] Usa [color=yellow]ls[/color] para encontrar archivos clave en /home/usuario/Documentos"

	elif command == "":
		pass

	else:
		if mision_actual == MISION_INICIAL_2_LS_2:
			output = "Ese comando no es correcto. Prueba con ls."
		else:
			output = "{command}: Comando no encontrado.".format({"command": command.split(" ")[0]})

	if output != "":
		history_text += "\n" + output
		history.text = history_text
	show_prompt()

func _ping_satisfactorio():
	ping_active = true
	ping_seq = 1
	rtt_times.clear()
	ping_timer = Timer.new()
	ping_timer.wait_time = 1.0
	ping_timer.one_shot = false
	add_child(ping_timer)
	ping_timer.timeout.connect(_on_ping_timer_timeout)
	ping_timer.start()
	history_text += "\nPING " + ping_host + " (" + ping_host + ") 56(84) bytes of data.\n"
	history.text = history_text
	
func _on_ping_timer_timeout():
	if not ping_active:
		return

	var time = randf_range(0.020, 0.030)  # Simulación de tiempo de respuesta
	rtt_times.append(time)
	history_text += "64 bytes from " + ping_host + ": icmp_seq=" + str(ping_seq) + " ttl=64 time=%.3f ms\n" % time
	history.text = history_text
	ping_seq += 1
	
func _ping_erroneo():
	ping_active = true
	ping_seq = 1
	rtt_times.clear()
	ping_timer = Timer.new()
	ping_timer.wait_time = 1.0
	ping_timer.one_shot = false
	add_child(ping_timer)
	ping_timer.timeout.connect(_on_ping_timer_timeout_error)
	ping_timer.start()
	history_text += "\nPING " + ping_host + " (" + ping_host + ") 56(84) bytes of data.\n"
	history.text = history_text
	
func _on_ping_timer_timeout_error():
	if not ping_active:
		return

	history_text += "Request timeout for icmp_seq=" + str(ping_seq) + "\n"
	ping_seq += 1
	history.text = history_text

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
	dialog_box.start_dialog(dialogs)
	dialog_box.visible = true


func autocomplete_command():
	var parts = current_command.strip_edges().split(" ")
	var last_part = parts[-1]

	# Dividir last_part en ruta base y fragmento incompleto
	var last_slash = last_part.rfind("/")
	var base_path = ""
	var incomplete = ""
	if last_slash != -1:
		base_path = last_part.substr(0, last_slash)  # ejemplo: /home
		incomplete = last_part.substr(last_slash + 1)  # ejemplo: us
	else:
		base_path = "."  # directorio actual
		incomplete = last_part

	# Construir la ruta absoluta desde current_path
	var full_path = ""
	if base_path.begins_with("/"):
		full_path = BASE_PATH + Funciones.normalize_path(base_path)  # ruta absoluta interna del juego
	else:
		full_path = get_full_path() + "/" + base_path  # relativa al directorio actual

	var dir = DirAccess.open(full_path)
	if not dir:
		return

	var dirs = dir.get_directories()
	var files = dir.get_files()

	# Distinguir el tipo de comando
	var command_type = parts[0] if parts.size() > 0 else ""
	var all_items = []

	if command_type == "cd" or command_type == "mkdir":
		all_items = dirs  # solo directorios
	elif command_type == "touch" or command_type == "nano" or command_type == "head" or command_type == "tail" or command_type == "cat" :
		all_items = files  # solo archivos
	else:
		all_items = dirs + files  # ambos

	var matches = []
	for item in all_items:
		if item.begins_with(incomplete):
			if dirs.has(item):
				matches.append(item + "/")
			else:
				matches.append(item)

	if matches.size() == 1:
		var completed = matches[0]
		var new_last_part = base_path + "/" + completed if base_path != "." else completed
		current_command = " ".join(parts.slice(0, -1)) + " " + new_last_part

		cursor_pos = current_command.length()
		history.text = history_text + current_command
		update_command_display()
	elif matches.size() > 1:
		var suggestions = "\n" + "  ".join(matches) + "\n"
		history_text += suggestions  # guarda las sugerencias

		# Añadir línea nueva del prompt limpio
		history_text += USER_COLOR + ":" + "[color=skyblue]" + current_path + "[/color]" + PROMPT_BASE
