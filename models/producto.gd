extends RefCounted
class_name Producto

# Modelo de datos para Producto

var id: int = -1
var sku: String = ""
var nombre: String = ""
var categoria: String = ""
var tipo: String = "REPUESTO" # REPUESTO | SERVICIO
var coste: float = 0.0
var pvp: float = 0.0
var iva: float = 21.0
var stock: int = 0
var stock_min: int = 0
var proveedor: String = ""

func _init(data: Dictionary = {}):
	cargar_desde_diccionario(data)

func cargar_desde_diccionario(data: Dictionary):
	if data.has("id"): id = int(data.id)
	if data.has("sku"): sku = data.sku
	if data.has("nombre"): nombre = data.nombre
	if data.has("categoria"): categoria = data.categoria
	if data.has("tipo"): tipo = data.tipo
	if data.has("coste"): coste = float(data.coste)
	if data.has("pvp"): pvp = float(data.pvp)
	if data.has("iva"): iva = float(data.iva)
	if data.has("stock"): stock = int(data.stock)
	if data.has("stock_min"): stock_min = int(data.stock_min)
	if data.has("proveedor"): proveedor = data.proveedor

func a_diccionario() -> Dictionary:
	return {
		"id": id,
		"sku": sku,
		"nombre": nombre,
		"categoria": categoria,
		"tipo": tipo,
		"coste": coste,
		"pvp": pvp,
		"iva": iva,
		"stock": stock,
		"stock_min": stock_min,
		"proveedor": proveedor
	}

func es_nuevo() -> bool:
	return id <= 0

func es_repuesto() -> bool:
	return tipo == "REPUESTO"

func es_servicio() -> bool:
	return tipo == "SERVICIO"

func tiene_stock_bajo() -> bool:
	return stock <= stock_min and es_repuesto()

func puede_venderse() -> bool:
	if es_servicio():
		return true
	return stock > 0 or AppState.get_config("stock_negativo_permitido", "0") == "1"

func calcular_margen() -> float:
	if coste > 0:
		return ((pvp - coste) / coste) * 100.0
	return 0.0

func obtener_precio_con_iva() -> float:
	return pvp * (1.0 + (iva / 100.0))

func obtener_descripcion_completa() -> String:
	var desc = nombre
	if sku != "":
		desc += " (" + sku + ")"
	if categoria != "":
		desc += " - " + categoria
	return desc