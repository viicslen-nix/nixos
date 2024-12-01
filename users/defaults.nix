{
  lib,
  user,
  description,
  password,
  ...
}: {
  users.users.${user} = {
    isNormalUser = true;
    inherit description;
    initialPassword = lib.mkIf (password == "") user;
    hashedPassword = lib.mkIf (password != "") password;
    extraGroups = ["networkmanager" user];
  };

  modules = {
    desktop = {
      gnome.users = [user];
      hyprland.users = [user];
    };

    programs = {
      docker.users = [user];
      mkcert.rootCA.users = [user];
      onePassword.users = [user];
    };
  };
}
