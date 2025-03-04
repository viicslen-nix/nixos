{
  pkgs,
  inputs,
}:
inputs.astal.lib.mkLuaPackage {
  inherit pkgs;
  name = "tokyob0t";
  src = ./.;

  extraPackages = [
    pkgs.inputs.astal.battery
    pkgs.dart-sass
  ];
}
