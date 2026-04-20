# Scope defaults and dev-only exclusions

Load this file at Step 0, after `rules.md`, to establish what paths are in scope for the assessment and which are deliberately skipped.

Default scope is the entire repository **minus** two categories of noise: vendor/build artifacts and local-dev-only files. Both are excluded because they are not part of the production attack surface; analyzing them generates false positives that drown out real findings.

The lists below are universal OSS patterns. They are deliberately generic — no assumption about the specific project or stack.

---

## Always off-scope (vendor / build / IDE)

- **Dependency trees:** `node_modules/`, `vendor/`, `.venv/`, `venv/`, `site-packages/`, `packages/`, `gems/`, `target/`, `bin/`, `obj/`
- **VCS internals:** `.git/`
- **Build outputs:** `dist/`, `build/`, `out/`, `coverage/`, `.next/`, `.nuxt/`, `.cache/`, `.parcel-cache/`, `.turbo/`
- **IDE / editor:** `.idea/`, `.vscode/`, `.cursor/`, `.junie/`, `.gemini/`, `.claude/`, `.ai/`
- **Minified / bundled assets:** `*.min.js`, `*.min.css`, sourcemaps
- **The assessment output directory itself** (no self-analysis) and any `archive/` folder under it

---

## Off-scope by default (local development)

These are artifacts of a developer's local environment. Hardcoded "passwords" in these files are expected and intentional — flagging them drowns the report.

- **Local env templates:** `.env.example`, `.env.dist`, `.env-dist`, `.env.sample`, `.env.local`, `.env.development`, `.env.test`. Only `.env` itself, when committed, is a finding (that's the live file).
- **Test fixtures and seeds:** `tests/`, `test/`, `spec/`, `__tests__/`, `cypress/`, `e2e/`, `fixtures/`, `seed/`, `seeds/`, `factories/`, `*.test.*`, `*.spec.*`, `*_test.*`. Fake credentials here are by design.
- **Local dev Compose overrides:** `docker-compose.override.yml`, `docker-compose.dev.yml`, `docker-compose.test.yml`, `docker-compose-dist.yml`.
- **Self-signed dev certs:** `docker/*/certs/`, `nginx-selfsigned.*`, `dhparam.pem`, `localhost.pem`, `*.local.pem`.
- **API collections / sandbox traces:** `*.postman_collection.json`, `*_sandbox*`, `*_staging*`, HAR exports.
- **Local-only scripts:** `scripts/dev-*`, `scripts/local-*`, `bin/dev`, and Makefile targets named `dev`, `local`, `start-local` (scan the Makefile but treat dev-only targets as out-of-scope for prod hardening).
- **Documentation and example directories:** `examples/`, `docs/`, README snippets. **Beware:** if a README contains a real API key as an "example", that IS a finding. Obvious placeholders (`YOUR_KEY_HERE`, `xxxxxxxx`, `sk_test_example`) are fine; anything with the shape of a real token is not.
- **AI/agent caches:** `.claude/plugins/cache/`, any vendor-namespaced `.cache` tree.

---

## Dev-to-prod leaks — the real concern

A password literal in a dev-only file is not the concern. A dev-only value that reaches production IS. Flag anything that:

- Looks dev-only but is **referenced from a production manifest** — e.g., a `docker-compose.yml` that the CI/CD pipeline actually uses as the prod compose. Check the deploy scripts and CI workflow to see which compose file is built into the prod image.
- Is under `tests/` but **mirrors the prod schema and carries realistic data** that could be re-deployed against production (fixture files used by migrations, seed scripts wired into Docker entrypoints).
- Sits in `.env.example` with a comment like "paste your real value here" AND **the placeholder is structurally a real secret** (full-length AWS key prefix, real-shape Stripe key, real-length JWT).
- Uses a **debug / dev flag in a file baked into the production image** — `APP_DEBUG=true`, `DEBUG=*`, `FLASK_ENV=development`, `NODE_ENV=development`, verbose error toggles, display_errors, long stack traces — if the config file is copied into the container in the production Dockerfile or referenced by the prod deploy manifest.

Exploration agents mark these with:

- **`dev-leak:`** — confident it reaches prod (evidence is the deploy manifest or CI reference itself).
- **`dev-leak?:`** — suspect but unverified.

Consolidation applies the Dev-leak handling rules in `consolidation.md`.

---

## User override at Step 0

After applying the defaults, ask the user three questions once:

- "Should I also scan the dev-only paths I would normally skip? (default: no)"
- "Are there additional paths specific to this repo I should exclude? (e.g., generated documentation sites, legacy frozen directories, large asset repos)"
- "What language should the report be written in? Offer a closed list — `English` (default), `Portuguese-BR`, `Spanish`, `French` — plus an `other` option for free-text input (e.g., `German`, `Italian`, `Japanese`). Default to `English` if the user skips the question."

Record the scope answers in the report's §4 Scope section. Record the language choice in the metadata table's `Language` row so future readers can see the convention used for this chain.

If the user mentions a specific sub-path ("just the API layer", "only the admin module"), narrow to that path **but keep the full workflow** — diff against baseline, chain linking, metadata. A narrowed assessment is still a dated assessment.

---

## Handoff to later steps

After Step 0, the downstream orchestrator has:

- `<output_dir>` — the directory where all prior and future reports live.
- `<stack_hint>` — an optional hint for the exploration agents (auto-detected when possible; asked when ambiguous).
- `<scope>` — explicit included and excluded lists derived from this file plus any user overrides.

Inject the effective exclusion list into each exploration agent prompt (the "Dev-only paths to skip" block in `explore_prompts.md`). Without it, the agents will default to over-flagging noise.