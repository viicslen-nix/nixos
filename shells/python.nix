{pkgs, ...}:
pkgs.mkShell {
  packages = with pkgs; [
    python3
  ];

  shellHook = ''
    exec zsh
  '';
}
