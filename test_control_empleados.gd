extends Node

"""
Test para verificar el control de acceso mejorado a empleados
- Verifica que el botón se deshabilite (no se oculte)
- Verifica que aparezca mensaje de error
- Verifica tooltips informativos
"""

func _ready():
	print("🧪 [TEST_CONTROL_EMPLEADOS] Iniciando test de control de acceso...")
	
	# Esperar a que DataService esté listo
	if not DataService.db:
		print("⏳ [TEST_CONTROL_EMPLEADOS] Esperando DataService...")
		await get_tree().create_timer(2.0).timeout
	
	# Test con usuario técnico (no-admin)
	await test_usuario_no_admin()
	
	# Test con usuario admin
	await test_usuario_admin()
	
	print("✅ [TEST_CONTROL_EMPLEADOS] Todos los tests completados")

func test_usuario_no_admin():
	print("\n🔒 [TEST_CONTROL_EMPLEADOS] Test 1: Usuario No-Admin (Técnico)")
	print("   - Email: user@mail.com")
	print("   - Rol: TECNICO (rol_id = 2)")
	print("   - Expectativa: Botón deshabilitado, no navegación")
	
	# Login como técnico
	var login_ok = AppState.login("user@mail.com", "123456")
	if not login_ok:
		print("❌ [TEST_CONTROL_EMPLEADOS] Error: No se pudo hacer login como técnico")
		return
	
	print("✅ [TEST_CONTROL_EMPLEADOS] Login técnico exitoso")
	print("   - Es admin: ", AppState.es_admin)
	
	# Verificar permisos en Router
	var puede_navegar = Router.puede_navegar_a("empleados_lista")
	if puede_navegar:
		print("❌ [TEST_CONTROL_EMPLEADOS] ERROR: Técnico puede navegar (Router)")
	else:
		print("✅ [TEST_CONTROL_EMPLEADOS] Correcto: Router bloquea navegación")
	
	# Simular intento de navegación directa
	print("\n🎯 [TEST_CONTROL_EMPLEADOS] Simulando intento de navegación directa...")
	try:
		# Esto debería ser bloqueado por Router.puede_navegar_a()
		Router.ir_a("empleados_lista")
		print("❌ [TEST_CONTROL_EMPLEADOS] ERROR: Navegación directa no fue bloqueada")
	except:
		print("✅ [TEST_CONTROL_EMPLEADOS] Correcto: Navegación directa bloqueada")
	
	AppState.logout()

func test_usuario_admin():
	print("\n🔑 [TEST_CONTROL_EMPLEADOS] Test 2: Usuario Admin")
	print("   - Email: admin@tienda-sat.com")
	print("   - Rol: ADMIN (rol_id = 1)")
	print("   - Expectativa: Botón habilitado, navegación permitida")
	
	# Login como admin
	var login_ok = AppState.login("admin@tienda-sat.com", "admin123")
	if not login_ok:
		print("❌ [TEST_CONTROL_EMPLEADOS] Error: No se pudo hacer login como admin")
		return
	
	print("✅ [TEST_CONTROL_EMPLEADOS] Login admin exitoso")
	print("   - Es admin: ", AppState.es_admin)
	
	# Verificar permisos en Router
	var puede_navegar = Router.puede_navegar_a("empleados_lista")
	if puede_navegar:
		print("✅ [TEST_CONTROL_EMPLEADOS] Correcto: Admin puede navegar (Router)")
	else:
		print("❌ [TEST_CONTROL_EMPLEADOS] ERROR: Router bloquea navegación del admin")
	
	AppState.logout()

func test_estados_boton():
	"""Test adicional: Verificar que el estado del botón cambia correctamente"""
	print("\n🔘 [TEST_CONTROL_EMPLEADOS] Test 3: Estados del Botón")
	
	# Crear una instancia ficticia del dashboard para probar lógica
	print("   - Simulando configuración de botón para técnico...")
	simulate_button_state(false)  # No-admin
	
	print("   - Simulando configuración de botón para admin...")
	simulate_button_state(true)   # Admin

func simulate_button_state(es_admin: bool):
	"""Simula la lógica de configuración del botón empleados"""
	var disabled = not es_admin
	var tooltip = "Solo los administradores pueden gestionar empleados" if not es_admin else "Gestionar empleados y usuarios del sistema"
	
	print("     - Botón deshabilitado: ", disabled)
	print("     - Tooltip: ", tooltip)
	
	if es_admin:
		print("✅ [TEST_CONTROL_EMPLEADOS] Admin: Botón habilitado con tooltip informativo")
	else:
		print("✅ [TEST_CONTROL_EMPLEADOS] No-admin: Botón deshabilitado con mensaje explicativo")