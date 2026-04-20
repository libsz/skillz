# CVE validation — Step 4

Load this file at Step 4 of the skill, after exploration agents have started and before consolidation. This step validates the **dependency supply chain** against public advisory databases.

All external queries run under the identifier-only rules defined in `rules.md` (Absolute prohibition, Positive allowlist, Query hygiene checklist). Nothing from the repo leaves the environment — only public package names, versions, CVE/CWE IDs, OWASP category names, public vendor names, and public reference URLs.

---

## Manifest discovery

Open whichever dependency manifest(s) the detected stack uses. Do not ship any of these files, their contents, or their paths to external services — read them locally and extract only public package + version pairs for identifier-only lookups.

| Stack | Primary manifest | Lockfile (preferred source of resolved versions) |
|---|---|---|
| **Node.js** | `package.json` | `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml` |
| **Python** | `pyproject.toml` / `requirements.txt` | `Pipfile.lock`, `poetry.lock`, `pdm.lock` |
| **PHP** | `composer.json` | `composer.lock` |
| **Go** | `go.mod` | `go.sum` |
| **Ruby** | `Gemfile` | `Gemfile.lock` |
| **Java** | `pom.xml` / `build.gradle` / `build.gradle.kts` | (Maven/Gradle resolve at build time — audit via `mvn dependency:tree` / `gradle dependencies`) |
| **Rust** | `Cargo.toml` | `Cargo.lock` |
| **.NET** | `*.csproj` / `Directory.Packages.props` | `packages.lock.json` |
| **Container** | `Dockerfile` | base image tags and SHA digests |
| **CI pipelines** | `.github/workflows/*.yml`, `.gitlab-ci.yml`, `Jenkinsfile`, etc. | third-party action / plugin refs |

Prefer the lockfile for exact resolved versions. The top-level manifest tells you *intent* (range, pin type); the lockfile tells you *reality* (installed version).

---

## Priority criteria — what to research first

Not every dependency needs a CVE lookup. Focus effort where risk concentrates:

1. **Exact-version pins** — a pin like `"lodash": "4.17.15"` or `requests==2.25.1` cannot auto-patch. If a known CVE affects that version, the project is actively vulnerable until someone manually bumps. Always look these up.
2. **VCS-branch pins** — `dev-master`, `main`, `HEAD`, `latest`, commit SHAs without a lockfile, or direct git URLs. These resolve to whatever was there when last fetched; they are supply-chain critical regardless of "internal" origin. Flag as A03 risk even if no public CVE exists.
3. **Abandoned packages** — no release in the last 24 months. Maintenance dead; security response will be slow or absent. Research whether a maintained fork exists.
4. **Pre-1.0 pins** — `0.x.y` versions. API instability is documented; security posture often is not. Check for known advisories and whether the library recommends a 1.x successor.
5. **Popular targets with large CVE history** — `jackson-databind`, `log4j`, `spring-*`, `express`, `axios`, `django`, `rails`, `lodash`, common PHP frameworks. A quick check of the installed version against the advisory database is cheap and high-value.
6. **Container base images** — `FROM node:18` (floating tag) vs `FROM node:18.12.1-alpine@sha256:...` (pinned). Floating tags drift silently; pin-by-digest is the hardened form.

**Skip** packages under conservative semver ranges (`^`, `~`, `>=`) **unless** a known high-severity advisory exists for the currently-installed version. The lockfile tells you which version is actually installed.

---

## Query mechanics — identifier-only

Every external lookup follows the Query hygiene checklist in `rules.md`. Concretely, allowed query shapes:

- WebSearch / WebFetch: `"<package> <version> CVE"`, `"<package> security advisory"`, `"<package> GHSA"`, or direct fetches of NVD / GitHub Advisory Database / vendor advisory pages.
- [Context7](https://github.com/upstash/context7): resolve-library-id with the public package name; query-docs for secure-API usage of the *named* library. Never send any repo content as context.
- [Perplexity](https://github.com/perplexityai/modelcontextprotocol): research prompts built from package name + version + CVE/CWE/OWASP IDs + public vendor names only. No code, no repo paths, no internal identifiers.

If an advisory is only meaningful in context (e.g., "this CVE only triggers when feature X is enabled"), determine the feature's enablement **locally** by reading the config. Do not describe the config to an external tool.

---

## What belongs in §8 "Dependencies with known CVEs"

Populate the §8 table (see `document_template.md`) with one row per package-version-CVE tuple. Required columns:

- **Package** — exact public name as it appears in the manifest.
- **Current version** — the resolved version from the lockfile when available.
- **CVE / Advisory** — linked to NVD (`https://nvd.nist.gov/vuln/detail/<CVE-ID>`) or the GitHub Advisory Database (`https://github.com/advisories/<GHSA-ID>`).
- **Severity** — CVSS-derived Low/Med/High/Crit.
- **Suggested action** — upgrade to version X, replace with maintained fork Y, or remove if unused. No timelines.

Also populate the A03 (Software Supply Chain Failures) category table with higher-level findings: "4 VCS-branch-pinned deps under `require-dev`", "2 abandoned packages with no maintained fork", "container base image uses floating tag instead of digest pin".

---

## Gap disclosure

If a specific lookup cannot be done without violating the data handling rules (e.g., the question only makes sense when paired with internal usage context), record the gap under §3 Methodology "Data handling compliance" or §4 Scope Limitations. Example:

> "The installed version of library X (1.2.3) has a CVE gated by runtime usage of feature Y. Whether feature Y is enabled in this deployment was verified locally by reading the configuration; no portion of the config was sent to external tools."

A locally-verified gap is acceptable. A leaked fragment is not.