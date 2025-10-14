extends RefCounted
class_name PrintService

# Servicio de impresión para generar documentos HTML/PDF

const Ticket = preload("res://models/ticket.gd")

static func generar_presupuesto(ticket: Ticket) -> String:
	var plantilla = cargar_plantilla("presupuesto")
	var html = procesar_plantilla(plantilla, ticket)
	
	var archivo_temp = guardar_html_temporal(html, "presupuesto_" + ticket.codigo)
	return archivo_temp

static func generar_orden_reparacion(ticket: Ticket) -> String:
	var plantilla = cargar_plantilla("orden_reparacion")
	var html = procesar_plantilla(plantilla, ticket)
	
	var archivo_temp = guardar_html_temporal(html, "orden_" + ticket.codigo)
	return archivo_temp

static func generar_entrega_garantia(ticket: Ticket) -> String:
	var plantilla = cargar_plantilla("entrega_garantia")
	var html = procesar_plantilla(plantilla, ticket)
	
	var archivo_temp = guardar_html_temporal(html, "entrega_" + ticket.codigo)
	return archivo_temp

static func generar_factura_simplificada(ticket: Ticket) -> String:
	var plantilla = cargar_plantilla("factura_simplificada") 
	var html = procesar_plantilla(plantilla, ticket)
	
	var archivo_temp = guardar_html_temporal(html, "factura_" + ticket.codigo)
	return archivo_temp

static func cargar_plantilla(tipo: String) -> String:
	var ruta = "res://printing/templates/" + tipo + ".html"
	var file = FileAccess.open(ruta, FileAccess.READ)
	
	if not file:
		push_error("No se pudo cargar plantilla: " + ruta)
		return ""
	
	var contenido = file.get_as_text()
	file.close()
	
	return contenido

static func procesar_plantilla(plantilla: String, ticket: Ticket) -> String:
	var html = plantilla
	
	# Variables de empresa
	html = html.replace("{{empresa.nombre}}", AppState.get_config("empresa_nombre", "Mi Tienda SAT"))
	html = html.replace("{{empresa.nif}}", AppState.get_config("empresa_nif", ""))
	html = html.replace("{{empresa.direccion}}", AppState.get_config("empresa_direccion", ""))
	html = html.replace("{{empresa.telefono}}", AppState.get_config("empresa_telefono", ""))
	html = html.replace("{{empresa.email}}", AppState.get_config("empresa_email", ""))
	
	# Variables de ticket
	html = html.replace("{{ticket.codigo}}", ticket.codigo)
	html = html.replace("{{ticket.estado}}", ticket.estado)
	html = html.replace("{{ticket.fecha_entrada}}", formatear_fecha(ticket.fecha_entrada))
	html = html.replace("{{ticket.fecha_presupuesto}}", formatear_fecha(ticket.fecha_presupuesto))
	html = html.replace("{{ticket.averia_cliente}}", ticket.averia_cliente)
	html = html.replace("{{ticket.diagnostico}}", ticket.diagnostico)
	
	# Variables de cliente
	html = html.replace("{{cliente.nombre}}", ticket.cliente_nombre)
	html = html.replace("{{cliente.telefono}}", ticket.cliente_telefono)
	html = html.replace("{{cliente.email}}", ticket.cliente_email)
	
	# Variables de equipo
	html = html.replace("{{equipo.tipo}}", ticket.equipo_tipo)
	html = html.replace("{{equipo.marca}}", ticket.equipo_marca)
	html = html.replace("{{equipo.modelo}}", ticket.equipo_modelo)
	html = html.replace("{{equipo.serie}}", ticket.numero_serie)
	html = html.replace("{{equipo.descripcion}}", ticket.obtener_descripcion_equipo())
	
	# Generar tabla de líneas
	var tabla_lineas = generar_tabla_lineas(ticket.lineas)
	html = html.replace("{{lineas}}", tabla_lineas)
	
	# Totales
	var subtotal = ticket.calcular_subtotal()
	var total_iva = ticket.calcular_iva()
	var total = ticket.calcular_total()
	
	html = html.replace("{{totales.subtotal}}", formatear_precio(subtotal))
	html = html.replace("{{totales.iva}}", formatear_precio(total_iva))
	html = html.replace("{{totales.total}}", formatear_precio(total))
	
	# Fecha actual
	html = html.replace("{{fecha_actual}}", formatear_fecha_actual())
	
	# Pie legal
	var pie_legal = "Documento generado por " + AppState.get_config("empresa_nombre", "Tienda SAT")
	html = html.replace("{{pie_legal}}", pie_legal)
	
	return html

