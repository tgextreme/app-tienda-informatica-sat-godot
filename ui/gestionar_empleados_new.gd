extends Control

# Gestión completa de empleados - CRUD

# Referencias a nodos
@onready var info_label: Label = $MainContainer/EmployeesPanel/EmployeesContent/InfoLabel
@onready var employees_list: VBoxContainer = $MainContainer/EmployeesPanel/EmployeesContent/EmployeesScroll/EmployeesList
@onready var search_input: LineEdit = $MainContainer/ToolsPanel/ToolsContent/SearchContainer/SearchInput
@onready var nuevo_btn: Button = get_node_or_null("MainContainer/ToolsPanel/ToolsContent/ActionContainer/NuevoBtn")
@onready var refresh_btn: Button = $MainContainer/ToolsPanel/ToolsContent/ActionContainer/RefreshBtn
@onready var volver_btn: Button = $MainContainer/Header/HeaderContent/VolverBtn

# Variables
var todos_los_empleados: Array = []
var empleados_filtrados: Array = []
var nuevo_empleado_dialog: Window

# Filtros de estado
var filtro_estado: String = "todos"  # "todos", "activos", "inactivos"
var btn_todos: Button
var btn_activos: Button
var btn_inactivos: Button

func _ready():
	print("👨‍💼 [GESTIONAR_EMPLEADOS] Inicializando gestión de empleados...")
	
	# Esperar un frame para que los nodos estén listos
	await get_tree().process_frame
	
	# Debug: verificar que todos los nodos existen
	print("📊 [DEBUG] nuevo_btn existe: ", nuevo_btn != null)
	print("📊 [DEBUG] refresh_btn existe: ", refresh_btn != null)
	print("📊 [DEBUG] volver_btn existe: ", volver_btn != null)
	print("📊 [DEBUG] search_input existe: ", search_input != null)
	
	# Si algún nodo crítico no existe, intentar crearlo
	if nuevo_btn == null:
		crear_boton_nuevo()
	if volver_btn == null:
		crear_boton_volver()
	
	# Esperar otro frame después de crear botones
	await get_tree().process_frame
	
	configurar_estilo()
	crear_filtros_estado()
	conectar_señales()
	verificar_permisos_admin()
	cargar_empleados()
	
	# Agregar botón de emergencia en la esquina si todo falla
	agregar_boton_emergencia()

func conectar_señales():
	"""Conecta las señales de los botones y campos"""
	# Desconectar señales existentes primero para evitar duplicados
	if nuevo_btn:
		if nuevo_btn.pressed.is_connected(_on_nuevo_empleado_pressed):
			nuevo_btn.pressed.disconnect(_on_nuevo_empleado_pressed)
		nuevo_btn.pressed.connect(_on_nuevo_empleado_pressed)
	
	if refresh_btn:
		if refresh_btn.pressed.is_connected(_on_actualizar_pressed):
			refresh_btn.pressed.disconnect(_on_actualizar_pressed)
		refresh_btn.pressed.connect(_on_actualizar_pressed)
	
	if volver_btn:
		if volver_btn.pressed.is_connected(_on_volver_pressed):
			volver_btn.pressed.disconnect(_on_volver_pressed)
		volver_btn.pressed.connect(_on_volver_pressed)
	
	if search_input:
		if search_input.text_changed.is_connected(_on_search_changed):
			search_input.text_changed.disconnect(_on_search_changed)
		search_input.text_changed.connect(_on_search_changed)

