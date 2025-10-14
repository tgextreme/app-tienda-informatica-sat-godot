extends Control

# Prueba simple de guardado de cliente

@onready var resultado_label = Label.new()

func _ready():
	print("🧪 [TEST_GUARDADO] Iniciando prueba de guardado...")
	
	# Configurar UI
	add_child(resultado_label)
	resultado_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resultado_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	resultado_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resultado_label.text = "Probando guardado de cliente..."
	
	# Esperar a que todo esté listo
	await get_tree().create_timer(3.0).timeout
	
	probar_guardado()

func probar_guardado():
	var mensaje = "🧪 PRUEBA DE GUARDADO DE CLIENTE\n\n"
	
	if DataService == null:
		mensaje += "❌ DataService no disponible"
		resultado_label.text = mensaje
		return
	
	# Crear un cliente de prueba
	var cliente_prueba = {
		"nombre": "Cliente de Prueba Guardado",
		"telefono": "999888777",
		"email": "prueba.guardado@test.com",
		"nif": "99988877A",
		"direccion": "Calle de Pruebas, 123",
		"telefono_alt": "666555444",
		"notas": "Cliente creado para probar el guardado",
		"rgpd_consent": 1
	}
	
	mensaje += "📝 Intentando guardar cliente:\n"
	mensaje += "   Nombre: " + cliente_prueba.nombre + "\n"
	mensaje += "   Teléfono: " + cliente_prueba.telefono + "\n"
	mensaje += "   Email: " + cliente_prueba.email + "\n\n"
	
	# Intentar guardar
	print("🧪 [TEST_GUARDADO] Guardando cliente de prueba...")
	var cliente_id = DataService.guardar_cliente(cliente_prueba)
	
	if cliente_id > 0:
		mensaje += "✅ CLIENTE GUARDADO EXITOSAMENTE\n"
		mensaje += "   ID asignado: " + str(cliente_id) + "\n\n"
		
		# Verificar que se guardó consultando
		var clientes = DataService.buscar_clientes()
		mensaje += "📊 Total de clientes después del guardado: " + str(clientes.size()) + "\n\n"
		
		# Buscar el cliente recién creado
		var cliente_encontrado = false
		for cliente in clientes:
			if int(cliente.get("id", 0)) == cliente_id:
				cliente_encontrado = true
				mensaje += "🔍 CLIENTE ENCONTRADO EN LA BD:\n"
				mensaje += "   ID: " + str(cliente.get("id")) + "\n"
				mensaje += "   Nombre: " + str(cliente.get("nombre", "N/A")) + "\n"
				mensaje += "   Teléfono: " + str(cliente.get("telefono", "N/A")) + "\n"
				break
		
		if not cliente_encontrado:
			mensaje += "❌ ERROR: Cliente no encontrado en la consulta posterior"
		
	else:
		mensaje += "❌ ERROR AL GUARDAR CLIENTE\n"
		mensaje += "   ID devuelto: " + str(cliente_id) + "\n"
		mensaje += "   Revisar logs para más detalles"
	
	resultado_label.text = mensaje