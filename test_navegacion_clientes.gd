extends Control

# Test específico de navegación a clientes

@onready var resultado_label = Label.new()

func _ready():
	print("🧪 [TEST_NAV] Iniciando prueba de navegación a clientes...")
	
	# Configurar UI
	add_child(resultado_label)
	resultado_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resultado_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	resultado_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resultado_label.text = "🔄 Iniciando prueba de navegación..."
	
	# Esperar a que todo esté listo
	await get_tree().create_timer(3.0).timeout
	
	probar_navegacion()

func probar_navegacion():
	var mensaje = "🧪 PRUEBA DE NAVEGACIÓN A CLIENTES\n\n"
	
	# 1. Verificar autoloads
	mensaje += "1. VERIFICANDO SISTEMA:\n"
	if AppState == null:
		mensaje += "❌ AppState no disponible\n"
		resultado_label.text = mensaje
		return
	mensaje += "✅ AppState OK\n"
	
	if Router == null:
		mensaje += "❌ Router no disponible\n"
		resultado_label.text = mensaje
		return
	mensaje += "✅ Router OK\n"
	
	if DataService == null:
		mensaje += "❌ DataService no disponible\n"
		resultado_label.text = mensaje
		return
	mensaje += "✅ DataService OK\n"
	
	# 2. Verificar Router
	mensaje += "\n2. VERIFICANDO ROUTER:\n"
	mensaje += "Root control: " + str(Router.root_control) + "\n"
	mensaje += "Root control válido: " + str(Router.root_control != null and is_instance_valid(Router.root_control)) + "\n"
	
	resultado_label.text = mensaje
	await get_tree().create_timer(1.0).timeout
	
	# 3. Probar navegación
	mensaje += "\n3. PROBANDO NAVEGACIÓN:\n"
	
	# Simular login si no hay usuario
	if AppState.usuario_actual.is_empty():
		mensaje += "🔧 Simulando login...\n"
		var usuario_admin = {
			"id": 1,
			"nombre": "Administrador Test",
			"email": "admin@test.com",
			"rol_id": 1,
			"rol_nombre": "ADMIN"
		}
		AppState.usuario_actual = usuario_admin
		AppState.es_admin = true
		mensaje += "✅ Usuario simulado configurado\n"
	
	resultado_label.text = mensaje
	await get_tree().create_timer(1.0).timeout
	
	# 4. Intentar navegar a clientes
	mensaje += "\n4. NAVEGANDO A CLIENTES:\n"
	resultado_label.text = mensaje
	
	print("🧪 [TEST_NAV] Intentando navegar a clientes...")
	Router.ir_a_clientes()
	
	await get_tree().create_timer(2.0).timeout
	
	# 5. Verificar resultado
	mensaje += "Pantalla actual: " + str(Router.pantalla_actual) + "\n"
	
	if Router.pantalla_actual == "clientes_lista":
		mensaje += "✅ NAVEGACIÓN EXITOSA!\n"
		mensaje += "\n🎉 El CRUD de clientes debería estar visible ahora\n"
	else:
		mensaje += "❌ Navegación falló\n"
		mensaje += "Pantalla esperada: clientes_lista\n"
		mensaje += "Pantalla actual: " + str(Router.pantalla_actual) + "\n"
	
	resultado_label.text = mensaje