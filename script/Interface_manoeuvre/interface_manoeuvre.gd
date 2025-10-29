extends Control
# Interface de saisie et d’envoi d’une manœuvre de Hohmann vers le serveur Orekit.

# --- HTTP ---
@onready var http : HTTPRequest = $HTTPRequest
# Nœud utilisé pour envoyer la requête HTTP.
const ENDPOINT := "http://localhost:8080/orekit"
# Adresse du serveur backend Java (Orekit).

# --- Entrées générales ---
@onready var man_type : OptionButton = $Panel/MarginContainer/CenterContainer/VBoxContainer/HBoxContainer/OptionButton
@onready var sat_name : LineEdit = $Panel/MarginContainer/CenterContainer/VBoxContainer/HBoxContainer3/LineEdit
# Nom du satellite.
@onready var spin_dt: SpinBox = $Panel/MarginContainer/CenterContainer/VBoxContainer/GridContainer/SpinBox3
# Pas de temps pour l’échantillonnage.
@onready var sat_color: ColorPickerButton = $Panel/MarginContainer/CenterContainer/VBoxContainer/GridContainer/ColorPickerButton
# Couleur du satellite créé.

# --- Entrées hohmann ---
@onready var a_init: SpinBox = $Panel/MarginContainer/CenterContainer/VBoxContainer/GridContainerHohmann/SpinBox
# Demi-grand axe initial (km).
@onready var a_final: SpinBox = $Panel/MarginContainer/CenterContainer/VBoxContainer/GridContainerHohmann/SpinBox2
# Demi-grand axe final (km).
# --- Entrées inclinaison ---
@onready var spin_a: SpinBox = $Panel/MarginContainer/CenterContainer/VBoxContainer/GridContainerInclination/SpinBoxa
@onready var spin_e: SpinBox = $Panel/MarginContainer/CenterContainer/VBoxContainer/GridContainerInclination/SpinBoxe
@onready var spin_i: SpinBox = $Panel/MarginContainer/CenterContainer/VBoxContainer/GridContainerInclination/SpinBoxi
@onready var spin_raan: SpinBox = $Panel/MarginContainer/CenterContainer/VBoxContainer/GridContainerInclination/SpinBoxraan
@onready var spin_argp: SpinBox = $Panel/MarginContainer/CenterContainer/VBoxContainer/GridContainerInclination/SpinBoxargp
@onready var spin_ta: SpinBox = $Panel/MarginContainer/CenterContainer/VBoxContainer/GridContainerInclination/SpinBoxta
@onready var type_node : OptionButton = $Panel/MarginContainer/CenterContainer/VBoxContainer/GridContainerInclination/OptionButtonNode
@onready var i_change : SpinBox = $Panel/MarginContainer/CenterContainer/VBoxContainer/GridContainerInclination/SpinBoxichange
# --- Paramètres de manœuvre ---
@onready var opt_button : OptionButton = $Panel/MarginContainer/CenterContainer/VBoxContainer/GridContainer/OptionButton
# Choix du mode de définition de la manœuvre.
@onready var opt_edit : LineEdit = $Panel/MarginContainer/CenterContainer/VBoxContainer/GridContainer/LineEdit
# Entrée texte (valeur manuelle, ex. date ISO).
@onready var opt_spin : SpinBox = $Panel/MarginContainer/CenterContainer/VBoxContainer/GridContainer/SpinBoxoption
# Entrée numérique (valeur relative ou orbitale).

# --- Boutons ---
@onready var btn_val: Button = $Panel/MarginContainer/CenterContainer/VBoxContainer/HBoxContainer2/Button
# Bouton de validation et envoi au serveur.
@onready var btn_ret: Button = $Panel/MarginContainer/CenterContainer/VBoxContainer/HBoxContainer2/Button2
# Bouton retour au menu précédent.

var manvalue
# Valeur associée à la manœuvre (date, délai, période…).
var last_body: Dictionary

var info :Dictionary
func _ready() -> void:
	# Connexion des signaux.
	http.request_completed.connect(_on_request_completed)
	btn_val.pressed.connect(_on_result_pressed)
	btn_ret.pressed.connect(_on_ann)
	_get_modif()

