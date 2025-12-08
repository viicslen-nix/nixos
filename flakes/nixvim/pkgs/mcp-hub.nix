{
  lib,
  pkgs,
  fetchFromGitHub,
}:
# MCPHub CLI tool (npm package)
# Note: mcphub-nvim plugin comes from the flake input, not built here
pkgs.buildNpmPackage rec {
  pname = "mcp-hub";
  version = "4.2.0";

  src = fetchFromGitHub {
    owner = "ravitemer";
    repo = "mcp-hub";
    rev = "v${version}";
    sha256 = "sha256-WwxFTg8wphvIC7jDqDqyQBtKvn3Xr0ZRptDjwkFNx78=";
  };

  npmDepsHash = "sha256-dN32oGN5lRGZmFi8tgi5ukr8oi8eS3SsabxyOrubO7U=";

  meta = with lib; {
    description = "MCP Hub CLI tool";
    homepage = "https://github.com/ravitemer/mcp-hub";
    license = licenses.mit;
    maintainers = [];
  };
}
