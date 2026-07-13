"""
test_lambda.py — unit tests for gym_logbook_submit.py

Run all tests from the project root with:
    pytest tests/ -v

The -v flag means "verbose" — it prints each test name and pass/fail instead
of just dots. Useful while learning.

----------------------------------------------------------------------
HOW EVERY TEST IS STRUCTURED — THE AAA PATTERN
----------------------------------------------------------------------

    Arrange  — set up the inputs / state you need
    Act      — call the one function you're testing
    Assert   — check the output is what you expected

Keep each test focused on ONE thing. If a test fails, you want to know
immediately what broke — not hunt through a test that checks five things at once.

----------------------------------------------------------------------
IMPORTS
----------------------------------------------------------------------

sys.path.insert puts the lambda_functions/ folder on Python's module search path so we
can import from gym_logbook_submit without installing it as a package.
"""

import json
import sys
import os
from unittest.mock import patch
import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "lambda_functions"))  # pylint: disable=wrong-import-position

# pylint: disable=wrong-import-position,missing-function-docstring
from gym_logbook_submit import (
    event_parse,
    row_maker,
    csv_maker,
    key_maker,
    validate_workout,
    lambda_handler,
)

# ==============================================================================
# SECTION 1 — event_parse
# ==============================================================================
#
# event_parse takes a raw API Gateway event (a dict with a "body" key whose
# value is a JSON *string*) and returns a Python dictionary.
#
# FULLY WORKED — read these carefully and make sure you understand the pattern
# before moving on to the exercises below.
# ==============================================================================


def test_event_parse_returns_a_dict():
    # Arrange — build the minimal event shape API Gateway sends
    event = {"body": json.dumps({"workout_date": "2026-06-18"})}

    # Act — call the function
    result = event_parse(event)

    # Assert — check the return type
    assert isinstance(result, dict)


def test_event_parse_decodes_workout_date():
    # Arrange
    event = {"body": json.dumps({"workout_date": "2026-06-18", "notes": "test"})}

    # Act
    result = event_parse(event)

    # Assert — check a specific field survived the decode intact
    assert result["workout_date"] == "2026-06-18"


# EXERCISE 1a — write a test that checks event_parse correctly decodes the
# "notes" field. Follow the exact same Arrange / Act / Assert structure above.
#
def test_event_parse_decodes_notes():

    event = {"body": json.dumps({"notes" : "hello world"})}

    result = event_parse(event)

    assert result["notes"] == "hello world"


# ==============================================================================
# SECTION 2 — row_maker
# ==============================================================================
#
# row_maker takes the parsed workout dict and flattens it into a list of rows,
# one row per set. Each row is a list: [date, notes, exercise_name, reps, weight_kg]
#
# The fixture `valid_workout` (defined in conftest.py) is passed in automatically
# by pytest when you name it as a parameter. It has 2 exercises: bench press
# (2 sets) and SQUAT (1 set) — so 3 rows total.
#
# PARTIALLY WORKED — Arrange and Act are done. You write the Assert.
# ==============================================================================


def test_row_maker_returns_correct_number_of_rows(valid_workout):
    # Arrange — `valid_workout` is injected by pytest from conftest.py
    # (no setup needed here, the fixture does it)

    # Act
    rows = row_maker(valid_workout)

    # EXERCISE 2a — assert that len(rows) equals the number of sets in valid_workout
    assert len(rows) == sum("reps" in number for exercise in valid_workout["exercises"] for number in exercise["sets"])


def test_row_maker_title_cases_exercise_names(valid_workout):
    # Act
    rows = row_maker(valid_workout)

    assert rows
    assert all(exercise[2].istitle() for exercise in rows)

    # EXERCISE 2b — the fixture has "bench press" (lower) and "SQUAT" (upper).
    # Assert that rows[0][2] (first row, exercise name column) is title-cased.
    # Hint: "bench press".title() == "Bench Press"
    # assert ...


