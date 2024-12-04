extends CanvasLayer

var button_options = ["","",""]
var puddle = ""
var curr_scene = ""
var health_var = 3
var prog_jump = 0
var prog_new = 0
var questions = Global.questions
# Declare the HTTPRequest node
var http_request : HTTPRequest
var student_id = Global.studentId
var base_url = str(Global.baseUrl)+"/updateScore?studentId="+str(Global.studentId)

func _ready():
	print(base_url)
	curr_scene = get_tree().current_scene.name
	match curr_scene:
		"Tutorial":
			$Textbox.show()
			prog_jump = 44
		"Easy":
			prog_jump = 7
			Global.currentLevel = "Easy"
			$score.text = "Score: " + str(Global.level1_score) + " / 6"
			$Level.text = "Level: 1"
		"Medium":
			prog_jump = 7
			Global.currentLevel = "Medium"
			$score.text = "Score: " + str(Global.level2_score) + " / 6"
			$Level.text = "Level: 2"
		"Hard":
			prog_jump = 7
			Global.currentLevel = "Hard"
			$score.text = "Score: " + str(Global.level3_score) + " / 6"
			$Level.text = "Level: 3"
	$ScienceScript.startGameText()
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._on_HTTPRequest_request_completed)
	# Connect meta_clicked signals for each RichTextLabel
	$Flasks/FlaskHolder/Option1.connect("meta_clicked", Callable(self, "_on_RichTextLabel_meta_clicked"))
	$Flasks/FlaskHolder/Option2.connect("meta_clicked", Callable(self, "_on_RichTextLabel_meta_clicked"))
	$Flasks/FlaskHolder/Option3.connect("meta_clicked", Callable(self, "_on_RichTextLabel_meta_clicked"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func updateScore(level: String, score: String) -> void:
	var payload = {
		"level": level,
		"score": score
	}
	var json_payload = JSON.stringify(payload).to_utf8_buffer()  # Convert the JSON payload to PackedByteArray
	var headers = PackedStringArray(["Content-Type: application/json"])

	var request_url = base_url  # Store the URL before making the request
	http_request.request_raw(base_url, headers, HTTPClient.METHOD_POST, json_payload)

# Callback for handling HTTP request responses
func _on_HTTPRequest_request_completed(result: int, response_code: int, headers: Array, body: PackedByteArray):
	if body.size() == 0:
		print("Empty response body")
		return

	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())

	if error != OK:
		print("Failed to parse JSON:", error)
		return

	# Access the parsed data through the 'data' property
	var response_data = json.data

	# Print the parsed response for debugging
	print("Response Data -> ", response_data)

	if response_code == 200:
		print("Score updated successfully!")
		print(response_data["message"])
		print("Updated Student Info:", response_data["student"])
	elif response_code == 400:
		print("Invalid level provided")
		print(response_data.get("message", "Unknown error"))
	elif response_code == 404:
		print("Student not found")
		print(response_data.get("message", "Unknown error"))
	else:
		print("Error:", response_data.get("message", "Unknown error"))

func updateText():
	jumble()
	$Flasks/FlaskHolder/Option1.bbcode_text = '[center][color=black][url="chem_button_1"]' + button_options[0] + '[/url][/color][/center]'
	$Flasks/FlaskHolder/Option2.bbcode_text = '[center][color=black][url="chem_button_2"]' + button_options[1] + '[/url][/color][/center]'
	$Flasks/FlaskHolder/Option3.bbcode_text = '[center][color=black][url="chem_button_3"]' + button_options[2] + '[/url][/color][/center]'
	if(Global.currentLevel != 'Easy'):
		$Puddle.text = str(Global.currentPudddle)
	else:
		$Puddle.text = str("Compound")
	$questionLabel.text = "Q"+str(Global.questionNumber)+str(". ")
	$questionTextLabel.bbcode_text = '[center][color=black]' + str(Global.currentQuestion) +  '[/color][/center]'

func _on_chem_button_pressed(button):
	if(curr_scene == "Tutorial"):
		get_tree().call_group("flask_reactions", "flask_throw")
		$ScienceScript.flask_throw(puddle, button_options[button])
		$Textbox/TextboxScript.update_dolphin_textbox(tutorial_dict["phial"])
	else:		
		#if textbox is active show hints
		if ($PauseButton.button_pressed):
			print("Disabling throw function while hints are being shown")
			#show_hints(hint_dict[puddle])
		else:
			$Flasks.hide()
			#if textbox is inactive meaning player is playing, throw the chemical
			get_tree().call_group("flask_reactions", "flask_throw")
			$ScienceScript.flask_throw(button_options[button])
			
func _on_RichTextLabel_meta_clicked(meta):
	match meta:
		"chem_button_1":
			handle_chemical_button_click(0)
		"chem_button_2":
			handle_chemical_button_click(1)
		"chem_button_3":
			handle_chemical_button_click(2)
			

func handle_chemical_button_click(button_id):
	if (curr_scene == "Tutorial"):
		get_tree().call_group("flask_reactions", "flask_throw")
		$ScienceScript.flask_throw(puddle, button_options[button_id])
		$Textbox/TextboxScript.update_dolphin_textbox(tutorial_dict["phial"])
	else:
		if ($PauseButton.button_pressed):
			print("Disabling throw function while hints are being shown")
		else:
			$Flasks.hide()
			get_tree().call_group("flask_reactions", "flask_throw")
			$ScienceScript.flask_throw(button_options[button_id])


func incorrect():
	await get_tree().create_timer(2).timeout
	health_var -= 1
	$Health.get_children()[health_var].hide()
	if(health_var == 0):
		if(Global.currentLevel == "Easy"):
			await updateScore("level1Score", str(Global.level1_score))
		elif(Global.currentLevel == "Medium"):
			await updateScore("level2Score", str(Global.level2_score))
		else:
			await updateScore("level3Score", str(Global.level3_score))
			
		Global.level1_score = 0
		Global.level2_score = 0
		Global.level3_score = 0
		$Flasks.hide()
		$PauseButton.hide()
		$Puddle.hide()
		$ProgressBar.hide()
		$Retry.show()
		$ExitButton.show()
	else:
		print("Incorrect")
		#prog_new += prog_jump
		await get_tree().create_timer(3).timeout
		if(prog_new < 42):
			$Health.hide()
			self.hide()
			$ScienceScript.startGameText()
			get_tree().call_group("flask_reactions", "_walk")
			get_tree().call_group("flask_reactions", "move_forward")
			await get_tree().create_timer(2).timeout
			get_tree().call_group("flask_reactions", "_stop")
			get_parent().question_number += 1
			self.show()
			$Health.show()
			$Flasks.show()

func jumble():
	print("Btns before shuffle: ", button_options)
	button_options.shuffle() 
	print("Btns after shuffle: ", button_options)  # Print after shuffling to check final state


	
func correct():
	print("Prog - ", prog_jump)
	print("Progress - ", $ProgressBar.frame)
	prog_new += prog_jump
	print("Prog new - ", prog_new)
	await get_tree().create_timer(2).timeout
	get_tree().call_group("flask_reactions", "success")
	await get_tree().create_timer(3).timeout
	if(prog_new < 44):
		$Health.hide()
		$score.hide()
		self.hide()
		$ScienceScript.startGameText()
		get_tree().call_group("flask_reactions", "_walk")
		get_tree().call_group("flask_reactions", "move_forward")
		await get_tree().create_timer(2).timeout
		get_tree().call_group("flask_reactions", "_stop")
		get_parent().question_number += 1
		if(Global.currentLevel == 'Easy'):
			Global.level1_score += 1
			$score.text = "Score: " + str(Global.level1_score) + " / 6"
		elif(Global.currentLevel == 'Medium'):
			Global.level2_score += 1
			$score.text = "Score: " + str(Global.level2_score) + " / 6"
		else:
			Global.level3_score += 1
			$score.text = "Score: " + str(Global.level3_score) + " / 6"
		$score.show()
		self.show()
		$Health.show()
	$Flasks.show()
	if(prog_new >= 42):
		print("YES!")
		match(curr_scene):
			"Easy":
				print("Score ", Global.level1_score)
				await updateScore("level1Score", str(Global.level1_score))
				Global.pq_progress[0] = true
				Global.canPlayLevel2 = true
				$Flasks.hide()
				$questionLabel.hide()
				$questionTextLabel.hide()
				$Puddle.hide()
				$response.show()
				$ExitButton.show()
				#_on_exit_button_pressed()
			"Medium":
				await updateScore("level2Score", str(Global.level2_score))
				Global.pq_progress[1] = true
				Global.canPlayLevel3 = true
				$Flasks.hide()
				$questionLabel.hide()
				$questionTextLabel.hide()
				$Puddle.hide()
				$response.show()
				$response.text = "You have successfully cleared the Level 2"
				$ExitButton.show()
				#_on_exit_button_pressed()
			"Hard":
				await updateScore("level3Score", str(Global.level3_score))
				Global.pq_progress[2] = true
				$Flasks.hide()
				$questionLabel.hide()
				$questionTextLabel.hide()
				$Puddle.hide()
				$finishMenu.show()
				$ExitButton.show()
				#_on_exit_button_pressed()

func _on_pause_button_toggled(toggled_on):
	$ExitButton.visible = toggled_on
	$Health.visible = !toggled_on
	#$ProgressBar.visible = !toggled_on
	$Textbox.visible = toggled_on
	$HelpButton.visible = !toggled_on
	if(curr_scene == "Tutorial"):
		$Textbox/TextboxScript.update_dolphin_textbox(tutorial_dict["pause"])
	else:
		print("question -> ", Global.currentQuestion)
		var quest = Global.currentQuestion
		$Textbox/TextboxScript.update_dolphin_textbox(quest)
		$Textbox/TextboxContainer.visible = toggled_on


func _on_help_button_toggled(toggled_on):
	_on_pause_button_toggled(toggled_on)
	$HelpButton.visible = true
	$PauseButton.visible = !toggled_on
	$ExitButton.visible = false
	$HelpButton/SolubilityChart.visible = toggled_on
	$HelpButton/SolubilityKey.visible = toggled_on

func _on_exit_button_pressed():
	get_tree().change_scene_to_file("res:///pq/Menu/main_menu.tscn")

##function to show hint for individual flask button pressed
#func show_hints(compound):
	#if (compound == "Hg2(NO3)2"):
		#$Textbox/TextboxScript.update_dolphin_textbox("Hg2(NO3)2")
	#elif (compound == "AgBr"):
		#$Textbox/TextboxScript.update_dolphin_textbox("AgBr")
	#elif (compound ==  "MgCO3"):
		#$Textbox/TextboxScript.update_dolphin_textbox("MgCO3")

var hint_dict = {
	"K⁺,Cl⁻": "Choose compounds to add to precipitate the Cl⁻ ions from water.",
	"2Na⁺,C₂O₄²⁻": "Choose compounds to add to precipitate the C2O4²⁻ ions from water.",
	"K⁺,F⁻": "Choose compounds to add to precipitate the F⁻ ions from water.",
	"Al³⁺,3Cl⁻": "Choose compounds to add to precipitate the Al³⁺ ions from water.",
	"2Na⁺,CO₃²⁻": "Choose compounds to add to precipitate the CO3²⁻ ions from water.",
	"Pb²⁺,2NO₂⁻": "Choose compounds to add to precipitate the Pb²⁺ ions from water.",
	"Ca²⁺,2Br⁻": "Choose compounds to add to precipitate the Ca²⁺ ions from water.",
	"K⁺,NO₃⁻": "Choose compounds to add to precipitate the NO3⁻ ions from water.",
	"Fe²⁺,2Cl⁻": "Choose compounds to add to precipitate the Fe²⁺ ions from water.",
	"Na+,PO₄³⁻": "Choose compounds to add to precipitate the PO4³⁻ ions from water.",
	"K⁺,AsO₄³⁻": "Choose compounds to add to precipitate the AsO4³⁻ ions from water.",
	"Cd²⁺,SO₄²⁻": "Choose compounds to add to precipitate the Cd²⁺ ions from water.",
	"Cr³⁺,SCN⁻": "Choose compounds to add to precipitate the Cr³⁺ ions from water.",
	#"LiClO₄": "Choose compounds to add to precipitate the ClO4⁻ ions from water.",
	"NO₃⁻,Ag⁺": "Choose compounds to add to precipitate the Ag⁺ ions from water.",
	"K⁺,CrO₄²⁻": "Choose compounds to add to precipitate the CrO4²⁻ ions from water.",
	"Na⁺,PO₄³⁻,OH⁻,OH⁻": "Choose compounds to add to precipitate the PO4³⁻ ions from water.",
	"Na⁺,AsO₄³⁻,OH⁻": "Choose compounds to add to precipitate the AsO4³⁻ ions from water.",
	"Cl⁻,Hg²⁺,O²⁻": "Choose compounds to add to precipitate the Hg²⁺ ions from water.",
	"Hg²⁺,NO₃⁻": "Choose compounds to add to precipitate the Hg²⁺ ions from water."
}

var tutorial_dict = {
	"tutorial" : "Welcome to the Ocean Lab tutorial. Press the flask button to throw a phial",
	"phial": "When this button is pressed, the player throws a phial hoping to form a precipitate in the puddle. Now press the pause button.",
	"speaker": "Fancy some music? Toggle it on and off with this button",
	"help": "this button's functionality is under construction",
	"exit" : "press the exit button if you are ready",
	"pause" : "Pausing shows a hint! The help button shows a solubility table. (Finding tables online may be needed). You can exit now.",
	"play" : "press play when you are ready to throw the phial"
}
