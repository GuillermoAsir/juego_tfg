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

# Variables principales
var current_command = ""
var current_path = "/"  # Ruta relativa dentro de ubuntu_sim
const BASE_PATH = "user://ubuntu_sim"  # Ruta real base
const BASE_PATH_CONTABILIDAD = "user://contabilidad_sim"  # Ruta base para el usuario contabilidad
const BASE_PATH_VENTAS = "user://ventas_sim"  # Ruta base para el usuario ventas (futuro)
var ssh_user_base_path = ""  # Ruta base para el usuario remoto (por ejemplo, "user://contabilidad")
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

# Variables para el sistema de diálogo
var dialog_active = false
var current_dialog_index = 0

#Fichero mensaje para pam
var para_pam_file_path = BASE_PATH_CONTABILIDAD + "/home/contabilidad/Documentos/Privado/Para_Pam.txt"

# Variables para controlar lo que se ha introducido por consola
var comandos_introducidos: Array[String] = []
var comando_actual = null

# Variables para controlar el flujo de la misión Apache
var apache_estado_verificado = false  # Indica si el jugador ha verificado el estado de Apache
var apache_reiniciado = false        # Indica si el jugador ha reiniciado Apache
var apache_mision_completada = false # Indica si la misión Apache está completada

#Variables ssh
# Variables principales
var ssh_active = false  # Indica si el jugador está conectado por SSH
var ssh_host = ""       # Guarda el nombre del host al que está conectado
var ssh_user = ""       # Guarda el nombre de usuario
var entorno_actual = "local"  # Puede ser "local" o "remoto"

#Lista de IPs permitidas
var ssh_allowed_ips = ["192.168.10.100", "192.168.10.101", "192.168.10.102"]

#Lista de nombres de dominio permitidos
var ssh_allowed_domains = {
	"servidor.contabilidad.local": "192.168.1.100",
	"router.local": "192.168.1.1",
	"backup.servidor.local": "192.168.1.101"
}

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
var mission2_dialogs6 = [
	"¡Por todos los nodos! Al router le pasa algo,\n" +
	"Ahora mismo les mando un mensaje para que utilicen la técnica ancestral de todo buen informático...\n" +
	"Reiniciar el router"
]

var mission2_dialogs7 = [
	"Enhorabuena por este gran éxito, ¡aquí te dejo tu pin!",
	"Saludos soy Pam me han llegado muchos email donde dicen nuestros clientes que nuestra web no funciona."
]
# Diálogos de la misión Apache
var apache_dialogs1 = [
	"Saludos soy Pam me han llegado muchos email donde dicen nuestros clientes que nuestra web no funciona."
]
var apache_dialogs2 = [
	"OMG! Repampanos y retuecanos ¡¿es que nadie hará nada?! Ah bueno nosotros.\n" +
	"Informáticos al rescate. Nuestra Web esta desde el servicio apache el indio apache noo!\n" +
	"Apache es el servicio web. Hoy vas a mirar el estado del servicio y si esta mal lo vas a resetear.\n" +
	"Empecemos mirando el estado solo tienes que escribir `sudo systemctl status apache`."
]
var apache_dialogs3 = [
	"Vaya tenemos un error en rojo los peores de todos! Vamos a resetear el servicio Apache ahora escribe `sudo systemctl restart apache`."
]
var apache_dialogs4 = [
	"Ahora puede volver a mirar el estado del servicio."
]
var apache_dialogs5 = [
	"Muy bien luego me acercare hablar con Pam para decirle que lo hemos solucionado. Misión terminada consultar apache."
]
# Variables para controlar el flujo de la misión
var esperando_ls = false  # Esperando que el jugador use `ls`
var archivo_listado = false  # Indica si el jugador ha listado los archivos
var archivo_leido = false  # Indica si el jugador ha usado `cat` en el archivo
var ping_completado = false  # Indica si el jugador ha completado el primer ping
var ping_error = false # Indica si el jugador no puso el ping correcto.

#Variables para saber en que misión está
var mision_actual = 6

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
	init_structure()
	show_prompt()
	save_button.pressed.connect(_on_save_button_pressed)
	
	# Crear archivo de misión si no existe
	var ips_file_path = BASE_PATH + "/home/usuario1/Documentos/IPS_El_Bohío.txt"
	if not FileAccess.file_exists(ips_file_path):
		var ips_file = FileAccess.open(ips_file_path, FileAccess.WRITE)
		if ips_file:
			ips_file.store_string("""# IPs asignadas al Departamento de Ventas - El Bohío

192.168.10.10   pc_ventas_1
192.168.10.11   pc_ventas_2
192.168.10.12   impresora_oficina
192.168.10.254  router_sede

# Fin del archivo""")
		ips_file.close()
	print("✅ Archivo IPS_El_Bohío.txt creado")
		
	# Inicializar la nueva misión Apache
