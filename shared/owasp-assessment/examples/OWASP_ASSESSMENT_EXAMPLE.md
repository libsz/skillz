# OWASP Top 10 (2025) — Security Assessment
## Example SaaS API

> 🔒 **Confidential — internal use only.** This report is a roadmap to attack the system. Do NOT paste it into public GitHub issues, public Slack channels, external email threads, or share it with third parties. Treat it as restricted to the internal security and engineering teams.

| Metadata | Value |
|----------|-------|
| **Project** | Example SaaS API |
| **Date** | 2026-04-19 |
| **Language** | English |
| **Branch analyzed** | `main` |
| **Commit** | `4f8c2b1` |
| **Stack** | Node.js + Express + PostgreSQL + Redis + Docker |
| **Reference** | OWASP Top 10 — 2025 |
| **Scope** | Codebase only (`src/`, `config/`, `migrations/`, `.github/workflows/`, `Dockerfile`) |
| **Out of scope** | Cloud IAM, WAF, CDN, load balancer TLS, secrets manager |
| **Previous assessment** | [OWASP_ASSESSMENT_2026-02-10.md](./OWASP_ASSESSMENT_2026-02-10.md) |
| **Superseded by** | _latest — no newer assessment yet_ |
| **Methodology** | Static analysis with 3 parallel exploration agents + CVE database consultation |

---

## 1. Executive summary

The application remains **partially conformant** with OWASP Top 10 (2025), with the highest current risks concentrated in injection, access control, and integrity validation around webhook handling. Two previously reported medium-severity issues were resolved, but three new high-severity findings were introduced in recently-added integration endpoints. The most urgent work is to eliminate raw SQL interpolation, enforce object-level authorization consistently, and add signature verification to external webhook handlers.

> > ⚠️ **Active exploit risk identified.** This report contains `2` finding(s) that represent currently-exploitable conditions (see IDs: `C1`, `H2`). Before committing this report to a shared branch, hand it to the security on-call channel so rotation and containment can happen first. Do NOT post these findings or their evidence in public channels (issues, Slack, email threads) until the active risk is contained.

### Findings by severity

| Severity | Count |
|----------|------:|
| 🔴 Critical | 1 |
| 🟠 High | 4 |
| 🟡 Medium | 3 |
| 🟢 Low | 2 |
| **Total** | **10** |

### Conformance table by OWASP category

| # | Category | Status | Aggregate severity | Findings |
|---|----------|--------|--------------------|---------:|
| A01 | Broken Access Control | ❌ Non-conformant | High | 2 |
| A02 | Security Misconfiguration | ⚠️ Partial | Medium | 1 |
| A03 | Software Supply Chain Failures | ⚠️ Partial | Medium | 1 |
| A04 | Cryptographic Failures | ⚠️ Partial | High | 1 |
| A05 | Injection | ❌ Non-conformant | Critical | 2 |
| A06 | Insecure Design | ⚠️ Partial | Medium | 1 |
| A07 | Authentication Failures | ⚠️ Partial | Low | 1 |
| A08 | Software/Data Integrity Failures | ❌ Non-conformant | High | 1 |
| A09 | Logging & Alerting Failures | ⚠️ Partial | Low | 1 |
| A10 | Server-Side Request Forgery | ✅ Conformant | None | 0 |

> **Legend:** ✅ Conformant · ⚠️ Partial · ❌ Non-conformant

---

## 2. Changes since previous assessment

Previous assessment: [OWASP_ASSESSMENT_2026-02-10.md](./OWASP_ASSESSMENT_2026-02-10.md) · Date: 2026-02-10 · Delta window: 2026-02-10 → 2026-04-19

### Summary of deltas

| Bucket | Count |
|--------|------:|
| ✓ Resolved (fixed since previous) | 2 |
| ★ New (not in previous) | 3 |
| ↑ Escalated (severity up) | 1 |
| ↓ De-escalated (severity down) | 0 |
| → Persisted (same severity) | 4 |

### Resolved

