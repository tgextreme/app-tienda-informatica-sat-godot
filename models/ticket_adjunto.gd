extends RefCounted
class_name TicketAdjunto

# Adjunto de un ticket

var id: int = -1
var ticket_id: int = -1
var nombre_archivo: String = ""
var ruta: String = ""
var tipo_mime: String = ""
var subido_por: int = -1
var subido_por_nombre: String = ""
var subido_en: String = ""

func _init(data: Dictionary = {}):
	cargar_desde_diccionario(data)

func cargar_desde_diccionario(data: Dictionary):
	if data.has("id"): id = int(data.id)
	if data.has("ticket_id"): ticket_id = int(data.ticket_id)
	if data.has("nombre_archivo"): nombre_archivo = data.nombre_archivo
	if data.has("ruta"): ruta = data.ruta
	if data.has("tipo_mime"): tipo_mime = data.tipo_mime
	if data.has("subido_por"): subido_por = int(data.subido_por)
	if data.has("subido_por_nombre"): subido_por_nombre = data.subido_por_nombre
	if data.has("subido_en"): subido_en = data.subido_en

func a_diccionario() -> Dictionary:
	return {
		"id": id,
		"ticket_id": ticket_id,
		"nombre_archivo": nombre_archivo,
		"ruta": ruta,
		"tipo_mime": tipo_mime,
		"subido_por": subido_por,
		"subido_en": subido_en
	}

func es_imagen() -> bool:
	return tipo_mime.begins_with("image/")

func es_pdf() -> bool:
	return tipo_mime == "application/pdf"

func obtener_extension() -> String:
	return nombre_archivo.get_extension()

func obtener_ruta_completa() -> String:
	return "res://adjuntos/" + ruta