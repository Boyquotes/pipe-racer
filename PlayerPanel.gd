extends Control

@onready var username: LineEdit = %Username
@onready var password: LineEdit	= %Password
@onready var colorPicker: ColorPickerButton = %ColorPicker
@onready var guestTickBox: CheckBox = %GuestTickBox
@onready var loginButton: Button = %LoginButton
@onready var logoutButton: Button = %LogoutButton
@onready var randomColorButton: Button = %RandomColorButton

@onready var profilePicture: TextureRect = %ProfilePicture

var isMainPlayer: bool = false

var defaultPicture: Texture

var sessionToken: String = ""
var userId: String = ""

func _ready():
	defaultPicture = profilePicture.texture
	connectSignals()

func connectSignals():
	username.text_changed.connect(onUsername_textChanged)
	password.text_changed.connect(onPassword_textChanged)
	colorPicker.color_changed.connect(onColorPicker_colorChanged)
	guestTickBox.toggled.connect(onGuestTickBox_toggled)
	loginButton.pressed.connect(onLoginButton_pressed)
	logoutButton.pressed.connect(onLogoutButton_pressed)
	randomColorButton.pressed.connect(onRandomColorButton_pressed)



func onUsername_textChanged(newText: String):
	pass

func onPassword_textChanged(newText: String):
	pass

func onColorPicker_colorChanged(newColor: Color):
	pass

func onGuestTickBox_toggled(pressed: bool):
	pass

func onLoginButton_pressed():
	setButtonsLoggingIn()

	var loginData = getLoginData()
	var loginRequest = HTTPRequest.new()
	add_child(loginRequest)

	loginRequest.request_completed.connect(onLoginRequestCompleted)

	var httpError = loginRequest.request(
		"http://localhost:80/api/auth/login",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(loginData)
	)
	if httpError != OK:
		print("Error: " + error_string(httpError))

func onLogoutButton_pressed():
	setButtonsLoggedOut()

	setRandomPlayerData()
	pass

func onLoginRequestCompleted(result: int, responseCode: int, headers: PackedStringArray, body: PackedByteArray):

	if responseCode != 200:
		setButtonsLoggedOut()
		print("Error: " + body.get_string_from_utf8())
		return
	
	setButtonsLoggedIn()

	var json = JSON.parse_string(body.get_string_from_utf8())
	
	# loginButton.text = "Log Out"
	password.text = ""
	sessionToken = json.sessionToken
	userId = json.userId

	if isMainPlayer:
		Playerstats.SESSION_TOKEN = sessionToken
		Playerstats.USER_ID = userId

	loadProfilePicture(json.profilePictureUrl)

func onRandomColorButton_pressed():
	colorPicker.color = Color(randf(), randf(), randf(), 1.0)

func setMainPlayerData():
	isMainPlayer = true
	username.text = Playerstats.PLAYER_NAME
	username.text_changed.connect(onTextChanged)
	password.text = Playerstats.PLAYER_PASSWORD
	password.text_changed.connect(onPasswordTextChanged)
	colorPicker.color = Playerstats.PLAYER_COLOR
	colorPicker.color_changed.connect(onColorChanged)

	onLoginButton_pressed()


func setRandomPlayerData():
	username.text = "Player" + str(randi() % 1000)
	colorPicker.color = Color(randf(), randf(), randf(), 1.0)
	sessionToken = ""
	userId = ""
	profilePicture.texture = defaultPicture

func onTextChanged(newText: String) -> void:
	if newText != "":
		Playerstats.PLAYER_NAME = newText

func onPasswordTextChanged(newText: String) -> void:
	if newText != "":
		Playerstats.PLAYER_PASSWORD = newText

func onColorChanged(new_color):
	Playerstats.PLAYER_COLOR = new_color

func getPlayerData() -> PlayerData:
	return PlayerData.new(userId, username.text, colorPicker.color)

func getLoginData() -> Dictionary:
	return {
		"username": username.text,
		"password": password.text,
	}

func loadProfilePicture(imageUrl: String):
	var httpRequest = HTTPRequest.new()
	add_child(httpRequest)
	httpRequest.request_completed.connect(onLoadProfilePictureRequestCompleted)

	var httpError = httpRequest.request(imageUrl)
	if httpError != OK:
		print("Error: " + str(httpError))

func onLoadProfilePictureRequestCompleted(result: int, responseCode: int, headers: PackedStringArray, body: PackedByteArray):
	var image = Image.new()
	var imageError = image.load_jpg_from_buffer(body)
	if imageError != OK:
		print("Error loading jpg: " + error_string(imageError))
		print("Trying PNG...")
		imageError = image.load_png_from_buffer(body)
		if imageError != OK:
			print("Error loading png: " + error_string(imageError))
			return
		else:
			print("PNG loaded successfully")
	else:
		print("JPG loaded successfully")
	
	# var profileTexture = ImageTexture.new()
	

	profilePicture.texture = ImageTexture.create_from_image(image)

func setButtonsLoggingIn():
	loginButton.disabled = true
	loginButton.text = "Loading"

func setButtonsLoggedIn():
	loginButton.visible = false
	logoutButton.visible = true

func setButtonsLoggedOut():
	loginButton.disabled = false
	loginButton.visible = true
	loginButton.text = "Log In"
	logoutButton.visible = false

