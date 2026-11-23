extends CharacterBody3D

@export var walk_speed := 3.5
@export var run_speed := 7.0
@export var jump_velocity := 5.5 
@export var fly_speed := 6.5
@export var vertical_fly_speed := 4.5
@export var rotation_speed := 10.0
@export var fly_pitch_degrees := 30.0
@export var tilt_speed := 6.0

const ANIM_IDLE := "Idle_3"
const ANIM_WALK := "Walking_Woman"
const ANIM_RUN := "Running"
const ANIM_FLY := "_01a1e1a1_adbf_7226_a4b5_5e7b38c65407"

@onready var fairy_model: Node3D = $fairyAnimations
@onready var anim_player: AnimationPlayer = $fairyAnimations/AnimationPlayer

var is_flying := false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := Vector3(input_dir.x, 0.0, input_dir.y).normalized()
	var is_sprinting := Input.is_action_pressed("sprint")

	# Toggle flight with Enter
	if Input.is_action_just_pressed("fly_toggle"):
		is_flying = !is_flying
		if is_flying:
			velocity.y = 4.0
			move_and_slide()
			_update_animation(direction, is_sprinting)
			return

	if is_flying:
		# flight movement
		if direction != Vector3.ZERO:
			velocity.x = direction.x * fly_speed
			velocity.z = direction.z * fly_speed
		else:
			velocity.x = move_toward(velocity.x, 0.0, fly_speed)
			velocity.z = move_toward(velocity.z, 0.0, fly_speed)

		var vertical_input := Input.get_axis("fly_down", "fly_up")
		velocity.y = vertical_input * vertical_fly_speed

		# Landing
		if is_on_floor() and vertical_input < 0.0:
			is_flying = false
	else:
		# Ground gravity &  "jump" action
		if not is_on_floor():
			velocity.y -= gravity * delta
		elif Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity

		# Ground walk / run movement
		var current_speed := run_speed if is_sprinting else walk_speed
		if direction != Vector3.ZERO:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0.0, current_speed)
			velocity.z = move_toward(velocity.z, 0.0, current_speed)

	# Rotate toward movement direction on Y, and tilt downward on X only while flying horizontally
	if direction != Vector3.ZERO:
		var target_angle := atan2(direction.x, direction.z)
		fairy_model.rotation.y = lerp_angle(fairy_model.rotation.y, target_angle, rotation_speed * delta)

	var target_pitch := deg_to_rad(fly_pitch_degrees) if (is_flying and direction != Vector3.ZERO) else 0.0
	fairy_model.rotation.x = lerp_angle(fairy_model.rotation.x, target_pitch, tilt_speed * delta)

	move_and_slide()
	_update_animation(direction, is_sprinting)


func _update_animation(direction: Vector3, is_sprinting: bool) -> void:
	var target_anim := ANIM_IDLE

	if is_flying:
		target_anim = ANIM_FLY
	elif not is_on_floor():
		target_anim = ANIM_RUN
	elif direction != Vector3.ZERO:
		target_anim = ANIM_RUN if is_sprinting else ANIM_WALK

	if anim_player.current_animation != target_anim:
		anim_player.play(target_anim, 0.2)
