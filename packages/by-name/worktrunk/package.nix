{ lib
, rustPlatform
, fetchFromGitHub
, ...
}:

rustPlatform.buildRustPackage rec {
  pname = "worktrunk";
  version = "0.28.2";

  src = fetchFromGitHub {
    owner = "max-sixty";
    repo = "worktrunk";
    rev = "v${version}";
    hash = "sha256-ftuZP5nmdUoSZLzbHVMwNkOeVr0ZSmtXfcL5w/xXBUg=";
  };

  cargoHash = "sha256-jAf9rTKZGiNsbkj08HPzceGsXevvFjd98FNcARB7gww=";

  doCheck = false;

  meta = with lib; {
    description = "CLI for git worktree management";
    homepage = "https://worktrunk.dev";
    license = licenses.mit;
    mainProgram = "wt";
    maintainers = [ ];
  };
}
