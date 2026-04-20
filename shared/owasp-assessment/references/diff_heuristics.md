# Diff heuristics — matching findings across assessments

This is Step 6 of the skill. The goal is to classify each current finding as **Resolved**, **New**, **Persisted**, or **Severity changed** relative to the previous assessment. The IDs used in each report are local to that report — the traceability comes from the matching logic below, not from stable IDs.

---

## Matching order

Apply the following rules **in order** for every current finding. The first rule that matches wins.

### Rule 1 — Exact evidence match (highest confidence)

Current finding and previous finding share:
- The **same OWASP category** (at least one category in common if multi-category)
- The **same file path** in evidence (line number may drift)

→ Classify as **Persisted** (same severity) or **Escalated/De-escalated** (different severity).

**Why this rule is first:** file paths are the most durable fingerprint across code churn. A line number shift from `:72` to `:89` because of an unrelated edit doesn't mean the finding is new — the vulnerability is still in `middleware/auth_token_check.ext`. If you match on `file:line` exactly, you will keep re-filing the same finding as "new" and "resolved" in alternating reports.

### Rule 2 — Description match with close file path (medium confidence)

Current finding and previous finding share:
- The **same OWASP category**
- A **substring match of the description** (e.g., both mention "SQL injection via interpolation")
- Evidence files in the **same directory tree** or one is clearly a refactor of the other (e.g., `controllers/AdminReportsController.ext` → `controllers/Admin/ReportsController.ext`)

→ Classify as **Persisted (refactored location)** — keep the old description, update the evidence to the new path.

**Why this exists:** during refactoring, file paths change but the underlying flaw doesn't. Without this rule, refactors look like a giant spike of "resolved" + "new" findings.

### Rule 3 — Same category + same short pattern (low confidence)

Current finding and previous finding share:
- The **same OWASP category**
- A **characteristic pattern** (e.g., both are "hardcoded JWT secret", both are "webhook without HMAC")

→ Classify as **Persisted (pattern)**. Flag for human review in the output because confidence is lower.

### Rule 4 — No match

Current finding has no analog in the baseline → **New** (`★`).

Baseline finding has no analog in the current report → **Resolved** (`✓`).

---

## Severity change detection

For any finding classified as Persisted under rules 1–3, compare severity:

| Previous → Current | Classification |
|--------------------|----------------|
| Critical → Critical | → Persisted |
| Critical → High | ↓ De-escalated |
| High → Critical | ↑ Escalated |
| Medium → High | ↑ Escalated |
| Low → Critical | ↑ Escalated (flag as surprising — re-verify) |
| anything → Low | ↓ De-escalated |

Severity should change only when exposure actually changed (new library CVE, newly-exposed endpoint, more untrusted code paths reaching the sink). A change from "oh I saw this more clearly now" is not a real severity change — keep the previous.

---

## Resolution validation

Before classifying a previous finding as **Resolved**, verify the fix actually landed:

1. Read the file and line cited in the baseline. Does the vulnerable pattern still exist?
2. If the file no longer exists, is the function it contained moved elsewhere? Grep for the distinctive string (function name, variable, SQL fragment).
3. If the pattern genuinely is gone, it's Resolved.
4. If the file exists but the line drifted, the finding is Persisted under Rule 1, not Resolved.

**Common false-positive for Resolved:**

- File was renamed or moved — run `git log --follow` on the old path before declaring resolved.
- Code was commented out rather than removed — still Persisted.
- Fix is partial (one of N call sites fixed) — Persisted with downgraded severity.

Each Resolved finding in the output must cite evidence of resolution in the table's last column: the commit SHA that fixed it if discoverable, or "pattern not found in current codebase — verified by grep `<pattern>`".

---

## Worked examples

Filenames below are illustrative placeholders; substitute whatever your codebase actually uses. The `.ext` suffix stands for the language's native source extension (`.php`, `.js`, `.py`, `.go`, `.rb`, `.java`, `.cs`, `.rs`, etc.).

### Example 1 — clear persist

Previous:
```
H7 | A07/A08 | Webhook via API key in URL path | routes/external_integrations.ext | High
```

Current grep on `routes/external_integrations.ext`: pattern `{apiKey:[a-zA-Z0-9=_-]+}` still present.

**Classification:** Persisted → new ID in current report (e.g., `H4`), "Status vs previous" column says `→ Persisted (was H7)`.

### Example 2 — resolution with verification

Previous:
```
C1 | A02 | .env committed with live credentials | .env (git history) | Critical
```

Current: `.env` no longer in `git ls-files`, `.gitignore` contains `.env`, secret-rotation PR found in `git log --all --grep="rotate credentials"`.

**Classification:** Resolved. Evidence of resolution: "`.env` removed from tracking in commit `<sha>`; `gitleaks` scan in CI introduced in commit `<sha>`."

### Example 3 — escalation

Previous:
```
M4 | A04 | AES-CTR with externally-provided IV | models/UserToken.ext:378 | Medium
```

Current: new code path discovered where the same `UserToken` class is called from a public endpoint that accepts attacker-chosen data. Vulnerability same, exposure wider.

**Classification:** ↑ Escalated M→H. Severity column in "Escalated" table: Medium → High. Trigger column: "now reachable from public endpoint `<path>`".

### Example 4 — refactored location

Previous:
```
C4 | A05 | SQL injection via interpolation | controllers/AdminReportsController.ext:739 | Critical
```

Current: `controllers/AdminReportsController.ext` no longer exists, but `controllers/Admin/ReportsController.ext` does and still has the same raw-query interpolation (e.g., `"SELECT … {$id} …"`).

**Classification:** Persisted (refactored location). Evidence updated to new path. Note the move in the "Status vs previous" column.

---

## What NOT to do

- Do not use the previous report's ID in the new report. Finding IDs reset each run. The chain is preserved through the "Status vs previous" column, not through ID reuse.
- Do not mark a finding as Resolved just because an agent didn't report it this run. Verify by reading the file or grepping for the pattern. Agents can miss things.
- Do not silently drop findings. Every baseline finding must appear in exactly one of the four buckets in the "Changes" section.
- Do not classify a rewording as Escalated. A finding whose severity went from Medium to High only because the assessor phrased it more urgently is not an escalation.