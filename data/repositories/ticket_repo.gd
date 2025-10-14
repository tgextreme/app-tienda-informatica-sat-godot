extends RefCounted
class_name TicketRepository

# Repositorio específico para operaciones con tickets
# Extiende las funciones básicas de DataService con lógica específica

const Ticket = preload("res://models/ticket.gd")
const TicketLinea = preload("res://models/ticket_linea.gd")
const TicketTiempo = preload("res://models/ticket_tiempo.gd")
const TicketHistorial = preload("res://models/ticket_historial.gd")
const TicketAdjunto = preload("res://models/ticket_adjunto.gd")

static func obtener_con_detalles(ticket_id: int) -> Ticket:
	var ticket_data = DataService.obtener_ticket(ticket_id)
	if ticket_data.is_empty():
		return null
	
	var ticket = Ticket.new(ticket_data)
	
	# Cargar líneas
	ticket.lineas = obtener_lineas(ticket_id)
	
	# Cargar tiempos
	ticket.tiempos = obtener_tiempos(ticket_id)
	
	# Cargar historial
	ticket.historial = obtener_historial(ticket_id)
	
	# Cargar adjuntos
	ticket.adjuntos = obtener_adjuntos(ticket_id)
	
	return ticket

static func obtener_lineas(ticket_id: int) -> Array:
	var lineas_data = DataService.execute_sql("""
		SELECT tl.*, p.nombre as producto_nombre, p.sku as producto_sku
		FROM ticket_lineas tl
		LEFT JOIN productos p ON tl.producto_id = p.id
		WHERE tl.ticket_id = ?
		ORDER BY tl.id
	""", [ticket_id])
	
	var lineas = []
	for linea_data in lineas_data:
		lineas.append(TicketLinea.new(linea_data))
	
	return lineas

static func obtener_tiempos(ticket_id: int) -> Array:
	var tiempos_data = DataService.execute_sql("""
		SELECT tt.*, u.nombre as tecnico_nombre
		FROM ticket_tiempos tt
		LEFT JOIN usuarios u ON tt.tecnico_id = u.id
		WHERE tt.ticket_id = ?
		ORDER BY tt.inicio
	""", [ticket_id])
	
	var tiempos = []
	for tiempo_data in tiempos_data:
		tiempos.append(TicketTiempo.new(tiempo_data))
	
	return tiempos

static func obtener_historial(ticket_id: int) -> Array:
	var historial_data = DataService.obtener_historial_ticket(ticket_id)
	
	var historial = []
	for entrada_data in historial_data:
		historial.append(TicketHistorial.new(entrada_data))
	
	return historial

static func obtener_adjuntos(ticket_id: int) -> Array:
	var adjuntos_data = DataService.execute_sql("""
		SELECT a.*, u.nombre as subido_por_nombre
		FROM adjuntos a
		LEFT JOIN usuarios u ON a.subido_por = u.id
		WHERE a.ticket_id = ?
		ORDER BY a.subido_en
	""", [ticket_id])
	
	var adjuntos = []
	for adjunto_data in adjuntos_data:
		adjuntos.append(TicketAdjunto.new(adjunto_data))
	
	return adjuntos

static func guardar_completo(ticket: Ticket) -> bool:
	# Guardar datos básicos del ticket
	var ticket_id = DataService.guardar_ticket(ticket.a_diccionario())
	if ticket_id <= 0:
		return false
	
	ticket.id = ticket_id
	
	# Guardar líneas
	guardar_lineas(ticket)
	
	return true

static func guardar_lineas(ticket: Ticket):
	# Eliminar líneas existentes
	DataService.execute_non_query("DELETE FROM ticket_lineas WHERE ticket_id = ?", [ticket.id])
	
	# Insertar líneas nuevas
	for linea in ticket.lineas:
		var linea_dict = linea.a_diccionario()
		linea_dict.ticket_id = ticket.id
		
		DataService.execute_non_query("""
			INSERT INTO ticket_lineas (ticket_id, tipo, producto_id, descripcion, cantidad, precio_unit, iva, total)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?)
		""", [
			linea_dict.ticket_id,
			linea_dict.tipo,
			linea_dict.producto_id if linea_dict.producto_id > 0 else -1,
			linea_dict.descripcion,
			linea_dict.cantidad,
			linea_dict.precio_unit,
			linea_dict.iva,
			linea_dict.total
		])