def test_row_maker_row_has_correct_structure(valid_workout):
    # Act
    rows = row_maker(valid_workout)
    first_row = rows[0]

    assert first_row == ["2026-06-18", "Good session", "Bench Press", 10, 60]

    # EXERCISE 2c — assert that first_row equals exactly what you'd expect:
    # date, notes, title-cased name, reps, weight for the first set.
    # assert first_row == [...]

# EXERCISE 2d — what happens when exercises is an empty list?
# Write a test for that edge case. Does the function crash or return []?
# Try it in a Python shell first: row_maker({"workout_date": ..., "notes": ..., "exercises": []})
#
def test_row_maker_empty_exercises_returns_empty_list():
    workout = {
        "workout_date": "2026-06-18",
        "notes": "Good session",
        "exercises": []
    }

    with pytest.raises(ValueError):
        row_maker(workout)

# ==============================================================================
# SECTION 3 — csv_maker
# ==============================================================================
#
# csv_maker takes the list of rows from row_maker and returns a string of CSV
# content (including a header row).
#
# LIGHTLY SCAFFOLDED — the Arrange is given; you write Act and Assert.
# ==============================================================================

def test_csv_maker_output_is_str():
    # Arrange
    rows = [["2026-06-18", "notes", "Squat", 5, 100]]

    csv_ouput = csv_maker(rows)

    assert isinstance(csv_ouput, str)

def test_csv_maker_output_has_correct_header():
    # Arrange
    rows = [["2026-06-18", "notes", "Squat", 5, 100]]

    csv_output = csv_maker(rows)
    header = 'workout_date,notes,exercise_name,reps,weight_kg'

    assert csv_output.splitlines()[0] == header

    # EXERCISE 3a — call csv_maker, then check that the first line of the output
    # is the expected header string.
    # Hint: "some\nstring".splitlines()[0] gives you the first line.
    # Hint: the header should be: "workout_date,notes,exercise_name,reps,weight_kg"


def test_csv_maker_correct_number_of_lines():
    # Arrange
    rows = [
        ["2026-06-18", "", "Squat", 5, 100],
        ["2026-06-18", "", "Squat", 5, 105],
    ]

    output = csv_maker(rows)
    csv_list = output.splitlines()

    assert len(csv_list) == 3

def test_csv_maker_preserves_row_data():
    # Arrange
    rows = [
        ["2026-06-18", "", "Squat", 5, 100],
        ["2026-06-18", "", "Squat", 5, 105],
    ]

    output = csv_maker(rows)
    csv_list = output.splitlines()

    assert '2026-06-18,,Squat,5,100' == csv_list[1]
    assert '2026-06-18,,Squat,5,105' == csv_list[2]

    # EXERCISE 3b — call csv_maker and assert the output has 3 lines total
    # (1 header + 2 data rows). Use .strip().splitlines() to avoid blank trailing lines.


# ==============================================================================
# SECTION 4 — validate_workout
# ==============================================================================
#
# validate_workout raises ValueError if any set has empty or null reps/weight_kg.
# It returns None (implicitly) when everything is valid.
#
# This section introduces pytest.raises — the way you test that a function
# raises an exception when it's supposed to.
#
# FULLY WORKED EXAMPLE — read this, then write the exercises below.
# ==============================================================================

def test_validate_workout_raises_on_empty_reps():
    # Arrange — a workout where reps is an empty string
    workout = {
        "exercises": [
            {"sets": [{"reps": "", "weight_kg": 100}]}
        ]
    }

    # Assert (wrapping Act) — pytest.raises is a context manager.
    # The code inside the `with` block MUST raise the named exception,
    # otherwise the test fails. This is how you verify error handling.
    with pytest.raises(ValueError):
        validate_workout(workout)