#func inicializar_mision_apache():
	#if mision_actual == 7:  # Nueva misión Apache
		#start_dialog(apache_dialogs1)  # Mostrar diálogo inicial de Pam
		#mision_actual = 8
	#
	#if apache_estado_verificado and apache_reiniciado:
		#apache_mision_completada = true
		#start_dialog(apache_dialogs5)  # Mostrar mensaje final
		#mision_actual += 1  # Avanzar a la siguiente misión
# Actualiza el prompt para no perder la visualización

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

func init_structure():
	var dir = DirAccess.open("user://")
	if dir:
		# Crear la carpeta del usuario contabilidad si no existe
		#if not dir.dir_exists("contabilidad_sim"):
			#dir.make_dir("contabilidad_sim")
			#dir.change_dir("contabilidad_sim")
			#for folder in ["home1", "etc1", "var1", "secret1", "bin1"]:
				#dir.make_dir(folder)
			#dir.make_dir("home/contabilidad")  # Carpeta personal del usuario contabilidad
			#dir.make_dir("home/contabilidad/Documentos")
			#dir.make_dir("home/contabilidad/Descargas")
			#dir.make_dir("home/contabilidad/Escritorio")
			#dir.change_dir("..")  # Volver al directorio raí

	# Aquí puedes agregar más usuarios en el futuro (por ejemplo, ventas_sim)
		# if not dir.dir_exists("ventas_sim"):
		#     dir.make_dir("ventas_sim")
		#     dir.change_dir("ventas_sim")
		#     for folder in ["home", "etc", "var", "secret", "bin"]:
		#         dir.make_dir(folder)
		#     dir.make_dir("home/ventas")  # Carpeta personal del usuario ventas
		#     dir.make_dir("home/ventas/Documents")
		#     dir.make_dir("home/ventas/Downloads")
		#     dir.make_dir("home/ventas/Desktop")
		#     dir.change_dir("..")  # Volver al directorio raíz

		## Crear carpetas raíz
		#for folder in ["home2", "etc2", "var2", "secret2", "bin2", "usr2"]:
			#if not dir.dir_exists(folder):
				#dir.make_dir(folder)

		# HOME
		if not dir.dir_exists("home/usuario1"):
			dir.make_dir("home/usuario1")
		for subfolder in ["Documentos", "Descargas", "Escritorio", "Imágenes", "Música", "Vídeos"]:
			if not dir.dir_exists("home/usuario1/" + subfolder):
				dir.make_dir("home/usuario1/" + subfolder)

		# ETC
		for etc_dir in ["passwd", "group", "shadow", "fstab", "hostname", "bash.bashrc", "crontab"]:
			if not dir.dir_exists("etc/" + etc_dir):
				dir.make_dir("etc/" + etc_dir)
		if not dir.dir_exists("etc/Network"):
			dir.make_dir("etc/Network")
		if not dir.dir_exists("etc/Network/interfaces"):
			dir.make_dir("etc/Network/interfaces")
		if not dir.dir_exists("etc/systemd"):
			dir.make_dir("etc/systemd")
		if not dir.dir_exists("etc/systemd/system"):
			dir.make_dir("etc/systemd/system")
		if not dir.dir_exists("etc/apt"):
			dir.make_dir("etc/apt")
		if not dir.dir_exists("etc/apt/sources.list"):
			dir.make_dir("etc/apt/sources.list")

		# USR
		for usr_sub in ["bin", "sbin", "share", "lib", "local", "src", "games"]:
			if not dir.dir_exists("usr/" + usr_sub):
				dir.make_dir("usr/" + usr_sub)

		# VAR
		for var_sub in ["log", "tmp", "lib", "spool", "cache", "mail", "run"]:
			if not dir.dir_exists("var/" + var_sub):
				dir.make_dir("var/" + var_sub)

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
			return

		# Procesar comandos normales
		if event.keycode == KEY_ENTER:
			if dialog_active:
				advance_dialog()
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


func normalize_path(path: String) -> String:
	var parts = []
	for p in path.split("/"):
		if p != "":
			parts.append(p)
	return "/" + "/".join(parts)

