{pkgs, ...}: {
  home.packages = with pkgs; [
    inputs.shell.default
  ];
}
