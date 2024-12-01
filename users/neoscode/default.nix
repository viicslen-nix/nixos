{
  lib,
  config,
  ...
}: let
  user = {
    name = "neoscode";
    description = "Victor R";
    password = "$6$hl2eKy3qKB3A7hd8$8QMfyUJst4sRAM9e9R4XZ/IrQ8qyza9NDgxRbo0VAUpAD.hlwi0sOJD73/N15akN9YeB41MJYoAE9O53Kqmzx/";
  };
in {
  users.users.${user.name} = {
    isNormalUser = true;
    description = user.description;
    initialPassword = lib.mkIf (user.password == "") user.name;
    hashedPassword = lib.mkIf (user.password != "") user.password;
    extraGroups = ["networkmanager" "wheel" user.name];
  };

  home-manager.users.${user.name}.imports = [(import ./home.nix { 
    user = user.name; 
    name = user.description;
  })];

  modules.functionality.backups = {
    home.users = [user.name];
    paths = ["/persist/home/${user.name}/Development"];
  };

  age.identityPaths = ["${config.users.users.${user.name}.home}/.ssh/agenix"];
}