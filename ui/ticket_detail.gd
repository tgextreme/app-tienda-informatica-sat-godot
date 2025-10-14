extends Control

# Pantalla de detalles del ticket

@onready var codigo_label = $MainContainer/HeaderPanel/HeaderContent/CodigoLabel
@onready var estado_label = $MainContainer/HeaderPanel/HeaderContent/EstadoLabel
@onready var fecha_entrada_label = $MainContainer/HeaderPanel/HeaderContent/FechaEntradaLabel

# Cliente info
@onready var cliente_nombre_label = $MainContainer/ContentContainer/ClientePanel/ClienteContent/NombreLabel
@onready var cliente_telefono_label = $MainContainer/ContentContainer/ClientePanel/ClienteContent/TelefonoLabel
@onready var cliente_email_label = $MainContainer/ContentContainer/ClientePanel/ClienteContent/EmailLabel

# Equipo info
@onready var equipo_tipo_label = $MainContainer/ContentContainer/EquipoPanel/EquipoContent/TipoLabel
@onready var equipo_marca_label = $MainContainer/ContentContainer/EquipoPanel/EquipoContent/MarcaLabel
@onready var equipo_modelo_label = $MainContainer/ContentContainer/EquipoPanel/EquipoContent/ModeloLabel
@onready var equipo_serie_label = $MainContainer/ContentContainer/EquipoPanel/EquipoContent/SerieLabel

# Avería info
@onready var averia_cliente_text = $MainContainer/ContentContainer/AveriaPanel/AveriaContent/ClienteText
@onready var averia_tecnico_text = $MainContainer/ContentContainer/AveriaPanel/AveriaContent/TecnicoText

# Técnico info
@onready var tecnico_label = $MainContainer/ContentContainer/TecnicoPanel/TecnicoContent/TecnicoLabel
@onready var prioridad_label = $MainContainer/ContentContainer/TecnicoPanel/TecnicoContent/PrioridadLabel

# Botones
@onready var editar_button = $MainContainer/ButtonsPanel/ButtonsContent/EditarButton
@onready var exportar_html_button = $MainContainer/ButtonsPanel/ButtonsContent/ExportarHTMLButton
@onready var exportar_pdf_button = $MainContainer/ButtonsPanel/ButtonsContent/ExportarPDFButton
@onready var cambiar_estado_button = $MainContainer/ButtonsPanel/ButtonsContent/CambiarEstadoButton
@onready var asignar_tecnico_button = $MainContainer/ButtonsPanel/ButtonsContent/AsignarTecnicoButton
@onready var volver_button = $MainContainer/ButtonsPanel/ButtonsContent/VolverButton

var ticket_data: Dictionary = {}
var ticket_id: int = 0

func _ready():
	print("🎫 [TICKET_DETAIL] Inicializando detalles del ticket...")
	
	# Configurar permisos
	configurar_permisos()

func configurar_permisos():
	"""Configura los permisos de la interfaz según el usuario"""
	editar_button.visible = AppState.tiene_permiso("editar_ticket")
	
	# Configurar conexiones de botones
	_configurar_conexiones_botones()

func _configurar_conexiones_botones():
	"""Configura las conexiones de los botones"""
	# Desconectar señales previas si existen
	if editar_button.pressed.is_connected(_on_editar_button_pressed):
		editar_button.pressed.disconnect(_on_editar_button_pressed)
	if exportar_html_button.pressed.is_connected(_on_exportar_html_button_pressed):
		exportar_html_button.pressed.disconnect(_on_exportar_html_button_pressed)
	if exportar_pdf_button.pressed.is_connected(_on_exportar_pdf_button_pressed):
		exportar_pdf_button.pressed.disconnect(_on_exportar_pdf_button_pressed)
	if cambiar_estado_button.pressed.is_connected(_on_cambiar_estado_button_pressed):
		cambiar_estado_button.pressed.disconnect(_on_cambiar_estado_button_pressed)
	if asignar_tecnico_button.pressed.is_connected(_on_asignar_tecnico_button_pressed):
		asignar_tecnico_button.pressed.disconnect(_on_asignar_tecnico_button_pressed)
	if volver_button.pressed.is_connected(_on_volver_button_pressed):
		volver_button.pressed.disconnect(_on_volver_button_pressed)
	
	# Conectar señales
	editar_button.pressed.connect(_on_editar_button_pressed)
	exportar_html_button.pressed.connect(_on_exportar_html_button_pressed)
	exportar_pdf_button.pressed.connect(_on_exportar_pdf_button_pressed)
	cambiar_estado_button.pressed.connect(_on_cambiar_estado_button_pressed)
	asignar_tecnico_button.pressed.connect(_on_asignar_tecnico_button_pressed)
	volver_button.pressed.connect(_on_volver_button_pressed)

