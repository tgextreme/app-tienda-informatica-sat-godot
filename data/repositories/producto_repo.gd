extends RefCounted
class_name ProductoRepository

# Repositorio para operaciones con productos

const Producto = preload("res://models/producto.gd")

static func obtener_por_id(producto_id: int) -> Producto:
	var producto_data = DataService.obtener_producto(producto_id)
	if producto_data.is_empty():
		return null
	
	return Producto.new(producto_data)

static func buscar(filtros: Dictionary = {}) -> Array:
	var productos_data = DataService.buscar_productos(filtros)
	var productos = []
	
	for producto_data in productos_data:
		productos.append(Producto.new(producto_data))
	
	return productos

static func guardar(producto: Producto) -> int:
	return DataService.guardar_producto(producto.a_diccionario())

static func obtener_categorias() -> Array:
	var result = DataService.execute_sql("""
		SELECT DISTINCT categoria 
		FROM productos 
		WHERE categoria IS NOT NULL AND categoria != ''
		ORDER BY categoria
	""")
	
	var categorias = []
	for row in result:
		categorias.append(row.categoria)
	
	return categorias

static func obtener_productos_stock_bajo() -> Array:
	var filtros = {"stock_bajo": true}
	return buscar(filtros)

static func validar_sku_unico(sku: String, producto_id: int = -1) -> bool:
	if sku == "":
		return true
	
	var sql = "SELECT COUNT(*) as count FROM productos WHERE sku = ?"
	var params = [sku]
	
	if producto_id > 0:
		sql += " AND id != ?"
		params.append(producto_id)
	
	var result = DataService.execute_sql(sql, params)
	
	if result.size() > 0:
		return int(result[0]["count"]) == 0
	
	return true

static func actualizar_stock(producto_id: int, nueva_cantidad: int) -> bool:
	return DataService.actualizar_stock(producto_id, nueva_cantidad)

static func obtener_movimientos_stock(_producto_id: int) -> Array:
	# Esta funcionalidad se puede expandir más adelante
	# Por ahora devolvemos un array vacío
	return []