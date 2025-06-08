extends Control

#Node Variables
@onready var PreviewImage: TextureRect = $DefaultBox/PreviewBackground/PreviewContainer/PreviewImage
@onready var ServicesBox: VBoxContainer = $DefaultBox/OptionsBackground/OptionsBox/ServicesBox
@onready var SettingsMenu: VBoxContainer = $DefaultBox/PreviewBackground/SettingsMenu
@onready var ErrorContainer: MarginContainer = $DefaultBox/PreviewBackground/ErrorMarginContainer
@onready var ErrorType: Label = $DefaultBox/PreviewBackground/ErrorMarginContainer/ErrorContainer/ErrorType
@onready var ErrorMessage: Label = $DefaultBox/PreviewBackground/ErrorMarginContainer/ErrorContainer/ErrorMessage

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
		
func SetScriptSettings() -> void:
	pass
	
func UpdateErrorLabel(ErrorTypeString: String, ErrorTypeMessage: String):
	ErrorType.text = ErrorTypeString + ": "
	ErrorMessage.text = ErrorTypeMessage
	ErrorContainer.visible = true 
	
func HideErrorLabel() -> void:
	ErrorContainer.visible = false 
	
#Trigger Functions
func _ready() -> void:
	SettingsMenu.LoadSettings()
	
func _on_service_button_mouse_entered(ServiceType: String) -> void:
	if DoChangePreview:
		PreviewImage.texture = load("res://Assets/Textures/PNGs/StreamingBackgrounds/" + ServiceType + ".png")
	
func _on_any_mouse_exited() -> void:
	PreviewImage.texture = load("res://Assets/Textures/PNGs/Backgrounds/BlankBackground.png")

func _on_any_service_button_pressed(_ServiceType: String) -> void:
	#OS.execute_with_pipe("bash", ["Streaming/LaunchApp.sh", StreamingLinks[ServiceType]])
	SetScriptSettings()
	#_on_power_pressed()

func _on_settings_pressed() -> void:
	ToggleButtonsDisabled(DoChangePreview) 
	ToggleSettingsMenu(!DoChangePreview)

func _on_power_pressed() -> void:
	get_tree().quit()
