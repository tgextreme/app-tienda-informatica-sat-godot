extends Control

# Gestión completa de empleados - CRUD

# Referencias a nodos
@onready var info_label: Label = $MainContainer/EmployeesPanel/EmployeesContent/InfoLabel
@onready var employees_list: VBoxContainer = $MainContainer/EmployeesPanel/EmployeesContent/EmployeesScroll/EmployeesList
@onready var search_input: LineEdit = $MainContainer/ToolsPanel/ToolsContent/SearchContainer/SearchInput

# Variables
var todos_los_empleados: Array = []
var empleados_filtrados: Array = []
var nuevo_empleado_dialog: AcceptDialog

func _ready():
	print("👨‍💼 [GESTIONAR_EMPLEADOS] Inicializando gestión de empleados...")
	configurar_estilo()
	cargar_empleados()

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
		style.border_color = Color(0.9, 0.7, 0.3, 1)
		tools_panel.add_theme_stylebox_override("panel", style)
	
	# Panel de empleados
	var employees_panel = $MainContainer/EmployeesPanel
	if employees_panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.12, 0.15, 1)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.3, 0.3, 0.4, 1)
		employees_panel.add_theme_stylebox_override("panel", style)

func cargar_empleados():
	"""Carga todos los empleados desde la base de datos"""
	print("📂 [GESTIONAR_EMPLEADOS] Cargando empleados...")
	
	todos_los_empleados = DataService.obtener_todos_los_empleados()
	empleados_filtrados = todos_los_empleados.duplicate()
	
	actualizar_interfaz()

func actualizar_interfaz():
	"""Actualiza la interfaz con los empleados filtrados"""
	# Actualizar contador
	info_label.text = "👨‍💼 Total de empleados: %d (mostrando %d)" % [todos_los_empleados.size(), empleados_filtrados.size()]
	
	# Limpiar lista
	for child in employees_list.get_children():
		child.queue_free()
	
	# Agregar empleados
	for empleado in empleados_filtrados:
		crear_empleado_card(empleado)

func crear_empleado_card(empleado: Dictionary):
	"""Crea una tarjeta visual para mostrar un empleado"""
	var card = Panel.new()
	card.custom_minimum_size = Vector2(0, 140)
	
	# Estilo de la tarjeta
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.18, 0.22, 1)
	style.border_width_left = 3
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	
	# Color del borde según estado del empleado
	if int(empleado.get("activo", 1)) == 1:
		style.border_color = Color(0.3, 0.8, 0.3, 1)  # Verde para activo
	else:
		style.border_color = Color(0.8, 0.3, 0.3, 1)  # Rojo para inactivo
	
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	card.add_theme_stylebox_override("panel", style)
	
	# Contenedor principal
	var main_hbox = HBoxContainer.new()
	main_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_hbox.offset_left = 20
	main_hbox.offset_top = 15
	main_hbox.offset_right = -20
	main_hbox.offset_bottom = -15
	card.add_child(main_hbox)
	
	# Información del empleado
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(info_vbox)
	
	# Nombre y estado
	var nombre_hbox = HBoxContainer.new()
	info_vbox.add_child(nombre_hbox)
	
	var nombre_label = Label.new()
	nombre_label.text = "👨‍💼 " + empleado.get("nombre", "Sin nombre")
	nombre_label.add_theme_font_size_override("font_size", 18)
	nombre_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3, 1))
	nombre_hbox.add_child(nombre_label)
	
	# Estado del empleado
	var estado_label = Label.new()
	if int(empleado.get("activo", 1)) == 1:
		estado_label.text = "✅ ACTIVO"
		estado_label.modulate = Color(0.3, 0.8, 0.3, 1)
	else:
		estado_label.text = "❌ INACTIVO"
		estado_label.modulate = Color(0.8, 0.3, 0.3, 1)
	estado_label.add_theme_font_size_override("font_size", 12)
	nombre_hbox.add_child(estado_label)
	
	# Email
	var email_label = Label.new()
	email_label.text = "✉️ " + empleado.get("email", "Sin email")
	email_label.add_theme_font_size_override("font_size", 14)
	info_vbox.add_child(email_label)
	
	# Rol
	var rol_label = Label.new()
	rol_label.text = "🎭 " + empleado.get("rol_nombre", "Sin rol")
	rol_label.add_theme_font_size_override("font_size", 14)
	rol_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1, 1))
	info_vbox.add_child(rol_label)
	
	# Fecha de creación
	var fecha_label = Label.new()
	var fecha_texto = empleado.get("fecha_creacion", "")
	if fecha_texto != "":
		fecha_label.text = "📅 Registrado: " + fecha_texto.split(" ")[0]  # Solo fecha, sin hora
	else:
		fecha_label.text = "📅 Fecha desconocida"
	fecha_label.add_theme_font_size_override("font_size", 12)
	fecha_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	info_vbox.add_child(fecha_label)
	
	# Botones de acción
	var buttons_vbox = VBoxContainer.new()
	buttons_vbox.custom_minimum_size = Vector2(140, 0)
	main_hbox.add_child(buttons_vbox)
	
	# Botón editar
	var edit_btn = Button.new()
	edit_btn.text = "✏️ EDITAR"
	edit_btn.custom_minimum_size = Vector2(0, 30)
	edit_btn.pressed.connect(func(): editar_empleado(empleado))
	buttons_vbox.add_child(edit_btn)
	
	# Botón activar/desactivar
	var toggle_btn = Button.new()
	if int(empleado.get("activo", 1)) == 1:
		toggle_btn.text = "🚫 DESACTIVAR"
		toggle_btn.modulate = Color(1, 0.6, 0.4, 1)
	else:
		toggle_btn.text = "✅ ACTIVAR"
		toggle_btn.modulate = Color(0.4, 1, 0.6, 1)
	toggle_btn.custom_minimum_size = Vector2(0, 30)
	toggle_btn.pressed.connect(func(): cambiar_estado_empleado(empleado))
	buttons_vbox.add_child(toggle_btn)
	
	# Botón eliminar (solo para admin)
	if AppState.es_admin:
		var delete_btn = Button.new()
		delete_btn.text = "🗑️ ELIMINAR"
		delete_btn.custom_minimum_size = Vector2(0, 30)
		delete_btn.modulate = Color(1, 0.4, 0.4, 1)
		delete_btn.pressed.connect(func(): confirmar_eliminar_empleado(empleado))
		buttons_vbox.add_child(delete_btn)
	
	employees_list.add_child(card)

