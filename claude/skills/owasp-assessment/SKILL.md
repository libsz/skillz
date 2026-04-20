---
name: owasp-assessment
description: Run an OWASP Top 10 (2025) security assessment of whatever codebase is at hand — any language, any stack — and produce a dated, versioned English report. Use when the user asks for a security assessment, OWASP review, vulnerability audit, codebase security analysis, security posture check, wants to refresh or update an OWASP report, or says things like "analyze security", "security findings", "run the owasp scan", or "check vulnerabilities".
---

# OWASP Assessment

Claude Code adapter for the OWASP assessment workflow. Authoritative standard: [OWASP Top 10 (2025)](https://owasp.org/Top10/2025/).

## Runtime notes

- Keep the common workflow in `references/`; this file should stay thin.
- Ask the user only when ambiguity changes scope or output location materially.
- When a user decision is needed inside Claude Code, use the runtime's question flow instead of inventing ad hoc prompts.
- Use parallel exploration aggressively: the default flow is three Explore subagents in parallel plus local CVE validation.

## Safety floor

`references/rules.md` is mandatory. Load it at Step 0 and apply every rule to every subsequent step. If that file cannot be loaded (missing, truncated, unreadable), refuse to run and tell the user — do not proceed with a partial rule set.

The following prohibitions are ALWAYS in effect, even before `rules.md` is loaded. They govern everything the skill does:

- **No repository content of any kind leaves this environment.** That includes source code, file paths, file or directory names, directory structure / file tree / repository layout, schemas, table or column names, configuration values, environment variables, stack traces, log lines, commit messages, internal service/domain names, business logic, customer/tenant/user names, and secrets in any form (full or partial).
- **External tools are used only for identifier-based lookups.** Valid inputs to WebFetch, WebSearch, Context7, Perplexity, or any MCP are limited to: public package names and versions, CVE IDs, CWE IDs, OWASP category names/slugs, public vendor names, and public reference URLs. Nothing else may appear in an external query.
- **Every external call is gated by the Query hygiene checklist in `rules.md`.** If a query cannot be phrased using the positive allowlist only, do not send it — do the analysis locally and record the gap in the report.
- **Default-deny for any tool not explicitly allowlisted in `rules.md`.** New MCPs that appear in the environment later do not automatically become eligible for external research.
- **Secrets are redacted in any output** (file:line plus at most a short non-functional prefix such as `AKIA...`).
- **Reports are written in the language the user chose at Step 0** (default: English; alternatives offered: Portuguese-BR, Spanish, French, or other on request). Universal identifiers (CWE/CVE/OWASP IDs, severity emoji, finding IDs, URLs) stay canonical regardless of language.
- **No application code is modified.**

If you are about to emit an external query and notice it contains a file path, a code fragment, a structural description of the repo, a schema name, or anything else from the prohibition list, abort the call, revise to identifier-only, and re-check. If you cannot, fall back to local analysis.

## Workflow

0. Load `references/rules.md` and apply every rule to all subsequent steps. Then load `references/scope_defaults.md` to establish what's in scope and which dev-only paths are skipped. Skipping these loads is not allowed.
1. Initialize the run and establish:
   - output directory (`<output_dir>`)
   - stack hint if needed (auto-detect manifests; ask only when ambiguous)
   - scope boundaries (defaults from `scope_defaults.md` plus user overrides)
   - report language (default English; offer Portuguese-BR, Spanish, French, plus an `other` free-text option — record in the metadata table's Language row)
2. Discover the most recent prior assessment in `<output_dir>`. Today's filename is `OWASP_ASSESSMENT_<YYYY-MM-DD>.md`; if that file already exists, ask the user whether to overwrite or bump a revision suffix (e.g., `_r2`).
3. Spawn three parallel Explore subagents using `references/explore_prompts.md`. Inject the effective exclusion list from Step 0 into each agent prompt.
4. Validate dependency CVEs using `references/cve_validation.md`. External queries are identifier-only, governed by `rules.md`.
5. Consolidate findings using `references/consolidation.md` — assign run-unique IDs, label confidence, handle dev-leak suspects, and apply the `⚠️ Active exploit risk` tag where all three criteria from `rules.md` hold.
6. Diff current findings against the previous assessment using `references/diff_heuristics.md`.
7. Write the new report using `references/document_template.md`, including the Data handling compliance attestation in §3.
8. Update only the immediately previous report's `Superseded by` link (per the immutability rule in `rules.md`).
9. Return a short summary to the user with the report path and delta counts. If any finding carries `⚠️ Active exploit risk`, advise coordinating with security on-call before sharing the report.

## Claude-specific expectations

- Prefer runtime-native subagents for the three analysis passes.
- If a subagent returns vague prose, re-prompt it for strict `file:line | severity | OWASP | confidence | evidence` output.
- Do not paste the report body into chat; the file is the artifact.

## Load order

- `references/rules.md` — before initialization (Step 0). Mandatory.
- `references/scope_defaults.md` — at initialization (Step 0) for scope and dev-only exclusions.
- `references/explore_prompts.md` — at the exploration phase (Step 3).
- `references/cve_validation.md` — at the dependency validation phase (Step 4).
- `references/consolidation.md` — at the consolidation phase (Step 5).
- `references/diff_heuristics.md` — at the diff phase (Step 6).
- `references/document_template.md` — at the writing phase (Step 7).
