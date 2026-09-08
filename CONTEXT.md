# CONTEXT

The story behind decisions at the root of this repo — the things a diff does
not explain. Rules and workflows live in [AGENTS.md](./AGENTS.md); this file is
why the code looks the way it does.

## An index entry can freeze, and bumping omniflake won't unstick it

`llm-agents-nix` sat on one rev across four consecutive `Update index` commits
while upstream shipped several package bumps a day. `just update-input
omniflake` was a no-op for it. Check before assuming a stale dependency is your
lock's fault — no fetch, no eval:

```bash
curl -sL "https://raw.githubusercontent.com/fzakaria/omniflake/$(jq -r .nodes.omniflake.locked.rev flake.lock)/index.json" \
  | jq '."<attr>".locked'
```

The fix is to make it a real input again, which is what `llm-agents` now is.
Two things learned doing it:

- **Don't hand-pin its nixpkgs to hold onto the upstream cache.** An input you
  say nothing about is locked from the *dependency's own* `flake.lock`, and
  `nix flake update <x>` re-reads that lock, so the author's rev tracks itself.
  Verified bare and with a sibling `follows`, at first lock and across an
  update. The forward jump described in AGENTS.md under "Removing an
  `inputs.<x>.nixpkgs.follows` does not restore the old pin" is specific to
  *removing* an override that was already locked.
- **Restore the loader's `systems = systems-linux`**, as
  `inputs.<x>.inputs.systems.follows = "systems-linux"`. Coming out of the
  index loses it.

Verify with store paths: `packages.x86_64-linux.<pkg>.outPath` through
`github:<owner>/<repo>/<rev>` must equal the one through
`(builtins.getFlake "git+file:///etc/nixos?submodules=1").inputs.<x>`, then
`nix path-info --store <cache> <path>` to confirm the cache has it.
