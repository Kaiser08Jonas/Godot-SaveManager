extends Node

# Adjust these constants only before creating the first save file.
const SAVE_DIRECTORY: String = "user://SaveManager//savegames/"			# The data is saved in this path.
const LOG_MESSAGE_DIRECTORY: String = "user://SaveManager//debuging/"	# The log messages is saved in this path.
const LOG_FILE_NAME: String = "Log"										# Name of the log messages file.
const ENCRYPT_KEY: String = "123456abc"									# If the data should be encrypted, it will be encrypted with this key.
const ENCRYPT_FILES: bool = false										# Determines whether the data should be encrypted.

# Adjust these variables according to the desired functions.
var PRINT_DEBUG_MESSAGES: bool = true		# When true, prints the debug messages via the signals.
var PRINT_ERROR_MESSAGES: bool = true		# When true, prints the error messages via the signals.
var SAVE_LOG_MESSAGES: bool = true			# When true, save the log messages in a text file.
var can_save_empty_data: bool = false		# When true, empty data will be saved.
var clean_up: bool  = true					# When true, loaded data is deleted from the saved file if it is no longer in the dictionary to be loaded.
var wait_time_after_fail: int = 1			# Defines the time in seconds how long the FAILED status remains.

# Marks the current process status
enum process_status {IDLE, FAILED, SAVING, LOADING, CLEANING_UP}
var save_process_status: process_status = process_status.IDLE
var load_process_status: process_status = process_status.IDLE
var cleanup_process_status: process_status = process_status.IDLE

# All queues
var save_queue: Dictionary = {} 			# Saves the data if a new save process is started during a save process.
var load_queue: Dictionary = {} 			# Saves the data if a new load process is started during a load process.
var cleanup_queue: Dictionary = {}			# Saves the data if a new cleanup process is started during a cleanup process.

# Status signals
signal save_successful(save_name: String, debug_message: String)				# Sends a signal if the save was successful.
signal save_failed(save_name: String, error_message: String)					# Sends a signal if the save has failed.
signal load_successful(save_name: String, debug_message: String)				# Sends a signal if the load was successful.
signal load_failed(save_name: String, error_message: String)					# Sends a signal if the load has failed.
signal data_cleanup_successful(save_name: String, debug_message: String)		# Sends a signal if the cleanup was successful.
signal data_cleanup_failed(save_name: String, error_message: String)			# Sends a signal if the cleanup has failed.
signal delete_save_successful(save_name: String, debug_message: String)
signal delete_save_failed(save_name: String, error_message: String)
# Is used to connect the signals in the _ready function.
# If new signals are added, they must be entered in the list in order to be automatically linked to the corresponding function.
const SIGNALS: Array = ["save_successful", "save_failed", "load_successful", "load_failed", "data_cleanup_successful", "data_cleanup_failed", "delete_save_successful", "delete_save_failed"]

enum log_message_type {DEBUG, ERROR}


func _ready() -> void:
	# Connect the signal to the functions
	for signal_name in SIGNALS:
		connect(signal_name, Callable(self, "_on_" + signal_name))


# Function to construct the file path for saving/loading.
# Returns a string representing the full path to the save file.
func get_save_path(directory: String, save_name: String, temporary: bool) -> String:
	if ENCRYPT_FILES:
		if temporary:
			return directory + save_name + ".tmp"
		else:
			return directory + save_name + ".save"
	
	if temporary:
		return directory + save_name + ".tmp"
	else:
		return directory + save_name + ".save"


