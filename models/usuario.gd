extends RefCounted
class_name Usuario

# Modelo de datos para Usuario

var id: int = -1
var nombre: String = ""
var email: String = ""
var pass_hash: String = ""
var rol_id: int = -1
var rol_nombre: String = ""
var activo: bool = true
var creado_en: String = ""

func _init(data: Dictionary = {}):
	cargar_desde_diccionario(data)

func cargar_desde_diccionario(data: Dictionary):
	if data.has("id"): id = int(data.id)
	if data.has("nombre"): nombre = data.nombre
	if data.has("email"): email = data.email
	if data.has("pass_hash"): pass_hash = data.pass_hash
	if data.has("rol_id"): rol_id = int(data.rol_id)
	if data.has("rol_nombre"): rol_nombre = data.rol_nombre
	if data.has("activo"): activo = bool(int(data.activo))
	if data.has("creado_en"): creado_en = data.creado_en

func a_diccionario() -> Dictionary:
	return {
		"id": id,
		"nombre": nombre,
		"email": email,
		"pass_hash": pass_hash,
		"rol_id": rol_id,
		"activo": 1 if activo else 0
	}

func es_nuevo() -> bool:
	return id <= 0

func es_admin() -> bool:
	return rol_id == 1

func es_tecnico() -> bool:
	return rol_id == 2

func es_recepcion() -> bool:
	return rol_id == 3

func es_readonly() -> bool:
	return rol_id == 4