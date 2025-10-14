extends Control

# Main - Controlador principal de la aplicación
# Inicializa el sistema y maneja la navegación global

@onready var content_container = $ContentContainer

func _ready():
	print("🎯 Iniciando aplicación SAT...")
	
	# Verificar que los nodos necesarios existen
	if content_container == null:
		print("❌ ERROR: ContentContainer no encontrado")
		return
	
	# Inicializar sistema paso a paso con verificaciones
	await inicializar_sistema()

func inicializar_sistema():
	print("📋 Verificando autoloads...")
	
	# Verificar que los autoloads estén disponibles
	if not verificar_autoloads():
		print("❌ ERROR: Autoloads no están listos")
		mostrar_error("Error del sistema: Autoloads no inicializados")
		return
	
	print("✅ Autoloads verificados")
	
	# Esperar un poco más para la inicialización
	await get_tree().create_timer(2.0).timeout
	
	# Inicializar el Router
	print("🧭 Inicializando Router...")
	if Router == null:
		print("❌ ERROR: Router no disponible")
		mostrar_error("Error del sistema: Router no disponible")
		return
	
	Router.inicializar(content_container)
	
	# Verificar sistema de base de datos
	print("💾 Verificando base de datos...")
	if DataService == null or DataService.db == null:
		print("⚠️ Base de datos no lista, reintentando...")
		await get_tree().create_timer(2.0).timeout
		
		if DataService == null or DataService.db == null:
			print("❌ ERROR: Base de datos no disponible")
			mostrar_error("Error del sistema: Base de datos no inicializada")
			return
	
	print("✅ Base de datos verificada")
	
	# Navegación inicial
	print("🧭 Iniciando navegación...")
	try_navegacion_inicial()

func verificar_autoloads() -> bool:
	var autoloads_ok = true
	
	if AppState == null:
		print("❌ AppState no disponible")
		autoloads_ok = false
	else:
		print("✅ AppState OK")
	
	if Router == null:
		print("❌ Router no disponible")
		autoloads_ok = false
	else:
		print("✅ Router OK")
	
	if DataService == null:
		print("❌ DataService no disponible")
		autoloads_ok = false
	else:
		print("✅ DataService OK")
	
	return autoloads_ok

func try_navegacion_inicial():
	# Verificar si hay usuario logueado
	if AppState.usuario_actual.size() > 0:
		print("✅ Usuario ya logueado, ir a dashboard")
		Router.ir_a_dashboard()
	else:
		print("👤 No hay usuario, ir a login")
		Router.ir_a_login()
	
	print("🚀 Aplicación SAT lista")

func mostrar_error(mensaje: String):
	# Crear un label de error simple
	var error_label = Label.new()
	error_label.text = mensaje + "\n\nPor favor:\n1. Cerrar la aplicación\n2. Verificar archivos del proyecto\n3. Reintentar"
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	error_label.add_theme_color_override("font_color", Color.RED)
	
	# Agregar al contenedor
	content_container.add_child(error_label)
	error_label.anchors_preset = Control.PRESET_FULL_RECT