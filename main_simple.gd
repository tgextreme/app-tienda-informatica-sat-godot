extends Control

# Versión simplificada del main para debugging

func _ready():
	print("🎯 [MAIN] Iniciando aplicación simple...")
	
	# Crear directamente la pantalla de login sin Router
	cargar_login_directo()

func cargar_login_directo():
	print("👤 [MAIN] Cargando login directamente...")
	
	# Verificar que el archivo existe
	if not FileAccess.file_exists("res://ui/login.tscn"):
		print("❌ [MAIN] Archivo login.tscn no existe")
		mostrar_error("Error: login.tscn no encontrado")
		return
	
	# Cargar la escena
	var login_scene = load("res://ui/login.tscn")
	if login_scene == null:
		print("❌ [MAIN] No se puede cargar login.tscn")
		mostrar_error("Error: No se puede cargar login.tscn")
		return
	
	# Instanciar
	var login_instance = login_scene.instantiate()
	if login_instance == null:
		print("❌ [MAIN] No se puede instanciar login")
		mostrar_error("Error: No se puede instanciar login")
		return
	
	# Agregar como hijo
	add_child(login_instance)
	print("✅ [MAIN] Login cargado correctamente")

func mostrar_error(mensaje: String):
	var label = Label.new()
	label.text = mensaje
	label.anchors_preset = Control.PRESET_FULL_RECT
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)