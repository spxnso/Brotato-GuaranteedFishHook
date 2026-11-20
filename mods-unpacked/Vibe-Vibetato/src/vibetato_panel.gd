extends PanelContainer

const Core = preload("res://mods-unpacked/Vibe-Vibetato/src/vibetato_core.gd")
const LOG_NAME := "Vibe-Vibetato:Panel"

var _vt_preset_opt = null
var _vt_ban_opt = null
var _vt_code_edit = null
var _vt_speed_opt = null
var _vt_enabled_cb = null
var _vt_status = null
var _vt_updating := false


func _ready() -> void:
	name = "VibeVibetatoPanel"

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.09, 0.11, 0.92)
	sb.border_color = Color(0.45, 0.45, 0.5, 1.0)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	add_stylebox_override("panel", sb)

	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	margin_left = -300
	margin_top = 16
	margin_right = -16
	rect_min_size = Vector2(284, 0)
	rect_size = Vector2(284, 10)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(vbox)

	var title := Label.new()
	title.text = "Vibetato"
	vbox.add_child(title)

	_vt_preset_opt = _row(vbox, "Preset:", OptionButton.new())
	_vt_preset_opt.connect("item_selected", self, "_preset_selected")

	_vt_ban_opt = _row(vbox, "Ban:", OptionButton.new())
	_vt_ban_opt.connect("item_selected", self, "_ban_selected")

	var code_row := HBoxContainer.new()
	vbox.add_child(code_row)
	var code_label := Label.new()
	code_label.text = "Code:"
	code_label.rect_min_size = Vector2(70, 0)
	code_row.add_child(code_label)
	_vt_code_edit = LineEdit.new()
	_vt_code_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vt_code_edit.placeholder_text = "VBT1.…"
	code_row.add_child(_vt_code_edit)
	var apply_btn := Button.new()
	apply_btn.text = "Apply"
	apply_btn.connect("pressed", self, "_apply_code")
	code_row.add_child(apply_btn)

	var btn_row := HBoxContainer.new()
	vbox.add_child(btn_row)
	var copy_btn := Button.new()
	copy_btn.text = "Copy run code"
	copy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy_btn.connect("pressed", self, "_copy_code")
	btn_row.add_child(copy_btn)
	var refresh_btn := Button.new()
	refresh_btn.text = "Refresh"
	refresh_btn.connect("pressed", self, "_refresh_pressed")
	btn_row.add_child(refresh_btn)

	_vt_speed_opt = _row(vbox, "Speed:", OptionButton.new())
	_vt_speed_opt.connect("item_selected", self, "_speed_selected")

	_vt_enabled_cb = CheckBox.new()
	_vt_enabled_cb.text = "Enabled"
	_vt_enabled_cb.connect("toggled", self, "_enabled_toggled")
	vbox.add_child(_vt_enabled_cb)

	_vt_status = Label.new()
	_vt_status.autowrap = true
	vbox.add_child(_vt_status)

	_refresh()
	call_deferred("_fit")


func _row(parent: Control, label_text: String, control: Control) -> Control:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.rect_min_size = Vector2(70, 0)
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return control


func _fit() -> void:
	var h = get_combined_minimum_size().y + 4
	if h < 40:
		h = 40
	rect_size = Vector2(284, h)


func _refresh() -> void:
	if _vt_preset_opt == null:
		return
	_vt_updating = true

	_vt_preset_opt.clear()
	_vt_preset_opt.add_item("(none)")
	var names: Array = Core.list_preset_names()
	for n in names:
		_vt_preset_opt.add_item(n)
	var active := Core.active_preset_name()
	var sel := 0
	for i in names.size():
		if names[i] == active:
			sel = i + 1
	_vt_preset_opt.select(sel)

	_vt_ban_opt.clear()
	_vt_ban_opt.add_item("(none)")
	var ban_presets: Dictionary = Core.get_presets_doc().get("ban_presets", {})
	var ban_names: Array = []
	for k in ban_presets:
		ban_names.push_back(String(k))
	ban_names.sort()
	for n in ban_names:
		_vt_ban_opt.add_item(n)
	var cur_ban: String = String(Core.get_preset().get("ban_preset", ""))
	var bsel := 0
	for i in ban_names.size():
		if ban_names[i] == cur_ban:
			bsel = i + 1
	_vt_ban_opt.select(bsel)

	_vt_speed_opt.clear()
	var steps: Array = Core.speed_steps()
	var cur_speed := Engine.time_scale
	var ssel := 0
	for i in steps.size():
		_vt_speed_opt.add_item("x%s" % str(steps[i]))
		if abs(float(steps[i]) - cur_speed) < 0.001:
			ssel = i
	_vt_speed_opt.select(ssel)

	_vt_enabled_cb.pressed = Core.is_enabled()

	var preset: Dictionary = Core.get_preset()
	if preset.empty():
		_vt_status.text = "No active preset (vanilla). Speed x%s." % str(cur_speed)
	else:
		_vt_status.text = "Preset: %s | speed x%s\nRun code: %s" % [String(preset.get("name", "")), str(cur_speed), Core.encode_run_code(preset)]

	_vt_updating = false
	call_deferred("_fit")


func _preset_selected(index: int) -> void:
	if _vt_updating:
		return
	var name := ""
	if index > 0 and index < _vt_preset_opt.get_item_count():
		name = _vt_preset_opt.get_item_text(index)
	if name == "":
		Core.clear_preset()
	else:
		Core.apply_preset_by_name(name)
	_refresh()


func _ban_selected(index: int) -> void:
	if _vt_updating:
		return
	var preset_name := Core.active_preset_name()
	if preset_name == "" or preset_name == "run_code":
		ModLoaderLog.warning("Select a named preset before choosing a ban preset.", LOG_NAME)
		_refresh()
		return
	var bp := ""
	if index > 0 and index < _vt_ban_opt.get_item_count():
		bp = _vt_ban_opt.get_item_text(index)
	Core.set_preset_field(preset_name, "ban_preset", bp)
	ModLoaderLog.info("Ban preset '%s' set on preset '%s'." % [bp, preset_name], LOG_NAME)
	_refresh()


func _apply_code() -> void:
	if _vt_updating:
		return
	Core.apply_run_code(_vt_code_edit.text)
	_refresh()


func _copy_code() -> void:
	var preset: Dictionary = Core.get_preset()
	if preset.empty():
		ModLoaderLog.info("No active preset to share.", LOG_NAME)
	else:
		var code := Core.encode_run_code(preset)
		OS.set_clipboard(code)
		ModLoaderLog.info("Run code copied to clipboard: %s" % code, LOG_NAME)
	_refresh()


func _refresh_pressed() -> void:
	if _vt_updating:
		return
	Core.reload_state()
	_refresh()


func _speed_selected(index: int) -> void:
	if _vt_updating:
		return
	var steps: Array = Core.speed_steps()
	if index >= 0 and index < steps.size():
		Core.set_speed(float(steps[index]))
	_refresh()


func _enabled_toggled(button_pressed: bool) -> void:
	if _vt_updating:
		return
	Core.set_enabled(button_pressed)
	_refresh()
