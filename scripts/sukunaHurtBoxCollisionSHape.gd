extends CollisionShape2D

func _ready():
	$"..".add_to_group("player_hurtbox")
