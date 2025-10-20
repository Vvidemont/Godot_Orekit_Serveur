extends Node3D
# Contrôle le déplacement d’un satellite le long d’une trajectoire 3D.

@export var loop: bool = true
# Si vrai, la trajectoire se répète en boucle.
@export var playback_speed: float = 1.0
# Vitesse de lecture de la trajectoire.
@export var sat_id: int = -1
# Identifiant unique du satellite (lié au registre global).
@export var create_default_mesh: bool = true
# Crée un cube si aucun Mesh n’est présent dans la scène.

var _pos: PackedVector3Array = PackedVector3Array()
# Liste des positions 3D du satellite.
var _t: PackedFloat32Array = PackedFloat32Array()
# Liste des instants temporels correspondants.
var _seg: int = 0
# Index du segment courant (entre deux points successifs).
var _default_mesh: MeshInstance3D = null
# Mesh par défaut (cube) si aucune géométrie n’existe.

func _ready() -> void:
	# Cache le nœud tant qu’il n’a pas de trajectoire assignée.
	visible = false

	var has_mesh: bool = false
	for c: Node in get_children():
		if c is MeshInstance3D:
			has_mesh = true
			break

	# Si aucun mesh n’existe et que l’option est activée → créer un cube.
	if create_default_mesh and not has_mesh:
		_default_mesh = MeshInstance3D.new()
		_default_mesh.mesh = BoxMesh.new()
		add_child(_default_mesh)

func set_trajectory(rows: Array) -> void:
	# Charge une nouvelle trajectoire depuis un tableau de points.
	_pos.clear()
	_t.clear()

	if rows.is_empty():
		visible = false
		return

	# Décale le temps pour que t0 = 0.
	var t0: float = float(rows[0][0])
	for r in rows:
		var vx: float = float(r[1])
		var vy: float = float(r[2])
		var vz: float = float(r[3])
		# Convertit [t, x, y, z] en coordonnées Godot (x, z, -y).
		_pos.push_back(Vector3(vx, vz, -vy))
		_t.push_back(float(r[0]) - t0)

	_seg = 0
	visible = true
	global_position = _pos[0]
	# Place le satellite au début de la trajectoire.

func _process(_delta: float) -> void:
	# Mise à jour du mouvement à chaque frame.
	if not visible or _pos.size() < 2:
		return

	var sim_t: float = float(Global.actual_time)
	var total: float = float(_t[_t.size() - 1])

	# Gestion des limites ou de la boucle de simulation.
	if loop and total > 0.0:
		sim_t = float(fposmod(sim_t, total))
	else:
		if sim_t <= 0.0:
			_seg = 0
			_seek_and_orient(0.0)
			return
		if sim_t >= total:
			_seg = _t.size() - 2
			_seek_and_orient(total)
			return

	# Recherche du bon segment pour interpoler la position.
	while _seg > 0 and sim_t < float(_t[_seg]):
		_seg -= 1
	while _seg < _t.size() - 2 and sim_t > float(_t[_seg + 1]):
		_seg += 1

	_seek_and_orient(sim_t)
	# Interpole la position et ajuste l’orientation du satellite.

func _seek_and_orient(sim_t: float) -> void:
	# Interpolation linéaire de la position et orientation vers la direction du mouvement.
	var t0: float = float(_t[_seg])
	var t1: float = float(_t[_seg + 1])
	var p0: Vector3 = _pos[_seg]
	var p1: Vector3 = _pos[_seg + 1]

	var dt: float = max(t1 - t0, 1e-6)
	var alpha: float = clamp((sim_t - t0) / dt, 0.0, 1.0)

	var p: Vector3 = p0.lerp(p1, alpha)
	global_position = p

	# Calcule la direction du segment et oriente le satellite.
	var dir: Vector3 = p1 - p0
	if dir.length_squared() > 1e-10:
		var ahead: Vector3 = p + dir.normalized() * max(dir.length() * 0.01, 0.01)
		if not p.is_equal_approx(ahead):
			look_at(ahead, Vector3.UP)
	# Si segment nul → garde l’orientation actuelle.