func verificar_permisos_admin():
	"""Verificar si el usuario actual es admin y mostrar/ocultar botón añadir"""
	print("🔐 [GESTIONAR_EMPLEADOS] Verificando permisos de admin...")
	print("👤 [GESTIONAR_EMPLEADOS] Usuario actual completo: ", AppState.usuario_actual)
	
	# Verificar múltiples formas de detectar admin
	var es_admin = false
	
	if AppState.usuario_actual.has("rol"):
		es_admin = AppState.usuario_actual.rol == "ADMIN"
		print("👤 [GESTIONAR_EMPLEADOS] Verificación por rol: ", AppState.usuario_actual.rol, " -> ", es_admin)
	
	if not es_admin and AppState.usuario_actual.has("rol_id"):
		es_admin = AppState.usuario_actual.rol_id == 1  # ID 1 = ADMIN
		print("👤 [GESTIONAR_EMPLEADOS] Verificación por rol_id: ", AppState.usuario_actual.rol_id, " -> ", es_admin)
	
	if not es_admin and AppState.usuario_actual.has("id"):
		es_admin = AppState.usuario_actual.id == 1  # Usuario ID 1 = admin principal
		print("👤 [GESTIONAR_EMPLEADOS] Verificación por user_id: ", AppState.usuario_actual.id, " -> ", es_admin)
	
	if not es_admin and AppState.usuario_actual.has("email"):
		es_admin = AppState.usuario_actual.email == "admin@tienda-sat.com"  # Email del admin
		print("👤 [GESTIONAR_EMPLEADOS] Verificación por email: ", AppState.usuario_actual.email, " -> ", es_admin)
	
	print("🎭 [GESTIONAR_EMPLEADOS] RESULTADO FINAL - Es admin: ", es_admin)
	
	if es_admin:
		mostrar_boton_nuevo()
	else:
		ocultar_boton_nuevo()

func mostrar_boton_nuevo():
	"""Mostrar el botón de añadir empleado"""
	if nuevo_btn:
		nuevo_btn.visible = true
		nuevo_btn.disabled = false
		print("✅ [GESTIONAR_EMPLEADOS] Botón añadir habilitado para admin")

func ocultar_boton_nuevo():
	"""Ocultar el botón de añadir empleado para usuarios no admin"""
	if nuevo_btn:
		nuevo_btn.visible = false
		nuevo_btn.disabled = true
		print("🚫 [GESTIONAR_EMPLEADOS] Botón añadir oculto para usuario no admin")

func configurar_estilo():
	"""Configura el estilo visual de la interfaz"""
	# Fondo principal
	var background = $Background
	if background:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.12, 1)
		background.add_theme_stylebox_override("panel", style)
	
	# Panel de herramientas
	var tools_panel = $MainContainer/ToolsPanel
	if tools_panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.15, 0.18, 1)
		style.border_width_bottom = 2
		style.border_color = Color(0.4, 0.6, 0.9, 1)
		tools_panel.add_theme_stylebox_override("panel", style)

func cargar_empleados():
	"""Carga todos los empleados desde la base de datos"""
	print("📂 [GESTIONAR_EMPLEADOS] Cargando empleados...")
	
	if not DataService:
		print("❌ [GESTIONAR_EMPLEADOS] DataService no disponible")
		return
	
	var empleados = DataService.obtener_empleados()
	todos_los_empleados = empleados
	empleados_filtrados = empleados.duplicate()
	
	print("✅ [GESTIONAR_EMPLEADOS] ", empleados.size(), " empleados cargados")
	
	actualizar_lista_visual()

func actualizar_lista_visual():
	"""Actualiza la lista visual de empleados"""
	# Limpiar lista actual
	if employees_list:
		for child in employees_list.get_children():
			child.queue_free()
	
	# Actualizar contador
	if info_label:
		info_label.text = "📊 Total de empleados: " + str(empleados_filtrados.size())
	
	# Crear tarjetas de empleados
	for empleado in empleados_filtrados:
		crear_empleado_card(empleado)

