#!/usr/bin/env python3
"""Validate audio/v2/cues.json against the Guided Practice v2 contract.

Run from anywhere; paths resolve relative to this file. Plain run validates the
committed manifest. `--self-test` additionally applies the committed negative
cases in memory and fails unless every one of them is rejected. CI runs both.
"""

import copy
import json
import sys
from pathlib import Path

MANIFEST = Path(__file__).resolve().parent.parent / "audio" / "v2" / "cues.json"
EXPECTED_SCHEMA = "guided-practice-manifest"
EXPECTED_SCHEMA_VERSION = 2

# Mirrors TimerEngine and the shipped gong assets; GuideManifestTests.swift
# asserts the same numbers against the live engine constants.
PREPARATION_SECONDS = 8
START_GONG_SECONDS = 4
WARNING_GONG_SECONDS = 4
COMPLETION_GONGS_SECONDS = 12
WARNING_BEFORE_END = 300
WARNING_STRICTLY_OVER_MINUTES = 30
METTA_ENDS_BEFORE_COMPLETION = 30
PROGRAM_TAIL_SECONDS = 3

# The fixed v2 product matrix. Expanding it is a spec change, not a manifest
# edit: specs/002-guided-practice/spec.md limits programs to these presets.
SUPPORTED_DURATIONS = (15, 30, 45, 60)
SUPPORTED_MATRIX = {(mode, minutes) for mode in ("guided", "light") for minutes in SUPPORTED_DURATIONS}

EXPECTED_ASSETS = {
    "container": "m4a",
    "codec": "aac",
    "sampleRateHz": 48000,
    "channels": 1,
    "integratedLufs": -19,
    "truePeakMaxDbfs": -3,
}
EXPECTED_TIMELINE = {
    "voiceOffsetOrigin": "meditationStart",
    "gongOffsetOrigin": "meditationStart",
    "playbackStartsAt": "sittingStart",
    "preparationSeconds": PREPARATION_SECONDS,
    "startGongSeconds": START_GONG_SECONDS,
    "completionGongsSeconds": COMPLETION_GONGS_SECONDS,
    "warningOffsetBeforeEndSeconds": WARNING_BEFORE_END,
    "warningGongSeconds": WARNING_GONG_SECONDS,
    "warningRequiresDurationStrictlyOverMinutes": WARNING_STRICTLY_OVER_MINUTES,
    "mettaEndsBeforeCompletionSeconds": METTA_ENDS_BEFORE_COMPLETION,
}
EXPECTED_GONGS = {
    "start": ("../../VipassanaTimer/Resources/Sounds/gong_start.caf", START_GONG_SECONDS),
    "warning": ("../../VipassanaTimer/Resources/Sounds/gong_start.caf", WARNING_GONG_SECONDS),
    "completion": ("../../VipassanaTimer/Resources/Sounds/gong_end_triple.caf", COMPLETION_GONGS_SECONDS),
}
# The instruction arc: fixed opening offsets, transition at one-third,
# equanimity reset at two-thirds (sittings of 30 minutes and up), metta
# inside the sitting — its reserved window closes 30 seconds before the
# completion gongs, so the spoken close is followed by silence, then the bell.
# settle starts once the 4s start gong has rung, leaving a few seconds of quiet
FIXED_VOICE_OFFSETS = {"settle": 8, "breath": 105, "begin": 12}
EXPECTED_SEQUENCES = {
    ("guided", "short"): ["settle", "breath", "sensations", "metta"],
    ("guided", "long"): ["settle", "breath", "sensations", "equanimity", "metta"],
    ("light", "short"): ["begin", "metta"],
    ("light", "long"): ["begin", "metta"],
}
EQUANIMITY_FROM_MINUTES = 30


def overlaps(a_start, a_end, b_start, b_end):
    return a_start < b_end and b_start < a_end


