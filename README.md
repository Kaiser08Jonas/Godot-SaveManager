# Godot-save-and-load-system
This is a save and load system for the Godot engine.
Made in the version 4.3-stable

This save and load system was specially developed for projects that require a fast, reliable and robust storage system. It uses the binary serialization of the Godot engine and ensures that your game data is stored securely without being easily manipulated.

> [!CAUTION]
> As binary serialization is used, the stored values cannot be edited in a text editor. This protects the data, but makes testing more difficult.

Further information can be found in the Godot documentation: [Saving Games](https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html)

## Save data
Add the data to be backed up to the Data Dictionary. This will automatically add it to the backup file the next time it is saved.
If the data does not exist in the backup file at the time of loading, the original value is used instead.

```
var data: Dictionary = {
	# This is where the variables to be stored go
	# For example:
	# "KEY": VALUE
	"count" = 0,
}
```

If a new save is made during the save process, the system waits until the current save process has been completed. It is then saved again. If the data is saved several times during the save process, it is only saved once after saving.
This ensures that multiple saving is not possible at the same time.

## Load data
During the loading process, only the data defined in the data dictionary is loaded. Data that no longer exists is skipped.

Only one loading process is possible at a time. If further loading processes are started during the loading process, only the current loading process is ended. After this, the loading function can be called up again.

## Save path
The memory path is the same as in the Godot documentation. It can be changed by changing the following variable to the desired path:

`const save_path = "user://savegame.save"`

It can be found at the top of the script.

## Integration into your project
1. Copy the script save_load.gd in your Project.
2. Add the script as AutoLoad
   - Go to `Project -> Project Settings -> Globals -> Autoload`
   - Add the Script `save_load.gd`
> [!IMPORTANT]
> The save_load script must be made into a global script (AutoLoad). This ensures that the data and functions are accessible at all times.
> You can find out how to do this in the Godot documentation: [Singletons (Autoload)](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html)

## How to use it
1. Add the data to be saved to the data dicitonary.
2. Call the save_data function:

    ```SaveLoad.save_data()```
4. To load the data use the function load_data:

    ```SaveLoad.load_data()```
6. After loading the data, the data in the data dictionary is updated with the loaded data.

## Notes on error handling
If an error occurs during saving or loading, a corresponding error message is displayed.

## Other Information
This project contains a demo project with which the functions can be tested.
> [!NOTE]
> This system was developed and tested with Godot 4.3-stable. It should also be compatible with future versions as long as no major changes are made to the Godot API.

