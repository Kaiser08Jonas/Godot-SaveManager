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
	SaveManager.save_data(str(save_name), data)


func _on_load_pressed() -> void:
	SaveManager.load_data(str(save_name), data)
	%Count1.text = str(data["count1"])
	%Count2.text = str(data["count2"])


# This is an example of how the status signals can be used.
func _ready() -> void:
	%Savefilename.text = "Savefilename: " + str(save_name)


func _on_savefileplus_pressed() -> void:
	save_name += 1
	%Savefilename.text = "Savefilename: " + str(save_name)


func _on_savefileminus_pressed() -> void:
	save_name -= 1
	%Savefilename.text = "Savefilename: " + str(save_name)
