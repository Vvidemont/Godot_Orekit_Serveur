extends Control
# Interface de gestion du temps simulé (lecture, date, vitesse).

@onready var slider_time: HSlider = $Panel/MarginContainer/VBoxContainer/GridContainer/VBoxContainer/HSlider
# Curseur contrôlant la vitesse de simulation.
@onready var Label_time: Label = $Panel/MarginContainer/VBoxContainer/GridContainer/VBoxContainer/HBoxContainer/Label2
# Affiche la vitesse actuelle (en secondes simulées/s réelles).
@onready var slider_date: HSlider = $Panel/MarginContainer/VBoxContainer/GridContainer/VBoxContainer2/HSlider
# Curseur représentant le temps simulé écoulé.
@onready var label_date: Label = $Panel/MarginContainer/VBoxContainer/GridContainer/VBoxContainer2/HBoxContainer/Label2
# Affiche la date correspondante au temps simulé.
var _accum := 0.0
# Accumulateur pour lisser le passage du temps simulé.

func _ready() -> void:
	# Initialise les valeurs et connecte les signaux des sliders.
	_on_slider_changed(slider_time.value)
	slider_time.value_changed.connect(_on_slider_changed)
	slider_date.value_changed.connect(_on_slider_date_changed)
	_set_date()

func _on_slider_changed(value: float) -> void:
	# Met à jour l’affichage de la vitesse et la vitesse de lecture globale.
	Label_time.text = "%.0f s" % value
	var sim = get_tree().get_current_scene()
	sim.set_playback_speed_all(value)

func _on_slider_date_changed(value: float) -> void:
	# Met à jour le temps simulé global et réécrit la date.
	Global.actual_time = int(slider_date.value)
	_write_date()

func _set_date() -> void:
	# Configure le slider de date selon la durée de simulation.
	slider_date.max_value = Global.sim_duration
	slider_date.min_value = 0
	slider_date.step = 1
	slider_date.value = 0
	Global.actual_time = 0
	label_date.text = Global.sim_start

func _write_date() -> void:
	# Convertit le temps simulé en date ISO lisible.
	var start_dt := Time.get_datetime_dict_from_datetime_string(Global.sim_start, true)
	var unix_time := Time.get_unix_time_from_datetime_dict(start_dt)
	unix_time += Global.actual_time
	var new_dt := Time.get_datetime_dict_from_unix_time(unix_time)
	var new_iso := "%04d-%02d-%02dT%02d:%02d:%02dZ" % [
		new_dt.year, new_dt.month, new_dt.day,
		new_dt.hour, new_dt.minute, new_dt.second
	]
	label_date.text = new_iso

func _process(delta: float) -> void:
	# Fait avancer ou reculer la simulation selon la vitesse choisie.
	var speed := float(slider_time.value)
	if speed == 0.0:
		return

	_accum += delta * speed

	# Avance d’une seconde simulée à la fois.
	while _accum >= 1.0:
		_accum -= 1.0
		if Global.actual_time < int(Global.sim_duration):
			Global.actual_time += 1
			slider_date.set_value_no_signal(float(Global.actual_time))
			_write_date()
		else:
			_accum = 0.0
			break

	# Recul d’une seconde simulée si vitesse négative.
	while _accum <= -1.0:
		_accum += 1.0
		if Global.actual_time > 0:
			Global.actual_time -= 1
			slider_date.set_value_no_signal(float(Global.actual_time))
			_write_date()
		else:
			_accum = 0.0
			break
