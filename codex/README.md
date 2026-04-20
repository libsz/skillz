# Codex

Codex adapters live under `codex/skills/`. The `owasp-assessment` skill follows the [OWASP Top 10 (2025)](https://owasp.org/Top10/2025/) standard end-to-end.

---

## 1. Clone this repository

```bash
git clone https://github.com/libsz/skillz.git
cd skillz
```

Every command below assumes you're inside the `skillz/` working copy. The variable `$CODEX_HOME` refers to your Codex configuration home (commonly `~/.codex`); export it or substitute the real path before running the install commands.

## 2. Install the `owasp-assessment` skill

Codex skills are directories named after the skill, placed under your Codex skills root. Pick user scope (available everywhere) or project scope (committed with a specific repo) and run the matching block.

### User scope

```bash
SKILLZ=/path/to/skillz
export CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
mkdir -p "$CODEX_HOME/skills/owasp-assessment/references"
cp "$SKILLZ/codex/skills/owasp-assessment/SKILL.md" "$CODEX_HOME/skills/owasp-assessment/"
cp -R "$SKILLZ/codex/skills/owasp-assessment/references/." "$CODEX_HOME/skills/owasp-assessment/references/"
```

### Project scope

If your Codex setup supports project-local skills, run the same mkdir/cp sequence targeting that project's local skills directory instead of `$CODEX_HOME/skills/`. Consult your Codex environment documentation for the exact path it reads.

After either install, the `owasp-assessment/` directory is self-contained.

## 3. (Recommended) Connect external data sources for fresh library docs and CVEs

The skill works without these, but reports are materially sharper when Codex can reach current library docs and freshly-disclosed advisories. The skill's own rules restrict external queries to **public identifiers only** (package name, version, CVE/CWE/OWASP IDs, public vendor names) — no repository content is ever sent.

- **[Context7](https://github.com/upstash/context7)** — up-to-date library and framework documentation. Install instructions on the upstream repo.
- **[Perplexity Ask](https://github.com/perplexityai/modelcontextprotocol)** — web-grounded research for recent CVEs and advisories. Install instructions on the upstream repo.

Install the Codex-compatible versions of these connectors following each project's upstream README and your Codex environment's MCP or connector registration flow. Keep the same policy boundary as the Claude adapter: public identifiers only, never repo content.

## 4. Verify the install

Open Codex inside your project and list available skills (command depends on your Codex surface — typically a `/skills` or equivalent listing). `owasp-assessment` should appear with its description.

## 5. Use the skill

Ask Codex for a security review. Examples:

- `run an OWASP assessment on this repo`
- `do a security review of the codebase`
- `check our injection posture`
- `update the OWASP report` (when a previous run exists — triggers the diff path)
- `has our security posture improved since last time?`

Explicit invocation:

- `use the owasp-assessment skill to audit this repo`

### First run

1. The skill asks for the output directory (default `docs/security/`), detects the stack from manifest files, and confirms scope (dev-only paths skipped by default).
2. It asks for the **report language** — closed list `English`, `Portuguese-BR`, `Spanish`, `French`, plus `other` free-text (default `English`).
3. It runs three focused analysis passes across the OWASP Top 10, validates dependency CVEs identifier-only, and writes a dated Markdown report with a conformance table, per-category findings with `file:line` evidence, a consolidated severity-sorted table, prioritized recommendations, and a list of dependencies with known CVEs.

### Subsequent runs

The skill finds the previous `OWASP_ASSESSMENT_YYYY-MM-DD.md`, diffs against it, and produces a new dated file whose first section is **Changes since previous assessment** (resolved / new / escalated / persisted). The previous file is edited only to add a `Superseded by:` link back to the new one.

## Uninstall

```bash
rm -rf "$CODEX_HOME/skills/owasp-assessment"
```

(or the project-scope equivalent path).