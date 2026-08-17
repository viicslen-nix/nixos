let
  sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIVQJb4vtkKXIrgE440ywBqMLNKZvbLEbT7G5WEFIvL+";
in {
  "secrets/restic/env.age".publicKeys = [sshKey];
  "secrets/restic/password.age".publicKeys = [sshKey];
  "secrets/github/runner.age".publicKeys = [sshKey];
  "secrets/intelephense/licence.age".publicKeys = [sshKey];
  "secrets/avante/anthropic-api-key.age".publicKeys = [sshKey];
  "secrets/mkcert/rootCA.age".publicKeys = [sshKey];
  "secrets/mkcert/rootCA-key.age".publicKeys = [sshKey];
  "secrets/prod-db/mysql-password.age".publicKeys = [sshKey];
  "secrets/grafana/service-account-token.age".publicKeys = [sshKey];
}
