# Consolidation rules

Load this file at Step 5 of the skill, after exploration and external research have produced raw findings. This file defines the **taxonomy** used in the final report: finding IDs, confidence labels, dev-leak promotion rules, and how duplicates are merged. It complements `rules.md` (governance) and `diff_heuristics.md` (baseline matching).

---

## Finding ID scheme

Consolidated findings use severity-prefixed, run-unique IDs:

- **Critical** → `C1`, `C2`, `C3`, …
- **High** → `H1`, `H2`, `H3`, …
- **Medium** → `M1`, `M2`, `M3`, …
- **Low** → `L1`, `L2`, `L3`, …

### Rules

- **IDs are per-run.** Do NOT reuse an ID from a previous report. Each report's IDs start fresh from 1 within each severity bucket.
- **Traceability across runs** lives in the "Status vs previous" column of the consolidated table (e.g., `→ Persisted (was H7)`), not in ID reuse. The matching logic is in `diff_heuristics.md`.
- **Multi-category findings** — a single finding that maps to more than one OWASP category appears in every relevant by-category table with the same ID. In the consolidated table, it gets **one row** with the categories slash-separated (e.g., `A02/A04/A07`).
- **Recommendations reference IDs** — the "Addresses" column in §7 Prioritized recommendations lists the same IDs used in §5 and §6. Cross-references must be consistent across all three sections.

---

## Confidence labels

Every finding carries a confidence label separate from severity. The label is a column in every findings table and the basis for triage effort.

- **Verified** — pattern confirmed by grep or direct code read. You can point to the exact line that exhibits the flaw.
- **Likely** — pattern present but the exploitation path has a gap (e.g., input is validated elsewhere but not in every caller). Worth fixing, worth verifying.
- **Inferred** — deduction from architectural smell or a single secondary signal. No direct code evidence. Requires human investigation before acting.

### Special rule: Inferred + Critical

A finding that is both **Inferred** and **Critical** must be flagged prominently in the Executive summary. That combination warrants immediate verification, not immediate action. Readers should not trigger incident response on an Inferred finding without reading the evidence first.

---

## Dev-leak handling

Exploration agents may prefix evidence lines with `dev-leak:` or `dev-leak?:` (as defined in `scope_defaults.md`). Treat them deliberately during consolidation:

- **`dev-leak:`** — the agent is confident the dev path reaches production. Verify once locally before including: read the deploy manifest, CI pipeline, or Dockerfile to confirm the file or directory is actually referenced in the prod build/deploy path.
  - If confirmed → promote to a regular finding with confidence `Verified`.
  - If disproven → drop the finding. Note nothing; this is noise.
- **`dev-leak?:`** — the agent suspects but could not verify. Record the finding with confidence `Inferred` and a `Dev-leak suspect` tag. Do NOT promote without human review. It goes into the report so the team can validate against their own knowledge of the deploy topology.
- **No prefix at all** on a finding from a path that matches the dev-only exclusions in `scope_defaults.md` — this should never have reached consolidation. If one slipped through, drop it.

### Presentation in the report

Dev-leak findings get their own short subsection inside each relevant OWASP category, titled **"Dev-leak suspects"**, so they are visually separated from direct prod findings. They still contribute to the severity counts **if promoted to `Verified`**; suspects-only contribute a parenthetical note (`+N dev-leak suspects`) but not to the headline count.

---

## Duplicate collapsing

Agents may report the same finding multiple times (same file:line, same pattern, different OWASP category perspectives). Consolidate:

- **Same file:line + same pattern** → one finding. If it spans multiple OWASP categories, list all of them (slash-separated) in the consolidated table's Category column.
- **Same pattern across multiple files** → separate findings if the files are independently exploitable. Keep as one finding only when it's a single function/module referenced from multiple call sites and the fix lives in one place.
- **Same category + similar description + adjacent paths** → one finding if it's a refactor spread; add a note ("present in N related controllers").

When in doubt, separate. It's easier for the recommendations phase to group later than to un-merge prematurely.

---

## Active exploit risk tag

The `⚠️ Active exploit risk` tag is defined in `rules.md` (criteria, banner text, confidentiality implications). Apply it here, during consolidation, to any finding that meets all three criteria:

1. Severity is Critical
2. Confidence is Verified
3. The vulnerable path is reachable from untrusted input today

If any finding carries this tag, the report's Executive summary must include the containment banner defined in `document_template.md` §1, and the user must be advised in the Step 9 summary to coordinate with security on-call before sharing the report.

---

## From consolidation to the report

Once consolidation is complete, you have:

- A list of findings with stable run-unique IDs, confidence labels, categories, evidence, and severity.
- Any `⚠️ Active exploit risk` tags applied.
- A dev-leak suspect subsection per relevant category.

Hand this structure off to Step 6 (diffing against baseline via `diff_heuristics.md`) and then Step 7 (writing the new report via `document_template.md`).