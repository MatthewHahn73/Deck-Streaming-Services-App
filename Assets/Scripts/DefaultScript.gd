extends Control

#Node Variables
@onready var SettingsMenu: VBoxContainer = $SettingsControl/SettingsMenu
@onready var AppVersion: Label = $OptionsBackground/OptionsBox/TopMargin/TitleBox/AppVersion
@onready var ClockLabel: Label = $ClockMarginContainer/ClockLabel
@onready var ServicesBox: VBoxContainer = $OptionsBackground/OptionsBox/ServicesBox
@onready var ErrorContainer: MarginContainer = $ErrorMarginContainer
@onready var ErrorType: Label = $ErrorMarginContainer/ErrorContainer/ErrorType
@onready var ErrorMessage: Label = $ErrorMarginContainer/ErrorContainer/ErrorMessage
@onready var MenuSounds: AudioStreamPlayer = $MenuSounds
@onready var SettingsAnimations: AnimationPlayer = $SettingsAnimations
@onready var LogoAnimations: AnimationPlayer = $LogoAnimations
@onready var PreviewImage: TextureRect = $PreviewImage
@onready var BackgroundImages: ResourcePreloader = $PreloadedImages

#General Variables
var SettingsToggle = true
var UserStreamingPath = "user://Streaming/"
var ConfBlueprintLocation = "user://Streaming/Config/StreamingBlueprint.conf"
var ScriptSettingsLocation = "user://Streaming/Config/Streaming.conf"
var StreamingLinksLocation = "res://Assets/JSON/StreamingLinks.json"
var VersionFileLocation = "res://Assets/JSON/Version.json"
var StreamingLinks = {}
var CMDArguments = {}
var MenuSettings = {}
	
#Custom Functions
func CheckForUserSettings() -> int: 
	if not DirAccess.dir_exists_absolute(UserStreamingPath):					#Move the streaming folder to an accessable user directory, if necessary
		var CurrentPath = OS.get_executable_path().get_base_dir()
		var StreamingFolderPathDebugging = "res://Streaming/"
		if DirAccess.dir_exists_absolute(CurrentPath + "/Streaming/"):			#Project is compiled. Pull from executable location
			CopyDirectory(CurrentPath + "/Streaming/", UserStreamingPath)
		elif DirAccess.dir_exists_absolute(StreamingFolderPathDebugging):		#Project is a godot debugging build. Pull from the resources path
			CopyDirectory(StreamingFolderPathDebugging, UserStreamingPath)
		else:
			UpdateErrorLabel("Error", "No Streaming folder exists at " + CurrentPath)
			return 1 
	return 0
	
func CopyDirectory(Source: String, Destination: String) -> void:
	DirAccess.make_dir_recursive_absolute(Destination)
	var SourceDir = DirAccess.open(Source)
	for Directory in SourceDir.get_directories():
		CopyDirectory(Source + Directory + "/", Destination + Directory + "/")	
	for Filename in SourceDir.get_files():
		SourceDir.copy(Source + Filename, Destination + Filename)
		
func LoadArguments() -> void:
	for Arg in OS.get_cmdline_args():
		if Arg.contains("="):
			var KeyValue = Arg.split("=")
			CMDArguments[KeyValue[0].trim_prefix("--")] = KeyValue[1]
			
func LoadStreamingLinks() -> void:
	var StreamingLinksFile = FileAccess.open(StreamingLinksLocation, FileAccess.READ)
	if StreamingLinksFile != null:
		var StreamingLinksJSON = JSON.new() 
		if StreamingLinksJSON.parse(StreamingLinksFile.get_as_text()) == 0: 
			StreamingLinks = StreamingLinksJSON.data 

func LoadBashScriptSettings() -> int:
	var BlueprintFile = FileAccess.open(ConfBlueprintLocation, FileAccess.READ)
	if BlueprintFile != null:
		if SettingsMenu.BrowserOption.selected != -1:
			var BrowserFlatpakLink = SettingsMenu.BrowserTable[str(SettingsMenu.BrowserOption.selected)]["Flatpak"]
			if SettingsMenu.FlatpakIsInstalled(BrowserFlatpakLink) == 0:
				var BlueprintText = BlueprintFile.get_as_text()
				if BlueprintText:	#Load the resolution/browser settings
					var ResolutionSize = get_viewport().get_visible_rect().size		#Set browser resolution to resolution of the application
					var ResolutionString = str(int(ResolutionSize.x)) + "," + str(int(ResolutionSize.y))
					var ConfFile = FileAccess.open(ScriptSettingsLocation, FileAccess.WRITE)
					BlueprintText = BlueprintText.replace("<WindowSize>", ResolutionString).replace("<Browser>", BrowserFlatpakLink)
					ConfFile.store_string(BlueprintText)
					ConfFile.close()
					return 0
				else:
					UpdateErrorLabel("Error", "Unable to load the conf file at " + ConfBlueprintLocation)
			else:
				UpdateErrorLabel("Error", "Unable to find selected flatpak " + BrowserFlatpakLink)
		else:
			UpdateErrorLabel("Error", "Unable to find an installed flatpak browser")
	BlueprintFile.close()
	return 1
	
