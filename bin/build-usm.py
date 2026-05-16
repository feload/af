#!/usr/bin/env python3
"""Bundle .af/docs/usm/source/ into the static .js files the viewer reads.

The USM is a static site opened by double-clicking index.html, so it cannot
fetch many files from file://. Per-item JSON lives under source/ as the
single source of truth; this script regenerates data.js, specs.js and bugs.js
from those sources.

Re-runnable. Subdirectories that don't exist yet (e.g. source/specs/, while
specs are not yet migrated) are skipped, leaving the corresponding .js file
untouched.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "docs" / "usm"
SOURCE = ROOT / "source"


def write_js(path: Path, var_name: str, payload) -> None:
    body = json.dumps(payload, indent=2, ensure_ascii=False)
    path.write_text(f"window.{var_name} = {body};\n", encoding="utf-8")


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def build_data() -> None:
    skeleton_path = SOURCE / "skeleton.json"
    if not skeleton_path.exists():
        print("skip data.js: source/skeleton.json missing", file=sys.stderr)
        return

    skeleton = load_json(skeleton_path)

    releases_dir = SOURCE / "releases"
    releases = [load_json(f) for f in sorted(releases_dir.glob("*.json"))]

    stories_by_step: dict[str, list] = {}
    for f in sorted((SOURCE / "stories").glob("*.json")):
        story = load_json(f)
        step_id = story.pop("step", None)
        if step_id is None:
            print(f"warn: {f.name} missing 'step' field — skipped", file=sys.stderr)
            continue
        stories_by_step.setdefault(step_id, []).append(story)

    known_steps = {s["id"] for a in skeleton["activities"] for s in a["steps"]}
    for step_id in stories_by_step:
        if step_id not in known_steps:
            print(f"warn: step '{step_id}' has stories but is not in skeleton.json", file=sys.stderr)

    activities = []
    for activity in skeleton["activities"]:
        steps = []
        for step in activity["steps"]:
            step_stories = sorted(
                stories_by_step.get(step["id"], []),
                key=lambda s: s["id"],
            )
            steps.append({**step, "stories": step_stories})
        activities.append({**activity, "steps": steps})

    payload = {"slices": releases, "activities": activities}
    write_js(ROOT / "data.js", "USM_DATA", payload)
    total = sum(len(s["stories"]) for a in activities for s in a["steps"])
    print(f"wrote data.js — {len(releases)} releases, {len(activities)} activities, {total} stories")


def build_specs() -> None:
    specs_dir = SOURCE / "specs"
    if not specs_dir.exists():
        return
    specs = [load_json(f) for f in sorted(specs_dir.glob("*.json"))]
    write_js(ROOT / "specs.js", "USM_SPECS", specs)
    print(f"wrote specs.js — {len(specs)} specs")


def build_bugs() -> None:
    bugs_dir = SOURCE / "bugs"
    if not bugs_dir.exists():
        return
    bugs = [load_json(f) for f in sorted(bugs_dir.glob("*.json"))]
    write_js(ROOT / "bugs.js", "USM_BUGS", bugs)
    print(f"wrote bugs.js — {len(bugs)} bugs")


def build_index() -> None:
    """Regenerate source/INDEX.md from the per-item files.

    INDEX.md is a grep-friendly catalogue (one row per item) so callers can
    locate a US/SPEC/BUG without opening every file. It is a generated
    artifact — do not hand-edit.
    """
    lines = [
        "# USM source index",
        "",
        "Single source of truth for stories, SPECs and bugs. The build script",
        "(`.af/bin/build-usm.py`) regenerates `data.js`, `specs.js`, `bugs.js`",
        "and this file from the per-item JSON under `source/`. Do not",
        "hand-edit the generated `.js` files or this catalogue.",
        "",
    ]

    # Pre-compute which stories have at least one external SPEC linked, so the
    # story rows can show whether the SPEC is inline, external, or missing.
    external_specs_by_story: dict[str, int] = {}
    specs_dir = SOURCE / "specs"
    if specs_dir.exists():
        for f in sorted(specs_dir.glob("*.json")):
            s = load_json(f)
            story_id = s.get("story")
            if story_id:
                external_specs_by_story[story_id] = external_specs_by_story.get(story_id, 0) + 1

    def spec_kind(story: dict) -> str:
        inline = bool(
            story.get("context")
            or story.get("problem")
            or story.get("constraints")
            or story.get("subtasks")
            or story.get("edgeCases")
            or story.get("doneCriteria")
        )
        external_count = external_specs_by_story.get(story["id"], 0)
        if inline and external_count:
            return f"inline + {external_count} ext"
        if inline:
            return "inline"
        if external_count:
            return f"external ({external_count})"
        return "—"

    # Stories
    story_rows: list[tuple[str, ...]] = []
    stories_dir = SOURCE / "stories"
    if stories_dir.exists():
        for f in sorted(stories_dir.glob("*.json")):
            s = load_json(f)
            story_rows.append((
                s["id"],
                s["title"].replace("|", "\\|"),
                s.get("status", ""),
                s.get("slice") or "—",
                s.get("step", "—"),
                spec_kind(s),
            ))
    lines += ["## Stories", "", "| ID | Title | Status | Slice | Step | Spec |", "|---|---|---|---|---|---|"]
    lines += ["| " + " | ".join(r) + " |" for r in story_rows] or ["| _none_ |  |  |  |  |  |"]
    lines += [""]

    # SPECs
    spec_rows: list[tuple[str, ...]] = []
    if specs_dir.exists():
        for f in sorted(specs_dir.glob("*.json")):
            s = load_json(f)
            spec_rows.append((
                s["id"],
                s["title"].replace("|", "\\|"),
                s.get("status", ""),
                s.get("story") or "—",
            ))
    lines += ["## SPECs", "", "| ID | Title | Status | Story |", "|---|---|---|---|"]
    lines += ["| " + " | ".join(r) + " |" for r in spec_rows] or ["| _none_ |  |  |  |"]
    lines += [""]

    # Bugs
    bug_rows: list[tuple[str, ...]] = []
    bugs_dir = SOURCE / "bugs"
    if bugs_dir.exists():
        for f in sorted(bugs_dir.glob("*.json")):
            b = load_json(f)
            bug_rows.append((
                b["id"],
                b["title"].replace("|", "\\|"),
                b.get("status", ""),
                b.get("story") or "—",
            ))
    lines += ["## Bugs", "", "| ID | Title | Status | Story |", "|---|---|---|---|"]
    lines += ["| " + " | ".join(r) + " |" for r in bug_rows] or ["| _none_ |  |  |  |"]
    lines += [""]

    (SOURCE / "INDEX.md").write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote INDEX.md — {len(story_rows)} stories, {len(spec_rows)} specs, {len(bug_rows)} bugs")


if __name__ == "__main__":
    build_data()
    build_specs()
    build_bugs()
    build_index()