| Prev ID | Category | Description | Prev severity | Evidence of resolution |
|---------|----------|-------------|---------------|-----------------------|
| M2 | A02 | Debug mode enabled in production container config | Medium | `NODE_ENV=production` enforced; debug flag removed from deployment manifest |
| L1 | A09 | Missing audit log on password reset request | Low | Audit event added in `src/controllers/auth/resetPassword.ts` |

### New

| New ID | Category | Description | Evidence | Severity |
|--------|----------|-------------|----------|----------|
| H3 | A08 | Webhook handler accepts unsigned requests | `src/routes/webhooks/partner.ts:34` | 🟠 High |
| H4 | A01 | Tenant invoice endpoint lacks ownership check | `src/controllers/invoices/show.ts:52` | 🟠 High |
| M3 | A03 | GitHub Action uses floating tag instead of pinned SHA | `.github/workflows/deploy.yml:18` | 🟡 Medium |

### Escalated / De-escalated

| Prev ID → New ID | Category | Description | Previous | Current | Trigger |
|------------------|----------|-------------|----------|---------|---------|
| M1 → H2 | A05 | Raw SQL interpolation in reporting endpoint | 🟡 Medium | 🟠 High | Endpoint is now reachable from authenticated tenant users rather than admin-only staff |

### Persisted

| Prev ID → New ID | Category | Description | Severity | Evidence |
|------------------|----------|-------------|----------|----------|
| C1 → C1 | A05 | SQL injection in search API | 🔴 Critical | `src/controllers/search.ts:88` |
| H5 → H1 | A04 | Hardcoded JWT signing fallback secret | 🟠 High | `src/lib/jwt.ts:14` |
| H6 → H5 | A01 | IDOR on file download route | 🟠 High | `src/controllers/files/download.ts:61` |
| M4 → M1 | A06 | No rate limiting on invite endpoint | 🟡 Medium | `src/routes/invitations.ts:12` |

### Trajectory

The codebase improved modestly in configuration hygiene and audit logging, but overall posture **stagnated** because new integration and tenant-facing endpoints introduced fresh high-severity issues. The largest movement was in A01/A05, where previously contained patterns are now exposed on broader request paths.

---

## 3. Methodology

Static analysis only, based on a snapshot of branch `main` at commit `4f8c2b1` on 2026-04-19. Three specialized exploration agents ran in parallel:

1. **Agent A** — A01 Broken Access Control + A07 Authentication Failures
2. **Agent B** — A03 Supply Chain + A04 Cryptographic + A05 Injection + A10 SSRF
3. **Agent C** — A02 Misconfiguration + A06 Insecure Design + A08 Integrity + A09 Logging

Supporting activities:

- Pattern searches via `grep`/`ripgrep` in `src/`, `config/`, `migrations/`, `.github/workflows/`.
- CVE cross-check against public advisory databases for pinned dependencies.
- Severity classified by effective exposure within the application context.

### Data handling compliance

All external lookups performed during this assessment used **public identifiers only** — package names and versions, CVE/CWE IDs, OWASP category names, public vendor names, and public reference URLs. **No repository content** (source code, file paths, directory structure, schemas, configuration, logs, secrets, or customer data) was transmitted to any external service. Questions that could not be answered safely through identifier-only queries were resolved locally from the codebase snapshot.

### Limitations

- No dynamic analysis.
- Some `file:line` references are representative of repeated patterns.
- Network infrastructure explicitly out of scope.
- Point-in-time snapshot only.

---

## 4. Scope

### Included
- `src/`
- `config/`
- `migrations/`
- `.github/workflows/`
- `Dockerfile`

### Excluded
- `node_modules/`
- `dist/`
- `.git/`
- `tests/`
- `docs/`
- `.env.example`, `.env.local`, `.env.development`
- `docker-compose.override.yml`
- Cloud infrastructure outside the repo

---

## 5. Findings by OWASP category

### [A01:2025 — Broken Access Control](https://owasp.org/Top10/2025/A01_2025-Broken_Access_Control/)
**Status:** ❌ Non-conformant · **Aggregate severity:** High

