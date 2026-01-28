# Development Workflow

This guide covers common development workflows and best practices for working with this NixOS configuration.

## Daily Workflows

### Making Configuration Changes

1. **Edit configuration files**
   ```bash
   $EDITOR hosts/my-host/default.nix
   ```

2. **Test the build**
   ```bash
   just build my-host
   ```

3. **Apply changes**
   ```bash
   just switch
   ```

4. **Commit**
   ```bash
   just commit "Add feature X"
   ```

### Adding a New Program

1. **Create module** (if needed)
   ```bash
   just new-module nixos programs my-program
   ```

2. **Edit module**
   ```bash
   $EDITOR modules/nixos/programs/my-program/default.nix
   ```

3. **Register in default.nix**
   Edit `modules/nixos/default.nix`

4. **Enable in host**
   ```nix
   modules.programs.my-program.enable = true;
   ```

5. **Test and apply**
   ```bash
   just build my-host
   just switch
   ```

## Development Tools

### Available Commands

View all commands:
```bash
just --list
```

Key commands organized by group:

#### Development
- `just new-module TYPE CATEGORY NAME` - Create new module
- `just validate` - Validate configuration
- `just update-docs` - Update documentation
- `just check` - Validate + update docs
- `just fmt` - Format nix files
- `just lint [FILE]` - Check for dead code

#### Build
- `just build HOST` - Build specific host
- `just build-all` - Build all hosts
- `just test` - Run eval tests

#### Update
- `just update` - Update all flake inputs
- `just update-input INPUT` - Update specific input
- `just full-upgrade` - Update + rebuild

#### Deploy
- `just switch [COMMAND]` - Rebuild system
- `just upgrade [COMMAND]` - Use nh helper
- `just commit-and-upgrade MSG` - Commit + rebuild

#### Maintenance
- `just clean` - Remove old generations
- `just gc` - Garbage collect
- `just optimize` - Optimize nix store
- `just history` - List generations

### Helper Scripts

Located in `tools/`:

#### generate-module.sh
Create new module with template:
```bash
./tools/generate-module.sh nixos programs docker
./tools/generate-module.sh home programs git
```

#### validate-config.sh
Validate entire configuration:
```bash
./tools/validate-config.sh
```

Checks:
- Flake syntax
- Code formatting
- All host builds (dry-run)

#### update-docs.sh
Regenerate documentation:
```bash
./tools/update-docs.sh
```

Auto-generates:
- `modules/README.md`
- `hosts/README.md`

## Development Shells

### Enter a Dev Shell

```bash
# Default shell
nix develop

# Specific shell
nix develop .#kubernetes
nix develop .#laravel
nix develop .#python
```

### Use with direnv

Create `.envrc`:
```bash
use flake .#laravel
```

Then:
```bash
direnv allow
```

## Testing Changes

### Build Test (Recommended)

Test without applying:
```bash
just build my-host
```

### Dry Run

See what would change:
```bash
nixos-rebuild dry-build --flake .#my-host
```

### VM Test

Test in virtual machine:
```bash
nixos-rebuild build-vm --flake .#my-host
./result/bin/run-my-host-vm
```

### Validation

Run full validation:
```bash
just validate
```

## Updating Dependencies

### Update All Inputs

```bash
just update
```

### Update Specific Input

```bash
just update-input nixpkgs
just update-input home-manager
```

### Check What Changed

```bash
nix flake lock --update-input nixpkgs
git diff flake.lock
```

### After Updates

```bash
just full-upgrade  # Updates + rebuilds with boot
```

## Debugging

### Check Option Values

```bash
nix eval .#nixosConfigurations.my-host.config.modules.programs.docker
```

### Check Build Logs

```bash
nixos-rebuild switch --flake .#my-host --show-trace
```

### Inspect Derivation

```bash
nix show-derivation .#nixosConfigurations.my-host.config.system.build.toplevel
```

### Check Dependencies

