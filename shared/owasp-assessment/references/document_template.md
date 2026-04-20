# Output document template

Fill every section. Do not skip sections as "not applicable" — if a category is clean, say so explicitly with one line of justification. Keep language formal but not bureaucratic. Avoid adjectives like "significant", "major" without a number behind them.

**Prose language:** use the language the user selected at Step 0 (default `English`; alternatives `Portuguese-BR`, `Spanish`, `French`, or any `other` free-text choice). Universal identifiers — CWE IDs, CVE IDs, OWASP category slugs, severity emoji, finding IDs, URLs, and `file:line` evidence — stay canonical regardless of language. Record the chosen language in the metadata table's `Language` row so the convention is explicit for future readers and for any successor report in the chain.

---

## Template

```markdown
# OWASP Top 10 (2025) — Security Assessment
## <Project name>

> 🔒 **Confidential — internal use only.** This report is a roadmap to attack the system. Do NOT paste it into public GitHub issues, public Slack channels, external email threads, or share it with third parties. Treat it as restricted to the internal security and engineering teams.

| Metadata | Value |
|----------|-------|
| **Project** | <project name> |
| **Date** | <YYYY-MM-DD> |
| **Branch analyzed** | <git branch> |
| **Commit** | <short SHA> |
| **Stack** | <language + framework + DB + cache + container stack> |
| **Language** | <English \| Portuguese-BR \| Spanish \| French \| other> |
| **Reference** | OWASP Top 10 — 2025 |
| **Scope** | Codebase only (<list analyzed dirs>) |
| **Out of scope** | <what infra was excluded> |
| **Previous assessment** | <link to prior file, or "Initial baseline"> |
| **Superseded by** | _latest — no newer assessment yet_ |
| **Methodology** | Static analysis with 3 parallel exploration agents + CVE database consultation |

---

## 1. Executive summary

<2–4 sentences stating overall posture and the 2–3 most urgent areas>

> **If any finding carries `⚠️ Active exploit risk`, insert this banner here (otherwise omit it):**
>
> > ⚠️ **Active exploit risk identified.** This report contains `<N>` finding(s) that represent currently-exploitable conditions (see IDs: `<list>`). Before committing this report to a shared branch, hand it to the security on-call channel so rotation and containment can happen first. Do NOT post these findings or their evidence in public channels (issues, Slack, email threads) until the active risk is contained.

### Findings by severity

| Severity | Count |
|----------|------:|
| 🔴 Critical | <n> |
| 🟠 High | <n> |
| 🟡 Medium | <n> |
| 🟢 Low | <n> |
| **Total** | **<n>** |

### Conformance table by OWASP category

| # | Category | Status | Aggregate severity | Findings |
|---|----------|--------|--------------------|---------:|
| A01 | Broken Access Control | ❌ Non-conformant / ⚠️ Partial / ✅ Conformant | <sev> | <n> |
| A02 | Security Misconfiguration | … | … | … |
| A03 | Software Supply Chain Failures | … | … | … |
| A04 | Cryptographic Failures | … | … | … |
| A05 | Injection | … | … | … |
| A06 | Insecure Design | … | … | … |
| A07 | Authentication Failures | … | … | … |
| A08 | Software/Data Integrity Failures | … | … | … |
| A09 | Logging & Alerting Failures | … | … | … |
| A10 | Server-Side Request Forgery | … | … | … |

> **Legend:** ✅ Conformant · ⚠️ Partial · ❌ Non-conformant

---

## 2. Changes since previous assessment

> **First run?** Replace this entire section with:
> `> This is the initial baseline. No previous assessment to compare.`

Previous assessment: <link> · Date: <previous date> · Delta window: <previous date> → <today>

### Summary of deltas

| Bucket | Count |
|--------|------:|
| ✓ Resolved (fixed since previous) | <n> |
| ★ New (not in previous) | <n> |
| ↑ Escalated (severity up) | <n> |
| ↓ De-escalated (severity down) | <n> |
| → Persisted (same severity) | <n> |

### Resolved

| Prev ID | Category | Description | Prev severity | Evidence of resolution |
|---------|----------|-------------|---------------|-----------------------|
| <old id> | … | … | … | <commit / file no longer present / pattern removed> |

### New

| New ID | Category | Description | Evidence | Severity |
|--------|----------|-------------|----------|----------|
| <id> | … | … | <file:line> | 🔴 / 🟠 / 🟡 / 🟢 |

### Escalated / De-escalated

| Prev ID → New ID | Category | Description | Previous | Current | Trigger |
|------------------|----------|-------------|----------|---------|---------|
| … → … | … | … | 🟡 Medium | 🟠 High | <what changed — more exploitation surface, new CVE, etc.> |

### Persisted

| Prev ID → New ID | Category | Description | Severity | Evidence |
|------------------|----------|-------------|----------|----------|
| … → … | … | … | 🔴 / 🟠 / 🟡 / 🟢 | <file:line> |

### Trajectory

<One paragraph stating: overall the codebase improved / stagnated / regressed, which area moved most, and what to watch next time.>

---

## 3. Methodology

Static analysis only, based on a snapshot of branch `<branch>` at commit `<sha>` on <date>. Three specialized exploration agents ran in parallel:

1. **Agent A** — A01 Broken Access Control + A07 Authentication Failures
2. **Agent B** — A03 Supply Chain + A04 Cryptographic + A05 Injection + A10 SSRF
3. **Agent C** — A02 Misconfiguration + A06 Insecure Design + A08 Integrity + A09 Logging

Supporting activities:

- Pattern searches via `grep`/`ripgrep` in `<list of directories>`.
- CVE cross-check against public advisory databases (Snyk, GitHub Advisory, NVD) for pinned dependencies.
- Severity classified by effective exposure within the application context.

### Data handling compliance

All external lookups performed during this assessment used **public identifiers only** — package names and versions, CVE/CWE IDs, OWASP category names, public vendor names, and public reference URLs. **No repository content** (source code, file paths, directory structure, schemas, configuration, logs, secrets, or customer data) was transmitted to any external service (WebFetch, WebSearch, Context7, Perplexity, or any MCP). Where a question could not be answered with an identifier-only query, analysis was performed locally and the coverage gap is noted under Limitations or Scope.

### Limitations

- No dynamic analysis (DAST, fuzzing, pentest).
- Some `file:line` references are representative of a repeated pattern — global `grep` recommended before remediation.
- Network infrastructure explicitly out of scope.
- Point-in-time snapshot; changes after this date are not reflected.

---

## 4. Scope

### Included
<bulleted list of analyzed directories and files>

### Excluded
<bulleted list — e.g., TLS at load balancer, WAF, CDN, secrets manager, IAM>

---

## 5. Findings by OWASP category

For each A01..A10 repeat this block. **The category heading must be a Markdown link to the OWASP Top 10 (2025) page for that category** — that link serves as the primary reference inherited by every finding beneath it.

### [A0X:2025 — <Category name>](https://owasp.org/Top10/2025/A0X_2025-<Slug>/)
**Status:** ❌ Non-conformant / ⚠️ Partial / ✅ Conformant · **Aggregate severity:** <sev>

> <one-line OWASP description of the category>

| # | Finding | Evidence | Severity | Confidence | CWE |
|---|---------|----------|----------|------------|-----|
| <id> | <short description> | `<file:line>` | 🔴/🟠/🟡/🟢 | Verified/Likely/Inferred | [CWE-xxx](https://cwe.mitre.org/data/definitions/xxx.html) |

**Plain-language impact:** <2–4 sentences in non-technical language explaining what this means for customers and operations.>

*Optional additional references (authoritative only — see SKILL.md):*
> _Additional references for this category:_ [OWASP Cheat Sheet — Topic](https://cheatsheetseries.owasp.org/cheatsheets/Topic_Cheat_Sheet.html), [NIST SP 800-XXX](https://csrc.nist.gov/publications/detail/sp/800-XXX/final)

If the category is clean, use:
> No findings in this assessment. <One sentence on what was checked to reach that conclusion.>

---

## 6. Consolidated findings table

Ordered by severity (Critical → Low). Cross-reference columns to the by-category tables.

| ID | Category | Description | Evidence | Severity | CWE | Status vs previous |
|----|----------|-------------|----------|----------|-----|--------------------|
| <id> | <A0X/A0Y> | <short desc> | `<file:line>` | 🔴/🟠/🟡/🟢 | CWE-xxx | ★ New / → Persisted / ↑ Escalated / ↓ De-escalated |

> `Status vs previous` column is empty on the first baseline run.

---

## 7. Prioritized recommendations

> **Ordered by severity — no timelines.** A single recommendation may address multiple findings; the mapping is explicit.

### 🔴 Critical priority

| # | Addresses | Recommendation | Benefit |
|---|-----------|----------------|---------|
| R1 | <ids> | <prose recommendation, no code snippets> | <outcome> |

### 🟠 High priority

| # | Addresses | Recommendation | Benefit |
|---|-----------|----------------|---------|
| … | … | … | … |

### 🟡 Medium priority

| # | Addresses | Recommendation | Benefit |
|---|-----------|----------------|---------|
| … | … | … | … |

### 🟢 Low priority / hygiene

| # | Addresses | Recommendation | Benefit |
|---|-----------|----------------|---------|
| … | … | … | … |

---

## 8. Dependencies with known CVEs

| Package | Current version | CVE / Advisory | Severity | Suggested action |
|---------|-----------------|----------------|----------|------------------|
| <pkg> | <ver> | [CVE-xxxx-xxxxx](https://…) — <short> | Low/Med/High/Crit | <what to do> |

> Final confirmation should come from the language-appropriate audit tool in the pipeline (e.g., `npm audit`, `pip-audit`, `composer audit`, `bundler-audit`, `govulncheck`, `cargo audit`).

---

## 9. Verification plan

### Static analysis / CI
- <specific check, mapped to R<n>>

### Automated tests
- <specific test mapped to R<n>>

### Manual review
- <specific manual review step>

### Runtime
- <specific runtime verification>

---

## 10. References

- [OWASP Top 10 — 2025](https://owasp.org/Top10/)
- [CWE (Common Weakness Enumeration)](https://cwe.mitre.org/)
- [NVD — National Vulnerability Database](https://nvd.nist.gov/)
- <other links used in findings>

---

## 11. Appendix — critical files for manual review

<code-block list of file paths cited in findings>

---

## Final caveats

- Static analysis snapshot of `<branch>` at `<sha>` on <date>.
- Manually validate every `file:line` citation before applying a fix — some are representative of a repeated pattern.
- No code changes were made during preparation of this report.
```