# Ensures that the storage location exists.
func ensure_save_directory(directory: String, save_name: String, process: String) -> bool:
	var dir: DirAccess = DirAccess.open("user://")
	# Checks if the folder was successfully opened for writing.
	if dir == null:
		if str(process) + "_data" == "save_data":
			save_failed.emit(save_name, "Failed to access user directory while saving.")
		if str(process) + "_data" == "load_data":
			load_failed.emit(save_name, "Failed to access user directory while loading.")
		return false
	
	# Create a folder if none exists.
	if !dir.dir_exists(directory):
		var result = dir.make_dir_recursive(directory)
		if result != OK:
			if str(process) + "_data" == "save_data":
				save_failed.emit(save_name, "Faild to create savegames directory. while saving.")
			if str(process) + "_data" == "load_data":
				load_failed.emit(save_name, "Faild to create savegames directory. while loading.")
			return false
		else:
			log_message(log_message_type.DEBUG, save_name, "Savegames directory created.")
	return true


# Validates the give data.
func validate_data(data_to_check: Dictionary) -> int:
	# Verifies that the data is a dictionary.
	if typeof(data_to_check) != TYPE_DICTIONARY:
		return  1 #"Failed to save data. Data is not a dictionary."
	# Checks if the data is empty.
	if !can_save_empty_data and data_to_check.is_empty():
		return 2 #"Cannot save empty data."
	
	return 0

enum file_access_mode {WRITE, READ}

# Get FileAccess
func file_access(save_path: String, mode: file_access_mode) -> FileAccess:
	# Get FileAccess without encryption
	if !ENCRYPT_FILES:
		match mode:
			file_access_mode.WRITE: return FileAccess.open(save_path, FileAccess.WRITE)
			file_access_mode.READ: return FileAccess.open(save_path, FileAccess.READ)
	# Get FileAccess with encryption
	else:
		match mode:
			file_access_mode.WRITE: return FileAccess.open_encrypted_with_pass(save_path, FileAccess.WRITE, ENCRYPT_KEY)
			file_access_mode.READ: return FileAccess.open_encrypted_with_pass(save_path, FileAccess.READ, ENCRYPT_KEY)
		
	return null


# Save data
func save_data(save_name: String, data_to_save: Dictionary) -> bool:
	
	# Checks if the data is already being saved to avoid multiple simultaneous saves.
	if save_process_status == process_status.SAVING:
		save_queue[save_name] = data_to_save
		return false
	
	save_process_status = process_status.SAVING # Mark the process as saving.
	
	if validate_data(data_to_save) > 0:
		match validate_data(data_to_save):
			1: save_failed.emit(save_name, "Failed to validate data. Data is not a dictionary.")
			2: save_failed.emit(save_name, "Cannot save empty data.")
		return false
	
	# Checks if the folder for the save exists.
	if !ensure_save_directory(SAVE_DIRECTORY, save_name, "save"):
		save_failed.emit(save_name, "Failed to ensure save directory for saving.")
		return false
	
	var save_path = get_save_path(SAVE_DIRECTORY, save_name, false)
	# Creates a temporary save path. This ensures that existing data is not damaged during saving.
	var temp_path = get_save_path(SAVE_DIRECTORY, save_name, true)
	
	var file : FileAccess = file_access(temp_path, file_access_mode.WRITE)

	# Checks if the file was successfully opened for writing.
	if file == null:
		save_failed.emit(save_name, "Failed to save data. Can`t write file.")
		return false
	
	# Store the data in the file.
	file.store_var(data_to_save)
	file.close()
	
	# Renaming after successful save
	if DirAccess.rename_absolute(temp_path, save_path) != OK:
		save_failed.emit(save_name, "Failed to rename temporary file to final save file.")
		return false
	
	save_successful.emit(save_name, "Save was successful")
	
	return true