```bash
nix-store --query --references $(which program)
```

## Git Workflow

### Basic Workflow

```bash
# Make changes
$EDITOR hosts/my-host/default.nix

# Test
just build my-host

# Commit
just commit "Update my-host configuration"

# Push
git push
```

### With Rebuild

```bash
just commit-and-upgrade "Add docker support"
```

### Feature Branches

```bash
# Create branch
git checkout -b feature/add-kubernetes

# Make changes
$EDITOR modules/nixos/programs/kubernetes/default.nix

# Test thoroughly
just validate
just build-all

# Commit
git add .
git commit -m "Add Kubernetes module"

# Merge
git checkout main
git merge feature/add-kubernetes
```

## Code Quality

### Format Code

```bash
# Format all files
just fmt

# Format specific file
nix fmt path/to/file.nix
```

### Check Syntax

```bash
just check-file path/to/file.nix
```

### Lint for Dead Code

```bash
# Check all files
just lint

# Check specific file
just lint path/to/file.nix
```

## Performance Tips

### Build Caching

Use a binary cache:
```nix
nix.settings = {
  substituters = [
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
  ];
};
```

### Parallel Builds

```nix
nix.settings = {
  max-jobs = 4;
  cores = 0;  # Use all cores
};
```

### Reduce Evaluation Time

- Use `--fast` flag for quick checks
- Enable `nix.settings.eval-cache = true`
- Minimize imports in frequently-built configs

## Troubleshooting

### Build Failures

1. **Check syntax**
   ```bash
   just check-file problematic-file.nix
   ```

2. **Update inputs**
   ```bash
   just update
   ```

3. **Clear cache**
   ```bash
   nix-collect-garbage -d
   ```

4. **Check logs**
   ```bash
   nixos-rebuild switch --flake .#my-host --show-trace
   ```

### Option Conflicts

```bash
# See where option is defined
nix eval --show-trace .#nixosConfigurations.my-host.config.option
```

Use `lib.mkForce` to override:
```nix
option = lib.mkForce value;
```

### Flake Issues

```bash
# Update lock file
nix flake update

# Verify flake
nix flake check

# Show flake structure
nix flake show
```

## Best Practices

### 1. Always Test Before Deploy

```bash
just build my-host && just switch
```

### 2. Commit Working States

After successful changes:
```bash
just commit "Working configuration"
```

### 3. Use Presets

Instead of:
```nix
modules.programs.docker.enable = true;
modules.programs.git.enable = true;
# ... 20 more lines
```

Use:
```nix
modules.presets.work.enable = true;
```

### 4. Document Complex Configs

```nix
# Enable docker with nvidia support for ML workloads
modules.programs.docker = {
  enable = true;
  nvidiaSupport = true;
};
```

### 5. Validate Before Pushing

```bash
just check && git push
```

### 6. Use Meaningful Commit Messages

```bash
# Bad
just commit "update"

# Good
just commit "Add kubernetes module with helm support"
```

### 7. Keep Hosts Minimal

Put common config in modules/presets, not in every host.

### 8. Regular Maintenance

```bash
# Weekly
just update
just full-upgrade

# Monthly  
just clean
just optimize
```

## Continuous Integration

### GitHub Actions (Example)

```yaml
name: Build
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: cachix/install-nix-action@v20
      
      - name: Validate
        run: nix run .#validate
      
      - name: Build all hosts
        run: |
          for host in home-desktop dostov-dev; do
            nix build .#nixosConfigurations.$host.config.system.build.toplevel
          done
```

### Pre-commit Hooks

Create `.git/hooks/pre-commit`:
```bash
#!/bin/bash
./tools/validate-config.sh || exit 1
```

Make executable:
```bash
chmod +x .git/hooks/pre-commit
```

## Learning Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nix Pills](https://nixos.org/guides/nix-pills/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Flakes Wiki](https://nixos.wiki/wiki/Flakes)

---

*See also other guides in `docs/` directory*
