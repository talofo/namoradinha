class_name BoostEffect
extends Node2D

# Visual properties
var particles: CPUParticles2D
var trail_length: int = 10
var trail_points: Array = []

# Effect configurations for different boost types
const EFFECT_CONFIGS = {
	"manual_air": {
		"color": Color(0.9, 0.6, 0.1, 0.8),  # Orange-yellow
		"amount": 20,
		"lifetime": 0.5,
		"velocity_min": 50,
		"velocity_max": 100,
		"scale": 3,
		"message": "Manual Air Boost!"
	},
	"environmental": {  # For future use
		"color": Color(0.2, 0.8, 0.3, 0.8),  # Green
		"amount": 30,
		"lifetime": 0.7,
		"velocity_min": 70,
		"velocity_max": 120,
		"scale": 3.5,
		"message": "Environmental Boost!"
	},
	"mega": {  # For future use
		"color": Color(0.8, 0.2, 0.9, 0.8),  # Purple
		"amount": 40,
		"lifetime": 1.0,
		"velocity_min": 100,
		"velocity_max": 200,
		"scale": 4,
		"message": "MEGA BOOST!"
	}
}

func _init() -> void:
	# Create particles for the boost effect
	particles = CPUParticles2D.new()
	particles.emitting = false
	particles.explosiveness = 0.7
	particles.direction = Vector2(0, 0)
	particles.spread = 180
	particles.gravity = Vector2(0, 0)
	
	# Set default configuration (will be overridden by configure_for_boost_type)
	configure_for_boost_type("manual_air")
	
	add_child(particles)

func _ready() -> void:
	# Initialize with invisible state
	modulate.a = 0.0

# Configure the effect based on boost type
func configure_for_boost_type(boost_type: String) -> void:
	var config = EFFECT_CONFIGS.get(boost_type, EFFECT_CONFIGS["manual_air"])
	
	particles.color = config["color"]
	particles.amount = config["amount"]
	particles.lifetime = config["lifetime"]
	particles.initial_velocity_min = config["velocity_min"]
	particles.initial_velocity_max = config["velocity_max"]
	particles.scale_amount_min = config["scale"]
	particles.scale_amount_max = config["scale"]

# Show the boost effect in the specified direction with the specified type
func show_effect(direction: Vector2, boost_type: String = "manual_air") -> void:
	# Set current boost type for drawing
	current_boost_type = boost_type
	
	# Configure effect based on boost type
	configure_for_boost_type(boost_type)
	
	# Reset state
	modulate.a = 1.0
	
	# Set particle direction opposite to boost direction
	particles.direction = -direction.normalized()
	
	# Start particle emission
	particles.restart()
	particles.emitting = true
	
	# Create a trail effect
	trail_points.clear()
	for i in range(trail_length):
		trail_points.append(Vector2.ZERO)
	
	# Create a tween to fade out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): particles.emitting = false)
	
	# Show message (in a real implementation, this would display on the UI)
	var message = EFFECT_CONFIGS.get(boost_type, EFFECT_CONFIGS["manual_air"])["message"]
	print("Boost message: " + message)

func _process(_delta: float) -> void:
	# Only update when visible
	if modulate.a <= 0.0:
		return
	
	# Update trail points
	if trail_points.size() > 0:
		trail_points.pop_back()
		trail_points.push_front(Vector2.ZERO)
	
	# Force redraw
	queue_redraw()

# Current boost type being displayed
var current_boost_type: String = "manual_air"

func _draw() -> void:
	# Draw trail
	if trail_points.size() < 2 or modulate.a <= 0.0:
		return
	
	# Get color from current boost type configuration
	var config = EFFECT_CONFIGS.get(current_boost_type, EFFECT_CONFIGS["manual_air"])
	var color = config["color"]
	color.a = color.a * modulate.a
	
	for i in range(trail_points.size() - 1):
		var alpha = 1.0 - float(i) / trail_points.size()
		var line_color = color
		line_color.a = alpha * modulate.a
		var width = 3.0 * (1.0 - float(i) / trail_points.size())
		draw_line(trail_points[i], trail_points[i+1], line_color, width)
