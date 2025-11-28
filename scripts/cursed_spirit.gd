extends CharacterBody2D

@export var speed := 80
@export var stop_distance := 30   # how close before attacking
@export var attack_cooldown := 1.
@onready var player: Node2D
@onready var anim_tree : AnimationTree =  $AnimationTree
var health := 2
var can_attack := true

@onready var sprite := $Sprite2D

func _ready():
	#put the curse in group enemies
	add_to_group("enemies")
	# Find the player automatically
	player = get_tree().get_root().find_child("Player", true, false) #looks everywhere starting in this scene until it finds Player
	
func _process(_delta):
	update_animation_parameters()

func _physics_process(delta):
	if player == null:
		return
		
	#gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	var distance = global_position.distance_to(player.global_position)

	# Face the player
	sprite.flip_h = (player.global_position.x < global_position.x)

	if distance > stop_distance:
		move_toward_player(delta)
	else:
		velocity = Vector2.ZERO
		attempt_attack()

	move_and_slide()
	
func take_damage():
	health -= 1
	print("Enemy took damage, HP =", health)

	if health <= 0:
		die()	
		
func die():
	queue_free()
	
func move_toward_player(delta):
	var direction = (player.global_position - global_position).normalized()
	velocity.x = direction.x * speed

func attempt_attack():
	if can_attack:
		can_attack = false
		attack()
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true

func attack():
	print("Enemy attacks!")  # replace this later with animation or damage
	
func update_animation_parameters():
	if velocity.x == 0:
		anim_tree["parameters/conditions/idle"] = true
		anim_tree["parameters/conditions/is_walking"] = false
	else:
		anim_tree["parameters/conditions/idle"] = false
		anim_tree["parameters/conditions/is_walking"] = true
