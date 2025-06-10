extends Control

#Node Variables
@onready var AppVersion: Label = $DefaultBox/OptionsBackground/OptionsBox/TopMargin/TitleBox/AppVersion
@onready var PreviewImage: TextureRect = $DefaultBox/PreviewBackground/PreviewContainer/PreviewImage
@onready var ServicesBox: VBoxContainer = $DefaultBox/OptionsBackground/OptionsBox/ServicesBox
@onready var SettingsMenu: VBoxContainer = $DefaultBox/PreviewBackground/SettingsMenu
@onready var ClockLabel: Label = $DefaultBox/PreviewBackground/ClockMarginContainer/ClockLabel
@onready var ErrorContainer: MarginContainer = $DefaultBox/PreviewBackground/ErrorMarginContainer
@onready var ErrorType: Label = $DefaultBox/PreviewBackground/ErrorMarginContainer/ErrorContainer/ErrorType
@onready var ErrorMessage: Label = $DefaultBox/PreviewBackground/ErrorMarginContainer/ErrorContainer/ErrorMessage
@onready var MenuSounds: AudioStreamPlayer2D = $MenuSounds

#General Variables
var DoChangePreview = true
var ScriptSettingsLocation = "res://Streaming/Config/Streaming.conf"
var StreamingLinks = {
	"Youtube" : "https://www.youtube.com/", 
	"PrimeVideo" : "https://www.amazon.com/video", 
	"Netflix" : "https://www.netflix.com/", 
	"HBOMax" : "https://www.max.com/",
	"Hulu" : "https://www.hulu.com/streaming",
	"AppleTV" : "https://tv.apple.com/", 
	"Disney" : "https://www.disneyplus.com/", 
	"Paramount" : "https://www.paramountplus.com/", 
}

#Custom Functions
func ToggleButtonsDisabled(Toggle: bool) -> void: 
	DoChangePreview = !Toggle
	for StreamingButton in ServicesBox.get_children():
		StreamingButton.disabled = Toggle
		
func ToggleSettingsMenu(Toggle: bool) -> void: 
	SettingsMenu.SettingsAnimations.play("Load In" if Toggle else "Load Out")
		
func UpdateErrorLabel(ErrorTypeString: String, ErrorTypeMessage: String):
	ErrorType.text = ErrorTypeString + ": "
	ErrorMessage.text = ErrorTypeMessage
	ErrorContainer.visible = true 
	
func HideErrorLabel() -> void:
	ErrorContainer.visible = false 
	
func LoadScriptSettings() -> void:
	var BlueprintFile = FileAccess.open("res://Streaming/Config/StreamingBlueprint.conf", FileAccess.READ)
	if BlueprintFile != null:
		var ResolutionText = SettingsMenu.ResolutionOption.get_item_text(SettingsMenu.ResolutionOption.selected).replace("×", ",")
		var BlueprintText = BlueprintFile.get_as_text().replace("<WindowSize>", ResolutionText)
		if BlueprintText:
			var ConfFile = FileAccess.open("res://Streaming/Config/Streaming.conf", FileAccess.WRITE)
			ConfFile.store_string(BlueprintText)
	
func LoadVersion() -> void: 
	var VersionFileLocation = "res://Version.json"
	var VersionFile = FileAccess.open(VersionFileLocation, FileAccess.READ)
	if VersionFile != null:
		var VersionJSON = JSON.new() 
		if VersionJSON.parse(VersionFile.get_as_text()) == 0: 
			var VersionData = VersionJSON.data 
			AppVersion.text = VersionData["Version"]
		else:
			UpdateErrorLabel("IOError", "Unable to load data from '" + VersionFileLocation + "'")
	else:
		UpdateErrorLabel("IOError", "Unable to open '" + VersionFileLocation + "'")
	
#Trigger Functions
func _ready() -> void:
	LoadVersion()
	SettingsMenu.LoadSettings()
	
func _process(_delta: float):
	var time = Time.get_time_dict_from_system()
	var meridiem = ("AM" if time.hour < 12 else "PM")
	ClockLabel.text = "%2d:%02d %s" % [time.hour % 12, time.minute, meridiem]
		
func _on_service_button_mouse_entered(ServiceType: String) -> void:
	MenuSounds.play()
	if DoChangePreview:
		PreviewImage.texture = load("res://Assets/Textures/PNGs/StreamingBackgrounds/" + ServiceType + ".png")
	
func _on_any_mouse_exited() -> void:
	PreviewImage.texture = load("res://Assets/Textures/PNGs/Backgrounds/BlankBackground.png")

func _on_any_service_button_pressed(ServiceType: String) -> void:
	LoadScriptSettings()
	OS.execute_with_pipe("bash", ["Streaming/LaunchApp.sh", StreamingLinks[ServiceType]])
	_on_power_pressed()

func _on_settings_pressed() -> void:
	ToggleButtonsDisabled(DoChangePreview) 
	ToggleSettingsMenu(!DoChangePreview)

func _on_power_pressed() -> void:
	get_tree().quit()
