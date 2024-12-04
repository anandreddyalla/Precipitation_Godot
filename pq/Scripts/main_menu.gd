extends Node

var music_playing = true
var background_music: AudioStreamPlayer2D
var masterVolume = 1;
var musicVolume = 1;
var sfxVolume = 1;
var http_request;
var request_url = ""


@onready var button_order = ["levelMenu/level1",
 "levelMenu/level2",
 "levelMenu/level3"
]

@onready var button_orders = [
	{"path": "levelMenu/level1", "level": "easy"},
	{"path": "levelMenu/level2", "level": "medium"},
	{"path": "levelMenu/level3", "level": "hard"}
]

# Backend URLs (replace with your actual backend URLs)
var signup_url = str(Global.baseUrl)+"/registerStudent"
var login_url = str(Global.baseUrl)+"/studentLogin"

func _ready():
	background_music = $"background-music"
	background_music.play()
	congrats()
	if (Global.studentId and Global.studentName):
		print("Already logged in")
		$signupNode.hide()
		$loginNode.hide()
		$levelMenu.show()
		
	# Create HTTPRequest node
	http_request = HTTPRequest.new()
	add_child(http_request)  # Add it to the current node as a child
	
	# Connect the "request_completed" signal to the handler function
	http_request.request_completed.connect(self._on_HTTPRequest_request_completed)
	# Iterate over each button in button_order
	for button_info in button_orders:
		var button_path = button_info["path"]
		var level = button_info["level"]

		# Get the button node using its path
		var button = get_node(button_path)

		if button:
			button.connect("pressed", Callable(self, "_on_mapbtn_pressed").bind(level))
		else:
			print("Button not found at path:", button_path)
			
	


func _process(delta):
	$background.scroll_offset.x -= 60 * delta

# --------------------------------------------------------------
# Main Menu code
# --------------------------------------------------------------

# Show response and hide it after 3 seconds
func show_response_for_3_seconds(response_node: String, response_text: String) -> void:
	
	if(response_node == "signup"):
		for child in $signupNode.get_children():
			if child.name != "signupResponse" and child.name != "auth-title" and "signup":
				child.hide()
		$signupNode/signupResponse.show()
		$signupNode/signupResponse.text = response_text
	else:
		for child in $loginNode.get_children():
			if child.name != "loginResponse" and child.name != "login-title" and "login":
				child.hide()
		$loginNode/loginResposne.show()
		$loginNode/loginResposne.text = response_text

	# Create a new Timer node
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	add_child(timer)
	timer.start()
	# Use Callable and bind the extra argument (response_node)
	if(response_node == "signup"):
		timer.connect("timeout", Callable(self, "_on_verification_timeout").bind($signupNode/signupResponse))
	else:
		timer.connect("timeout", Callable(self, "_on_verification_timeout").bind($loginNode/loginResposne))
	
		
# Callback function to hide the response after the timer finishes
func _on_verification_timeout(response_node: Node) -> void:
	# Hide the response node
	response_node.hide()
	for child in $signupNode.get_children():
			if child.name != "signupResponse":
				child.show()
				if child is LineEdit or child is TextEdit:
					child.text = ""

	for child in $loginNode.get_children():
			if child.name != "loginResponse":
				child.show()
				if child is LineEdit or child is TextEdit:
					child.text = ""
	# Optionally, free the timer if it was dynamically created
	var timer = get_parent().get_node("Timer")
	if timer:
		timer.queue_free()



# Function to handle signup
func signup(full_name: String, email: String, password: String, section_id: String) -> void:
	var payload = {
		"fullName": full_name,
		"email": email,
		"password": password,
		"sectionId": section_id
	}
	var json_payload = JSON.stringify(payload).to_utf8_buffer()  # Convert the JSON payload to PackedByteArray
	var headers = PackedStringArray(["Content-Type: application/json"])

	request_url = signup_url  # Store the URL before making the request
	http_request.request_raw(signup_url, headers, HTTPClient.METHOD_POST, json_payload)

