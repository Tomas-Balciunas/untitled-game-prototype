extends Node

signal request_conversation(speaker: String, lines: Array)
signal conversation_finished

signal request_choice(text: String, choices: Array)
signal choice_made(choice: String)

signal event_concluded