func process_command(command: String):
	var output := ""
	history_text += command

	if command.begins_with("cd "):
		var target = command.substr(3).strip_edges()
		var new_path = current_path

		if target == ".":
			pass
		elif target == "..":
			if current_path != "/":
				var parts = current_path.split("/")
				if parts.size() > 0:
					parts.remove_at(parts.size() - 1)
					new_path = "/" + "/".join(parts) if parts.size() > 0 else "/"
				else:
					new_path = "/"
		elif target == "/":
			new_path = "/"
		else:
			new_path = target if target.begins_with("/") else current_path.rstrip("/") + "/" + target

		var full_path = BASE_PATH + normalize_path(new_path)
		if DirAccess.dir_exists_absolute(full_path):
			current_path = normalize_path(new_path)
			if current_path == "/home/usuario1/Documentos" and not archivo_listado:
				esperando_ls = true
				if mision_actual == 1:
					start_dialog(mission2_dialogs)
					mision_actual = 2
		else:
			output = "No existe el directorio: " + target

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

			# Verificar si el jugador ha listado el archivo correcto
			if current_path == "/home/usuario1/Documents" and esperando_ls and not archivo_listado:
				if "IPS_El_Bohío.txt" in files:
					archivo_listado = true
					esperando_ls = false
					if mision_actual == 2:
						start_dialog(mission2_dialogs2)
						mision_actual = 3
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
		var target = args[0]
		var recursive = "-r" in args or "--recursive" in args
		var full_path = get_full_path() + "/" + target
		if DirAccess.dir_exists_absolute(full_path):
			if recursive:
				var dir = DirAccess.open(full_path)
				if dir:
					dir.remove(full_path)
					output = "Directorio eliminado: " + target
				else:
					output = "No se pudo eliminar el directorio: " + target
			else:
				output = "rm: no se puede eliminar '" + target + "': Es un directorio. Usa -r para eliminar recursivamente."
		elif FileAccess.file_exists(full_path):
			var file = FileAccess.open(full_path, FileAccess.READ)
			if file:
				file.close()
				DirAccess.remove_absolute(full_path)
				output = "Archivo eliminado: " + target
			else:
				output = "No se pudo eliminar el archivo: " + target
		else:
			output = "rm: no se puede eliminar '" + target + "': No existe tal archivo o directorio"

	elif command.begins_with("cat "):
		var filename = command.substr(4).strip_edges()
		if filename == "":
			output = "Error: Debes proporcionar el nombre de un archivo."
		else:
			var file_path = get_full_path() + "/" + filename
			if FileAccess.file_exists(file_path):
				var file = FileAccess.open(file_path, FileAccess.READ)
				if file:
					output = file.get_as_text()
					file.close()
					if archivo_listado and filename == "IPS_El_Bohío.txt" and not archivo_leido:
						archivo_leido = true
						if mision_actual == 3:
							start_dialog(mission2_dialogs3)
							mision_actual = 4
				else:
					output = "Error: No se pudo abrir el archivo."
			else:
				output = "Error: El archivo '" + filename + "' no existe."

	elif command.begins_with("ping "):
		var target = command.substr(5).strip_edges()
		if target == "":
			output = "Error: Debes proporcionar una dirección IP o nombre de host."
		else:
			ping_host = target
			if is_valid_ip(target) or resolve_hostname(target):
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
				show_prompt()

				if mision_actual == 4 and target == "192.168.10.10":
					start_dialog(mission2_dialogs4)
					mision_actual = 5
				elif mision_actual == 4:
					start_dialog(mission2_dialogs5)
				elif mision_actual == 5 and target == "192.168.10.1":
					start_dialog(mission2_dialogs6)
					mision_actual = 6
				elif mision_actual == 6 and target == "192.168.10.1":
					start_dialog(mission2_dialogs7)
					mision_actual = 7
					advance_dialog()
			else:
				output = "ping: " + target + ": Temporary failure in name resolution"

	elif command.begins_with("sudo systemctl"):
		if mision_actual < 8:
			output = "No tienes acceso a este comando todavía."
		else:
			var parts = command.split(" ")
			if parts.size() < 3:
				output = "Comando incompleto. Usa sudo systemctl status apache o sudo systemctl restart apache."
			else:
				var action = parts[2].strip_edges()
				if action == "status":
					if "apache" in command:
						if not apache_estado_verificado:
							apache_estado_verificado = true
							if mision_actual == 8:
								output = "[color=red]● apache.service - Apache HTTP Server\n   Loaded: loaded (/lib/systemd/system/apache.service; enabled; vendor preset: enabled)\n   Active: failed (Result: exit-code) since Mon 2023-10-01 12:00:00 UTC; 1h ago[/color]"
								start_dialog(apache_dialogs3)
						else:
							output = "El servicio Apache ya fue verificado previamente."
				elif action == "restart":
					if "apache" in command:
						if apache_estado_verificado and not apache_reiniciado:
							apache_reiniciado = true
							output = "Restarting Apache service..."
							start_dialog(apache_dialogs4)
						else:
							output = "No se puede reiniciar Apache sin verificar su estado primero."
				else:
					output = "Comando incorrecto. Usa sudo systemctl status apache o sudo systemctl restart apache."

				if apache_estado_verificado and apache_reiniciado:
					apache_mision_completada = true
					start_dialog(apache_dialogs5)
					mision_actual += 1

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

			# Asignar la ruta base según el usuario
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
					for folder in ["home", "etc", "var", "bin"]:
						dir.make_dir(folder)
					dir.make_dir("home/" + user)
					dir.make_dir("home/" + user + "/Documentos")
					dir.make_dir("home/" + user + "/Descargas")
					dir.make_dir("home/" + user + "/Escritorio")
					dir.make_dir("home/" + user + "/Documentos/Privado")
					dir.change_dir("..")

					print("✅ Estructura de carpetas creada para:", user_sim_path)

					# Crear archivo específico solo para contabilidad
					if user == "contabilidad":
						var para_pam_file_path = BASE_PATH_CONTABILIDAD + "/home/" + user + "/Documentos/Privado/Para_Pam.txt"
						if not FileAccess.file_exists(para_pam_file_path):
							var file = FileAccess.open(para_pam_file_path, FileAccess.WRITE)
							if file:
								file.store_string(
									"Querida Pam,\n\n" +
									"Sé que dentro de poco te casarás con nuestro jefe. Sé que estoy siendo egoísta, pero no puedo olvidar lo que pasó entre nosotros aquella noche; nunca lo podré olvidar.\n\n" +
									"Marchémonos juntos y dejemos atrás estas oficinas. No me importa adónde vayamos, solo que sea a tu lado. No puedo dejar de pensar en ti, y sé que tú también piensas en mí.\n\n" +
									"Espero tu respuesta.\n\n" +
									"# Fin del archivo"
								)
								file.close()
								print("✅ Archivo 'Para_Pam.txt' creado")
				else:
					print("ℹ️ La estructura de carpetas ya existe para:", user_sim_path)

				# Actualizar estado global
				ssh_active = true
				ssh_user = user
				ssh_host = host
				current_path = "/home/" + user
			else:
				output = "Error accediendo al sistema de archivos."
		else:
			output = "Acceso denegado. IP o dominio no permitido."