---

## Notes when filling the template

- **Consistency of severity emoji** — always 🔴 Critical / 🟠 High / 🟡 Medium / 🟢 Low. Don't switch to words mid-document.
- **CWE IDs** — cite the primary CWE per finding. Multiple CWEs allowed, comma-separated.
- **Cross-referencing IDs between sections** — the same finding ID (C1, H3…) must appear identically in (a) the by-category table, (b) the consolidated table, and (c) the recommendations table's "Addresses" column.
- **Persisted findings** — carry the old ID forward in the "Status vs previous" column as `→ Persisted (was <old id>)`, but the primary ID in the new report is the fresh one. This keeps every report self-consistent while making the chain traversable.
- **Plain-language impact** — written for product owners, legal, compliance. No file paths, no abbreviations, no CWE numbers in that paragraph.

---

## Authoritative references policy

Every finding must cite at least one primary authoritative reference. A finding without a reference is unactionable because the reader has no way to study the class of vulnerability beyond the evidence line.

### Primary reference — required, always

The OWASP Top 10 (2025) page for the category the finding maps to. URL pattern:

```
https://owasp.org/Top10/2025/A0X_2025-<Slug>/
```

Slugs for the 2025 list:

- A01 → `Broken_Access_Control`
- A02 → `Security_Misconfiguration`
- A03 → `Software_Supply_Chain_Failures`
- A04 → `Cryptographic_Failures`
- A05 → `Injection`
- A06 → `Insecure_Design`
- A07 → `Authentication_Failures`
- A08 → `Software_or_Data_Integrity_Failures`
- A09 → `Security_Logging_and_Alerting_Failures`
- A10 → `Server-Side_Request_Forgery_(SSRF)`

