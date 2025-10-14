extends Control

# Gestión completa de clientes - CRUD

# Referencias a nodos
@onready var info_label: Label = $MainContainer/ClientsPanel/ClientsContent/InfoLabel
@onready var clients_list: VBoxContainer = $MainContainer/ClientsPanel/ClientsContent/ClientsScroll/ClientsList
@onready var search_input: LineEdit = $MainContainer/ToolsPanel/ToolsContent/SearchContainer/SearchInput
@onready var nuevo_btn: Button = get_node_or_null("MainContainer/ToolsPanel/ToolsContent/ActionContainer/NuevoBtn")
@onready var refresh_btn: Button = $MainContainer/ToolsPanel/ToolsContent/ActionContainer/RefreshBtn
@onready var volver_btn: Button = $MainContainer/Header/HeaderContent/VolverBtn

# Variables
var todos_los_clientes: Array = []
var clientes_filtrados: Array = []
var nuevo_cliente_dialog: Window

# Gestión completa de clientes

func _ready():
	print("👥 [GESTIONAR_CLIENTES] Inicializando gestión de clientes...")
	
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
	conectar_señales()
	cargar_clientes()
	
	# Agregar botón de emergencia en la esquina si todo falla
	agregar_boton_emergencia()

func conectar_señales():
	"""Conecta las señales de los botones y campos"""
	# Desconectar señales existentes primero para evitar duplicados
	if nuevo_btn:
		if nuevo_btn.pressed.is_connected(_on_nuevo_cliente_pressed):
			nuevo_btn.pressed.disconnect(_on_nuevo_cliente_pressed)
		nuevo_btn.pressed.connect(_on_nuevo_cliente_pressed)
	
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
	
	# Panel de clientes
	var clients_panel = $MainContainer/ClientsPanel
	if clients_panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.12, 0.15, 1)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.3, 0.3, 0.4, 1)
		clients_panel.add_theme_stylebox_override("panel", style)

func cargar_clientes():
	"""Carga todos los clientes desde la base de datos"""
	print("📂 [GESTIONAR_CLIENTES] Cargando clientes...")
	
	todos_los_clientes = DataService.obtener_todos_los_clientes()
	clientes_filtrados = todos_los_clientes.duplicate()
	
	actualizar_interfaz()

func actualizar_interfaz():
	"""Actualiza la interfaz con los clientes filtrados"""
	# Actualizar contador
	info_label.text = "📊 Total de clientes: %d (mostrando %d)" % [todos_los_clientes.size(), clientes_filtrados.size()]
	
	# Limpiar lista
	for child in clients_list.get_children():
		child.queue_free()
	
	# Agregar clientes
	for cliente in clientes_filtrados:
		crear_cliente_card(cliente)

