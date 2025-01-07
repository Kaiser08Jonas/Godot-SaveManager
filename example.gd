extends Control

var save_name: int = 1

var data: Dictionary = {
	"count1" = 0,
	"count2" = 5,
}

func _on_plus_pressed() -> void:
	data["count1"] += 1
	%Count1.text = str(data["count1"])


func _on_minus_pressed() -> void:
	data["count1"] -= 1
	%Count1.text = str(data["count1"])


func _on_save_pressed() -> void:
	SaveLoad.save_data(str(save_name), data)


func _on_load_pressed() -> void:
	SaveLoad.load_data(str(save_name), data)
	%Count1.text = str(data["count1"])
	%Count2.text = str(data["count2"])
	print(data)

# This is an example of how the status signals can be used.
func _ready() -> void:
	# Connect the signal to the functions
	SaveLoad.save_successful.connect(_on_save_successful)
	SaveLoad.save_failed.connect(_on_save_failed)
	SaveLoad.load_successful.connect(_on_load_successful)
	SaveLoad.load_failed.connect(_on_load_failed)
	%Savefilename.text = "Savefilename: " + str(save_name)

func _on_save_successful():
	print("save successful")

func _on_save_failed():
	print("save failed")

func _on_load_successful():
	print("loade successful")

func _on_load_failed():
	print("load failed")


func _on_savefileplus_pressed() -> void:
	save_name += 1
	%Savefilename.text = "Savefilename: " + str(save_name)


func _on_savefileminus_pressed() -> void:
	save_name -= 1
	%Savefilename.text = "Savefilename: " + str(save_name)