func _on_result_pressed() -> void:
	var body: Dictionary
	match man_type.get_selected_id():
		0:
	# Construit le corps JSON pour la requête de calcul Hohmann.
			body = {
			"action": "compute_hohmann",
			"params": {
				"type": "Hohmann",
				"a_init": a_init.value * 1000.0,
				"a_final": a_final.value * 1000.0,
				"man_method": opt_button.get_selected(),
				"man_value": _get_opt_value(),
				"epoch_start": Global.sim_start,
				"epoch_end": Global.sim_end,
				"dt": int(spin_dt.value)
			}
		}
		1:
			body = {
			"action": "compute_inclination",
			"params": {
				"type": "Inclination",
				"a": spin_a.value * 1000.0,
				"e": spin_e.value,
				"i": spin_i.value,
				"raan": spin_raan.value,
				"argp": spin_argp.value,
				"ta": spin_ta.value,
				"node": _get_node(),
				"itarget": i_change.value,
				"epoch_start": Global.sim_start,
				"epoch_end": Global.sim_end,
				"man_method": opt_button.get_selected(),
				"man_value": _get_opt_value(),
				"dt": int(spin_dt.value)
			}
		}
	
	last_body = body.duplicate(true)
	var json := JSON.stringify(body)
	var headers := PackedStringArray(["Content-Type: application/json"])

	# Vérifie qu’aucune requête n’est déjà en cours.
	if http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		print("Requête déjà en cours, annulation.")
		return

	btn_val.disabled = true
	# Désactive le bouton pendant l’envoi.
	var err := http.request(ENDPOINT, headers, HTTPClient.METHOD_POST, json)
	if err != OK:
		btn_val.disabled = false
		push_error("HTTPRequest failed to start: %s" % err)

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	# Analyse la réponse JSON reçue du serveur Orekit.
	btn_val.disabled = false
	var raw := body.get_string_from_utf8()

	if response_code != 200:
		push_error("HTTP code != 200: %s" % response_code)
		return

	var parsed : Variant = JSON.parse_string(raw)
	if parsed == null or not (parsed is Dictionary):
		push_error("Réponse non-JSON ou non-Dict")
		return

	var data := parsed as Dictionary
	if not data.get("ok", false):
		push_error("Serveur a renvoyé ok=false: %s" % data.get("error", ""))
		return

	var result_data_any : Variant = data.get("result", {})
	if not (result_data_any is Dictionary):
		push_error("Champ 'result' non-objet")
		return
	
	var id_sat = 0
	
	if Global.id_info != null:
		id_sat = Global.id_info
		SatelliteRegistry.remove_satellite(Global.id_info)
		
	var result_data := result_data_any as Dictionary
	var arr_data : Array = result_data.get("data", [])
	if arr_data.is_empty():
		push_warning("Avertissement: 'data' est vide")

	# Crée un nouveau satellite à partir des données calculées.
	var name := sat_name.text.strip_edges()
	if name.is_empty():
		name = "Satellite %s" % Time.get_datetime_string_from_system()
	var chosen_color := sat_color.color
	var meta_input :Dictionary = last_body["params"].duplicate(true)
	meta_input["action"] = last_body["action"]
	SatelliteRegistry.add_satellite(name, chosen_color,arr_data,id_sat,meta_input)
	print("Satellite ajouté: ", name, " points=", arr_data.size())

func _on_ann() -> void:
	# Retourne au formulaire de simulation.
	Global.id_info = null
	var ui_parent := get_parent()
	var hud_scene: PackedScene = load("res://scenes/formulaire_simulation.tscn")
	var hud := hud_scene.instantiate()
	ui_parent.add_child(hud)
	queue_free()

func _get_opt_value():
	# Récupère la valeur selon le type d’entrée choisi.
	match opt_button.get_selected():
		0:
			return str(opt_edit.text)
		1, 2:
			return int(opt_spin.value)

func _get_node():
	match type_node.get_selected_id():
		0:
			return str(true)
		1:
			return str(false)
			
func _get_modif() :
	if Global.id_info != null:
		var sat_id: int = Global.id_info
		var sat: SatelliteRegistry.Satellite = SatelliteRegistry.get_one(sat_id)
		
		info = sat.meta_input
		sat_name.text = str(sat.name)
		spin_dt.value = info["dt"]
		sat_color.color = sat.color
		opt_button.selected = info["man_method"]
		
		match info["man_method"]:
			0:
				opt_edit.text = info["man_value"]
			1,2:
				opt_spin.value = info["man_value"]
		
		match info["type"] :
			"Hohmann":
				a_init.value = info["a_init"]  * 1e-3
				a_final.value = info["a_final"] * 1e-3
				
			
				
	else :
		return
