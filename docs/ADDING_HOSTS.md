# Adding New Hosts

This guide walks you through adding a new host configuration to this NixOS flake.

## Quick Start

### Option 1: Manual Creation

1. **Create host directory**
   ```bash
   mkdir -p hosts/my-host
   ```

2. **Create basic configuration**
   ```bash
   touch hosts/my-host/default.nix
   touch hosts/my-host/hardware.nix
   ```

3. **Register the host**
   Edit `hosts/default.nix` and add your host to the `hosts` attribute set.

4. **Build and test**
   ```bash
   just build my-host
   ```

### Option 2: Copy Existing Host

```bash
cp -r hosts/home-desktop hosts/my-host
# Edit the files to customize
```

## Step-by-Step Guide

### 1. Create Host Directory

```bash
mkdir -p hosts/my-host
cd hosts/my-host
```

### 2. Create Hardware Configuration

Generate hardware config on the target machine:

```bash
nixos-generate-config --show-hardware-config > hardware.nix
```

Or create manually:

```nix
# hosts/my-host/hardware.nix
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/...";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/...";
    fsType = "vfat";
  };

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
```

### 3. Create Main Configuration

```nix
# hosts/my-host/default.nix
{ lib, pkgs, config, ... }:

{
  imports = [
    ./hardware.nix
  ];

  # Hostname
  networking.hostName = "my-host";
  networking.hostId = "12345678";  # Generate with: head -c4 /dev/urandom | od -A none -t x4

  # Bootloader
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Enable modules
  modules = {
    hardware = {
      # Enable as needed
      # intel.enable = true;
      # nvidia.enable = true;
    };
    
    desktop = {
      # Choose desktop environment
      # gnome.enable = true;
    };
    
    programs = {
      # Enable programs
      # docker.enable = true;
    };
  };

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    git
  ];
}
```

### 4. Register Host

Edit `hosts/default.nix` and add your host to the `hosts` attribute set.

**The path defaults to the attribute name**, so you only need to specify `system` and optional `presets`:

```nix
{
  inputs,
  outputs,
}: {
  shared = {
    # ... shared config
  };

  hosts = {
    # ... existing hosts
    
    my-host = {
      system = "x86_64-linux";  # or "aarch64-linux"
      presets = ["base" "work" "personal"];  # Optional preset list
      # path = ./custom-path;  # Optional: defaults to ./my-host
    };
    };
    };
  };
}
```

### 5. Build and Deploy

```bash
# Build (dry-run)
just build my-host

# Deploy
just switch my-host  # if on the target machine
# or
nixos-rebuild switch --flake /etc/nixos#my-host
```

## Available Presets

Presets are specified in `hosts/default.nix` for each host. Available presets:

- **`base`** - Essential system setup (users, fonts, Home Manager, common packages, Nix settings)
- **`work`** - Development tools (PHP, Node.js, Go, containers, SSH configs)
- **`personal`** - Personal apps (nix-alien, QMK, personal containers)
- **`linode`** - Linode VPS server configuration

Example configuration in `hosts/default.nix`:
```nix
my-host = {
  system = "x86_64-linux";
  presets = ["base" "work" "personal"];  # List presets to apply
  # path defaults to ./my-host based on attribute name
};
```

**No need to import** presets in individual host files - just list them in `hosts/default.nix`!

## Optional Configurations

### Disk Partitioning (Disko)

Create `hosts/my-host/disko.nix`:

```nix
{ device ? "/dev/sda" }:
{
  disko.devices = {
    disk = {
      main = {
        inherit device;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
```

Import in `default.nix`:

```nix
imports = [
  inputs.disko.nixosModules.disko
  (import ./disko.nix { device = "/dev/sda"; })
  ./hardware.nix
];
```

### Home Manager Configuration

Create `hosts/my-host/home.nix`:

```nix
{ config, pkgs, ... }:

{
  # User-specific home-manager configuration
  home.packages = with pkgs; [
    neovim
    tmux
  ];

  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "you@example.com";
  };
}
```

Import in `default.nix`:

```nix
{
  # ...
  
  home-manager.sharedModules = [ ./home.nix ];
}
```

## Host Types

### Desktop/Laptop

In `hosts/default.nix`:
```nix
my-desktop = {
  system = "x86_64-linux";
  presets = ["base" "personal"];  # Path defaults to ./my-desktop
};
```

In host configuration:
```nix
modules = {
  hardware = {
    intel.enable = true;
    bluetooth.enable = true;
  };
  
  desktop.gnome.enable = true;
  
  programs = {
    steam.enable = true;
    docker.enable = true;
  };
  
  core = {
    sound.enable = true;
    theming.enable = true;
  };
  
  services.powerManagement.enable = true;
};
```

### Server

In `hosts/default.nix`:
```nix
my-server = {
  system = "x86_64-linux";
  presets = ["base"];  # Path defaults to ./my-server
};
```

In host configuration:
```nix
modules = {
  programs.docker.enable = true;
  
  functionality = {
    network.enable = true;
    backups.enable = true;
  };
};

# Disable GUI
services.xserver.enable = false;
```

### WSL

```nix
imports = [
  inputs.nixos-wsl.nixosModules.wsl
];

wsl = {
  enable = true;
  defaultUser = "neoscode";
};

modules.presets.base.enable = true;
```

## Common Configurations

### User Accounts

```nix
users = {
  mutableUsers = false;
  
  users.myuser = {
    isNormalUser = true;
    description = "My User";
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    hashedPassword = "$6$...";  # Generate with: mkpasswd -m sha-512
  };
};
```

### Network

```nix
networking = {
  hostName = "my-host";
  hostId = "12345678";
  networkmanager.enable = true;
  
  firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];
  };
  
  # Custom hosts
  extraHosts = ''
    192.168.1.100 server.local
  '';
};
```

### Locale & Timezone

```nix
time.timeZone = "America/New_York";

i18n = {
  defaultLocale = "en_US.UTF-8";
  extraLocaleSettings = {
    LC_TIME = "en_US.UTF-8";
  };
};
```

## Testing

### Build Test

```bash
just build my-host
```

### VM Test

```bash
nixos-rebuild build-vm --flake .#my-host
./result/bin/run-my-host-vm
```

### Validation

```bash
just validate
```

## Troubleshooting

### Build Errors

1. **Check syntax**
   ```bash
   just check-file hosts/my-host/default.nix
   ```

2. **Check imports**
   Ensure all imported files exist and are valid.

3. **Check module options**
   ```bash
   nix eval .#nixosConfigurations.my-host.config.modules
   ```

### Boot Issues

1. Check hardware config matches actual hardware
2. Verify bootloader configuration
3. Check file system UUIDs

### Missing Features

Ensure required modules are:
1. Imported in `modules/nixos/default.nix`
2. Enabled in host config
3. Have their dependencies met

## Best Practices

1. **Start Simple** - Begin with minimal config, add features incrementally
2. **Test Builds** - Always build before deploying
3. **Use Presets** - Leverage presets for common configurations
4. **Document** - Add comments for non-obvious settings
5. **Version Control** - Commit working configs before major changes

---

*See also: [MODULES.md](./MODULES.md) for available modules*