func LoadVersion() -> void: 
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

func ToggleStreamingButtonsDisabled(Toggle: bool) -> void: 
	SettingsToggle = !Toggle
	for StreamingButton in ServicesBox.get_children():
		StreamingButton.disabled = Toggle
		
func ToggleSettingsMenu(Toggle: bool) -> void: 
	if Toggle:
		SettingsMenu.visible = Toggle
		SettingsAnimations.play("Settings Load")
	else:
		SettingsAnimations.play_backwards("Settings Load")
		
func FindAndKillAnyActiveSessions() -> void:
	var TerminalOutput = [] 
	OS.execute("flatpak", ["ps"], TerminalOutput) 
	var RunningApplications = Array(TerminalOutput[0].split("\n"))
	RunningApplications.pop_back()												#Remove the last empty string
	for CurrentApp in RunningApplications:
		var CurrentAppStats = CurrentApp.split("\t")
		var CurrentApplicationType = CurrentAppStats.get(2)
		if CurrentApplicationType == SettingsMenu.BrowserTable[str(SettingsMenu.BrowserOption.selected)]["Flatpak"]:		
			OS.execute_with_pipe("flatpak", ["kill", CurrentAppStats[0]])		#If open browser session is matched with currently selected browser then close it
		
func UpdateClock() -> void:
	var CurrentTime = Time.get_time_dict_from_system()
	var Meridiem = ("AM" if CurrentTime.hour < 12 else "PM")
	var CurrentHour = CurrentTime.hour % 12 if (CurrentTime.hour % 12 != 0) else 12
	ClockLabel.text = "%2d:%02d %s" % [CurrentHour, CurrentTime.minute, Meridiem]

func UpdateErrorLabel(ErrorTypeString: String, ErrorTypeMessage: String) -> void:
	ErrorType.text = ErrorTypeString + ": "
	ErrorMessage.text = ErrorTypeMessage
	ErrorContainer.visible = true 
	
func HideErrorLabel() -> void:
	ErrorContainer.visible = false 
		
func ReturnButtonFromType(Type: String) -> Button:
	match Type:
		"AppleTV":
			return $OptionsBackground/OptionsBox/ServicesBox/AppleTV
		"Disney":
			return $OptionsBackground/OptionsBox/ServicesBox/Disney
		"HBOMax":
			return $OptionsBackground/OptionsBox/ServicesBox/HBOMax
		"Hulu":
			return $OptionsBackground/OptionsBox/ServicesBox/Hulu
		"Netflix":
			return $OptionsBackground/OptionsBox/ServicesBox/Netflix
		"Paramount":
			return $OptionsBackground/OptionsBox/ServicesBox/Paramount
		"PrimeVideo":
			return $OptionsBackground/OptionsBox/ServicesBox/Amazon
		"Youtube":
			return $OptionsBackground/OptionsBox/ServicesBox/Youtube
		_:
			return null
			
#Trigger Functions
func _ready() -> void:
	LoadArguments()
	LoadVersion()
	LoadStreamingLinks()
	if CheckForUserSettings() == 0:
		SettingsMenu.LoadSettings()
	if CMDArguments.has("AutoLaunch") && CMDArguments["AutoLaunch"] != null:			#If a command line argument for autolaunch was loaded, load that service 
		_on_any_service_button_pressed(CMDArguments["AutoLaunch"])
	
func _process(_delta: float):
	UpdateClock()
	await get_tree().create_timer(1.0).timeout 		#Check every second instead of every frame
		
func _on_service_button_mouse_entered(ServiceType: String) -> void:
	var ServiceButtonEntered = ReturnButtonFromType(ServiceType)
	if ServiceButtonEntered != null && !ServiceButtonEntered.disabled:
		if MenuSettings["MenuSounds"]:
			MenuSounds.play()
		PreviewImage.texture = BackgroundImages.get_resource(ServiceType) 
		LogoAnimations.play("Preview Fade In")		
		
func _on_other_buttons_mouse_entered() -> void:
	if MenuSettings["MenuSounds"]:
		MenuSounds.play()
	
func _on_any_mouse_exited(ServiceType: String) -> void:
	var ServiceButtonEntered = ReturnButtonFromType(ServiceType)
	if ServiceButtonEntered != null && !ServiceButtonEntered.disabled:
		LogoAnimations.play("Preview Fade Out")		
		
func _on_any_service_button_pressed(ServiceType: String) -> void:
	if LoadBashScriptSettings() == 0:	#If script settings successfully loaded, launch the browser
		FindAndKillAnyActiveSessions()
		OS.execute_with_pipe("bash", ["Streaming/LaunchApp.sh", StreamingLinks[ServiceType]])
		if MenuSettings["AutoClose"]:
			_on_power_pressed()

func _on_settings_pressed() -> void:
	ToggleStreamingButtonsDisabled(SettingsToggle) 
	ToggleSettingsMenu(!SettingsToggle)
	
func _on_power_pressed() -> void:
	get_tree().quit()
