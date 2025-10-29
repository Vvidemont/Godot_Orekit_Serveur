extends OptionButton

@onready var opt_button : OptionButton = $"."
@onready var opt_label : Label = $"../Labeloption"
@onready var opt_spin : SpinBox = $"../SpinBoxoption"
@onready var opt_edit : LineEdit = $"../LineEdit"
var info :Dictionary
func _ready() -> void:
	select(0)

	# Connexion du signal (il passe l'index sélectionné)
	item_selected.connect(_on_item_selected)

	# État initial
	_on_item_selected(get_selected())

func _on_item_selected(index: int) :
	if Global.id_info != null:
		var sat_id: int = Global.id_info
		var sat: SatelliteRegistry.Satellite = SatelliteRegistry.get_one(sat_id)
		info = sat.meta_input
		 
		match int(info["man_method"]):
			0:
				_date_selected()
			1:
				_time_selected()
			2:
				_orbit_selected()
	else :
		match index:
			0:
				_date_selected()
			1:
				_time_selected()
			2:
				_orbit_selected()
			_:
			# Sécurité
				opt_spin.hide()
				opt_edit.hide()

func _date_selected() -> void :
	opt_spin.hide()
	opt_edit.show()
	opt_label.text = "Date"
	opt_edit.text = Global.sim_start

func _orbit_selected() -> void :
	opt_label.text = "nb orbite"
	opt_spin.show()
	opt_edit.hide()
	opt_spin.value = 1
	opt_spin.step = 1

func _time_selected() -> void :
	opt_label.text = "Temps [s]"
	opt_spin.show()
	opt_edit.hide()
	opt_spin.value = 1
	opt_spin.step = 1
