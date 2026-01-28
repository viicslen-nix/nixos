# Development Shells

This directory contains pre-configured development environments for different workflows.

## Available Shells

### Kubernetes Development
```bash
nix develop .#kubernetes
```
Development environment for Kubernetes work with kubectl, helm, and related tools.

### Laravel/PHP Development
```bash
nix develop .#laravel
```
PHP development environment with Laravel-specific tooling and dependencies.

### Python Development
```bash
nix develop .#python
```
Python development environment with common tools and libraries.

### Default Shell
```bash
nix develop
```
General-purpose development environment.

## Usage

Enter a development shell:
```bash
nix develop .#<shell-name>
```

Or use direnv with `.envrc`:
```bash
use flake .#<shell-name>
```

## Adding a New Shell

1. Create a new file: `dev-shells/my-shell.nix`
2. Define your shell environment
3. Add to `dev-shells/default.nix` exports
4. Test with: `nix develop .#my-shell`

---

*For more information, see the main README.md*