# Function to handle login
func login(email: String, password: String) -> void:
	var payload = {
		"email": email,
		"password": password
	}
	var json_payload = JSON.stringify(payload).to_utf8_buffer()  # Convert the JSON payload to PackedByteArray
	var headers = PackedStringArray(["Content-Type: application/json"])

	request_url = login_url  # Store the URL before making the request
	http_request.request_raw(login_url, headers, HTTPClient.METHOD_POST, json_payload)


# Callback for handling HTTP request responses
func _on_HTTPRequest_request_completed(result: int, response_code: int, headers: Array, body: PackedByteArray):
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())

	if error != OK:
		print("Failed to parse JSON:", error.error_string)
		return

	# Access the parsed data through the 'data' property
	var response_data = json.data

	# Print the parsed response for debugging
	print("Response Data -> ", response_data)

	# Handle the response based on the stored URL
	if request_url == signup_url:
		if response_code == 201:  # Signup successful
			print("Signup successful! Student ID: ", response_data["studentId"])
			print("Welcome,", response_data["studentName"])
			var signup_message = str("Signup successful! Student ID: ") + response_data["studentId"]
			show_response_for_3_seconds("signup", signup_message)
			$signupNode.hide()
			$loginNode.show()
		else:  # Signup failed
			print("Signup failed:", response_data.get("message", "Unknown error"))
			var signup_error_message = response_data.get("message", "Unknown error")
			show_response_for_3_seconds("signup", signup_error_message)

	elif request_url == login_url:
		if response_code == 200:  # Login successful
			print("Login successful!")
			print("Student ID:", response_data["studentId"])
			print("Welcome,", response_data["studentName"])
			Global.studentId = response_data["studentId"]
			Global.studentName = response_data["studentName"]
			Global.canPlayLevel2 = int(response_data["level1Score"]) == 6
			Global.canPlayLevel3 = int(response_data["level2Score"]) == 6
			show_response_for_3_seconds("login", "Login successful!")
			$loginNode.hide()
			$levelMenu.show()
		else:  # Login failed
			print("Login failed:", response_data.get("message", "Unknown error"))
			var login_error_message = response_data.get("message", "Unknown error")
			show_response_for_3_seconds("login", login_error_message)



# Handle Login button press
func _on_login_btn_pressed() -> void:
	var email = $loginNode/loginEmail.text
	var password = $loginNode/loginPassword.text

	if email.is_empty() or password.is_empty():
		$loginNode/loginResposne.text = "Please fill in all fields."
		show_response_for_3_seconds("login", "Please fill in all fields.")
		print("Please fill in all fields.")
	else:
		login(email, password)

# Handle Signup button press
func _on_signup_btn_pressed() -> void:
	var full_name = $signupNode/fullNameInput.text
	var email = $signupNode/emailInput1.text
	var password = $signupNode/password1Input1.text
	var password2 = $signupNode/password2Input2.text
	var section_id = $signupNode/sectionInput.text

	# Hide password input fields (if not already hidden)
	$signupNode/password1Input1.secret = true
	$signupNode/password2Input2.secret = true

	# Check if any of the required fields are empty
	if full_name.is_empty() or email.is_empty() or password.is_empty() or section_id.is_empty():
		$signupNode/signupResponse.text = "Please fill in all fields."
		show_response_for_3_seconds("signup", "Please fill in all fields.")
		print("Please fill in all fields.")

	# Validate email format
	elif not is_valid_email(email):
		$signupNode/signupResponse.text = "Invalid email address."
		show_response_for_3_seconds("signup", "Invalid email address.")
		print("Invalid email address.")

	# Check if passwords match
	elif password != password2:
		$signupNode/signupResponse.text = "Passwords do not match."
		show_response_for_3_seconds("signup", "Passwords do not match.")
		print("Passwords do not match.")

	else:
		# Proceed with signup if passwords match and email is valid
		signup(full_name, email, password, section_id)

# Function to validate email format using regex
func is_valid_email(email: String) -> bool:
	var regex = RegEx.new()
	# Basic email regex pattern (you can adjust it if needed)
	var pattern = r"^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$"

	var error = regex.compile(pattern)
	if error != OK:
		print("Failed to compile regex:", error)
		return false

	return regex.search(email) != null





