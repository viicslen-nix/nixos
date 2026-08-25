---
name: cicd-pipeline
description: How CI, releases, image builds, and production deploys are wired across the app repos. Use when touching .github/workflows, docker-bake.hcl, docker/Dockerfile.*, release-please config, or when a release/build/deploy did not fire.
---

# CI/CD Pipeline

Every app repo follows the same chain. Nothing is deployed by hand.

```
conventional commit -> master
  -> release-please  (opens/merges "chore(master): release X.Y.Z" PR, tags, GitHub Release)
  -> release: published
     -> docker/bake-action -> Docker Hub  (fmtod/<app>)
     -> repository_dispatch(deploy-production) -> FmTod2/mylisterhub-cloud-config
        -> ./mlh appVersion <version> [chart] -> commit to master
        -> ./mlh upgrade production -y [charts...]
```

## Workflows

| File | Trigger | Job |
| --- | --- | --- |
| `.github/workflows/tests.yaml` | `push: master`, `pull_request` | composer install, `cp .env.example .env`, `key:generate`, `./vendor/bin/pest --ci` |
| `.github/workflows/release-please.yaml` | `push: master` | `googleapis/release-please-action@v4` with `release-please-config.json` + `.release-please-manifest.json` |
| `.github/workflows/release-published.yaml` | `release: published`, `workflow_dispatch` | `build` (bake + push) then `deploy` (dispatch), `deploy` gated on `if: github.event_name == 'release'` |

## Non-obvious rules

**Always use a GitHub App token, never `GITHUB_TOKEN`.**
- A release created with `GITHUB_TOKEN` does **not** emit `release: published`, so the image build never fires. This is the single most common "why didn't it deploy" cause.
- `submodules: true` needs an App token scoped to the submodule repos (`repositories:` list in `actions/create-github-app-token@v2`). Without it `package:discover` fails on missing providers. Add every new submodule repo to that list in **both** `tests.yaml` and `release-published.yaml`.

Secrets used: `GH_APP_ID`, `GH_APP_PRIVATE_KEY`, `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`. The App needs `contents:read` on the app repo + submodules, and write on `mylisterhub-cloud-config` for the dispatch.

**Concurrency**: `release-please` group with `cancel-in-progress: false` (cancelling mid-run leaves a half-written manifest); build group with `cancel-in-progress: true`.

**Versions** are bumped only by release-please via conventional commits. `.release-please-manifest.json` is the source of truth. Never hand-edit `CHANGELOG.md` or tag manually. Commit types that show in the changelog: `feat`, `fix`, `perf`, `refactor`, `build`, `ci`, `docs`; `style`/`chore` are hidden. Commitlint (`@commitlint/config-conventional`) enforces this locally via husky.

## Docker build

`docker-bake.hcl` defines three targets chained by named contexts, built with `docker/bake-action@v7 targets: production`:

- `backend` — `serversideup/php:${PHP_VERSION}-cli-alpine`, installs `PHP_EXTS`, two-stage composer install (deps layer from `composer.json`/`composer.lock`/`modules/` for cache, then `--optimize-autoloader` over the full source).
- `frontend` — `oven/bun:1`, pulls `vendor/` from the `backend` context (Vite plugins need it), `bun --smol run build` with cache mounts on `~/.bun/install/cache` and `node_modules/.vite`.
- `production` — `serversideup/php:${PHP_VERSION}-fpm-nginx`, copies the whole app from `backend` and only `public/build` from `frontend`.

Tags come from `docker/metadata-action@v6` and are passed in as the `TAGS` env var (comma-joined; `split_tags` in the HCL splits them). Caching is `type=gha` / `mode=max`.

PHP version lives in three places that must agree: bake `PHP_VERSION`, the Dockerfile `ARG` defaults, and `setup-php` in `tests.yaml`. `PHP_EXTS` also differs slightly between backend (has `sockets`) and production — keep intentional differences intentional.

## Deploy

The `deploy` job resolves `app_version` by stripping the leading `v` from the release tag, then `peter-evans/repository-dispatch@v3` sends `deploy-production` to `FmTod2/mylisterhub-cloud-config` with:

```json
{ "app_version": "...", "charts": "<chart name>", "source_repo": "...",
  "source_ref": "...", "source_sha": "...", "trigger_source": "release",
  "triggered_by": "..." }
```

`charts` scopes the deploy (e.g. `admin`). In cloud-config, `deploy-production.yaml` bumps `appVersion` in the matching `Chart.yaml` via `./mlh appVersion`, commits to master, then upgrades:

- charts under `helm/app/charts/` (cron, web, worker, nightwatch) are one umbrella release — `./mlh upgrade production -y`; only the bumped charts differ in the diff, so only those pods roll.
- anything else (`admin`, `notifications`, `beacon`, ...) is its own release and must be named: `./mlh upgrade production -y <chart>`.

Empty `charts` means all charts. Deploys are Helm + helm-secrets with `HELM_SECRETS_BACKEND=vals` (values hold `ref+gcpsecrets://` refs), authenticating to GCP with `GCP_CREDENTIALS` and to the cluster with `KUBECONFIG_PRODUCTION` (base64 kubeconfig, context renamed to `production`).

## Debugging checklist

- Release PR never opened -> commit was not conventional, or type is hidden in `changelog-sections`.
- Release tagged but no image -> the release was made with `GITHUB_TOKEN` (or created by hand in the UI, which is fine — that does emit the event — but check `release: published` in the run list).
- Build fails on `package:discover` / missing provider -> App token missing a submodule repo.
- Image pushed but nothing rolled -> check the dispatch step, then the cloud-config Actions tab; a chart name not matching a directory silently becomes a standalone upgrade that fails.
- Re-run a build without a new release: `workflow_dispatch` on the build workflow (the `deploy` job is skipped by design).

Reproduce workflows locally with `act` (it is installed).
