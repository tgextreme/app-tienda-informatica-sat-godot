extends Node

# Test de relaciones tipo Foreign Key

func _ready():
	print("🧪 [FK_TEST] Iniciando test de relaciones Foreign Key")
	await get_tree().process_frame  # Esperar que el sistema esté listo
	
	test_foreign_key_validation()
	test_cascade_operations()
	test_relational_queries()

func test_foreign_key_validation():
	print("\n=== TEST 1: Validación de Foreign Keys ===")
	
	# Test: Intentar crear ticket con cliente inexistente
	print("🧪 Intentando crear ticket con cliente_id=999 (no existe)")
	var ticket_invalido = DataService.execute_sql("""
		INSERT INTO tickets (codigo, cliente_id, equipo_tipo, averia_cliente) 
		VALUES (?, ?, ?, ?)
	""", ["TEST-001", 999, "Móvil", "Pantalla rota"])
	
	# Test: Crear ticket con cliente válido
	print("🧪 Intentando crear ticket con cliente_id=1 (existe)")
	var ticket_valido = DataService.execute_sql("""
		INSERT INTO tickets (codigo, cliente_id, equipo_tipo, averia_cliente) 
		VALUES (?, ?, ?, ?)
	""", ["TEST-002", 1, "Móvil", "Batería agotada"])

func test_cascade_operations():
	print("\n=== TEST 2: Operaciones en Cascada ===")
	
	# Obtener cliente con sus tickets
	var cliente_con_tickets = DataService.obtener_cliente_con_tickets(1)
	print("🔗 Cliente 1 tiene ", cliente_con_tickets.get("tickets", []).size(), " tickets")
	
	# Test de eliminación con validación
	var resultado = DataService.eliminar_cliente_con_validacion(1)
	print("🗑️ Resultado eliminación: ", resultado)

func test_relational_queries():
	print("\n=== TEST 3: Consultas Relacionales ===")
	
	# Obtener tickets con información completa
	var tickets_completos = DataService.obtener_tickets_con_cliente_y_tecnico()
	print("📋 Tickets con relaciones: ", tickets_completos.size())
	
	if tickets_completos.size() > 0:
		var primer_ticket = tickets_completos[0]
		print("🎫 Primer ticket completo:")
		print("   - Código: ", primer_ticket.get("codigo", "N/A"))
		print("   - Cliente: ", primer_ticket.get("cliente_nombre", "N/A"))
		print("   - Técnico: ", primer_ticket.get("tecnico_nombre", "N/A"))
	
	# Obtener estadísticas relacionales
	var stats = DataService.obtener_estadisticas_relacionales()
	print("📊 Estadísticas:")
	print("   - Tickets por cliente: ", stats.get("tickets_por_cliente", []).size())
	print("   - Tickets por técnico: ", stats.get("tickets_por_tecnico", []).size())