# Load data
func load_data(save_name: String, data_to_load_into: Dictionary) -> Dictionary:
	
	# Check if data is already being loaded to prevent loading multiple times at once.
	if load_process_status == process_status.LOADING:
		load_queue[save_name] = data_to_load_into
		return data_to_load_into
	
	load_process_status = process_status.LOADING # Mark the process as loading.
	
	if !ensure_save_directory(SAVE_DIRECTORY, save_name, "loading"):
		load_failed.emit(save_name, "Failed to ensure save directory for loading.")
		return data_to_load_into
	
	# Check if the file exists.
	if !FileAccess.file_exists(get_save_path(SAVE_DIRECTORY, save_name, false)):
		load_failed.emit(save_name, "Failed to load data. File does not exist.")
		return data_to_load_into
	
	var save_path: String = get_save_path(SAVE_DIRECTORY, save_name, false)
	
	var file: FileAccess = file_access(save_path, file_access_mode.READ)
	
	# Check if the file was successfully opened for reading.
	if file == null:
		load_failed.emit(save_name, "Failed to load data. Can`t read file.")
		return data_to_load_into
	
	var loaded_data: Variant = file.get_var()
	var filtered_data: Dictionary = {}
	
	if validate_data(loaded_data) > 0:
		match validate_data(loaded_data):
			1: load_failed.emit(save_name, "Failed to validate data. Data is not a dictionary.")
			2: load_failed.emit(save_name, "Cannot load empty data.")
		return data_to_load_into
	
	# Filter the loaded data to include only the expected keys.
	for key in data_to_load_into.keys():
		if loaded_data.has(key):
			filtered_data[key] = loaded_data[key]
	# Merge the filtered data with the original data.
	data_to_load_into.merge(filtered_data, true) # Overwrite old values with new values if they exist.
	
	file.close()
	
	if clean_up:
		cleanup_data(save_name, loaded_data, data_to_load_into)
	
	load_successful.emit(save_name, "Load was successful")
	
	return data_to_load_into


# Cleanup old saved data
func cleanup_data(save_name: String, loaded_data: Dictionary, data_to_compare: Dictionary) -> bool:
	
		# Checks if the data is already being saved to avoid multiple simultaneous saves.
	if cleanup_process_status == process_status.CLEANING_UP:
		cleanup_queue[save_name] = [loaded_data, data_to_compare]
		return false
	
	cleanup_process_status = process_status.CLEANING_UP
	
	# Checks whether the loaded data and the data to be compared are identical.
	if loaded_data == data_to_compare:
		data_cleanup_successful.emit(save_name, "No data to clean found")
		return false
	
	# Add the repuired data to a new dictionary.
	# This ensures that if an error occurs during cleanup, the saved data will not be damaged.
	var new_data: Dictionary = {}
	for key in loaded_data:
		if data_to_compare.has(key):
			new_data[key] = loaded_data[key]
	
	var file: FileAccess = FileAccess.open(get_save_path(SAVE_DIRECTORY, save_name, false), FileAccess.WRITE)
	
	# Checks if the file was successfully opened for writing.
	if file == null:
		data_cleanup_failed.emit(save_name, "Failed to open file for cleaning old data.")
		return false
	
	# Store the new data in the file.
	file.store_var(new_data)
	file.close()
	data_cleanup_successful.emit(save_name, "Data cleanup was successful.")
	return true


func check_queue(queue: Dictionary, process: Callable) -> void:
	# Checks if the queue is empty
	if queue.size() > 0:
		# Checks whether further process should be made.
		if queue == cleanup_queue:
				for key in cleanup_queue.keys():
					var next_array = cleanup_queue[key]
					var next_loaded_data = next_array[0]
					var next_data_to_compare = next_array[1]
					cleanup_queue.erase(key)
					cleanup_data(key, next_loaded_data, next_data_to_compare) # Starts the cleanup process for the next data in the queue.
					break
		else:
			for key in queue.keys():
				var next_item = queue[key]
				queue.erase(key)
				process.call(key, next_item) # Starts the saving process for the next data in the queue.
				break

# Deletes a save file if it exists.
func delete_save(save_name:String) -> bool:
	var save_path = get_save_path(SAVE_DIRECTORY, save_name, false)
	
	if !FileAccess.file_exists(save_path):
		delete_save_failed.emit(save_name, "Failed to delete save. File does not exist.")
		return false
	
	var dir = DirAccess.open(SAVE_DIRECTORY)
	if dir == null:
		delete_save_failed.emit(save_name, "Failed to access save directory while deleting.")
		return false
	
	if dir.remove(save_path.get_file()) != OK:
		delete_save_failed.emit(save_name, "Failed to delete save file.")
	
	delete_save_successful.emit(save_name, "Save file deleted successfully")
	return true


