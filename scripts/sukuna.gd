extends CharacterBody2D
class_name Sukuna


const SPEED = 150.0
var ACCELERATION := 500
const JUMP_VELOCITY = -300.0
var dismantle_scene_path=preload("res://scenes/dismantle.tscn")
var is_heavy_attacking = false
var is_light_attacking = false
var CollisionShapeFacingRight = -1
var CollisionShapeFacingLeft = 1
var SpearCollisionShapeFacingRight = 13
var SpearCollisionShapeFacingLeft = -13
var PunchCollisionShapeFacingRight = 8
var PunchCollisionShapeFacingLeft = -8
var in_knockback_state = false
var is_attacking = false
var damaged = false
var health = 20
var dying = false
@export var receives_knockback : bool = true
@export var knockback_modifier : float = 0.1
@onready var sprite = $Sprite2D
@onready var anim_tree : AnimationTree =  $AnimationTree
@onready var sukuna = $"."
@onready var CollisionShape = $CollisionShape2D
@onready var SpearCollisionShape = $Spear/SpearCollisionShape2D
@onready var PunchCollisionShape = $Punch/PunchCollisionShape2D

func _ready():
	anim_tree.active = true
	SpearCollisionShape.disabled = true
	PunchCollisionShape.disabled = true

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
		velocity.x = move_toward(velocity.x, 0, ACCELERATION * delta)
	# PREVENT MOVEMENT WHILE ATTACKING
	if is_heavy_attacking:
		velocity.x = 0 # freeze left/right
		velocity.y = move_toward(velocity.y, 0, 9999) #freeze jump
		move_and_slide()
		return
		
	#Shooting Dismantle
	if Input.is_action_just_pressed("main_ability") :
		shootDismantle()
	
	#light attack
	if Input.is_action_just_pressed("lightAttack"):
		lightAttack()
		
	#heavy attack
	if Input.is_action_just_pressed("heavyAttack") and is_on_floor() and !is_heavy_attacking and !Input.is_key_pressed(KEY_SHIFT):#prevents attacking if it already is attacking #we make sure shift is not pressed because if not, this will also trigger when main_ability is going off since we're using left click for both
		heavyAttack()
	move_and_slide()

func take_tongue_damage(globalPosEnemy):	
	print("sukuna got attacked!")
	damaged = true
	#damage output
	var damage = 1
	#Knockback
	receive_knockback(globalPosEnemy, damage)
	health -= damage
	print("Sukuna took Light damage, HP =", health)
	
	#die if health is below 0
	deathIfBelow0()
	await get_tree().create_timer(0.2).timeout 
	damaged = false
	