| # | Finding | Evidence | Severity | Confidence | CWE |
|---|---------|----------|----------|------------|-----|
| H4 | Missing ownership check on invoice lookup | `src/controllers/invoices/show.ts:52` | 🟠 | Verified | [CWE-639](https://cwe.mitre.org/data/definitions/639.html) |
| H5 | File download route trusts file ID without tenant check | `src/controllers/files/download.ts:61` | 🟠 | Verified | [CWE-284](https://cwe.mitre.org/data/definitions/284.html) |

**Plain-language impact:** A user may access another customer's invoices or files by changing identifiers in requests. This risks direct exposure of customer data and weakens tenant isolation guarantees.

### [A02:2025 — Security Misconfiguration](https://owasp.org/Top10/2025/A02_2025-Security_Misconfiguration/)
**Status:** ⚠️ Partial · **Aggregate severity:** Medium

| # | Finding | Evidence | Severity | Confidence | CWE |
|---|---------|----------|----------|------------|-----|
| M2 | Missing `Content-Security-Policy` header on admin responses | `src/server.ts:41` | 🟡 | Verified | [CWE-693](https://cwe.mitre.org/data/definitions/693.html) |

**Plain-language impact:** Browser-side protections are incomplete, which makes certain client-side attack chains easier if another issue is exploited first.

### [A03:2025 — Software Supply Chain Failures](https://owasp.org/Top10/2025/A03_2025-Software_Supply_Chain_Failures/)
**Status:** ⚠️ Partial · **Aggregate severity:** Medium

| # | Finding | Evidence | Severity | Confidence | CWE |
|---|---------|----------|----------|------------|-----|
| M3 | CI workflow uses floating GitHub Action tag | `.github/workflows/deploy.yml:18` | 🟡 | Verified | [CWE-494](https://cwe.mitre.org/data/definitions/494.html) |

**Plain-language impact:** Build behavior can change without review if an upstream action tag is moved. That increases the chance of unexpected or malicious code entering the deployment pipeline.

### [A04:2025 — Cryptographic Failures](https://owasp.org/Top10/2025/A04_2025-Cryptographic_Failures/)
**Status:** ⚠️ Partial · **Aggregate severity:** High

| # | Finding | Evidence | Severity | Confidence | CWE |
|---|---------|----------|----------|------------|-----|
| H1 | JWT library falls back to hardcoded local secret | `src/lib/jwt.ts:14` | 🟠 | Verified | [CWE-798](https://cwe.mitre.org/data/definitions/798.html) |

**Plain-language impact:** If configuration is missing or misapplied, authentication tokens may be signed with a predictable secret. That can allow forged sessions.

### [A05:2025 — Injection](https://owasp.org/Top10/2025/A05_2025-Injection/)
**Status:** ❌ Non-conformant · **Aggregate severity:** Critical

| # | Finding | Evidence | Severity | Confidence | CWE |
|---|---------|----------|----------|------------|-----|
| C1 | Search endpoint builds SQL with raw query interpolation | `src/controllers/search.ts:88` | 🔴 | Verified | [CWE-89](https://cwe.mitre.org/data/definitions/89.html) |
| H2 | Reporting endpoint interpolates user-controlled sort field | `src/controllers/reports/export.ts:119` | 🟠 | Verified | [CWE-89](https://cwe.mitre.org/data/definitions/89.html) |

**Plain-language impact:** An attacker may alter database queries and retrieve or modify data that should not be accessible. In the most severe case this can expose customer records or corrupt business data.

### [A06:2025 — Insecure Design](https://owasp.org/Top10/2025/A06_2025-Insecure_Design/)
**Status:** ⚠️ Partial · **Aggregate severity:** Medium

| # | Finding | Evidence | Severity | Confidence | CWE |
|---|---------|----------|----------|------------|-----|
| M1 | Invite endpoint lacks rate limiting and abuse controls | `src/routes/invitations.ts:12` | 🟡 | Verified | [CWE-307](https://cwe.mitre.org/data/definitions/307.html) |

**Plain-language impact:** Public-facing invitation flows can be abused for spam, enumeration, or service degradation. This increases operational noise and can degrade customer trust.

### [A07:2025 — Authentication Failures](https://owasp.org/Top10/2025/A07_2025-Authentication_Failures/)
**Status:** ⚠️ Partial · **Aggregate severity:** Low

| # | Finding | Evidence | Severity | Confidence | CWE |
|---|---------|----------|----------|------------|-----|
| L2 | Login endpoint does not enforce incremental backoff | `src/controllers/auth/login.ts:33` | 🟢 | Likely | [CWE-307](https://cwe.mitre.org/data/definitions/307.html) |

**Plain-language impact:** Password guessing attacks are cheaper than they should be. This is less severe than direct account compromise bugs but still weakens account protection.

### [A08:2025 — Software/Data Integrity Failures](https://owasp.org/Top10/2025/A08_2025-Software_or_Data_Integrity_Failures/)
**Status:** ❌ Non-conformant · **Aggregate severity:** High

| # | Finding | Evidence | Severity | Confidence | CWE |
|---|---------|----------|----------|------------|-----|
| H3 | Partner webhook accepts events without signature verification | `src/routes/webhooks/partner.ts:34` | 🟠 | Verified | [CWE-345](https://cwe.mitre.org/data/definitions/345.html) |

**Plain-language impact:** External systems can impersonate trusted webhook senders. That can trigger unauthorized state changes inside the product.

### [A09:2025 — Logging & Alerting Failures](https://owasp.org/Top10/2025/A09_2025-Security_Logging_and_Alerting_Failures/)
**Status:** ⚠️ Partial · **Aggregate severity:** Low

| # | Finding | Evidence | Severity | Confidence | CWE |
|---|---------|----------|----------|------------|-----|
| L3 | Request logger records raw authorization header on error path | `src/middleware/errorLogger.ts:27` | 🟢 | Verified | [CWE-532](https://cwe.mitre.org/data/definitions/532.html) |

**Plain-language impact:** Sensitive token material may end up in logs. This broadens the blast radius of any later log access incident.

### [A10:2025 — Server-Side Request Forgery](https://owasp.org/Top10/2025/A10_2025-Server-Side_Request_Forgery_(SSRF)/)
**Status:** ✅ Conformant · **Aggregate severity:** None

> No findings in this assessment. Reviewed external fetchers, redirect handling, and user-controlled URL paths; current code paths enforce hostname allowlisting.

---

## 6. Consolidated findings table

| ID | Category | Description | Evidence | Severity | CWE | Status vs previous |
|----|----------|-------------|----------|----------|-----|--------------------|
| C1 | A05 | SQL injection in search API | `src/controllers/search.ts:88` | 🔴 | CWE-89 | → Persisted |
| H1 | A04 | Hardcoded JWT signing fallback secret | `src/lib/jwt.ts:14` | 🟠 | CWE-798 | → Persisted |
| H2 | A05 | Raw SQL interpolation in reporting endpoint | `src/controllers/reports/export.ts:119` | 🟠 | CWE-89 | ↑ Escalated |
| H3 | A08 | Webhook handler accepts unsigned requests | `src/routes/webhooks/partner.ts:34` | 🟠 | CWE-345 | ★ New |
| H4 | A01 | Missing invoice ownership check | `src/controllers/invoices/show.ts:52` | 🟠 | CWE-639 | ★ New |
| H5 | A01 | IDOR on file download route | `src/controllers/files/download.ts:61` | 🟠 | CWE-284 | → Persisted |
| M1 | A06 | No rate limiting on invite endpoint | `src/routes/invitations.ts:12` | 🟡 | CWE-307 | → Persisted |
| M2 | A02 | Missing CSP header | `src/server.ts:41` | 🟡 | CWE-693 | ★ New |
| M3 | A03 | Floating GitHub Action tag | `.github/workflows/deploy.yml:18` | 🟡 | CWE-494 | ★ New |
| L2 | A07 | Missing login backoff | `src/controllers/auth/login.ts:33` | 🟢 | CWE-307 | → Persisted |
| L3 | A09 | Authorization header logged on error path | `src/middleware/errorLogger.ts:27` | 🟢 | CWE-532 | ★ New |

---

## 7. Prioritized recommendations

### 🔴 Critical priority

| # | Addresses | Recommendation | Benefit |
|---|-----------|----------------|---------|
| R1 | C1, H2 | Replace raw SQL string construction with parameterized query APIs across all controller and export paths. | Removes highest-likelihood data exposure and tampering vector. |

### 🟠 High priority

| # | Addresses | Recommendation | Benefit |
|---|-----------|----------------|---------|
| R2 | H4, H5 | Enforce centralized object-level authorization on invoice, file, and similar tenant-scoped resources. | Restores tenant isolation. |
| R3 | H3 | Require cryptographic signature verification for every webhook provider before request processing. | Prevents forged external events. |
| R4 | H1 | Remove insecure JWT secret fallback and fail closed when signing configuration is absent. | Prevents token forgery under misconfiguration. |

### 🟡 Medium priority

| # | Addresses | Recommendation | Benefit |
|---|-----------|----------------|---------|
| R5 | M1, L2 | Add consistent rate limiting and backoff to auth-adjacent and invitation flows. | Reduces abuse, spam, and guessing attacks. |
| R6 | M2 | Add missing browser security headers in the main server middleware. | Improves resilience against secondary client-side attacks. |
| R7 | M3 | Pin CI actions to immutable SHAs and review update cadence explicitly. | Hardens build integrity. |

### 🟢 Low priority / hygiene

| # | Addresses | Recommendation | Benefit |
|---|-----------|----------------|---------|
| R8 | L3 | Scrub authorization headers and other secret-bearing fields from all error and request logs. | Reduces secondary exposure in operational systems. |

---

## 8. Dependencies with known CVEs

| Package | Current version | CVE / Advisory | Severity | Suggested action |
|---------|-----------------|----------------|----------|------------------|
| `axios` | `0.27.2` | [GHSA-wf5p-g6vw-rhxx](https://github.com/advisories/GHSA-wf5p-g6vw-rhxx) | Medium | Upgrade to a fixed release |
| `jsonwebtoken` | `8.5.1` | [CVE-2022-23529](https://nvd.nist.gov/vuln/detail/CVE-2022-23529) | High | Upgrade and review token handling code paths |

> Final confirmation should come from the language-appropriate audit tool in the pipeline.

---

## 9. Verification plan

### Static analysis / CI
- Add query-pattern checks for raw SQL construction mapped to `R1`.
- Add CI policy to reject floating GitHub Actions tags mapped to `R7`.

### Automated tests
- Add authorization tests for cross-tenant invoice and file access mapped to `R2`.
- Add webhook verification tests for valid and invalid signatures mapped to `R3`.

### Manual review
- Review all endpoints that dereference tenant-owned resources by ID.
- Review all token and secret fallback behavior in auth bootstrap.

### Runtime
- Confirm CSP and auth logging changes in staging response headers and log sinks.
- Monitor rejected webhook and rate-limit metrics after rollout.

---

## 10. References

- [OWASP Top 10 — 2025](https://owasp.org/Top10/)
- [CWE](https://cwe.mitre.org/)
- [NVD](https://nvd.nist.gov/)
- [OWASP SQL Injection Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)
- [OWASP Webhook Security Guidelines](https://cheatsheetseries.owasp.org/)

---

## 11. Appendix — critical files for manual review

```text
src/controllers/search.ts
src/controllers/reports/export.ts
src/controllers/invoices/show.ts
src/controllers/files/download.ts
src/routes/webhooks/partner.ts
src/lib/jwt.ts
src/routes/invitations.ts
src/middleware/errorLogger.ts
.github/workflows/deploy.yml
```

---

## Final caveats

- Static analysis snapshot only.
- Validate every `file:line` reference before remediation.
- No code changes were made during preparation of this report.
