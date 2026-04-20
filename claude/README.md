# Claude Code

Claude adapters live under `claude/skills/`. The `owasp-assessment` skill follows the [OWASP Top 10 (2025)](https://owasp.org/Top10/2025/) standard end-to-end.

---

## 1. Clone this repository

```bash
git clone https://github.com/libsz/skillz.git
cd skillz
```

Every command below assumes you're inside the `skillz/` working copy.

## 2. Install the `owasp-assessment` skill

Skills in Claude Code are directories named after the skill, placed under either `.claude/skills/` (project scope) or `~/.claude/skills/` (user scope). Pick one scope and run the matching block.

### Project scope — committed alongside a project

Run this **inside the target project's root** (not inside `skillz/`). Replace `/path/to/skillz` with the absolute path to your clone.

```bash
SKILLZ=/path/to/skillz
mkdir -p .claude/skills/owasp-assessment/references
cp "$SKILLZ/claude/skills/owasp-assessment/SKILL.md" .claude/skills/owasp-assessment/
cp -R "$SKILLZ/claude/skills/owasp-assessment/references/." .claude/skills/owasp-assessment/references/
```

After this, `.claude/skills/owasp-assessment/` is self-contained; you can commit it so the team gets the skill on checkout.

### User scope — available in every project

Run this anywhere; the skill lands in your home Claude config.

```bash
SKILLZ=/path/to/skillz
mkdir -p ~/.claude/skills/owasp-assessment/references
cp "$SKILLZ/claude/skills/owasp-assessment/SKILL.md" ~/.claude/skills/owasp-assessment/
cp -R "$SKILLZ/claude/skills/owasp-assessment/references/." ~/.claude/skills/owasp-assessment/references/
```

## 3. (Recommended) Install MCP servers for fresh external data

The skill works without these, but reports are materially sharper when Claude Code can reach current library docs and freshly-disclosed advisories. Queries to these services are restricted by the skill's own rules to **public identifiers only** (package name, version, CVE/CWE/OWASP IDs, public vendor names) — no repository content is ever sent.

- **[Context7](https://github.com/upstash/context7)** — up-to-date library and framework documentation on demand.
- **[Perplexity Ask](https://github.com/perplexityai/modelcontextprotocol)** — web-grounded research with citations for recent CVEs and advisories that post-date the model's training cutoff.

Install commands:

```bash
# Context7 (interactive setup: OAuth + API key + Claude Code registration)
npx ctx7 setup --claude

# Perplexity Ask (needs an API key from https://www.perplexity.ai/account/api/group)
claude mcp add perplexity \
  --env PERPLEXITY_API_KEY="your_key_here" \
  -- npx -y @perplexity-ai/mcp-server
```

Restart Claude Code after either install.

## 4. Verify the install

Open Claude Code inside the project where you installed the skill (or any project, if you used user scope) and run:

```
/skills
```

You should see `owasp-assessment` in the list with its description. To confirm the MCPs:

```
/mcp
```

`context7` and `perplexity` (if you installed them) should appear as connected servers.

## 5. Use the skill

The skill triggers automatically when you ask Claude Code for a security review. Examples:

- `run an OWASP assessment on this repo`
- `do a security review of the codebase`
- `check our injection posture`
- `update the OWASP report` (after a previous run exists — this triggers the diff path)
- `has our security posture improved since last time?`

You can also invoke it explicitly:

- `use the owasp-assessment skill to audit this repo`

### What happens on a first run

1. The skill asks where to write the report (default `docs/security/`), detects the stack from the repo's manifest files, and confirms scope (dev-only paths skipped by default).
2. It asks you for the **report language** — closed list `English`, `Portuguese-BR`, `Spanish`, `French`, plus an `other` free-text option (default `English`).
3. It runs three parallel exploration agents covering all ten OWASP categories, validates dependency CVEs identifier-only, and writes a dated Markdown report with a conformance table, per-category findings with `file:line` evidence, a consolidated severity-sorted table, prioritized recommendations, and a list of dependencies with known CVEs.

### What happens on subsequent runs

The skill finds the previous `OWASP_ASSESSMENT_YYYY-MM-DD.md`, diffs against it, and produces a new dated file whose first section is **Changes since previous assessment** (resolved / new / escalated / persisted). The previous file is edited only to add a `Superseded by:` link back to the new one.

## Uninstall

Delete the skill directory. Project scope:

```bash
rm -rf .claude/skills/owasp-assessment
```

User scope:

```bash
rm -rf ~/.claude/skills/owasp-assessment
```