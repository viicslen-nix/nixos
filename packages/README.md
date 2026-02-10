# Custom Packages

This directory contains custom package definitions that are not available in nixpkgs or need custom configurations.

## Using Packages

Packages are automatically exported and can be used in multiple ways:

### In Your Configuration

```nix
environment.systemPackages = with pkgs; [
  # Custom packages from this flake
  local.antigravity
  local.mago
];
```

### Directly with Nix

```bash
# Run a package
nix run .#antigravity

# Build a package
nix build .#mago

# Install to profile
nix profile install .#openwork
```

## Adding a New Package

1. Create directory: `packages/by-name/my-package/`
2. Create `packages/by-name/my-package/package.nix`
3. Define your package derivation
4. Build and test: `nix build .#my-package`

### Example Package Structure

```nix
# packages/by-name/my-package/package.nix
{ lib
, stdenv
, fetchFromGitHub
}:

stdenv.mkDerivation rec {
  pname = "my-package";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "owner";
    repo = "repo";
    rev = "v${version}";
    hash = "sha256-...";
  };

  meta = with lib; {
    description = "Description of my package";
    homepage = "https://example.com";
    license = licenses.mit;
    maintainers = [ ];
  };
}
```

## Guidelines

- Use `by-name/` directory structure for automatic discovery
- Follow nixpkgs naming conventions
- Include proper meta information
- Test packages before committing

---

*For more information, see the main README.md*
