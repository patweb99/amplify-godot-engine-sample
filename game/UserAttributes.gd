class_name UserAttributes
extends ColorRect

class USER_ATTRIBUTES:
	const NAME = "preferred_username"
	const COLOR = "custom:color"

@onready var player_name: LineEdit = %Name
@onready var player_color: ColorPickerButton = %Color

func _ready() -> void:
	aws_amplify.auth.user_changed.connect(_on_user_changed)
	
	player_name.text = ""
	player_color.color = Color.ORANGE_RED
	
	var user_attributes = aws_amplify.auth.get_user_attributes()
	_update_user_attributes(user_attributes)
	
func _exit_tree() -> void:
	aws_amplify.auth.user_changed.disconnect(_on_user_changed)
	player_name.text = ""
	player_color.color = Color.ORANGE_RED
	
func _on_update_pressed() -> void:
	var user_attributes = {}
	user_attributes[USER_ATTRIBUTES.NAME] = player_name.text
	user_attributes[USER_ATTRIBUTES.COLOR] = player_color.color.to_html()
	var response = await aws_amplify.auth.add_user_attributes(user_attributes)
	if not response.success:
		print(response)

func _on_user_changed(user_attributes) -> void:
	_update_user_attributes(user_attributes)
	
func _update_user_attributes(user_attributes) -> void:
	if user_attributes.has(USER_ATTRIBUTES.NAME):
		player_name.text = user_attributes[USER_ATTRIBUTES.NAME]
	if user_attributes.has(USER_ATTRIBUTES.COLOR):
		player_color.color = Color(user_attributes[USER_ATTRIBUTES.COLOR])
