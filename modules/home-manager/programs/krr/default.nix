{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  name = "krr";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc "krr");
    package = mkOption {
      type = types.package;
      default = pkgs.krr;
      description = "Override the krr package.";
    };
    enableK9sIntegration = mkEnableOption (mdDoc "Integrate krr with k9s");
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    programs.k9s.plugins = mkIf cfg.enableK9sIntegration {
      krr = {
        shortCut = "Shift-K";
        description = "Get krr";
        scopes = [ "deployments" "daemonsets" "statefulsets" "cronjobs" ];
        command = "bash";
        background = false;
        confirm = false;
        args = [
          "-c"
          ''
            LABELS=$(${getExe pkgs.kubectl} get $RESOURCE_NAME $NAME -n $NAMESPACE  --context $CONTEXT  --show-labels | awk '{print $NF}' | awk '{if(NR>1)print}')
            ${getExe cfg.package} simple --cluster $CONTEXT --selector $LABELS
            echo "Press 'q' to exit"
            while : ; do
            read -n 1 k <&1
            if [[ $k = q ]] ; then
            break
            fi
            done
          ''
        ];
      };
      krr-ns = {
        shortCut = "Shift-K";
        description = "Get krr";
        scopes = [ "namespaces" ];
        command = "bash";
        background = false;
        confirm = false;
        args = [
          "-c"
          ''
            ${getExe cfg.package} simple --cluster $CONTEXT -n $RESOURCE_NAME
            echo "Press 'q' to exit"
            while : ; do
            read -n 1 k <&1
            if [[ $k = q ]] ; then
            break
            fi
            done
          ''
        ];
      };
    };
  };
}
