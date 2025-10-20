# res://scenes/simulation_3d.gd
extends Node3D
# Script principal de la scène 3D — gère les satellites, orbites et l’interface.

@onready var ui_layer : CanvasLayer = $UILayer
# Couche d’interface principale (HUD de simulation).
@onready var time_layer : CanvasLayer = $UILayerTime
# Couche d’interface dédiée au contrôle du temps.
var hud_scene := preload("res://scenes/formulaire_simulation.tscn")
# Précharge la scène du panneau de configuration de simulation.
var time_scene := preload("res://scenes/Temps.tscn")
# Précharge la scène du panneau de gestion du temps.
var _follower_nodes_by_id: Dictionary = {}  
# Dictionnaire : id_satellite → nœud “follower” (le cube qui bouge).
var _follower_scene := preload("res://scenes/satellite.tscn")
# Précharge la scène du satellite (follower 3D).
@onready var label: Label = $Label
# Label affichant le temps simulé.
@onready var orbits_root: Node3D = $OrbitsRoot
# Nœud racine où seront ajoutées les orbites et satellites.

var _orbit_nodes_by_id: Dictionary = {}
# Dictionnaire : id_satellite → MeshInstance3D représentant la trajectoire.

func _ready() -> void:
	# Initialise la racine d’orbites dans le singleton Global.
	Global.orbits_root = self

	# Instancie et affiche les interfaces HUD et Temps.
	var hud := hud_scene.instantiate()
	var time := time_scene.instantiate()
	ui_layer.add_child(hud)
	time_layer.add_child(time)

	# Crée toutes les orbites existantes au démarrage.
	for sat in SatelliteRegistry.get_all():
		_spawn_orbit_for_satellite(sat)

	# Connecte les signaux pour détecter ajout/suppression de satellites.
	SatelliteRegistry.satellite_added.connect(_on_satellite_added)
	SatelliteRegistry.satellite_removed.connect(_on_satellite_removed)

func _process(_delta: float) -> void:
	# Met à jour le label avec le temps actuel de simulation.
	label.text = str(Global.actual_time)

func _on_satellite_added(id: int) -> void:
	# Appelé lorsqu’un nouveau satellite est ajouté.
	var s = SatelliteRegistry.get_one(id)
	if s != null:
		_spawn_orbit_for_satellite(s)

func _on_satellite_removed(id: int) -> void:
	# Supprime les objets liés au satellite supprimé.
	if _orbit_nodes_by_id.has(id):
		_orbit_nodes_by_id[id].queue_free()
		_orbit_nodes_by_id.erase(id)
	if _follower_nodes_by_id.has(id):
		_follower_nodes_by_id[id].queue_free()
		_follower_nodes_by_id.erase(id)

func _spawn_orbit_for_satellite(sat) -> void:
	# Crée l’orbite et le follower pour un satellite donné.
	if sat == null or sat.trajectory.is_empty():
		return

	# Évite de créer des doublons si déjà existants.
	if _orbit_nodes_by_id.has(sat.id) or _follower_nodes_by_id.has(sat.id):
		return

	# --- Génération du tracé d’orbite ---
	var mesh := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = sat.color
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, mat)

	for row in sat.trajectory:
		if row.size() >= 4:
			# Données [t, x, y, z] → conversion en repère Godot.
			mesh.surface_add_vertex(Vector3(row[1], row[3], - row[2]))
		else:
			# Données [x, y, z] → conversion en repère Godot.
			mesh.surface_add_vertex(Vector3(row[0], row[2], - row[1]))
	mesh.surface_end()

	# Crée le MeshInstance3D représentant l’orbite.
	var orbit_instance := MeshInstance3D.new()
	orbit_instance.name = "Orbit_%d" % sat.id
	orbit_instance.mesh = mesh
	orbits_root.add_child(orbit_instance)
	_orbit_nodes_by_id[sat.id] = orbit_instance

	# --- Création du follower (cube satellite) ---
	var follower := _follower_scene.instantiate()
	follower.name = "Satellite_%d" % sat.id
	if "sat_id" in follower:
		follower.sat_id = sat.id
	orbits_root.add_child(follower)
	follower.set_trajectory(sat.trajectory)  # Applique la trajectoire au follower.
	_follower_nodes_by_id[sat.id] = follower

func set_playback_speed_all(v: float) -> void:
	# Change la vitesse de lecture de tous les followers.
	for f in _follower_nodes_by_id.values():
		f.playback_speed = v
