extends Node3D
# Script de rig caméra orbitale (rotation, zoom, focus sur cible).

@onready var cam: Camera3D = $Camera3D
# Référence directe à la caméra enfant.

# --- Réglages de base ---
var target: Vector3 = Vector3.ZERO
# Point que la caméra regarde.
var distance: float = 12.0
# Distance actuelle entre caméra et cible.
var min_distance: float = 2.0
# Distance minimale autorisée (zoom max).
var max_distance: float = 200.0
# Distance maximale autorisée (zoom out).

var zoom_step: float = 1.1
# Facteur de zoom par cran de molette.
var zoom_lerp_speed: float = 12.0
# Vitesse de transition du zoom (lissage).

var rotate_sens: float = 0.2
# Sensibilité de rotation à la souris.
var min_pitch_deg: float = -85.0
# Inclinaison minimale (empêche de retourner la caméra).
var max_pitch_deg: float = 85.0
# Inclinaison maximale.

var focus_node: Node3D = null
# Cible suivie automatiquement (ex : satellite).

# --- État interne ---
var _dragging := false
# Indique si clic droit maintenu.
var _yaw_deg := 0.0
# Angle de rotation horizontale.
var _pitch_deg := 20.0
# Angle vertical initial.
var _target_distance: float
# Distance visée (interpolée par le zoom).

func _ready() -> void:
	# Initialise la caméra au démarrage.
	add_to_group("camera_rig")
	global_position = target
	_target_distance = clamp(distance, min_distance, max_distance)
	_update_camera_local()

func _process(delta: float) -> void:
	# Lisse la distance vers la cible (zoom fluide).
	var alpha: float = clamp(zoom_lerp_speed * delta, 0.0, 1.0)
	distance = lerp(distance, _target_distance, alpha)

	# Si un node est ciblé, la caméra suit sa position.
	if focus_node and is_instance_valid(focus_node):
		target = focus_node.global_position

	# Met à jour la position locale de la caméra.
	_update_camera_local()

func focus_on_node(node: Node3D) -> void:
	# Définit un node à suivre (focus caméra).
	focus_node = node

func _unhandled_input(event: InputEvent) -> void:
	# Clic droit → active ou désactive le drag.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		_dragging = event.pressed

	# Si on déplace la souris pendant le drag → rotation caméra.
	if event is InputEventMouseMotion and _dragging:
		_yaw_deg   -= event.relative.x * rotate_sens
		_pitch_deg -= event.relative.y * rotate_sens
		_pitch_deg = clamp(_pitch_deg, min_pitch_deg, max_pitch_deg)
		# _process se charge de mettre à jour chaque frame.

	# Molette → modifie la distance cible (zoom in/out).
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_target_distance = clamp(_target_distance / zoom_step, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_target_distance = clamp(_target_distance * zoom_step, min_distance, max_distance)

func _update_camera_local() -> void:
	# Met à jour l’orientation et la position locale de la caméra.
	rotation_degrees = Vector3(_pitch_deg, _yaw_deg, 0.0)
	if cam:
		cam.transform.origin = Vector3(0.0, 0.0, distance)
