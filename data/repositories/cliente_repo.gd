extends RefCounted
class_name ClienteRepository

# Repositorio para operaciones con clientes

const Cliente = preload("res://models/cliente.gd")

static func obtener_por_id(cliente_id: int) -> Cliente:
	var cliente_data = DataService.obtener_cliente(cliente_id)
	if cliente_data.is_empty():
		return null
	
	return Cliente.new(cliente_data)

static func buscar(busqueda: String = "") -> Array:
	var clientes_data = DataService.buscar_clientes(busqueda)
	var clientes = []
	
	for cliente_data in clientes_data:
		clientes.append(Cliente.new(cliente_data))
	
	return clientes

static func guardar(cliente: Cliente) -> int:
	return DataService.guardar_cliente(cliente.a_diccionario())

static func obtener_historial_tickets(cliente_id: int) -> Array:
	return DataService.execute_sql("""
		SELECT t.id, t.codigo, t.estado, t.fecha_entrada, t.equipo_tipo, t.equipo_marca
		FROM tickets t
		WHERE t.cliente_id = ?
		ORDER BY t.fecha_entrada DESC
		LIMIT 20
	""", [cliente_id])

static func validar_email_unico(email: String, cliente_id: int = -1) -> bool:
	if email == "":
		return true
	
	var sql = "SELECT COUNT(*) as count FROM clientes WHERE email = ?"
	var params = [email]
	
	if cliente_id > 0:
		sql += " AND id != ?"
		params.append(cliente_id)
	
	var result = DataService.execute_sql(sql, params)
	
	if result.size() > 0:
		return int(result[0]["count"]) == 0
	
	return true