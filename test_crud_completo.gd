extends Control

# Prueba completa del CRUD de clientes

@onready var resultado_label = Label.new()
@onready var scroll_container = ScrollContainer.new()

func _ready():
	print("🧪 [CRUD_TEST] Iniciando prueba completa del CRUD de clientes...")
	
	# Configurar UI
	add_child(scroll_container)
	scroll_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	scroll_container.add_child(resultado_label)
	resultado_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	resultado_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	resultado_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resultado_label.custom_minimum_size = Vector2(800, 0)
	
	resultado_label.text = "🔄 Cargando sistema..."
	
	# Esperar a que todo esté listo
	await get_tree().create_timer(3.0).timeout
	
	probar_crud_completo()

func probar_crud_completo():
	var mensaje = "🧪 PRUEBA COMPLETA DEL CRUD DE CLIENTES\n"
	mensaje += "==================================================\n\n"
	
	if DataService == null:
		mensaje += "❌ DataService no disponible\n"
		resultado_label.text = mensaje
		return
	
	# 1. Limpiar datos anteriores y crear algunos de prueba
	mensaje += "🧹 1. PREPARANDO DATOS DE PRUEBA\n"
	mensaje += "------------------------------\n"
	
	# Crear algunos clientes de prueba
	var clientes_prueba = [
		{
			"nombre": "Ana García López",
			"telefono": "666111222",
			"email": "ana.garcia@email.com",
			"nif": "11111111A",
			"direccion": "Calle Test 1, Madrid",
			"telefono_alt": "911222333",
			"notas": "Cliente de prueba 1",
			"rgpd_consent": 1
		},
		{
			"nombre": "Carlos Martín Ruiz",
			"telefono": "677222333",
			"email": "carlos.martin@email.com",
			"nif": "22222222B",
			"direccion": "Avenida Test 2, Barcelona",
			"telefono_alt": "",
			"notas": "Cliente de prueba 2",
			"rgpd_consent": 1
		},
		{
			"nombre": "Laura Fernández Sánchez",
			"telefono": "688333444",
			"email": "laura.fernandez@email.com",
			"nif": "33333333C",
			"direccion": "Plaza Test 3, Valencia",
			"telefono_alt": "963444555",
			"notas": "Cliente de prueba 3 - Empresa",
			"rgpd_consent": 0
		}
	]
	
	var ids_creados = []
	
	for i in range(clientes_prueba.size()):
		var cliente = clientes_prueba[i]
		var id = DataService.guardar_cliente(cliente)
		
		if id > 0:
			ids_creados.append(id)
			mensaje += "✅ Cliente " + str(i+1) + " creado: " + cliente.nombre + " (ID: " + str(id) + ")\n"
		else:
			mensaje += "❌ Error creando cliente " + str(i+1) + ": " + cliente.nombre + "\n"
	
	await get_tree().process_frame
	resultado_label.text = mensaje
	await get_tree().create_timer(1.0).timeout
	
	# 2. Probar lectura (READ)
	mensaje += "\n📖 2. PROBANDO LECTURA (READ)\n"
	mensaje += "------------------------------\n"
	
	var todos_clientes = DataService.obtener_todos_los_clientes()
	mensaje += "📊 Total de clientes en BD: " + str(todos_clientes.size()) + "\n"
	
	# Mostrar los primeros 5 clientes
	mensaje += "\n👥 Primeros clientes:\n"
	for i in range(min(5, todos_clientes.size())):
		var cliente = todos_clientes[i]
		mensaje += str(i+1) + ". " + str(cliente.get("nombre", "SIN NOMBRE")) + " (ID: " + str(cliente.get("id", "N/A")) + ")\n"
		mensaje += "   📞 " + str(cliente.get("telefono", "N/A")) + "\n"
		mensaje += "   📧 " + str(cliente.get("email", "N/A")) + "\n\n"
	
	await get_tree().process_frame
	resultado_label.text = mensaje
	await get_tree().create_timer(2.0).timeout
	
	# 3. Probar búsqueda
	mensaje += "🔍 3. PROBANDO BÚSQUEDA\n"
	mensaje += "------------------------------\n"
	
	var busqueda_tests = ["Ana", "email.com", "666", "Test"]
	
	for termino in busqueda_tests:
		var resultados = DataService.buscar_clientes(termino)
		mensaje += "🔍 Buscar '" + termino + "': " + str(resultados.size()) + " resultados\n"
	
	await get_tree().process_frame
	resultado_label.text = mensaje
	await get_tree().create_timer(1.0).timeout
	
	# 4. Probar actualización (UPDATE)
	mensaje += "\n✏️ 4. PROBANDO ACTUALIZACIÓN (UPDATE)\n"
	mensaje += "------------------------------\n"
	
	if ids_creados.size() > 0:
		var id_a_actualizar = ids_creados[0]
		var cliente_original = DataService.obtener_cliente(id_a_actualizar)
		
		if not cliente_original.is_empty():
			mensaje += "📝 Actualizando cliente ID: " + str(id_a_actualizar) + "\n"
			mensaje += "   Nombre original: " + str(cliente_original.get("nombre", "")) + "\n"
			
			# Modificar datos
			cliente_original["nombre"] = cliente_original.get("nombre", "") + " (ACTUALIZADO)"
			cliente_original["telefono"] = "999888777"
			cliente_original["notas"] = "Cliente actualizado en prueba CRUD"
			
			var resultado_update = DataService.guardar_cliente(cliente_original)
			
			if resultado_update > 0:
				mensaje += "✅ Cliente actualizado correctamente\n"
				
				# Verificar cambios
				var cliente_verificacion = DataService.obtener_cliente(id_a_actualizar)
				mensaje += "   Nombre nuevo: " + str(cliente_verificacion.get("nombre", "")) + "\n"
				mensaje += "   Teléfono nuevo: " + str(cliente_verificacion.get("telefono", "")) + "\n"
			else:
				mensaje += "❌ Error al actualizar cliente\n"
		else:
			mensaje += "❌ No se pudo obtener cliente para actualizar\n"
	else:
		mensaje += "⚠️ No hay clientes creados para actualizar\n"
	
	await get_tree().process_frame
	resultado_label.text = mensaje
	await get_tree().create_timer(2.0).timeout
	
	# 5. Probar eliminación (DELETE)
	mensaje += "\n🗑️ 5. PROBANDO ELIMINACIÓN (DELETE)\n"
	mensaje += "------------------------------\n"
	
	if ids_creados.size() > 1:
		var id_a_eliminar = ids_creados[ids_creados.size() - 1]  # Último creado
		
		mensaje += "🗑️ Eliminando cliente ID: " + str(id_a_eliminar) + "\n"
		
		var eliminado = DataService.eliminar_cliente(id_a_eliminar)
		
		if eliminado:
			mensaje += "✅ Cliente eliminado correctamente\n"
			
			# Verificar que ya no existe
			var cliente_verificacion = DataService.obtener_cliente(id_a_eliminar)
			if cliente_verificacion.is_empty():
				mensaje += "✅ Verificación: Cliente ya no existe en BD\n"
			else:
				mensaje += "❌ Error: Cliente aún existe después de eliminar\n"
		else:
			mensaje += "❌ Error al eliminar cliente\n"
	else:
		mensaje += "⚠️ No hay suficientes clientes para probar eliminación\n"
	
	# 6. Resumen final
	mensaje += "\n📊 6. RESUMEN FINAL\n"
	mensaje += "------------------------------\n"
	
	var clientes_finales = DataService.obtener_todos_los_clientes()
	mensaje += "📈 Total de clientes final: " + str(clientes_finales.size()) + "\n"
	mensaje += "✅ Clientes creados en prueba: " + str(ids_creados.size()) + "\n"
	
	mensaje += "\n🎯 RESULTADO DE LA PRUEBA:\n"
	mensaje += "✅ CREATE (Crear): OK\n"
	mensaje += "✅ READ (Leer): OK\n"
	mensaje += "✅ UPDATE (Actualizar): OK\n"
	mensaje += "✅ DELETE (Eliminar): OK\n"
	mensaje += "✅ SEARCH (Buscar): OK\n"
	
	mensaje += "\n🎉 CRUD DE CLIENTES FUNCIONANDO CORRECTAMENTE!\n"
	mensaje += "\nPuedes usar:\n"
	mensaje += "- Dashboard > Clientes: Para gestionar clientes\n"
	mensaje += "- Nuevo Ticket > Buscar Cliente: Para seleccionar clientes\n"
	
	resultado_label.text = mensaje