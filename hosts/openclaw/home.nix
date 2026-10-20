let
  # tailscaled runs with --tun=userspace-networking, so tailnet hosts are only reachable through its proxy.
  tailnetProxy = "http://127.0.0.1:1055";
  noProxy = "localhost,127.0.0.1,::1";
in {
  home = {
    stateVersion = "25.11";
    preferXdgDirectories = true;
    sessionVariables = {
      HTTPS_PROXY = tailnetProxy;
      HTTP_PROXY = tailnetProxy;
      NO_PROXY = noProxy;
      NODE_USE_ENV_PROXY = "1";
    };
  };

  programs = {
    home-manager.enable = true;
    claude-code.settings.env = {
      HTTPS_PROXY = tailnetProxy;
      NO_PROXY = noProxy;
    };
  };
}