Apply the primary reference two ways:

1. Make the **category heading in §5** a Markdown link to the OWASP page. Every finding beneath that heading inherits the primary reference.
2. In §6 Consolidated findings, link the category cell for any finding that spans multiple categories (e.g., `[A04](https://owasp.org/Top10/2025/A04_2025-Cryptographic_Failures/)`).

### Secondary references — required when applicable

- **CWE** — if the finding has a CWE, render the ID as a link to the MITRE page: `https://cwe.mitre.org/data/definitions/<NUM>.html` (e.g., CWE-89 → `https://cwe.mitre.org/data/definitions/89.html`). Every CWE cell in every findings table gets this treatment.
- **CVE** — if the finding cites a CVE, render the ID as a link to NVD (`https://nvd.nist.gov/vuln/detail/<CVE-ID>`) or the GitHub Advisory Database (`https://github.com/advisories/<GHSA-ID>`). Apply in the A03 findings table and in §8 Dependencies with known CVEs.

### Additional references — optional, authoritative only

A finding may include a trailing italic `_Additional references:_` line with extra links. These must come from **authoritative** sources only:

- Official library / framework documentation or upstream repository (vendor docs, maintained package READMEs).
- OWASP Cheat Sheet Series (`https://cheatsheetseries.owasp.org/`).
- Vendor security advisories (Stripe, AWS, Google Cloud, GitHub Security Lab; disclosed HackerOne reports on the vendor's own side).
- NIST publications (SP 800-series), IETF RFCs.
- MITRE ATT&CK or CAPEC pages.

### Forbidden as reference sources

Never cite these in a security assessment:

- Blog posts, Medium articles, third-party tutorials.
- Stack Overflow and similar Q&A answers.
- Commercial marketing or sales pages.
- AI-generated summaries without a primary source.
- Any link that requires authentication or is not publicly reachable.

If no authoritative additional source is available, omit the additional-references line entirely. Pad-filling with weak sources degrades the report's credibility.

Reference discipline also applies to §7 Recommendations and §9 Verification plan when they assert a specific standard — e.g., a recommendation to migrate to `argon2id` should link the OWASP Password Storage Cheat Sheet as an additional reference.