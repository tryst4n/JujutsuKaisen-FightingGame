extends CharacterBody2D

@export var speed := 40
@export var stop_distance := 20   # how close before attacking
@export var attack_cooldown := 1
@export var receives_knockback : bool = true
@export var knockback_modifier : float = 0.1
@onready var player: Node2D
@onready var anim_tree : AnimationTree =  $AnimationTree
@onready var CollisionShape = $CollisionShape2D
@onready var HurtBoxCollisionShape = $Hurtbox/HurtBoxCollisionShape2D
@onready var TongueCollisionShape = $Tongue/CollisionShape2D
@onready var HitParticles = $HitParticles
@onready var PlayerCamera = $"../Player/Camera2D"
var HitParticlesFacingRight = -23
var HitParticlesFacingLeft = 23
var CollisionShapeFacingRight = -7
var CollisionShapeFacingLeft = 7
var HurtBoxCollisionShapeFacingRight = -7.5
var HurtBoxCollisionShapeFacingLeft = 7.5
var TongueCollisionShapeFacingRight = 7
var TongueCollisionShapeFacingLeft = -7
var health := 4
var can_attack := true
var damaged = false
var dying = false
var in_knockback_state = false
var is_attacking = false
var time_in_attack_range := 0.0
var player_is_dead = false
var is_walking = false

@onready var sprite := $Sprite2D

func _ready():
	#put the curse in group enemies
	add_to_group("enemies")
	# Find the player automatically
	player = get_tree().get_root().find_child("Player", true, false) #looks everywhere starting in this scene until it finds Player
	
	
func _process(_delta):
	update_animation_parameters()

func _physics_process(delta):
	if player == null or player_is_dead:
		velocity.x = 0
		is_attacking = false
		time_in_attack_range = 0.0
		is_walking = false
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)

	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Face player
	if player.global_position.x < global_position.x:
		update_facing_direction("left")
	else:
		update_facing_direction("right")
		
	#movement
	if dying or distance_to_player <= stop_distance: #if its not dying, move
		velocity.x = 0
		is_walking = false
	elif in_knockback_state:
		pass
	else:
		move_toward_player(delta)
		is_walking = true
	
	#attack if close enough
	if distance_to_player <= stop_distance and not dying and not damaged and not in_knockback_state:
		time_in_attack_range += delta
		if time_in_attack_range >= 0.1:
			attempt_attack()
	else :
		time_in_attack_range = 0.0

	move_and_slide()
	
func take_spear_damage(globalPosPlayer):
	damaged = true
	var damage = 4
	#Knockback + particles
	receive_knockback(globalPosPlayer, damage)
	hitParticles(globalPosPlayer)
	#damage output
	health -= damage
	print("Enemy took Heavy damage, HP =", health)
	
	#die if health is below 0
	deathIfBelow0()
	await get_tree().create_timer(0.2).timeout 
	damaged = false
		
func take_punch_damage(globalPosPlayer):
	damaged = true
	var damage = 1
	#Knockback + particles + cameraShake
	receive_knockback(globalPosPlayer, damage)
	hitParticles(globalPosPlayer)
	#damage output
	health -= damage
	print("Enemy took Light damage, HP =", health)
	
	#die if health is below 0
	deathIfBelow0()
	await get_tree().create_timer(0.2).timeout 
	damaged = false
	
func take_dismantle_damage():
	health -= 20
	print("Enemy took Light damage, HP =", health)
	#die if health is below 0
	deathIfBelow0()
		
func deathIfBelow0():
	if health <= 0:
		dying = true
		var body = CollisionShape.get_parent()
		# Turn OFF all collision alayers so we can pass through him
		body.set_collision_layer_value(2, false)
		await get_tree().create_timer(1.4).timeout
		queue_free()
	
	
func move_toward_player(delta):
	var direction = (player.global_position - global_position).normalized()
	velocity.x = direction.x * speed

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

func attempt_attack():
	if can_attack:
		can_attack = false
		attack()
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true

func attack():
	print("Enemy attacks!")  # replace this later with animation or damage
	is_attacking = true
	await get_tree().create_timer(0.3).timeout
	TongueCollisionShape.disabled = false
	await get_tree().create_timer(0.2).timeout
	TongueCollisionShape.disabled = true
	is_attacking = false
	
func hitParticles(player_pos: Vector2):
	var dir = (player_pos - global_position).normalized()  # enemy → player
	dir.y = 0 #this enemy is always on the ground so i dont want the player's height to affect where the particles come out fromaa
	$HitParticles.rotation = dir.angle()
	$HitParticles.emitting = true
	$HitParticles.restart()


func update_facing_direction(facing):
	if facing == "left" :
		sprite.flip_h = true
		CollisionShape.position.x = CollisionShapeFacingLeft
		HurtBoxCollisionShape.position.x = HurtBoxCollisionShapeFacingLeft
		TongueCollisionShape.position.x = TongueCollisionShapeFacingLeft
		HitParticles.position.x = HitParticlesFacingLeft
	else :
		sprite.flip_h = false
		CollisionShape.position.x = CollisionShapeFacingRight
		HurtBoxCollisionShape.position.x = HurtBoxCollisionShapeFacingRight
		TongueCollisionShape.position.x = TongueCollisionShapeFacingRight
		HitParticles.position.x = HitParticlesFacingRight
	
func update_animation_parameters():
	#if damaged is priority
	if dying :
		anim_tree["parameters/conditions/died"] = true
		anim_tree["parameters/conditions/damaged"] = false
		anim_tree["parameters/conditions/idle"] = false
		anim_tree["parameters/conditions/is_walking"] = false
		anim_tree["parameters/conditions/is_attacking"] = false
	elif damaged :
		anim_tree["parameters/conditions/damaged"] = true
		anim_tree["parameters/conditions/idle"] = false
		anim_tree["parameters/conditions/is_walking"] = false
		anim_tree["parameters/conditions/is_attacking"] = false
	elif is_attacking:
		anim_tree["parameters/conditions/is_attacking"] = true
		anim_tree["parameters/conditions/died"] = false
		anim_tree["parameters/conditions/damaged"] = false
		anim_tree["parameters/conditions/idle"] = false
		anim_tree["parameters/conditions/is_walking"] = false
	else :
		anim_tree["parameters/conditions/damaged"] = false
		anim_tree["parameters/conditions/is_attacking"] = false
		if not is_walking:
			anim_tree["parameters/conditions/idle"] = true
			anim_tree["parameters/conditions/is_walking"] = false
		else:
			anim_tree["parameters/conditions/idle"] = false
			anim_tree["parameters/conditions/is_walking"] = true


func _on_tongue_area_entered(area: Area2D) -> void:
		if area.is_in_group("player_hurtbox"):
			area.take_tongue_damage(global_position) #pass global position for knockback direction
