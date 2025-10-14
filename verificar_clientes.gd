extends Control

# Verificación simple de clientes

@onready var info_label = Label.new()

func _ready():
	print("🔍 [DB_CHECK] Iniciando verificación...")
	
	# Configurar UI
	add_child(info_label)
	info_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.text = "Verificando base de datos..."
	
	# Esperar a que DataService esté listo
	await get_tree().create_timer(3.0).timeout
	
	verificar_database()

func verificar_database():
	var mensaje = "� VERIFICACIÓN DE CLIENTES\n\n"
	
	if DataService == null:
		mensaje += "❌ DataService no disponible\n"
		info_label.text = mensaje
		return
	
	if DataService.db == null:
		mensaje += "❌ Base de datos no conectada\n"
		info_label.text = mensaje
		return
	
	# Verificar clientes
	var clientes = DataService.buscar_clientes()  # Usar la función que ya tiene debug
	mensaje += "📊 Total de clientes encontrados: " + str(clientes.size()) + "\n\n"
	
	if clientes.size() == 0:
		mensaje += "⚠️ No hay clientes en la base de datos\n"
		mensaje += "🔧 Creando clientes de prueba...\n"
		
		# Crear clientes de prueba
		DataService.crear_clientes_de_prueba()
		
		# Verificar de nuevo
		clientes = DataService.buscar_clientes()
		mensaje += "✅ Clientes creados: " + str(clientes.size()) + "\n\n"
	
	# Mostrar primeros clientes
	mensaje += "📋 PRIMEROS CLIENTES:\n"
	for i in range(min(3, clientes.size())):
		var cliente = clientes[i]
		mensaje += str(i+1) + ". " + str(cliente.get("nombre", "SIN NOMBRE")) + "\n"
		mensaje += "   Tel: " + str(cliente.get("telefono", "N/A")) + "\n"
		mensaje += "   Email: " + str(cliente.get("email", "N/A")) + "\n\n"
	
	info_label.text = mensaje
	print("✅ [DB_CHECK] Verificación completada")