func crear_empleado_card(empleado: Dictionary):
	"""Crea una tarjeta visual para un empleado"""
	var card = Panel.new()
	card.custom_minimum_size = Vector2(0, 120)
	
	# Estilo de la tarjeta
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.25, 1)
	style.border_width_left = 4
	style.border_color = Color(0.4, 0.8, 0.4, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override("panel", style)
	
	# Contenedor principal
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 15)
	card.add_child(hbox)
	
	# Información del empleado
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_container)
	
	# Nombre
	var nombre_label = Label.new()
	nombre_label.text = "👨‍💼 " + empleado.get("nombre", "Sin nombre")
	nombre_label.add_theme_font_size_override("font_size", 16)
	nombre_label.add_theme_color_override("font_color", Color.WHITE)
	info_container.add_child(nombre_label)
	
	# Email y rol
	var detalles_container = HBoxContainer.new()
	info_container.add_child(detalles_container)
	
	var email_label = Label.new()
	email_label.text = "✉️ " + empleado.get("email", "Sin email")
	email_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1, 1))
	detalles_container.add_child(email_label)
	
	var separador = Control.new()
	separador.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detalles_container.add_child(separador)
	
	var rol_label = Label.new()
	rol_label.text = "🎭 " + empleado.get("rol_nombre", "Sin rol")
	rol_label.add_theme_color_override("font_color", Color(1, 0.8, 0.4, 1))
	detalles_container.add_child(rol_label)
	
	# Estado - Manejo compatible de bool/int
	var estado_label = Label.new()
	var activo_value = empleado.get("activo", true)
	var activo: bool = false
	
	# Manejar tanto bool como int para compatibilidad
	if activo_value is bool:
		activo = activo_value
	else:
		activo = (int(activo_value) == 1)
	
	estado_label.text = "🟢 ACTIVO" if activo else "🔴 INACTIVO"
	estado_label.add_theme_color_override("font_color", Color(0.4, 1, 0.4, 1) if activo else Color(1, 0.4, 0.4, 1))
	info_container.add_child(estado_label)
	
	# Botones de acción
	var buttons_container = VBoxContainer.new()
	buttons_container.custom_minimum_size = Vector2(120, 0)
	hbox.add_child(buttons_container)
	
	# Botón editar
	var edit_btn = Button.new()
	edit_btn.text = "✏️ EDITAR"
	edit_btn.custom_minimum_size = Vector2(100, 30)
	edit_btn.pressed.connect(_on_editar_empleado.bind(empleado))
	buttons_container.add_child(edit_btn)
	
	# Botón activar/desactivar (solo si no es el admin principal)
	var empleado_id = int(empleado.get("id", 0))
	var es_admin_principal = empleado_id == 1
	
	if not es_admin_principal:
		# Determinar si está activo (compatibilidad bool/int)
		var activo_btn_value = empleado.get("activo", true)
		var esta_activo = (typeof(activo_btn_value) == TYPE_BOOL and activo_btn_value) or (typeof(activo_btn_value) == TYPE_INT and activo_btn_value == 1)
		
		# Botón activar/desactivar
		var toggle_btn = Button.new()
		if esta_activo:
			toggle_btn.text = "🔴 DESACTIVAR"
			toggle_btn.modulate = Color(1, 0.8, 0.6, 1)  # Color naranja suave
		else:
			toggle_btn.text = "🟢 ACTIVAR"
			toggle_btn.modulate = Color(0.6, 1, 0.6, 1)  # Color verde suave
		
		toggle_btn.custom_minimum_size = Vector2(110, 30)
		toggle_btn.pressed.connect(_on_toggle_empleado.bind(empleado))
		buttons_container.add_child(toggle_btn)
		
		# Botón eliminar
		var delete_btn = Button.new()
		delete_btn.text = "🗑️ ELIMINAR"
		delete_btn.custom_minimum_size = Vector2(100, 30)
		delete_btn.modulate = Color(1, 0.6, 0.6, 1)
		delete_btn.pressed.connect(_on_confirmar_eliminar.bind(empleado))
		buttons_container.add_child(delete_btn)
	else:
		# Mostrar label informativo para el admin
		var admin_label = Label.new()
		admin_label.text = "🔒 PROTEGIDO"
		admin_label.add_theme_color_override("font_color", Color(1, 0.8, 0.4, 1))
		admin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		buttons_container.add_child(admin_label)
	
	# Agregar a la lista
	if employees_list:
		employees_list.add_child(card)

func filtrar_empleados(texto_busqueda: String):
	"""Filtra empleados por texto de búsqueda - mantener por compatibilidad"""
	filtrar_empleados_completo(texto_busqueda, filtro_estado)

