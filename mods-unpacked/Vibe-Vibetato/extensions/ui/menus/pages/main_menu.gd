extends "res://ui/menus/pages/main_menu.gd"

const Core = preload("res://mods-unpacked/Vibe-Vibetato/src/vibetato_core.gd")
const LOG_NAME := "Vibe-Vibetato:MainMenu"
const PANEL_NAME := "VibeVibetatoPanel"

var _vt_panel = null
var _vt_preset_opt = null
var _vt_ban_opt = null
var _vt_code_edit = null
var _vt_speed_opt = null
var _vt_enabled_cb = null
var _vt_status = null
var _vt_updating := false


func init() -> void:
	.init()
	Core.apply_preset_to_debug_service()
	Core.apply_boss_waves_from_preset()
	_vibetato_build_panel()
	_vibetato_refresh()


func _vibetato_build_panel() -> void:
	if has_node(PANEL_NAME):
		return

	var panel := PanelContainer.new()
	panel.name = PANEL_NAME
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.09, 0.11, 0.92)
	sb.border_color = Color(0.45, 0.45, 0.5, 1.0)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	panel.add_stylebox_override("panel", sb)
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.margin_left = -300
	panel.margin_top = 16
	panel.margin_right = -16
	panel.rect_min_size = Vector2(284, 0)
	panel.rect_size = Vector2(284, 10)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Vibetato"
	vbox.add_child(title)

	_vt_preset_opt = _vibetato_row(vbox, "Preset:", OptionButton.new())
	_vt_preset_opt.connect("item_selected", self, "_vibetato_preset_selected")

	_vt_ban_opt = _vibetato_row(vbox, "Ban:", OptionButton.new())
	_vt_ban_opt.connect("item_selected", self, "_vibetato_ban_selected")

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
	apply_btn.connect("pressed", self, "_vibetato_apply_code")
	code_row.add_child(apply_btn)

	var copy_btn := Button.new()
	copy_btn.text = "Copy run code of active preset"
	copy_btn.connect("pressed", self, "_vibetato_copy_code")
	vbox.add_child(copy_btn)

	_vt_speed_opt = _vibetato_row(vbox, "Speed:", OptionButton.new())
	_vt_speed_opt.connect("item_selected", self, "_vibetato_speed_selected")

	_vt_enabled_cb = CheckBox.new()
	_vt_enabled_cb.text = "Enabled"
	_vt_enabled_cb.connect("toggled", self, "_vibetato_enabled_toggled")
	vbox.add_child(_vt_enabled_cb)

	_vt_status = Label.new()
	_vt_status.autowrap = true
	vbox.add_child(_vt_status)

	add_child(panel)
	_vt_panel = panel
	call_deferred("_vibetato_fit_panel")


func _vibetato_row(parent: Control, label_text: String, control: Control) -> Control:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.rect_min_size = Vector2(70, 0)
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return control


func _vibetato_fit_panel() -> void:
	if _vt_panel == null:
		return
	var h := _vt_panel.get_combined_minimum_size().y + 4
	if h < 40:
		h = 40
	_vt_panel.rect_size = Vector2(284, h)


func _vibetato_refresh() -> void:
	if _vt_panel == null:
		return
	_vt_updating = true

	_vt_preset_opt.clear()
	_vt_preset_opt.add_item("(none)")
	var names := Core.list_preset_names()
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
	var ban_names := []
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
	var steps := Core.speed_steps()
	var cur_speed := Engine.time_scale
	var ssel := 0
	for i in steps.size():
		_vt_speed_opt.add_item("x%s" % str(steps[i]))
		if abs(float(steps[i]) - cur_speed) < 0.001:
			ssel = i
	_vt_speed_opt.select(ssel)

	_vt_enabled_cb.pressed = Core.is_enabled()

	var preset := Core.get_preset()
	if preset.empty():
		_vt_status.text = "No active preset (vanilla). Speed x%s." % str(cur_speed)
	else:
		_vt_status.text = "Preset: %s | speed x%s\nRun code: %s" % [String(preset.get("name", "")), str(cur_speed), Core.encode_run_code(preset)]

	_vt_updating = false


func _vibetato_preset_selected(index: int) -> void:
	if _vt_updating:
		return
	var name := ""
	if index > 0 and index < _vt_preset_opt.get_item_count():
		name = _vt_preset_opt.get_item_text(index)
	if name == "":
		Core.clear_preset()
	else:
		Core.apply_preset_by_name(name)
	_vibetato_refresh()


func _vibetato_ban_selected(index: int) -> void:
	if _vt_updating:
		return
	var preset_name := Core.active_preset_name()
	if preset_name == "" or preset_name == "run_code":
		ModLoaderLog.warning("Select a named preset before choosing a ban preset.", LOG_NAME)
		_vibetato_refresh()
		return
	var bp := ""
	if index > 0 and index < _vt_ban_opt.get_item_count():
		bp = _vt_ban_opt.get_item_text(index)
	Core.set_preset_field(preset_name, "ban_preset", bp)
	ModLoaderLog.info("Ban preset '%s' set on preset '%s'." % [bp, preset_name], LOG_NAME)
	_vibetato_refresh()


func _vibetato_apply_code() -> void:
	if _vt_updating:
		return
	Core.apply_run_code(_vt_code_edit.text)
	_vibetato_refresh()


func _vibetato_copy_code() -> void:
	var preset := Core.get_preset()
	if preset.empty():
		ModLoaderLog.info("No active preset to share.", LOG_NAME)
	else:
		var code := Core.encode_run_code(preset)
		OS.set_clipboard(code)
		ModLoaderLog.info("Run code copied to clipboard: %s" % code, LOG_NAME)
	_vibetato_refresh()


func _vibetato_speed_selected(index: int) -> void:
	if _vt_updating:
		return
	var steps := Core.speed_steps()
	if index >= 0 and index < steps.size():
		Core.set_speed(float(steps[index]))
	_vibetato_refresh()


func _vibetato_enabled_toggled(button_pressed: bool) -> void:
	if _vt_updating:
		return
	Core.set_enabled(button_pressed)
	_vibetato_refresh()
