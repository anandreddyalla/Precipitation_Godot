extends Node

var pq_progress = [false, false, false]
var questions
var currentQuestion
var currentPudddle
var questionNumber
var level1_score = 0
var level2_score = 0
var level3_score = 0
var studentId = "dbda86c9-06f6-47f9-a306-45f4fe3ff89d"
var studentName
var baseUrl = "https://precipitatesec05.onrender.com/api"
var currentLevel = "Easy"
var canPlayLevel2 = false
var canPlayLevel3 = false
var level1_questions = []
var level2_questions = []
var level3_questions = []
