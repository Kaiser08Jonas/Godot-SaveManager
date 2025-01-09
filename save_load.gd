extends Node

const save_directory = "user://savegames/"

# Adjust these variables according to the desired functions.
var print_debug_messages: bool = true		# When true, prints the debug messages via the signals.
var can_save_empty_data: bool = false		# When true, empty data will be saved.
var delete_old_loaded_data:bool  = false	# When true, loaded data is deleted from the saved file if it is no longer in the dictionary to be loaded.

var is_saving: bool
var is_loading: bool
var save_queue: Dictionary = {} 			# Saves the data if a new save process is started during a save process.
var load_queue: Dictionary = {} 			# Saves the data if a new load process is started during a load process.

# Status signals
signal save_successful(save_name: String)										# Sends a signal if the save was successful.
signal save_failed(save_name: String, error_message: String)					# Sends a signal if the save has failed.
signal load_successful(save_name: String)										# Sends a signal if the load was successful.
signal load_failed(save_name: String, error_message: String)					# Sends a signal if the load has failed.
signal data_cleanup_successful(save_name: String)								# Sends a signal if the cleanup was successful.
signal data_cleanup_failed(save_name: String, error_message: String)			# Sends a signal if the cleanup has failed.


func _ready() -> void:
	# Connect the signal to the functions
	save_successful.connect(_on_save_successful)
	save_failed.connect(_on_save_failed)
	load_successful.connect(_on_load_successful)
	load_failed.connect(_on_load_failed)
	data_cleanup_successful.connect(_on_data_cleanup_successful)
	data_cleanup_failed.connect(_on_data_cleanup_failed)


# Function to construct the file path for saving/loading.
# Returns a string representing the full path to the save file.
func get_save_path(save_name: String, temporary: bool) -> String:
	if temporary:
		return save_directory + save_name + ".tmp"
	else:
		return save_directory + save_name + ".save"


# Ensures that the storage location exists.
func ensure_save_directory() -> bool:
	var dir: DirAccess = DirAccess.open("user://")
	# Checks if the folder was successfully opened for writing.
	if dir == null:
		printerr("Failed to access user directory.")
		return false
	# Create a folder if none exists.
	if !dir.dir_exists(save_directory):
		var result = dir.make_dir(save_directory)
		if result != OK:
			printerr("Faild to create savegames directory.")
			return false
		else:
			print("Savegames directory created.")
	return true


# Save data
func save_data(save_name: String, data_to_save: Dictionary) -> bool:
	
	# Checks if the data is already being saved to avoid multiple simultaneous saves.
	if is_saving:
		save_queue[save_name] = data_to_save
		return false
	
	is_saving = true # Mark the process as saving.
	
	# Ensure that the data to save is a dictionary.
	if typeof(data_to_save) != TYPE_DICTIONARY:
		var error_message = "Failed to save data. Data is not a dictionary."
		save_failed.emit(save_name, error_message)
		return false
	
	# Checks if the folder for the save exists.
	if !ensure_save_directory():
		var error_message: String = "Failed to ensure save directory for saving."
		save_failed.emit(save_name, error_message)
		is_saving = false
		return false
	
	# Checks if the save dictionary is empty.
	if !can_save_empty_data and data_to_save.is_empty():
		var error_message: String = "Cannot save empty data."
		save_failed.emit(save_name, error_message)
		is_saving = false
		return false
	
	var save_path = get_save_path(save_name, false)
	# Creates a temporary save path. This ensures that existing data is not damaged during loading.
	var temp_path = get_save_path(save_name, true)
	var file : FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	
	# Checks if the file was successfully opened for writing.
	if file == null:
		var error_message: String = "Failed to save data. Can`t write file."
		save_failed.emit(save_name, error_message)
		is_saving = false
		return false
	
	# Store the data in the file.
	file.store_var(data_to_save)
	file.close()
	
	# Renaming after successful save
	DirAccess.rename_absolute(temp_path, save_path)
	
	save_successful.emit(save_name)
	
	is_saving = false # Mark the process as done.
	
	check_save_queue()
	return true


func check_save_queue() -> void:
	# Checks whether further saves should be made.
	if save_queue.size() > 0:
		for key in save_queue.keys():
			var next_item = save_queue[key]
			save_queue.erase(key)
			save_data(key, next_item) # Starts the saving process for the next data in the queue.
			break