func crear_cliente_card(cliente: Dictionary):
	"""Crea una tarjeta visual para mostrar un cliente"""
	var card = Panel.new()
	card.custom_minimum_size = Vector2(0, 120)
	
	# Estilo de la tarjeta
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.18, 0.22, 1)
	style.border_width_left = 3
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.4, 0.6, 0.9, 1)
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
	
	# Información del cliente
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(info_vbox)
	
	# Nombre
	var nombre_label = Label.new()
	var nombre = str(cliente.get("nombre", "Sin nombre")) if cliente.get("nombre") != null else "Sin nombre"
	nombre_label.text = "👤 " + nombre
	nombre_label.add_theme_font_size_override("font_size", 18)
	nombre_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1, 1))
	info_vbox.add_child(nombre_label)
	
	# Contacto
	var contacto_label = Label.new()
	var telefono = str(cliente.get("telefono", "-")) if cliente.get("telefono") != null else "-"
	var email = str(cliente.get("email", "-")) if cliente.get("email") != null else "-"
	contacto_label.text = "📞 " + telefono + "  ✉️ " + email
	contacto_label.add_theme_font_size_override("font_size", 14)
	info_vbox.add_child(contacto_label)
	
	# NIF y fecha
	var extra_label = Label.new()
	var nif_text = str(cliente.get("nif", "")) if cliente.get("nif") != null else ""
	var fecha_text = str(cliente.get("fecha_registro", "")) if cliente.get("fecha_registro") != null else ""
	if nif_text != "":
		extra_label.text = "🆔 " + nif_text
	if fecha_text != "":
		var fecha_solo = fecha_text.split("T")[0] if fecha_text.find("T") != -1 else fecha_text
		if extra_label.text != "":
			extra_label.text += "  📅 " + fecha_solo
		else:
			extra_label.text = "📅 " + fecha_solo
	extra_label.add_theme_font_size_override("font_size", 12)
	extra_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	info_vbox.add_child(extra_label)
	
	# Botones de acción
	var buttons_vbox = VBoxContainer.new()
	buttons_vbox.custom_minimum_size = Vector2(140, 0)
	main_hbox.add_child(buttons_vbox)
	
	# Botón editar
	var edit_btn = Button.new()
	edit_btn.text = "✏️ EDITAR"
	edit_btn.custom_minimum_size = Vector2(0, 30)
	edit_btn.pressed.connect(func(): editar_cliente(cliente))
	buttons_vbox.add_child(edit_btn)
	
	# Botón eliminar
	var delete_btn = Button.new()
	delete_btn.text = "🗑️ ELIMINAR"
	delete_btn.custom_minimum_size = Vector2(0, 30)
	delete_btn.modulate = Color(1, 0.4, 0.4, 1)
	delete_btn.pressed.connect(func(): eliminar_cliente(cliente))
	buttons_vbox.add_child(delete_btn)
	
	clients_list.add_child(card)

func filtrar_clientes(filtro: String):
	"""Filtra la lista de clientes según el texto de búsqueda"""
	if filtro.strip_edges() == "":
		clientes_filtrados = todos_los_clientes.duplicate()
	else:
		clientes_filtrados = []
		var filtro_lower = filtro.to_lower()
		
		for cliente in todos_los_clientes:
			var nombre = str(cliente.get("nombre", "")).to_lower()
			var telefono = str(cliente.get("telefono", "")).to_lower()
			var email = str(cliente.get("email", "")).to_lower()
			var nif = str(cliente.get("nif", "")).to_lower()
			
			if (nombre.contains(filtro_lower) or 
				telefono.contains(filtro_lower) or 
				email.contains(filtro_lower) or
				nif.contains(filtro_lower)):
				clientes_filtrados.append(cliente)
	
	actualizar_interfaz()

func editar_cliente(cliente: Dictionary):
	"""Abre el formulario de edición de cliente usando Router"""
	print("✏️ [GESTIONAR_CLIENTES] Editando cliente: ", cliente.get("nombre", ""))
	
	var cliente_id = int(cliente.get("id", 0))
	if cliente_id > 0:
		Router.ir_a_cliente_detalle(cliente_id)
	else:
		print("❌ [GESTIONAR_CLIENTES] ID de cliente inválido: ", cliente)

func confirmar_eliminar_cliente(cliente: Dictionary):
	"""Confirma la eliminación de un cliente"""
	var dialog = ConfirmationDialog.new()
	dialog.title = "⚠️ Confirmar Eliminación"
	dialog.dialog_text = "¿Está seguro de que desea eliminar al cliente?\n\n👤 " + cliente.get("nombre", "Sin nombre") + "\n📞 " + cliente.get("telefono", "-")
	dialog.get_ok_button().text = "🗑️ ELIMINAR"
	dialog.get_cancel_button().text = "❌ CANCELAR"
	
	dialog.confirmed.connect(func():
		eliminar_cliente(cliente)
		dialog.queue_free()
	)
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered(Vector2(400, 200))

