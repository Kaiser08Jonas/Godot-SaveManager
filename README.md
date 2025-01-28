# Godot SaveManager
This is a save and load system for the Godot engine.
Made in the version 4.3-stable.

This SaveManager was specially developed for projects that require a fast, reliable and robust storage system. It uses the binary serialization of the Godot engine and ensures that your game data is stored securely without being easily manipulated. For better data security, these can optionally be encrypted.

> [!CAUTION]
> As binary serialization is used, the stored values cannot be edited in a text editor. This protects the data, but makes testing more difficult.

Further information can be found in the Godot documentation: [Saving Games](https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html)

## Save or load data
### Save path
The save path is the same as in the Godot documentation. It can be changed by changing the following constant to the desired path:

`const SAVE_DIRECTORY: String = "user://SaveManager//savegames/"`

> [!IMPORTANT]
> The SAVE_DIRECTORY is used for saving and loading. It should therefore not be changed if a file has already been saved! Only files located in the folder to which the save path leads can be loaded.

### Save data
To start saving, simply call the save_data function. The name of the save file and the dictionary to be saved must always be passed to it.
For example:
```
var data: Dictionary = {
	"count1" = 1,
	"count2" = 5,
}
SaveManager.save_data("save1", data)
```

"save1" is the name given to the file after saving.
If a new process is requested while a save process is running, it is placed in a queue. As soon as the current process is finished, one process after the other is processed automatically.

### Load data
Similar to saving, the loading process can be called via the load_data function. The name of the saved file from which the data is to be taken and the dictionary in which the data is to be loaded must be passed to the function.
For example:
```
var data: Dictionary = {
	"count1" = 0,
	"count2" = 0,
}
SaveManager.load_data("save1", data)
```

"save1" is the name of the file that is to be loaded.
As with the save function, load requests that are requested during a running process are placed in a queue list. This is then processed one after the other.

> [!NOTE]
> The saving and loading functions can be used simultaneously!

## Integration into your project
1. Copy the script SaveManager.gd in your Project.
2. Add the script as AutoLoad
   - Go to `Project -> Project Settings -> Globals -> Autoload`
   - Add the Script `SaveManager.gd`
> [!IMPORTANT]
> The SaveManager.gd script must be made into a global script (AutoLoad). This ensures that the data and functions are accessible at all times.
> You can find out how to do this in the Godot documentation: [Singletons (Autoload)](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html)

## Other functions

### Encrypting files
The constant `ENCRYPT_KEY: String = "123456abc"` determines the key with which a file is encrypted.
The `const ENCRYPT_FILES: bool = true` determines whether the data should be encrypted.

> [!IMPORTANT]
> As with SAVE_DIRECTORY, the constant ENCRYPT_KEY and the ENCRYPT_FILES shoud not be changed after a file has already been saved!
> Only the files with the correct settings of both constants can be loaded!

### Status signals
There are status signals that can be used to provide information, such as that the save was successful. The signals also transmit information about the save name and error messages. Information on how to use the signals can be found in the code.

The following signal exist:
```
signal save_successful(save_name: String, debug_message: String)		# Sends a signal if the save was successful.
signal save_failed(save_name: String, error_message: String)			# Sends a signal if the save has failed.
signal load_successful(save_name: String, debug_message: String)		# Sends a signal if the load was successful.
signal load_failed(save_name: String, error_message: String)			# Sends a signal if the load has failed.
signal data_cleanup_successful(save_name: String, debug_message: String)	# Sends a signal if the cleanup was successful.
signal data_cleanup_failed(save_name: String, error_message: String)		# Sends a signal if the cleanup has failed.
```

### Print debug or error messages
The `PRINT_DEBUG_MESSAGES` variable defines whether the debug messages are printed or not.
The `PRINT_ERROR_MESSAGES` variable defines the same, only for error messages.

If false -> no debug/error messages will be printed.

If true -> all debug/error messages will be printed.

### Save log messages
The `SAVE_LOG_MESSAGES` variable can be used to determine whether the log messages (debug and error) are saved in a file.
This is an example of what the saved messages look like: `[DEBUG] 2025-01-26 12:14:54 Name: 1 Save was successful
`

If false -> no log messages will be saved.

If true -> all log messages will be saved.

With `LOG_MESSAGE_DIRECTORY` and `LOG_FILE_NAME` you can specify where the messages are saved and the name of the file.

### Save empty data
The variable `can_save_empty_data` determines whether empty dictionarys can be saved.

If false -> empty dictionarys are skipped and a corresponding error message will be printet in the console.

If true -> the empty dictionary gets saved like a regular save.

### Cleanup data
`delete_old_loaded_data` determines whether loaded data that is not in the dictionary into which it is to be loaded gets deleted.

If false -> old data remains in the saved file.

If true -> old data will be deleted from the saved file and a corresponding debug message will be printet in the console.

### Wait after fail
The `wait_time_after_fail: int = 1` variable defines the time in seconds that the load or save process remains in fail mode. The higher it is, the longer no new process can be started after an error.

## Other Information
### Demo project
This project contains a demo project with which the basic save and load functions can be tested.

### Compatibility
> [!NOTE]
> This system was developed and tested with Godot 4.3-stable. It should also be compatible with future versions as long as no major changes are made to the Godot API.
