extends Node

#Función que borre de forma recursiva los directorios
func remove_directory_recursive(path):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name != "." and file_name != "..":
				var full_path = path + "/" + file_name
				if dir.current_is_dir():
					# Si es un subdirectorio, llamar recursivamente
					remove_directory_recursive(full_path)
				else:
					# Si es un archivo, eliminarlo
					DirAccess.remove_absolute(full_path)
			file_name = dir.get_next()
		dir.list_dir_end()
		# Cuando esté vacío, eliminar el directorio principal
		DirAccess.remove_absolute(path)

func remove_directory_contents(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name != "." and file_name != "..":
				var full_path = path + "/" + file_name
				if dir.current_is_dir():
					Funciones.remove_directory_recursive(full_path)
				else:
					DirAccess.remove_absolute(full_path)
			file_name = dir.get_next()
		dir.list_dir_end()
		
#función apt-get clean
func delete_files_in(path: String) -> int:
	var dir = DirAccess.open(path)
	var count = 0
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			if not dir.current_is_dir():
				var full_file_path = path + "/" + file
				DirAccess.remove_absolute(full_file_path)
				count += 1
			file = dir.get_next()
		dir.list_dir_end()
	return count

func normalize_path(path: String) -> String:
	var parts = []
	for p in path.split("/"):
		if p != "":
			parts.append(p)
	return "/" + "/".join(parts)

# Función para copiar directorios recursivamente
func copy_directory(src: String, dst: String, full_path: String):
	# Crear una instancia de DirAccess
	var dir_access = DirAccess.open(full_path)
	
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
				copy_directory(src_item, dst_item, full_path)
			# Si es un archivo, copiarlo
			elif src_dir.file_exists(src_item):
				copy_file(src_item, dst_item, full_path)

		# Obtener el siguiente archivo o subdirectorio
		file_name = src_dir.get_next()

	# Terminar la lectura del directorio
	src_dir.list_dir_end()

# Función para copiar archivos
func copy_file(src_path: String, dst_path: String, full_path: String):
	var file_name = src_path.get_file()
	
	# Verifica si el archivo de origen existe
	if not FileAccess.file_exists(src_path):
		print("Error: El archivo de origen no existe: ", src_path)
		return false

	# Si el destino es un directorio existente, añade el nombre del archivo al final
	var dir_access = DirAccess.open(full_path)
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

#Contraseña para sudo apt-get clean
func prompt_password(prompt_text: String) -> String:
	var dialog = AcceptDialog.new()
	dialog.dialog_text = prompt_text

	var password_input = LineEdit.new()
	password_input.secret = true
	password_input.secret_character = "*"  # Puedes cambiar el carácter si lo deseas
	dialog.add_child(password_input)

	add_child(dialog)
	dialog.popup_centered()

	await dialog.confirmed

	var password = password_input.text
	dialog.queue_free()
	return password

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

# Simulación simple de resolución de nombres
func resolve_hostname(hostname: String) -> bool:
	return hostname == "localhost" or hostname.ends_with(".com")
