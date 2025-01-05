# Godot-save-and-load-system
This is a save and load system for the Godot engine
Made in the version 4.3-stable

This save and load system uses the binary serialization of the engine.
As a result, the <ins>**saved values cannot be edited in a text editor**</ins>. This prevents simple editing of the saved values.
However, the values cannot be changed for testing either.

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
When loading the backup data, only the data in the data dictionary is loaded. All data that is not in the data dictionary during the loading process is skipped.

Only one loading process is possible at a time. If further loading processes are started during the loading process, only the current loading process is ended. After this, the loading function can be called up again.

## Save path
The memory path is the same as in the Godot documentation. It can be changed by changing the following variable to the desired path:
`const save_path = "user://savegame.save"`.

It can be found at the top of the script.

## Other Information
This project contains a demo project with which the functions can be tested. If you would like to use the system in another project, simply copy the save_load script into your project.
> [!IMPORTANT]
> The save_load script must be made into a global script (AutoLoad). This ensures that the data and functions are accessible at all times.
> You can find out how to do this in the Godot documentation: [Singletons (Autoload)](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html)

