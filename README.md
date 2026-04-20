# skillz

A collection of language-agnostic agent skills for multiple coding runtimes.

This repository now separates:

- `shared/` — runtime-neutral material such as prompts, templates, and heuristics
- `claude/` — Claude Code adapters and install docs
- `codex/` — Codex adapters and install docs

The goal is to keep the security methodology portable while letting each runtime keep its own trigger text, tool assumptions, and installation path.

## Skills

### Security

- `owasp-assessment` — Run an [OWASP Top 10 (2025)](https://owasp.org/Top10/2025/) security assessment of any codebase and produce a dated, versioned English report with baseline diffing.

  Each run produces a single dated Markdown file under a project-chosen directory (default `docs/security/`) containing: a conformance table across A01–A10, findings per category with `file:line` evidence and CWE links, a consolidated findings table ordered by severity, prioritized recommendations, a list of dependencies with known CVEs, and — from the second run onward — an explicit diff against the previous assessment (resolved / new / escalated / persisted). Reports are stack-agnostic and written in the language chosen at runtime (`English` default, `Portuguese-BR`, `Spanish`, `French`, or any other on request). For a clean diff across runs, stick to one language per chain of reports.

  Example output: [shared/owasp-assessment/examples/OWASP_ASSESSMENT_EXAMPLE.md](./shared/owasp-assessment/examples/OWASP_ASSESSMENT_EXAMPLE.md)

## Repository layout

```text
.
├── LICENSE
├── README.md
├── CONTRIBUTING.md
├── .github/
│   └── workflows/
│       └── check-shared-sync.yml      # CI: verifies runtime copies match shared/
├── scripts/
│   └── sync_shared_refs.sh            # local: sync shared/ → runtime adapters
├── shared/
│   └── <skill-name>/
│       └── references/                # canonical runtime-neutral material
├── claude/
│   ├── README.md
│   └── skills/
│       └── <skill-name>/
│           ├── SKILL.md
│           └── references/            # exact copy of shared/<skill-name>/references/
└── codex/
    ├── README.md
    └── skills/
        └── <skill-name>/
            ├── SKILL.md
            └── references/            # exact copy of shared/<skill-name>/references/
```

## Design principles

- Runtime-neutral analysis logic belongs in `shared/`.
- Runtime-specific trigger wording and tool assumptions belong in `claude/` or `codex/`.
- Installed skills should remain self-contained, so each runtime keeps a local `references/` copy even when `shared/` is the canonical source in-repo.
- Reports and artifacts stay in English regardless of input language.
- External lookups must never exfiltrate repo content; only public identifiers may leave the environment.
- The current layout is an investment in portability. With one skill it adds maintenance overhead; it pays off as more runtimes and skills land.

## Runtime guides

- Claude Code: [claude/README.md](./claude/README.md)
- Codex: [codex/README.md](./codex/README.md)

## Canonical source for skill references

For every skill in this repo, `shared/<skill-name>/references/` is the single source of truth for runtime-neutral material — prompts, templates, heuristics, rules, schemas, and any other file type you need to ship with the skill. Each runtime adapter under `claude/skills/<skill-name>/references/` and `codex/skills/<skill-name>/references/` keeps a byte-identical copy so the installed skill stays self-contained.

When files under `shared/` change:

1. Run `scripts/sync_shared_refs.sh` — it discovers every skill under `shared/*/references/` and mirrors the full contents (any extension, including nested directories) into every runtime adapter.
2. CI (`.github/workflows/check-shared-sync.yml`) verifies the same invariant on every pull request and push, and fails if any runtime copy drifts from `shared/`.

The sync machinery is generic. Adding a new skill is `mkdir -p shared/<new-skill>/references/`, dropping the canonical files in, and running the sync script — no edits to the script or the workflow needed.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

MIT — see [LICENSE](./LICENSE).
