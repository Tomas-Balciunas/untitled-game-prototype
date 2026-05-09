@abstract
extends RefCounted

class_name Entity


@abstract
func can_be_damaged() -> bool

@abstract
func can_be_healed() -> bool

@abstract
func can_receive_effects() -> bool
