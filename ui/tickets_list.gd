extends Control

# Lista de tickets SAT con filtros y búsqueda

@onready var search_input = $VBoxContainer/FiltersContainer/SearchInput
@onready var estado_filter = $VBoxContainer/FiltersContainer/EstadoFilter  
@onready var tecnico_filter = $VBoxContainer/FiltersContainer/TecnicoFilter
@onready var tickets_tree = $VBoxContainer/TicketsTree
@onready var count_label = $VBoxContainer/StatusBar/CountLabel
@onready var new_ticket_button = $VBoxContainer/TopBar/NewTicketButton

var tickets_data: Array = []
var filtros_actuales: Dictionary = {}

func _ready():
	configurar_interfaz()
	configurar_filtros()
	cargar_tickets()

func configurar_interfaz():
	# Configurar permisos
	new_ticket_button.visible = AppState.tiene_permiso("crear_ticket")
	
	# Configurar columnas del tree
	tickets_tree.set_column_title(0, "Código")
	tickets_tree.set_column_title(1, "Cliente")
	tickets_tree.set_column_title(2, "Equipo")
	tickets_tree.set_column_title(3, "Estado")
	tickets_tree.set_column_title(4, "Técnico")
	tickets_tree.set_column_title(5, "Fecha")
	
	tickets_tree.set_column_custom_minimum_width(0, 120)
	tickets_tree.set_column_custom_minimum_width(1, 200)
	tickets_tree.set_column_custom_minimum_width(2, 150)
	tickets_tree.set_column_custom_minimum_width(3, 120)
	tickets_tree.set_column_custom_minimum_width(4, 150)
	tickets_tree.set_column_custom_minimum_width(5, 100)

func configurar_filtros():
	# Filtro de estados
	estado_filter.add_item("Todos los estados", 0)
	for i in range(AppState.estados_ticket.size()):
		estado_filter.add_item(AppState.estados_ticket[i], i + 1)
	
	# Filtro de técnicos
	tecnico_filter.add_item("Todos los técnicos", 0)
	var tecnicos = DataService.obtener_tecnicos()
	for i in range(tecnicos.size()):
		var tecnico = tecnicos[i]
		tecnico_filter.add_item(tecnico.nombre, int(tecnico.id))

func cargar_tickets():
	# Construir filtros de búsqueda
	var filtros = {}
	
	# Filtro de búsqueda general
	if search_input.text.strip_edges() != "":
		filtros["busqueda"] = search_input.text.strip_edges()
	
	# Filtro de estado
	var estado_seleccionado = estado_filter.get_selected_id()
	if estado_seleccionado > 0:
		var estado = AppState.estados_ticket[estado_seleccionado - 1]
		filtros["estado"] = estado
	
	# Filtro de técnico
	var tecnico_seleccionado = tecnico_filter.get_selected_id()
	if tecnico_seleccionado > 0:
		filtros["tecnico_id"] = tecnico_seleccionado
	
	# Aplicar filtros externos si los hay
	if filtros_actuales.size() > 0:
		for clave in filtros_actuales:
			filtros[clave] = filtros_actuales[clave]
	
	# Cargar datos
	tickets_data = DataService.buscar_tickets(filtros)
	actualizar_tree()
	actualizar_contador()

func actualizar_tree():
	tickets_tree.clear()
	var root = tickets_tree.create_item()
	
	# Definir colores por estado
	var colores_estados = {
		"Nuevo": Color(0.3, 0.6, 1.0),
		"Diagnosticando": Color(1.0, 0.8, 0.2),
		"Presupuestado": Color(0.8, 0.4, 1.0),
		"Aprobado": Color(0.2, 1.0, 0.6),
		"En reparación": Color(1.0, 0.6, 0.2),
		"En pruebas": Color(0.6, 1.0, 0.8),
		"Listo para entrega": Color(0.2, 0.8, 0.2),
		"Entregado": Color(0.7, 0.7, 0.7),
		"Rechazado": Color(1.0, 0.4, 0.4),
		"No reparable": Color(0.6, 0.6, 0.6)
	}
	
	for ticket_data in tickets_data:
		var item = tickets_tree.create_item(root)
		
		# Código
		item.set_text(0, ticket_data.get("codigo", ""))
		
		# Cliente
		item.set_text(1, ticket_data.get("cliente_nombre", ""))
		
		# Equipo (tipo + marca/modelo)
		var equipo = str(ticket_data.get("equipo_tipo", ""))
		var marca = str(ticket_data.get("equipo_marca", ""))
		var modelo = str(ticket_data.get("equipo_modelo", ""))
		if marca != "" and marca != "null" and marca != "0":
			equipo += " " + marca
		if modelo != "" and modelo != "null" and modelo != "0":
			equipo += " " + modelo
		item.set_text(2, equipo)
		
		# Estado con color
		var estado = ticket_data.get("estado", "")
		item.set_text(3, estado)
		if colores_estados.has(estado):
			item.set_custom_color(3, colores_estados[estado])
		
		# Técnico
		item.set_text(4, ticket_data.get("tecnico_nombre", "Sin asignar"))
		
		# Fecha (solo la fecha, sin hora)
		var fecha_entrada = ticket_data.get("fecha_entrada", "")
		if fecha_entrada != "":
			var fecha_parts = fecha_entrada.split(" ")
			if fecha_parts.size() > 0:
				item.set_text(5, fecha_parts[0])
		
		# Guardar ID del ticket como metadatos
		item.set_metadata(0, int(ticket_data.get("id", 0)))

func actualizar_contador():
	count_label.text = str(tickets_data.size()) + " ticket(s) encontrado(s)"

func _on_search_button_pressed():
	cargar_tickets()

func _on_search_input_text_submitted(_text: String):
	cargar_tickets()

func _on_estado_filter_item_selected(_index: int):
	cargar_tickets()

func _on_tecnico_filter_item_selected(_index: int):
	cargar_tickets()

func _on_refresh_button_pressed():
	cargar_tickets()

func _on_back_button_pressed():
	Router.ir_a_dashboard()

func _on_new_ticket_button_pressed():
	Router.ir_a_nuevo_ticket()

func _on_tickets_tree_item_activated():
	var selected = tickets_tree.get_selected()
	if selected:
		var ticket_id = selected.get_metadata(0)
		if ticket_id != null and int(ticket_id) > 0:
			Router.ir_a_ticket_detalle(int(ticket_id))

# Configurar la pantalla con parámetros externos
func configurar(parametros: Dictionary):
	if parametros.has("filtros"):
		filtros_actuales = parametros.filtros
		
		# Aplicar filtros a la interfaz
		if filtros_actuales.has("estado"):
			var estado = filtros_actuales.estado
			var index = AppState.estados_ticket.find(estado)
			if index >= 0:
				estado_filter.select(index + 1)
	
	# Cargar datos con filtros aplicados
	if is_node_ready():
		cargar_tickets()

# Método para actualizar desde señales externas
func _on_ticket_guardado(_ticket_id: int):
	cargar_tickets()

func _ready_connections():
	# Conectar señales de DataService
	if DataService.ticket_guardado.connect(_on_ticket_guardado) != OK:
		print("Error conectando señal ticket_guardado")