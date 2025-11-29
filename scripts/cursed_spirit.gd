extends CharacterBody2D

@export var speed := 40
@export var stop_distance := 30   # how close before attacking
@export var attack_cooldown := 1.
@onready var player: Node2D
@onready var anim_tree : AnimationTree =  $AnimationTree
@onready var CollisionShape = $CollisionShape2D
@onready var HurtBoxCollisionShape = $Hurtbox/HurtBoxCollisionShape2D
@export var knockback_decay := 500
var CollisionShapeFacingRight = -7
var CollisionShapeFacingLeft = 7
var HurtBoxCollisionShapeFacingRight = -7.5
var HurtBoxCollisionShapeFacingLeft = 7.5
var health := 20
var can_attack := true
var damaged = false

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

	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Face player
	if player.global_position.x < global_position.x:
		update_facing_direction("left")
	else:
		update_facing_direction("right")
		
	#movement
	move_toward_player(delta)

	move_and_slide()
	
func take_spear_damage():
	damaged = true
	#damage output
	health -= 3
	print("Enemy took Heavy damage, HP =", health)
	
	#die if health is below 0
	if health <= 0:
		die()	
	await get_tree().create_timer(0.2).timeout 
	damaged = false
		
func take_punch_damage():
	damaged = true
	#damage output
	health -= 1
	print("Enemy took Light damage, HP =", health)
	
	#die if health is below 0
	if health <= 0:
		die()
	await get_tree().create_timer(0.2).timeout 
	damaged = false
		
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

func update_facing_direction(facing):
	if facing == "left" :
		sprite.flip_h = true
		CollisionShape.position.x = CollisionShapeFacingLeft
		HurtBoxCollisionShape.position.x = HurtBoxCollisionShapeFacingLeft
	else :
		sprite.flip_h = false
		CollisionShape.position.x = CollisionShapeFacingRight
		HurtBoxCollisionShape.position.x = HurtBoxCollisionShapeFacingRight
	
func update_animation_parameters():
	#if damaged is priority
	if damaged :
		anim_tree["parameters/conditions/damaged"] = true
		anim_tree["parameters/conditions/idle"] = false
		anim_tree["parameters/conditions/is_walking"] = false
	else :
		anim_tree["parameters/conditions/damaged"] = false
		if velocity.x == 0:
			anim_tree["parameters/conditions/idle"] = true
			anim_tree["parameters/conditions/is_walking"] = false
		else:
			anim_tree["parameters/conditions/idle"] = false
			anim_tree["parameters/conditions/is_walking"] = true
