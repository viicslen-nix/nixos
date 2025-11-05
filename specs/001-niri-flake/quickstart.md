# Quickstart Guide: Extract Niri Desktop Configuration to Separate Flake

**Feature**: 001-niri-flake
**Date**: 2025-11-05

## Overview

This guide provides step-by-step instructions for testing and validating the niri flake migration. It covers flake evaluation, building, integration testing, and functional validation.

---

## Prerequisites

- NixOS system with flakes enabled
- Git repository at `/etc/nixos`
- Feature branch `001-niri-flake` checked out
- Existing niri configuration in `modules/nixos/desktop/niri/` (before migration)

---

## Quick Reference

```bash
# Stage 1: Flake Evaluation
cd /etc/nixos
nix flake check ./flakes/niri
nix flake show ./flakes/niri
nix flake metadata ./flakes/niri

# Stage 2: Independent Build
nix build ./flakes/niri

# Stage 3: Integration Build
nixos-rebuild build --flake .#asus-zephyrus-gu603

# Stage 4: System Switch
sudo nixos-rebuild switch --flake .#asus-zephyrus-gu603

# Stage 5: Update Independence
cd flakes/niri
nix flake update
cd ../..
git diff flake.lock  # Should show no changes

# Rollback (if needed)
sudo nixos-rebuild switch --rollback
```

---

## Stage 1: Flake Evaluation

**Purpose**: Verify the flake structure is valid and evaluates without errors

### Step 1.1: Check Flake Validity

```bash
cd /etc/nixos
nix flake check ./flakes/niri
```

**Expected Output**:
```
evaluating...
warning: (possible warnings about experimental features - ignore)
```

**Success Criteria**: No evaluation errors, exits with code 0

**Troubleshooting**:
- Syntax errors: Check `flakes/niri/flake.nix` for Nix syntax issues
- Missing inputs: Verify all inputs defined in research.md are present
- Import errors: Check relative paths in imports are correct

---

### Step 1.2: Show Flake Outputs

```bash
nix flake show ./flakes/niri
```

**Expected Output**:
```
path:/etc/nixos/flakes/niri
└───nixosModules
    ├───default: NixOS module
    └───niri: NixOS module
```

**Success Criteria**: Both `nixosModules.default` and `nixosModules.niri` listed

**Troubleshooting**:
- No outputs shown: Check `outputs` section in flake.nix
- Missing nixosModules: Verify outputs format matches research.md pattern

---

### Step 1.3: Check Flake Metadata

```bash
nix flake metadata ./flakes/niri
```

**Expected Output**:
```
Resolved URL:  path:/etc/nixos/flakes/niri
Locked URL:    path:/etc/nixos/flakes/niri
Description:   Niri desktop environment configuration
Path:          /nix/store/...
Inputs:
├───dankMaterialShell: github:AvengeMedia/DankMaterialShell/...
├───dgop: github:AvengeMedia/dgop/...
├───dms-cli: github:AvengeMedia/danklinux/...
├───niri-flake: github:sodiboo/niri-flake/...
└───nixpkgs: github:NixOS/nixpkgs/...
```

**Success Criteria**: All 5 inputs listed, description shows correctly

**Troubleshooting**:
- Missing inputs: Add to `inputs` section in flake.nix
- Wrong nixpkgs: Check `inputs.nixpkgs.follows` is set correctly

---

## Stage 2: Independent Build

**Purpose**: Verify the flake can build in isolation without main flake

### Step 2.1: Build Niri Flake

```bash
nix build ./flakes/niri
```

**Expected Behavior**:
- Evaluation starts immediately
- No "building" output (pure module, nothing to build)
- Completes quickly (< 10 seconds)

**Expected Output**:
```
warning: (possible experimental features warning)
```

**Success Criteria**: Exits with code 0, no errors

