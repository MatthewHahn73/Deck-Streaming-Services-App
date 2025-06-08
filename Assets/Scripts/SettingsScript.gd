extends VBoxContainer

#Node Variables
@onready var ResolutionOption: OptionButton = $ResolutionRow/ResolutionOption
@onready var SaveButton: Button = $SettingsMargins/SettingsButtonContainer/SaveButton
@onready var SettingsAnimations: AnimationPlayer = $SettingsAnimations
@onready var SettingsMenu: VBoxContainer = $"."
@onready var DefaultScript: Control = get_parent().get_parent().get_parent()

#General Variables
var SettingsLocation = "res://Streaming/Config/Settings.json"

#Custom Functions
func LoadSettings() -> void: 
	#Check if file exists, if it doesn't create one
	var SettingsFile = FileAccess.open(SettingsLocation, FileAccess.READ)
	if SettingsFile != null:
		var SettingsJSON = JSON.new() 
		if SettingsJSON.parse(SettingsFile.get_as_text()) == 0: 
			var SettingsData = SettingsJSON.data 
			ResolutionOption.selected = SettingsData["Resolution"]
		else:
			DefaultScript.UpdateErrorLabel("IOError", "Unable to load settings from '" + SettingsLocation + "'")
		SettingsFile.close()
	else:
		SaveSettings()
		LoadSettings()
		
func SaveSettings() -> void: 
	#Check if file exists, if it does, write to it, if not create a new one
	var SettingsFile = FileAccess.open(SettingsLocation, FileAccess.WRITE)
	var SettingsJSON = JSON.new() 
	SettingsJSON = {
		"Resolution" : ResolutionOption.selected if ResolutionOption.selected != -1 else 5
	}
	SettingsFile.store_string(JSON.stringify(SettingsJSON))
	SettingsFile.close()
	
#Trigger Functions
func _ready() -> void:
	SaveButton.disabled = true

func _on_settings_save_button_pressed() -> void:
	SaveSettings()
	if !SaveButton.disabled:
		SaveButton.disabled = true
	
func _on_back_button_pressed() -> void:
	DefaultScript._on_settings_pressed() 

func _on_resolution_option_item_selected(_index: int) -> void:
	if SaveButton.disabled:
		SaveButton.disabled = false

func _on_settings_animations_animation_finished(_AnimationName: StringName) -> void:
	pass