func configurar(parametros: Dictionary):
	"""Configura la pantalla con los parámetros recibidos"""
	print("🎫 [TICKET_DETAIL] Configurando con parámetros: ", parametros)
	
	if parametros.has("ticket_id"):
		ticket_id = parametros.ticket_id
		cargar_ticket(ticket_id)

func cargar_ticket(id: int):
	"""Carga los datos del ticket desde la base de datos"""
	print("📂 [TICKET_DETAIL] Cargando ticket ID: ", id)
	
	ticket_data = DataService.obtener_ticket_por_id(id)
	
	if ticket_data.is_empty():
		mostrar_error("No se pudo cargar el ticket con ID: " + str(id))
		return
	
	actualizar_interfaz()

func actualizar_interfaz():
	"""Actualiza la interfaz con los datos del ticket"""
	if ticket_data.is_empty():
		return
	
	# Header
	codigo_label.text = ticket_data.get("codigo", "Sin código")
	estado_label.text = ticket_data.get("estado", "Sin estado")
	
	# Aplicar color al estado
	var color_estado = get_color_estado(ticket_data.get("estado", ""))
	estado_label.add_theme_color_override("font_color", color_estado)
	
	fecha_entrada_label.text = formatear_fecha(ticket_data.get("fecha_entrada", ""))
	
	# Cliente
	cliente_nombre_label.text = ticket_data.get("cliente_nombre", "Sin nombre")
	cliente_telefono_label.text = ticket_data.get("cliente_telefono", "Sin teléfono")
	cliente_email_label.text = ticket_data.get("cliente_email", "Sin email")
	
	# Equipo
	equipo_tipo_label.text = ticket_data.get("equipo_tipo", "Sin tipo")
	equipo_marca_label.text = ticket_data.get("equipo_marca", "Sin marca")
	equipo_modelo_label.text = ticket_data.get("equipo_modelo", "Sin modelo")
	equipo_serie_label.text = ticket_data.get("equipo_serie", "Sin serie")
	
	# Avería
	averia_cliente_text.text = ticket_data.get("averia_cliente", "Sin descripción")
	averia_tecnico_text.text = ticket_data.get("diagnostico_tecnico", "Sin diagnóstico")
	
	# Técnico
	var tecnico_nombre = ticket_data.get("tecnico_nombre", "Sin asignar")
	if tecnico_nombre == "":
		tecnico_nombre = "Sin asignar"
	tecnico_label.text = tecnico_nombre
	
	prioridad_label.text = ticket_data.get("prioridad", "Normal")
	var color_prioridad = get_color_prioridad(ticket_data.get("prioridad", "Normal"))
	prioridad_label.add_theme_color_override("font_color", color_prioridad)

func get_color_estado(estado: String) -> Color:
	"""Devuelve el color correspondiente al estado"""
	match estado:
		"Nuevo": return Color(0.3, 0.6, 1.0)
		"Diagnosticando": return Color(1.0, 0.8, 0.2)
		"Presupuestado": return Color(0.8, 0.4, 1.0)
		"Aprobado": return Color(0.2, 1.0, 0.6)
		"En reparación": return Color(1.0, 0.6, 0.2)
		"En pruebas": return Color(0.6, 1.0, 0.8)
		"Listo para entrega": return Color(0.2, 0.8, 0.2)
		"Entregado": return Color(0.7, 0.7, 0.7)
		"Rechazado": return Color(1.0, 0.4, 0.4)
		"No reparable": return Color(0.6, 0.6, 0.6)
		_: return Color(1.0, 1.0, 1.0)

func get_color_prioridad(prioridad: String) -> Color:
	"""Devuelve el color correspondiente a la prioridad"""
	match prioridad:
		"Alta": return Color(1.0, 0.4, 0.4)
		"Normal": return Color(1.0, 1.0, 1.0)
		"Baja": return Color(0.7, 0.7, 0.7)
		_: return Color(1.0, 1.0, 1.0)

