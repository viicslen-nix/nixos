# use zshell for shell commands
set shell := ["zsh", "-c"]

############################################################################
#
#  Common commands(suitable for all machines)
#
############################################################################

# Run eval tests
test:
  nix eval .#evalTests --show-trace --print-build-logs --verbose

# update all the flake inputs
update:
  nix flake update

# Update specific input
# Usage: just upgrade nixpkgs
update-input INPUT:
  nix flake update {{INPUT}}

# Upgrade the system using the default nix command
nix-upgrade COMMAND='switch':
  sudo nixos-rebuild {{COMMAND}}

# Upgrade the system using the nix helper utility
upgrade COMMAND='switch':
  nh os {{COMMAND}}

# Commit any pending file changes and upgrade the system
commit-and-upgrade:
  nixos-upgrade

# Commit any pending file changes
commit MESSAGE:
  git add .
  git commit -m "{{MESSAGE}}"

# Commit any pending file changes
push MESSAGE:
  git add .
  git commit -m "{{MESSAGE}}"
  git push

# List all generations of the system profile
history:
  nix profile history --profile /nix/var/nix/profiles/system

# Open a nix shell with the flake
repl:
  nix repl -f flake:nixpkgs

# remove all generations older than 7 days
clean:
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

# Garbage collect all unused nix store entries
gc:
  sudo nix store gc --debug
  sudo nix-collect-garbage --delete-old

link:
  sudo ln -s ~/.nix /etc/nixos


############################################################################
#
#  Misc, other useful commands
#
############################################################################

fmt:
  # format the nix files in this repo
  nix fmt

path:
   $env.PATH | split row ":"