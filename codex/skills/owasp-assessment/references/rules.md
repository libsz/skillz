# Hard rules

Load this file at Step 0, before any exploration or external lookup.

Authoritative reference for the standard being assessed: [OWASP Top 10 (2025)](https://owasp.org/Top10/2025/). Every finding must map to at least one of its categories (A01–A10).

These rules are runtime-neutral and mandatory. They exist to keep the assessment useful without leaking sensitive project information.

## Output rules

- **Language — user choice at Step 0.** The default language is **English**. At Step 0, offer the user a closed list of alternatives (`English`, `Portuguese-BR`, `Spanish`, `French`) plus an "other" option for free-text input (e.g., `German`, `Italian`, `Japanese`). The chosen language applies to all prose in the report: findings descriptions, plain-language impact paragraphs, recommendations, limitations, and narrative sections. Record the choice in the report metadata under a `Language` row. Universal identifiers stay canonical regardless of language: CWE IDs, CVE IDs, OWASP category slugs, severity emoji (🔴🟠🟡🟢), finding IDs (C1/H1/M1/L1), URLs, and `file:line` evidence citations. Once a chain of reports for a given project is started in a language, subsequent runs should use the same language — mixing languages across the chain makes the Changes section harder to read. If the user explicitly asks to switch mid-chain, translate prior finding descriptions inline when citing them in the new report.
- **No timelines.** Never write time-bound remediation language such as "within 1 week", sprint labels, quarter labels, or rollout waves. Prioritize by severity and let the team schedule.
- **No code fixes in the report.** This is an assessment, not a remediation PR. Recommendations stay in prose unless the user explicitly asks for a separate appendix with snippets.
- **Evidence must be concrete.** Every finding cites `file:line` or an explicit "not found in code" note.
- **Do not modify application code.** The skill writes only to the chosen assessment output directory.
- **Do not delete or rewrite previous reports.** Past reports are a historical record. The only allowed edit to a previous report is adding or updating the `Superseded by` link.

## Data handling rules

These rules govern what may and may not leave the local environment. The assessment runs on real source code, real secrets, and real architectural detail — none of that can be allowed to reach a third-party service under any circumstance.

### Absolute prohibition — never leaves this environment

The following categories of information must NEVER be transmitted to any external service (WebFetch, WebSearch, Context7, Perplexity, any MCP server, or any tool added to this environment in the future):

- **Source code** — no snippets, no fragments, no paraphrased logic, no pseudocode derived from the real code.
- **File paths, file names, or directory/folder names** from the repository, including extensions when they reveal project-specific naming.
- **Directory structure, file tree, or repository layout** in any form — not as a listing, not as ASCII art, not as a prose description of "what lives where".
- **Schemas, table names, column names, SQL/NoSQL fragments**, migration files, or any data-model identifier.
- **Configuration** — env vars, config file contents, feature flags, connection strings (even redacted structures).
- **Stack traces, log lines, error messages** pulled from the repo or its runtime.
- **Commit messages, branch names, ticket IDs, PR numbers, comments** in code.
- **Business logic, internal service names, internal domain names, or internal API routes.**
- **Customer, tenant, partner, organization, user, or employee names** surfaced during exploration.
- **Secrets of any kind** — API keys, tokens, passwords, private keys, session IDs, webhook signing secrets, hashes of the above — not even prefixes, not even "the first 4 chars for context".

"External service" means anything not running entirely inside the local runtime process and the local filesystem.

### Positive allowlist — the ONLY things that may appear in an external query

External queries may contain exclusively these items:

- **Package names and version strings** from public registries (`lodash 4.17.15`, `requests==2.25.1`, `composer/guzzle:7.5.0`).
- **CVE identifiers** (`CVE-2023-12345`).
- **CWE identifiers** (`CWE-89`).
- **OWASP category names and slugs** (`A05:2025 Injection`, `A03_2025-Software_Supply_Chain_Failures`).
- **Public vendor names** (`Stripe`, `AWS`, `GitHub`).
- **Public reference URLs** (OWASP pages, NVD entries, GitHub Advisory Database pages, official vendor docs).

Anything not on this list is forbidden by default.

### Query hygiene checklist — run BEFORE every external call

Before sending any request to WebFetch, WebSearch, Context7, or Perplexity, check the prompt against this list. If the answer to ANY question is "yes", do not send:

1. Does the query contain a file path, file name, or directory name from this repository?
2. Does the query describe or imply the repo's directory structure or file layout?
3. Does the query contain a function, class, variable, route, or symbol name from this repository?
4. Does the query contain a table name, column name, schema, or migration fragment?
5. Does the query contain a code snippet, stack trace, log line, or configuration value?
6. Does the query contain any identifier that could identify the project, organization, customer, or internal system?
7. Does the query contain a secret, token, API key, password, or any fragment thereof?
8. Does the query contain anything that is NOT in the Positive allowlist above?

Only when every answer is "no" is the query safe to send.

### Refusal directive — when in doubt, don't send

If a research question cannot be answered with an identifier-only query, DO NOT send a modified version with any repo content. Instead:

1. Perform the analysis locally using internal tooling (Explore subagent, file read, grep).
2. Record the gap explicitly in the report's §3 Methodology or §4 Scope section.
3. Tell the user what could not be externally verified and why.

A locally-analyzed finding with a minor coverage gap beats a leaked repo fragment. "Good enough" never justifies breaking this rule.

### Per-tool scope — what each allowed tool is for

- **WebSearch / WebFetch** — public advisories, vendor changelogs, OWASP/CWE/NVD pages. Queries of the form `"<package> <version> CVE"`, `"<package> security advisory"`, or fetches of public URLs. Nothing else.
- **[Context7](https://github.com/upstash/context7) (`query-docs`, `resolve-library-id`)** — retrieving published library documentation by public package name. Never send code, configuration, or internal usage context. Upstream source and install guide: <https://github.com/upstash/context7>.
- **[Perplexity](https://github.com/perplexityai/modelcontextprotocol) (`perplexity_ask`, `perplexity_search`, `perplexity_research`, `perplexity_reason`)** — research queries built exclusively from the Positive allowlist. Every Perplexity prompt goes through the Query hygiene checklist first. Upstream source and install guide: <https://github.com/perplexityai/modelcontextprotocol>.
- **Any other tool or MCP, now or in the future** — default-deny. Adding a tool to the allowlist requires an explicit edit to this file, not an in-session judgment call.

### Secret redaction in every output

If exploration finds a credential literal (API key, password, private key, token, session identifier, webhook signing secret), the report cites the `file:line` only and shows at most a short, non-functional prefix: `AKIA...`, `sk_live_...`, `-----BEGIN PRIVATE KEY-----…`. The full value is never written to the report, to chat, to memory, or to any external tool.

### Customer data minimization

Do not include real customer, tenant, partner, organization, building, landlord, user, or employee names in report prose. Replace them with generic placeholders ("a user", "a customer", "an organization", "a resource in the system"). The only identifiers allowed are generic terms that are part of the system's public design (class names, feature names, public product names) and are not customer-specific.

## Confidentiality rules

- **Confidentiality seal on every report.** Every report file starts with `Confidential — internal use only` immediately under the H1.
- **Treat the report as restricted.** The report is a roadmap to attack the system. Do not paste it into public issues, public chat channels, or external email threads.

## Active exploit risk

Apply the `Active exploit risk` tag only if all of the following are true:

1. Severity is Critical.
2. Confidence is Verified.
3. The vulnerable path is reachable from untrusted input today.

Examples that qualify:

- `.env` with live credentials committed to the repo
- SQL injection on a reachable endpoint
- SSRF on a currently used external fetch path

Examples that do not qualify:

- IDOR that still requires a legitimate account and additional manual verification
- weak crypto used only for a non-security purpose

If any finding carries `Active exploit risk`, the report must include the explicit containment warning from the document template.

## Failure modes to avoid

These anti-patterns have caused real problems in past runs. Treat them as hard guardrails:

- **Skipping the diff when a baseline exists.** Defeats the purpose of the skill. Always list `<output_dir>` first and read any prior `OWASP_ASSESSMENT_*.md` before starting fresh.
- **Reusing finding IDs across runs.** Confuses readers. IDs are per-report; traceability lives in the "Status vs previous" column.
- **Writing a sprawling report without the Changes section on top.** Stakeholders want to see what changed first, then the absolute state. The Changes section must appear before any findings tables.
- **Letting agents return vague prose summaries.** Re-prompt for `file:line | severity | OWASP | confidence | evidence` output. Dense evidence is what makes the report actionable.
- **Treating VCS-branch-pinned dependencies as low-risk** because they feel "internal" or "we control them". `dev-master`, `main`, `HEAD`, and commit SHAs without a lockfile are supply-chain critical regardless of origin.
- **Hard-coding a specific language or framework into the workflow.** The skill is stack-agnostic; the exploration agents detect the stack and translate patterns. Do not bake PHP, Node, Python, Go, Ruby, Java, or any framework name into the operating procedure — detection belongs inside each agent.
- **Forgetting the Data handling compliance attestation** in §3 of the report. It's what makes the privacy guarantee auditable for future readers. If omitted, the assessment reads as if external tools may have seen repo content — even when they didn't.
- **Promoting a `dev-leak?:` suspect to a full finding without human validation.** The suspect tag exists precisely because the agent could not confirm the prod path. Promoting unverified suspects inflates severity and erodes trust in future runs.