func filtrar_empleados(filtro: String):
	"""Filtra la lista de empleados según el texto de búsqueda"""
	if filtro.strip_edges() == "":
		empleados_filtrados = todos_los_empleados.duplicate()
	else:
		empleados_filtrados = []
		var filtro_lower = filtro.to_lower()
		
		for empleado in todos_los_empleados:
			var nombre = str(empleado.get("nombre", "")).to_lower()
			var email = str(empleado.get("email", "")).to_lower()
			var rol_nombre = str(empleado.get("rol_nombre", "")).to_lower()
			
			if (nombre.contains(filtro_lower) or 
				email.contains(filtro_lower) or 
				rol_nombre.contains(filtro_lower)):
				empleados_filtrados.append(empleado)
	
	actualizar_interfaz()

func editar_empleado(empleado: Dictionary):
	"""Abre el formulario de edición de empleado"""
	print("✏️ [GESTIONAR_EMPLEADOS] Editando empleado: ", empleado.get("nombre", ""))
	
	# Cargar escena de nuevo empleado para editar
	var nuevo_empleado_scene = load("res://ui/nuevo_empleado.tscn")
	if nuevo_empleado_scene == null:
		print("❌ Error cargando formulario de empleado")
		return
	nuevo_empleado_dialog = nuevo_empleado_scene.instantiate()
	
	# Conectar señales
	nuevo_empleado_dialog.empleado_guardado.connect(_on_empleado_modificado)
	
	# Llenar campos con datos existentes
	await get_tree().process_frame  # Esperar a que se inicialice
	
	if nuevo_empleado_dialog.has_method("cargar_datos_empleado"):
		nuevo_empleado_dialog.cargar_datos_empleado(empleado)
	
	add_child(nuevo_empleado_dialog)
	nuevo_empleado_dialog.popup_centered(Vector2(800, 650))

