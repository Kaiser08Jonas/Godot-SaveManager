# Godot SaveManager
This is a save and load system for the Godot engine.
Made in the version 4.3-stable.

This SaveManager was specially developed for projects that require a fast, reliable and robust storage system. It uses the binary serialization of the Godot engine and ensures that your game data is stored securely without being easily manipulated.

> [!CAUTION]
> As binary serialization is used, the stored values cannot be edited in a text editor. This protects the data, but makes testing more difficult.

> [!IMPORTANT]
> Even if the data cannot be edited just like that, they are not encrypted!

Further information can be found in the Godot documentation: [Saving Games](https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html)

## Save or load data
### Save path
The save path is the same as in the Godot documentation. It can be changed by changing the following constant to the desired path:

`const save_path = "user://savegame.save"`

It can be found at the top of the script.

> [!CAUTION]
> The save path is used for saving and loading. It should therefore not be changed if a file has already been saved! Only files located in the folder to which the save path leads can be loaded.

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

If a new process is requested while a storage process is running, it is placed in a queue. As soon as the current process is finished, one process after the other is processed automatically.

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
### Status signals
There are status signals that can be used to provide information, such as that the save was successful. The signals also transmit information about the save name and error messages. Information on how to use the signals can be found in the code.

The following signal exist:
```
signal save_successful(save_name: String)				# Sends a signal if the save was successful.
signal save_failed(save_name: String, error_message: String)		# Sends a signal if the save has failed.
signal load_successful(save_name: String)				# Sends a signal if the load was successful.
signal load_failed(save_name: String, error_message: String)		# Sends a signal if the load has failed.
signal data_cleanup_successful(save_name: String)			# Sends a signal if the cleanup was successful.
signal data_cleanup_failed(save_name: String, error_message: String)	# Sends a signal if the cleanup has failed.
```

### Print debut messages
The `print_debug_messages` variable defines whether the debug messages are printed or not.

If false -> no debug messages will be printed.

If true -> all debug messages will be printed.

### Save empty data
The variable `can_save_empty_data` determines whether empty dictionarys can be saved. The messages use the status signals.

If false -> empty dictionarys are skipped and a corresponding message will be printet in the console.

If true -> the empty dictionary gets saved like a regular save.

### Cleanup data
`delete_old_loaded_data` determines whether loaded data that is not in the dictionary into which it is to be loaded gets deleted.

If false -> old data remains in the saved file.

If true -> old data will be deleted from the saved file and a corresponding message will be printet in the console.

## Notes on error handling
If an error occurs during saving or loading, a corresponding error message will be printet.

## Other Information
### Demo project
This project contains a demo project with which the functions can be tested.

### Compatibility
> [!NOTE]
> This system was developed and tested with Godot 4.3-stable. It should also be compatible with future versions as long as no major changes are made to the Godot API.
