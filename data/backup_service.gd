extends RefCounted
class_name BackupService

# Servicio para crear y restaurar copias de seguridad

static func crear_backup() -> String:
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var nombre_backup = "backup_tienda_sat_" + timestamp + ".zip"
	var ruta_backup = "user://backups/" + nombre_backup
	
	# Crear directorio de backups si no existe
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://backups/"))
	
	# Crear ZIP
	var zip_writer = ZIPPacker.new()
	var error = zip_writer.open(ProjectSettings.globalize_path(ruta_backup))
	
	if error != OK:
		push_error("No se pudo crear archivo ZIP: " + str(error))
		return ""
	
	# Agregar base de datos
	agregar_archivo_a_zip(zip_writer, "user://tienda_sat.db", "database/tienda_sat.db")
	
	# Agregar carpeta de adjuntos si existe
	agregar_directorio_a_zip(zip_writer, "user://adjuntos", "adjuntos")
	
	# Crear manifiesto con información del backup
	var manifiesto = crear_manifiesto()
	zip_writer.start_file("manifest.json")
	zip_writer.write_file(manifiesto.to_utf8_buffer())
	zip_writer.close_file()
	
	zip_writer.close()
	
	print("Backup creado exitosamente: ", ruta_backup)
	return ruta_backup

static func restaurar_backup(ruta_backup: String) -> bool:
	if not FileAccess.file_exists(ruta_backup):
		push_error("Archivo de backup no encontrado: " + ruta_backup)
		return false
	
	var zip_reader = ZIPReader.new()
	var error = zip_reader.open(ProjectSettings.globalize_path(ruta_backup))
	
	if error != OK:
		push_error("No se pudo abrir archivo ZIP: " + str(error))
		return false
	
	# Leer manifiesto
	if not validar_manifiesto(zip_reader):
		push_error("Backup inválido o incompatible")
		zip_reader.close()
		return false
	
	# Hacer backup de los datos actuales antes de restaurar
	var backup_actual = crear_backup()
	if backup_actual == "":
		push_warning("No se pudo crear backup de seguridad de los datos actuales")
	
	# Extraer base de datos
	if zip_reader.file_exists("database/tienda_sat.db"):
		var db_data = zip_reader.read_file("database/tienda_sat.db")
		var db_file = FileAccess.open("user://tienda_sat.db", FileAccess.WRITE)
		if db_file:
			db_file.store_buffer(db_data)
			db_file.close()
	
	# Extraer adjuntos
	extraer_directorio_desde_zip(zip_reader, "adjuntos", "user://adjuntos")
	
	zip_reader.close()
	
	print("Backup restaurado exitosamente desde: ", ruta_backup)
	return true

static func agregar_archivo_a_zip(zip_writer: ZIPPacker, ruta_origen: String, ruta_destino: String):
	var archivo = FileAccess.open(ruta_origen, FileAccess.READ)
	if archivo:
		zip_writer.start_file(ruta_destino)
		zip_writer.write_file(archivo.get_buffer(archivo.get_length()))
		zip_writer.close_file()
		archivo.close()

static func agregar_directorio_a_zip(zip_writer: ZIPPacker, ruta_directorio: String, prefijo_zip: String):
	var dir = DirAccess.open(ruta_directorio)
	if not dir:
		return
	
	agregar_directorio_recursivo(zip_writer, dir, ruta_directorio, prefijo_zip)

static func agregar_directorio_recursivo(zip_writer: ZIPPacker, dir: DirAccess, ruta_base: String, prefijo_zip: String):
	dir.list_dir_begin()
	var nombre_archivo = dir.get_next()
	
	while nombre_archivo != "":
		if nombre_archivo != "." and nombre_archivo != "..":
			var ruta_completa = ruta_base + "/" + nombre_archivo
			var ruta_zip = prefijo_zip + "/" + nombre_archivo
			
			if dir.current_is_dir():
				# Es un directorio, agregar recursivamente
				var subdir = DirAccess.open(ruta_completa)
				if subdir:
					agregar_directorio_recursivo(zip_writer, subdir, ruta_completa, ruta_zip)
			else:
				# Es un archivo, agregarlo
				agregar_archivo_a_zip(zip_writer, ruta_completa, ruta_zip)
		
		nombre_archivo = dir.get_next()

