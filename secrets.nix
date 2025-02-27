let
  sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIVQJb4vtkKXIrgE440ywBqMLNKZvbLEbT7G5WEFIvL+";
in {
  "secrets/restic/env.age".publicKeys = [sshKey];
  "secrets/restic/password.age".publicKeys = [sshKey];
  "secrets/github/runner.age".publicKeys = [sshKey];
  "secrets/intelephense/licence.age".publicKeys = [sshKey];
}
