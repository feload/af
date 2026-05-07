---
model: sonnet
effort: medium
---

# /af-create-card

**Trigger:** PM needs to create one or more external cards (tracker work items, file rows, links — wherever cards live for this project).

**Steps:**
1. If the PM hasn't said where cards should be created and `AGENTS.md` / `CLAUDE.md` / `.af/docs/conventions.md` doesn't make it clear, ask once. The framework is agnostic about the backend — examples: an Azure DevOps work item via MCP, a GitHub issue via the `gh` CLI, a Jira ticket, a row in a local file, or a manually-pasted ref.
2. For each card the PM wants to create:
   - Ask clarifying questions one at a time until the card has a clear title, summary, and acceptance criteria.
   - Show the PM the formatted card content and confirm before submitting.
   - Create the card via the chosen backend.
   - Capture the resulting card ref or link.
3. When the PM says they're done, output the list of card refs/links collected during the session.

**Output:** Card refs/links.

**Stop here.** Do not load the Lead. Do not write a SPEC. Card creation is its own session — the PM runs `/af-create-spec` (or `/af-create-bug`) in a separate session when they're ready to spec out a card.