static func extraer_directorio_desde_zip(zip_reader: ZIPReader, prefijo_zip: String, ruta_destino: String):
	var archivos = zip_reader.get_files()
	
	for archivo in archivos:
		if archivo.begins_with(prefijo_zip + "/"):
			var ruta_relativa = archivo.substr(prefijo_zip.length() + 1)
			var ruta_completa = ruta_destino + "/" + ruta_relativa
			
			# Crear directorio padre si no existe
			var directorio_padre = ruta_completa.get_base_dir()
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directorio_padre))
			
			# Extraer archivo
			var datos = zip_reader.read_file(archivo)
			var file = FileAccess.open(ruta_completa, FileAccess.WRITE)
			if file:
				file.store_buffer(datos)
				file.close()

static func crear_manifiesto() -> String:
	var manifiesto = {
		"version": "1.0",
		"app_version": "1.0.0",
		"created_at": Time.get_datetime_string_from_system(),
		"created_by": AppState.get_usuario_nombre(),
		"database_version": obtener_version_bd(),
		"files": {
			"database": "database/tienda_sat.db",
			"attachments": "adjuntos/"
		}
	}
	
	return JSON.stringify(manifiesto)

static func validar_manifiesto(zip_reader: ZIPReader) -> bool:
	if not zip_reader.file_exists("manifest.json"):
		return false
	
	var manifest_data = zip_reader.read_file("manifest.json")
	var manifest_text = manifest_data.get_string_from_utf8()
	
	var json = JSON.new()
	var parse_result = json.parse(manifest_text)
	
	if parse_result != OK:
		return false
	
	var manifiesto = json.data
	
	# Validar versión de aplicación
	if not manifiesto.has("version"):
		return false
	
	# Validar que tiene la base de datos
	if not manifiesto.has("files") or not manifiesto.files.has("database"):
		return false
	
	return true

static func obtener_version_bd() -> int:
	var result = DataService.execute_sql("SELECT MAX(version) as version FROM migrations")
	if result.size() > 0 and result[0].has("version"):
		return int(result[0]["version"])
	return 0

static func listar_backups() -> Array:
	var backups = []
	var dir = DirAccess.open("user://backups/")
	
	if not dir:
		return backups
	
	dir.list_dir_begin()
	var nombre_archivo = dir.get_next()
	
	while nombre_archivo != "":
		if nombre_archivo.ends_with(".zip") and nombre_archivo.begins_with("backup_"):
			var ruta_completa = "user://backups/" + nombre_archivo
			var info_backup = obtener_info_backup(ruta_completa)
			if info_backup.size() > 0:
				backups.append(info_backup)
		
		nombre_archivo = dir.get_next()
	
	# Ordenar por fecha de creación (más reciente primero)
	backups.sort_custom(func(a, b): return a.fecha > b.fecha)
	
	return backups

static func obtener_info_backup(ruta_backup: String) -> Dictionary:
	var info = {}
	
	# Información básica del archivo
	var file_access = FileAccess.open(ruta_backup, FileAccess.READ)
	if file_access:
		info["ruta"] = ruta_backup
		info["nombre"] = ruta_backup.get_file()
		info["tamaño"] = file_access.get_length()
		file_access.close()
		
		# Intentar leer manifiesto
		var zip_reader = ZIPReader.new()
		if zip_reader.open(ProjectSettings.globalize_path(ruta_backup)) == OK:
			if zip_reader.file_exists("manifest.json"):
				var manifest_data = zip_reader.read_file("manifest.json")
				var manifest_text = manifest_data.get_string_from_utf8()
				
				var json = JSON.new()
				if json.parse(manifest_text) == OK:
					var manifiesto = json.data
					info["fecha"] = manifiesto.get("created_at", "")
					info["usuario"] = manifiesto.get("created_by", "")
					info["version_app"] = manifiesto.get("app_version", "")
					info["version_bd"] = manifiesto.get("database_version", 0)
			
			zip_reader.close()
	
	return info

static func eliminar_backup(ruta_backup: String) -> bool:
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta_backup)) == OK

static func formatear_tamaño(bytes: int) -> String:
	if bytes < 1024:
		return str(bytes) + " B"
	elif bytes < 1024 * 1024:
		return "%.1f KB" % (bytes / 1024.0)
	else:
		return "%.1f MB" % (bytes / (1024.0 * 1024.0))