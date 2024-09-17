let
  sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIVQJb4vtkKXIrgE440ywBqMLNKZvbLEbT7G5WEFIvL+";
in
{
  "restic/env.age".publicKeys = [ sshKey ];
  "restic/repo.age".publicKeys = [ sshKey ];
  "restic/password.age".publicKeys = [ sshKey ];
}