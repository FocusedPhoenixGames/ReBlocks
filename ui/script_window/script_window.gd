@tool
extends Window

@onready var script_label: CodeEdit = $"PanelContainer/VBox/Code"

var script_content: String = ""


## Attempts to match the syntax highlighting for some open script in the
## editor, which is more likely to be appropriate for the editor theme
## than our hardcoded default
func _apply_editor_syntax_highlighter() -> void:
	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	for x in script_editor.get_open_script_editors():
		var control: Control = x.get_base_editor()
		if control is TextEdit:
			script_label.syntax_highlighter = control.syntax_highlighter
			break


## Undoes the effect of the CodeEdit being read-only
func _remove_font_color_alpha_clamp() -> void:
	var font_readonly_color = script_label.get_theme_color("font_readonly_color")
	font_readonly_color.a = 1
	script_label.add_theme_color_override("font_readonly_color", font_readonly_color)


func update_script(script: String) -> void:
	_apply_editor_syntax_highlighter()
	_remove_font_color_alpha_clamp()
	script_content = script
	script_label.text = script_content.replace("\t", "    ")


func _on_copy_code_pressed() -> void:
	DisplayServer.clipboard_set(script_content)
