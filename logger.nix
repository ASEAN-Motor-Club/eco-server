{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.services.eco-server-logger;
in {
  options.services.eco-server-logger = {
    enable = lib.mkEnableOption "Eco server log streaming";
    serverLogsPath = mkOption {
      type = types.str;
      description = "The path to Saved/ServerLog";
    };
    tag = mkOption {
      type = types.str;
      description = "The tag for log lines";
      default = "eco";
    };
  };

  config = mkIf cfg.enable {
    services.rsyslogd.extraConfig = ''
      input(type="imfile"
        File="${cfg.serverLogsPath + "/*.txt"}"
        Tag="${cfg.tag}"
        ruleset="mt-out"
        addMetadata="on"
      )
    '';
  };
}
