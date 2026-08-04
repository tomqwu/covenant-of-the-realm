extends SceneTree


func _initialize() -> void:
	var user_args := OS.get_cmdline_user_args()
	if user_args.size() != 1:
		push_error("package content probe requires exactly one manifest path")
		quit(1)
		return
	var manifest_file := FileAccess.open(user_args[0], FileAccess.READ)
	if manifest_file == null:
		push_error("package content probe cannot open manifest")
		quit(1)
		return
	var parser := JSON.new()
	if parser.parse(manifest_file.get_as_text()) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		push_error("package content probe received invalid manifest JSON")
		quit(1)
		return
	var manifest: Dictionary = parser.data
	var required: Array = manifest.get("required_resources", [])
	var excluded: Array = manifest.get("excluded_resources", [])
	if required.is_empty() or excluded.is_empty():
		push_error("package content probe requires non-empty resource contracts")
		quit(1)
		return
	for path in required:
		if typeof(path) != TYPE_STRING or not ResourceLoader.exists(path):
			push_error("required packaged resource is missing: %s" % path)
			quit(1)
			return
	for path in excluded:
		if typeof(path) != TYPE_STRING or ResourceLoader.exists(path):
			push_error("development-only resource leaked into package: %s" % path)
			quit(1)
			return
	print(
		"RPG package contents passed: %d required resources present, %d development resources absent."
		% [required.size(), excluded.size()]
	)
	quit(0)
