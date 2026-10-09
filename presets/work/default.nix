{
  config,
  nixosModules,
  ...
}: {
  imports = [
    nixosModules.programs.mkcert
  ];

  config = {
    home-manager.sharedModules = [./home.nix];

    # Cert is public and feeds the build-time bundle; only the key is a secret.
    age.secrets.mkcert-rootCA-key.file = ../../secrets/mkcert/rootCA-key.age;

    modules = {
      programs.mkcert.rootCA = {
        enable = true;
        certPath = ../../secrets/mkcert/rootCA.pem;
        keyPath = config.age.secrets.mkcert-rootCA-key.path;
      };

      core.network.hosts = {
        # Shared work servers
        "webapps" = "50.116.36.170";
        "storesites" = "23.239.17.196";
        "db-prod-master" = "45.33.94.139";
        "db-prod-read" = "45.79.151.62";

        # Work projects
        "erpnext.test" = "127.0.0.1";
        "selldiam.test" = "127.0.0.1";
        "mylisterhub.test" = "127.0.0.1";
        "vite.mylisterhub.test" = "127.0.0.1";
        "app.mylisterhub.test" = "127.0.0.1";
        "admin.mylisterhub.test" = "127.0.0.1";
        "*.mylisterhub.test" = "127.0.0.1";
        "time-tracker.test" = "127.0.0.1";
        "labreu.test" = "127.0.0.1";
        "store.labreu.test" = "127.0.0.1";
      };
    };
  };
}
