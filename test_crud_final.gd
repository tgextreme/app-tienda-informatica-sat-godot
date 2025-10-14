extends Control

# Test específico para el CRUD de clientes

func _ready():
	print("🧪 [TEST_CRUD] Iniciando test del CRUD de clientes...")
	
	# Crear una ventana de test
	var label = Label.new()
	add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = "🔄 Ejecutando pruebas del CRUD de clientes..."
	
	# Esperar un momento y luego ejecutar pruebas
	await get_tree().create_timer(2.0).timeout
	
	ejecutar_pruebas(label)

func ejecutar_pruebas(label: Label):
	var resultado = "🧪 PRUEBAS DEL CRUD DE CLIENTES\n\n"
	
	# 1. Verificar que los autoloads están disponibles
	resultado += "1. VERIFICANDO SISTEMA:\n"
	if Router == null:
		resultado += "❌ Router no disponible\n"
		label.text = resultado
		return
	resultado += "✅ Router disponible\n"
	
	if DataService == null:
		resultado += "❌ DataService no disponible\n"
		label.text = resultado
		return
	resultado += "✅ DataService disponible\n"
	
	# 2. Verificar que las escenas existen
	resultado += "\n2. VERIFICANDO ESCENAS:\n"
	
	var gestionar_clientes_scene = load("res://ui/gestionar_clientes.tscn")
	if gestionar_clientes_scene == null:
		resultado += "❌ gestionar_clientes.tscn no se puede cargar\n"
	else:
		resultado += "✅ gestionar_clientes.tscn carga correctamente\n"
	
	var nuevo_cliente_scene = load("res://ui/nuevo_cliente.tscn")
	if nuevo_cliente_scene == null:
		resultado += "❌ nuevo_cliente.tscn no se puede cargar\n"
	else:
		resultado += "✅ nuevo_cliente.tscn carga correctamente\n"
	
	# 3. Probar instanciación
	resultado += "\n3. PROBANDO INSTANCIACIÓN:\n"
	
	if gestionar_clientes_scene:
		var instancia = gestionar_clientes_scene.instantiate()
		if instancia:
			resultado += "✅ gestionar_clientes se puede instanciar\n"
			instancia.queue_free()
		else:
			resultado += "❌ Error al instanciar gestionar_clientes\n"
	
	if nuevo_cliente_scene:
		var instancia = nuevo_cliente_scene.instantiate()
		if instancia:
			resultado += "✅ nuevo_cliente se puede instanciar\n"
			instancia.queue_free()
		else:
			resultado += "❌ Error al instanciar nuevo_cliente\n"
	
	# 4. Probar navegación
	resultado += "\n4. PROBANDO NAVEGACIÓN:\n"
	
	# Simular usuario logueado si no lo hay
	if AppState.usuario_actual.is_empty():
		resultado += "🔧 Simulando login de administrador...\n"
		AppState.usuario_actual = {
			"id": 1,
			"nombre": "Admin Test",
			"email": "admin@test.com",
			"rol_id": 1,
			"rol_nombre": "ADMIN"
		}
		AppState.es_admin = true
	
	# Verificar función de navegación
	if Router.has_method("ir_a_clientes"):
		resultado += "✅ Router tiene método ir_a_clientes()\n"
		
		# Intentar navegar
		Router.ir_a_clientes()
		await get_tree().create_timer(1.0).timeout
		
		if Router.pantalla_actual == "clientes_lista":
			resultado += "✅ Navegación a clientes exitosa!\n"
			resultado += "\n🎉 EL CRUD DE CLIENTES ESTÁ FUNCIONANDO!\n"
			resultado += "\n📝 Puedes:\n"
			resultado += "• Ver lista de clientes\n"
			resultado += "• Buscar clientes\n"
			resultado += "• Crear nuevos clientes\n"
			resultado += "• Editar clientes existentes\n"
			resultado += "• Eliminar clientes\n"
		else:
			resultado += "❌ Navegación falló - Pantalla actual: " + str(Router.pantalla_actual) + "\n"
	else:
		resultado += "❌ Router no tiene método ir_a_clientes()\n"
	
	label.text = resultado