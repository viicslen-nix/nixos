{writeShellScriptBin,stdenv,...}: writeShellScriptBin "system-update" ''
  #!${stdenv.shell}

  if [ "$#" -eq 0 ]; then
    nix flake update
  else
    for input in "$@"; do
      nix flake lock --update-input ''${input}
    done
  fi
''