func eliminar_cliente(cliente: Dictionary):
	"""Elimina un cliente de la base de datos"""
	print("🗑️ [GESTIONAR_CLIENTES] Eliminando cliente: ", cliente.get("nombre", ""))
	
	var cliente_id = int(cliente.get("id", 0))
	if cliente_id > 0:
		var resultado = DataService.eliminar_cliente(cliente_id)
		if resultado:
			print("✅ [GESTIONAR_CLIENTES] Cliente eliminado correctamente")
			cargar_clientes()  # Recargar la lista
		else:
			mostrar_error("Error al eliminar el cliente")
	else:
		mostrar_error("ID de cliente inválido")

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
	print("🏠 [GESTIONAR_CLIENTES] Volviendo al menú principal...")
	Router.ir_a_dashboard()

func _on_new_client_button_pressed():
	print("➕ [GESTIONAR_CLIENTES] Creando nuevo cliente...")
	
	# Cargar escena de nuevo cliente
	var nuevo_cliente_scene = preload("res://ui/nuevo_cliente.tscn")
	nuevo_cliente_dialog = nuevo_cliente_scene.instantiate()
	
	# Conectar señales
	nuevo_cliente_dialog.cliente_creado.connect(_on_cliente_creado)
	
	add_child(nuevo_cliente_dialog)
	nuevo_cliente_dialog.popup_centered(Vector2(800, 600))

func _on_search_input_text_changed(new_text: String):
	filtrar_clientes(new_text)

func _on_refresh_button_pressed():
	print("🔄 [GESTIONAR_CLIENTES] Actualizando lista...")
	cargar_clientes()
	search_input.text = ""

func _on_cliente_creado(cliente_data: Dictionary):
	print("✅ [GESTIONAR_CLIENTES] Cliente creado/modificado: ", cliente_data.get("nombre", ""))
	cargar_clientes()  # Recargar la lista
	if nuevo_cliente_dialog:
		nuevo_cliente_dialog.queue_free()

func _on_cliente_modificado(cliente_data: Dictionary):
	_on_cliente_creado(cliente_data)  # Misma lógica

# Funciones de eventos de botones
func _on_nuevo_cliente_pressed():
	"""Abre el diálogo para crear un nuevo cliente"""
	print("➕ [GESTIONAR_CLIENTES] Abriendo formulario nuevo cliente...")
	abrir_formulario_cliente()

func _on_volver_pressed():
	"""Vuelve al dashboard"""
	print("🔙 [GESTIONAR_CLIENTES] Volviendo al dashboard...")
	if Router:
		Router.ir_a_dashboard()

func _on_search_changed(text: String):
	"""Filtra clientes cuando cambia el texto de búsqueda"""
	filtrar_clientes(text)

func _on_actualizar_pressed():
	"""Recarga la lista de clientes"""
	print("🔄 [GESTIONAR_CLIENTES] Actualizando lista de clientes...")
	cargar_clientes()

func crear_boton_nuevo():
	"""Crea el botón NUEVO si no existe"""
	print("🔧 [GESTIONAR_CLIENTES] Creando botón NUEVO...")
	
	# Buscar el contenedor de acciones
	var action_container = $MainContainer/ToolsPanel/ToolsContent/ActionContainer
	if action_container == null:
		print("❌ [GESTIONAR_CLIENTES] No se encontró ActionContainer")
		return
	
	# Crear el botón
	nuevo_btn = Button.new()
	nuevo_btn.name = "NuevoBtn"
	nuevo_btn.text = "➕ NUEVO"
	nuevo_btn.custom_minimum_size = Vector2(140, 40)
	
	# Agregarlo al contenedor
	action_container.add_child(nuevo_btn)
	
	# Conectar señal
	nuevo_btn.pressed.connect(_on_nuevo_cliente_pressed)
	
	print("✅ [GESTIONAR_CLIENTES] Botón NUEVO creado exitosamente")