func receive_knockback(damage_source_pos: Vector2, received_damage: int):
	if receives_knockback:
		in_knockback_state = true

		var startingPos = global_position
		var knockback_direction = damage_source_pos.direction_to(global_position)
		knockback_direction.y = 0
		knockback_direction = knockback_direction.normalized()
		
		var end = startingPos + knockback_direction * (received_damage * 20)  # push distance

		var tween = get_tree().create_tween()
		tween.tween_property(self, "global_position", end, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		await tween.finished
		in_knockback_state = false

func deathIfBelow0():
	if health <= 0:
		dying = true
		var body = CollisionShape.get_parent()
		# Turn OFF all collision alayers so we can pass through him
		body.set_collision_layer_value(1, false)
		await get_tree().create_timer(1.4).timeout 
		queue_free()
		
func lightAttack():
	is_light_attacking = true
	get_mouse_pos_then_flip()
	await get_tree().create_timer(0.1).timeout 
	PunchCollisionShape.disabled = false
	await get_tree().create_timer(0.1).timeout 
	PunchCollisionShape.disabled = true
	await get_tree().create_timer(0.1).timeout 
	is_light_attacking = false
	
func heavyAttack():
	is_heavy_attacking = true
	get_mouse_pos_then_flip()
	#activate hitbox after 0.3s
	await get_tree().create_timer(0.3).timeout 
	SpearCollisionShape.disabled = false
	#disactivate hitbox after another 0.1s
	await get_tree().create_timer(0.1).timeout 
	SpearCollisionShape.disabled = true
	
	await get_tree().create_timer(0.7).timeout #0.7s + 0.1s + 0.3s being the total time of the attack animation
	is_heavy_attacking = false
	
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
		update_facing_direction("left");
	else:
		update_facing_direction("right");
	
	dismantle.dir=direction # the projectile's movement direction in radians
	dismantle.pos=sukuna.global_position + spawn_offset# starting position of projectile + the offset
	dismantle.rota=direction # rotation of the projectile so it faces the right direction (up, left, right) in radians
	
	get_parent().add_child(dismantle)
	
func get_mouse_pos_then_flip():
	#get mouse position
	var mouse_pos = get_global_mouse_position()
	#computes a vector between player and the mouse and convert it to an angle in radians
	var direction = (mouse_pos - global_position).angle()
	
	#Flip sukuna to the cursor's side
	# convert radians to degrees
	var angle_deg = rad_to_deg(direction)
	if angle_deg > 90 or angle_deg < -90:
		update_facing_direction("left");
	else:
		update_facing_direction("right");

func update_facing_direction(facing):
	if facing == "left" :
		sprite.flip_h = true
		CollisionShape.position.x = CollisionShapeFacingLeft
		SpearCollisionShape.position.x = SpearCollisionShapeFacingLeft
		PunchCollisionShape.position.x = PunchCollisionShapeFacingLeft
	else :
		sprite.flip_h = false
		CollisionShape.position.x = CollisionShapeFacingRight
		SpearCollisionShape.position.x = SpearCollisionShapeFacingRight
		PunchCollisionShape.position.x = PunchCollisionShapeFacingRight
	
func update_animation_parameters():
	var direction := Input.get_axis("move_left", "move_right")
	var is_jumping =  !(velocity.y == 0) #if velocity in y != 0, character is jumping
	#flip the sprite depending on facing direction
	if direction > 0 : 
		update_facing_direction("right")
		CollisionShape.position.x = -1
	elif direction < 0 :
		update_facing_direction("left")
	#HANDLE JUMPING
	if damaged :
		anim_tree["parameters/conditions/damaged"] = true
		anim_tree["parameters/conditions/idle"] = false
		anim_tree["parameters/conditions/start_run"] = false
		anim_tree["parameters/conditions/is_running"] = false
		anim_tree["parameters/conditions/is_jumping"] = false
		anim_tree["parameters/conditions/heavy"] = false
		anim_tree["parameters/conditions/light"] = false
		return
	
	if is_light_attacking :
		anim_tree["parameters/conditions/idle"] = false
		anim_tree["parameters/conditions/start_run"] = false
		anim_tree["parameters/conditions/is_running"] = false
		anim_tree["parameters/conditions/is_jumping"] = false
		anim_tree["parameters/conditions/heavy"] = false
		anim_tree["parameters/conditions/light"] = true
		anim_tree["parameters/conditions/damaged"] = false
		return
	
	if is_jumping :
		anim_tree["parameters/conditions/idle"] = false
		anim_tree["parameters/conditions/start_run"] = false
		anim_tree["parameters/conditions/is_running"] = false
		anim_tree["parameters/conditions/is_jumping"] = true
		anim_tree["parameters/conditions/heavy"] = false
		anim_tree["parameters/conditions/light"] = false
		anim_tree["parameters/conditions/damaged"] = false
		return
	anim_tree["parameters/conditions/is_jumping"] = false
	anim_tree["parameters/conditions/damaged"] = false
	
	#ATTACKING
	if is_heavy_attacking:
		anim_tree["parameters/conditions/idle"] = false
		anim_tree["parameters/conditions/start_run"] = false
		anim_tree["parameters/conditions/is_running"] = false
		anim_tree["parameters/conditions/is_jumping"] = false
		anim_tree["parameters/conditions/heavy"] = true
		anim_tree["parameters/conditions/light"] = false
		anim_tree["parameters/conditions/damaged"] = false
		return
	
	#HANDLE IDLE / RUN
	if direction == 0 :
		anim_tree["parameters/conditions/idle"] = true
		anim_tree["parameters/conditions/start_run"] = false
		anim_tree["parameters/conditions/is_running"] = false
		anim_tree["parameters/conditions/heavy"] = false
		anim_tree["parameters/conditions/light"] = false
		anim_tree["parameters/conditions/damaged"] = false
	else:
		anim_tree["parameters/conditions/idle"] = false
		anim_tree["parameters/conditions/start_run"] = true
		#when start_run animation will finish, run animation will start as set in the AnimationTree StateMachine
		anim_tree["parameters/conditions/is_running"] = true
		anim_tree["parameters/conditions/heavy"] = false
		anim_tree["parameters/conditions/light"] = false
		anim_tree["parameters/conditions/damaged"] = false


func _on_spear_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hurtbox"):
		area.take_spear_damage(global_position) #pass global position for knockback direction


func _on_punch_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hurtbox"):
		area.take_punch_damage(global_position) #pass global position for knockback direction
