---
name: ci-pipeline
description: Tests, conventional commits, release-please versioning, and Docker image build/push for the app repos. Use when touching .github/workflows for tests/releases/builds, docker-bake.hcl, docker/Dockerfile.*, release-please config, migrating a repo off semantic-release, or when a release PR or image build did not fire. For what happens after the image is pushed, see the cd-pipeline skill.
---

# CI Pipeline

Everything up to and including a pushed image. Deployment is a separate concern — see `cd-pipeline`.

```
conventional commit -> master
  -> release-please  (opens/merges "chore(master): release X.Y.Z" PR, tags, GitHub Release)
  -> release: published
     -> docker/bake-action -> Docker Hub (fmtod/<app>)
     -> [handoff to cd-pipeline]
```

## Workflows

| File | Trigger | Job |
| --- | --- | --- |
| `.github/workflows/tests.yaml` | `push: master`, `pull_request` | composer install, `cp .env.example .env`, `key:generate`, `./vendor/bin/pest --ci` |
| `.github/workflows/release-please.yaml` | `push: master` | `googleapis/release-please-action@v4` with `release-please-config.json` + `.release-please-manifest.json` |
| `.github/workflows/release-published.yaml` | `release: published`, `workflow_dispatch` | `build` (bake + push); a `deploy` job follows it — that one belongs to `cd-pipeline` |

## Non-obvious rules

**Always use a GitHub App token, never `GITHUB_TOKEN`.**
- A release created with `GITHUB_TOKEN` does **not** emit `release: published`, so the image build never fires. This is the single most common "why didn't it build" cause.
- `submodules: true` needs an App token scoped to the submodule repos (`repositories:` list in `actions/create-github-app-token@v2`). Without it `package:discover` fails on missing providers. Add every new submodule repo to that list in **both** `tests.yaml` and `release-published.yaml`.

Secrets: `GH_APP_ID`, `GH_APP_PRIVATE_KEY`, `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`. The App needs `contents:read` on the app repo and its submodules.

**Concurrency**: `release-please` group with `cancel-in-progress: false` (cancelling mid-run leaves a half-written manifest); build group with `cancel-in-progress: true`.

**Versions** are bumped only by release-please via conventional commits. `.release-please-manifest.json` is the source of truth. Never hand-edit `CHANGELOG.md` or tag manually. Types shown in the changelog: `feat`, `fix`, `perf`, `refactor`, `build`, `ci`, `docs`; `style`/`chore` hidden. Commitlint (`@commitlint/config-conventional`) enforces the format locally via husky.

## Docker build

`docker-bake.hcl` defines three targets chained by named contexts, built with `docker/bake-action@v7 targets: production`:

- `backend` — `serversideup/php:${PHP_VERSION}-cli-alpine`, installs `PHP_EXTS`, two-stage composer install (deps layer from `composer.json`/`composer.lock`/`modules/` for cache, then `--optimize-autoloader` over the full source).
- `frontend` — `oven/bun:1`, pulls `vendor/` from the `backend` context (Vite plugins need it), `bun --smol run build` with cache mounts on `~/.bun/install/cache` and `node_modules/.vite`.
- `production` — `serversideup/php:${PHP_VERSION}-fpm-nginx`, copies the whole app from `backend` and only `public/build` from `frontend`.

Tags come from `docker/metadata-action@v6` and are passed in as the `TAGS` env var (comma-joined; `split_tags` in the HCL splits them). Caching is `type=gha` / `mode=max`.

PHP version lives in three places that must agree: bake `PHP_VERSION`, the Dockerfile `ARG` defaults, and `setup-php` in `tests.yaml`. `PHP_EXTS` also differs slightly between backend (has `sockets`) and production — keep intentional differences intentional.

## Porting a repo onto this pipeline

Doing only this half is fine and useful: a repo can adopt release-please + image builds while its chart keeps being bumped by hand. Wire the deploy later with `cd-pipeline`.

