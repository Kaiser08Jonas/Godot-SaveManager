extends Node

const save_path = "user://savegame.save"

var is_saving: bool
var save_again: bool
var is_loading: bool

# Status signals
signal save_successful
signal save_failed
signal load_successful
signal load_failed

var data: Dictionary = {
	# This is where the variables to be stored go
	# For example:
	# "KEY": VALUE
	"count1" = 0,
	"count2" = 2,
	#"count3" = 983275
}


# Save data
func save_data() -> bool:
	# Check if the data is already being saved to avoid multiple simultaneous saves
	if is_saving:
		save_again = true # If another save is requested during an ongoing save, set save_again to true
		return false
	
	is_saving = true # Mark the process as saving
	
	var file : FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	# Check if the file was successfully opened for writing
	if file == null:
		printerr("Failed to save data. Can`t write file.")
		save_failed.emit()
		return false
	
	# Store the data in the file
	file.store_var(data)
	file.close()
	
	is_saving = false # Mark the process as done
	
	# If another save was requested while saving, perform the save again
	if save_again:
		save_again = false
		save_data() # Recursively save the data if requested during the previous save
		
	save_successful.emit()
	return true


# Load data
func load_data() -> bool:
	# Check if data is already being loaded to prevent loading multiple times at once
	if is_loading:
		print("Already loading the game")
		return false
	
	is_loading = true # Mark the process as loading
	
	# Check if the file exists
	if !FileAccess.file_exists(save_path):
		printerr("Failed to load data. File does not exist.")
		load_failed.emit()
		return false
	
	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	# Check if the file was successfully opened for reading
	if file == null:
		printerr("Failed to load data. Can`t read file.")
		load_failed.emit()
		return false
	
	var loaded_data: Variant = file.get_var()
	var filtered_data: Dictionary = {}
	
	# Ensure that the loaded data is a dictionary
	if typeof(loaded_data) == TYPE_DICTIONARY:
		# Filter the loaded data to include only the expected keys
		for key in data.keys():
			if loaded_data.has(key):
				filtered_data[key] = loaded_data[key]
		# Merge the filtered data with the original data
		data.merge(filtered_data, true) # Overwrite old values with new values if they exist
	else:
		printerr("Failed to load data. Data is not a valid dictionary.")
		load_failed.emit()
		return false
	
	file.close()
	
	is_loading = false # Mark the loading process as done
	
	load_successful.emit()
	return true
