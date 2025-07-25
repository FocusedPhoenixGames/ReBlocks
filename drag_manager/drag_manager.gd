@tool
extends Control

signal block_dropped
signal block_modified

const BlockCanvas = preload("res://addons/reblocks/ui/block_canvas/block_canvas.gd")
const BlockTreeUtil = preload("res://addons/reblocks/ui/block_tree_util.gd")
const Drag = preload("res://addons/reblocks/drag_manager/drag.gd")
const Picker = preload("res://addons/reblocks/ui/picker/picker.gd")
const Util = preload("res://addons/reblocks/ui/util.gd")

@export var picker_path: NodePath
@export var block_canvas_path: NodePath

const Constants = preload("res://addons/reblocks/ui/constants.gd")

@onready var _context := BlockEditorContext.get_default()

var _picker: Picker
var _block_canvas: BlockCanvas

var drag: Drag = null


func _ready():
	if picker_path:
		_picker = get_node(picker_path)
	_block_canvas = get_node(block_canvas_path)


func _process(_delta):
	if drag:
		drag.update_drag_state()


func drag_block(block: Block, copied_from: Block = null, offset: Vector2 = Vector2.ZERO):
	if copied_from and copied_from.is_inside_tree():
		offset += get_global_mouse_position() - copied_from.global_position
	elif block.is_inside_tree():
		offset += get_global_mouse_position() - block.global_position

	if _block_canvas.is_ancestor_of(block):
		offset /= _block_canvas.zoom

	var parent = block.get_parent()

	if parent:
		parent.remove_child(block)

	block.disconnect_signals()

	var block_scope := BlockTreeUtil.get_tree_scope(block)
	if block_scope != "":
		_block_canvas.set_scope(block_scope)

	drag = Drag.new(block, block_scope, offset, _block_canvas)
	drag.set_snap_points(get_tree().get_nodes_in_group("snap_point"))
	if _picker:
		drag.add_delete_area(_picker.get_global_rect())
	if block is ParameterBlock and block.spawned_by:
		drag.add_delete_area(block.spawned_by.get_global_rect())
	add_child(drag)


func copy_block(block: Block) -> Block:
	if _context.block_script == null:
		return null
	return _context.block_script.instantiate_block(block.definition)


func copy_picked_block_and_drag(block: Block, offset: Vector2):
	var new_block: Block = copy_block(block)
	drag_block(new_block, block, offset)


func drag_ended():
	if not drag:
		return

	var block = drag.apply_drag()

	if block:
		connect_block_canvas_signals(block)
		block.grab_focus()

		# Allow the block to be deleted and edited now that it's on the canvas.
		block.can_delete = true
		block.editable = true

	_block_canvas.release_scope()

	drag.queue_free()
	drag = null

	block_dropped.emit()


func connect_block_canvas_signals(block: Block):
	if block.drag_started.get_connections().size() == 0:
		block.drag_started.connect(_on_block_drag_started)
	if block.modified.get_connections().size() == 0:
		block.modified.connect(func(): block_modified.emit())


func _on_block_drag_started(block: Block, offset: Vector2):
	drag_block(block, null, offset)
