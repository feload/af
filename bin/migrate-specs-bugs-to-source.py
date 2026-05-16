#!/usr/bin/env python3
"""One-shot migration: split specs.js and bugs.js into per-item files.

Reads:
  .af/docs/usm/specs.js   (header comments, then `window.USM_SPECS = [...]`)
  .af/docs/usm/bugs.js    (header comments, then `window.USM_BUGS = [...]`)

Writes:
  source/specs/SPEC-XXXX.json
  source/bugs/BUG-XXXX.json (creates the dir even if empty)

Verifies the round-trip by re-loading each per-item file and comparing the
list to the original parsed payload.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "docs" / "usm"
SOURCE = ROOT / "source"

SPEC_KEY_ORDER = ["id", "title", "status", "card", "story",
                  "context", "problem", "constraints", "subtasks",
                  "edgeCases", "doneCriteria"]

BUG_KEY_ORDER = ["id", "title", "status", "card", "story", "foundAt",
                 "description", "stepsToReproduce", "expected", "actual",
                 "affectedArea", "rootCause", "fix", "regressionTest",
                 "doneCriteria"]


def parse_array_assignment(path: Path, var: str) -> list:
    """Parse `window.<var> = [ ...JSON... ];` from a .js file.

    Skips the leading `//` header lines and any whole-line `//` comments
    interleaved inside the array body (e.g. commented-out example items).
    JSON strings never start with `//` after whitespace, so stripping
    lines whose first non-whitespace token is `//` is safe.
    """
    text = path.read_text(encoding="utf-8")
    pattern = rf"window\.{re.escape(var)}\s*=\s*"
    m = re.search(pattern, text)
    if not m:
        raise SystemExit(f"{path}: no `window.{var} =` assignment found")
    body = text[m.end():]
    body = "\n".join(line for line in body.splitlines() if not line.lstrip().startswith("//"))
    body = body.rstrip().rstrip(";").rstrip()
    return json.loads(body)


def write_json(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def reorder(item: dict, key_order: list[str]) -> dict:
    ordered = {k: item[k] for k in key_order if k in item}
    for k, v in item.items():
        if k not in ordered:
            ordered[k] = v
    return ordered


def migrate(var: str, dir_name: str, key_order: list[str]) -> int:
    src = ROOT / f"{dir_name}.js"
    items = parse_array_assignment(src, var)
    out_dir = SOURCE / dir_name
    out_dir.mkdir(parents=True, exist_ok=True)
    for item in items:
        write_json(out_dir / f"{item['id']}.json", reorder(item, key_order))

    # Round-trip check: re-load per-item files and compare to the original list.
    rebuilt = [json.loads(f.read_text(encoding="utf-8"))
               for f in sorted(out_dir.glob("*.json"))]
    original_sorted = sorted(items, key=lambda x: x["id"])

    # Compare as deep-equal dicts (key order does not matter for equality)
    if rebuilt != original_sorted:
        # Find first divergent id for the operator
        rebuilt_by_id = {x["id"]: x for x in rebuilt}
        orig_by_id = {x["id"]: x for x in original_sorted}
        for k in sorted(set(rebuilt_by_id) | set(orig_by_id)):
            if rebuilt_by_id.get(k) != orig_by_id.get(k):
                print(f"divergence in {var} item {k}", file=sys.stderr)
                break
        raise SystemExit(f"round-trip verification FAILED for {var}")
    return len(items)


def main() -> None:
    n_specs = migrate("USM_SPECS", "specs", SPEC_KEY_ORDER)
    print(f"wrote source/specs/ — {n_specs} specs (round-trip OK)")

    n_bugs = migrate("USM_BUGS", "bugs", BUG_KEY_ORDER)
    print(f"wrote source/bugs/ — {n_bugs} bugs (round-trip OK)")


if __name__ == "__main__":
    main()
