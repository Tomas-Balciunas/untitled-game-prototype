extends Node

enum ActivationScope { OWNER_ONLY, OWNER_SIDE, OPPOSITE_SIDE, ALL }

const ON_TURN_END := "on_turn_end"
const ON_TURN_START := "on_turn_start"

const ON_HIT := "on_hit"
const ON_POST_HIT := "on_post_hit"
const ON_DAMAGE_ABOUT_TO_BE_APPLIED := "damage_about_to_be_applied"
const ON_BEFORE_RECEIVE_DAMAGE := "on_before_receive_damage"
const ON_DAMAGE_APPLIED := "damage_applied"

const ON_HEAL := "on_heal"
const ON_RECEIVE_HEAL := "on_receive_heal"

const ON_BEFORE_APPLY_EFFECT := "on_before_apply_effect"
const ON_BEFORE_RECEIVE_EFFECT := "on_before_receive_effect"
const ON_APPLY_EFFECT := "on_apply_effect"
const ON_POST_APPLY_EFFECT := "on_post_apply_effect"
const ON_EXPIRE := "on_expire"