**Troubleshooting**:
- Evaluation errors: Module import paths likely wrong
- Infinite recursion: Check for circular dependencies in imports
- Missing attributes: Verify all referenced config paths exist

---

### Step 2.2: Inspect Build Result

```bash
ls -la result/
```

**Expected**: No result symlink created (modules don't produce build outputs)

**Note**: This is expected behavior for pure module flakes

---

## Stage 3: Integration Build

**Purpose**: Verify the main flake can consume the niri flake and build successfully

### Step 3.1: Verify Main Flake Input

```bash
cd /etc/nixos
grep -A 3 'niri.*=' flake.nix
```

**Expected Output**:
```nix
niri = {
  url = "path:./flakes/niri";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

**Success Criteria**: Input defined with local path and nixpkgs follows

---

### Step 3.2: Build System Configuration

```bash
nixos-rebuild build --flake .#asus-zephyrus-gu603
```

**Expected Behavior**:
- Builds main flake
- Evaluates niri flake
- Builds system configuration
- Creates `result` symlink

**Expected Duration**: 1-5 minutes depending on system

**Success Criteria**:
- Exits with code 0
- `result` symlink created
- No evaluation errors

**Troubleshooting**:
- "file not found" for niri modules: Check import paths in default.nix
- "infinite recursion": Circular dependency between main and niri flakes
- "attribute missing": Module options path changed, update host config
- Home manager errors: Check sharedModules injection in default.nix

---

### Step 3.3: Inspect Build Result

```bash
ls -l result/
```

**Expected**: System configuration symlink to `/nix/store/...`

```bash
nix-store --query --references result/ | grep niri
```

**Expected**: Should show niri-related store paths

---

## Stage 4: System Switch

**Purpose**: Apply the new configuration and verify runtime functionality

⚠️ **Warning**: This modifies your running system. Ensure you can rollback.

### Step 4.1: Switch to New Configuration

```bash
sudo nixos-rebuild switch --flake .#asus-zephyrus-gu603
```

**Expected Behavior**:
- Builds configuration (if not already built)
- Activates new system generation
- Restarts affected services
- Niri desktop session available

**Expected Duration**: 1-5 minutes

**Success Criteria**:
- Exits with code 0
- New generation activated
- No service failures

**Troubleshooting**:
- Services fail to start: Check systemd journal `journalctl -xe`
- Niri won't start: Check `~/.local/share/niri/niri.log`
- Display manager issues: Check display manager logs

---

### Step 4.2: Login to Niri Session

1. Log out of current session
2. Select "Niri" from display manager session menu
3. Log in

**Expected**: Niri desktop environment starts successfully

**Success Criteria**: Desktop loads with DankMaterialShell visible

---

## Stage 5: Functional Validation

**Purpose**: Verify all niri functionality works identically to before migration

### Step 5.1: Test Keybindings

Test each configured keybinding:

| Keybinding | Expected Action | Status |
|------------|----------------|--------|
| `Mod+Return` | Open terminal | ⬜ |
| `Mod+B` | Open browser | ⬜ |
| `Mod+E` | Open file manager | ⬜ |
| `Ctrl+Shift+Space` | Password manager quick access | ⬜ |
| `Mod+1` through `Mod+0` | Switch to workspace 1-10 | ⬜ |
| `Mod+Shift+1` through `Mod+Shift+0` | Move window to workspace 1-10 | ⬜ |
| `Mod+Q` | Close window | ⬜ |
| `Mod+T` | Toggle floating | ⬜ |
| `Mod+F` | Maximize column | ⬜ |
| `Mod+Shift+F` | Maximize window | ⬜ |
| `Mod+H/L` | Focus left/right | ⬜ |
| `Mod+K/J` | Focus up/down | ⬜ |
| `Mod+Shift+S` | Screenshot | ⬜ |

**Success Criteria**: All keybindings work as before

**Troubleshooting**:
- Keybinding doesn't work: Check `programs.niri.settings.binds` in `~/.config/niri/config.kdl`
- Application doesn't launch: Verify package is in PATH
- Wrong application launches: Check preference fallback resolution

---

### Step 5.2: Test Window Rules

1. Launch Ferdium: `ferdium`
2. Verify:
   - Opens floating
   - Positioned on right side
   - Takes 50% width
   - Has rounded corners

**Success Criteria**: Ferdium matches window rule from rules.nix

**Troubleshooting**:
- Rules don't apply: Check `niri msg windows` output
- Wrong positioning: Check `programs.niri.settings.window-rules` in config

---

### Step 5.3: Test Compositor Settings

Verify compositor behavior:

- [ ] Cursor hides after 2 seconds of inactivity
- [ ] Cursor hides when typing
- [ ] Mouse warps to focused window (center)
- [ ] Focus follows mouse
- [ ] Window gaps are 16 pixels
- [ ] Window borders are 4 pixels thick
- [ ] Screenshots save to `~/Pictures/Screenshots/`

**Success Criteria**: All settings match settings.nix configuration

---

### Step 5.4: Test Startup Applications

Check startup applications launched:

```bash
ps aux | grep -E 'polkit-gnome|gnome-keyring'
```

**Expected**: Both processes running

**Success Criteria**: All spawn-at-startup apps from settings.nix running

**Troubleshooting**:
- Apps not running: Check niri log for startup errors
- Password manager missing: Check fallback resolution

---

### Step 5.5: Test DankMaterialShell

Verify shell loaded:

- [ ] Material Design shell visible
- [ ] Stylix theme applied (if stylix enabled)
- [ ] System tray functional
- [ ] Workspace indicators visible
- [ ] Clock/date displayed

**Success Criteria**: DankMaterialShell fully functional

**Troubleshooting**:
- Shell missing: Check `~/.local/share/niri/niri.log` for shell errors
- Theme wrong: Verify `~/.config/DankMaterialShell/stylix.json` exists
- Widgets broken: Check DankMaterialShell logs

---

## Stage 6: Update Independence

**Purpose**: Verify the niri flake can be updated without affecting main flake

### Step 6.1: Update Niri Flake

```bash
cd /etc/nixos/flakes/niri
nix flake update
```

**Expected**: Updates `flakes/niri/flake.lock`

---

### Step 6.2: Verify Main Flake Unchanged

```bash
cd /etc/nixos
git diff flake.lock
```

**Expected Output**: Empty (no diff)

**Success Criteria**: Main `flake.lock` NOT modified by niri update

**Troubleshooting**:
- Main flake.lock changed: Input following not configured correctly
- Both locks changed: Check for shared inputs without follows

---

### Step 6.3: Rebuild with Updated Niri

```bash
sudo nixos-rebuild build --flake .#asus-zephyrus-gu603
```

**Expected**: Builds successfully with updated niri dependencies

**Success Criteria**: Build succeeds, niri still functional

---

## Stage 7: Rollback Testing

**Purpose**: Verify easy rollback if issues occur

### Step 7.1: List Generations

```bash
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

**Expected**: Shows all system generations including current

---

### Step 7.2: Rollback (Optional)

```bash
sudo nixos-rebuild switch --rollback
```

**Expected**: Reverts to previous generation (before niri flake migration)

**Success Criteria**: System boots with old configuration

---

### Step 7.3: Roll Forward (Optional)

```bash
sudo nixos-rebuild switch --flake .#asus-zephyrus-gu603
```

**Expected**: Returns to niri flake configuration

---

## Success Checklist

Mark each as complete:

- [ ] **Stage 1**: Flake evaluation passes
  - [ ] `nix flake check` succeeds
  - [ ] `nix flake show` displays outputs
  - [ ] `nix flake metadata` shows all inputs

- [ ] **Stage 2**: Independent build succeeds
  - [ ] `nix build ./flakes/niri` completes

- [ ] **Stage 3**: Integration build succeeds
  - [ ] Main flake input configured
  - [ ] `nixos-rebuild build` completes

- [ ] **Stage 4**: System switch succeeds
  - [ ] `nixos-rebuild switch` completes
  - [ ] Niri session available and starts

- [ ] **Stage 5**: Functionality validated
  - [ ] All keybindings work
  - [ ] Window rules apply
  - [ ] Compositor settings active
  - [ ] Startup apps launch
  - [ ] DankMaterialShell loads

- [ ] **Stage 6**: Update independence verified
  - [ ] Niri flake updates independently
  - [ ] Main flake.lock unchanged
  - [ ] Rebuild succeeds with updates

- [ ] **Stage 7**: Rollback tested
  - [ ] Can list generations
  - [ ] Rollback works (if tested)

---

## Common Issues and Solutions

### Issue: "experimental-features" Warning

**Symptom**: Warning about experimental features when running nix commands

**Solution**: Expected and harmless. Flakes are still experimental. Can suppress with:
```bash
export NIX_CONFIG="experimental-features = nix-command flakes"
```

---

### Issue: "path does not exist" for niri flake

**Symptom**: Error that `./flakes/niri` doesn't exist

**Solution**:
1. Verify directory exists: `ls -la flakes/niri/`
2. Verify flake.nix exists: `ls -la flakes/niri/flake.nix`
3. Check working directory is `/etc/nixos`

---

### Issue: Module option not found

**Symptom**: Error like "attribute 'modules.desktop.niri' missing"

**Solution**:
1. Verify default.nix defines options correctly
2. Check import in main flake or host configuration
3. Ensure niri flake output is `nixosModules.default`

---

### Issue: Home manager integration broken

**Symptom**: Niri settings don't apply per-user

**Solution**:
1. Check default.nix uses `home-manager.sharedModules`
2. Verify homeManagerLoaded check is correct
3. Confirm home-manager is enabled in host configuration

---

### Issue: Keybindings don't work

**Symptom**: Pressing keybinding does nothing

**Solution**:
1. Check application preference is set or has valid fallback
2. Verify application package is installed
3. Check niri config: `niri msg version` (tests niri is running)
4. Check generated config has binding: `grep "Mod+Return" ~/.config/niri/config.kdl`

---

### Issue: DankMaterialShell missing

**Symptom**: No shell/panel visible in niri

**Solution**:
1. Check shell.nix imports dankMaterialShell modules
2. Verify `programs.dankMaterialShell.enable = true`
3. Check niri log: `cat ~/.local/share/niri/niri.log | grep -i shell`
4. Verify dankMaterialShell in inputs

---

## Performance Benchmarks

Expected performance for each stage:

| Stage | Expected Duration | Notes |
|-------|------------------|-------|
| Flake check | < 5 seconds | Pure evaluation |
| Flake show | < 3 seconds | Quick metadata |
| Independent build | < 10 seconds | No actual building |
| Integration build | 1-5 minutes | Depends on cache |
| System switch | 1-5 minutes | First time longer |
| Update niri flake | 10-30 seconds | Network dependent |

---

## Next Steps

After successful validation:

1. **Commit changes**: `git add . && git commit -m "feat: extract niri to separate flake"`
2. **Merge to main**: `git checkout main && git merge 001-niri-flake`
3. **Deploy to other hosts**: Repeat testing on other machines using niri
4. **Document**: Update README.md with new flake structure
5. **Clean up**: Remove old `modules/nixos/desktop/niri/` directory reference from docs

---

## Support

If issues persist after following this guide:

1. Check niri logs: `~/.local/share/niri/niri.log`
2. Check system logs: `journalctl -xe`
3. Verify nixos-rebuild output for clues
4. Compare with research.md decisions
5. Review data-model.md for structure expectations

---

**Last Updated**: 2025-11-05
**Validated On**: NixOS unstable, Nix 2.18+