func formatear_fecha(fecha_str: String) -> String:
	"""Formatea la fecha para mostrarla de forma legible"""
	if fecha_str == "":
		return "Sin fecha"
	
	# Extraer solo la fecha (sin hora)
	var partes = fecha_str.split(" ")
	if partes.size() > 0:
		return partes[0]
	
	return fecha_str

func mostrar_error(mensaje: String):
	"""Muestra un mensaje de error"""
	print("❌ [TICKET_DETAIL] Error: ", mensaje)
	
	# Mostrar mensaje en la interfaz
	codigo_label.text = "ERROR"
	estado_label.text = mensaje
	estado_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

# === EVENTOS ===

func _on_editar_button_pressed():
	"""Navega a la pantalla de editar ticket"""
	print("✏️ [TICKET_DETAIL] Editando ticket: ", ticket_id)
	Router.ir_a("nuevo_ticket", {"ticket_id": ticket_id, "modo": "editar"})

func _on_exportar_html_button_pressed():
	"""Exporta el ticket a HTML"""
	print("🌐 [TICKET_DETAIL] Exportando ticket a HTML: ", ticket_id)
	exportar_ticket_html()

func _on_exportar_pdf_button_pressed():
	"""Exporta el ticket a PDF"""
	print("📄 [TICKET_DETAIL] Exportando ticket a PDF: ", ticket_id)
	exportar_ticket_pdf()

func _on_cambiar_estado_button_pressed():
	"""Cambia el estado del ticket"""
	print("🔄 [TICKET_DETAIL] Cambiando estado del ticket: ", ticket_id)
	mostrar_dialogo_cambiar_estado()

func _on_asignar_tecnico_button_pressed():
	"""Asigna un técnico al ticket"""
	print("👨‍💻 [TICKET_DETAIL] Asignando técnico al ticket: ", ticket_id)
	mostrar_dialogo_asignar_tecnico()

func _on_volver_button_pressed():
	print("🔙 [TICKET_DETAIL] Volviendo a la lista...")
	Router.ir_a_tickets()

# ========== EXPORTACIÓN ==========

func exportar_ticket_html():
	"""Genera y guarda el ticket en formato HTML"""
	var html_content = generar_html_ticket()
	var filename = "ticket_" + str(ticket_id) + "_" + Time.get_datetime_string_from_system().replace(":", "-") + ".html"
	var file_path = "user://reportes/" + filename
	
	# Crear directorio si no existe
	if not DirAccess.dir_exists_absolute("user://reportes/"):
		DirAccess.create_dir_recursive_absolute("user://reportes/")
	
	# Guardar archivo
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(html_content)
		file.close()
		print("✅ [EXPORT] HTML guardado en: ", file_path)
		mostrar_mensaje("Ticket exportado a HTML: " + filename)
		# Abrir archivo
		OS.shell_open(ProjectSettings.globalize_path(file_path))
	else:
		mostrar_error("Error al crear el archivo HTML")

func exportar_ticket_pdf():
	"""Genera y guarda el ticket en formato PDF"""
	# Por ahora generamos HTML y mostramos mensaje para PDF
	var html_content = generar_html_ticket()
	var filename = "ticket_" + str(ticket_id) + "_" + Time.get_datetime_string_from_system().replace(":", "-") + ".html"
	var file_path = "user://reportes/" + filename
	
	# Crear directorio si no existe
	if not DirAccess.dir_exists_absolute("user://reportes/"):
		DirAccess.create_dir_recursive_absolute("user://reportes/")
	
	# Guardar archivo HTML (más adelante se puede convertir a PDF)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(html_content)
		file.close()
		print("✅ [EXPORT] HTML para PDF guardado en: ", file_path)
		mostrar_mensaje("HTML generado. Para PDF, imprimir desde navegador o usar conversor online.")
		# Abrir archivo
		OS.shell_open(ProjectSettings.globalize_path(file_path))
	else:
		mostrar_error("Error al crear el archivo para PDF")