func crear_boton_volver():
	"""Crea el botón VOLVER si no existe"""
	print("🔧 [GESTIONAR_CLIENTES] Creando botón VOLVER...")
	
	# Buscar el contenedor del header
	var header_container = $MainContainer/Header/HeaderContent
	if header_container == null:
		print("❌ [GESTIONAR_CLIENTES] No se encontró HeaderContent")
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
	
	print("✅ [GESTIONAR_CLIENTES] Botón VOLVER creado exitosamente")

func agregar_boton_emergencia():
	"""Agrega un botón de emergencia para crear clientes si todo lo demás falla"""
	print("🚨 [GESTIONAR_CLIENTES] Agregando botón de emergencia...")
	
	# Crear un botón grande y visible en la esquina
	var emergency_btn = Button.new()
	emergency_btn.name = "EmergencyNewBtn"
	emergency_btn.text = "🆘 NUEVO CLIENTE"
	emergency_btn.size = Vector2(200, 60)
	emergency_btn.position = Vector2(20, 20)
	emergency_btn.add_theme_font_size_override("font_size", 16)
	
	# Agregarlo directamente a este control
	add_child(emergency_btn)
	emergency_btn.z_index = 1000  # Asegurar que esté por encima de todo
	
	# Conectar señal
	emergency_btn.pressed.connect(_on_emergency_nuevo_pressed)
	
	print("✅ [GESTIONAR_CLIENTES] Botón de emergencia creado")

func _on_emergency_nuevo_pressed():
	"""Función de emergencia para crear nuevo cliente"""
	print("🚨 [GESTIONAR_CLIENTES] ¡Botón de emergencia activado!")
	_on_nuevo_cliente_pressed()

func abrir_formulario_cliente(cliente_data: Dictionary = {}):
	"""Abre el formulario de cliente (crear o editar)"""
	print("📝 [GESTIONAR_CLIENTES] Abriendo formulario de cliente...")
	
	var formulario_escena = load("res://ui/nuevo_cliente.tscn")
	if formulario_escena == null:
		print("❌ [GESTIONAR_CLIENTES] Error cargando escena nuevo_cliente.tscn")
		crear_formulario_simple()
		return
	
	var formulario_cliente = formulario_escena.instantiate()
	if formulario_cliente == null:
		print("❌ [GESTIONAR_CLIENTES] Error instanciando formulario de cliente")
		crear_formulario_simple()
		return
	
	print("✅ [GESTIONAR_CLIENTES] Formulario cargado correctamente")
	
	# Configurar el formulario
	get_tree().root.add_child(formulario_cliente)
	
	# Si hay datos de cliente, es edición
	if not cliente_data.is_empty():
		if formulario_cliente.has_method("cargar_datos_cliente"):
			formulario_cliente.cargar_datos_cliente(cliente_data)
	
	# Conectar señales
	if formulario_cliente.has_signal("cliente_creado"):
		formulario_cliente.cliente_creado.connect(_on_cliente_creado)
	
	# Mostrar formulario
	if formulario_cliente.has_method("popup_centered"):
		formulario_cliente.popup_centered(Vector2(800, 600))
	else:
		formulario_cliente.show()
	
	print("✅ [GESTIONAR_CLIENTES] Formulario mostrado exitosamente")

func crear_formulario_simple():
	"""Crea un formulario simple si el archivo .tscn no funciona"""
	print("🔧 [GESTIONAR_CLIENTES] Creando formulario de emergencia...")
	
	# Crear ventana de diálogo simple
	var dialog = AcceptDialog.new()
	dialog.title = "CREAR NUEVO CLIENTE"
	dialog.size = Vector2(500, 400)
	
	# Crear contenido básico
	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)
	
	var label = Label.new()
	label.text = "Función de creación de clientes temporalmente simplificada.\nPor favor, añada manualmente en la base de datos."
	vbox.add_child(label)
	
	# Mostrar
	get_tree().root.add_child(dialog)
	dialog.popup_centered()
	
	print("✅ [GESTIONAR_CLIENTES] Formulario de emergencia mostrado")
