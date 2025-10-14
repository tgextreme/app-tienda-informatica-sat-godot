extends RefCounted
class_name TicketLinea

# Línea de ticket (repuesto o mano de obra)

var id: int = -1
var ticket_id: int = -1
var tipo: String = "REPUESTO" # REPUESTO | MO
var producto_id: int = -1
var descripcion: String = ""
var cantidad: float = 1.0
var precio_unit: float = 0.0
var iva: float = 21.0
var total: float = 0.0

# Datos del producto (si aplica)
var producto_nombre: String = ""
var producto_sku: String = ""

func _init(data: Dictionary = {}):
	cargar_desde_diccionario(data)

func cargar_desde_diccionario(data: Dictionary):
	if data.has("id"): id = int(data.id)
	if data.has("ticket_id"): ticket_id = int(data.ticket_id)
	if data.has("tipo"): tipo = data.tipo
	if data.has("producto_id") and data.producto_id != "": producto_id = int(data.producto_id)
	if data.has("descripcion"): descripcion = data.descripcion
	if data.has("cantidad"): cantidad = float(data.cantidad)
	if data.has("precio_unit"): precio_unit = float(data.precio_unit)
	if data.has("iva"): iva = float(data.iva)
	if data.has("total"): total = float(data.total)
	
	if data.has("producto_nombre"): producto_nombre = data.producto_nombre
	if data.has("producto_sku"): producto_sku = data.producto_sku

func a_diccionario() -> Dictionary:
	return {
		"id": id,
		"ticket_id": ticket_id,
		"tipo": tipo,
		"producto_id": producto_id if producto_id > 0 else -1,
		"descripcion": descripcion,
		"cantidad": cantidad,
		"precio_unit": precio_unit,
		"iva": iva,
		"total": total
	}

func calcular_base() -> float:
	return precio_unit * cantidad

func calcular_iva() -> float:
	var base = calcular_base()
	return base * (iva / 100.0)

func calcular_total() -> float:
	return calcular_base() + calcular_iva()

func recalcular():
	total = calcular_total()

func es_repuesto() -> bool:
	return tipo == "REPUESTO"

func es_mano_obra() -> bool:
	return tipo == "MO"