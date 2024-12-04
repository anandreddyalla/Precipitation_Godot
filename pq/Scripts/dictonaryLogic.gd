extends Node

# Array to store the question data from the API
var questions = []
var level1_questions = []
var level2_questions = []
var level3_questions = []
var current_question = {}
var question_number = 0  # Counter to track the current question
var currentQuestion = Global.currentQuestion
var currentLevel = Global.currentLevel
# HTTPRequest instance
var http_request

func _ready():
	http_request = HTTPRequest.new()  # Create HTTPRequest node
	add_child(http_request)
	http_request.connect("request_completed", Callable(self, "_on_request_completed"))
	fetch_data_from_api()

# Function to fetch data from an API
func fetch_data_from_api():
	var url = str(Global.baseUrl)+"/genQuestions"  # API endpoint
	http_request.request(url)

# Callback for when the request is completed
func _on_request_completed(result, response_code, headers, body):
	print("Code -> ", response_code)
	#print("Result -> ", result)
	if response_code == 200:
		var json_parser = JSON.new()
		var parse_result = json_parser.parse(body.get_string_from_utf8())
		print("Parse result -> ", parse_result)
		if parse_result == OK:
			var json_data = json_parser.data
			questions = json_data["level1"]
			Global.questions = questions
			level1_questions = json_data["level1"]
			level2_questions = json_data["level2"]
			level3_questions = json_data["level3"]
			Global.level1_questions = level1_questions
			Global.level2_questions = level2_questions
			Global.level3_questions = level3_questions
			#print("Questions loaded: ", questions)
			startGameText()  # Start the game after loading data
		else:
			print("Error parsing JSON: ", parse_result)
	else:
		print("Request failed with code: %d" % response_code)

func flask_throw(selected_option):
	
	var correct_option_text = current_question.options[current_question.correctOption-1]
	# Compare the selected option text with the correct option text
	print("Selected Option ", selected_option)
	print("Correct option", correct_option_text)
	if selected_option == correct_option_text:
		get_parent().correct()  # Call correct function on the parent node
		print("Correct answer!")
	else:
		get_parent().incorrect()  # Call incorrect function on the parent node
		print("Incorrect answer!")
	

# Function to start the game and set up the first problem
func startGameText():
	if level1_questions.size() == 0 or level2_questions.size() == 0 or level3_questions.size() == 0:
		print("Data is not yet loaded")
		return

	print("Starting game...")
	
	match Global.currentLevel:
		"Easy":
			questions = Global.level1_questions
			currentLevel = "Easy"
		"Medium":
			questions = Global.level2_questions
			currentLevel = "Medium"
		"Hard":
			questions = Global.level3_questions
			currentLevel = "Hard"
	if question_number < questions.size():
		current_question = questions[question_number]  # Get the current question based on the index
		question_number += 1  # Increment the index for the next question
		Global.questionNumber = question_number
		if(currentLevel == "Easy"):
			Global.currentQuestion = current_question.questionText
			get_parent().puddle = current_question.questionText
		else:
			Global.currentQuestion = current_question.statement
			Global.currentPudddle = current_question.questionText
			get_parent().puddle = current_question.statement
		# Display the question and options
		print("Selected question: ", current_question.questionText)
		print("Options: ", current_question.options)
				# Set parent properties and call parent's updateText function
		  # Store the current question
		get_parent().button_options = current_question.options.duplicate()
		#get_parent().jumble()
		get_parent().call("updateText")  # Call parent's method to update text
	else:
		print("No more questions available!")  # All questions have been asked