def expected_voice_offset(segment, duration, metta_max=0):
    if segment in FIXED_VOICE_OFFSETS:
        return FIXED_VOICE_OFFSETS[segment]
    if segment == "sensations":
        return duration // 3
    if segment == "equanimity":
        return duration * 2 // 3
    if segment == "metta":
        return duration - METTA_ENDS_BEFORE_COMPLETION - metta_max
    return None


def validate(manifest):
    errors = []

    def check(condition, message):
        if not condition:
            errors.append(message)
        return condition

    check(manifest.get("schema") == EXPECTED_SCHEMA, "wrong schema name")
    check(manifest.get("schemaVersion") == EXPECTED_SCHEMA_VERSION, "wrong schemaVersion")
    check(manifest.get("language") == "en", "language must be en in v2")

    assets = manifest.get("assets", {})
    for key, value in EXPECTED_ASSETS.items():
        check(assets.get(key) == value, f"assets.{key} must be {value!r}, found {assets.get(key)!r}")

    timeline = manifest.get("timeline", {})
    for key, value in EXPECTED_TIMELINE.items():
        check(timeline.get(key) == value, f"timeline.{key} must be {value!r}, found {timeline.get(key)!r}")

    gongs = manifest.get("gongs", {})
    check(
        set(gongs) - {"note"} == set(EXPECTED_GONGS),
        f"gongs must define exactly {sorted(EXPECTED_GONGS)} (plus an optional note)")
    for gong_id, (master, seconds) in EXPECTED_GONGS.items():
        entry = gongs.get(gong_id, {})
        check(entry.get("master") == master, f"gongs.{gong_id}.master must be {master}")
        check(entry.get("durationSeconds") == seconds, f"gongs.{gong_id}.durationSeconds must be {seconds}")

    segments, seen_scripts, seen_masters = {}, set(), set()
    for seg in manifest.get("segments", []):
        seg_id = seg.get("id")
        if not check(seg_id not in segments, f"duplicate segment id {seg_id!r}"):
            continue
        segments[seg_id] = seg
        check(seg.get("script") not in seen_scripts, f"segment {seg_id}: script {seg.get('script')} reused")
        check(seg.get("master") not in seen_masters, f"segment {seg_id}: master {seg.get('master')} reused")
        seen_scripts.add(seg.get("script"))
        seen_masters.add(seg.get("master"))
        check(str(seg.get("master", "")).endswith(".wav"), f"segment {seg_id}: master must be a .wav")
        script = MANIFEST.parent / str(seg.get("script", ""))
        check(script.is_file(), f"segment {seg_id}: script {seg.get('script')} does not exist")
        check(
            0 < seg.get("minDurationSeconds", 0) <= seg.get("maxDurationSeconds", -1),
            f"segment {seg_id}: bad duration range")

    modes = {}
    for mode in manifest.get("modes", []):
        if not check(mode.get("id") not in modes, f"duplicate mode id {mode.get('id')!r}"):
            continue
        modes[mode["id"]] = mode
    check(set(modes) == {"silent", "light", "guided"}, "modes must be exactly silent, light, guided")
    check(
        not modes.get("silent", {}).get("supportedDurationsMinutes", [1]),
        "silent mode must support no program durations")
    defaults = [m["id"] for m in modes.values() if m.get("default")]
    check(defaults == ["silent"], f"silent must be the one and only default mode, found {defaults}")
    for mode_id in ("light", "guided"):
        durations = tuple(modes.get(mode_id, {}).get("supportedDurationsMinutes", []))
        check(
            durations == SUPPORTED_DURATIONS,
            f"mode {mode_id} must support exactly {SUPPORTED_DURATIONS}, found {durations}")

    programs = manifest.get("programs", [])
    seen_keys, seen_files = set(), set()
    for program in programs:
        key = (program.get("mode"), program.get("durationMinutes"))
        check(key not in seen_keys, f"duplicate program for {key}")
        seen_keys.add(key)
        check(key in SUPPORTED_MATRIX, f"program {key} is outside the fixed v2 matrix")
        file_name = program.get("file", "")
        check(file_name not in seen_files, f"program file {file_name!r} reused")
        seen_files.add(file_name)
        check(file_name.endswith("-v2-en.m4a"), f"program {key}: file must end with -v2-en.m4a")
    for key in SUPPORTED_MATRIX:
        check(key in seen_keys, f"matrix entry {key} has no program")

    metta_max = segments.get("metta", {}).get("maxDurationSeconds", 0)
    for program in programs:
        mode, minutes = program.get("mode"), program.get("durationMinutes", 0)
        if (mode, minutes) not in SUPPORTED_MATRIX:
            continue
        label = f"{mode}-{minutes}"
        duration = minutes * 60

        check(
            program.get("leadInSilenceSeconds") == PREPARATION_SECONDS,
            f"{label}: leadInSilenceSeconds must equal the {PREPARATION_SECONDS}s preparation")
        expected_length = (
            PREPARATION_SECONDS + duration + COMPLETION_GONGS_SECONDS
            + PROGRAM_TAIL_SECONDS)
        check(
            program.get("lengthSeconds") == expected_length,
            f"{label}: lengthSeconds must be exactly {expected_length}")

        expected_gongs = [("start", 0)]
        if minutes > WARNING_STRICTLY_OVER_MINUTES:
            expected_gongs.append(("warning", duration - WARNING_BEFORE_END))
        expected_gongs.append(("completion", duration))
        actual_gongs = [(g.get("gong"), g.get("offsetSeconds")) for g in program.get("gongLayout", [])]
        check(actual_gongs == expected_gongs, f"{label}: gongLayout is {actual_gongs}, expected {expected_gongs}")

        gong_windows = [
            (name, offset, offset + EXPECTED_GONGS[name][1]) for name, offset in expected_gongs]

        layout = program.get("layout", [])
        length_form = "long" if minutes >= EQUANIMITY_FROM_MINUTES else "short"
        expected_sequence = EXPECTED_SEQUENCES[(mode, length_form)]
        actual_sequence = [entry.get("segment") for entry in layout]
        if not check(
            actual_sequence == expected_sequence,
            f"{label}: sequence is {actual_sequence}, expected {expected_sequence}",
        ):
            continue

        previous_end = 0.0
        for entry in layout:
            seg = segments.get(entry["segment"])
            if seg is None:
                errors.append(f"{label}: unknown segment {entry['segment']!r}")
                continue
            start = entry.get("offsetSeconds")
            required = expected_voice_offset(entry["segment"], duration, metta_max)
            check(
                start == required,
                f"{label}: {entry['segment']} must sit at {required}s, found {start}s")
            end = start + seg["maxDurationSeconds"]
            check(start >= previous_end, f"{label}: {entry['segment']} overlaps the previous segment")
            previous_end = end
            for gong_name, g_start, g_end in gong_windows:
                check(
                    not overlaps(start, end, g_start, g_end),
                    f"{label}: {entry['segment']} [{start}, {end}]s overlaps the {gong_name} gong")
            check(
                PREPARATION_SECONDS + end <= program.get("lengthSeconds", 0),
                f"{label}: {entry['segment']} ends {PREPARATION_SECONDS + end}s into the file, past program length")

    return errors


