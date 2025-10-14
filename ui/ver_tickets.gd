extends Control

# Pantalla para ver la lista de tickets

# Referencias a nodos
@onready var buscar_input: LineEdit = $MainContainer/FiltrosPanel/FiltrosContent/BuscarInput
@onready var estado_option: OptionButton = $MainContainer/FiltrosPanel/FiltrosContent/EstadoOption
@onready var tickets_container: VBoxContainer = $MainContainer/ListaContainer/TicketsScrollContainer/TicketsVBox
@onready var status_label: Label = $MainContainer/StatusPanel/StatusContent/StatusLabel
@onready var contador_label: Label = $MainContainer/StatusPanel/StatusContent/ContadorLabel

# Datos
var todos_los_tickets: Array = []
var tickets_filtrados: Array = []
var timer_busqueda: Timer

func _ready():
	print("🎫 [VER_TICKETS] Inicializando lista de tickets...")
	
	# Configurar filtros
	configurar_estados()
	configurar_busqueda()
	
	# Cargar tickets
	cargar_tickets()
	
	print("✅ [VER_TICKETS] Lista inicializada")

func configurar_estados():
	"""Configura las opciones de filtro por estado"""
	estado_option.clear()
	estado_option.add_item("Todos los estados", -1)
	
	for i in range(AppState.estados_ticket.size()):
		var estado = AppState.estados_ticket[i]
		estado_option.add_item(estado, i)

func configurar_busqueda():
	"""Configura la búsqueda con delay"""
	timer_busqueda = Timer.new()
	timer_busqueda.wait_time = 0.5
	timer_busqueda.one_shot = true
	add_child(timer_busqueda)
	timer_busqueda.timeout.connect(filtrar_tickets)

func cargar_tickets():
	"""Carga todos los tickets desde la base de datos"""
	print("📂 [VER_TICKETS] Cargando tickets desde base de datos...")
	
	status_label.text = "Cargando tickets..."
	
	# Obtener tickets desde DataService
	todos_los_tickets = DataService.obtener_todos_los_tickets()
	
	# Aplicar filtros
	filtrar_tickets()
	
	print("✅ [VER_TICKETS] ", todos_los_tickets.size(), " tickets cargados")

func filtrar_tickets():
	"""Aplica los filtros de búsqueda y estado"""
	var busqueda = buscar_input.text.strip_edges().to_lower()
	var estado_seleccionado = estado_option.get_selected_id()
	
	tickets_filtrados.clear()
	
	for ticket in todos_los_tickets:
		var cumple_busqueda = true
		var cumple_estado = true
		
		# Filtro por búsqueda
		if busqueda != "":
			var texto_ticket = (
				ticket.get("codigo", "").to_lower() + " " +
				ticket.get("cliente_nombre", "").to_lower() + " " +
				ticket.get("equipo_marca", "").to_lower() + " " +
				ticket.get("equipo_modelo", "").to_lower() + " " +
				ticket.get("averia_cliente", "").to_lower()
			)
			cumple_busqueda = texto_ticket.contains(busqueda)
		
		# Filtro por estado
		if estado_seleccionado >= 0:
			var estado_ticket = ticket.get("estado", "Nuevo")
			var estado_filtro = AppState.estados_ticket[estado_seleccionado]
			cumple_estado = (estado_ticket == estado_filtro)
		
		# Agregar si cumple ambos filtros
		if cumple_busqueda and cumple_estado:
			tickets_filtrados.append(ticket)
	
	# Actualizar vista
	actualizar_lista_tickets()

func actualizar_lista_tickets():
	"""Actualiza la lista visual de tickets"""
	# Limpiar contenedor
	for child in tickets_container.get_children():
		child.queue_free()
	
	# Agregar tickets filtrados
	for ticket in tickets_filtrados:
		agregar_ticket_a_lista(ticket)
	
	# Actualizar status
	status_label.text = "Mostrando " + str(tickets_filtrados.size()) + " de " + str(todos_los_tickets.size()) + " tickets"
	contador_label.text = str(tickets_filtrados.size()) + " tickets"