def test_validate_workout_raises_on_none_reps():
    # Arrange — a workout where reps is an empty string
    workout = {
        "exercises": [
            {"sets": [{"reps": None, "weight_kg": 100}]}
        ]
    }

    # Assert (wrapping Act) — pytest.raises is a context manager.
    # The code inside the `with` block MUST raise the named exception,
    # otherwise the test fails. This is how you verify error handling.
    with pytest.raises(ValueError):
        validate_workout(workout)


# EXERCISE 4a — write a test for the case where weight_kg is empty.
def test_validate_workout_raises_on_empty_weight():
    #Arrange
    workout = {
        "exercises": [
            {"sets": [{"reps": "", "weight_kg": ""}]}
        ]
    }

    with pytest.raises(ValueError):
        validate_workout(workout)

def test_validate_workout_raises_on_none_weight():
    #Arrange
    workout = {
        "exercises": [
            {"sets": [{"reps": "", "weight_kg": None}]}
        ]
    }

    with pytest.raises(ValueError):
        validate_workout(workout)

# EXERCISE 4c — write a test that confirms validate_workout does NOT raise
# when the data is valid. Use the `valid_workout` fixture from conftest.py.
# Hint: just call the function — if it raises, pytest will catch it and fail the test.
#
def test_validate_workout_passes_with_valid_data(valid_workout):
    validate_workout(valid_workout)

# ==============================================================================
# SECTION 5 — lambda_handler (with mocking)
# ==============================================================================
#
# lambda_handler calls upload_to_s3, which uses boto3 to talk to real AWS.
# We don't want our tests to hit AWS — that's slow, costs money, and requires
# credentials. Instead, we MOCK upload_to_s3: replace it with a fake that
# does nothing but lets the rest of the code run normally.
#
# @patch("gym_logbook_submit.upload_to_s3") replaces the real function with a
# MagicMock object for the duration of the test. The mock is passed into the
# test as `mock_upload` — you can use it to check if it was called, with what
# arguments, etc. (though you don't need to here).
#
# FULLY WORKED — the first test shows the full pattern. The rest are exercises.
# ==============================================================================

@patch("gym_logbook_submit.upload_to_s3")
def test_lambda_handler_returns_200_on_valid_input(mock_upload, test_event):
    # Arrange — VALID_EVENT is defined above; mock_upload replaces the real S3 call

    # Act
    result = lambda_handler(test_event, None)

    # Assert
    assert result["statusCode"] == 200


@patch("gym_logbook_submit.upload_to_s3")
def test_lambda_handler_returns_400_on_invalid_data(mock_upload):
    # Arrange — build a bad event where reps is empty
    bad_event = {
        "body": json.dumps({
            "workout_date": "2026-06-18",
            "notes": "",
            "exercises": [
                {"name": "squat", "sets": [{"reps": "", "weight_kg": None}]}
            ]
        })
    }

    result = lambda_handler(bad_event, None)

    assert result["statusCode"] == 400

# EXERCISE 5b — write a test that checks the response body contains a "message" key.
# Hint: the body is a JSON string — you'll need json.loads() to parse it.
# Hint: look at what lambda_handler actually returns on line 128 of the Lambda file.

@patch("gym_logbook_submit.upload_to_s3")
def test_lambda_handler_200_response_contains_message_key(mock_upload, test_event):

    result = lambda_handler(test_event, None)
    response = result["body"]

    assert json.loads(response)["message"] == "Workout processed successfully"

# EXERCISE 5c — STRETCH GOAL
# Write a test that checks lambda_handler returns 500 when upload_to_s3 raises
# an unexpected exception. You can make the mock raise by doing:
#     mock_upload.side_effect = Exception("something broke")
#
@patch("gym_logbook_submit.upload_to_s3")
def test_lambda_handler_returns_500_on_unexpected_error(mock_upload, test_event):
    mock_upload.side_effect = Exception("Unable to reach AWS")

    result = lambda_handler(test_event, None)

    assert result["statusCode"] == 500

# EXERCISE 6a - Key maker Unit Test
