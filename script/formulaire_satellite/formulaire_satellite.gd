extends Control
# Interface de création de satellite et envoi des données à Orekit (backend).

# --- HTTP ---
@onready var http : HTTPRequest = $HTTPRequest
# Nœud de requêtes HTTP pour communiquer avec le serveur.
const ENDPOINT := "http://localhost:8080/orekit"
# Adresse locale du backend Java (Orekit).

# --- Caméra / Scène satellite ---
@export var _follower_scene: PackedScene
# Référence à la scène satellite (follower 3D affiché en orbite).

# --- Paramètres initiaux ---
@onready var sat_name : LineEdit = $Panel/MarginContainer/VBoxContainer/GridContainer2/LineEditsatname
# Nom du satellite.
@onready var spin_dt: SpinBox = $Panel/MarginContainer/VBoxContainer/GridContainer2/SpinBoxdt
# Pas de temps pour la propagation.
@onready var line_epoch: LineEdit = $Panel/MarginContainer/VBoxContainer/HBoxContainer/LineEditepoch
# Date de référence de l’orbite.
@onready var color : ColorPickerButton = $Panel/MarginContainer/VBoxContainer/GridContainer2/ColorPickerButtoncolor
# Couleur choisie pour représenter le satellite.
@onready var option_button : OptionButton = $Panel/MarginContainer/VBoxContainer/GridContainer2/OptionButton
# Permet de choisir entre paramètres “classiques” ou “cartésiens”.

# --- Grids pour les deux types d’entrée ---
@onready var grid_classique : GridContainer = $Panel/MarginContainer/VBoxContainer/GridContainerClassique
# Conteneur pour les paramètres orbitaux classiques.
@onready var grid_cartesien : GridContainer = $"Panel/MarginContainer/VBoxContainer/GridContainerCartésien"
# Conteneur pour les coordonnées cartésiennes.

# --- Entrée Classique ---
@onready var spin_a: SpinBox = $Panel/MarginContainer/VBoxContainer/GridContainerClassique/SpinBoxa
@onready var spin_e: SpinBox = $Panel/MarginContainer/VBoxContainer/GridContainerClassique/SpinBoxe
@onready var spin_i: SpinBox = $Panel/MarginContainer/VBoxContainer/GridContainerClassique/SpinBoxi
@onready var spin_raan: SpinBox = $Panel/MarginContainer/VBoxContainer/GridContainerClassique/SpinBoxraan
@onready var spin_argp: SpinBox = $Panel/MarginContainer/VBoxContainer/GridContainerClassique/SpinBoxargp
@onready var spin_ta: SpinBox = $Panel/MarginContainer/VBoxContainer/GridContainerClassique/SpinBoxta
# Paramètres orbitaux : a, e, i, RAAN, ω, ν.

# --- Entrée Cartésienne ---
@onready var spin_x: SpinBox = $"Panel/MarginContainer/VBoxContainer/GridContainerCartésien/SpinBoxX"
@onready var spin_y: SpinBox = $"Panel/MarginContainer/VBoxContainer/GridContainerCartésien/SpinBoxY"
@onready var spin_z: SpinBox = $"Panel/MarginContainer/VBoxContainer/GridContainerCartésien/SpinBoxZ"
@onready var spin_vx: SpinBox = $"Panel/MarginContainer/VBoxContainer/GridContainerCartésien/SpinBoxVx"
@onready var spin_vy: SpinBox = $"Panel/MarginContainer/VBoxContainer/GridContainerCartésien/SpinBoxVy"
@onready var spin_vz: SpinBox = $"Panel/MarginContainer/VBoxContainer/GridContainerCartésien/SpinBoxtVz"
# Coordonnées position (x, y, z) et vitesse (vx, vy, vz).

# --- Boutons ---
@onready var btn_res: Button = $Panel/MarginContainer/VBoxContainer/HBoxContainer2/ButtonRes
# Bouton “Résultat” pour lancer le calcul.
@onready var btn_ann: Button = $Panel/MarginContainer/VBoxContainer/HBoxContainer2/ButtonAnn
# Bouton “Annuler” pour revenir en arrière.
# Label d’affichage de texte ou d’erreurs.