# Start Button - Go to the Map
func _on_mainstart_btn_pressed():
	$"sound-effect".play()
	$mapMenu.visible = true
	$mainMenu.visible = false
	$optionMenu.visible = false
	$descMenu.visible = false
	for x in button_order.size():
		if(Global.pq_progress[x-1]):
			get_node(button_order[x-1]).add_theme_color_override("font_color", "Green")

# Options Button - Go to the option
func _on_mainoption_btn_pressed():
	$"sound-effect".play()
	$mapMenu.visible = false
	$mainMenu.visible = false
	$optionMenu.visible = true
	$descMenu.visible = false

func _on_maindesc_btn_pressed():
	$"sound-effect".play()
	$mapMenu.visible = false
	$mainMenu.visible = false
	$optionMenu.visible = false
	$descMenu.visible = true

func _complete_game():
	$"sound-effect".play()
	$mapMenu.visible = false
	$mainMenu.visible = false
	$optionMenu.visible = false
	$descMenu.visible = true
	$"descMenu/desc/desc-title".hide()
	$"descMenu/desc/desc-content".hide()

func congrats():
	for lvl in Global.pq_progress:
		if(!lvl):
			return
	$finishMenu/confetti.play()
	$finishMenu/confetti2.play()
	#$finishMenu/dolphin.play()
	$finishMenu.show()
	
# --------------------------------------------------------------
# Options code
# --------------------------------------------------------------

# Back Button: Go back to the main menu
func _on_optionback_btn_pressed():
	$"sound-effect".play()
	$mapMenu.visible = false
	$mainMenu.visible = true
	$optionMenu.visible = false
	$descMenu.visible = false
	
# Volume setup
func volume(bus_index, value):
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
	
# Master slider-
func _on_master_value_changed(value):
	volume(0, value)
	masterVolume = value
	
# Music slider
func _on_music_value_changed(value):
	volume(1, value)
	musicVolume = value

# Sound fx slider
func _on_sfx_value_changed(value):
	volume(2, value)
	sfxVolume = value

# Master mute button
func _on_optionmaster_box_toggled(toggled_on):
	if toggled_on == true:
		volume(0, 0)
	else:
		volume(0, masterVolume)

# Music mute button
func _on_optionmusic_box_toggled(toggled_on):
	if toggled_on == true:
		volume(1, 0)
	else:
		volume(1, musicVolume)

# Sound effect mute button
func _on_optionsfx_box_toggled(toggled_on):
	if toggled_on == true:
		volume(2, 0)
	else:
		volume(2, sfxVolume)
	
# --------------------------------------------------------------
# Map code
# --------------------------------------------------------------

#Switch scene
func _on_mapbtn_pressed(level):
	print("Level - ", level)
	$"sound-effect".play()
	$levelMenu.visible = false
	$mainMenu.visible = false
	$levelMenu.visible = false
	$optionMenu.visible = false
	$descMenu.visible = false
	if(level == "medium" and Global.canPlayLevel2 == true):
		get_tree().change_scene_to_file("res://pq/" + level + ".tscn")
	elif(level == "medium" and Global.canPlayLevel2 == false):
		get_tree().change_scene_to_file("res://pq/easy.tscn")
	elif(level == "hard" and Global.canPlayLevel3 == true):
		get_tree().change_scene_to_file("res://pq/" + level + ".tscn")
	elif(level == "hard" and Global.canPlayLevel3 == false):
		if(Global.canPlayLevel2 == true):
			get_tree().change_scene_to_file("res://pq/medium.tscn")
		else:
			get_tree().change_scene_to_file("res://pq/easy.tscn")
	else:
		get_tree().change_scene_to_file("res://pq/easy.tscn")
		
		
		
		

# Back Button: Go back to the main menu
func _on_mapback_btn_pressed():
	$"sound-effect".play()
	$mapMenu.visible = false
	$mainMenu.visible = true
	$optionMenu.visible = false
	$descMenu.visible = false



func _on_go_to_login_btn_pressed() -> void:
	$signupNode.hide()
	$loginNode.show()

func _on_go_to_signup_btn_pressed() -> void:
	$signupNode.show()
	$loginNode.hide()