#Para salir del SSH
	elif command == "exit":
		if ssh_active:
			output = "Connection to " + ssh_host + " closed."
			ssh_active = false  # Desactivar el estado SSH
			ssh_host = ""       # Limpiar el host
			ssh_user = ""       # Limpiar el usuario
			ssh_user_base_path = ""  # Limpiar la ruta base del usuario remoto
			current_path = "/"   # Volver al sistema local
			show_prompt()
		else:
			output = "Not connected to an SSH session. Use this command only to disconnect remote sessions."

	elif command.begins_with("cp "):
			var args = command.substr(3).strip_edges().split(" ")
			var recursive = false

			# Detectar si se usó la opción -r
			if args[0] == "-r":
				recursive = true
				args.remove_at(0)

			if args.size() < 2:
				output = "Uso: cp [-r] <origen> <destino>"
			else:
				var source = args[0]
				var destination = args[1]
				var source_path = get_full_path() + "/" + source
				var dest_path = get_full_path() + "/" + destination

				var dir = DirAccess.open(get_full_path())
				if not dir:
					output = "No se pudo acceder al directorio actual"
				elif dir.dir_exists(source):
					if not recursive:
						output = "cp: omitiendo directorio '" + source + "'. Usa -r para copiar recursivamente."
					else:
						# Llamamos a la función recursiva 'copy_directory' para copiar directorios
						copy_directory(source_path, dest_path)
						output = "Directorio copiado de " + source + " a " + destination
				elif FileAccess.file_exists(source_path):
					# Copiar archivo simple
					var source_file = FileAccess.open(source_path, FileAccess.READ)
					if source_file:
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
						output = "cp: no se pudo leer el archivo de origen"
				else:
					output = "cp: archivo o directorio no encontrado: " + source

	elif command == "clear":
		history_text = ""
		show_prompt()
		return

	elif command == "help":
		output = "Comandos disponibles:\ncd [ruta], ls, mkdir [nombre], touch [archivo], nano [archivo], rm [-r] [archivo/directorio], cat [archivo], clear, help"

	elif command == "":
		pass

	else:
		if esperando_ls:
			output = "Ese comando no es correcto. Prueba con ls."
		else:
			output = "{command}: Comando no encontrado.".format({"command": command.split(" ")[0]})

	if output != "":
		history_text += "\n" + output
		history.text = history_text
	show_prompt()

