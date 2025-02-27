{pkgs}: with pkgs; vimUtils.buildVimPlugin {
  src = fetchFromGitHub {
    owner = "V13Axel";
    repo = "neotest-pest";
    rev = "v1.0";
    sha256 = "";
  };
  pname = "neotest-pest";
  version = "1.0";
}
