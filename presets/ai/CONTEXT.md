# CONTEXT

The `ai` preset: the AI harnesses, the `ai` subflake's profile, and the
CLIProxyAPI proxy every harness uses by default. It used to be split between
`dev` (harnesses) and `personal` (proxy); it became its own preset so a
non-NixOS home host (`openclaw`) can take the same config without `dev`'s
toolchains or anything that needs a NixOS system.

## Home-only, and no `osConfig`

`default.nix` only adds `home.nix` to `home-manager.sharedModules`; nothing here
needs the system. `home.nix` must never read `osConfig`: a home host is built by
standalone home-manager, where `osConfig` is `null`. The other presets'
`home.nix` read it for the desktop gate, which is why a home host can list
`ai` and nothing else.

`dev` imports this directory, so every NixOS host with `dev` gets it without
listing it. Imports of the same path are deduplicated, so listing it as well
would be harmless.

## The proxy key

`apiKeyFile` defaults to `$XDG_CONFIG_HOME/cliproxyapi/api-key`, a plain file a
machine outside agenix is given by hand. `personal` overrides it with the
agenix secret; the proxy option is a submodule, so that one attribute merges
over this definition.
