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
