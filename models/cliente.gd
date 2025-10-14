extends RefCounted
class_name Cliente

# Modelo de datos para Cliente

var id: int = -1
var nombre: String = ""
var nif: String = ""
var email: String = ""
var telefono: String = ""
var telefono_alt: String = ""
var direccion: String = ""
var notas: String = ""
var rgpd_consent: bool = false
var creado_en: String = ""

func _init(data: Dictionary = {}):
	cargar_desde_diccionario(data)

func cargar_desde_diccionario(data: Dictionary):
	if data.has("id"): id = int(data.id)
	if data.has("nombre"): nombre = data.nombre
	if data.has("nif"): nif = data.nif
	if data.has("email"): email = data.email
	if data.has("telefono"): telefono = data.telefono
	if data.has("telefono_alt"): telefono_alt = data.telefono_alt
	if data.has("direccion"): direccion = data.direccion
	if data.has("notas"): notas = data.notas
	if data.has("rgpd_consent"): rgpd_consent = bool(int(data.rgpd_consent))
	if data.has("creado_en"): creado_en = data.creado_en

func a_diccionario() -> Dictionary:
	return {
		"id": id,
		"nombre": nombre,
		"nif": nif,
		"email": email,
		"telefono": telefono,
		"telefono_alt": telefono_alt,
		"direccion": direccion,
		"notas": notas,
		"rgpd_consent": 1 if rgpd_consent else 0
	}

func es_nuevo() -> bool:
	return id <= 0

func obtener_telefono_principal() -> String:
	if telefono != "":
		return telefono
	return telefono_alt

func tiene_datos_completos() -> bool:
	return nombre != "" and telefono != ""