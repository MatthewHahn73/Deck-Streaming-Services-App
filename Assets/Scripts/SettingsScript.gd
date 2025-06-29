extends VBoxContainer

#Node Variables
@onready var BrowserOption: OptionButton = $BrowserRow/BrowserOption
@onready var MenuSoundsCheckbox: CheckBox = $MenuSoundsRow/CheckboxContainer/MenuSoundsButton
@onready var AutoCloseCheckbox: CheckBox = $AutoCloseRow/CheckboxContainer/AutoCloseButton
@onready var BackButton: Button = $SettingsMargins/SettingsButtonContainer/BackButton
@onready var SaveButton: Button = $SettingsMargins/SettingsButtonContainer/SaveButton
@onready var SettingsMenu: VBoxContainer = $"."
@onready var SettingSounds: AudioStreamPlayer = $MenuSounds
@onready var MenuClicks: AudioStreamPlayer = $MenuClicks
@onready var DefaultScript: Control = get_parent().get_parent() 	#DefaultScene Node

#General Variables
var SettingsLocation = "user://Streaming/Config/Settings.json"
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
		if FlatpakIsInstalled(BrowserTable[Key]["Flatpak"]) == 0:
			BrowserOption.add_item(BrowserTable[Key]["Name"], int(Key)) 
	
func LoadSettings() -> void: 
	#Check if file exists, if it doesn't create one
	var SettingsFile = FileAccess.open(SettingsLocation, FileAccess.READ)
	if SettingsFile != null:
		var SettingsJSON = JSON.new() 
		if SettingsJSON.parse(SettingsFile.get_as_text()) == 0: 
			var SettingsData = SettingsJSON.data 
			BrowserOption.selected = SettingsData["Browser"]
			MenuSoundsCheckbox.button_pressed = SettingsData["MenuSounds"]
			AutoCloseCheckbox.button_pressed = SettingsData["AutoClose"]
			SetMenuValues()
		else:
			DefaultScript.UpdateErrorLabel("IOError", "Unable to load settings from '" + SettingsLocation + "'")
		SettingsFile.close()
	else:
		SaveSettings()
		LoadSettings()
		
func SetMenuValues() -> void:
	DefaultScript.MenuSettings["MenuSounds"] = MenuSoundsCheckbox.button_pressed
	DefaultScript.MenuSettings["AutoClose"] = AutoCloseCheckbox.button_pressed
		
func SaveSettings() -> void: 
	#Check if file exists, if it does, write to it, if not create a new one
	var SettingsFile = FileAccess.open(SettingsLocation, FileAccess.WRITE)
	var SettingsJSON = JSON.new() 
	SettingsJSON = {
		"Browser" : BrowserOption.selected if BrowserOption.selected != -1 else 0, 
		"MenuSounds" : MenuSoundsCheckbox.button_pressed, 
		"AutoClose" : AutoCloseCheckbox.button_pressed
	}
	SettingsFile.store_string(JSON.stringify(SettingsJSON))
	SettingsFile.close()
	
func FlatpakIsInstalled(Program: String) -> int: 
	var TerminalOutput = [] 
	OS.execute("flatpak", ["list", "--app"], TerminalOutput) 
	if Program in TerminalOutput[0]:
		return 0 
	return 1
	
func ReturnButtonFromType(Type: String) -> Button:
	match Type:
		"Back":
			return $SettingsMargins/SettingsButtonContainer/BackButton
		"Save":
			return $SettingsMargins/SettingsButtonContainer/SaveButton
		_:
			return null
	
#Trigger Functions
func _ready() -> void:
	SaveButton.disabled = true
	LoadAvailableBrowserData()

func _on_settings_save_button_pressed() -> void:
	SaveSettings()
	SetMenuValues()
	if !SaveButton.disabled:
		SaveButton.disabled = true
	
func _on_back_button_pressed() -> void:
	DefaultScript._on_settings_pressed() 

func _on_resolution_option_item_selected(_index: int) -> void:
	if DefaultScript.MenuSettings["MenuSounds"]:
		MenuClicks.play()
	if SaveButton.disabled:
		SaveButton.disabled = false

func _on_browser_option_pressed() -> void:
	if DefaultScript.MenuSettings["MenuSounds"]:
		MenuClicks.play()

func _on_button_mouse_entered(ButtonType: String) -> void:
	var ButtonEntered = ReturnButtonFromType(ButtonType)
	if ButtonEntered != null && !ButtonEntered.disabled:
		if DefaultScript.MenuSettings["MenuSounds"]:
			SettingSounds.play()
