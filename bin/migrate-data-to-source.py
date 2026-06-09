#!/usr/bin/env python3
"""One-shot migration: split data.js into per-item files under source/.

Reads window.USM_DATA from .af/docs/usm/data.js and writes:
  source/skeleton.json            activity + step skeleton (no stories)
  source/releases/<slice>.json    one file per release/slice
  source/stories/US-XXXX.json     one file per story, with `step` added
  source/INDEX.md                 grep-friendly catalogue

After running this, run build-usm.py and the rebuilt data.js should be
content-equivalent to the original (whitespace/key-order may differ).
The script verifies this and reports any divergence.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "docs" / "usm"
SOURCE = ROOT / "source"

STORY_KEY_ORDER = ["id", "title", "status", "slice", "step",
                   "description", "rationale", "acceptance", "tasks"]


def parse_data_js(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    m = re.match(r"\s*window\.USM_DATA\s*=\s*", text)
    if not m:
        raise SystemExit(f"unexpected format in {path}: missing window.USM_DATA assignment")
    body = text[m.end():].rstrip().rstrip(";").rstrip()
    return json.loads(body)


def write_json(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def reorder_story(story: dict, step_id: str) -> dict:
    enriched = {**story, "step": step_id}
    ordered = {k: enriched[k] for k in STORY_KEY_ORDER if k in enriched}
    for k, v in enriched.items():
        if k not in ordered:
            ordered[k] = v
    return ordered


def verify_roundtrip(original: dict) -> None:
    """Rebuild data.js (without touching disk) and compare to the original."""
    skeleton = json.loads((SOURCE / "skeleton.json").read_text(encoding="utf-8"))
    releases = [json.loads(f.read_text(encoding="utf-8"))
                for f in sorted((SOURCE / "releases").glob("*.json"))]
    stories_by_step: dict[str, list] = {}
    for f in sorted((SOURCE / "stories").glob("*.json")):
        story = json.loads(f.read_text(encoding="utf-8"))
        step_id = story.pop("step")
        stories_by_step.setdefault(step_id, []).append(story)

    rebuilt_activities = []
    for activity in skeleton["activities"]:
        steps = []
        for step in activity["steps"]:
            step_stories = sorted(stories_by_step.get(step["id"], []), key=lambda s: s["id"])
            steps.append({**step, "stories": step_stories})
        rebuilt_activities.append({**activity, "steps": steps})

    # Normalise the original the same way: sort stories within each step by id.
    normalised = {
        "slices": original["slices"],
        "activities": [
            {**a, "steps": [
                {**s, "stories": sorted(s.get("stories", []), key=lambda x: x["id"])}
                for s in a["steps"]
            ]}
            for a in original["activities"]
        ],
    }
    rebuilt = {"slices": releases, "activities": rebuilt_activities}

    if rebuilt != normalised:
        # Compute a coarse diff for the operator
        for key in ("slices", "activities"):
            if rebuilt[key] != normalised[key]:
                print(f"divergence in {key}", file=sys.stderr)
        raise SystemExit("round-trip verification FAILED — see divergences above")


def main() -> None:
    data = parse_data_js(ROOT / "data.js")

    for slice_ in data["slices"]:
        write_json(SOURCE / "releases" / f"{slice_['id']}.json", slice_)

    # The viewer titles the page from `project`; default it to the repo name.
    skeleton = {"project": Path.cwd().name, "activities": []}
    index_rows: list[tuple[str, ...]] = []
    story_count = 0

    for activity in data["activities"]:
        sk_activity = {
            "id": activity["id"],
            "title": activity["title"],
            "steps": [{"id": s["id"], "title": s["title"]} for s in activity["steps"]],
        }
        skeleton["activities"].append(sk_activity)
        for step in activity["steps"]:
            for story in step.get("stories", []):
                ordered = reorder_story(story, step["id"])
                write_json(SOURCE / "stories" / f"{story['id']}.json", ordered)
                story_count += 1
                index_rows.append((
                    story["id"],
                    story["title"].replace("|", "\\|"),
                    story.get("status", ""),
                    story.get("slice") or "—",
                    step["id"],
                ))

    write_json(SOURCE / "skeleton.json", skeleton)

    lines = [
        "# USM source index",
        "",
        "Single source of truth for stories, SPECs and bugs. The build script",
        "(`.af/bin/build-usm.py`) regenerates `data.js`, `specs.js` and `bugs.js`",
        "from these files — do not hand-edit the generated `.js`.",
        "",
        "## Stories",
        "",
        "| ID | Title | Status | Slice | Step |",
        "|---|---|---|---|---|",
    ]
    for row in sorted(index_rows, key=lambda r: r[0]):
        lines.append("| " + " | ".join(row) + " |")
    lines += [
        "",
        "## SPECs",
        "",
        "_not yet migrated — see `specs.js`._",
        "",
        "## Bugs",
        "",
        "_not yet migrated — see `bugs.js`._",
        "",
    ]
    (SOURCE / "INDEX.md").write_text("\n".join(lines), encoding="utf-8")

    print(f"wrote source/: {len(data['slices'])} releases, "
          f"{len(skeleton['activities'])} activities, {story_count} stories")

    verify_roundtrip(data)
    print("round-trip verification: OK")


if __name__ == "__main__":
    main()
