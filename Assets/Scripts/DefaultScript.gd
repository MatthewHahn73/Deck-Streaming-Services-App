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
@onready var MenuSounds: AudioStreamPlayer = $MenuSounds
@onready var MenuAnimations: AnimationPlayer = $MenuAnimations

#General Variables
var DoChangePreview = true
var ScriptSettingsLocation = "res://Streaming/Config/Streaming.conf"
var StreamingLinksLocation = "res://Assets/JSON/StreamingLinks.json"
var StreamingLinks = {}

#Custom Functions
func LoadStreamingLinks() -> void:
	var StreamingLinksFile = FileAccess.open(StreamingLinksLocation, FileAccess.READ)
	if StreamingLinksFile != null:
		var StreamingLinksJSON = JSON.new() 
		if StreamingLinksJSON.parse(StreamingLinksFile.get_as_text()) == 0: 
			StreamingLinks = StreamingLinksJSON.data 

func LoadBashScriptSettings() -> int:
	var ConfFileLocation = "res://Streaming/Config/StreamingBlueprint.conf"
	var BlueprintFile = FileAccess.open(ConfFileLocation, FileAccess.READ)
	if BlueprintFile != null:
		if SettingsMenu.BrowserOption.selected != -1:
			var BrowserFlatpakLink = SettingsMenu.BrowserTable[str(SettingsMenu.BrowserOption.selected)]["Flatpak"]
			if SettingsMenu.FlatpakIsInstalled(BrowserFlatpakLink) == 0:
				var BlueprintText = BlueprintFile.get_as_text()
				if BlueprintText:	#Load the resolution/browser settings
					var ResolutionText = SettingsMenu.ResolutionOption.get_item_text(SettingsMenu.ResolutionOption.selected).replace("×", ",")
					var ConfFile = FileAccess.open("res://Streaming/Config/Streaming.conf", FileAccess.WRITE)
					BlueprintText = BlueprintText.replace("<WindowSize>", ResolutionText).replace("<Browser>", BrowserFlatpakLink)
					ConfFile.store_string(BlueprintText)
					ConfFile.close()
					return 0
				else:
					UpdateErrorLabel("Error", "Unable to load the conf file at " + ConfFileLocation)
			else:
				UpdateErrorLabel("Error", "Unable to find selected flatpak " + BrowserFlatpakLink)
		else:
			UpdateErrorLabel("Error", "Unable to find an installed flatpak browser")
	BlueprintFile.close()
	return 1
	
func LoadVersion() -> void: 
	var VersionFileLocation = "res://Assets/JSON/Version.json"
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

func ToggleButtonsDisabled(Toggle: bool) -> void: 
	DoChangePreview = !Toggle
	for StreamingButton in ServicesBox.get_children():
		StreamingButton.disabled = Toggle
		
func ToggleSettingsMenu(Toggle: bool) -> void: 
	SettingsMenu.SettingsAnimations.play("Load In" if Toggle else "Load Out")
		
func UpdateClock() -> void:
	var time = Time.get_time_dict_from_system()
	var meridiem = ("AM" if time.hour < 12 else "PM")
	var hour = time.hour % 12 if time.hour != 0 else 12
	ClockLabel.text = "%2d:%02d %s" % [hour, time.minute, meridiem]

func UpdateErrorLabel(ErrorTypeString: String, ErrorTypeMessage: String):
	ErrorType.text = ErrorTypeString + ": "
	ErrorMessage.text = ErrorTypeMessage
	ErrorContainer.visible = true 
	
func HideErrorLabel() -> void:
	ErrorContainer.visible = false 
			
#Trigger Functions
func _ready() -> void:
	LoadVersion()
	LoadStreamingLinks()
	SettingsMenu.LoadSettings()
	
func _process(_delta: float):
	UpdateClock()
	await get_tree().create_timer(1.0).timeout 		#Check every second instead of every frame
		
func _on_service_button_mouse_entered(ServiceType: String) -> void:
	MenuSounds.play()
	if DoChangePreview:
		PreviewImage.texture = load("res://Assets/Textures/PNGs/StreamingBackgrounds/" + ServiceType + ".png")
		MenuAnimations.play("Preview Fade In")
		
func _on_other_buttons_mouse_entered() -> void:
	MenuSounds.play()
		
func _on_any_mouse_exited() -> void:
	MenuAnimations.play("Preview Fade Out")

func _on_any_service_button_pressed(ServiceType: String) -> void:
	if LoadBashScriptSettings() == 0:	#If script settings successfully loaded, launhc the browser
		OS.execute_with_pipe("bash", ["Streaming/LaunchApp.sh", StreamingLinks[ServiceType]])
		_on_power_pressed()

func _on_settings_pressed() -> void:
	ToggleButtonsDisabled(DoChangePreview) 
	ToggleSettingsMenu(!DoChangePreview)

func _on_power_pressed() -> void:
	get_tree().quit()

func _on_menu_animations_animation_finished(AnimationName: StringName) -> void:
	if AnimationName == "Preview Fade In":
		PreviewImage.visible = true
	elif AnimationName == "Preivew Fade Out": 
		PreviewImage.visible = false
