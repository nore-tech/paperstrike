class_name RangeTargetManager
extends Node

## Remembers each firing-range dummy and restores it without reloading the level.

var _slots: Array[Dictionary] = []

func _ready() -> void:
	add_to_group("range_target_manager")
	_register_existing()

func reset_all() -> void:
	_register_existing()
	for slot in _slots:
		var current: Variant = slot.get("node")
		if is_instance_valid(current):
			var dummy := current as TargetDummy
			dummy.global_transform = slot.transform
			dummy.restore()
			continue
		var packed: PackedScene = slot.packed
		if packed == null:
			continue
		var parent: Variant = slot.get("parent")
		if not is_instance_valid(parent):
			continue
		var fresh := packed.instantiate()
		(parent as Node).add_child(fresh)
		fresh.global_transform = slot.transform
		slot.node = fresh

func _register_existing() -> void:
	for node in get_tree().get_nodes_in_group("range_target"):
		if node is TargetDummy and not _has_slot(node):
			_remember(node)

func _has_slot(dummy: TargetDummy) -> bool:
	for slot in _slots:
		var current: Variant = slot.get("node")
		if is_instance_valid(current) and current == dummy:
			return true
	return false

func _remember(dummy: TargetDummy) -> void:
	var packed: PackedScene = null
	if dummy.scene_file_path != "":
		packed = load(dummy.scene_file_path)
	_slots.append({
		"parent": dummy.get_parent(),
		"transform": dummy.global_transform,
		"packed": packed,
		"node": dummy,
	})
