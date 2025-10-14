extends RefCounted
class_name Ticket

# Modelo de datos para Ticket SAT

var id: int = -1
var codigo: String = ""
var estado: String = "Nuevo"
var prioridad: String = "NORMAL"
var cliente_id: int = -1
var tecnico_id: int = -1

# Fechas
var fecha_entrada: String = ""
var fecha_presupuesto: String = ""
var fecha_aprobacion: String = ""
var fecha_entrega: String = ""
var fecha_cierre: String = ""

# Datos del equipo
var equipo_tipo: String = ""
var equipo_marca: String = ""
var equipo_modelo: String = ""
var numero_serie: String = ""
var imei: String = ""
var accesorios: String = ""
var password_bloqueo: String = ""

# Información técnica
var averia_cliente: String = ""
var diagnostico: String = ""
var aprobacion_metodo: String = ""
var aprobacion_usuario_id: int = -1
var notas_internas: String = ""
var notas_cliente: String = ""

# Datos relacionados (cargados por joins)
var cliente_nombre: String = ""
var cliente_telefono: String = ""
var cliente_email: String = ""
var tecnico_nombre: String = ""

# Líneas del ticket (cargadas por separado)
var lineas: Array = []
var tiempos: Array = []
var historial: Array = []
var adjuntos: Array = []

func _init(data: Dictionary = {}):
	cargar_desde_diccionario(data)

func cargar_desde_diccionario(data: Dictionary):
	if data.has("id"): id = int(data.id)
	if data.has("codigo"): codigo = data.codigo
	if data.has("estado"): estado = data.estado
	if data.has("prioridad"): prioridad = data.prioridad
	if data.has("cliente_id"): cliente_id = int(data.cliente_id)
	if data.has("tecnico_id") and data.tecnico_id != "": tecnico_id = int(data.tecnico_id)
	
	if data.has("fecha_entrada"): fecha_entrada = data.fecha_entrada
	if data.has("fecha_presupuesto"): fecha_presupuesto = data.fecha_presupuesto
	if data.has("fecha_aprobacion"): fecha_aprobacion = data.fecha_aprobacion
	if data.has("fecha_entrega"): fecha_entrega = data.fecha_entrega
	if data.has("fecha_cierre"): fecha_cierre = data.fecha_cierre
	
	if data.has("equipo_tipo"): equipo_tipo = data.equipo_tipo
	if data.has("equipo_marca"): equipo_marca = data.equipo_marca
	if data.has("equipo_modelo"): equipo_modelo = data.equipo_modelo
	if data.has("numero_serie"): numero_serie = data.numero_serie
	if data.has("imei"): imei = data.imei
	if data.has("accesorios"): accesorios = data.accesorios
	if data.has("password_bloqueo"): password_bloqueo = data.password_bloqueo
	
	if data.has("averia_cliente"): averia_cliente = data.averia_cliente
	if data.has("diagnostico"): diagnostico = data.diagnostico
	if data.has("aprobacion_metodo"): aprobacion_metodo = data.aprobacion_metodo
	if data.has("aprobacion_usuario_id") and data.aprobacion_usuario_id != "": 
		aprobacion_usuario_id = int(data.aprobacion_usuario_id)
	if data.has("notas_internas"): notas_internas = data.notas_internas
	if data.has("notas_cliente"): notas_cliente = data.notas_cliente
	
	# Datos relacionados
	if data.has("cliente_nombre"): cliente_nombre = data.cliente_nombre
	if data.has("cliente_telefono"): cliente_telefono = data.cliente_telefono
	if data.has("cliente_email"): cliente_email = data.cliente_email
	if data.has("tecnico_nombre"): tecnico_nombre = data.tecnico_nombre

func a_diccionario() -> Dictionary:
	return {
		"id": id,
		"codigo": codigo,
		"estado": estado,
		"prioridad": prioridad,
		"cliente_id": cliente_id,
		"tecnico_id": tecnico_id if tecnico_id > 0 else -1,
		"fecha_entrada": fecha_entrada,
		"fecha_presupuesto": fecha_presupuesto,
		"fecha_aprobacion": fecha_aprobacion,
		"fecha_entrega": fecha_entrega,
		"fecha_cierre": fecha_cierre,
		"equipo_tipo": equipo_tipo,
		"equipo_marca": equipo_marca,
		"equipo_modelo": equipo_modelo,
		"numero_serie": numero_serie,
		"imei": imei,
		"accesorios": accesorios,
		"password_bloqueo": password_bloqueo,
		"averia_cliente": averia_cliente,
		"diagnostico": diagnostico,
		"aprobacion_metodo": aprobacion_metodo,
		"aprobacion_usuario_id": aprobacion_usuario_id if aprobacion_usuario_id > 0 else -1,
		"notas_internas": notas_internas,
		"notas_cliente": notas_cliente
	}

func es_nuevo() -> bool:
	return id <= 0

func esta_abierto() -> bool:
	return estado not in ["Cerrado", "Entregado"]

func puede_editarse() -> bool:
	return estado not in ["Cerrado"]

func necesita_presupuesto() -> bool:
	return estado in ["Diagnosticando", "Presupuestado"] and calcular_total() > 0

func esta_presupuestado() -> bool:
	return fecha_presupuesto != ""

func esta_aprobado() -> bool:
	return fecha_aprobacion != "" and aprobacion_metodo != ""

func calcular_subtotal() -> float:
	var subtotal = 0.0
	for linea in lineas:
		subtotal += linea.calcular_base()
	return subtotal

func calcular_iva() -> float:
	var total_iva = 0.0
	for linea in lineas:
		total_iva += linea.calcular_iva()
	return total_iva

func calcular_total() -> float:
	var total = 0.0
	for linea in lineas:
		total += linea.total
	return total

func obtener_descripcion_equipo() -> String:
	var desc = equipo_tipo
	if equipo_marca != "":
		desc += " " + equipo_marca
	if equipo_modelo != "":
		desc += " " + equipo_modelo
	return desc

func obtener_tiempo_total() -> int:
	var total_minutos = 0
	for tiempo in tiempos:
		total_minutos += tiempo.minutos
	return total_minutos

func obtener_tiempo_formateado() -> String:
	var total_minutos = obtener_tiempo_total()
	var horas = total_minutos / 60
	var minutos = total_minutos % 60
	return "%dh %02dm" % [horas, minutos]