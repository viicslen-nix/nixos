let
  sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIVQJb4vtkKXIrgE440ywBqMLNKZvbLEbT7G5WEFIvL+";
in
{
  "env.age".publicKeys = [ sshKey ];
  "password.age".publicKeys = [ sshKey ];
}