func agregar_ticket_a_lista(ticket: Dictionary):
	"""Crea y agrega un elemento de ticket a la lista"""
	var ticket_panel = Panel.new()
	ticket_panel.custom_minimum_size = Vector2(0, 120)
	
	# Estilo del panel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.2, 1)
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = get_color_estado(ticket.get("estado", "Nuevo"))
	style_box.corner_radius_top_left = 6
	style_box.corner_radius_top_right = 6
	style_box.corner_radius_bottom_right = 6
	style_box.corner_radius_bottom_left = 6
	ticket_panel.add_theme_stylebox_override("panel", style_box)
	
	# Contenido del ticket
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 15
	hbox.offset_top = 10
	hbox.offset_right = -15
	hbox.offset_bottom = -10
	ticket_panel.add_child(hbox)
	
	# Información principal (lado izquierdo)
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	# Línea 1: Código y Cliente
	var linea1 = HBoxContainer.new()
	info_vbox.add_child(linea1)
	
	var codigo_label = Label.new()
	codigo_label.text = "🎫 " + ticket.get("codigo", "SIN-CÓDIGO")
	codigo_label.add_theme_font_size_override("font_size", 16)
	codigo_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1, 1))
	linea1.add_child(codigo_label)
	
	var cliente_label = Label.new()
	cliente_label.text = "👤 " + ticket.get("cliente_nombre", "Cliente no especificado")
	cliente_label.add_theme_font_size_override("font_size", 14)
	cliente_label.add_theme_color_override("font_color", Color(1, 1, 0.7, 1))
	cliente_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linea1.add_child(cliente_label)
	
	# Línea 2: Equipo
	var equipo_text = "💻 " + ticket.get("equipo_tipo", "Equipo") 
	if ticket.get("equipo_marca", "") != "":
		equipo_text += " " + ticket.get("equipo_marca", "")
	if ticket.get("equipo_modelo", "") != "":
		equipo_text += " " + ticket.get("equipo_modelo", "")
	
	var equipo_label = Label.new()
	equipo_label.text = equipo_text
	equipo_label.add_theme_font_size_override("font_size", 14)
	info_vbox.add_child(equipo_label)
	
	# Línea 3: Avería (truncada)
	var averia_text = ticket.get("averia_cliente", "Sin descripción")
	if averia_text.length() > 80:
		averia_text = averia_text.substr(0, 80) + "..."
	
	var averia_label = Label.new()
	averia_label.text = "🔧 " + averia_text
	averia_label.add_theme_font_size_override("font_size", 12)
	averia_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	info_vbox.add_child(averia_label)
	
	# Información de estado (lado derecho)
	var estado_vbox = VBoxContainer.new()
	estado_vbox.custom_minimum_size = Vector2(200, 0)
	hbox.add_child(estado_vbox)
	
	# Estado
	var estado_label = Label.new()
	estado_label.text = get_icono_estado(ticket.get("estado", "Nuevo")) + " " + ticket.get("estado", "Nuevo")
	estado_label.add_theme_font_size_override("font_size", 14)
	estado_label.add_theme_color_override("font_color", get_color_estado(ticket.get("estado", "Nuevo")))
	estado_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	estado_vbox.add_child(estado_label)
	
	# Prioridad
	var prioridad_label = Label.new()
	prioridad_label.text = get_icono_prioridad(ticket.get("prioridad", "Normal")) + " " + ticket.get("prioridad", "Normal")
	prioridad_label.add_theme_font_size_override("font_size", 12)
	prioridad_label.add_theme_color_override("font_color", get_color_prioridad(ticket.get("prioridad", "Normal")))
	prioridad_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	estado_vbox.add_child(prioridad_label)
	
	# Fecha
	var fecha_label = Label.new()
	fecha_label.text = "📅 " + ticket.get("fecha_entrada", "").substr(0, 10)  # Solo la fecha, no la hora
	fecha_label.add_theme_font_size_override("font_size", 12)
	fecha_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	fecha_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	estado_vbox.add_child(fecha_label)
	
	# Botón para ver detalles
	var ver_button = Button.new()
	ver_button.text = "👁️ VER"
	ver_button.custom_minimum_size = Vector2(80, 30)
	ver_button.pressed.connect(func(): ver_detalle_ticket(ticket))
	estado_vbox.add_child(ver_button)
	
	# Agregar al contenedor
	tickets_container.add_child(ticket_panel)

func get_color_estado(estado: String) -> Color:
	match estado:
		"Nuevo": return Color(0.4, 1, 0.4, 1)      # Verde
		"En Progreso": return Color(1, 0.8, 0.4, 1)  # Amarillo
		"Esperando Pieza": return Color(1, 0.6, 0.4, 1)  # Naranja
		"Finalizado": return Color(0.4, 0.8, 1, 1)   # Azul
		"Entregado": return Color(0.8, 0.8, 0.8, 1)  # Gris
		_: return Color(1, 1, 1, 1)  # Blanco por defecto

func get_icono_estado(estado: String) -> String:
	match estado:
		"Nuevo": return "🆕"
		"En Progreso": return "⚙️"
		"Esperando Pieza": return "⏳"
		"Finalizado": return "✅"
		"Entregado": return "📦"
		_: return "❓"

func get_color_prioridad(prioridad: String) -> Color:
	match prioridad:
		"Alta": return Color(1, 0.4, 0.4, 1)      # Rojo
		"Normal": return Color(1, 1, 1, 1)        # Blanco
		"Baja": return Color(0.7, 0.7, 0.7, 1)   # Gris
		_: return Color(1, 1, 1, 1)

func get_icono_prioridad(prioridad: String) -> String:
	match prioridad:
		"Alta": return "🔴"
		"Normal": return "🟡"
		"Baja": return "🟢"
		_: return "⚪"

func ver_detalle_ticket(ticket: Dictionary):
	print("👁️ [VER_TICKETS] Viendo detalle del ticket: ", ticket.get("codigo", ""))
	# Aquí se podría abrir una ventana de detalles del ticket
	# Por ahora, mostrar información en consola
	print("Ticket completo: ", ticket)

# === EVENTOS ===

func _on_nuevo_ticket_pressed():
	print("➕ [VER_TICKETS] Ir a nuevo ticket...")
	Router.ir_a_nuevo_ticket()

func _on_actualizar_pressed():
	print("🔄 [VER_TICKETS] Actualizando lista...")
	cargar_tickets()

func _on_volver_pressed():
	print("🏠 [VER_TICKETS] Volviendo al dashboard...")
	Router.ir_a_dashboard()

func _on_buscar_changed(_text: String):
	timer_busqueda.stop()
	timer_busqueda.start()

func _on_estado_selected(_index: int):
	filtrar_tickets()