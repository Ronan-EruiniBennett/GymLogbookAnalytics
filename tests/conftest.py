"""
conftest.py — pytest reads this file automatically before running any tests.

Its main job is to hold FIXTURES. A fixture is a reusable piece of test setup —
think of it as a function that builds the inputs your tests need, so you don't
have to repeat that setup code in every single test.

You declare a fixture with @pytest.fixture, then pass its name as a parameter
to any test function that needs it. pytest wires them together automatically.

Example:
    @pytest.fixture
    def my_number():
        return 42

    def test_something(my_number):   # <-- pytest injects the fixture here
        assert my_number == 42

The fixture below builds a realistic workout dictionary — the same shape of data
your Lambda receives after event_parse() runs. Several tests will need this, so
it lives here rather than being copy-pasted into each test.
"""

import pytest


@pytest.fixture
def valid_workout():
    """A realistic workout dict with two exercises and multiple sets each."""
    return {
        "workout_date": "2026-06-18",
        "notes": "Good session",
        "exercises": [
            {
                "name": "bench press",
                "sets": [
                    {"reps": 10, "weight_kg": 60},
                    {"reps": 8,  "weight_kg": 70},
                ]
            },
            {
                "name": "SQUAT",
                "sets": [
                    {"reps": 5, "weight_kg": 100},
                ]
            }
        ]
    }


