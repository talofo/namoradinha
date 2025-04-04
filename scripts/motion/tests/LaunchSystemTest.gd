extends Node2D

# References to UI elements
@onready var test_object = $TestObject
@onready var angle_slider = $UI/Panel/VBoxContainer/AngleSlider
@onready var angle_label = $UI/Panel/VBoxContainer/AngleLabel
@onready var power_slider = $UI/Panel/VBoxContainer/PowerSlider
@onready var power_label = $UI/Panel/VBoxContainer/PowerLabel
@onready var launch_button = $UI/Panel/VBoxContainer/LaunchButton
@onready var reset_button = $UI/Panel/VBoxContainer/ResetButton
@onready var status_label = $UI/Panel/VBoxContainer/StatusLabel

# Motion system and launch system
var motion_system = null
var launch_system = null

# Test object properties
var test_object_id = 0
var initial_position = Vector2(100, 500)
var has_launched = false

# Trajectory visualization
var trajectory_points = []
var draw_trajectory = true

func _ready():
	# Connect UI signals
	angle_slider.value_changed.connect(_on_angle_slider_changed)
	power_slider.value_changed.connect(_on_power_slider_changed)
	launch_button.pressed.connect(_on_launch_button_pressed)
	reset_button.pressed.connect(_on_reset_button_pressed)
	
	# Initialize motion system
	_initialize_motion_system()
	
	# Register test object
	test_object_id = test_object.get_instance_id()
	if launch_system:
		launch_system.register_entity(test_object_id)
		
		# Set initial launch parameters
		launch_system.set_launch_parameters(
			test_object_id,
			angle_slider.value,
			power_slider.value / 100.0
		)
		
		# Update trajectory preview
		_update_trajectory_preview()
	
	# Update UI
	_update_ui()

func _initialize_motion_system():
	# Create motion system
	motion_system = load("res://scripts/motion/MotionSystem.gd").new()
	add_child(motion_system)
	
	# Create and register launch system
	launch_system = load("res://scripts/motion/subsystems/LaunchSystem.gd").new()
	
	# Set the motion system reference in the launch system
	launch_system._motion_system = motion_system
	
	if motion_system.register_subsystem(launch_system):
		print("LaunchSystem registered successfully")
	else:
		push_error("Failed to register LaunchSystem")

func _physics_process(delta):
	if has_launched:
		# Apply gravity
		test_object.velocity.y += 1200 * delta
		
		# Move the test object
		test_object.move_and_slide()
		
		# Check if on floor
		if test_object.is_on_floor():
			test_object.velocity.x *= 0.98  # Simple friction
			
			# Stop if velocity is very low
			if abs(test_object.velocity.x) < 10:
				test_object.velocity = Vector2.ZERO
				has_launched = false
				status_label.text = "Stopped"

func _draw():
	# Draw trajectory preview
	if draw_trajectory and not has_launched:
		for i in range(trajectory_points.size() - 1):
			draw_line(
				trajectory_points[i] + initial_position,
				trajectory_points[i + 1] + initial_position,
				Color(1, 1, 0, 0.5),
				2
			)

func _on_angle_slider_changed(value):
	if launch_system:
		launch_system.set_launch_parameters(
			test_object_id,
			value,
			power_slider.value / 100.0
		)
		_update_trajectory_preview()
	
	angle_label.text = "Angle: %d°" % value
	queue_redraw()

func _on_power_slider_changed(value):
	if launch_system:
		launch_system.set_launch_parameters(
			test_object_id,
			angle_slider.value,
			value / 100.0
		)
		_update_trajectory_preview()
	
	power_label.text = "Power: %d%%" % value
	queue_redraw()

func _on_launch_button_pressed():
	if launch_system and not has_launched:
		# Launch the test object
		var launch_vector = launch_system.launch_entity(test_object_id)
		test_object.velocity = launch_vector
		has_launched = true
		status_label.text = "Launched"
		
		# Hide trajectory while in motion
		draw_trajectory = false
		queue_redraw()

func _on_reset_button_pressed():
	# Reset test object
	test_object.position = initial_position
	test_object.velocity = Vector2.ZERO
	has_launched = false
	status_label.text = "Reset"
	
	# Show trajectory again
	draw_trajectory = true
	queue_redraw()

func _update_trajectory_preview():
	if launch_system:
		trajectory_points = launch_system.get_preview_trajectory(test_object_id)
		queue_redraw()

func _update_ui():
	angle_label.text = "Angle: %d°" % angle_slider.value
	power_label.text = "Power: %d%%" % power_slider.value