func filtrar_empleados_completo(texto_busqueda: String, estado: String):
	"""Filtra empleados por texto de búsqueda y estado"""
	empleados_filtrados = []
	
	for empleado in todos_los_empleados:
		# Filtro por estado
		var cumple_estado = true
		if estado != "todos":
			var activo_value = empleado.get("activo", true)
			var esta_activo = (typeof(activo_value) == TYPE_BOOL and activo_value) or (typeof(activo_value) == TYPE_INT and activo_value == 1)
			
			if estado == "activos" and not esta_activo:
				cumple_estado = false
			elif estado == "inactivos" and esta_activo:
				cumple_estado = false
		
		if not cumple_estado:
			continue
		
		# Filtro por texto de búsqueda
		if texto_busqueda.is_empty():
			empleados_filtrados.append(empleado)
		else:
			texto_busqueda = texto_busqueda.to_lower()
			var nombre = empleado.get("nombre", "").to_lower()
			var email = empleado.get("email", "").to_lower()
			var rol = empleado.get("rol_nombre", "").to_lower()
			
			if nombre.contains(texto_busqueda) or email.contains(texto_busqueda) or rol.contains(texto_busqueda):
				empleados_filtrados.append(empleado)
	
	actualizar_lista_visual()

func _on_editar_empleado(empleado: Dictionary):
	"""Abre el formulario para editar un empleado"""
	print("✏️ [GESTIONAR_EMPLEADOS] Editando empleado: ", empleado.get("nombre", ""))
	abrir_formulario_empleado(empleado)

func _on_confirmar_eliminar(empleado: Dictionary):
	"""Muestra confirmación para eliminar empleado"""
	print("🗑️ [GESTIONAR_EMPLEADOS] Confirmando eliminación: ", empleado.get("nombre", ""))
	
	var confirmacion = ConfirmationDialog.new()
	confirmacion.title = "🗑️ ELIMINAR EMPLEADO"
	confirmacion.dialog_text = "¿Está seguro de que desea eliminar al empleado:\n\n👨‍💼 " + empleado.get("nombre", "Sin nombre") + "\n\nEsta acción no se puede deshacer."
	
	get_tree().root.add_child(confirmacion)
	confirmacion.confirmed.connect(_on_eliminar_empleado.bind(empleado))
	confirmacion.popup_centered(Vector2(400, 200))

func _on_eliminar_empleado(empleado: Dictionary):
	"""Elimina un empleado de la base de datos"""
	print("🗑️ [GESTIONAR_EMPLEADOS] Eliminando empleado: ", empleado.get("nombre", ""))
	
	# Protección adicional: verificar que no sea el admin principal
	var empleado_id = int(empleado.get("id", 0))
	if empleado_id == 1:
		print("🔒 [GESTIONAR_EMPLEADOS] Intento de eliminar admin principal - BLOQUEADO")
		mostrar_error("No se puede eliminar al administrador principal del sistema")
		return
	
	if not DataService:
		print("❌ [GESTIONAR_EMPLEADOS] DataService no disponible")
		return
	
	var resultado = DataService.eliminar_empleado(empleado.id)
	
	if resultado.success:
		print("✅ [GESTIONAR_EMPLEADOS] Empleado eliminado correctamente")
		cargar_empleados()  # Recargar lista
		# Limpiar búsqueda
		if search_input:
			search_input.text = ""
	else:
		print("❌ [GESTIONAR_EMPLEADOS] Error al eliminar empleado: ", resultado.message)
		mostrar_error("Error al eliminar empleado: " + resultado.message)

