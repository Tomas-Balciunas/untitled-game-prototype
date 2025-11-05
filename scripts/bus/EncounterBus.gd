extends Node

signal encounter_started(encounter_data: EncounterData)
signal encounter_concluded(result: String)
signal encounter_ended(result: String, encounter_data: EncounterData)
