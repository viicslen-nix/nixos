# CONTEXT

Why `modules.programs.bash` configures so little.

## Shell integrations are not listed here

atuin/carapace/direnv/starship/zoxide/yazi/keychain all default their
`enableBashIntegration` to `home.shell.enableShellIntegration`, so bash picks up
the same set nushell and zsh use without repeating it here.
