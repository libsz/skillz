# Contributing a skill

This repository supports multiple runtimes. Contribute skills with a clear split between shared logic and runtime adapters.

## Directory layout

```text
shared/<skill-name>/
└── references/          # canonical runtime-neutral material

claude/skills/<skill-name>/
├── SKILL.md             # Claude adapter
└── references/          # installable local copy of shared refs

codex/skills/<skill-name>/
├── SKILL.md             # Codex adapter
└── references/          # installable local copy of shared refs
```

## What goes where

- `shared/`: prompts, templates, heuristics, schemas, and other material that should stay identical across runtimes.
- `claude/skills/.../SKILL.md`: Claude-specific trigger text, tool assumptions, and workflow glue.
- `codex/skills/.../SKILL.md`: Codex-specific trigger text, tool assumptions, and workflow glue.
- `references/` under each runtime skill: an exact, synced copy of `shared/<skill-name>/references/`. **Runtime-specific reference files are not allowed here** — anything that differs per runtime belongs in the adapter's `SKILL.md`. The sync script enforces this by deleting any runtime copy that does not match a shared source.

## Naming

- Skill names are lowercase, kebab-case.
- Keep runtime adapters thin. Put heavy content in `shared/` first unless it is truly runtime-specific.

## SKILL.md frontmatter

Each runtime adapter must start with YAML frontmatter:

```markdown
---
name: <skill-name>
description: <when to trigger, what it produces, and example phrases>
---
```

`name` and `description` are mandatory. Keep the frontmatter minimal and runtime-portable; do not introduce runtime-specific fields unless both runtimes ignore unknown fields cleanly and the field is documented here.

## House rules

- Write the core workflow once, then adapt only the runtime-specific parts.
- Do not exfiltrate repo content through external tools.
- Keep outputs in English when the artifact is meant for audit, compliance, or cross-team review.
- Analysis skills should not modify application code as a side effect.
- If a skill maintains dated artifacts, append and supersede; do not rewrite history.

## Sync rule

When editing shared reference files for an existing skill:

1. Update `shared/<skill-name>/references/`.
2. Sync the same changes into:
   - `claude/skills/<skill-name>/references/`
   - `codex/skills/<skill-name>/references/`
3. Verify both runtime adapters still point to the correct local filenames.

This duplication is intentional so a runtime skill can be copied out and installed on its own.

Use `scripts/sync_shared_refs.sh` after editing shared references. CI checks that runtime copies match `shared/`.

## Testing before a PR

1. Test the runtime you have access to.
2. If you cannot test the other runtime, state that gap clearly in the PR so a maintainer can cover it.
3. Run the workflow on at least one real codebase outside the language used in examples.
4. Verify no external lookup sends repo content.
5. Verify the installed runtime skill still works when copied out of this repo.

## Opening a PR

- Update the top-level [README.md](./README.md) if you add a new skill.
- Update the runtime README if installation steps changed.
- Keep the adapters thin; avoid duplicating long procedural content unless required for installability.