def self_test(manifest):
    """Committed negative cases: each mutation must be rejected."""

    def set_path(m, path, value):
        node = m
        for part in path[:-1]:
            node = node[part]
        node[path[-1]] = value

    def program(m, mode, minutes):
        return next(p for p in m["programs"] if p["mode"] == mode and p["durationMinutes"] == minutes)

    def voice(m, mode, minutes, segment):
        return next(e for e in program(m, mode, minutes)["layout"] if e["segment"] == segment)

    cases = {
        "wrong codec": lambda m: set_path(m, ["assets", "codec"], "opus"),
        "wrong sample rate": lambda m: set_path(m, ["assets", "sampleRateHz"], 44100),
        "stereo channels": lambda m: set_path(m, ["assets", "channels"], 2),
        "wrong loudness": lambda m: set_path(m, ["assets", "integratedLufs"], -14),
        "wrong warning gong seconds": lambda m: set_path(m, ["timeline", "warningGongSeconds"], 99),
        "wrong metta gap": lambda m: set_path(m, ["timeline", "mettaEndsBeforeCompletionSeconds"], 99),
        "mistimed settle": lambda m: set_path(voice(m, "guided", 15, "settle"), ["offsetSeconds"], 10),
        "mistimed breath": lambda m: set_path(voice(m, "guided", 30, "breath"), ["offsetSeconds"], 90),
        "mistimed begin": lambda m: set_path(voice(m, "light", 45, "begin"), ["offsetSeconds"], 20),
        "sensations off one-third": lambda m: set_path(voice(m, "guided", 60, "sensations"), ["offsetSeconds"], 300),
        "equanimity off two-thirds": lambda m: set_path(voice(m, "guided", 45, "equanimity"), ["offsetSeconds"], 1350),
        "late metta": lambda m: set_path(voice(m, "guided", 15, "metta"), ["offsetSeconds"], 930),
        "reordered sequence": lambda m: (
            set_path(voice(m, "guided", 15, "settle"), ["segment"], "breath"),
            set_path(program(m, "guided", 15)["layout"][1], ["segment"], "settle")),
        "duplicate program file": lambda m: set_path(
            program(m, "light", 30), ["file"], program(m, "light", 15)["file"]),
        "wrong program extension": lambda m: set_path(
            program(m, "guided", 60), ["file"], "guide-program-guided-60-v2-en.mp3"),
        "inflated program length": lambda m: set_path(program(m, "guided", 15), ["lengthSeconds"], 99999),
        "missing lead-in": lambda m: set_path(program(m, "light", 60), ["leadInSilenceSeconds"], 0),
        "missing completion gong": lambda m: set_path(
            program(m, "guided", 30), ["gongLayout"], [{"gong": "start", "offsetSeconds": 0}]),
        "mistimed warning gong": lambda m: set_path(
            program(m, "guided", 45)["gongLayout"][1], ["offsetSeconds"], 2000),
        "matrix expansion to 120": lambda m: (
            m["modes"][2]["supportedDurationsMinutes"].append(120),
            m["programs"].append({**copy.deepcopy(program(m, "guided", 60)),
                                  "durationMinutes": 120, "file": "guide-program-guided-120-v2-en.m4a"})),
        "reused segment master": lambda m: set_path(
            m["segments"][1], ["master"], m["segments"][0]["master"]),
        "reused segment script": lambda m: set_path(
            m["segments"][1], ["script"], m["segments"][0]["script"]),
        "duplicate segment id": lambda m: m["segments"].append(copy.deepcopy(m["segments"][0])),
        "duplicate mode id": lambda m: m["modes"].append(copy.deepcopy(m["modes"][1])),
        "second default mode": lambda m: set_path(m, ["modes", 1, "default"], True),
        "no default mode": lambda m: m["modes"][0].pop("default"),
    }

    failures = []
    for name, mutate in cases.items():
        mutated = copy.deepcopy(manifest)
        mutate(mutated)
        if not validate(mutated):
            failures.append(name)
    return failures


def main():
    try:
        manifest = json.loads(MANIFEST.read_text())
    except (OSError, json.JSONDecodeError) as error:
        print(f"FAIL: cannot read manifest {MANIFEST}: {error}")
        sys.exit(1)

    errors = validate(manifest)
    if errors:
        for error in errors:
            print(f"FAIL: {error}")
        sys.exit(1)

    if "--self-test" in sys.argv:
        failures = self_test(manifest)
        if failures:
            for name in failures:
                print(f"FAIL: negative case not rejected: {name}")
            sys.exit(1)
        print("OK: self-test rejected every negative case")

    checked = ", ".join(f"{m}-{d}" for m, d in sorted(SUPPORTED_MATRIX))
    print(f"OK: manifest schema v{EXPECTED_SCHEMA_VERSION}; validated programs: {checked}")


if __name__ == "__main__":
    main()
