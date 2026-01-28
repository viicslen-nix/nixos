# Secrets Management with Agenix

This configuration uses [agenix](https://github.com/ryantm/agenix) for managing encrypted secrets.

## Overview

Agenix encrypts secrets with SSH keys, allowing:
- Secrets in Git repository (encrypted)
- Decryption at build/runtime only
- Key-based access control
- Age encryption format

## Directory Structure

```
secrets/
├── default.nix          # Imports secrets.nix
├── secrets.nix          # Secret file definitions
├── restic/              # Restic backup secrets
│   ├── env.age
│   └── password.age
├── github/              # GitHub secrets
│   └── runner.age
├── intelephense/        # Intelephense license
│   └── licence.age
├── avante/              # Avante API keys
│   └── anthropic-api-key.age
└── mkcert/              # mkcert certificates
    ├── rootCA.age
    └── rootCA-key.age
```

## Configuration

### `secrets/secrets.nix`

Defines which secrets exist and who can decrypt them:

```nix
let
  # SSH public keys that can decrypt secrets
  sshKey = "ssh-ed25519 AAAAC3Nza...";
in {
  "secrets/restic/env.age".publicKeys = [sshKey];
  "secrets/restic/password.age".publicKeys = [sshKey];
  "secrets/github/runner.age".publicKeys = [sshKey];
  # ... more secrets
}
```

## Managing Secrets

### Prerequisites

Install agenix:
```bash
nix-env -iA nixpkgs.agenix
```

Or use it from the flake:
```bash
nix run github:ryantm/agenix -- --help
```

### Creating a Secret

1. **Create/Edit Secret**
   ```bash
   agenix -e secrets/myapp/api-key.age
   ```
   
   This opens your `$EDITOR` with the decrypted content.

2. **Add to secrets.nix**
   ```nix
   let
     sshKey = "ssh-ed25519 ...";
   in {
     # ... existing secrets
     "secrets/myapp/api-key.age".publicKeys = [sshKey];
   }
   ```

3. **Commit**
   ```bash
   git add secrets/myapp/api-key.age secrets/secrets.nix
   git commit -m "Add API key secret"
   ```

### Editing a Secret

```bash
agenix -e secrets/myapp/api-key.age
```

### Re-keying Secrets

When SSH keys change, rekey all secrets:

```bash
agenix --rekey
```

## Using Secrets in Configuration

### System-Level Secret

```nix
{ config, ... }:
{
  age.secrets.github-runner = {
    file = ../secrets/github/runner.age;
    owner = "github-runner";
    group = "github-runner";
    mode = "0400";
  };

  services.github-runner = {
    enable = true;
    tokenFile = config.age.secrets.github-runner.path;
  };
}
```

### User-Level Secret (Home Manager)

```nix
{ config, ... }:
{
  age.secrets.anthropic-api-key = {
    file = ../secrets/avante/anthropic-api-key.age;
  };

  home.sessionVariables = {
    ANTHROPIC_API_KEY_FILE = config.age.secrets.anthropic-api-key.path;
  };
}
```

### File Installation

```nix
{ config, ... }:
{
  age.secrets.mkcert-ca = {
    file = ../secrets/mkcert/rootCA.age;
  };

  age.secrets.mkcert-ca-key = {
    file = ../secrets/mkcert/rootCA-key.age;
    mode = "0600";
  };

  # Link to expected location
  system.activationScripts.mkcert = ''
    mkdir -p /root/.local/share/mkcert
    ln -sf ${config.age.secrets.mkcert-ca.path} /root/.local/share/mkcert/rootCA.pem
    ln -sf ${config.age.secrets.mkcert-ca-key.path} /root/.local/share/mkcert/rootCA-key.pem
  '';
}
```

## SSH Keys

### Your SSH Key

Find your public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

Or generate one:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

### Adding Multiple Keys

For team access:

```nix
let
  user1 = "ssh-ed25519 AAAAC3...";
  user2 = "ssh-ed25519 AAAAC3...";
  ci = "ssh-ed25519 AAAAC3...";
in {
  "secrets/shared/api-key.age".publicKeys = [user1 user2 ci];
}
```

### Host-Specific Secrets

```nix
let
  userKey = "ssh-ed25519 ...";
  hostKey = "ssh-ed25519 ...";  # /etc/ssh/ssh_host_ed25519_key.pub
in {
  "secrets/host-specific/key.age".publicKeys = [userKey hostKey];
}
```

## Best Practices

### 1. Never Commit Plaintext

- ❌ Don't commit `.env`, `config.json` with secrets
- ✅ Encrypt with agenix, commit `.age` files

### 2. Use Appropriate Permissions

```nix
age.secrets.my-secret = {
  file = ../secrets/my-secret.age;
  owner = "service-user";  # Owner of the secret file
  group = "service-group";
  mode = "0400";           # Read-only for owner
};
```

### 3. Organize by Service

```
secrets/
├── restic/      # Backup service
├── github/      # CI/CD
├── myapp/       # Application secrets
└── certs/       # Certificates
```

### 4. Document Required Secrets

In module documentation:

```nix
# This module requires:
# - secrets/myapp/api-key.age
# - secrets/myapp/database-password.age
```

### 5. Rotate Secrets Regularly

1. Create new secret
2. Update secret file: `agenix -e secrets/old-secret.age`
3. Update application
4. Test
5. Commit

## Security Considerations

### What's Protected

- ✅ Secret content is encrypted
- ✅ Only authorized keys can decrypt
- ✅ Secrets decrypted at runtime only

### What's Not Protected

- ⚠️ Secret file names are visible
- ⚠️ Anyone with repo access sees encrypted files
- ⚠️ Root on target system can read decrypted secrets

### Recommendations

1. **Limit Repository Access** - Only trusted users
2. **Secure SSH Keys** - Password-protect private keys
3. **Minimize Secret Scope** - Only grant access to needed hosts
4. **Audit Changes** - Review secret additions in Git history
5. **Rotate Keys** - Regular rotation schedule

## Troubleshooting

### "No such secret"

Secret not defined in `secrets/secrets.nix`:

```nix
"secrets/path/to/secret.age".publicKeys = [sshKey];
```

### Permission Denied

Check:
1. Your SSH key is listed in `publicKeys`
2. SSH key exists and is accessible
3. Run `agenix` with correct key: `agenix -i ~/.ssh/id_ed25519 -e secret.age`

### Can't Decrypt on Host

The host's SSH key must be in `publicKeys`. Get it:

```bash
sudo cat /etc/ssh/ssh_host_ed25519_key.pub
```

Add to `secrets/secrets.nix` and rekey:

```bash
agenix --rekey
```

### Secret Path Issues

Secrets are decrypted to `/run/agenix/`:

```nix
# Access via config.age.secrets.<name>.path
config.age.secrets.my-secret.path
# Results in: /run/agenix/my-secret
```

## Migration from Other Tools

### From SOPS-nix

1. Decrypt with sops: `sops -d secret.yaml`
2. Encrypt with agenix: `agenix -e secret.age`
3. Update configuration to use agenix
4. Remove sops files

### From Plain Files

1. For each secret file:
   ```bash
   cat secret.txt | agenix -e secrets/secret.age
   ```
2. Update references in configuration
3. Delete plain files (after testing!)
4. Remove from `.gitignore` if needed

## Advanced Usage

### Environment Files

For `.env` style secrets:

```nix
age.secrets.app-env = {
  file = ../secrets/app/env.age;
};

systemd.services.myapp = {
  serviceConfig = {
    EnvironmentFile = config.age.secrets.app-env.path;
  };
};
```

### Multiple Recipients

```nix
let
  users = [
    "ssh-ed25519 AAAA... user1"
    "ssh-ed25519 AAAA... user2"
  ];
  hosts = [
    "ssh-ed25519 AAAA... host1"
    "ssh-ed25519 AAAA... host2"
  ];
in {
  "secrets/shared.age".publicKeys = users ++ hosts;
}
```

---

*For more security best practices, see NixOS security documentation*
