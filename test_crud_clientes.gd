extends Node

# Script de prueba completa del CRUD de clientes

func _ready():
	print("🧪 [TEST_CLIENTES] Iniciando pruebas del CRUD de clientes...")
	
	# Esperar a que DataService esté listo
	await get_tree().create_timer(2.0).timeout
	
	# Ejecutar todas las pruebas
	await test_crear_clientes()
	await test_buscar_clientes()
	await test_obtener_cliente()
	await test_actualizar_cliente()
	await test_eliminar_cliente()
	
	print("✅ [TEST_CLIENTES] Todas las pruebas completadas!")
	get_tree().quit()

func test_crear_clientes():
	print("\n📝 [TEST] Probando creación de clientes...")
	
	# Crear clientes de prueba
	DataService.crear_clientes_de_prueba()
	
	# Verificar que se crearon
	var clientes = DataService.obtener_todos_los_clientes()
	print("📊 [TEST] Total clientes después de crear: ", clientes.size())
	
	# Mostrar algunos detalles
	if clientes.size() > 0:
		var primer_cliente = clientes[0]
		print("👤 [TEST] Primer cliente:")
		print("  - ID: ", primer_cliente.get("id"))
		print("  - Nombre: ", primer_cliente.get("nombre"))
		print("  - Email: ", primer_cliente.get("email"))
		print("  - Teléfono: ", primer_cliente.get("telefono"))

func test_buscar_clientes():
	print("\n🔍 [TEST] Probando búsqueda de clientes...")
	
	# Buscar todos los clientes
	var todos = DataService.buscar_clientes("")
	print("📋 [TEST] Buscar todos: ", todos.size(), " clientes")
	
	# Buscar por nombre
	var por_nombre = DataService.buscar_clientes("Juan")
	print("🔍 [TEST] Buscar 'Juan': ", por_nombre.size(), " resultados")
	
	# Buscar por email
	var por_email = DataService.buscar_clientes("maria.lopez")
	print("📧 [TEST] Buscar 'maria.lopez': ", por_email.size(), " resultados")
	
	# Buscar por teléfono
	var por_telefono = DataService.buscar_clientes("666")
	print("📞 [TEST] Buscar '666': ", por_telefono.size(), " resultados")

func test_obtener_cliente():
	print("\n👤 [TEST] Probando obtener cliente individual...")
	
	# Obtener el primer cliente
	var clientes = DataService.obtener_todos_los_clientes()
	if clientes.size() > 0:
		var cliente_id = int(clientes[0].get("id", 0))
		var cliente = DataService.obtener_cliente(cliente_id)
		
		if not cliente.is_empty():
			print("✅ [TEST] Cliente obtenido correctamente:")
			print("  - ID: ", cliente.get("id"))
			print("  - Nombre: ", cliente.get("nombre"))
		else:
			print("❌ [TEST] Error al obtener cliente")
	else:
		print("⚠️ [TEST] No hay clientes para obtener")

func test_actualizar_cliente():
	print("\n✏️ [TEST] Probando actualización de cliente...")
	
	# Obtener un cliente existente
	var clientes = DataService.obtener_todos_los_clientes()
	if clientes.size() > 0:
		var cliente = clientes[0]
		var cliente_id = int(cliente.get("id", 0))
		
		# Actualizar datos
		cliente["nombre"] = "Juan Pérez González (ACTUALIZADO)"
		cliente["email"] = "juan.actualizado@email.com"
		cliente["notas"] = "Cliente actualizado en prueba"
		
		# Guardar cambios
		var resultado = DataService.guardar_cliente(cliente)
		
		if resultado > 0:
			print("✅ [TEST] Cliente actualizado correctamente")
			
			# Verificar cambios
			var cliente_actualizado = DataService.obtener_cliente(cliente_id)
			print("📋 [TEST] Datos actualizados:")
			print("  - Nombre: ", cliente_actualizado.get("nombre"))
			print("  - Email: ", cliente_actualizado.get("email"))
			print("  - Notas: ", cliente_actualizado.get("notas"))
		else:
			print("❌ [TEST] Error al actualizar cliente")
	else:
		print("⚠️ [TEST] No hay clientes para actualizar")

func test_eliminar_cliente():
	print("\n🗑️ [TEST] Probando eliminación de cliente...")
	
	# Crear un cliente temporal para eliminar
	var cliente_temp = {
		"nombre": "Cliente Temporal Para Eliminar",
		"telefono": "999999999",
		"email": "temporal@eliminar.com",
		"nif": "99999999Z",
		"direccion": "Dirección temporal",
		"telefono_alt": "",
		"notas": "Para eliminar en prueba",
		"rgpd_consent": 0
	}
	
	var cliente_id = DataService.guardar_cliente(cliente_temp)
	print("📝 [TEST] Cliente temporal creado con ID: ", cliente_id)
	
	if cliente_id > 0:
		# Eliminar el cliente
		var eliminado = DataService.eliminar_cliente(cliente_id)
		
		if eliminado:
			print("✅ [TEST] Cliente eliminado correctamente")
			
			# Verificar que ya no existe
			var cliente_verificacion = DataService.obtener_cliente(cliente_id)
			if cliente_verificacion.is_empty():
				print("✅ [TEST] Verificación: Cliente ya no existe en BD")
			else:
				print("❌ [TEST] Error: Cliente aún existe después de eliminar")
		else:
			print("❌ [TEST] Error al eliminar cliente")
	else:
		print("❌ [TEST] Error: No se pudo crear cliente temporal")
	
	# Mostrar resumen final
	var total_final = DataService.obtener_todos_los_clientes().size()
	print("📊 [TEST] Total clientes final: ", total_final)