func generar_html_ticket() -> String:
	"""Genera el contenido HTML del ticket"""
	var html = """
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Ticket SAT #{codigo}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #2c5aa0; color: white; padding: 15px; text-align: center; }
        .info-section { margin: 15px 0; padding: 10px; border-left: 4px solid #2c5aa0; }
        .info-row { margin: 8px 0; }
        .label { font-weight: bold; color: #2c5aa0; }
        .status { padding: 5px 10px; border-radius: 5px; color: white; }
        .status-abierto { background: #e74c3c; }
        .status-proceso { background: #f39c12; }
        .status-cerrado { background: #27ae60; }
        .priority { padding: 3px 8px; border-radius: 3px; color: white; font-size: 12px; }
        .priority-alta { background: #e74c3c; }
        .priority-media { background: #f39c12; }
        .priority-baja { background: #27ae60; }
        .footer { margin-top: 30px; padding: 15px; background: #f8f9fa; text-align: center; font-size: 12px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>TICKET SAT #{codigo}</h1>
        <p>Sistema de Atención Técnica - Tienda de Informática</p>
    </div>
    
    <div class="info-section">
        <h3>Información del Ticket</h3>
        <div class="info-row"><span class="label">Código:</span> {codigo}</div>
        <div class="info-row"><span class="label">Estado:</span> <span class="status status-{estado_class}">{estado}</span></div>
        <div class="info-row"><span class="label">Prioridad:</span> <span class="priority priority-{prioridad_class}">{prioridad}</span></div>
        <div class="info-row"><span class="label">Fecha Creación:</span> {fecha_creacion}</div>
        <div class="info-row"><span class="label">Fecha Actualización:</span> {fecha_actualizacion}</div>
    </div>
    
    <div class="info-section">
        <h3>Información del Cliente</h3>
        <div class="info-row"><span class="label">Nombre:</span> {cliente_nombre}</div>
        <div class="info-row"><span class="label">Email:</span> {cliente_email}</div>
        <div class="info-row"><span class="label">Teléfono:</span> {cliente_telefono}</div>
        <div class="info-row"><span class="label">Dirección:</span> {cliente_direccion}</div>
    </div>
    
    <div class="info-section">
        <h3>Información del Equipo</h3>
        <div class="info-row"><span class="label">Tipo:</span> {equipo_tipo}</div>
        <div class="info-row"><span class="label">Marca:</span> {equipo_marca}</div>
        <div class="info-row"><span class="label">Modelo:</span> {equipo_modelo}</div>
        <div class="info-row"><span class="label">Serie:</span> {equipo_serie}</div>
    </div>
    
    <div class="info-section">
        <h3>Descripción de la Avería</h3>
        <p>{averia_descripcion}</p>
    </div>
    
    <div class="info-section">
        <h3>Observaciones del Cliente</h3>
        <p>{observaciones_cliente}</p>
    </div>
    
    {tecnico_section}
    
    <div class="footer">
        <p>Generado el {fecha_generacion}</p>
        <p>Sistema SAT - Tienda de Informática</p>
    </div>
</body>
</html>
"""
	
	# Reemplazar placeholders
	var estado_class = ticket_data.estado.to_lower().replace(" ", "-")
	var prioridad_class = ticket_data.prioridad.to_lower()
	
	# Sección técnico (solo si está asignado)
	var tecnico_section = ""
	if ticket_data.has("tecnico_nombre") and ticket_data.tecnico_nombre != "":
		tecnico_section = """
    <div class="info-section">
        <h3>Técnico Asignado</h3>
        <div class="info-row"><span class="label">Nombre:</span> {tecnico_nombre}</div>
        <div class="info-row"><span class="label">Email:</span> {tecnico_email}</div>
    </div>
		""".format({
			"tecnico_nombre": ticket_data.get("tecnico_nombre", ""),
			"tecnico_email": ticket_data.get("tecnico_email", "")
		})
	
	html = html.format({
		"codigo": ticket_data.codigo,
		"estado": ticket_data.estado,
		"estado_class": estado_class,
		"prioridad": ticket_data.prioridad,
		"prioridad_class": prioridad_class,
		"fecha_creacion": ticket_data.fecha_creacion,
		"fecha_actualizacion": ticket_data.fecha_actualizacion,
		"cliente_nombre": ticket_data.cliente_nombre,
		"cliente_email": ticket_data.cliente_email,
		"cliente_telefono": ticket_data.cliente_telefono,
		"cliente_direccion": ticket_data.cliente_direccion,
		"equipo_tipo": ticket_data.equipo_tipo,
		"equipo_marca": ticket_data.equipo_marca,
		"equipo_modelo": ticket_data.equipo_modelo,
		"equipo_serie": ticket_data.equipo_serie,
		"averia_descripcion": ticket_data.averia_descripcion,
		"observaciones_cliente": ticket_data.observaciones_cliente,
		"tecnico_section": tecnico_section,
		"fecha_generacion": Time.get_datetime_string_from_system()
	})
	
	return html

