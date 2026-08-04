extends Control

signal transition_finished

const TRANSITION_DURATION := 0.48

@onready var transition_label: Label = %TransitionLabel
@onready var input_sink: Button = %TransitionInputSink

var active := false
var elapsed := 0.0
var last_label := ""
var last_reduced_motion := false


func _ready() -> void:
	hide()
	set_process(false)


func play(label_text: String, reduced_motion: bool) -> void:
	if label_text.strip_edges().is_empty():
		return
	last_label = label_text
	last_reduced_motion = reduced_motion
	transition_label.text = label_text
	elapsed = 0.0
	if reduced_motion:
		active = false
		modulate.a = 0.0
		hide()
		set_process(false)
		return
	active = true
	modulate.a = 1.0
	show()
	set_process(true)
	_grab_transition_focus.call_deferred()


func _grab_transition_focus() -> void:
	if active and visible:
		input_sink.grab_focus()


func _process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	if not active:
		return
	elapsed = minf(elapsed + maxf(delta, 0.0), TRANSITION_DURATION)
	var progress := elapsed / TRANSITION_DURATION
	modulate.a = 1.0 - smoothstep(0.14, 1.0, progress)
	if elapsed >= TRANSITION_DURATION:
		finish()


func finish() -> void:
	if not active:
		return
	active = false
	elapsed = TRANSITION_DURATION
	modulate.a = 0.0
	hide()
	set_process(false)
	transition_finished.emit()


func is_transitioning() -> bool:
	return active


func transition_contract() -> Dictionary:
	return {
		"active": active,
		"label": last_label,
		"duration": TRANSITION_DURATION,
		"elapsed": elapsed,
		"alpha": modulate.a,
		"reduced_motion": last_reduced_motion,
		"blocks_input": active and visible and mouse_filter == Control.MOUSE_FILTER_STOP,
		"z_index": z_index,
	}
