extends CharacterBody2D

#position
var pos:Vector2
#rotation
var rota: float
#direction
var dir: float
#speed
var speed = 150

var start_pos: Vector2
var max_distance := 170.0

func _ready():
	global_position=pos
	global_rotation=rota
	start_pos = global_position
	# Calculate angle
	var angle_deg = rad_to_deg(dir)  # convert radians to degrees
	if angle_deg > 90 or angle_deg < -90:
		$AnimatedSprite2D.flip_v = true
	else:
		$AnimatedSprite2D.flip_v = false

func _physics_process(delta):
	velocity=Vector2(speed, 0).rotated(dir)
	move_and_slide()
	
	# Check distance traveled
	if global_position.distance_to(start_pos) >= max_distance:
		queue_free() # delete this node


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("hurtbox"):
		area.take_dismantle_damage()
