# flake.nix Output Contract

**Contract Type**: Flake output specification  
**Purpose**: Define the interface that the hyprland flake must expose for consumption by the main configuration

---

## Flake Outputs Schema

```nix
{
  description = "Hyprland desktop environment configuration flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # Hyprland ecosystem inputs
    hyprland.url = "github:hyprwm/Hyprland";
    waybar.url = "github:Alexays/Waybar";
    pyprland.url = "github:hyprland-community/pyprland"; 
    hyprland-contrib.url = "github:hyprwm/contrib";
    hyprland-plugins.url = "github:hyprwm/hyprland-plugins";
    hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";
    hypridle.url = "github:hyprwm/hypridle";
    hyprpaper.url = "github:hyprwm/hyprpaper";
    hyprspace.url = "github:KZDKM/Hyprspace";
    hyprsplit.url = "github:shezdy/hyprsplit"; 
    hyprchroma.url = "github:alexhulbert/Hyprchroma";
  };

  outputs = { nixpkgs, ... } @ inputs: {
    # REQUIRED: Main module output
    nixosModules.default = import ./default.nix inputs;
    
    # OPTIONAL: Development utilities  
    devShells.x86_64-linux.default = /* development shell */;
    
    # OPTIONAL: Formatter for flake development
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;
  };
}
```

---

## NixOS Module Interface

**Contract**: The `nixosModules.default` output must provide a NixOS module with the following interface:

### Required Options
```nix
{
  options.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland desktop environment";
    
    gnomeCompatibility = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable GNOME compatibility features";
    };
    
    # Additional existing options must be preserved exactly
    # ... (all current options from modules/nixos/desktop/hyprland/default.nix)
  };
}
```

### Required Services
When `config.desktop.hyprland.enable = true`, the module must provide:

1. **Core Hyprland Service**
   ```nix
   programs.hyprland = {
     enable = true;
     package = /* from hyprland input */;
   };
   ```

2. **Home Manager Integration**
   ```nix
   home-manager.sharedModules = [
     # User-level hyprland configuration
     # Component configurations (waybar, rofi, etc.)
   ];
   ```

3. **System Packages**
   ```nix
   environment.systemPackages = [
     # Essential hyprland utilities
   ];
   ```

### Required Behavior
- **Backward Compatibility**: All existing options must work identically
- **Home Manager**: User configurations must be applied via sharedModules
- **Dependencies**: All hyprland ecosystem packages must be available
- **Services**: systemd services must start correctly with dependencies

---

## Consumption Contract

**Pattern**: Main flake must consume hyprland flake via local path input:

```nix
{
  inputs = {
    # Other inputs...
    hyprland-flake = {
      url = "path:./flakes/hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  
  outputs = { nixpkgs, hyprland-flake, ... }: {
    nixosConfigurations.hostname = nixpkgs.lib.nixosSystem {
      modules = [
        hyprland-flake.nixosModules.default
        # ... other modules
      ];
    };
  };
}
```

**Requirements**:
- Must follow nixpkgs for dependency consistency
- Must work with existing host configurations unchanged
- Must support multiple hosts consuming same flake

---

## Testing Contract

The flake must pass these validation checks:

### 1. Flake Structure Tests
```bash
nix flake check ./flakes/hyprland  # Must pass without errors
nix eval ./flakes/hyprland#nixosModules.default --json  # Must return module
```

### 2. Integration Tests  
```bash
# Must build successfully with flake integration
nixos-rebuild build --flake .#asus-zephyrus-gu603
nixos-rebuild build --flake .#home-desktop
```

### 3. Module Validation Tests
```bash
# Options must be available and documented
nix eval ./flakes/hyprland#nixosModules.default.options.desktop.hyprland --json
```

### 4. Functionality Tests
- Hyprland desktop environment starts correctly
- All keybindings work as configured
- Waybar and components display properly
- Window rules apply correctly
- Home manager integration functions

---

## Compatibility Contract

**Guarantee**: After migration, these must work identically:

1. **Host Configuration**: `desktop.hyprland.enable = true;` 
2. **Options**: All current hyprland options and their defaults
3. **Keybindings**: Existing keybind configuration unchanged
4. **Components**: Waybar, rofi, notification daemon functionality
5. **Home Manager**: User-level customizations preserved
6. **Multiple Hosts**: asus-zephyrus-gu603 and home-desktop both work

**Breaking Changes**: None allowed - this is a structural migration only.

---

## Versioning Contract

**Independent Updates**: The hyprland flake can be updated independently via:
```bash
cd flakes/hyprland && nix flake update
# OR update specific inputs:
nix flake update --input hyprland ./flakes/hyprland
```

**Main Configuration**: Remains stable while hyprland ecosystem updates independently

**Lock File**: `flakes/hyprland/flake.lock` manages hyprland ecosystem versions separately from main `flake.lock`