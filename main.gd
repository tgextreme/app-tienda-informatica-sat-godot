extends Control

# Main - Controlador principal simplificado

@onready var content_container = $ContentContainer

func _ready():
	print("🎯 [MAIN] Iniciando aplicación SAT...")
	print("📊 [MAIN] ContentContainer encontrado: ", content_container != null)
	
	# Agregar al grupo para que el Router pueda encontrarlo
	add_to_group("main")
	print("✅ [MAIN] Agregado al grupo 'main'")
	
	# Esperar a que todos los autoloads estén listos
	await get_tree().process_frame
	await get_tree().process_frame
	
	inicializar_aplicacion()
	
	# Ejecutar test temporal
	call_deferred("test_productos_directo")

func inicializar_aplicacion():
	print("🔧 [MAIN] Iniciando inicialización...")
	
	# Verificar autoloads
	if not verificar_autoloads():
		mostrar_error("Error: Autoloads no disponibles")
		return
	
	# Inicializar Router
	if Router == null:
		mostrar_error("Error: Router no disponible")
		return
	
	if content_container == null:
		mostrar_error("Error: ContentContainer no encontrado")
		return
	
	print("🧭 [MAIN] Inicializando Router...")
	Router.inicializar(content_container)
	
	# Proteger el ContentContainer de ser eliminado
	content_container.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Verificar que se inicializó correctamente
	await get_tree().create_timer(1.0).timeout
	
	if Router.root_control == null:
		mostrar_error("Error: Router no se inicializó correctamente")
		return
	
	print("✅ [MAIN] Router inicializado correctamente")
	
	# Verificar estado de la aplicación y navegar
	navegar_inicial()

func verificar_autoloads() -> bool:
	print("📋 [MAIN] Verificando autoloads...")
	
	if AppState == null:
		print("❌ [MAIN] AppState no disponible")
		return false
	print("✅ [MAIN] AppState OK")
	
	if Router == null:
		print("❌ [MAIN] Router no disponible") 
		return false
	print("✅ [MAIN] Router OK")
	
	if DataService == null:
		print("❌ [MAIN] DataService no disponible")
		return false
	print("✅ [MAIN] DataService OK")
	
	return true

func navegar_inicial():
	print("🧭 [MAIN] Iniciando navegación...")
	
	# Verificar si hay usuario logueado
	if AppState.usuario_actual.size() > 0:
		print("✅ [MAIN] Usuario logueado, ir a dashboard")
		Router.ir_a_dashboard()
	else:
		print("👤 [MAIN] No hay usuario, ir a login")
		Router.ir_a_login()
	
	print("🚀 [MAIN] Aplicación SAT iniciada correctamente")

func mostrar_error(mensaje: String):
	print("❌ [MAIN] ERROR: ", mensaje)
	
	# Crear mensaje de error visual
	var error_label = Label.new()
	error_label.text = "❌ ERROR CRÍTICO\n\n" + mensaje + "\n\nPor favor:\n1. Cerrar la aplicación\n2. Verificar instalación\n3. Reintentar"
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	error_label.add_theme_color_override("font_color", Color.RED)
	error_label.add_theme_font_size_override("font_size", 16)
	
	# Agregar al contenedor si existe, sino a la raíz
	if content_container:
		content_container.add_child(error_label)
	else:
		add_child(error_label)
	
	error_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

# TEST TEMPORAL PARA PRODUCTOS
func _on_tree_ready():
	await get_tree().create_timer(3.0).timeout
	test_productos_directo()

func test_productos_directo():
	print("🧪 [MAIN_TEST] Iniciando test directo de productos...")
	
	# Buscar productos existentes
	var productos = DataService.buscar_productos({})
	print("🧪 [MAIN_TEST] Productos encontrados: ", productos.size())
	
	if productos.size() > 0:
		print("🧪 [MAIN_TEST] Primer producto: ", productos[0])
		print("🧪 [MAIN_TEST] Campos disponibles: ", productos[0].keys())
	else:
		print("🧪 [MAIN_TEST] No hay productos - creando uno de prueba...")
		var producto_test = {
			"sku": "TEST-MAIN-001",
			"nombre": "Producto Test Main", 
			"categoria": "Test",
			"tipo": "REPUESTO",
			"coste": 20.0,
			"pvp": 30.0,
			"iva": 21.0,
			"stock": 10,
			"stock_min": 3,
			"proveedor": "Test Provider"
		}
		
		var resultado = DataService.guardar_producto(producto_test)
		print("🧪 [MAIN_TEST] Resultado creación: ", resultado)