static func agregar_linea(ticket_id: int, linea: TicketLinea) -> bool:
	var linea_dict = linea.a_diccionario()
	linea_dict.ticket_id = ticket_id
	
	var exito = DataService.execute_non_query("""
		INSERT INTO ticket_lineas (ticket_id, tipo, producto_id, descripcion, cantidad, precio_unit, iva, total)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)
	""", [
		linea_dict.ticket_id,
		linea_dict.tipo,
		linea_dict.producto_id if linea_dict.producto_id > 0 else -1,
		linea_dict.descripcion,
		linea_dict.cantidad,
		linea_dict.precio_unit,
		linea_dict.iva,
		linea_dict.total
	])
	
	# Si es un repuesto, actualizar stock
	if exito and linea.es_repuesto() and linea.producto_id > 0:
		actualizar_stock_producto(linea.producto_id, -linea.cantidad)
	
	return exito

static func eliminar_linea(linea_id: int) -> bool:
	# Obtener información de la línea antes de eliminarla
	var linea_data = DataService.execute_sql("SELECT * FROM ticket_lineas WHERE id = ?", [linea_id])
	if linea_data.size() == 0:
		return false
	
	var linea = TicketLinea.new(linea_data[0])
	
	# Eliminar línea
	var exito = DataService.execute_non_query("DELETE FROM ticket_lineas WHERE id = ?", [linea_id])
	
	# Devolver stock si es repuesto
	if exito and linea.es_repuesto() and linea.producto_id > 0:
		actualizar_stock_producto(linea.producto_id, linea.cantidad)
	
	return exito

static func agregar_tiempo(ticket_id: int, tiempo: TicketTiempo) -> bool:
	var tiempo_dict = tiempo.a_diccionario()
	tiempo_dict.ticket_id = ticket_id
	
	return DataService.execute_non_query("""
		INSERT INTO ticket_tiempos (ticket_id, tecnico_id, inicio, fin, minutos, descripcion)
		VALUES (?, ?, ?, ?, ?, ?)
	""", [
		tiempo_dict.ticket_id,
		tiempo_dict.tecnico_id,
		tiempo_dict.inicio,
		tiempo_dict.fin,
		tiempo_dict.minutos,
		tiempo_dict.descripcion
	])

static func subir_adjunto(ticket_id: int, archivo_path: String, usuario_id: int) -> bool:
	var archivo_nombre = archivo_path.get_file()
	var extension = archivo_nombre.get_extension()
	
	# Crear carpeta del ticket si no existe
	var ticket_folder = "adjuntos/SAT-" + str(ticket_id)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://" + ticket_folder))
	
	# Copiar archivo
	var destino = ticket_folder + "/" + archivo_nombre
	var origen = FileAccess.open(archivo_path, FileAccess.READ)
	var destino_file = FileAccess.open("user://" + destino, FileAccess.WRITE)
	var exito = false
	
	if origen and destino_file:
		destino_file.store_buffer(origen.get_buffer(origen.get_length()))
		exito = true
	
	if origen:
		origen.close()
	if destino_file:
		destino_file.close()
	
	if not exito:
		return false
	
	# Determinar tipo MIME
	var tipo_mime = ""
	match extension.to_lower():
		"jpg", "jpeg":
			tipo_mime = "image/jpeg"
		"png":
			tipo_mime = "image/png"
		"pdf":
			tipo_mime = "application/pdf"
		_:
			tipo_mime = "application/octet-stream"
	
	# Guardar en base de datos
	return DataService.execute_non_query("""
		INSERT INTO adjuntos (ticket_id, nombre_archivo, ruta, tipo_mime, subido_por)
		VALUES (?, ?, ?, ?, ?)
	""", [ticket_id, archivo_nombre, destino, tipo_mime, usuario_id])

static func actualizar_stock_producto(producto_id: int, cantidad_cambio: float):
	DataService.execute_non_query("""
		UPDATE productos 
		SET stock = stock + ? 
		WHERE id = ?
	""", [cantidad_cambio, producto_id])

static func buscar_por_filtros(filtros: Dictionary) -> Array:
	var tickets_data = DataService.buscar_tickets(filtros)
	var tickets = []
	
	for ticket_data in tickets_data:
		tickets.append(Ticket.new(ticket_data))
	
	return tickets

static func obtener_resumen_estados() -> Dictionary:
	var estados = DataService.execute_sql("""
		SELECT estado, COUNT(*) as cantidad 
		FROM tickets 
		WHERE fecha_cierre IS NULL 
		GROUP BY estado
		ORDER BY cantidad DESC
	""")
	
	var resumen = {}
	for estado in estados:
		resumen[estado.estado] = int(estado.cantidad)
	
	return resumen