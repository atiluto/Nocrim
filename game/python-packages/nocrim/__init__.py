"""Nocrim's deterministic, save-friendly campaign rules."""
from .world import REGIONS, PEOPLE, EVENTS, ENDINGS
from .engine import new_game, apply, available_choices, frontier, power, chance, income, upkeep, relation_name, ending, finale_options