# Función para copiar directorios recursivamente
func copy_directory(src: String, dst: String):
	# Crear una instancia de DirAccess
	var dir_access = DirAccess.open(get_full_path())
	
	# Verificar si el directorio destino existe, y si no, crearlo
	if not dir_access.dir_exists(dst):
		print("Creando directorio destino:", dst)  # Agregar un print para verificar la creación
		if not dir_access.make_dir_recursive(dst):
			print("Error: No se pudo crear el directorio destino:", dst)
			return

	# Abrir el directorio origen
	var src_dir = DirAccess.open(src)
	if not src_dir:
		print("Error: No se pudo acceder al directorio origen:", src)
		return

	# Comenzar a recorrer el directorio origen
	src_dir.list_dir_begin()
	var file_name = src_dir.get_next()

	# Iterar sobre todos los archivos y subdirectorios
	while file_name != "":
		if file_name != "." and file_name != "..":
			var src_item = src + "/" + file_name
			var dst_item = dst + "/" + file_name

			# Si es un directorio, llamar recursivamente
			if src_dir.dir_exists(src_item):
				copy_directory(src_item, dst_item)
			# Si es un archivo, copiarlo
			elif src_dir.file_exists(src_item):
				copy_file(src_item, dst_item)

		# Obtener el siguiente archivo o subdirectorio
		file_name = src_dir.get_next()

	# Terminar la lectura del directorio
	src_dir.list_dir_end()

# Función para copiar archivos

func copy_file(src_path: String, dst_path: String):
	var file_name = src_path.get_file()
	
	# Verifica si el archivo de origen existe
	if not FileAccess.file_exists(src_path):
		print("Error: El archivo de origen no existe: ", src_path)
		return false

	# Si el destino es un directorio existente, añade el nombre del archivo al final
	var dir_access = DirAccess.open(get_full_path())
	if dir_access and dir_access.dir_exists(dst_path):
		dst_path = dst_path.rstrip("/") + "/" + file_name

	# Intenta abrir el archivo de origen
	var source_file = FileAccess.open(src_path, FileAccess.READ)
	if not source_file:
		print("Error: No se pudo leer el archivo de origen: ", src_path)
		return false

	var content = source_file.get_as_text()
	source_file.close()

	# Intenta crear y escribir en el archivo de destino
	var dest_file = FileAccess.open(dst_path, FileAccess.WRITE)
	if not dest_file:
		print("Error: No se pudo escribir en el archivo de destino: ", dst_path)
		return false

	dest_file.store_string(content)
	dest_file.close()

	print("Archivo copiado de %s a %s" % [src_path, dst_path])
	return true


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

func autocomplete_command():
	var parts = current_command.strip_edges().split(" ")
	var last_part = parts[-1]

	var full_path = get_full_path()
	var dir = DirAccess.open(full_path)
	if not dir:
		return

	var dirs = dir.get_directories()
	var files = dir.get_files()
	var all_items = dirs + files

	var matches = []
	for item in all_items:
		if item.begins_with(last_part):
			matches.append(item)

	if matches.size() == 1:
		var completed = matches[0]
		current_command = " ".join(parts.slice(0, -1)) + " " + completed
		
		# Mover el cursor al final del comando
		cursor_pos = current_command.length()

		history.text = history_text + current_command
		update_command_display()

	elif matches.size() > 1:
		var suggestions = "\n" + "  ".join(matches) + "\n"
		# NO añadir al history_text — solo mostrarlo como visual temporal
		var prompt = "\n" + USER_COLOR + ":" + "[color=skyblue]" + current_path + "[/color]" + PROMPT_BASE + " " + current_command
		history.text = history_text + suggestions + prompt
#Este si