# ========== GESTIÓN DE ESTADO Y TÉCNICOS ==========

func mostrar_dialogo_cambiar_estado():
	"""Muestra un diálogo para cambiar el estado del ticket"""
	var dialog = AcceptDialog.new()
	dialog.title = "Cambiar Estado del Ticket"
	dialog.size = Vector2i(400, 200)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	
	var label = Label.new()
	label.text = "Seleccione el nuevo estado:"
	vbox.add_child(label)
	
	var option_button = OptionButton.new()
	option_button.add_item("Abierto")
	option_button.add_item("En Proceso")
	option_button.add_item("Cerrado")
	
	# Seleccionar estado actual
	var estados = ["Abierto", "En Proceso", "Cerrado"]
	var estado_actual = estados.find(ticket_data.estado)
	if estado_actual >= 0:
		option_button.selected = estado_actual
	
	vbox.add_child(option_button)
	
	var cambiar_button = Button.new()
	cambiar_button.text = "Cambiar Estado"
	cambiar_button.pressed.connect(func(): 
		var nuevo_estado = option_button.get_item_text(option_button.selected)
		cambiar_estado_ticket(nuevo_estado)
		dialog.queue_free()
	)
	vbox.add_child(cambiar_button)
	
	dialog.add_child(vbox)
	add_child(dialog)
	dialog.popup_centered()

func mostrar_dialogo_asignar_tecnico():
	"""Muestra un diálogo para asignar un técnico al ticket"""
	var tecnicos = DataService.obtener_usuarios_por_rol("tecnico")
	
	if tecnicos.is_empty():
		mostrar_mensaje("No hay técnicos disponibles")
		return
	
	var dialog = AcceptDialog.new()
	dialog.title = "Asignar Técnico al Ticket"
	dialog.size = Vector2i(400, 200)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	
	var label = Label.new()
	label.text = "Seleccione el técnico:"
	vbox.add_child(label)
	
	var option_button = OptionButton.new()
	option_button.add_item("Sin asignar", -1)
	
	for tecnico in tecnicos:
		option_button.add_item(tecnico.nombre, tecnico.id)
	
	# Seleccionar técnico actual si existe
	if ticket_data.has("tecnico_id") and ticket_data.tecnico_id > 0:
		for i in range(option_button.get_item_count()):
			if option_button.get_item_id(i) == ticket_data.tecnico_id:
				option_button.selected = i
				break
	
	vbox.add_child(option_button)
	
	var asignar_button = Button.new()
	asignar_button.text = "Asignar Técnico"
	asignar_button.pressed.connect(func(): 
		var tecnico_id = option_button.get_item_id(option_button.selected) if option_button.selected > 0 else null
		asignar_tecnico_ticket(tecnico_id)
		dialog.queue_free()
	)
	vbox.add_child(asignar_button)
	
	dialog.add_child(vbox)
	add_child(dialog)
	dialog.popup_centered()

func cambiar_estado_ticket(nuevo_estado: String):
	"""Cambia el estado del ticket"""
	var exito = DataService.actualizar_campo_ticket(ticket_id, "estado", nuevo_estado)
	
	if exito:
		ticket_data.estado = nuevo_estado
		actualizar_interfaz()
		mostrar_mensaje("Estado actualizado a: " + nuevo_estado)
	else:
		mostrar_error("Error al actualizar el estado del ticket")

func asignar_tecnico_ticket(tecnico_id):
	"""Asigna un técnico al ticket"""
	var exito = DataService.actualizar_campo_ticket(ticket_id, "tecnico_id", tecnico_id)
	
	if exito:
		# Recargar datos del ticket para obtener info actualizada
		cargar_ticket(ticket_id)
		mostrar_mensaje("Técnico asignado correctamente")
	else:
		mostrar_error("Error al asignar el técnico")

func mostrar_mensaje(texto: String):
	"""Muestra un mensaje informativo temporal"""
	print("ℹ️ [TICKET_DETAIL] Mensaje: ", texto)
	# Aquí se podría agregar una notificación visual