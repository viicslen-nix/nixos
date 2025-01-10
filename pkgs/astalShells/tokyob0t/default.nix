{
  system,
  astal,
  pkgs,
}: astal.lib.mkLuaPackage {
    inherit pkgs;
    name = "tokyob0t";
    src = ./.;

    extraPackages = [
      astal.packages.${system}.battery
      pkgs.dart-sass
    ];
}
