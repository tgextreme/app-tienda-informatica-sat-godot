extends Node

"""
Test para verificar que los usuarios no-admin no pueden acceder a empleados
"""

func _ready():
	print("🧪 [TEST_PERMISOS_EMPLEADOS] Iniciando test de permisos...")
	
	# Esperar a que DataService esté listo
	if not DataService.db:
		print("⏳ [TEST_PERMISOS_EMPLEADOS] Esperando DataService...")
		await get_tree().create_timer(2.0).timeout
	
	# Test 1: Usuario técnico no debería poder navegar a empleados
	await test_usuario_tecnico()
	
	# Test 2: Usuario admin sí debería poder navegar a empleados
	await test_usuario_admin()
	
	print("✅ [TEST_PERMISOS_EMPLEADOS] Todos los tests completados")

func test_usuario_tecnico():
	print("\n🔒 [TEST_PERMISOS_EMPLEADOS] Test 1: Usuario Técnico")
	print("   - Email: user@mail.com")
	print("   - Rol: TECNICO (rol_id = 2)")
	print("   - Debería: NO poder acceder a empleados")
	
	# Login como técnico
	var login_ok = AppState.login("user@mail.com", "123456")
	if not login_ok:
		print("❌ [TEST_PERMISOS_EMPLEADOS] Error: No se pudo hacer login como técnico")
		return
	
	print("✅ [TEST_PERMISOS_EMPLEADOS] Login técnico exitoso")
	print("   - Usuario actual: ", AppState.usuario_actual)
	print("   - Es admin: ", AppState.es_admin)
	print("   - Es técnico: ", AppState.es_tecnico)
	
	# Verificar que Router no permita navegación a empleados
	var puede_navegar = Router.puede_navegar_a("empleados_lista")
	if puede_navegar:
		print("❌ [TEST_PERMISOS_EMPLEADOS] ERROR: Técnico PUEDE navegar a empleados (debería estar bloqueado)")
	else:
		print("✅ [TEST_PERMISOS_EMPLEADOS] Correcto: Técnico NO puede navegar a empleados")
	
	# Verificar que el botón de empleados no esté visible en dashboard
	# (Esto se verificaría en la interfaz, aquí solo podemos verificar el estado)
	if AppState.es_admin:
		print("❌ [TEST_PERMISOS_EMPLEADOS] ERROR: Técnico marcado como admin")
	else:
		print("✅ [TEST_PERMISOS_EMPLEADOS] Correcto: Técnico no marcado como admin")
	
	AppState.logout()

func test_usuario_admin():
	print("\n🔑 [TEST_PERMISOS_EMPLEADOS] Test 2: Usuario Admin")
	print("   - Email: admin@tienda-sat.com")
	print("   - Rol: ADMIN (rol_id = 1)")
	print("   - Debería: SÍ poder acceder a empleados")
	
	# Login como admin
	var login_ok = AppState.login("admin@tienda-sat.com", "admin123")
	if not login_ok:
		print("❌ [TEST_PERMISOS_EMPLEADOS] Error: No se pudo hacer login como admin")
		return
	
	print("✅ [TEST_PERMISOS_EMPLEADOS] Login admin exitoso")
	print("   - Usuario actual: ", AppState.usuario_actual)
	print("   - Es admin: ", AppState.es_admin)
	print("   - Es técnico: ", AppState.es_tecnico)
	
	# Verificar que Router SÍ permita navegación a empleados
	var puede_navegar = Router.puede_navegar_a("empleados_lista")
	if puede_navegar:
		print("✅ [TEST_PERMISOS_EMPLEADOS] Correcto: Admin PUEDE navegar a empleados")
	else:
		print("❌ [TEST_PERMISOS_EMPLEADOS] ERROR: Admin NO puede navegar a empleados (debería poder)")
	
	# Verificar que esté marcado como admin
	if AppState.es_admin:
		print("✅ [TEST_PERMISOS_EMPLEADOS] Correcto: Admin marcado como admin")
	else:
		print("❌ [TEST_PERMISOS_EMPLEADOS] ERROR: Admin NO marcado como admin")
	
	AppState.logout()