# Prints the log_messages
func log_message(type: log_message_type, info: String, message: String) -> void:
	var datetime_dict = Time.get_datetime_dict_from_system()
	var datetime_string = Time.get_datetime_string_from_datetime_dict(datetime_dict, true)
	match type:
		log_message_type.DEBUG: if PRINT_DEBUG_MESSAGES: print("[DEBUG] " + message + "\n[DEBUG] Name: " + info + "\n[DEBUG] Date/time: " + datetime_string)
		log_message_type.ERROR: if PRINT_ERROR_MESSAGES: printerr("[ERROR] " + message + "\n[ERROR] Name: " + info + "\n[ERROR] Date/time: " + datetime_string)
	if SAVE_LOG_MESSAGES:
		save_log_messages(type, info, message, datetime_string)


# Save the log messages in a .txt file
func save_log_messages(type: log_message_type, info: String, message: String, datetime_string: String) -> void:
	# Checks if the folder for the save exists.
	if !ensure_save_directory(LOG_MESSAGE_DIRECTORY, "LOG_FILE_NAME", "log"):
		return
	
	var save_path = LOG_MESSAGE_DIRECTORY + "Log.txt"
	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ_WRITE)
	var log_message_to_save: String
	
	if !FileAccess.file_exists(save_path):
		file = FileAccess.open(save_path, FileAccess.WRITE)
	
	# Checks if the file was successfully opened for writing.
	if file == null:
		return
	
	match type:
		log_message_type.DEBUG: log_message_to_save = "[DEBUG] "  + datetime_string + " Name: " + info + " " + message + "\n"
		log_message_type.ERROR: log_message_to_save = "[ERROR] "  + datetime_string + " Name: " + info + " " + message + "\n"
	
	file.seek_end()
	file.store_string(log_message_to_save)
	file.close()
	
	pass


# Prints the debug messages
func _on_save_successful(save_name: String, debug_message: String):
	save_process_status = process_status.IDLE # Marks the process as done.
	log_message(log_message_type.DEBUG, save_name, debug_message)
	check_queue(save_queue, save_data)

func _on_save_failed(save_name: String, error_message: String):
	save_process_status = process_status.FAILED # Marks the process as failed.
	log_message(log_message_type.ERROR, save_name, error_message)
	await get_tree().create_timer(wait_time_after_fail).timeout
	save_process_status = process_status.IDLE
	check_queue(save_queue, save_data)

func _on_load_successful(save_name: String, debug_message: String):
	load_process_status = process_status.IDLE # Marks the process as done.
	log_message(log_message_type.DEBUG, save_name, debug_message)
	check_queue(load_queue, load_data)

func _on_load_failed(save_name: String, error_message: String):
	load_process_status = process_status.FAILED # Marks the process as failed.
	log_message(log_message_type.ERROR, save_name, error_message)
	await get_tree().create_timer(wait_time_after_fail).timeout
	load_process_status = process_status.IDLE
	check_queue(load_queue, load_data)
	
func _on_data_cleanup_successful(save_name: String, debug_message: String):
	cleanup_process_status = process_status.IDLE
	log_message(log_message_type.DEBUG, save_name, debug_message)
	check_queue(cleanup_queue, cleanup_data)

func _on_data_cleanup_failed(save_name: String, error_message: String):
	cleanup_process_status = process_status.FAILED
	log_message(log_message_type.ERROR, save_name, error_message)
	await get_tree().create_timer(wait_time_after_fail).timeout
	cleanup_process_status = process_status.IDLE
	check_queue(cleanup_queue, cleanup_data)

func _on_delete_save_successful(save_name: String, debug_message: String):
	log_message(log_message_type.DEBUG, save_name, debug_message)