func _on_toggle_empleado(empleado: Dictionary):
	"""Alterna el estado activo/inactivo del empleado"""
	var empleado_id = int(empleado.get("id", 0))
	
	# Proteger admin principal
	if empleado_id == 1:
		print("🔒 [GESTIONAR_EMPLEADOS] Intento de desactivar admin principal - BLOQUEADO")
		mostrar_error("No se puede desactivar al administrador principal del sistema")
		return
	
	if not DataService:
		print("❌ [GESTIONAR_EMPLEADOS] DataService no disponible")
		return
	
	# Determinar estado actual (compatibilidad bool/int)
	var activo_value = empleado.get("activo", true)
	var esta_activo = (typeof(activo_value) == TYPE_BOOL and activo_value) or (typeof(activo_value) == TYPE_INT and activo_value == 1)
	
	var resultado
	if esta_activo:
		# Desactivar empleado
		resultado = DataService.desactivar_empleado(empleado_id)
		if resultado.success:
			print("✅ [GESTIONAR_EMPLEADOS] Empleado desactivado: ", empleado.get("nombre", ""))
		else:
			print("❌ [GESTIONAR_EMPLEADOS] Error al desactivar empleado: ", resultado.message)
			mostrar_error("Error al desactivar empleado: " + resultado.message)
	else:
		# Activar empleado
		resultado = DataService.activar_empleado(empleado_id)
		if resultado.success:
			print("✅ [GESTIONAR_EMPLEADOS] Empleado activado: ", empleado.get("nombre", ""))
		else:
			print("❌ [GESTIONAR_EMPLEADOS] Error al activar empleado: ", resultado.message)
			mostrar_error("Error al activar empleado: " + resultado.message)
	
	# Recargar lista si la operación fue exitosa
	if resultado.success:
		cargar_empleados()

func mostrar_error(mensaje: String):
	"""Muestra un mensaje de error al usuario"""
	print("⚠️ [GESTIONAR_EMPLEADOS] " + mensaje)
	# Aquí puedes agregar una notificación visual si lo deseas

func _on_empleado_creado(empleado_data: Dictionary):
	print("✅ [GESTIONAR_EMPLEADOS] Empleado creado/modificado: ", empleado_data.get("nombre", ""))
	cargar_empleados()  # Recargar la lista
	if nuevo_empleado_dialog:
		nuevo_empleado_dialog.queue_free()

func _on_empleado_modificado(empleado_data: Dictionary):
	_on_empleado_creado(empleado_data)  # Misma lógica

# Funciones de eventos de botones
func _on_nuevo_empleado_pressed():
	"""Abre el diálogo para crear un nuevo empleado"""
	print("➕ [GESTIONAR_EMPLEADOS] Abriendo formulario nuevo empleado...")
	abrir_formulario_empleado()

func _on_volver_pressed():
	"""Vuelve al dashboard"""
	print("🔙 [GESTIONAR_EMPLEADOS] Volviendo al dashboard...")
	if Router:
		Router.ir_a_dashboard()

func _on_search_changed(text: String):
	"""Filtra empleados cuando cambia el texto de búsqueda"""
	filtrar_empleados(text)

func _on_actualizar_pressed():
	"""Recarga la lista de empleados"""
	print("🔄 [GESTIONAR_EMPLEADOS] Actualizando lista de empleados...")
	cargar_empleados()

func crear_boton_nuevo():
	"""Crea el botón NUEVO si no existe"""
	print("🔧 [GESTIONAR_EMPLEADOS] Creando botón NUEVO...")
	
	# Buscar el contenedor de acciones
	var action_container = $MainContainer/ToolsPanel/ToolsContent/ActionContainer
	if action_container == null:
		print("❌ [GESTIONAR_EMPLEADOS] No se encontró ActionContainer")
		return
	
	# Crear el botón
	nuevo_btn = Button.new()
	nuevo_btn.name = "NuevoBtn"
	nuevo_btn.text = "➕ NUEVO"
	nuevo_btn.custom_minimum_size = Vector2(140, 40)
	
	# Agregarlo al contenedor
	action_container.add_child(nuevo_btn)
	
	# Conectar señal
	nuevo_btn.pressed.connect(_on_nuevo_empleado_pressed)
	
	print("✅ [GESTIONAR_EMPLEADOS] Botón NUEVO creado exitosamente")

