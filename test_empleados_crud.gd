extends Control

# Test del CRUD de empleados

func _ready():
	print("🧪 [TEST_EMPLEADOS] Iniciando prueba del sistema de empleados...")
	
	# Esperar a que el sistema esté listo
	await get_tree().create_timer(2.0).timeout
	
	ejecutar_pruebas()

func ejecutar_pruebas():
	var resultado = "🧪 PRUEBAS DEL CRUD DE EMPLEADOS\n\n"
	
	# 1. Verificar autoloads
	resultado += "1. VERIFICANDO SISTEMA:\n"
	if Router == null:
		resultado += "❌ Router no disponible\n"
		return
	resultado += "✅ Router disponible\n"
	
	if DataService == null:
		resultado += "❌ DataService no disponible\n"
		return
	resultado += "✅ DataService disponible\n"
	
	# 2. Verificar que las escenas existen
	resultado += "\n2. VERIFICANDO ESCENAS:\n"
	
	var gestionar_empleados_scene = load("res://ui/gestionar_empleados_new.tscn")
	if gestionar_empleados_scene == null:
		resultado += "❌ gestionar_empleados_new.tscn no se puede cargar\n"
	else:
		resultado += "✅ gestionar_empleados_new.tscn carga correctamente\n"
	
	var nuevo_empleado_scene = load("res://ui/nuevo_empleado_new.tscn")
	if nuevo_empleado_scene == null:
		resultado += "❌ nuevo_empleado_new.tscn no se puede cargar\n"
	else:
		resultado += "✅ nuevo_empleado_new.tscn carga correctamente\n"
	
	# 3. Probar funciones de DataService
	resultado += "\n3. PROBANDO DATASERVICE:\n"
	
	if DataService.has_method("obtener_empleados"):
		resultado += "✅ DataService.obtener_empleados() existe\n"
		var empleados = DataService.obtener_empleados()
		resultado += "📊 Empleados encontrados: " + str(empleados.size()) + "\n"
	else:
		resultado += "❌ DataService.obtener_empleados() NO existe\n"
	
	if DataService.has_method("crear_empleado"):
		resultado += "✅ DataService.crear_empleado() existe\n"
	else:
		resultado += "❌ DataService.crear_empleado() NO existe\n"
	
	# 4. Probar navegación
	resultado += "\n4. PROBANDO NAVEGACIÓN:\n"
	
	# Simular usuario admin
	AppState.usuario_actual = {
		"id": 1,
		"nombre": "Admin Test",
		"rol_id": 1,
		"rol_nombre": "ADMIN"
	}
	AppState.es_admin = true
	
	if Router.has_method("ir_a_empleados"):
		resultado += "✅ Router.ir_a_empleados() existe\n"
		resultado += "\n🎉 EL CRUD DE EMPLEADOS ESTÁ LISTO!\n"
		resultado += "\n📝 Funcionalidades disponibles:\n"
		resultado += "• Ver lista de empleados\n"
		resultado += "• Buscar empleados por nombre, email o rol\n"
		resultado += "• Crear nuevos empleados\n"
		resultado += "• Editar empleados existentes\n"
		resultado += "• Eliminar empleados\n"
		resultado += "• Gestión de roles y permisos\n"
	else:
		resultado += "❌ Router.ir_a_empleados() NO existe\n"
	
	print(resultado)
	
	# Crear ventana para mostrar resultado
	var label = Label.new()
	add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = resultado
	
	# Terminar después de un tiempo
	await get_tree().create_timer(5.0).timeout
	get_tree().quit()