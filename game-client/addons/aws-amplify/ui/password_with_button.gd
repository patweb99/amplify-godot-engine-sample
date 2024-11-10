extends HBoxContainer
class_name PasswordWithButton

const EYE_SOLID = preload("res://addons/aws-amplify/icons/eye-solid.svg")
const EYE_SLASH_SOLID = preload("res://addons/aws-amplify/icons/eye-slash-solid.svg")

@onready @export var password: LineEdit = %Password
@onready @export var password_button: Button = $PasswordButton

func _on_password_button_toggled(toggled) -> void:
	password.secret = !toggled
	if toggled:
		password_button.icon = EYE_SLASH_SOLID
	else:
		password_button.icon = EYE_SOLID