func crear_boton_volver():
	"""Crea el botón VOLVER si no existe"""
	print("🔧 [GESTIONAR_EMPLEADOS] Creando botón VOLVER...")
	
	# Buscar el contenedor del header
	var header_container = $MainContainer/Header/HeaderContent
	if header_container == null:
		print("❌ [GESTIONAR_EMPLEADOS] No se encontró HeaderContent")
		return
	
	# Crear el botón
	volver_btn = Button.new()
	volver_btn.name = "VolverBtn"
	volver_btn.text = "🔙 VOLVER"
	volver_btn.custom_minimum_size = Vector2(120, 40)
	
	# Agregarlo al contenedor
	header_container.add_child(volver_btn)
	
	# Conectar señal
	volver_btn.pressed.connect(_on_volver_pressed)
	
	print("✅ [GESTIONAR_EMPLEADOS] Botón VOLVER creado exitosamente")

func agregar_boton_emergencia():
	"""Agrega un botón de emergencia para crear empleados si todo lo demás falla"""
	print("🚨 [GESTIONAR_EMPLEADOS] Agregando botón de emergencia...")
	
	# Crear un botón grande y visible en la esquina
	var emergency_btn = Button.new()
	emergency_btn.name = "EmergencyNewBtn"
	emergency_btn.text = "🆘 NUEVO EMPLEADO"
	emergency_btn.size = Vector2(200, 60)
	emergency_btn.position = Vector2(20, 20)
	emergency_btn.add_theme_font_size_override("font_size", 16)
	
	# Agregarlo directamente a este control
	add_child(emergency_btn)
	emergency_btn.z_index = 1000  # Asegurar que esté por encima de todo
	
	# Conectar señal
	emergency_btn.pressed.connect(_on_emergency_nuevo_pressed)
	
	print("✅ [GESTIONAR_EMPLEADOS] Botón de emergencia creado")

func _on_emergency_nuevo_pressed():
	"""Función de emergencia para crear nuevo empleado"""
	print("🚨 [GESTIONAR_EMPLEADOS] ¡Botón de emergencia activado!")
	_on_nuevo_empleado_pressed()

func crear_filtros_estado():
	"""Crea botones de filtro por estado del empleado"""
	var tools_content = get_node_or_null("MainContainer/ToolsPanel/ToolsContent")
	if not tools_content:
		print("❌ [GESTIONAR_EMPLEADOS] No se encontró ToolsContent")
		return
	
	# Crear contenedor de filtros
	var filter_container = HBoxContainer.new()
	filter_container.name = "FilterContainer"
	
	# Crear label
	var filter_label = Label.new()
	filter_label.text = "Estado:"
	filter_label.add_theme_color_override("font_color", Color.WHITE)
	filter_container.add_child(filter_label)
	
	# Botón "Todos"
	btn_todos = Button.new()
	btn_todos.text = "👥 TODOS"
	btn_todos.custom_minimum_size = Vector2(80, 30)
	btn_todos.modulate = Color(0.8, 0.8, 1, 1)  # Azul suave - activo por defecto
	btn_todos.pressed.connect(_on_filtro_todos)
	filter_container.add_child(btn_todos)
	
	# Botón "Activos"
	btn_activos = Button.new()
	btn_activos.text = "🟢 ACTIVOS"
	btn_activos.custom_minimum_size = Vector2(80, 30)
	btn_activos.modulate = Color(0.6, 0.6, 0.6, 1)  # Gris - inactivo
	btn_activos.pressed.connect(_on_filtro_activos)
	filter_container.add_child(btn_activos)
	
	# Botón "Inactivos"
	btn_inactivos = Button.new()
	btn_inactivos.text = "🔴 INACTIVOS"
	btn_inactivos.custom_minimum_size = Vector2(80, 30)
	btn_inactivos.modulate = Color(0.6, 0.6, 0.6, 1)  # Gris - inactivo
	btn_inactivos.pressed.connect(_on_filtro_inactivos)
	filter_container.add_child(btn_inactivos)
	
	# Agregar contenedor después del SearchContainer
	var search_container = tools_content.get_node_or_null("SearchContainer")
	if search_container:
		var index = search_container.get_index()
		tools_content.add_child(filter_container)
		tools_content.move_child(filter_container, index + 1)
	else:
		tools_content.add_child(filter_container)
	
	print("✅ [GESTIONAR_EMPLEADOS] Filtros de estado creados")

