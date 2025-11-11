# Quickstart Guide: Testing Hyprland Flake Migration

**Feature**: 002-hyprland-flake
**Purpose**: Testing and validation procedures for the hyprland flake extraction

---

## Pre-Migration Testing

**Objective**: Establish baseline functionality before migration

### 1. Document Current State
```bash
# Record current hyprland configuration status
cd /etc/nixos
git status
git log --oneline -10

# Test current hyprland desktop functionality
nixos-rebuild build --flake .#$(hostname)
```

### 2. Validate Existing Functionality
**Manual Testing Checklist**:
- [ ] Hyprland starts successfully
- [ ] Waybar displays correctly with all modules
- [ ] Keybindings respond (Super+Return, Super+Q, etc.)
- [ ] Window rules apply correctly
- [ ] Rofi launcher works
- [ ] Notification daemon (swaync) functions
- [ ] Multiple workspace navigation works
- [ ] Plugin functionality (if enabled)

### 3. Capture Configuration State
```bash
# Document current module structure
find modules/nixos/desktop/hyprland -name "*.nix" | wc -l
find modules/nixos/desktop/hyprland -type f -exec wc -l {} + | tail -1

# Record current inputs
nix flake metadata --json | jq '.locks.nodes | keys | map(select(test("hypr|waybar|rofi")))'
```

---

## Migration Testing Procedure

**Objective**: Validate each migration step progressively

### Phase 1: Flake Creation Testing
```bash
# 1. Create initial flake structure
cd /etc/nixos
mkdir -p flakes/hyprland

# 2. Test flake evaluation (before content)
cd flakes/hyprland
nix flake check  # Should pass with minimal flake.nix

# 3. Test main flake still works
cd /etc/nixos
nixos-rebuild build --flake .#$(hostname)  # Should still work
```

### Phase 2: Content Migration Testing
```bash
# 4. Test flake with migrated content
cd /etc/nixos/flakes/hyprland
nix flake check  # Must pass with all modules

# 5. Test module evaluation
nix eval .#nixosModules.default --json >/dev/null  # Must succeed

# 6. Test input resolution
nix flake metadata  # Verify all 10 hyprland inputs resolve
```

### Phase 3: Integration Testing
```bash
# 7. Test main flake integration
cd /etc/nixos
nixos-rebuild build --flake .#$(hostname)  # Must build successfully

# 8. Test configuration evaluation
nix show-config --flake .#$(hostname) | grep -i hyprland  # Verify config loads
```

---

## Post-Migration Validation

**Objective**: Confirm identical functionality after migration

### 1. Build Validation
```bash
# Test all relevant host configurations
nixos-rebuild build --flake .#asus-zephyrus-gu603
nixos-rebuild build --flake .#home-desktop

# Verify no configuration errors
journalctl -b | grep -i "error\|failed" | grep -i hyprland
```

### 2. Functional Testing
**Apply same checklist as pre-migration**:
- [ ] Hyprland starts successfully *(identical behavior)*
- [ ] Waybar displays correctly *(identical layout and modules)*
- [ ] Keybindings respond *(same key mappings)*
- [ ] Window rules apply correctly *(same rules, same behavior)*
- [ ] Rofi launcher works *(identical appearance and function)*
- [ ] Notification daemon functions *(same notification behavior)*
- [ ] Multiple workspace navigation *(same workspace switching)*
- [ ] Plugin functionality *(if enabled, same behavior)*

### 3. Performance Validation
```bash
# Test build performance
time nixos-rebuild build --flake .#$(hostname)

# Test flake evaluation performance
time nix eval .#nixosConfigurations.$(hostname).config.desktop.hyprland --json >/dev/null

# Test hyprland flake evaluation
cd flakes/hyprland && time nix eval .#nixosModules.default --json >/dev/null
```

---

## Independent Update Testing

**Objective**: Validate hyprland can be updated independently

### 1. Isolated Update Test
```bash
# Update only hyprland flake
cd /etc/nixos/flakes/hyprland
nix flake update

# Verify main configuration still builds
cd /etc/nixos
nixos-rebuild build --flake .#$(hostname)
```

### 2. Selective Input Updates
```bash
# Update specific hyprland ecosystem components
cd /etc/nixos/flakes/hyprland
nix flake update --input hyprland
nix flake update --input waybar

# Test incremental updates work
nixos-rebuild build --flake /etc/nixos#$(hostname)
```

---

## Rollback Procedure

**Purpose**: Safe recovery if migration issues are discovered

### Emergency Rollback
```bash
# 1. Return to previous git state
cd /etc/nixos
git status
git reset --hard HEAD~1  # Or specific commit before migration

# 2. Verify rollback works
nixos-rebuild build --flake .#$(hostname)

# 3. If needed, switch to working configuration
sudo nixos-rebuild switch --flake .#$(hostname)
```

### Partial Rollback (Keep Flake, Revert Integration)
```bash
# 1. Comment out hyprland flake input in main flake.nix
# 2. Restore original module imports in modules/nixos/desktop/default.nix
# 3. Test build
nixos-rebuild build --flake .#$(hostname)
```

---

## Troubleshooting Guide

### Common Issues

#### 1. Flake Evaluation Errors
**Symptoms**: `nix flake check` fails
**Debug**:
```bash
cd /etc/nixos/flakes/hyprland
nix flake check --show-trace  # Detailed error information
nix eval .#nixosModules.default --show-trace  # Module evaluation errors
```

#### 2. Missing Dependencies
**Symptoms**: Build fails with "package not found"
**Debug**:
```bash
# Check input resolution
nix flake metadata

# Verify package availability in specific input
nix search hyprland.packages.x86_64-linux hyprland
```

#### 3. Module Import Errors
**Symptoms**: Configuration evaluation fails
**Debug**:
```bash
# Test module loading in isolation
nix eval --expr 'import /etc/nixos/flakes/hyprland/default.nix'

# Check for import path issues
grep -r "modules/nixos/desktop/hyprland" /etc/nixos/hosts/
```

#### 4. Home Manager Integration Issues
**Symptoms**: User configuration not applied
**Debug**:
```bash
# Check home-manager service status
systemctl --user status home-manager

# Verify shared modules
nix eval .#nixosConfigurations.$(hostname).config.home-manager.sharedModules --json
```

### Recovery Commands
```bash
# Clean rebuild if caches are corrupted
nix-collect-garbage -d
nixos-rebuild build --flake .#$(hostname) --refresh

# Reset flake lock if dependency issues
cd /etc/nixos && rm flake.lock && nix flake lock
cd /etc/nixos/flakes/hyprland && rm flake.lock && nix flake lock
```

---

## Success Criteria

**Migration is successful when**:
1. ✅ All build commands pass without errors
2. ✅ Functional testing checklist items identical to pre-migration
3. ✅ Performance within acceptable ranges (< 10% regression)
4. ✅ Independent updates work correctly
5. ✅ No new warnings or errors in system logs
6. ✅ Rollback procedure tested and working

**Migration completion verified by**:
```bash
# Final validation command
cd /etc/nixos
nixos-rebuild build --flake .#$(hostname) && \
cd flakes/hyprland && nix flake check && \
echo "✅ Hyprland flake migration successful"
```