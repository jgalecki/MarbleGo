extends RigidBody2D
class_name Marble

var bounce_particles_prefab = preload("res://prefab_scenes/bounce_particles.tscn")
var bounce_particles_smaller_prefab = preload("res://prefab_scenes/bounce_particles_smaller.tscn")
var stabalize_particles_prefab = preload("res://prefab_scenes/stabalize_particles.tscn")
var atair_particles_prefab = preload("res://prefab_scenes/atari_particles.tscn")
@onready var unstable_particles = $"Unstable Particles"



@export var sprite:Sprite2D
@export var collider:CollisionShape2D
@export var shadow:Sprite2D
@onready var trail_2d = $Trail2D

@onready var animation_player = $AnimationPlayer
@export var min_speed_for_major_collision:float
@export var min_speed_for_minor_collision:float
var spawned_particles_this_turn:bool
var is_shooting:bool

@export var player:int
var placed_index:int
var border_marble:bool

var is_move_manually
var move_manually_to

var stable:bool
var turns_until_stable:int
var STABILITY_TURNS:int = 8

var hitstop_frames:int = 0

var nearest_marbles:Array[Marble] = []

# For screen shake
var camera:Camera

signal on_collision(marble : Marble, is_big : bool)

func init(placing_player:int, placed_position:Vector2, index:int):
	$"/root/Lobby".print("marble.init(), index " + str(index) + " at " + str(placed_position))			
	sprite.modulate = Color(0.06, 0.06, 0.12) if placing_player == 0 else Color(0.984, 0.961, 0.937)
	player = placing_player
	position = placed_position
	placed_index = index
	stable = false
	turns_until_stable = STABILITY_TURNS
	nearest_marbles = []
	
func _integrate_forces(state):
	if is_move_manually:
		is_move_manually = false
		state.transform = Transform2D(0, move_manually_to)	

func move_manually(move_to:Vector2):
	move_manually_to = move_to
	is_move_manually = true

func update_after_turn():
	# handle captures prior to this function call.
	if stable:
		return
		
	if linear_velocity.length() > 0:
		sprite.scale = Vector2(0.25, 0.25)
	
	unstable_particles.restart()
	unstable_particles.emitting = true 
	unstable_particles.visible = true 
		
		
	turns_until_stable -= 1
	if turns_until_stable <= 0:
		stable = true
		spawn_stabalize_particles()
		unstable_particles.visible = false
		unstable_particles.emitting = false
		self.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
		self.freeze = true
		shadow.visible = false
	else:
		var nearest_opponent_count = nearest_marbles.filter(func(m): return m != null && m.player != player).size()
		if player == 0:
			unstable_particles.modulate = Color(0.06, 0.06, 0.12)
		else:
			unstable_particles.modulate = Color(0.984, 0.961, 0.937)
			
		if nearest_marbles.size() == 4 && nearest_opponent_count >= 3:
			shadow.modulate = Color(0.776, 0.623, 0.647, 1)
			var particles:GPUParticles2D = atair_particles_prefab.instantiate()
			get_tree().current_scene.add_child(particles)
			particles.position = position
		else:
			shadow.modulate = Color(1, 1, 1, 0.25)
			
func _process(delta):
	if linear_velocity.length() > 0 && not animation_player.is_playing():
		var speed_value = lerpf(0.25, 0.4, linear_velocity.length() / 500)
		var obverse_value = lerpf(0.25, 0.15, (speed_value - 0.25) / 0.15)
		sprite.scale = Vector2(speed_value, obverse_value)
		sprite.rotation = self.linear_velocity.angle()
	if (sleeping || freeze || linear_velocity.length() < 10) \
		&& (animation_player == null || not animation_player.is_playing()):
		sprite.scale = Vector2(0.25, 0.25)
		
	if unstable_particles != null:
		var moving = linear_velocity.length() > 1 && not sleeping
#		unstable_particles.emitting = not moving
		if moving:
			unstable_particles.visible = false
		
		
func _physics_process(delta):
#	if hitstop_frames > 0:
#		hitstop_frames -= 1
#		if hitstop_frames <= 0:
#			stop_hitstop()
#		return
	
	if border_marble || sleeping:
		return
		
	var collision = move_and_collide(get_linear_velocity() * delta, true, 0.08, true)
	if not collision:
		return
		
	var normal = collision.get_normal()
	sprite.rotation = normal.angle()
	
	if get_linear_velocity().length() < min_speed_for_minor_collision:
		spawn_bounce_particles(position, normal, false)
		on_collision.emit(self, false)
	elif get_linear_velocity().length() < min_speed_for_major_collision:
		spawn_bounce_particles(position, normal, false)		
		if collision.get_collider().is_in_group("marble"):
			hit_lag(0.8, 1)
			camera.shake(150, 1)
			on_collision.emit(self, true)
		else:
			on_collision.emit(self, false)
	else:
		animation_player.play("marble_bounce")
		spawn_bounce_particles(position, normal, true)
		on_collision.emit(self, true)
		if collision.get_collider().is_in_group("marble"):
			# hit stop
			hit_lag(0.6, 2)
			camera.shake(1000, 2)
		
#		collision.get_collider().start_hitstop(32)
	
func spawn_bounce_particles(pos:Vector2, normal:Vector2, larger:bool):
	if spawned_particles_this_turn:
		return
	spawned_particles_this_turn = true
	
	var particles:GPUParticles2D
	if larger:
		particles = bounce_particles_prefab.instantiate()
	else:
		particles = bounce_particles_smaller_prefab.instantiate()
		
	get_tree().current_scene.add_child(particles)
	particles.position = pos
	particles.rotation = normal.angle()

func spawn_stabalize_particles():
	var particles:GPUParticles2D = stabalize_particles_prefab.instantiate()
	get_tree().current_scene.add_child(particles)
	if player == 0:
		particles.modulate = Color(0.06, 0.06, 0.12)
	else:
		particles.modulate = Color(0.984, 0.961, 0.937)
	particles.position = position

func hit_lag(t_scale, duration):
	if Engine.time_scale < t_scale:
		return
	Engine.time_scale = t_scale
	await get_tree().create_timer(t_scale * duration).timeout
	Engine.time_scale = 1
#
#func start_hitstop(frames:int):
#	animation_player.pause()
#	hitstop_frames = frames
#
#func stop_hitstop():
#	animation_player.play()
	
