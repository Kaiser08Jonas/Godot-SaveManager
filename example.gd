extends Control

var count1:  int = 0
var count2:  int = 0
var count3:  int = 0


func _on_plus_pressed() -> void:
	count1 += 1
	%Count1.text = str(count1)


func _on_minus_pressed() -> void:
	count1 -= 1
	%Count1.text = str(count1)


func _on_save_pressed() -> void:
	SaveLoad.data["count1"] = count1
	SaveLoad.save_data()


func _on_load_pressed() -> void:
	SaveLoad.load_data()
	count1 = SaveLoad.data["count1"]
	%Count1.text = str(count1)
	count2 = SaveLoad.data["count2"]
	%Count2.text = str(count2)
	#count3 = SaveLoad.data["count3"]
	#%Count3.text = str(count3)
	print(SaveLoad.data)

# This is an example of how the status signals can be used.
func _ready() -> void:
	# Connect the signal to the functions
	SaveLoad.save_successful.connect(_on_save_successful)
	SaveLoad.save_failed.connect(_on_save_failed)
	SaveLoad.load_successful.connect(_on_load_successful)
	SaveLoad.load_failed.connect(_on_load_failed)


func _on_save_successful():
	print("save successful")

func _on_save_failed():
	print("save failed")

func _on_load_successful():
	print("loade successful")

func _on_load_failed():
	print("load failed")
