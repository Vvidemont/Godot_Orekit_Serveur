# res://global/SatelliteRegistry.gd
extends Node
# Registre global des satellites : création, suppression, accès et signaux.

signal satellite_added(id: int)
# Émis lorsqu’un nouveau satellite est ajouté.
signal satellite_removed(id: int)
# Émis lorsqu’un satellite est supprimé.

# --- Classe interne représentant un satellite ---
class Satellite:
	var id: int
	# Identifiant unique du satellite.
	var name: String
	# Nom du satellite.
	var trajectory: Array
	# Liste des positions temporelles [[t,x,y,z], ...].
	var color: Color
	# Couleur d’affichage dans la scène 3D.
	var meta_input = {}
	# Dictionnaire stockant les paramètres d’entrée (origine JSON, etc.).

	func _init(_id: int, _name: String, _trajectory: Array, _color: Color, _meta_input: Dictionary = {}) -> void:
		# Initialise un satellite avec ses attributs.
		id = _id
		name = _name
		trajectory = _trajectory
		color = _color
		meta_input = _meta_input

# --- Données du registre ---
var _next_id: int = 1
# Prochain identifiant disponible (auto-incrémenté).
var _by_id: Dictionary = {}
# Dictionnaire : id → Satellite.

func add_satellite(name: String, color: Color, trajectory: Array, meta_input: Dictionary = {}) -> int:
	# Ajoute un satellite au registre global.
	var id := _next_id
	_next_id += 1
	var sat := Satellite.new(id, name, trajectory, color, meta_input)
	_by_id[id] = sat
	emit_signal("satellite_added", id)
	return id

func remove_satellite(id: int) -> void:
	# Supprime un satellite par son identifiant.
	if _by_id.has(id):
		_by_id.erase(id)
		emit_signal("satellite_removed", id)

func get_all() -> Array:
	# Retourne la liste complète des satellites (objets Satellite).
	return _by_id.values()

func get_one(id: int) -> Satellite:
	# Retourne un satellite précis ou null s’il n’existe pas.
	return _by_id.get(id, null)

func get_meta_input(id: int) -> Dictionary:
	# Retourne les paramètres d’entrée d’un satellite.
	var s := get_one(id)
	return s.meta_input if s else {}
