# Explore agent prompts for OWASP assessment

Authoritative reference for the categories used below: [OWASP Top 10 (2025)](https://owasp.org/Top10/2025/).

Three agents run in parallel at Step 3 of the skill. Each agent covers a cohesive group of OWASP categories so it can keep context tight and return concrete evidence.

**Stack-agnostic.** These prompts are written in terms of *risk classes*, not specific framework APIs. Every prompt starts by telling the agent to first identify the primary language(s) and framework(s) and then translate the generic patterns below to the idioms that stack actually uses. Concrete examples are given only because they make the patterns tangible — the agent should substitute equivalents for Node, Python, Go, Ruby, Java, C#, Rust, PHP, etc.

**No external calls from exploration agents.** These subagents run inside the local runtime and have direct repository access. They MUST NOT call WebFetch, WebSearch, Context7, Perplexity, or any external tool — no finding should require sending repo content outside the environment. External research is reserved for Step 4 of the skill (CVE validation) and is strictly identifier-only, governed by `rules.md`. If an agent feels it needs external data to judge a finding, it should return the finding with lower confidence and a note; the orchestrator decides whether a safe identifier-only lookup is warranted.

**How to spawn:** single message, three `Agent` calls, `subagent_type: "Explore"`, `thoroughness: "very thorough"`. Pass `<stack_hint>` from Step 0 into each prompt if available (otherwise omit that line and the agent will auto-detect).

**Output contract for every agent:**
```
file_path:line_number | severity | OWASP_id | confidence | 1–2 sentence evidence
```
Severity is one of `Critical | High | Medium | Low`. Confidence is one of `Verified | Likely | Inferred`. If an agent returns prose instead of the tabular format, re-invoke it with tighter instructions.

**Dev-only exclusions — applied by every agent.** Each prompt below ends with a "Dev-only paths to skip" block. Always inject there the effective exclusion list from Step 0 (vendor/build/IDE dirs + local-dev-only patterns: `.env.example`/`.env.dist`/`.env.local`/`.env.development`/`.env.test`, `tests/`/`spec/`/`__tests__/`/`fixtures/`/`seeds/`, `docker-compose.override.yml`/`docker-compose.dev.yml`/`docker-compose-dist.yml`, dev self-signed certs under `docker/*/certs/`, `*.postman_collection.json`, local-only scripts, etc.).

Each agent's findings must distinguish:
- **Prod finding** — pattern exists in a path that ships to production. Report normally.
- **Dev leak suspect** — pattern exists only in a nominally-dev path **but** that path is referenced from a production deployment manifest or CI pipeline. Report with confidence `Likely` and prefix evidence with `dev-leak:` so consolidation knows to highlight it.
- **Pure dev — do NOT report.** Pattern exists only in a path matching the dev-only exclusions and there is no evidence it reaches prod. Skip entirely. Hardcoded passwords in test fixtures, fake tokens in Postman collections, self-signed certs in `docker/*/certs/` — all of these are noise and must be skipped.

When in doubt about whether a path is dev-only, prefer `Likely` confidence with a `dev-leak?:` prefix rather than dropping or over-flagging.

---

## Agent A — Access control and authentication

**Description:** `OWASP A01/A07 — authN/authZ audit`

**Subagent type:** `Explore`

**Prompt:**

```
You are auditing a codebase for OWASP Top 10 (2025) — focus only on:

A01:2025 Broken Access Control — missing authorization checks, IDOR, route protection, role/ACL enforcement, CORS + credentials, direct object reference on sensitive entities.

A07:2025 Authentication Failures — token handling (algorithm choice, secret source, kid/key rotation, expiry), session management, password hashing, credential stuffing protection, MFA, brute force protection, insecure password reset, OAuth state/nonce handling.

Stack hint from the caller: <stack_hint or "unknown — detect first">

Before searching, briefly identify the primary language, framework, and authentication library in use. Then translate the generic patterns below to the specific idioms of that stack. Examples from any single language are illustrative only; substitute the local equivalent (e.g., Express middlewares, Django auth backends, Spring Security, Rails devise/pundit, ASP.NET Core Identity, Gin middleware, Laravel guards, etc.).

Return findings strictly in this format, one per line:
file_path:line_number | Critical|High|Medium|Low | A01 or A07 | Verified|Likely|Inferred | short evidence

Confidence:
- Verified: pattern confirmed by direct code read / grep hit
- Likely: pattern present but exploitation path has a gap you couldn't close in this pass
- Inferred: deduced from architecture smell or secondary signal, not from direct code match

Be very thorough. Check:
1. Authentication bootstrapping — how is identity established on each request? Middleware/filter/interceptor chain, public vs private routes, default-deny vs default-allow.
2. Token handling (JWT/OAuth/session tokens) — algorithm (symmetric vs asymmetric, any accept-any-alg bug, "none" alg risk), secret source (env vs hardcoded), expiry enforcement, kid/rotation support, how refresh works.
3. Access control patterns — explicit authorization layer (policy/voter/pundit/guard) vs implicit middleware-only? Any endpoint that only checks "is user X" (e.g., getUserId()) without checking "does user X own Y" (classic IDOR) on sensitive resources (payments, billing, admin, multi-tenant data, files).
4. Password handling — modern hash (argon2id/bcrypt) with sane cost? Any md5/sha1/plain-text storage or verification?
5. Session config — store (memory/redis/DB), lifetime, httpOnly/secure/samesite on cookies, CSRF posture if cookie auth.
6. ID obfuscation used as authorization (e.g., hashids, base62 IDs) — flag as weak control.
7. Brute-force protection — is rate limiting wired to login, signup, password-reset, OTP, email send, PDF generation? Anonymous endpoints especially.
8. Hardcoded tokens, API keys, credentials anywhere in source (not in env/secret stores).
9. Social login / OAuth — state/nonce validation, callback URL allowlist, redirect URI fixation.
10. Webhook endpoints using API key in URL path (instead of header/HMAC).

Evidence must include file:line. Do not summarize vaguely. Return dense, under 2500 words.
```

---

## Agent B — Supply chain, crypto, injection, SSRF

**Description:** `OWASP A03/A04/A05/A10 — supply chain, crypto, injection, SSRF`

**Subagent type:** `Explore`

**Prompt:**

```
You are auditing a codebase for OWASP Top 10 (2025) — focus only on:

A03:2025 Software Supply Chain Failures — outdated/vulnerable deps, unpinned deps, VCS-branch pins (dev-master / main / HEAD), unofficial packages, abandoned packages, build pipeline risks. Read the dependency manifest(s) for the detected stack; also review CI config and container definitions.

A04:2025 Cryptographic Failures — weak hashes (md5/sha1) for sensitive data, hardcoded keys, non-CSPRNG where CSPRNG is required (rand/mt_rand/Math.random/java.util.Random), insecure cipher modes (ECB, reused IV, static IV), authenticated-encryption missing (AES-CTR without MAC), plaintext secrets in logs/storage.

A05:2025 Injection — SQL (string concatenation/interpolation into raw query APIs), NoSQL ($where / JSON injection), OS command (system shells, child_process.exec, os.system, Runtime.exec, backticks), LDAP, XPath, template injection (server-side template engines rendering user input), XSS in server-rendered output, XXE via XML libraries.

A10:2025 SSRF — user- or config-controlled URLs passed to HTTP clients (curl/fetch/requests/axios/http.Client/Guzzle/OkHttp), webhook targets, image/PDF/feed fetchers, OAuth callbacks, server-side redirect followers.

Stack hint from the caller: <stack_hint or "unknown — detect first">

Before searching, identify the primary language(s) and major libraries. Then translate the generic patterns below to idioms of that stack. Examples from any single language are illustrative only.

Return findings strictly in this format, one per line:
file_path:line_number | Critical|High|Medium|Low | A03|A04|A05|A10 | Verified|Likely|Inferred | short evidence

Be very thorough. Check:
1. Supply chain: list VCS-branch-pinned deps (dev-master, main, HEAD, commit SHA without lockfile), abandoned packages (no release 2+ years), unofficial repos, exact-version pins of known-old libs, container images with floating tags vs SHA digest, lockfile committed, secrets passed via ARG/ENV in Dockerfile (persist in layers), CI secret scanning.
2. SQL / NoSQL injection: grep for raw-query APIs with string concatenation or template interpolation of variables. Examples by stack: PHP `$this->db->query("… {$var} …")`, Node `knex.raw("SELECT … " + var)`, Python f-string in `cursor.execute`, Go `fmt.Sprintf` into `db.Exec`, Ruby string interpolation in `ActiveRecord.find_by_sql`, Java string concat in `Statement.executeQuery`. Report every hit, not a sample.
3. OS command injection: any shell-invoking API (exec/system/spawn/run with shell=True/Runtime.exec/os.popen/backticks) — trace whether user-controllable input reaches them.
4. XXE: XML parsers without entity/DOCTYPE hardening (PHP `simplexml_load_string`/`DOMDocument::loadXML`, Python `xml.etree`/`lxml` without `resolve_entities=False`, Java `DocumentBuilderFactory` without `FEATURE_SECURE_PROCESSING`, Node `libxmljs`). Feeds ingesting remote XML are high priority.
5. SSRF: any HTTP client call where the URL comes from config, DB, query string, webhook payload, or user input — check whether internal CIDRs are blocked and whether redirects are re-validated.
6. Crypto: md5/sha1/MD2/MD4 anywhere near authentication/integrity, non-CSPRNG for token/ID generation, `openssl_encrypt`/`crypto.createCipheriv` with mode=ECB or CTR without MAC, static or predictable IVs, hardcoded keys in code/config files.
7. XSS / template injection: server-rendered templates fed user input without escaping, PDF/HTML generators consuming raw user HTML, any `eval(`/`Function(`/`new Function(`/`exec()`/`compile()` on user input.
8. Deserialization: language-native deserializers on untrusted input (PHP `unserialize`, Python `pickle.loads`/`yaml.load`, Java `ObjectInputStream`, Ruby `Marshal.load`, .NET `BinaryFormatter`) — check allowlist of allowed classes.

Evidence must include file:line. Dense, under 2500 words.
```

---

## Agent C — Configuration, design, integrity, logging

**Description:** `OWASP A02/A06/A08/A09 — config, design, integrity, logging`

**Subagent type:** `Explore`

**Prompt:**

```
You are auditing a codebase for OWASP Top 10 (2025) — focus only on:

A02:2025 Security Misconfiguration — verbose errors in prod, debug modes, permissive CORS, missing security headers (CSP, HSTS, X-Content-Type-Options, X-Frame-Options, Referrer-Policy, Permissions-Policy), exposed config files committed to the repo, stack traces leaked to clients, containers running as root, display_errors / DEBUG=true in prod paths, open listing/indexing.

A06:2025 Insecure Design — no central input validation, no rate limiting on sensitive flows (password reset, signup, OTP, PDF generation, email send), business logic flaws, trust boundaries mixed (admin/tenant/user in same endpoint), long-lived API keys with no rotation metadata, missing CSRF on state-changing endpoints when cookie auth is used.

A08:2025 Software/Data Integrity Failures — unsigned updates, insecure deserialization (revisit from Agent B angle: webhook integrity), plugin loading from untrusted sources, weak file upload validation (extension-only, MIME-only, no magic bytes), dynamic `include/require/import` with user-controlled paths, webhook handlers without signature verification, CI that pulls unpinned actions.

A09:2025 Logging & Alerting Failures — missing auth audit logs, logging of secrets/PII/tokens (raw request body, headers), error reporters without scrubbing (Sentry, Rollbar, Datadog, Bugsnag), no alerting on suspicious patterns (failed logins, role changes), no log retention policy, PII/card data ending up in log files.

Stack hint from the caller: <stack_hint or "unknown — detect first">

Before searching, identify the primary language, framework, container/runtime tooling, and observability libraries. Then adapt the patterns below.

Return findings strictly in this format, one per line:
file_path:line_number | Critical|High|Medium|Low | A02|A06|A08|A09 | Verified|Likely|Inferred | short evidence

Be very thorough. Check:
1. A02 config: framework config files and env templates (.env, application.yml, settings.py, appsettings.json, config/*.php, etc.). Container definitions (Dockerfile, compose) — USER root? ADD from URL? COPY secrets? Reverse proxy / ingress configs for headers. Bootstrap file for error output (echoing stack traces to clients). Env files committed with live credentials.
2. A06 design: is there a single validation layer (JSON schema, pydantic, zod, class-validator, Bean Validation)? Is it applied to every handler or just some? Rate limiting wired to public flows? CSRF tokens used when cookies carry auth? Admin vs tenant separation — distinct controllers/routes? Long-lived API keys with no rotation metadata on their storage model?
3. A08 integrity: file upload handlers — MIME only? magic bytes (finfo / file-type libs)? extension allowlist? storage path under web root? `include`/`require`/`import` with variables? Webhook endpoints: which ones verify signatures (Stripe `constructEvent`, Coinbase HMAC, GitHub X-Hub-Signature-256) and which ones just accept an API key in URL or body? CI workflows: are third-party actions/plugins pinned to SHA or floating tags?
4. A09 logging: where does application logging initialize? Grep for log calls that include raw request body, headers, password, token, JWT, credit card, SSN. Error reporter init — does it scrub sensitive fields (before_send hook in Sentry, sanitizer in Rollbar)? Is there a login/role-change audit trail? Log handlers — file, network, third-party? Rotation and retention?

Evidence must include file:line. Dense, under 2500 words.
```

---

## Handling vague agent output

If an agent returns prose instead of the tabular format, re-invoke with:

> Your previous reply was too narrative. Return strictly `file_path:line_number | severity | OWASP_id | confidence | evidence` lines. No headers, no summary, one line per finding.

If an agent returns fewer than ~5 findings for a category group, the search was probably too shallow — re-invoke with:

> Widen the search. Use the detected stack's idioms to grep for every variant of the patterns in the original prompt and report every hit, not a sample. Duplicates across files are fine; the consolidation step will de-duplicate.