static func generar_tabla_lineas(lineas: Array) -> String:
	var html = ""
	
	for linea in lineas:
		html += "<tr>"
		html += "<td>" + linea.descripcion + "</td>"
		html += "<td style='text-align: center;'>" + str(linea.cantidad) + "</td>"
		html += "<td style='text-align: right;'>" + formatear_precio(linea.precio_unit) + "</td>"
		html += "<td style='text-align: right;'>" + str(linea.iva) + "%</td>"
		html += "<td style='text-align: right;'>" + formatear_precio(linea.total) + "</td>"
		html += "</tr>"
	
	return html

static func formatear_precio(precio: float) -> String:
	return "%.2f €" % precio

static func formatear_fecha(fecha: String) -> String:
	if fecha == "":
		return ""
	
	# Convertir de formato ISO a formato español
	var partes = fecha.split(" ")
	if partes.size() > 0:
		var fecha_parte = partes[0]
		var fecha_partes = fecha_parte.split("-")
		if fecha_partes.size() == 3:
			return fecha_partes[2] + "/" + fecha_partes[1] + "/" + fecha_partes[0]
	
	return fecha

static func formatear_fecha_actual() -> String:
	var datetime = Time.get_datetime_dict_from_system()
	return "%02d/%02d/%d" % [datetime.day, datetime.month, datetime.year]

static func guardar_html_temporal(html: String, nombre_archivo: String) -> String:
	var ruta_temporal = "user://temp_" + nombre_archivo + ".html"
	
	var file = FileAccess.open(ruta_temporal, FileAccess.WRITE)
	if not file:
		push_error("No se pudo crear archivo temporal: " + ruta_temporal)
		return ""
	
	file.store_string(html)
	file.close()
	
	return ruta_temporal

static func abrir_para_imprimir(ruta_archivo: String):
	var ruta_global = ProjectSettings.globalize_path(ruta_archivo)
	OS.shell_open(ruta_global)

static func generar_pdf(ruta_html: String, ruta_pdf: String) -> bool:
	var wkhtmltopdf_path = AppState.get_config("wkhtmltopdf_path", "")
	
	if wkhtmltopdf_path == "" or not FileAccess.file_exists(wkhtmltopdf_path):
		push_warning("wkhtmltopdf no está configurado. Abriendo HTML para imprimir.")
		abrir_para_imprimir(ruta_html)
		return false
	
	var args = [
		"--page-size", "A4",
		"--margin-top", "15mm",
		"--margin-bottom", "15mm", 
		"--margin-left", "10mm",
		"--margin-right", "10mm",
		ProjectSettings.globalize_path(ruta_html),
		ProjectSettings.globalize_path(ruta_pdf)
	]
	
	var output = []
	var exit_code = OS.execute(wkhtmltopdf_path, args, output)
	
	if exit_code == 0:
		OS.shell_open(ProjectSettings.globalize_path(ruta_pdf))
		return true
	else:
		push_error("Error generando PDF: " + str(output))
		abrir_para_imprimir(ruta_html)
		return false

# Función de conveniencia para generar e imprimir
static func imprimir_documento(ticket: Ticket, tipo: String):
	var ruta_html = ""
	
	match tipo:
		"presupuesto":
			ruta_html = generar_presupuesto(ticket)
		"orden":
			ruta_html = generar_orden_reparacion(ticket)
		"entrega":
			ruta_html = generar_entrega_garantia(ticket)
		"factura":
			ruta_html = generar_factura_simplificada(ticket)
		_:
			push_error("Tipo de documento no válido: " + tipo)
			return
	
	if ruta_html != "":
		# Intentar generar PDF, si no, abrir HTML
		var ruta_pdf = ruta_html.replace(".html", ".pdf")
		if not generar_pdf(ruta_html, ruta_pdf):
			abrir_para_imprimir(ruta_html)