func _on_filtro_todos():
	"""Muestra todos los empleados"""
	filtro_estado = "todos"
	actualizar_botones_filtro()
	aplicar_filtros()

func _on_filtro_activos():
	"""Muestra solo empleados activos"""
	filtro_estado = "activos"
	actualizar_botones_filtro()
	aplicar_filtros()

func _on_filtro_inactivos():
	"""Muestra solo empleados inactivos"""
	filtro_estado = "inactivos"
	actualizar_botones_filtro()
	aplicar_filtros()

func actualizar_botones_filtro():
	"""Actualiza el estilo visual de los botones de filtro"""
	if btn_todos:
		btn_todos.modulate = Color(0.8, 0.8, 1, 1) if filtro_estado == "todos" else Color(0.6, 0.6, 0.6, 1)
	if btn_activos:
		btn_activos.modulate = Color(0.6, 1, 0.6, 1) if filtro_estado == "activos" else Color(0.6, 0.6, 0.6, 1)
	if btn_inactivos:
		btn_inactivos.modulate = Color(1, 0.6, 0.6, 1) if filtro_estado == "inactivos" else Color(0.6, 0.6, 0.6, 1)

func aplicar_filtros():
	"""Aplica todos los filtros (búsqueda y estado)"""
	var texto_busqueda = search_input.text if search_input else ""
	filtrar_empleados_completo(texto_busqueda, filtro_estado)

func abrir_formulario_empleado(empleado_data: Dictionary = {}):
	"""Abre el formulario de empleado (crear o editar)"""
	print("📝 [GESTIONAR_EMPLEADOS] Abriendo formulario de empleado...")
	
	var formulario_escena = load("res://ui/nuevo_empleado_new.tscn")
	if formulario_escena == null:
		print("❌ [GESTIONAR_EMPLEADOS] Error cargando escena nuevo_empleado_new.tscn")
		crear_formulario_simple()
		return
	
	var formulario_empleado = formulario_escena.instantiate()
	if formulario_empleado == null:
		print("❌ [GESTIONAR_EMPLEADOS] Error instanciando formulario de empleado")
		crear_formulario_simple()
		return
	
	print("✅ [GESTIONAR_EMPLEADOS] Formulario cargado correctamente")
	
	# Configurar el formulario
	get_tree().root.add_child(formulario_empleado)
	
	# Si hay datos de empleado, es edición
	if not empleado_data.is_empty():
		if formulario_empleado.has_method("cargar_datos_empleado"):
			formulario_empleado.cargar_datos_empleado(empleado_data)
	
	# Conectar señales
	if formulario_empleado.has_signal("empleado_guardado"):
		formulario_empleado.empleado_guardado.connect(_on_empleado_creado)
	
	# Mostrar formulario
	if formulario_empleado.has_method("popup_centered"):
		formulario_empleado.popup_centered(Vector2(800, 650))
	else:
		formulario_empleado.show()
	
	print("✅ [GESTIONAR_EMPLEADOS] Formulario mostrado exitosamente")

func crear_formulario_simple():
	"""Crea un formulario simple si el archivo .tscn no funciona"""
	print("🔧 [GESTIONAR_EMPLEADOS] Creando formulario de emergencia...")
	
	# Crear ventana de diálogo simple
	var dialog = AcceptDialog.new()
	dialog.title = "CREAR NUEVO EMPLEADO"
	dialog.size = Vector2(500, 400)
	
	# Crear contenido básico
	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)
	
	var label = Label.new()
	label.text = "Función de creación de empleados temporalmente simplificada.\nPor favor, añada manualmente en la base de datos."
	vbox.add_child(label)
	
	# Mostrar
	get_tree().root.add_child(dialog)
	dialog.popup_centered()
	
	print("✅ [GESTIONAR_EMPLEADOS] Formulario de emergencia mostrado")