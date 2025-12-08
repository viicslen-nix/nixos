{pkgs}:
with pkgs;
  vimUtils.buildVimPlugin {
    pname = "neotest-pest";
    version = "1.0";

    src = fetchFromGitHub {
      owner = "V13Axel";
      repo = "neotest-pest";
      rev = "v1.0";
      sha256 = "sha256-8iCGpbrDnqJLTiB9oe5RvpTAgi9J9D0y7VzSw9qd0oQ=";
    };

    buildInputs = with vimPlugins; [
      neotest
    ];
  }