# Variables temporaires
var last_body: Dictionary
var p1; var p2; var p3; var p4; var p5; var p6; var type

func _ready() -> void:
	# Connexion des signaux aux fonctions correspondantes.
	http.request_completed.connect(_on_request_completed)
	btn_res.pressed.connect(_on_result_pressed)
	btn_ann.pressed.connect(_on_ann)
	option_button.item_selected.connect(_type_choice)

func _on_result_pressed() -> void:
	# Selon le mode sélectionné, lit les valeurs correspondantes.
	match option_button.get_selected():
		# Parametre classique
		0:
			p1 = spin_a.value * 1000.0		#a
			p2 = spin_e.value				#e
			p3 = spin_i.value				#i
			p4 = spin_raan.value			#raan
			p5 = spin_argp.value			#argp
			p6 = spin_ta.value				#ta
			type = 0
		# Parametre cartésien
		1:
			p1 = spin_x.value * 1000		#x
			p2 = spin_y.value * 1000		#y
			p3 = spin_z.value * 1000		#z
			p4 = spin_vx.value * 1000		#vx
			p5 = spin_vy.value * 1000		#vy
			p6 = spin_vz.value * 1000		#vz
			type = 1
	
	var epoch_text := line_epoch.text.strip_edges()
	if epoch_text.is_empty():
		epoch_text = "2025-09-22T00:00:00Z"
		# Valeur par défaut si aucune date n’est saisie.

	# Construction du dictionnaire JSON à envoyer.
	var body: Dictionary = {
		"action": "compute_orbit",
		"params": {
			"p1": p1,
			"p2": p2,
			"p3": p3,
			"p4": p4,
			"p5": p5,
			"p6": p6,
			"type": type,
			"frame": "EME2000",
			"epoch_start": epoch_text,
			"epoch_end": Global.sim_end,
			"dt_seconds": int(spin_dt.value)
		}
	}

	last_body = body.duplicate(true)
	# Sauvegarde du corps pour réutilisation.
	var json := JSON.stringify(body)
	var headers := PackedStringArray(["Content-Type: application/json"])

	btn_res.disabled = true
	# Désactive le bouton pendant l’envoi.

	var err := http.request(ENDPOINT, headers, HTTPClient.METHOD_POST, json)
	if err != OK:
		btn_res.disabled = false
		# Réactive le bouton en cas d’échec d’envoi.

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	btn_res.disabled = false
	# Réactive le bouton à la réception.

	if response_code != 200:
		return  # Arrête si erreur serveur.

	var raw := body.get_string_from_utf8()
	var parsed :Variant = JSON.parse_string(raw)
	if parsed == null or not (parsed is Dictionary):
		return

	var data := parsed as Dictionary
	if not data.get("ok", false):
		return

	var result_data_any :Variant = data.get("result", {})
	if not (result_data_any is Dictionary):
		return
		
	var result_data := result_data_any as Dictionary
	
	# --- Récupère la trajectoire calculée ---
	var arr_data : Array = result_data.get("data", [])

	# Ajoute le satellite dans le registre global.
	var name := sat_name.text.strip_edges()
	if name.is_empty():
		name = "Satellite %s" % Time.get_datetime_string_from_system()
	var sat_color := color.color
	
	var meta_input :Dictionary = last_body["params"].duplicate(true)
	meta_input["action"] = last_body["action"]
	SatelliteRegistry.add_satellite(name, sat_color, arr_data, meta_input)

	# Affiche la durée de simulation renvoyée.
	var tv : Variant = result_data.get("time_length", {})
	var t := tv as float
	print(t)

	var n : Variant = result_data.get("n", {})
	print(n)

func _on_ann() -> void:
	# Revient au formulaire de simulation (annulation).
	var ui_parent := get_parent()
	var hud_scene: PackedScene = load("res://scenes/formulaire_simulation.tscn")
	var hud := hud_scene.instantiate()
	ui_parent.add_child(hud)
	queue_free()

func _type_choice(index: int) -> void:
	# Affiche le bon panneau selon le mode choisi.
	match option_button.get_selected():
		0:
			grid_classique.show()
			grid_cartesien.hide()
		1:
			grid_classique.hide()
			grid_cartesien.show()