### Invariant (every repo, any language)

1. Conventional commits, enforced by commitlint + husky.
2. `release-please` on `push: master` — never semantic-release, never manual tags.
3. A GitHub **App token** everywhere a release is created or a private repo is cloned.
4. Build workflow on `release: published` + `workflow_dispatch`, pushing to `fmtod/<app>` on Docker Hub with `docker/metadata-action` semver tags and `type=gha` cache.

### Per-repo — do not copy from admin blindly

- **Test job** — whatever the language needs. Admin runs pest; a Go repo keeps its own `_test.yml` / `_security.yml` reusable workflows. Keep them.
- **Bake vs plain build** — `docker-bake.hcl` with the backend/frontend/production graph exists because Laravel needs `vendor/` present during the asset build. A single `Dockerfile` with `docker/build-push-action` is fine and should stay; only the tag/cache/registry conventions are shared.
- **`release-type`** — admin uses `simple`. Stay on `simple` unless you want a version file rewritten (`node` rewrites `package.json`, `go` writes a version const). A repo whose `package.json` version is stale tooling metadata should stay on `simple`.
- **Submodule token scoping** — only if the repo has submodules.
- **Action major versions** — admin is on `checkout@v7`, `metadata-action@v6`, `bake-action@v7`, `docker/*-action@v4`. Older repos on v3/v5 still work; bump them in the same PR or leave them, but don't mix within one repo.

### Migrating off semantic-release

1. Delete `release.config.mjs`; drop `semantic-release` and `@semantic-release/*` from `devDependencies`. Keep `@commitlint/*` and `husky`.
2. Add `release-please-config.json` (copy admin's `changelog-sections`). Drop semantic-release's `releaseRules` — release-please decides bumps from the commit type and has no equivalent knob.
3. Add `.release-please-manifest.json` seeded with the **current released version, no `v`** — e.g. `{ ".": "1.3.2" }`. Getting this wrong makes release-please re-release an old version or skip commits.
4. Tag shape must match what semantic-release produced. `include-component-in-tag: false` yields `v1.3.2`, which is also what semantic-release emits, so history stays continuous. If the tag is missing or shaped differently, add `bootstrap-sha` pointing at the last released commit.
5. Keep `CHANGELOG.md`. release-please appends to it; the formatting won't match the old entries, which is fine.
6. Replace the release workflow rather than adapting it. semantic-release runs after tests in one job chain; release-please is its own workflow on `push: master` and does not gate on tests (the tests workflow already runs on that same push). Don't try to preserve a `needs: [test, security]` gate on release-please — gate the *build* instead if you want that.
7. Swap `secrets.GITHUB_TOKEN` for the App token. semantic-release repos typically use `GITHUB_TOKEN`, which silently breaks the `release: published` -> build chain.

### Checklist

- [ ] App installed on the repo with `contents:read` (plus submodule repos)
- [ ] `GH_APP_ID`, `GH_APP_PRIVATE_KEY`, `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` available
- [ ] `release-please-config.json` + `.release-please-manifest.json` seeded to the current version
- [ ] Release workflow uses the App token, `concurrency` with `cancel-in-progress: false`
- [ ] Build workflow triggers on `release: published`, image name `fmtod/<app>`
- [ ] Old release tooling removed — config file, deps, and workflows

## Debugging checklist

- Release PR never opened -> commit was not conventional, or the type is hidden in `changelog-sections`.
- Release tagged but no image -> the release was made with `GITHUB_TOKEN`. (A release created by hand in the UI *does* emit the event; check for `release: published` in the run list.)
- Build fails on `package:discover` / missing provider -> App token missing a submodule repo.
- Re-run a build without cutting a release: `workflow_dispatch` on the build workflow. The `deploy` job is skipped by design.
- Image pushed but nothing rolled -> that is `cd-pipeline`, not this skill.

Reproduce workflows locally with `act` (it is installed).
