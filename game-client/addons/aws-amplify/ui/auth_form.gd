extends Control
class_name AuthForm

const USER_CONFIG_PATH = "user://.config"
const CONFIG_EMAIL = "email"

var config: Dictionary = {}

# Form

@onready var auth_tab: TabContainer = %AuthTab
@onready var sign_in: VBoxContainer = %SignIn
@onready var sign_up: VBoxContainer = %SignUp

# Sign-In
@onready var sign_in_e_mail: LineEdit = %SignInEMail
@onready var sign_in_password_container: PasswordWithButton = %SignInPasswordContainer
@onready var sign_in_button: Button = %SignInButton
@onready var sign_in_error: Label = %SignInError
@onready var sign_in_remember_me: CheckButton = %SignInRememberMe
@onready var forgot_password_confirm: VBoxContainer = %ForgotPasswordConfirm
@onready var forgot_password_confirm_code: LineEdit = %ForgotPasswordConfirmCode
@onready var forgot_password_confirm_password: PasswordWithButton = %ForgotPasswordConfirmPassword
@onready var forgot_password_confirm_password_confirmation: PasswordWithButton = %ForgotPasswordConfirmPasswordConfirmation
@onready var forgot_password_confirm_button: Button = %ForgotPasswordConfirmButton
@onready var forgot_password_confirm_error: Label = %ForgotPasswordConfirmError

func _on_sign_in_button_pressed():
	sign_in_button.disabled = true
	var response = await aws_amplify.auth.sign_in_with_user_password(sign_in_e_mail.text, sign_in_password_container.password.text)
	if response.success and sign_in_remember_me.toggled:
		config[CONFIG_EMAIL] = sign_in_e_mail.text
		_save_user_config()
	else:
		sign_in_error.text = response.response_body.message
	sign_in_button.disabled = false
		
func _on_sign_in_sign_up_link_pressed() -> void:
	auth_tab.current_tab = 1

func _forgot_password_confirm_link_pressed() -> void:
	var response = await aws_amplify.auth.forgot_password(sign_in_e_mail.text)
	if response.success:
		sign_in.hide()
		forgot_password_confirm.show()
	else:
		sign_in_error.text = response.response_body.message

func _forgot_password_confirm_button_pressed() -> void:
	forgot_password_confirm_button.disabled = true
	if forgot_password_confirm_password.password.text != forgot_password_confirm_password_confirmation.password.text:
		forgot_password_confirm_error.text = "Both passwords do not match!"
	else:
		var response = await aws_amplify.auth.forgot_password_confirm_code(
			sign_in_e_mail.text, 
			forgot_password_confirm_code.text, 
			forgot_password_confirm_password.password.text
		)
		if response.success:
			sign_in.show()
			forgot_password_confirm.hide()
		else:
			forgot_password_confirm_error.text = response.response_body.message
	forgot_password_confirm_button.disabled = false

func _forgot_password_confirm_send_code_link_pressed() -> void:
	_forgot_password_confirm_link_pressed()
	
func _forgot_password_confirm_draw() -> void:
	auth_tab.set_tab_disabled(1, true)

func _forgot_password_confirm_hidden() -> void:
	auth_tab.set_tab_disabled(1, false)
	
# Sign-Up

@onready var sign_up_e_mail: LineEdit = %SignUpEMail
@onready var sign_up_password: PasswordWithButton = %SignUpPassword
@onready var sign_up_password_confirmation: PasswordWithButton = %SignUpPasswordConfirmation
@onready var sign_up_error: Label = %SignUpError
@onready var sign_up_confirm: VBoxContainer = %SignUpConfirm
@onready var sign_up_confirm_code: LineEdit = %SignUpConfirmCode
@onready var sign_up_confirm_error: Label = %SignUpConfirmError

func _on_sign_up_button_pressed() -> void:
	var response = await aws_amplify.auth.sign_up(sign_up_e_mail.text, sign_up_password.password.text)
	if response.success:
		sign_up.hide()
		sign_up_confirm.show()
	else:
		sign_up_error.text = response.response_body.message

func _on_sign_up_sign_in_link_pressed() -> void:
	auth_tab.current_tab = 0

func _on_sign_up_confirm_link_pressed() -> void:
	sign_up.hide()
	sign_up_confirm.show()

func _on_sign_up_confirm_button_pressed() -> void:
	if sign_up_password.password.text != sign_up_password_confirmation.password.text:
		sign_up_confirm_error.text = "Both passwords do not match!"
	else:
		var response = await aws_amplify.auth.sign_up_confirm_code(sign_up_e_mail.text, sign_up_confirm_code.text)
		if response.success:
			sign_up.show()
			sign_up_confirm.hide()
			auth_tab.current_tab = 0
		else:
			sign_up_confirm_error.text = response.response_body.message
		
func _on_sign_up_confirm_send_code_link_pressed() -> void:
	var response = await aws_amplify.auth.sign_up_resend_code(sign_up_e_mail.text)
	if response.success:
		auth_tab.current_tab = 0
	else:
		sign_up_confirm_error.text = response.response_body.message
	
func _on_sign_up_confirm_draw() -> void:
	auth_tab.set_tab_disabled(0, true)

func _on_sign_up_confirm_hidden() -> void:
	auth_tab.set_tab_disabled(0, false)

func _load_user_config() -> void:
	if FileAccess.file_exists(USER_CONFIG_PATH):
		var config_file = FileAccess.open(USER_CONFIG_PATH, FileAccess.READ)
		var config_content = config_file.get_as_text()
		config = JSON.parse_string(config_content)
	else:
		config = {}

func _save_user_config() -> void:
	var config_file = FileAccess.open(USER_CONFIG_PATH, FileAccess.WRITE)
	var config_content = JSON.stringify(config)
	config_file.store_string(config_content)
	
# Init
func _ready() -> void:
	auth_tab.set_tab_title(0, "Sign-In")
	auth_tab.set_tab_title(1, "Sign-Up")
	
	_load_user_config()	
	
	if config.has(CONFIG_EMAIL):
		auth_tab.current_tab = 0
		sign_in_e_mail.text = config[CONFIG_EMAIL]
		sign_in_e_mail.grab_focus()
	else:
		auth_tab.current_tab = 1
		sign_up_e_mail.grab_focus()
