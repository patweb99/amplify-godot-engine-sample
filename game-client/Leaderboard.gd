extends Control

@onready var main_container = $VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var leaderboard_data = await get_leaderboard_data()

	leaderboard_data.sort_custom(func(a, b): return a["score"] > b["score"])
	
	for i in range(leaderboard_data.size()):
		add_leaderboard_entry(i + 1, leaderboard_data[i].username, leaderboard_data[i].score)	
	

func get_leaderboard_data():
	
	var response = await AWSAmplify.data.query("{ listLeaderboards(limit: 10) {items {username, score} }}", "QueryData")
	var json = response.response_body
	if json.has("data"):
		return json.data.listLeaderboards.items
	else:
		return []
		
func add_leaderboard_entry(rank, username, score):
	var hbox = HBoxContainer.new()
	
	var label_left = Label.new()
	label_left.text = str(rank) + ". " + username
	label_left.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	hbox.add_child(label_left)
	
	var label_right = Label.new()
	label_right.text = str(score)
	label_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	hbox.add_child(label_right)
	
	main_container.add_child(hbox)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_tree().change_scene_to_file("res://Main.tscn")