# Load data
func load_data(save_name: String, data_to_load_into: Dictionary) -> Dictionary:
	
	# Check if data is already being loaded to prevent loading multiple times at once.
	if is_loading:
		load_queue[save_name] = data_to_load_into
		return data_to_load_into
	
	is_loading = true # Mark the process as loading.
	
	if !ensure_save_directory():
		var error_message: String = "Failed to ensure save directory for loading"
		load_failed.emit(save_name, error_message)
		is_loading = false
		return data_to_load_into
	
	# Check if the file exists.
	if !FileAccess.file_exists(get_save_path(save_name, false)):
		var error_message: String = "Failed to load data. File >>" + get_save_path(save_name, false) + "<< does not exist."
		load_failed.emit(save_name, error_message)
		is_loading = false
		return data_to_load_into
	
	var file: FileAccess = FileAccess.open(get_save_path(save_name, false), FileAccess.READ)
	# Check if the file was successfully opened for reading.
	if file == null:
		var error_message: String = "Failed to load data. Can`t read file >>" + get_save_path(save_name, false) + "<< ."
		load_failed.emit(save_name, error_message)
		is_loading = false
		return data_to_load_into
	
	var loaded_data: Variant = file.get_var()
	var filtered_data: Dictionary = {}
	
	# Ensure that the loaded data is a dictionary.
	if typeof(loaded_data) == TYPE_DICTIONARY:
		# Filter the loaded data to include only the expected keys.
		for key in data_to_load_into.keys():
			if loaded_data.has(key):
				filtered_data[key] = loaded_data[key]
		# Merge the filtered data with the original data.
		data_to_load_into.merge(filtered_data, true) # Overwrite old values with new values if they exist.
	else:
		var error_message: String = "Failed to load data. Data is not a valid dictionary."
		load_failed.emit(save_name, error_message)
		is_loading = false
		return data_to_load_into
	
	file.close()
	
	if delete_old_loaded_data:
		delete_old_data(save_name, loaded_data, data_to_load_into)
	
	load_successful.emit(save_name)
	
	is_loading = false # Mark the loading process as done.
	
	check_loading_queue()
	return data_to_load_into


# Cleanup old saved data
func delete_old_data(save_name, loaded_data: Dictionary, data_to_compare: Dictionary) -> bool:
	# Checks whether the loaded data and the data to be compared are identical.
	if loaded_data == data_to_compare:
		data_cleanup_successful.emit(save_name)
		return false
	
	# Add the repuired data to a new dictionary.
	var new_data: Dictionary = {}
	for key in loaded_data:
		if data_to_compare.has(key):
			new_data[key] = loaded_data[key]
	
	var file: FileAccess = FileAccess.open(get_save_path(save_name, false), FileAccess.WRITE)
	
	# Checks if the file was successfully opened for writing.
	if file == null:
		var error_message: String = "Failed to open file for cleaning old data."
		data_cleanup_failed.emit(save_name, error_message)
		return false
	
	# Store the new data in the file.
	file.store_var(new_data)
	file.close()
	data_cleanup_successful.emit(save_name)
	return true


func check_loading_queue() -> void:
	# Checks whether further saves should be made.
	if load_queue.size() > 0:
		for key in load_queue.keys():
			var next_item = load_queue[key]
			load_queue.erase(key)
			load_data(key, next_item) # Starts the loading process for the next data in the queue.
			break


# Prints the debug messages
func _on_save_successful(save_name):
	if print_debug_messages:
		print("save successful as >> " + save_name + " <<")

func _on_save_failed(save_name, error_message):
	if print_debug_messages:
		printerr("save failed for >> " + save_name + " <<. " + error_message)

func _on_load_successful(save_name):
	if print_debug_messages:
		print("load successful from >> " + save_name + " <<")

func _on_load_failed(save_name, error_message):
	if print_debug_messages:
		printerr("load failed from >> " + save_name + " <<. " + error_message)

func _on_data_cleanup_successful(save_name):
	if print_debug_messages:
		print("data cleanup successful for >> " + save_name + " <<")

func _on_data_cleanup_failed(save_name, error_message):
	if print_debug_messages:
		printerr("data cleanup failed for >> " + save_name + " <<. " + error_message)
