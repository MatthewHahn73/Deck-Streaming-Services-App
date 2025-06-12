extends VBoxContainer

#Node Variables
@onready var BrowserOption: OptionButton = $BrowserRow/BrowserOption
@onready var ResolutionOption: OptionButton = $ResolutionRow/ResolutionOption
@onready var SaveButton: Button = $SettingsMargins/SettingsButtonContainer/SaveButton
@onready var SettingsAnimations: AnimationPlayer = $SettingsAnimations
@onready var SettingsMenu: VBoxContainer = $"."
@onready var DefaultScript: Control = get_parent().get_parent().get_parent()

#General Variables
var SettingsLocation = "res://Streaming/Config/Settings.json"
var BrowserTableLocation = "res://Assets/JSON/BrowserFlatpaks.json"
var BrowserTable = {}

#Custom Functions
func LoadAvailableBrowserData() -> void: 
	var BrowserTableFile = FileAccess.open(BrowserTableLocation, FileAccess.READ)
	if BrowserTableFile != null:
		var BrowserTableJSON = JSON.new() 
		if BrowserTableJSON.parse(BrowserTableFile.get_as_text()) == 0: 
			BrowserTable = BrowserTableJSON.data 
	for Key in BrowserTable: 
		if FlatpakIsInstalled(BrowserTable[Key]["Flatpak"]):
			BrowserOption.add_item(BrowserTable[Key]["Name"], int(Key)) 
	
func LoadSettings() -> void: 
	#Check if file exists, if it doesn't create one
	var SettingsFile = FileAccess.open(SettingsLocation, FileAccess.READ)
	if SettingsFile != null:
		var SettingsJSON = JSON.new() 
		if SettingsJSON.parse(SettingsFile.get_as_text()) == 0: 
			var SettingsData = SettingsJSON.data 
			ResolutionOption.selected = SettingsData["Resolution"]
			BrowserOption.selected = SettingsData["Browser"]
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
		"Resolution" : ResolutionOption.selected if ResolutionOption.selected != -1 else 5,
		"Browser" : ResolutionOption.selected if ResolutionOption.selected != -1 else 0
	}
	SettingsFile.store_string(JSON.stringify(SettingsJSON))
	SettingsFile.close()
	
func FlatpakIsInstalled(Program: String) -> bool: 
	var TerminalOutput = [] 
	OS.execute("flatpak", ["list", "--app"], TerminalOutput) 
	if Program in TerminalOutput[0]:
		return true 
	return false
	
#Trigger Functions
func _ready() -> void:
	SaveButton.disabled = true
	LoadAvailableBrowserData()

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
