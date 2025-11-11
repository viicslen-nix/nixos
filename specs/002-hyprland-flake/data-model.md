# Data Model: Hyprland Flake Module Structure

**Feature**: 002-hyprland-flake  
**Phase 1 Deliverable**: Module structure documentation

---

## Flake Output Schema

```nix
{
  # Primary output - consumable NixOS modules
  nixosModules = {
    default = ./default.nix;  # Main hyprland configuration module
  };
  
  # Development utilities
  devShells = {
    default = mkShell { ... };  # Development shell for flake testing
  };
  
  # Package outputs (if any hyprland-specific packages needed)
  packages = {
    # Currently none - all packages come from upstream inputs
  };
}
```

**Consumption Pattern** (in main flake.nix):
```nix
{
  inputs = {
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

---

## Module Hierarchy

### 1. Root Module (`default.nix`)

**Purpose**: Main module that exposes configuration options and coordinates component modules

**Interface**:
```nix
{
  options.desktop.hyprland = {
    enable = mkEnableOption "Hyprland desktop environment";
    gnomeCompatibility = mkOption { ... };
    # ... existing options preserved
  };
  
  config = mkIf cfg.enable {
    # Import all component modules
    imports = [
      ./config/binds.nix
      ./config/env.nix 
      ./config/rules.nix
      ./config/settings.nix
      ./config/plugins.nix
      ./config/pyprland.nix
      ./components/waybar
      ./components/rofi
      # ... 20+ other components
    ];
    
    # Core hyprland service configuration
    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    };
  };
}
```

**Dependencies**: All component modules, flake inputs (hyprland, waybar, etc.)

---

### 2. Core Configuration (`config/`)

**Purpose**: System-level hyprland configuration (keybinds, rules, settings)

#### 2.1 `config/binds.nix`
- **Function**: Defines keybinding mappings and shortcuts
- **Home Manager**: Yes - exports wayland.windowManager.hyprland.settings.bind
- **External Dependencies**: None (pure key mapping)
- **Options Exposed**: keybind customization

#### 2.2 `config/env.nix`  
- **Function**: Environment variables and session setup
- **Home Manager**: Yes - session variables and environment
- **External Dependencies**: None
- **Options Exposed**: environment variable overrides

#### 2.3 `config/rules.nix`
- **Function**: Window rules and workspace assignments
- **Home Manager**: Yes - windowrules and workspace configs
- **External Dependencies**: None
- **Options Exposed**: window rule customization

#### 2.4 `config/settings.nix`
- **Function**: Core hyprland compositor settings  
- **Home Manager**: Yes - general hyprland settings
- **External Dependencies**: None
- **Options Exposed**: animation, layout, input settings

#### 2.5 `config/plugins.nix`
- **Function**: Hyprland plugin management
- **Home Manager**: No - system-level plugin loading
- **External Dependencies**: hyprland-plugins input
- **Options Exposed**: plugin enable/disable options

#### 2.6 `config/pyprland.nix`
- **Function**: Pyprland utility configuration
- **Home Manager**: Yes - user-level pyprland config
- **External Dependencies**: pyprland input
- **Options Exposed**: pyprland module configuration

---

### 3. Component Modules (`components/`)

**Purpose**: Individual desktop components that integrate with hyprland

#### 3.1 `components/waybar/` (directory)
- **Function**: Status bar configuration and theming
- **Files**: `default.nix`, `config.nix`, `style.css.nix`
- **Home Manager**: Yes - programs.waybar configuration
- **External Dependencies**: waybar input, font packages
- **Options Exposed**: waybar module customization, theme selection

#### 3.2 `components/rofi/` (directory)  
- **Function**: Application launcher and menu system
- **Files**: `default.nix`, `theme.nix` 
- **Home Manager**: Yes - programs.rofi configuration
- **External Dependencies**: rofi-wayland package
- **Options Exposed**: rofi theme and behavior options

#### 3.3 `components/swaync.nix` 
- **Function**: Notification daemon for wayland
- **Home Manager**: Yes - services.swaync
- **External Dependencies**: swaynotificationcenter package
- **Options Exposed**: notification behavior and theming

#### 3.4 Additional Components (20+ modules)
Similar structure for: hyprpaper, hypridle, wofi, wlogout, hyprlock, etc.
- Each component: single .nix file or directory for complex components
- All follow same pattern: home-manager integration + external dependencies + exposed options

---

## Integration Patterns

### Home Manager Integration
**Pattern**: All modules use home-manager's sharedModules for user configuration
```nix
home-manager.sharedModules = [
  {
    wayland.windowManager.hyprland = {
      # Component-specific hyprland settings
    };
    programs.componentName = {
      # Component-specific program settings
    };
  }
];
```

### Service Dependencies
**Pattern**: Services declare systemd dependencies and ordering
```nix
systemd.user.services.componentName = {
  requires = [ "hyprland-session.target" ];
  after = [ "hyprland-session.target" ];
  # ...
};
```

### Package Management  
**Pattern**: Packages declared in home.packages or environment.systemPackages
```nix
environment.systemPackages = with pkgs; [
  # System-wide packages (hyprland itself)
];

home-manager.sharedModules = [{
  home.packages = with pkgs; [
    # User packages (utilities, themes)
  ];
}];
```

---

## Data Flow

```
Main Flake → Hyprland Flake → Module Hierarchy
    ↓              ↓               ↓
nixosModules → default.nix → config/ + components/
    ↓              ↓               ↓  
Host Config → Options API → Service Configuration
    ↓              ↓               ↓
NixOS System → Home Manager → User Environment
```

**Key Relationships**:
1. **Inputs Flow**: Main flake inputs → Hyprland flake inputs → Module dependencies
2. **Config Flow**: Host options → Module options → Component configuration  
3. **Build Flow**: Flake evaluation → Module imports → Service definitions
4. **Runtime Flow**: NixOS activation → Home Manager → Desktop environment

---

## Migration Mapping

### Input Dependencies
```
Main flake.nix inputs section:
hyprland → flakes/hyprland/flake.nix inputs.hyprland
waybar → flakes/hyprland/flake.nix inputs.waybar  
pyprland → flakes/hyprland/flake.nix inputs.pyprland
[...8 more dependencies...]
```

### Module Path Updates
```
modules/nixos/desktop/hyprland/default.nix → flakes/hyprland/default.nix
modules/nixos/desktop/hyprland/config/ → flakes/hyprland/config/
modules/nixos/desktop/hyprland/components/ → flakes/hyprland/components/
```

### Import Reference Updates
```
# Host configurations
hosts/*/default.nix:
  OLD: ./modules/nixos/desktop/hyprland
  NEW: inputs.hyprland-flake.nixosModules.default

# Module aggregation  
modules/nixos/desktop/default.nix:
  OLD: ./hyprland  
  NEW: (removed - consumed via flake input)
```

---

This data model preserves the existing modular structure while adapting it to flake outputs. All 30+ modules maintain their current interface and functionality, just organized under the flake pattern.