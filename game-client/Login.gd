extends Control

@onready var mail_input = $Mail
@onready var password_input = $Password
@onready var login_button = $Login

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	login_button.pressed.connect(_on_login_button_pressed)

func _on_login_button_pressed():
	
	var success = await AWSAmplify.auth.sign_in_with_user_password(mail_input.text, password_input.text)
	if success:
		get_tree().change_scene_to_file("res://Main.tscn")
