extends CharacterBody2D
#position
var pos:Vector2
#rotation
var rota: float
#direction
var dir: float
#speed
var speed = 150

func _ready():
	global_position=pos
	global_rotation=rota
	# Calculate angle
	var angle_deg = rad_to_deg(dir)  # convert radians to degrees
	if angle_deg > 90 or angle_deg < -90:
		$AnimatedSprite2D.flip_v = true
	else:
		$AnimatedSprite2D.flip_v = false

func _physics_process(delta):
	velocity=Vector2(speed, 0).rotated(dir)
	move_and_slide()
