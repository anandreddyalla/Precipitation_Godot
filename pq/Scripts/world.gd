extends Node2D

var curr_scene = ""
var puddle_tops = []
var puddles = []
var scrolling = false
var index = 0
var should_move = true
# Called when the node enters the scene tree for the first time.
func _ready():
	curr_scene = get_tree().current_scene.name
	puddle_tops.append($PuddleTop)
	puddles.append($Puddle)
	if(curr_scene == "Easy"):
		puddle_tops.append($PuddleTop2)
		puddle_tops.append($PuddleTop3)
		puddle_tops.append($PuddleTop4)
		puddle_tops.append($PuddleTop5)
		puddle_tops.append($PuddleTop6)
		puddle_tops.append($PuddleTop7)
		puddle_tops.append($PuddleTop8)
		puddle_tops.append($PuddleTop9)
		puddle_tops.append($PuddleTop10)
		puddle_tops.append($PuddleTop11)
		puddle_tops.append($PuddleTop12)
		puddle_tops.append($PuddleTop13)
		puddle_tops.append($PuddleTop14)
		puddle_tops.append($PuddleTop15)
		puddle_tops.append($PuddleTop16)
		puddles.append($Puddle2)
		puddles.append($Puddle3)
		puddles.append($Puddle4)
		puddles.append($Puddle5)
		puddles.append($Puddle6)
		puddles.append($Puddle7)
		puddles.append($Puddle8)
		puddles.append($Puddle9)
		puddles.append($Puddle10)
		puddles.append($Puddle11)
		puddles.append($Puddle12)
		puddles.append($Puddle13)
		puddles.append($Puddle14)
		puddles.append($Puddle15)
		puddles.append($Puddle16)
	else:
		puddle_tops.append($PuddleTop2)
		puddle_tops.append($PuddleTop3)
		puddle_tops.append($PuddleTop4)
		puddle_tops.append($PuddleTop5)
		puddle_tops.append($PuddleTop6)
		puddle_tops.append($PuddleTop7)
		puddle_tops.append($PuddleTop8)
		puddle_tops.append($PuddleTop9)
		puddle_tops.append($PuddleTop10)
		puddle_tops.append($PuddleTop11)
		puddles.append($Puddle2)
		puddles.append($Puddle3)
		puddles.append($Puddle4)
		puddles.append($Puddle5)
		puddles.append($Puddle6)
		puddles.append($Puddle7)
		puddles.append($Puddle8)
		puddles.append($Puddle9)
		puddles.append($Puddle10)
		puddles.append($Puddle11)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(scrolling == true):
		$Background.scroll_offset.x -= 60*delta

func flask_throw():
	if (should_move):
		index = get_parent().question_number
		print("index... ",index )
	puddle_tops[index].stop()
	puddle_tops[index].play("default")

func move_forward():
	scrolling = true
	var tween : Tween = create_tween()
	var new_pos = Vector2(self.position[0] + -1152, 0)
	tween.tween_property(self, "position", new_pos, 2)
	await tween.finished
	scrolling = false

func success():
	if (should_move):
		index = get_parent().question_number
	puddles[index].stop()
	puddles[index].play("default")
