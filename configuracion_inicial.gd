extends Node

const BASE_PATH = "user://ubuntu_sim"  # Ruta real base

func _ready():
	crear_estructura_directorios()
	
	var ips_file_path = BASE_PATH + "/home/usuario/Documentos/IPS_Departamentos.txt"
	if not FileAccess.file_exists(ips_file_path):
		var ips_file = FileAccess.open(ips_file_path, FileAccess.WRITE)
		if ips_file:
			ips_file.store_string("""# IPs asignadas a los departamentos de Cyberdyne Systems

			192.168.10.10   pc_ventas
			192.168.10.100   pc_contabilidad
			192.168.10.12   impresora_oficina
			192.168.10.1  router_ventas

			# Fin del archivo""")
	
	
func crear_estructura_directorios():
	var dir = DirAccess.open("user://")
	if dir:
		# Crear ubuntu_sim si no existe
		if not dir.dir_exists("ubuntu_sim"):
			dir.make_dir("ubuntu_sim")
		dir.change_dir("ubuntu_sim")

		# Crear carpetas raíz
		var root_folders = ["home", "etc", "var", "bin", "usr", "boot", "dev", "lib", "media", "mnt", "opt", "proc", "root", "run", "sbin", "srv", "sys", "tmp"]
		for folder in root_folders:
			if not dir.dir_exists(folder):
				dir.make_dir(folder)

		# HOME
		if not dir.dir_exists("home/usuario"):
			dir.make_dir_recursive("home/usuario")
		var user_subfolders = ["Documentos", "Descargas", "Escritorio", "Imágenes", "Música", "Vídeos"]
		for subfolder in user_subfolders:
			if not dir.dir_exists("home/usuario/" + subfolder):
				dir.make_dir("home/usuario/" + subfolder)

		# ETC
		var etc_files = ["passwd", "group", "shadow", "fstab", "hostname", "bash.bashrc", "crontab"]
		for etc_file in etc_files:
			var path = "etc/" + etc_file
			if not dir.file_exists(path):
				var f = FileAccess.open("user://ubuntu_sim/" + path, FileAccess.WRITE)
				if f: f.close()
		var etc_dirs = ["Network", "systemd", "apt", "opt", "X11", "sgml", "xml"]
		for etc_dir in etc_dirs:
			if not dir.dir_exists("etc/" + etc_dir):
				dir.make_dir_recursive("etc/" + etc_dir)
		if not dir.dir_exists("etc/Network/interfaces"):
			dir.make_dir_recursive("etc/Network/interfaces")
		if not dir.dir_exists("etc/systemd/system"):
			dir.make_dir_recursive("etc/systemd/system")
		if not dir.file_exists("etc/apt/sources.list"):
			var f = FileAccess.open("user://ubuntu_sim/etc/apt/sources.list", FileAccess.WRITE)
			if f: f.close()

		# USR
		var usr_subdirs = ["bin", "sbin", "share", "lib", "local", "src", "games", "include", "libexec"]
		for usr_sub in usr_subdirs:
			if not dir.dir_exists("usr/" + usr_sub):
				dir.make_dir_recursive("usr/" + usr_sub)
		if not dir.dir_exists("usr/share/man"):
			dir.make_dir_recursive("usr/share/man")
		if not dir.dir_exists("usr/share/doc"):
			dir.make_dir_recursive("usr/share/doc")
		if not dir.dir_exists("usr/X11R6"):
			dir.make_dir_recursive("usr/X11R6")

		# VAR
		var var_subdirs = ["log", "tmp", "lib", "spool", "cache", "mail", "run", "lock", "opt"]
		for sub in var_subdirs:
			if not dir.dir_exists("var/" + sub):
				dir.make_dir_recursive("var/" + sub)

		# Subdirectorios específicos para apt-get clean
		var cache_subdirs = ["apt", "apt/archives", "apt/archives/partial"]
		for sub in cache_subdirs:
			var path = "var/cache/" + sub
			if not dir.dir_exists(path):
				dir.make_dir_recursive(path)

		var lib_subdirs = ["apt", "apt/lists", "dpkg"]
		for sub in lib_subdirs:
			var path = "var/lib/" + sub
			if not dir.dir_exists(path):
				dir.make_dir_recursive(path)

		if not dir.dir_exists("var/spool/mail"):
			dir.make_dir_recursive("var/spool/mail")

		# ⚠️ Crear archivos .deb simulados (útiles para que apt-get clean funcione de inicio)
		var archive_files = ["nano_1.0.deb", "htop_1.0.deb"]
		for filename in archive_files:
			var file_path = "user://ubuntu_sim/var/cache/apt/archives/" + filename
			if not FileAccess.file_exists(file_path):
				var f = FileAccess.open(file_path, FileAccess.WRITE)
				if f:
					f.store_string("Contenido simulado de " + filename)
					f.close()