func cambiar_estado_empleado(empleado: Dictionary):
	"""Cambia el estado activo/inactivo de un empleado"""
	var nuevo_estado = 0 if int(empleado.get("activo", 1)) == 1 else 1
	var accion = "activar" if nuevo_estado == 1 else "desactivar"
	
	var dialog = ConfirmationDialog.new()
	dialog.title = "⚠️ Confirmar Cambio de Estado"
	dialog.dialog_text = "¿Está seguro de que desea %s al empleado?\n\n👨‍💼 %s" % [accion, empleado.get("nombre", "Sin nombre")]
	dialog.get_ok_button().text = "✅ CONFIRMAR"
	dialog.get_cancel_button().text = "❌ CANCELAR"
	
	dialog.confirmed.connect(func():
		DataService.cambiar_estado_empleado(int(empleado.get("id", 0)), nuevo_estado)
		cargar_empleados()  # Recargar la lista
		dialog.queue_free()
	)
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered(Vector2(400, 200))

func confirmar_eliminar_empleado(empleado: Dictionary):
	"""Confirma la eliminación de un empleado"""
	var dialog = ConfirmationDialog.new()
	dialog.title = "⚠️ Confirmar Eliminación"
	dialog.dialog_text = "¿Está seguro de que desea ELIMINAR PERMANENTEMENTE al empleado?\n\n👨‍💼 " + empleado.get("nombre", "Sin nombre") + "\n✉️ " + empleado.get("email", "-") + "\n\n⚠️ ESTA ACCIÓN NO SE PUEDE DESHACER"
	dialog.get_ok_button().text = "🗑️ ELIMINAR"
	dialog.get_cancel_button().text = "❌ CANCELAR"
	
	dialog.confirmed.connect(func():
		eliminar_empleado(empleado)
		dialog.queue_free()
	)
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered(Vector2(450, 250))

func eliminar_empleado(empleado: Dictionary):
	"""Elimina un empleado de la base de datos"""
	print("🗑️ [GESTIONAR_EMPLEADOS] Eliminando empleado: ", empleado.get("nombre", ""))
	
	var empleado_id = int(empleado.get("id", 0))
	if empleado_id > 0:
		var resultado = DataService.eliminar_empleado(empleado_id)
		if resultado:
			print("✅ [GESTIONAR_EMPLEADOS] Empleado eliminado correctamente")
			cargar_empleados()  # Recargar la lista
		else:
			mostrar_error("Error al eliminar el empleado")
	else:
		mostrar_error("ID de empleado inválido")

func mostrar_error(mensaje: String):
	"""Muestra un mensaje de error"""
	var dialog = AcceptDialog.new()
	dialog.title = "❌ Error"
	dialog.dialog_text = mensaje
	add_child(dialog)
	dialog.popup_centered(Vector2(300, 150))
	
	# Auto-eliminar después de mostrar
	dialog.confirmed.connect(func(): dialog.queue_free())

# --- SEÑALES ---

func _on_back_button_pressed():
	print("🏠 [GESTIONAR_EMPLEADOS] Volviendo al menú principal...")
	Router.ir_a_dashboard()

func _on_new_employee_button_pressed():
	print("➕ [GESTIONAR_EMPLEADOS] Creando nuevo empleado...")
	
	# Cargar escena de nuevo empleado
	var nuevo_empleado_scene = load("res://ui/nuevo_empleado.tscn")
	if nuevo_empleado_scene == null:
		print("❌ Error cargando formulario de empleado")
		return
	nuevo_empleado_dialog = nuevo_empleado_scene.instantiate()
	
	# Conectar señales
	nuevo_empleado_dialog.empleado_guardado.connect(_on_empleado_creado)
	
	add_child(nuevo_empleado_dialog)
	nuevo_empleado_dialog.popup_centered(Vector2(800, 650))

func _on_search_input_text_changed(new_text: String):
	filtrar_empleados(new_text)

func _on_refresh_button_pressed():
	print("🔄 [GESTIONAR_EMPLEADOS] Actualizando lista...")
	cargar_empleados()
	search_input.text = ""

func _on_empleado_creado(empleado_data: Dictionary):
	print("✅ [GESTIONAR_EMPLEADOS] Empleado creado/modificado: ", empleado_data.get("nombre", ""))
	cargar_empleados()  # Recargar la lista
	if nuevo_empleado_dialog:
		nuevo_empleado_dialog.queue_free()

func _on_empleado_modificado(empleado_data: Dictionary):
	_on_empleado_creado(empleado_data)  # Misma lógica