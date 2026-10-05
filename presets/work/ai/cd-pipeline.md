---
name: cd-pipeline
description: How a published release reaches production — the repository_dispatch to mylisterhub-cloud-config, mlh appVersion bumps, and Helm upgrades against the production cluster. Use when adding or debugging a deploy job, choosing the charts payload, working in mylisterhub-cloud-config/helm, or when an image was pushed but nothing rolled. For tests, release-please, and image builds, see the ci-pipeline skill.
---

# CD Pipeline

Picks up where `ci-pipeline` ends: an image is on Docker Hub and a GitHub Release exists.

```
release: published
  -> deploy job in the app repo
     -> repository_dispatch(deploy-production) -> FmTod2/mylisterhub-cloud-config
        -> ./mlh appVersion <version> [chart] -> commit to master
        -> ./mlh upgrade production -y [charts...]
        -> rollout verification
```

Nothing is deployed by hand. A chart bumped manually will be overwritten by the next release.

## The deploy job (app repo side)

Lives in `.github/workflows/release-published.yaml` as a second job:

- `needs: build`, `if: github.event_name == 'release'` — so a `workflow_dispatch` rebuild never deploys.
- Resolves `app_version` by stripping the leading `v` from `github.event.release.tag_name`.
- App token scoped to `mylisterhub-cloud-config` (needs write there).
- `peter-evans/repository-dispatch@v3`, `event-type: deploy-production`, payload:

```json
{ "app_version": "...", "charts": "<chart name>", "source_repo": "...",
  "source_ref": "...", "source_sha": "...", "trigger_source": "release",
  "triggered_by": "..." }
```

Only `app_version` and `charts` drive behavior; the rest is provenance for the run log.

## Choosing `charts`

Find the chart in `mylisterhub-cloud-config/helm/`:

- Under `helm/app/charts/` — `cron`, `web`, `worker`, `nightwatch` — these four are **one umbrella release**. Naming any of them triggers one umbrella upgrade; scoping already happened at the `appVersion` bump, so only the bumped charts differ in the diff and only their pods roll.
- A top-level dir — `admin`, `beacon`, `cms`, `imports`, `landing`, `notifications`, `proxysql` — is its **own release** and must be named explicitly or nothing rolls.

Use the **directory** name, not `name:` from `Chart.yaml`: `helm/beacon` holds a chart named `mylisterhub-beacon`, but the payload value is `beacon`.

Empty `charts` means all charts. Fine for a coordinated release, wrong for a single app — it rolls everything.

## cloud-config side

`.github/workflows/deploy-production.yaml`, on `repository_dispatch: [deploy-production]` or `workflow_dispatch`:

1. Auth: `google-github-actions/auth@v2` with `GCP_CREDENTIALS`, then `setup-gcloud` on project `mylisterhub`.
2. Tooling: helm, `vals` v0.45.0 (pinned, fetched from GitHub releases), helm-secrets 4.7.4 plus its getter and post-renderer plugins, helm-diff, kubectl.
3. kubeconfig from `KUBECONFIG_PRODUCTION` (base64), then the current context is **renamed to `production`** — `mlh` addresses the cluster as `--kube-context production` regardless of what the secret calls it.
4. `./mlh appVersion <version> [chart]` per named chart, or all charts when `charts` is empty.
5. `git add helm` — deliberately not `helm/app/charts/*/Chart.yaml`, which misses the umbrella's own `Chart.yaml` and standalone charts under `helm/<chart>/`. `mlh` only ever touches `Chart.yaml` files. Commit is skipped when the diff is empty.
6. `./mlh upgrade production -y` for the umbrella, and/or `./mlh upgrade production -y <chart>...` for standalone charts. The workflow decides which by testing `-d helm/app/charts/$chart`.
7. Rollout verification per chart against `mylisterhub-<chart>`.

Secrets are not in the values files: they hold `ref+gcpsecrets://` references resolved at render time by `vals` (`HELM_SECRETS_BACKEND=vals`, not sops).

## Wiring a repo that has no deploy yet

A repo can run `ci-pipeline` for a while with its chart bumped by hand. To automate it:

1. Confirm the chart exists under `mylisterhub-cloud-config/helm/` and note its directory name.
2. Confirm the App is installed on `mylisterhub-cloud-config` with write access.
3. Copy admin's `deploy` job verbatim into the build workflow, changing only `charts` and the App token's `repositories:` scope.
4. If the `appVersion` was being bumped by hand until now, the first automated release is a no-op commit when it already matches — harmless.

## Debugging checklist

- Image pushed, nothing rolled -> check the `deploy` step ran at all (it is gated on `github.event_name == 'release'`), then the cloud-config Actions tab.
- Dispatch step fails -> App token not scoped to `mylisterhub-cloud-config`, or missing write there.
- Deploy "succeeds" but pods are unchanged -> `charts` names something that is not a directory under `helm/`, so the standalone upgrade path ran against a nonexistent release. Compare against the directory listing, not `Chart.yaml`.
- Wrong app rolled -> `charts` was empty, so all charts were bumped and upgraded.
- Chart.yaml commit landed but no upgrade -> check whether the chart is umbrella or standalone; a standalone chart never rolls via the umbrella upgrade.
- Secret resolution failures at render -> `vals` missing from PATH or the `ref+gcpsecrets://` target does not exist for that project.
