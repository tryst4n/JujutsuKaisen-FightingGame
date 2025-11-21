extends CharacterBody2D


const SPEED = 150.0
var ACCELERATION := 300
const JUMP_VELOCITY = -400.0
@onready var sprite = $Sprite2D
@onready var anim_tree : AnimationTree =  $AnimationTree
@onready var sukuna = $"."
var dismantle_scene_path=preload("res://scenes/dismantle.tscn")

func _ready():
	anim_tree.active = true

func _process(_delta):
	update_animation_parameters()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	#get the input direction: -1, 0, 1
	var direction := Input.get_axis("move_left", "move_right")
	
	#horizontal movement
	if direction:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	#Shooting Dismantle
	if Input.is_action_just_pressed("main_weapon") :
		shootDismantle()

	move_and_slide()
	
func shootDismantle():
	var dismantle=dismantle_scene_path.instantiate()
	var spawn_distance = 20  # pixels

	#get mosue position
	var mouse_pos = get_global_mouse_position()
	#computes a vector between player and the mouse and convert it to an angle in radians
	var direction = (mouse_pos - global_position).angle()
	var spawn_offset = Vector2(spawn_distance, 0).rotated(direction) # spawn_offset rotates the spawn_distance to match the direction(mouse position)
	
	#Flip sukuna to the cursor's side
	# convert radians to degrees
	var angle_deg = rad_to_deg(direction)
	if angle_deg > 90 or angle_deg < -90:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
	
	dismantle.dir=direction # the projectile's movement direction in radians
	dismantle.pos=sukuna.global_position + spawn_offset# starting position of projectile + the offset
	dismantle.rota=direction # rotation of the projectile so it faces the right direction (up, left, right) in radians
	
	get_parent().add_child(dismantle)
	
func update_animation_parameters():
	var direction := Input.get_axis("move_left", "move_right")
	var is_jumping = !(velocity.y == 0) #if velocity in y = 0, character is jumping
	#flip the sprite depending on facing direction
	if direction > 0 : 
		sprite.flip_h = false
	elif direction < 0 :
		sprite.flip_h = true
	
	#HANDLE JUMPING
	if is_jumping :
		anim_tree["parameters/conditions/idle"] = false
		anim_tree["parameters/conditions/start_run"] = false
		anim_tree["parameters/conditions/is_running"] = false
		anim_tree["parameters/conditions/is_jumping"] = true
		return
	anim_tree["parameters/conditions/is_jumping"] = false
	
	#HANDLE IDLE / RUN
	if direction == 0 :
		anim_tree["parameters/conditions/idle"] = true
		anim_tree["parameters/conditions/start_run"] = false
		anim_tree["parameters/conditions/is_running"] = false
	else:
		anim_tree["parameters/conditions/idle"] = false
		anim_tree["parameters/conditions/start_run"] = true
		#when start_run animation will finish, run animation will start as set in the AnimationTree StateMachine
		anim_tree["parameters/conditions/is_running"] = true
		
